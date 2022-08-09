// NFTStandard.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Error messages.
//
// NFTStandard: Error 1 : client id array length must match the amount of tokens to be minted
// NFTStandard: Error 2 : invalid client id #XYZ
// NFTStandard: Error 3 : client id #XYZ is already minted
// NFTStandard: Error 4 : get multi minting condition with nonexistent key
// NFTStandard: Error 5 : beneficiary is not set
// NFTStandard: Error 6 : no funds to withdraw
// NFTStandard: Error 7 : failed to withdraw
// NFTStandard: Error 8 : token id #XYZ does not exist
// NFTStandard: Error 9 : token id #XYZ does not have its clientId
// NFTStandard: Error 10 : URI query for nonexistent token
// NFTStandard: Error 11 : the starting token id is greater than the ending token id
// NFTStandard: Error 12 : royalty fee will exceed salePrice
// NFTStandard: Error 13 : invalid receiver address
// NFTStandard: Error 14 : invalid beneficiary address
// NFTStandard: Error 15 : the starting block id is greater than the ending block
// NFTStandard: Error 16 : maximum token amount per address can not be 0
// NFTStandard: Error 17 : starting block has to be greater than current block height
// NFTStandard: Error 18 : the starting client id is greater than the ending client id
// NFTStandard: Error 19 : client id can not be 0
// NFTStandard: Error 20 : given range contains minted token id
// NFTStandard: Error 21 : given range overlaps a token range in minting condition ID #XYZ
// NFTStandard: Error 22 : minting condition id #XYZ does not exist
// NFTStandard: Error 23 : all tokens are minted
// NFTStandard: Error 24 : tokens are not mintable in this block
// NFTStandard: Error 25 : insufficient funds
// NFTStandard: Error 26 : it exceeds the remaining mintable tokens
// NFTStandard: Error 27 : it exceeds the maximum token amount per address
// NFTStandard: Error 28 : failed to refund
// NFTStandard: Error 29 : not whitelisted
// NFTStandard: Error 30 : invalid amount per address

/**
 *
 * @dev Library for managing an enumerable minting condition
 * @dev inspired by Openzeppelin enumerable map
 *
 */
library EnumerableSale {
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    using Strings for uint256;
        
    // @dev a common struct to manage a range
    struct Range {
        uint256 _startId;
        uint256 _endId;
    }

    /**
     * @dev The minting condition struct
     *
     * @param _tokenRange The token's id range that can be minted (inclusive).
     * @param _blockRange The block range where users can call the mint function(inclusive).
     * @param _clientIdRange The client id range mapped to the client-side resource (inclusive)
     * @param _minters the list of addresses to mint for airdrop
     * @param _whitelistMerkleRoot The merkle root calculated from the whitelist.
     * @param _price The token price in Wei.
     * @param _maxAmountPerAddress The maximum token amount that a single address can mint.
     * @param _baseuri The base URI of tokens in the specified range. It can be updated any time.
     * @param _royaltyReceiver The address to receive royalty of tokens in the specified range.
     * @param _royaltyFraction The royalty fraction to determine the royalty amount. It can be updated any time.
     */
    struct MintingConditionStruct {
        Range _tokenRange;
        Range _blockRange;
        Range _clientIdRange;
        address[] _minters;
        bytes32 _whitelistMerkleRoot;
        uint256 _price;
        uint256 _maximumAmountPerAddress;
        string _baseURI;
        address _royaltyReceiver;
        uint96 _royaltyFraction;
    }

    struct Sale {
        MintingConditionStruct _mintingCond;
        Counters.Counter _tokenIdTracker;
        bool _saleClosed;
        mapping(address => uint256) _tokensPerCapital;
    }

    struct Sales {
        uint256 _saleIdCounter;
        // Storage of keys
        EnumerableSet.UintSet _keys;
        mapping(uint256 => Sale) _values;
        // @dev client id set
        EnumerableSet.UintSet _clientIdSet;
    }

    function _tokenTrackerIncrement(Sales storage sales, uint256 key) internal {
        // assert key must exist
        assert(_contains(sales, key));
        sales._values[key]._tokenIdTracker.increment();
    }

    function _tokenTrackerCurrent(Sales storage sales, uint256 key) internal view returns(uint256) {
        // assert key must exist
        assert(_contains(sales, key));
        return sales._values[key]._tokenIdTracker.current();
    }

    function _tokenTrackerReset(Sales storage sales, uint256 key) internal {
        // assert key must exist
        assert(_contains(sales, key));
        sales._values[key]._tokenIdTracker.reset();
    }

    function _setClosedState(Sales storage sales, uint256 key, bool state) internal {
        // assert key must exist
        assert(_contains(sales, key));
        sales._values[key]._saleClosed = state;
    }

    function _getClosedState(Sales storage sales, uint256 key) internal view returns(bool) {
        // assert key must exist
        assert(_contains(sales, key));
        return sales._values[key]._saleClosed;
    }

    function _setWhoMintedHowmany(Sales storage sales, uint256 key, address minter, uint256 amount) internal {
        // assert key must exist
        assert(_contains(sales, key));
        sales._values[key]._tokensPerCapital[minter] = amount;
    }

    function _getWhoMintedHowmany(Sales storage sales, uint256 key, address minter) internal view returns(uint256) {
        // assert key must exist
        assert(_contains(sales, key));
        return sales._values[key]._tokensPerCapital[minter];
    }
    
    function _isAMinter(Sales storage sales, uint256 key, address user) internal view returns (bool){
        // assert key must exist
        assert(_contains(sales, key));
        for (uint256 i = 0; i < sales._values[key]._mintingCond._minters.length; i ++) {
            if (user == sales._values[key]._mintingCond._minters[i]) {
                return true;
            }
        }
        return false;
    }

    // function get the latest id created
    function _getLatestSaleId(Sales storage sales) internal view returns(uint256) {
        return sales._saleIdCounter;
    }

    // validate clientid
    function _validateClientId(Sales storage sales, uint256 key, uint256[] calldata clientIds, uint256 amountPerAddress, uint256 receiversLenght) internal {
        // assert key must exist
        assert(_contains(sales, key));

        require(clientIds.length == (amountPerAddress * receiversLenght), "NFTStandard: Error 1");
        for (uint256 i = 0; i < clientIds.length; i++) {
            uint256 clientId = clientIds[i];
            assert(clientId != 0); // must be != 0
            require(inRange(clientId, sales._values[key]._mintingCond._clientIdRange), string(abi.encodePacked("NFTStandard: Error 2, ", clientId.toString())));
            require(sales._clientIdSet.add(clientId), string(abi.encodePacked("NFTStandard: Error 3, ", clientId.toString())));
        }
    }

    /**
     * @dev private function to check if an ID is in range
     * @param _id The id to be verified if in range
     * @param _range The range to be verified if contains _id
    */
    function inRange(uint256 _id, EnumerableSale.Range memory _range) private pure returns(bool) {
        return (_id >= _range._startId && _id <= _range._endId);
    }

    /**
     * @dev calculate total tokens in a minting condition
    */
    function _totalTokenSet(Sales storage sales, uint256 key) internal view returns(uint256) {
        return (sales._values[key]._mintingCond._tokenRange._endId - sales._values[key]._mintingCond._tokenRange._startId + 1);
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     * @param key can be 0 or others. if 0 it creates new minting condition. If others it updates
     */
    function _set(
        Sales storage sales,
        uint256 key,
        MintingConditionStruct memory value
    ) internal returns (bool) {
        // if key = 0, create a new auto-incremented minting condition id
        if (key == 0) {
            sales._saleIdCounter++; // omit #0
            key = _getLatestSaleId(sales);
        } else {
            // assert key exist
            assert(_contains(sales, key));
        }

        sales._values[key]._mintingCond = value;
        return sales._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Sales storage sales, uint256 key) internal returns (bool) {
        // assert key must exist
        assert(_contains(sales, key));
        delete sales._values[key];
        // TODO safe with current logic, check.
        //delete sales._whoMintedHowMany[key];
        return sales._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Sales storage sales, uint256 key) internal view returns (bool) {
        return sales._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Sales storage sales) internal view returns (uint256) {
        return sales._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Sales storage sales, uint256 index) internal view returns (uint256, MintingConditionStruct memory) {
        uint256 key = sales._keys.at(index);
        return (key, sales._values[key]._mintingCond);
    }


    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Sales storage sales, uint256 key) internal view returns (MintingConditionStruct memory) {
        MintingConditionStruct memory value = sales._values[key]._mintingCond;
        require(_contains(sales, key), "NFTStandard: Error 4");
        return value;
    }
}

// abstract contract for NFT standard
abstract contract NFTStandard is ERC721Enumerable, ERC721Burnable, ERC721Pausable, IERC2981, Ownable, ReentrancyGuard {
    using EnumerableSale for EnumerableSale.Sales;
    using EnumerableSet for EnumerableSet.UintSet;
    using Strings for uint256;

    // @dev This emits when the minting condition is changed.
    event MintingConditionSet(uint256 _mintingConditionId, EnumerableSale.MintingConditionStruct _mintingCondition);

    // @dev This emits when the beneficiary who can withdraw the funds in the contract is set.
    event BeneficiarySet(address _beneficiary);

    // @dev This emits when the base URI is changed.
    event BaseURISet(EnumerableSale.Range _tokenRange, string _baseURI);

    // @dev This emits when the default royalty information is changed.
    event RoyaltyInfoSet(EnumerableSale.Range _tokenRange, address _receiver, uint96 _feeNumerator);

    // @dev This emits when the contract uri is changed.
    event ContractURISet(string _contractURI);

    // for multi minting condition management
    EnumerableSale.Sales private sales;

    // @dev mapping token id to client id
    mapping(uint256=>uint256) private tokenIdClientId;

    // @dev The version of this standard template
    uint256 public constant version = 2;

    // @dev public beneficiary address
    address payable public beneficiary;

    // @dev manage base uri by range
    struct Range_baseuri {
        EnumerableSale.Range _range;
        string _baseuri;
    }
    mapping(uint256 => Range_baseuri) private indexedRangeBaseuri;
    uint256 private baseUriSetterCounter;
    
    // @dev manage token royalty in range
    struct RoyaltyInfo {
        address _receiver;
        uint96 _royaltyFraction;
    }

    struct Range_royaltyinfo {
        EnumerableSale.Range _range;
        RoyaltyInfo _royalty;
    }
    mapping(uint256 => Range_royaltyinfo) private indexedRangeRoyaltyInfo;
    uint256 private royaltyInfoSetterCounter;
    uint96 private feeDenominator = 10000;

    // @dev record minted range
    EnumerableSale.Range[] private mintedRanges;

    // @dev reserved merkle root that allows for free-whitelist minting
    bytes32 private reservedMerkleRoot = 0x0;

    // @dev contract URI
    string private contractUri = "";
    
    /**
     * @dev Constructor
     * @notice The custom event is emitted for The Graph indexing service.
     * @param _name The name of the NFT token
     * @param _symbol The symbol of the NFT token
    */
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        setBeneficiary(_msgSender());
    }

    /**
     * @dev check if 2 ranges overlap each other
     * @param range1 the first range
     * @param range2 the second range
    */
    function overlapped(EnumerableSale.Range memory range1, EnumerableSale.Range memory range2) private pure returns(bool) {
        // overlapped range is [overlapped_start, overlapped_stop] with:
        uint256 overlapped_start = (range1._startId >= range2._startId) ? range1._startId : range2._startId;
        uint256 overlapped_stop = (range1._endId <= range2._endId) ? range1._endId : range2._endId;
        return(overlapped_start <= overlapped_stop);
    }

    /**
     * @dev Check if comming range's vacant or not
     * @param _tokenRange The token id range to be verified
    */
    function isRangeVacant(EnumerableSale.Range memory _tokenRange) private view returns(bool) {
        for (uint i = 0; i < mintedRanges.length; i++) {
            if (overlapped(_tokenRange, mintedRanges[i]))
                return false;
        }
        return true;
    }

    /**
     * @dev pause all transferring activities
    */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause all transferring activities
    */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Overriding just to solve a diamond problem.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Withdraw the funds in this contract.
    */
    function withdraw() external onlyOwner {
        require(beneficiary != address(0x0), "NFTStandard: Error 5");
        require(address(this).balance > 0, "NFTStandard: Error 6");
        (bool sent, ) = beneficiary.call{value: address(this).balance}("");
        require(sent, "NFTStandard: Error 7");
    }

    /**
     * @notice Return client ids mapped to given token ids
     * @dev Throws if any of given token ids is not minted.
     * @param _tokenIds Token ids to query client ids.
     * @return The array of client ids
    */
    function clientIdBatch(uint256[] calldata _tokenIds) external view returns (uint256[] memory) {
        uint256[] memory clientIds = new uint256[](_tokenIds.length);
        uint256 id;
        uint256 clid;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            id = _tokenIds[i];
            clid = tokenIdClientId[id];
            require(_exists(id), string(abi.encodePacked("NFTStandard: Error 8, ", id.toString())));
            require(clid != 0, string(abi.encodePacked("NFTStandard: Error 9, ", id.toString())));
            clientIds[i] = clid;
        }
        return clientIds;
    }

    /**
     * @notice Return the contract URI
     * @return The contract URI.
    */
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    /**
     * @notice Set the contract URI
    */
    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractUri = _contractURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "NFTStandard: Error 10");
        string memory baseURI = _baseURI(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev overload ERC721::_baseURI() with tokenId as param
     * @param tokenId The baseURI of this tokenId will be returned
    */
    function _baseURI(uint256 tokenId) private view returns (string memory) {
        // scan backward to get the latest update on range baseuri
        for(uint256 idx = baseUriSetterCounter; idx > 0; idx --) {
            if (inRange(tokenId, indexedRangeBaseuri[idx-1]._range)) {
                return indexedRangeBaseuri[idx-1]._baseuri;
            }
        }
        return "";
    }

    /**
     * @dev private function to check if an ID is in range
     * @param _id The id to be verified if in range
     * @param _range The range to be verified if contains _id
    */
    function inRange(uint256 _id, EnumerableSale.Range memory _range) private pure returns(bool) {
        return (_id >= _range._startId && _id <= _range._endId);
    }

    /**
     * @dev Change the base URI to apply to tokens in a specific range.
     * @param _tokenRange the token's id range that can be minted (inclusive).
     * @param _baseuri The base URI to set
    */
    function setBaseURI(EnumerableSale.Range calldata _tokenRange, string calldata _baseuri) public onlyOwner {
        require(_tokenRange._startId <= _tokenRange._endId, "NFTStandard: Error 11");
        indexedRangeBaseuri[baseUriSetterCounter]._range = _tokenRange;
        indexedRangeBaseuri[baseUriSetterCounter]._baseuri = _baseuri;
        baseUriSetterCounter ++;
        emit BaseURISet(_tokenRange, _baseuri);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty;
        uint256 royaltyAmount;
        // scan backward to get the latest update on range royalty
        for(uint256 idx = royaltyInfoSetterCounter; idx > 0; idx --) {
            if (inRange(_tokenId, indexedRangeRoyaltyInfo[idx-1]._range)) {
                royalty = indexedRangeRoyaltyInfo[idx-1]._royalty;
                royaltyAmount = (_salePrice * royalty._royaltyFraction) / feeDenominator;
                return (royalty._receiver, royaltyAmount);
            }
        }
        return (address(0x0), 0);
    }

    /**
     * @dev Change the default royalty information to apply to tokens in a specific range.
     * @param _tokenRange he token's id range that can be minted (inclusive).
     * @param _receiver The account to receive royalty amount.
     * @param _feeNumerator The fee numerator to calculate royalty rate (numerator/feeDenominator).
    */
    function setRoyaltyInfo(EnumerableSale.Range calldata _tokenRange, address _receiver, uint96 _feeNumerator) public onlyOwner {
        require(_tokenRange._startId <= _tokenRange._endId, "NFTStandard: Error 11");
        require(_feeNumerator <= feeDenominator, "NFTStandard: Error 12");
        require(_receiver != address(0), "NFTStandard: Error 13");
        indexedRangeRoyaltyInfo[royaltyInfoSetterCounter]._range = _tokenRange;
        indexedRangeRoyaltyInfo[royaltyInfoSetterCounter]._royalty = RoyaltyInfo(_receiver, _feeNumerator);
        royaltyInfoSetterCounter++;
        emit RoyaltyInfoSet(_tokenRange, _receiver, _feeNumerator);
    }

    // @dev Set the beneficiary.
    function setBeneficiary(address _beneficiary) public onlyOwner {
        require(_beneficiary != address(0x0), "NFTStandard: Error 14");
        beneficiary = payable(_beneficiary);
        emit BeneficiarySet(_beneficiary);
    }

    /**
     * @notice Change the minting condition. Only the owner can change.
     * @dev If changed during a sale, only the ending of blockRange and whitelist are in effect.
     * @param _mintingConditionId 0 if creating; others(existing) if updating.
     * @param _mintingCondition The minting condition to be set for each sale
     */
    function setMintingCondition(uint256 _mintingConditionId, EnumerableSale.MintingConditionStruct calldata _mintingCondition) external onlyOwner {
        // ________VALIDATING INPUT MINTING CONDITION__________
        require(_mintingCondition._blockRange._startId <= _mintingCondition._blockRange._endId, "NFTStandard: Error 15");

        uint256 saleId;
        EnumerableSale.MintingConditionStruct memory sale;
        // process to record minted Range
        for (uint256 i = 0; i < sales._length(); i ++) {
            (saleId, sale) = sales._at(i);
            // sale period expired with some tokens minted
            if (block.number > sale._blockRange._endId && !sales._getClosedState(saleId) && sales._tokenTrackerCurrent(saleId) != 0) {
                _updateSaleStates(saleId, EnumerableSale.Range(sale._tokenRange._startId, sale._tokenRange._startId + sales._tokenTrackerCurrent(saleId) - 1));
            }
        }
        require(isRangeVacant(_mintingCondition._tokenRange), "NFTStandard: Error 20");


        // ________RESOLVE ALL MINTING CONDITIONS IN ALL SALES__________
        for (uint256 i = 0; i < sales._length(); i ++) {
            (saleId, sale) = sales._at(i);

            // if not overlap, no need to resolve
            if (!overlapped(_mintingCondition._tokenRange, sale._tokenRange)) {
                continue;
            }

            // sale period expired
            if (block.number > sale._blockRange._endId) {
                // the tokenRange is not minted at all
                if (!sales._getClosedState(saleId) && sales._tokenTrackerCurrent(saleId) == 0) {
                    sales._remove(saleId);
                }
            // in sale period
            } else if (block.number >= sale._blockRange._startId) {
                // sale is active. we can't decide anything except preventing overlaping configuration creations
                if (_mintingConditionId == 0) {
                    revert(string(abi.encodePacked("NFTstandard: Error 21, ", saleId.toString())));
                }
            // in-the-future sales
            } else {
                // if sale hasn't started, allow for reconfiguration
                sales._remove(saleId);
            }
        }
        
        // creating new minting condition
        if (_mintingConditionId == 0) {
            require(_mintingCondition._tokenRange._startId <= _mintingCondition._tokenRange._endId, "NFTStandard: Error 11");
            require(_mintingCondition._maximumAmountPerAddress != 0, "NFTStandard: Error 16");
            require(_mintingCondition._blockRange._startId > block.number, "NFTStandard: Error 17");
            require(_mintingCondition._clientIdRange._startId <= _mintingCondition._clientIdRange._endId, "NFTStandard: Error 18");
            require(_mintingCondition._clientIdRange._startId > 0, "NFTStandard: Error 19");
            // _mintingConditionId would be auto incremented
            sales._set(_mintingConditionId, _mintingCondition);
            setBaseURI(_mintingCondition._tokenRange, _mintingCondition._baseURI);
            setRoyaltyInfo(_mintingCondition._tokenRange, _mintingCondition._royaltyReceiver, _mintingCondition._royaltyFraction);
            // A new sale is beginning
            sales._setClosedState(sales._getLatestSaleId(), false);
            emit MintingConditionSet(sales._getLatestSaleId(), _mintingCondition);
        // updating old minting condition if passed correctly
        } else {
            require(sales._contains(_mintingConditionId), string(abi.encodePacked("NFTStandard: Error 22, ", _mintingConditionId.toString())));
            if (inRange(block.number, sales._get(_mintingConditionId)._blockRange) && !sales._getClosedState(_mintingConditionId)) {
                EnumerableSale.MintingConditionStruct memory newsaleInstance = sales._get(_mintingConditionId);
                newsaleInstance._blockRange._endId = _mintingCondition._blockRange._endId;
                newsaleInstance._whitelistMerkleRoot = _mintingCondition._whitelistMerkleRoot;
                newsaleInstance._minters = _mintingCondition._minters;
                sales._set(_mintingConditionId, newsaleInstance);
                emit MintingConditionSet(_mintingConditionId, sales._get(_mintingConditionId));
            }
        }
    }

    /**
     * @notice Return the minting condition.
     * @param _mintingConditionId the minting condition id
     * @return a tuple of (Range, Range, Range, bytes32, uint256, uint256, string, address, uint96)
     */
    function mintingCondition(uint256 _mintingConditionId) public view returns(EnumerableSale.MintingConditionStruct memory) {
        return sales._get(_mintingConditionId);
    }

    /**
     * @notice Get all minting conditions id.
     * @return The array of all sale/minting condition ids
    */
    function mintingConditionIdBatch() public view returns (uint256[] memory) {
        uint256[] memory idBatch = new uint256[](sales._length());
        for (uint256 i = 0; i < sales._length(); i ++) {
            (idBatch[i], ) = sales._at(i);
        }
        return idBatch;
    }

    /**
    * @notice log successful sale information
    */
    function _updateSaleStates(uint256 minitngConditionId, EnumerableSale.Range memory tokenRange) private {
        mintedRanges.push(tokenRange);
        sales._tokenTrackerReset(minitngConditionId);
        sales._setClosedState(minitngConditionId, true);
    }

    /**
     * @notice mint for receivers in batch
    */
    function _mint(uint256 _mintingConditionId, address[] memory _receivers, uint256 _amountPerEach, uint256[] memory _clientIds) private {
        uint256 tokenId;
        // receivers list shouldn't be too big
        for(uint256 i = 0; i < _receivers.length; i ++) {
            for(uint256 j = 0; j < _amountPerEach; j ++) {
                tokenId = sales._get(_mintingConditionId)._tokenRange._startId + sales._tokenTrackerCurrent(_mintingConditionId);
                _safeMint(_receivers[i], tokenId);
                sales._tokenTrackerIncrement(_mintingConditionId);
                if (_clientIds.length != 0) {
                    tokenIdClientId[tokenId] = _clientIds[_amountPerEach*i + j];
                }
            }
        }
    }

    /**
     * @notice The minted tokens belong to msg.sender if whitelist mode enabled and belongs to receivers if minters mint.
     * The remaining coin after minting is refunded.
     * @dev Mint the token with the native coin.
     *
     * @param _mintingConditionId The id given by the contract for each successful minting condition set
     * @param _receivers The list to receve NFT when minters mint
     * @param _amountPerAddress The number of tokens to mint
     * @param _clientIds An array of clientIds that should be a subset of mintingCondition.clientIdRange.
     * @param _merkleProof The proof that msg.sender is in the whitelist.
     */
    function mint(uint256 _mintingConditionId, address[] calldata _receivers, uint256 _amountPerAddress, uint256[] calldata _clientIds, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(_amountPerAddress != 0, "NFTStandard: Error 30");
        require(sales._contains(_mintingConditionId), string(abi.encodePacked("NFTStandard: Error 22, ", _mintingConditionId.toString())));
        require(!sales._getClosedState(_mintingConditionId), "NFTStandard: Error 23");
        EnumerableSale.MintingConditionStruct memory sale = sales._get(_mintingConditionId);
        require(inRange(block.number, sale._blockRange), "NFTStandard: Error 24");

        // reused variable for tokens minted PC and refund to avoid stack too deep error
        uint256 temp;
        // validate minters and mint to receivers of minters make the call
        if(sale._minters.length != 0 && sales._isAMinter(_mintingConditionId, _msgSender()) && (_receivers.length > 0)) {
            require(msg.value >= (sale._price * _amountPerAddress * _receivers.length), "NFTStandard: Error 25");
            require(sales._tokenTrackerCurrent(_mintingConditionId) + _amountPerAddress * _receivers.length <= sales._totalTokenSet(_mintingConditionId), "NFTStandard: Error 26");
            for (uint256 i = 0; i < _receivers.length; i ++) {
                // validate amount of tokens per person
                temp = sales._getWhoMintedHowmany(_mintingConditionId, _receivers[i]);
                require((temp + _amountPerAddress) <= sale._maximumAmountPerAddress, "NFTStandard: Error 27");
            }
            // validate client ids
            if (_clientIds.length != 0) { sales._validateClientId(_mintingConditionId, _clientIds, _amountPerAddress, _receivers.length); }
            
            _mint(_mintingConditionId, _receivers, _amountPerAddress, _clientIds);

            // record amount of tokens per person
            for (uint256 i = 0; i < _receivers.length; i ++) {
                temp = sales._getWhoMintedHowmany(_mintingConditionId, _receivers[i]);
                sales._setWhoMintedHowmany(_mintingConditionId, _receivers[i], temp + _amountPerAddress);
            }

            // all tokens in range have been minted
            if (sales._tokenTrackerCurrent(_mintingConditionId) == sales._totalTokenSet(_mintingConditionId)) {
                _updateSaleStates(_mintingConditionId, sale._tokenRange);
            }

            // refund
            temp = msg.value - (sale._price * _amountPerAddress * _receivers.length);
            if (temp != 0) {
                (bool sent, ) = payable(_msgSender()).call{value: temp}("");
                require(sent, "NFTStandard: Error 28");
            }
        //validate whitelist program and mint to caller
        } else {
            if (sale._whitelistMerkleRoot != reservedMerkleRoot) {
                bytes32 merkleLeaf = keccak256(abi.encodePacked(_msgSender()));
                require(MerkleProof.verify(_merkleProof, sale._whitelistMerkleRoot, merkleLeaf), "NFTStandard: Error 29");
            }

            require(msg.value >= (sale._price * _amountPerAddress), "NFTStandard: Error 25");
            require(sales._tokenTrackerCurrent(_mintingConditionId) + _amountPerAddress <= sales._totalTokenSet(_mintingConditionId), "NFTStandard: Error 26");
            temp = sales._getWhoMintedHowmany(_mintingConditionId, _msgSender());
            require((temp + _amountPerAddress) <= sale._maximumAmountPerAddress, "NFTStandard: Error 27");
            // validate client ids
            if (_clientIds.length != 0) { sales._validateClientId(_mintingConditionId, _clientIds, _amountPerAddress, 1); }

            address[] memory user = new address[](1);
            user[0] = _msgSender();
            _mint(_mintingConditionId, user, _amountPerAddress, _clientIds);

            sales._setWhoMintedHowmany(_mintingConditionId, _msgSender(), temp + _amountPerAddress);
            
            // all tokens in range have been minted
            if (sales._tokenTrackerCurrent(_mintingConditionId) == sales._totalTokenSet(_mintingConditionId)) {
                _updateSaleStates(_mintingConditionId, sale._tokenRange);
            }

            // refund
            temp = msg.value - (sale._price * _amountPerAddress);
            if (temp != 0) {
                (bool sent, ) = payable(_msgSender()).call{value: temp}("");
                require(sent, "NFTStandard: Error 28");
            }
        }
    }
}

contract ETHERGEN is NFTStandard {
    constructor(string memory _name, string memory _symbol)
        NFTStandard(_name, _symbol) {
        // do nothing
    }
}