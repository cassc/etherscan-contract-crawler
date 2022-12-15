// NFTStandard.sol
// SPDX-License-Identifier: MIT

/*
 * Error message map.
 * NS1 : client id array length must match the amount of tokens to be minted
 * NS2 : invalid client id #XYZ
 * NS3 : client id #XYZ is already minted
 * NS4 : get multi minting condition with nonexistent key
 * NS5 : beneficiary is not set
 * NS6 : no funds to withdraw
 * NS7 : failed to withdraw
 * NS8 : token id #XYZ does not exist
 * NS9 : token id #XYZ does not have its clientId
 * NS10 : URI query for nonexistent token
 * NS11 : the starting token id is greater than the ending token id
 * NS12 : royalty fee will exceed salePrice
 * NS13 : invalid receiver address
 * NS14 : invalid beneficiary address
 * NS15 : the starting block id is greater than the ending block
 * NS16 : maximum token amount per address can not be 0
 * NS17 : starting block has to be greater than current block height
 * NS18 : the starting client id is greater than the ending client id
 * NS19 : client id can not be 0
 * NS20 : given range contains minted token id
 * NS21 : given range overlaps a token range in minting condition ID #XYZ
 * NS22 : minting condition id #XYZ does not exist
 * NS23 : all tokens are minted
 * NS24 : the current block height is less than the starting block
 * NS25 : insufficient funds
 * NS26 : it exceeds the remaining mintable tokens #XYZ
 * NS27 : it exceeds the maximum token amount per address #XYZ
 * NS28 : failed to refund
 * NS29 : not whitelisted
 * NS30 : invalid amount per address
 * NS31 : minting condition is closed already
 * NS32 : the current block height is greater than the ending block
 */

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/**
 * @dev Library for managing an enumerable minting condition
 * @dev inspired by Openzeppelin enumerable map
 */
library EnumerableSale {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    // @dev a common struct to manage a range
    struct Range {
        uint256 _startId;
        uint256 _endId;
    }

    /**
     * @dev The minting condition struct
     * @param _tokenRange The token's id range that can be minted (inclusive).
     * @param _blockRange The block range where users can call the mint function(inclusive).
     * @param _clientIdRange The client id range mapped to the client-side resource (inclusive)
     * @param _minters the list of addresses to mint for airdrop
     * @param _whitelistMerkleRoot The merkle root calculated from the whitelist.
     * @param _price The token price in Wei.
     * @param _maxAmountPerAddress The maximum token amount that a single address can mint.
     * @param _baseuri The base URI of tokens in the specified range. It can be updated any time.
     * @param _royaltyReceiver The address to receive royalty of tokens in the specified range.
     * @param _royaltyFraction The royalty fraction to determine the royalty amount. It can be
     * updated any time.
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
        CountersUpgradeable.Counter _tokenIdTracker;
        bool _saleClosed;
        mapping(address => uint256) _tokensPerCapital;
    }

    struct Sales {
        uint256 _saleIdCounter;
        // Storage of keys
        EnumerableSetUpgradeable.UintSet _keys;
        mapping(uint256 => Sale) _values;
        EnumerableSetUpgradeable.UintSet _clientIdSet;
    }

    /**
     * @dev Add 1 to the number of token minted
     * @param key The sale/minting-condition Id
     */
    function _tokenTrackerIncrement(Sales storage sales, uint256 key) internal {
        // assert key must exist
        assert(_contains(sales, key));
        sales._values[key]._tokenIdTracker.increment();
    }

    /**
     * @dev return the number of tokens minted
     * @param key The sale/minting-condition Id
     */
    function _tokenTrackerCurrent(Sales storage sales, uint256 key)
        internal
        view
        returns (uint256)
    {
        // assert key must exist
        assert(_contains(sales, key));
        return sales._values[key]._tokenIdTracker.current();
    }

    /**
     * @dev rest token tracker
     * @param key The sale/minting-condition Id
     */
    function _tokenTrackerReset(Sales storage sales, uint256 key) internal {
        // assert key must exist
        assert(_contains(sales, key));
        sales._values[key]._tokenIdTracker.reset();
    }

    /**
     * @dev set flag CLOSED for sale
     * @param key The sale/minting-condition Id
     * @param state true: CLOSED, NOT CLOSED
     */
    function _setClosedState(
        Sales storage sales,
        uint256 key,
        bool state
    ) internal {
        // assert key must exist
        assert(_contains(sales, key));
        sales._values[key]._saleClosed = state;
    }

    /**
     * @dev check if sale is CLOSED or not
     * @param key The sale/minting-condition Id
     */
    function _getClosedState(Sales storage sales, uint256 key)
        internal
        view
        returns (bool)
    {
        // assert key must exist
        assert(_contains(sales, key));
        return sales._values[key]._saleClosed;
    }

    /**
     * @dev track whom minted how many tokens for commonValidation()
     * @param key The sale/minting-condition Id
     */
    function _setWhoMintedHowmany(
        Sales storage sales,
        uint256 key,
        address minter,
        uint256 amount
    ) internal {
        // assert key must exist
        assert(_contains(sales, key));
        sales._values[key]._tokensPerCapital[minter] = amount;
    }

    /**
     * @dev get whom minted how many tokens
     * @param key The sale/minting-condition Id
     */
    function _getWhoMintedHowmany(
        Sales storage sales,
        uint256 key,
        address minter
    ) internal view returns (uint256) {
        // assert key must exist
        assert(_contains(sales, key));
        return sales._values[key]._tokensPerCapital[minter];
    }

    /**
     * @dev check if a user is in the minter list or not
     * @param key The sale/minting-condition Id
     */
    function _isAMinter(
        Sales storage sales,
        uint256 key,
        address user
    ) internal view returns (bool) {
        // assert key must exist
        assert(_contains(sales, key));
        address[] memory minters = sales._values[key]._mintingCond._minters;
        for (uint256 i = 0; i < minters.length; ++i) {
            if (user == minters[i]) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev function get the latest id created
     */
    function _getLatestSaleId(Sales storage sales)
        internal
        view
        returns (uint256)
    {
        return sales._saleIdCounter;
    }

    /**
     * @dev validate clientid
     * @param key The minting condition id
     * @param clientIds The client id list
     * @param amountPerAddress The amount to be minted for each address
     * @param receiversLenght The length of the NFT receivers
     */
    function _validateClientId(
        Sales storage sales,
        uint256 key,
        uint256[] calldata clientIds,
        uint256 amountPerAddress,
        uint256 receiversLenght
    ) internal {
        if (clientIds.length != 0) {
            // assert key must exist
            assert(_contains(sales, key));
            require(
                clientIds.length == (amountPerAddress * receiversLenght),
                "NS1"
            );
            Range memory clidRange = sales
                ._values[key]
                ._mintingCond
                ._clientIdRange;
            for (uint256 i = 0; i < clientIds.length; ++i) {
                uint256 clientId = clientIds[i];
                assert(clientId != 0); // must be != 0
                require(
                    (clientId >= clidRange._startId) &&
                        (clientId <= clidRange._endId),
                    string(abi.encodePacked("NS2, ", clientId.toString()))
                );
                require(
                    sales._clientIdSet.add(clientId),
                    string(abi.encodePacked("NS3, ", clientId.toString()))
                );
            }
        }
    }

    /**
     * @dev calculate total tokens in a minting condition
     */
    function _totalToken(Sales storage sales, uint256 key)
        internal
        view
        returns (uint256)
    {
        return (sales._values[key]._mintingCond._tokenRange._endId -
            sales._values[key]._mintingCond._tokenRange._startId +
            1);
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing key.
     *
     * Returns true if the key was added to the map, that is if it was not already present.
     * @param key can be 0 or others. if 0 it creates new minting condition. If others it updates
     */
    function _set(
        Sales storage sales,
        uint256 key,
        MintingConditionStruct memory value
    ) internal returns (bool) {
        // if key = 0, create a new auto-incremented minting condition id
        if (key == 0) {
            ++sales._saleIdCounter; // omit #0
            key = _getLatestSaleId(sales);
        } else {
            assert(_contains(sales, key));
        }

        sales._values[key]._mintingCond = value;
        return sales._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     * @param key the sale/minting-condition id
     */
    function _remove(Sales storage sales, uint256 key) internal returns (bool) {
        // assert key must exist
        assert(_contains(sales, key));
        delete sales._values[key];
        return sales._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     * @param key the sale/minting-condition id
     */
    function _contains(Sales storage sales, uint256 key)
        internal
        view
        returns (bool)
    {
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
    function _at(Sales storage sales, uint256 index)
        internal
        view
        returns (uint256, MintingConditionStruct memory)
    {
        uint256 key = sales._keys.at(index);
        return (key, sales._values[key]._mintingCond);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     * @param key the sale/minting-condition id
     */
    function _get(Sales storage sales, uint256 key)
        internal
        view
        returns (MintingConditionStruct memory)
    {
        MintingConditionStruct memory value = sales._values[key]._mintingCond;
        require(_contains(sales, key), "NS4");
        return value;
    }
}

// abstract contract for NFT standard
abstract contract NFTStandard is
    Initializable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721PausableUpgradeable,
    IERC2981Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    using EnumerableSale for EnumerableSale.Sales;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using StringsUpgradeable for uint256;

    // @dev This emits when the minting condition is changed.
    event MintingConditionSet(
        uint256 _mintingConditionId,
        EnumerableSale.MintingConditionStruct _mintingCondition
    );

    // @dev This emits when the beneficiary who can withdraw the funds in the contract is set.
    event BeneficiarySet(address _beneficiary);

    // @dev This emits when the base URI is changed.
    event BaseURISet(EnumerableSale.Range _tokenRange, string _baseURI);

    // @dev This emits when the default royalty information is changed.
    event RoyaltyInfoSet(
        EnumerableSale.Range _tokenRange,
        address _receiver,
        uint96 _feeNumerator
    );

    // @dev This emits when the contract uri is changed.
    event ContractURISet(string _contractURI);

    // @dev for multi minting condition management
    EnumerableSale.Sales private sales;

    // @dev mapping token id to client id
    mapping(uint256 => uint256) private tokenIdClientId;

    // @dev The version of this standard template
    uint256 public constant version = 5;

    // @dev public beneficiary address
    address payable public beneficiary;

    // @dev manage base uri by range
    struct Range_baseuri {
        EnumerableSale.Range _range;
        string _baseuri;
    }
    Range_baseuri[] private baseURIs;

    // @dev manage token royalty in range
    struct RoyaltyInfo {
        address _receiver;
        uint96 _royaltyFraction;
    }

    struct Range_royaltyinfo {
        EnumerableSale.Range _range;
        RoyaltyInfo _royalty;
    }
    Range_royaltyinfo[] private RoyaltyInfos;
    uint96 private feeDenominator;

    // @dev record minted range
    EnumerableSale.Range[] private mintedRanges;

    // @dev reserved merkle root that allows for free-whitelist minting
    bytes32 private constant reservedMerkleRoot = 0x0;

    // @dev contract URI
    string private contractUri;

    // @dev reserve 50 storage slots for future upgrades
    uint256[50] __gap;

    /**
     * @dev initialize
     * @notice function as a constructor's alternative
     * @param _owner The address to own this contract instance
     * @param _name The name of the NFT token
     * @param _symbol The symbol of the NFT token
     * @param _contractUri The contract uri
     */
    function __NFTStandard_init(
        address _owner,
        string memory _name,
        string memory _symbol,
        string memory _contractUri
    ) internal onlyInitializing {
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __ERC721Pausable_init();

        __Ownable_init();
        setBeneficiary(_owner);
        setContractURI(_contractUri);
        // Factory's transfering proxy ownership
        transferOwnership(_owner);

        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();

        __ERC721_init(_name, _symbol);
        __Context_init();

        feeDenominator = 10000;
    }

    /**
     * @dev check if 2 ranges overlap each other
     * @param range1 the first range
     * @param range2 the second range
     */
    function overlapped(
        EnumerableSale.Range memory range1,
        EnumerableSale.Range memory range2
    ) private pure returns (bool) {
        // overlapped range is [overlapped_start, overlapped_stop] with:
        uint256 overlapped_start = (range1._startId >= range2._startId)
            ? range1._startId
            : range2._startId;
        uint256 overlapped_stop = (range1._endId <= range2._endId)
            ? range1._endId
            : range2._endId;
        return (overlapped_start <= overlapped_stop);
    }

    /**
     * @dev Check if comming range's vacant or not
     * @param _tokenRange The token id range to be verified
     */
    function isRangeVacant(EnumerableSale.Range memory _tokenRange)
        private
        view
        returns (bool)
    {
        EnumerableSale.Range[] memory rangesMinted = mintedRanges;
        for (uint256 i = 0; i < rangesMinted.length; ++i) {
            if (overlapped(_tokenRange, rangesMinted[i])) return false;
        }
        return true;
    }

    /**
     * @dev pause all transferring activities
     */
    function pause() external virtual onlyOwner {
        _pause();
    }

    /**
     * @dev unpause all transferring activities
     */
    function unpause() external virtual onlyOwner {
        _unpause();
    }

    /**
     * @dev Overriding just to solve a diamond problem.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    )
        internal
        virtual
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC721PausableUpgradeable
        )
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Withdraw the funds in this contract.
     */
    function withdraw() external virtual onlyOwner {
        require(beneficiary != address(0x0), "NS5");
        require(address(this).balance > 0, "NS6");
        (bool sent, ) = beneficiary.call{value: address(this).balance}("");
        require(sent, "NS7");
    }

    /**
     * @notice Return client ids mapped to given token ids
     * @dev Throws if any of given token ids is not minted.
     * @param _tokenIds Token ids to query client ids.
     * @return clientIds The array of client ids
     */
    function clientIdBatch(uint256[] calldata _tokenIds)
        external
        view
        virtual
        returns (uint256[] memory)
    {
        uint256[] memory clientIds = new uint256[](_tokenIds.length);
        uint256 id;
        uint256 clid;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            id = _tokenIds[i];
            clid = tokenIdClientId[id];
            require(
                _exists(id),
                string(abi.encodePacked("NS8, ", id.toString()))
            );
            require(
                clid != 0,
                string(abi.encodePacked("NS9, ", id.toString()))
            );
            clientIds[i] = clid;
        }
        return clientIds;
    }

    /**
     * @notice Return the contract URI
     * @return contractUri The contract URI.
     */
    function contractURI() public view virtual returns (string memory) {
        return contractUri;
    }

    /**
     * @notice Set the contract URI
     * @param _contractURI The contract URI to be set
     */
    function setContractURI(string memory _contractURI)
        public
        virtual
        onlyOwner
    {
        contractUri = _contractURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "NS10");
        string memory baseURI = _baseURI(tokenId);
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev overload ERC721::_baseURI() with tokenId as param
     * @param tokenId The baseURI of this tokenId will be returned
     */
    function _baseURI(uint256 tokenId) private view returns (string memory) {
        // scan backward to get the latest update on range baseuri
        Range_baseuri[] memory cachedBaseUris = baseURIs;
        for (uint256 idx = cachedBaseUris.length; idx > 0; idx--) {
            if (inRange(tokenId, cachedBaseUris[idx - 1]._range)) {
                return cachedBaseUris[idx - 1]._baseuri;
            }
        }
        return "";
    }

    /**
     * @dev private function to check if an ID is in range
     * @param _id The id to be verified if in range
     * @param _range The range to be verified if contains _id
     */
    function inRange(uint256 _id, EnumerableSale.Range memory _range)
        private
        pure
        returns (bool)
    {
        return (_id >= _range._startId && _id <= _range._endId);
    }

    /**
     * @dev Change the base URI to apply to tokens in a specific range.
     * @param _tokenRange the token's id range that can be minted (inclusive).
     * @param _baseuri The base URI to set
     */
    function setBaseURI(
        EnumerableSale.Range calldata _tokenRange,
        string calldata _baseuri
    ) public virtual onlyOwner {
        require(_tokenRange._startId <= _tokenRange._endId, "NS11");
        baseURIs.push(Range_baseuri(_tokenRange, _baseuri));
        emit BaseURISet(_tokenRange, _baseuri);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty;
        uint256 royaltyAmount;
        // scan backward to get the latest update on range royalty
        Range_royaltyinfo[] memory cachedRoyaltyInfos = RoyaltyInfos;
        for (uint256 idx = cachedRoyaltyInfos.length; idx > 0; idx--) {
            if (inRange(_tokenId, cachedRoyaltyInfos[idx - 1]._range)) {
                royalty = cachedRoyaltyInfos[idx - 1]._royalty;
                royaltyAmount =
                    (_salePrice * royalty._royaltyFraction) /
                    feeDenominator;
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
    function setRoyaltyInfo(
        EnumerableSale.Range calldata _tokenRange,
        address _receiver,
        uint96 _feeNumerator
    ) public virtual onlyOwner {
        require(_tokenRange._startId <= _tokenRange._endId, "NS11");
        require(_feeNumerator <= feeDenominator, "NS12");
        require(_receiver != address(0), "NS13");
        RoyaltyInfos.push(
            Range_royaltyinfo(
                _tokenRange,
                RoyaltyInfo(_receiver, _feeNumerator)
            )
        );
        emit RoyaltyInfoSet(_tokenRange, _receiver, _feeNumerator);
    }

    /**
     * @notice Set the beneficiary.
     * @param _beneficiary The beneficiary address to be set
     */
    function setBeneficiary(address _beneficiary) public virtual onlyOwner {
        require(_beneficiary != address(0x0), "NS14");
        beneficiary = payable(_beneficiary);
        emit BeneficiarySet(_beneficiary);
    }

    /**
     * @notice validate basic properties of a minting condition
     * @param _mintingCondition The minting condition to be validated
     */
    function commonValidation(
        EnumerableSale.MintingConditionStruct calldata _mintingCondition
    ) private view {
        require(
            _mintingCondition._tokenRange._startId <=
                _mintingCondition._tokenRange._endId,
            "NS11"
        );
        require(_mintingCondition._maximumAmountPerAddress != 0, "NS16");
        require(_mintingCondition._blockRange._startId > block.number, "NS17");
        require(
            _mintingCondition._clientIdRange._startId <=
                _mintingCondition._clientIdRange._endId,
            "NS18"
        );
        require(_mintingCondition._clientIdRange._startId > 0, "NS19");
    }

    /**
     * @notice Change the minting condition. Only the owner can change.
     * @dev If changed during a sale, only the ending of blockRange and whitelist are in effect.
     * @param _mintingConditionId 0 if creating; others(existing) if updating.
     * @param _mintingCondition The minting condition to be set for each sale
     */
    function setMintingCondition(
        uint256 _mintingConditionId,
        EnumerableSale.MintingConditionStruct calldata _mintingCondition
    ) external virtual onlyOwner {
        require(
            _mintingCondition._blockRange._startId <=
                _mintingCondition._blockRange._endId,
            "NS15"
        );
        uint256 saleId;
        EnumerableSale.MintingConditionStruct memory sale;
        // validating the input minting condition vacancy and resolve valid overlapped configuration
        for (uint256 i = 0; i < sales._length(); ++i) {
            (saleId, sale) = sales._at(i);
            bool overlaping = overlapped(
                _mintingCondition._tokenRange,
                sale._tokenRange
            );

            // sale period expired
            if (block.number > sale._blockRange._endId) {
                if (!sales._getClosedState(saleId)) {
                    if (sales._tokenTrackerCurrent(saleId) != 0) {
                        // process to record minted Range
                        _closeSale(
                            saleId,
                            EnumerableSale.Range(
                                sale._tokenRange._startId,
                                sale._tokenRange._startId +
                                    sales._tokenTrackerCurrent(saleId) -
                                    1
                            ),
                            true
                        );
                    } else if (overlaping) {
                        // totally unsatisfactory sale, remove it
                        sales._remove(saleId);
                    }
                }
                // in sale period
            } else if (block.number >= sale._blockRange._startId) {
                // sale is activated, prevent overlaping configuration creations
                if (_mintingConditionId == 0 && overlaping) {
                    revert(
                        string(abi.encodePacked("NS21, ", saleId.toString()))
                    );
                }
                // in-the-future sales
            } else {
                // if sale hasn't started, allow for overlapping reconfiguration
                if (_mintingConditionId == 0 && overlaping) {
                    sales._remove(saleId);
                }
            }
        }
        require(isRangeVacant(_mintingCondition._tokenRange), "NS20");

        // creating new minting condition
        if (_mintingConditionId == 0) {
            commonValidation(_mintingCondition);
            _newlySet(_mintingConditionId, _mintingCondition);
            emit MintingConditionSet(
                sales._getLatestSaleId(),
                _mintingCondition
            );
            // updating existing minting condition
        } else {
            require(
                sales._contains(_mintingConditionId),
                string(
                    abi.encodePacked("NS22, ", _mintingConditionId.toString())
                )
            );
            require(!sales._getClosedState(_mintingConditionId), "NS31");
            // updating activated minting condition
            if (
                inRange(
                    block.number,
                    sales._get(_mintingConditionId)._blockRange
                )
            ) {
                EnumerableSale.MintingConditionStruct
                    memory newsaleInstance = sales._get(_mintingConditionId);
                newsaleInstance._blockRange._endId = _mintingCondition
                    ._blockRange
                    ._endId;
                newsaleInstance._whitelistMerkleRoot = _mintingCondition
                    ._whitelistMerkleRoot;
                newsaleInstance._minters = _mintingCondition._minters;
                sales._set(_mintingConditionId, newsaleInstance);
                setBaseURI(
                    _mintingCondition._tokenRange,
                    _mintingCondition._baseURI
                );
                setRoyaltyInfo(
                    _mintingCondition._tokenRange,
                    _mintingCondition._royaltyReceiver,
                    _mintingCondition._royaltyFraction
                );
                emit MintingConditionSet(_mintingConditionId, newsaleInstance);
                // updating inactivated minting condition
            } else {
                commonValidation(_mintingCondition);
                _newlySet(_mintingConditionId, _mintingCondition);
                emit MintingConditionSet(
                    _mintingConditionId,
                    _mintingCondition
                );
            }
        }
    }

    /**
     * @notice Set a minting condition newly
     * @param _mintingConditionId the minting condition id
     * @param _mintingCondition The minting condition to be set
     */
    function _newlySet(
        uint256 _mintingConditionId,
        EnumerableSale.MintingConditionStruct calldata _mintingCondition
    ) private {
        sales._set(_mintingConditionId, _mintingCondition);
        setBaseURI(_mintingCondition._tokenRange, _mintingCondition._baseURI);
        setRoyaltyInfo(
            _mintingCondition._tokenRange,
            _mintingCondition._royaltyReceiver,
            _mintingCondition._royaltyFraction
        );
    }

    /**
     * @notice Return the minting condition.
     * @param _mintingConditionId the minting condition id
     * @return a tuple of (Range, Range, Range, address[], bytes32,
     * uint256, uint256, string, address, uint96)
     */
    function mintingCondition(uint256 _mintingConditionId)
        external
        view
        virtual
        returns (EnumerableSale.MintingConditionStruct memory)
    {
        return sales._get(_mintingConditionId);
    }

    /**
     * @notice Get all minting conditions id.
     * @return idBatch The array of all sale/minting condition ids
     */
    function mintingConditionIdBatch()
        external
        view
        virtual
        returns (uint256[] memory)
    {
        uint256[] memory idBatch = new uint256[](sales._length());
        for (uint256 i = 0; i < sales._length(); ++i) {
            (idBatch[i], ) = sales._at(i);
        }
        return idBatch;
    }

    /**
     * @notice close and update infor + flag
     * @param _mintingConditionId The minting-condition/sale Id
     * @param _tokenRange The token range distributed (could be less than what's configured)
     */
    function _closeSale(
        uint256 _mintingConditionId,
        EnumerableSale.Range memory _tokenRange,
        bool _unsatisfactory
    ) private {
        mintedRanges.push(_tokenRange);
        sales._tokenTrackerReset(_mintingConditionId);
        sales._setClosedState(_mintingConditionId, true);
        // correct token range information if sale ended unsatisfactorily
        if (_unsatisfactory) {
            EnumerableSale.MintingConditionStruct memory newsaleInstance = sales
                ._get(_mintingConditionId);
            newsaleInstance._tokenRange = _tokenRange;
            sales._set(_mintingConditionId, newsaleInstance);
        }
    }

    /**
     * @notice mint for receivers in batch
     * @param _mintingConditionId The minting-condition/sale id
     * @param _receivers The NFT receiver list
     * @param _amountPerEach The amount for each receiver
     * @param _clientIds The list of client Id
     */
    function _mint(
        uint256 _mintingConditionId,
        address[] memory _receivers,
        uint256 _amountPerEach,
        uint256[] memory _clientIds
    ) private {
        uint256 tokenId;
        // receivers list shouldn't be too big
        for (uint256 i = 0; i < _receivers.length; ++i) {
            for (uint256 j = 0; j < _amountPerEach; ++j) {
                tokenId =
                    sales._get(_mintingConditionId)._tokenRange._startId +
                    sales._tokenTrackerCurrent(_mintingConditionId);
                _safeMint(_receivers[i], tokenId);
                sales._tokenTrackerIncrement(_mintingConditionId);
                if (_clientIds.length != 0) {
                    tokenIdClientId[tokenId] = _clientIds[
                        _amountPerEach * i + j
                    ];
                }
            }
        }
    }

    /**
     * @notice refund
     * @param fund The fund
     */
    function _refund(uint256 fund) private {
        if (fund != 0) {
            (bool sent, ) = payable(_msgSender()).call{value: fund}("");
            require(sent, "NS28");
        }
    }

    /**
     * @notice The minted tokens belong to msg.sender if whitelist mode enabled and belongs to receivers
     * if minters mint.
     * The remaining coin after minting is refunded.
     * @dev Mint the token with the native coin.
     *
     * @param _mintingConditionId The id given by the contract for each successful minting condition set
     * @param _receivers The list to receve NFT when minters mint
     * @param _amountPerAddress The number of tokens to mint
     * @param _clientIds An array of clientIds that should be a subset of mintingCondition.clientIdRange.
     * @param _merkleProof The proof that msg.sender is in the whitelist.
     */
    function mint(
        uint256 _mintingConditionId,
        address[] calldata _receivers,
        uint256 _amountPerAddress,
        uint256[] calldata _clientIds,
        bytes32[] calldata _merkleProof
    ) external payable virtual nonReentrant {
        require(_amountPerAddress != 0, "NS30");
        require(
            sales._contains(_mintingConditionId),
            string(abi.encodePacked("NS22, ", _mintingConditionId.toString()))
        );
        require(!sales._getClosedState(_mintingConditionId), "NS23");
        EnumerableSale.MintingConditionStruct memory sale = sales._get(
            _mintingConditionId
        );
        require(sale._blockRange._startId <= block.number, "NS24");
        require(block.number <= sale._blockRange._endId, "NS32");

        uint256 tokenNumPC;
        uint256 remainTokenNum = sales._totalToken(_mintingConditionId) -
            sales._tokenTrackerCurrent(_mintingConditionId);
        // validate minters and mint to receivers if minters make the call
        if (
            sale._minters.length != 0 &&
            sales._isAMinter(_mintingConditionId, _msgSender()) &&
            (_receivers.length > 0)
        ) {
            require(
                msg.value >=
                    (sale._price * _amountPerAddress * _receivers.length),
                "NS25"
            );
            require(
                remainTokenNum >= _amountPerAddress * _receivers.length,
                string(abi.encodePacked("NS26, ", remainTokenNum.toString()))
            );
            for (uint256 i = 0; i < _receivers.length; ++i) {
                tokenNumPC = sales._getWhoMintedHowmany(
                    _mintingConditionId,
                    _receivers[i]
                );
                require(
                    (tokenNumPC + _amountPerAddress) <=
                        sale._maximumAmountPerAddress,
                    string(
                        abi.encodePacked(
                            "NS27, ",
                            sale._maximumAmountPerAddress.toString()
                        )
                    )
                );
            }
            sales._validateClientId(
                _mintingConditionId,
                _clientIds,
                _amountPerAddress,
                _receivers.length
            );

            _mint(
                _mintingConditionId,
                _receivers,
                _amountPerAddress,
                _clientIds
            );

            // record amount of tokens per person
            for (uint256 i = 0; i < _receivers.length; ++i) {
                tokenNumPC = sales._getWhoMintedHowmany(
                    _mintingConditionId,
                    _receivers[i]
                );
                sales._setWhoMintedHowmany(
                    _mintingConditionId,
                    _receivers[i],
                    tokenNumPC + _amountPerAddress
                );
            }

            // all tokens in range have been minted
            if (remainTokenNum == 0) {
                _closeSale(_mintingConditionId, sale._tokenRange, false);
            }

            _refund(
                msg.value -
                    (sale._price * _amountPerAddress * _receivers.length)
            );

            //validate whitelist program and mint to caller
        } else {
            if (sale._whitelistMerkleRoot != reservedMerkleRoot) {
                bytes32 merkleLeaf = keccak256(abi.encodePacked(_msgSender()));
                require(
                    MerkleProofUpgradeable.verify(
                        _merkleProof,
                        sale._whitelistMerkleRoot,
                        merkleLeaf
                    ),
                    "NS29"
                );
            }

            require(msg.value >= (sale._price * _amountPerAddress), "NS25");
            require(
                remainTokenNum >= _amountPerAddress,
                string(abi.encodePacked("NS26, ", remainTokenNum.toString()))
            );
            tokenNumPC = sales._getWhoMintedHowmany(
                _mintingConditionId,
                _msgSender()
            );
            require(
                (tokenNumPC + _amountPerAddress) <=
                    sale._maximumAmountPerAddress,
                string(
                    abi.encodePacked(
                        "NS27, ",
                        sale._maximumAmountPerAddress.toString()
                    )
                )
            );
            sales._validateClientId(
                _mintingConditionId,
                _clientIds,
                _amountPerAddress,
                1
            );

            address[] memory user = new address[](1);
            user[0] = _msgSender();
            _mint(_mintingConditionId, user, _amountPerAddress, _clientIds);
            sales._setWhoMintedHowmany(
                _mintingConditionId,
                _msgSender(),
                tokenNumPC + _amountPerAddress
            );

            // all tokens in range have been minted
            if (
                sales._tokenTrackerCurrent(_mintingConditionId) ==
                sales._totalToken(_mintingConditionId)
            ) {
                _closeSale(_mintingConditionId, sale._tokenRange, false);
            }

            _refund(msg.value - (sale._price * _amountPerAddress));
        }
    }

    /* UPDATE: a set of ERC721 functions added modifiers from OpenSea
     * making the Contract Royalty configurable in their marketplace
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        virtual
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        virtual
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        virtual
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        virtual
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}