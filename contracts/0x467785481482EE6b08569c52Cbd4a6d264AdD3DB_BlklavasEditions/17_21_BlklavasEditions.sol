pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
///@author ReggieRumsfeld 


import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./operator-filter/RevokableDefaultOperatorFilterer.sol";



error AlreadyClaimed(bytes32 root, address claimer);
error BatchDataCorrupt();
error CanNotSetMaxSupplyUnderCurrentSupply(uint256 attemptingToSet, uint256 alreadyMinted); 
error CanNotIncreaseSupply(uint256 attemptingToSet, uint256 currentMaxSupply);
error MaxAmountPerTxExceeded(uint256 mintAmount, uint256 maxMintAmountPerTx);
error MaxSupplyExceeded();
error MaxSupplyNotSet(uint256 tokenID);
error MsgValueTooLow(uint256 valueSend, uint256 totalCost);
error NotACurrentDrop(bytes32 root);
error PriceNotSetForToken();
error RegulatedBurnNotAllowed();
error StartingIdCanNotHaveSupply();
error SlotValueSameAsInput(uint256 idValue);
error SplitsCanOnlyContainIncreasingIDs();


struct RegulatedBurn {
    bool allowed;
    bool decreaseMaxSupply;
}


contract BlklavasEditions is ERC1155Supply, RevokableDefaultOperatorFilterer, Ownable, Pausable, ReentrancyGuard, ERC2981 {
  using Strings for uint256;
    
    /// @dev ROOT => Address(this) => Uint256 > 0 means: 
    /// 1.) drop is ON!!! 2.) gives you the starting ID (inlcusive)
    mapping (bytes32 => mapping (address => uint256)) private _rootToClaimed;

    mapping (uint256 => uint256) public price;
    
    mapping (uint256 => uint256) private _maxSupply;

    /// @dev OPTIONAL Batch or Token specific URIS:

    mapping(uint256 => string) private _tokenURIs;
    
    uint256[] public uriSplits = [0, 0, 0, 0];

    string private _baseURI = "";

    string private _uriSuffix = "";

    /// --- ///

    uint256 public maxMintAmountPerTx = 10;

    RegulatedBurn private regulatedBurn = RegulatedBurn(false, false);

    event WhiteListClaimStarted(bytes32 indexed root, uint256 startingId);
    event WhiteListClaimEnded(bytes32 indexed root);

    /// @notice with regard to claimable and mintable:
    /// claimable doesn't check if ids in the drop are "already" publicly mintable;
    /// for each claim it would have to iterate over the IDs in the claim to check 
    /// if supply is set (which makes an ID publicly mintable).
    /// There is no supply check on each claim (open ended supply during claim, save for 
    /// the last image).
    ///
    /// Mintable can't check if an ID is still claimable.
    /// It boils down to proper admin/management when activating/deactivating claim & mints
    /// Use a web2 interface with offchain side-wheels.

    modifier claimable(bytes32 root, address claimer) {
        if(!dropIsOn(root)) revert NotACurrentDrop(root);
        if(!unClaimed(root, claimer)) revert AlreadyClaimed(root, claimer);
        _;
    }

    modifier mintable(uint256 mintAmount, uint256 tokenId) {
        //Payment check
        uint price_ = price[tokenId];
        if(price_ == 0) revert PriceNotSetForToken();
        uint256 totalCost = price[tokenId] * mintAmount;
        if(msg.value < totalCost) revert MsgValueTooLow(msg.value, totalCost);
        // seperate from _supplyCheck(), since that function is also used by adMint():
        uint256 maxSupply_ = _maxSupply[tokenId];
        if(maxSupply_ == 0) revert MaxSupplyNotSet(tokenId);
        if(mintAmount > maxMintAmountPerTx) revert MaxAmountPerTxExceeded(mintAmount, maxMintAmountPerTx); 
        _supplyCheck(mintAmount, tokenId, maxSupply_);
        _;
    }

    constructor(uint96 feeNumerator, address receiver, string memory uri_) ERC1155(uri_){
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /////////////////////
    // ADMIN - GENERAL //
    /////////////////////

    function withdraw(address payable recipient) external onlyOwner {
        (bool sent, ) = recipient.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setRegulatedBurn(bool allowed, bool decrease) external onlyOwner {
        regulatedBurn = RegulatedBurn(allowed, decrease);
    }

    function setRegulatedBurnAllowed(bool allowed_) external onlyOwner {
        regulatedBurn.allowed = allowed_;
    }

    function setRegulatedBurnDecreaseMaxSupply(bool decrease) external onlyOwner {
        regulatedBurn.decreaseMaxSupply = decrease;
    }

    ////////////////////////
    // ADMIN - COLLECTION //
    ////////////////////////

    /// @notice OFFCHAIN SIDE WHEELS FOR ADMIN PROVIDED
    /// DIRECT ENGAGEMENT IS ERROR-PRONE (TOKEN ID OVERLAP / PROPPER END OF CLAIM)

    function setPrice(uint256 tokenId, uint256 price_) public onlyOwner {
        price[tokenId] = price_;
    }

    /// @dev Only perform sober: can't increase!!
    /// @notice Also gas efficient admin burn: lower supply upto total supply
    function setMaxSupply(uint256 tokenId, uint256 supplyAmount) public onlyOwner {
        uint256 totalSupply_ = totalSupply(tokenId);
        if (supplyAmount < totalSupply_) revert CanNotSetMaxSupplyUnderCurrentSupply(supplyAmount, totalSupply_);
        uint256 maxSupply = _maxSupply[tokenId];
        if(maxSupply != 0 && supplyAmount > maxSupply) revert CanNotIncreaseSupply(supplyAmount, maxSupply);
        _maxSupply[tokenId] = supplyAmount;
    }

    function setPriceAndMaxSupplyBatch(uint256[] calldata tokenIds, uint256[] calldata supplyAmounts, uint256 price_) external {
        if(tokenIds.length != supplyAmounts.length) revert BatchDataCorrupt();
        for(uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            setMaxSupply(tokenId, supplyAmounts[i]);
            setPrice(tokenId, price_);
        }
    }

    function setMaxSupplyBatch(uint256[] calldata tokenIds, uint256[] calldata supplyAmounts) external {
        if(tokenIds.length != supplyAmounts.length) revert BatchDataCorrupt();
        for(uint256 i = 0; i < tokenIds.length; i++) {
            setMaxSupply(tokenIds[i], supplyAmounts[i]);
        }
    }

    function setPriceBatch(uint256[] calldata tokenIds, uint256 price_) external {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            setPrice(tokenIds[i], price_);
        }
    }

    function setMaxPerTx(uint256 newMax) external onlyOwner {
        maxMintAmountPerTx = newMax;
    }
 
    /// @param startingID the first tokenID in the drop, or 0 to turn off!
    function dropSwitch (bytes32 root, uint256 startingID) external onlyOwner {
        bool supply = _maxSupply[startingID] > 0 || totalSupply(startingID) > 0;
        if(startingID != 0 && supply) revert StartingIdCanNotHaveSupply();
        _dropSwitch(root, startingID);
        if(startingID > 0) {
          emit WhiteListClaimStarted(root, startingID);
        } else {
          emit WhiteListClaimEnded(root);
        }
    }

    ///////////////////////////
    // ADMIN: URI - METADATA //
    ///////////////////////////

    /// @notice Setting the token specific uri
    /// The tokenUri is prefixed by the baseUri and appended by the suffix
    function setTokenURI(uint256 tokenId, string calldata tokenURI) public onlyOwner {
        _tokenURIs[tokenId] = tokenURI;
    }

    /// @notice Setting the base uri 
    /// This the prefix for all token specific uris
    function setBaseURI(string calldata baseURI) public onlyOwner {
        _baseURI = baseURI;
    }

    function setSuffixURI(string calldata uriSuffix) public onlyOwner {
        _uriSuffix = uriSuffix;
    }

    function setBaseAndSuffix(string calldata baseURI, string calldata uriSuffix) public {
        setBaseURI(baseURI);
        setSuffixURI(uriSuffix);
    }

    function setFullTokenURI(
        uint256 tokenId, 
        string calldata tokenURI, 
        string calldata baseURI, 
        string calldata uriSuffix
    ) external {
        setTokenURI(tokenId, tokenURI);
        setBaseAndSuffix(baseURI, uriSuffix);
    }

    /// @notice setting the general uri, which is shown when a tokenId maps to its default value ""
    /// format https://token-cdn-domain/{id}.json - ipfs://Qmf6XY7fBnd8yQcBmC1nRE6Wvnm87dwmRixStwvf7QNVWx/{id}.json
    function setGeneralURI(string calldata uri_) external onlyOwner {
        _setURI(uri_); 
    }

    /// @notice token Specific overrule split,  no need to set split for non batch ids
    /// @dev make sure that there is a tokenURI for the splitvalue to be set (offchain sidewheels)
    function pushSplit(uint256 tokenId) external onlyOwner {
        uint256 length = uriSplits.length;
        if(length > 0 && uriSplits[length - 1] > tokenId) revert SplitsCanOnlyContainIncreasingIDs();
        uriSplits.push(tokenId);
    }

    /// See comments pushSplit() above
    function setSplit(uint256[] calldata splitArray) external onlyOwner {
        uint256 length = splitArray.length;
        if(length > 0) {
            for(uint256 i = 1; i < length; i++) {
              if(splitArray[i] < splitArray[i - 1]) revert SplitsCanOnlyContainIncreasingIDs();
            }
        }
        uriSplits = splitArray;
    }

    function uri(uint256 id) public view override returns (string memory) {
        string memory tokenURI = _tokenURIs[id]; // Checking for token specific
        if(bytes(tokenURI).length > 0) return _uri(tokenURI); // Perfect hit
        uint256 length = uriSplits.length;
        if(length == 0) return super.uri(id); // Splits not set, returning general
        uint256 lastID = uriSplits[length - 1];
        if(id>lastID) return super.uri(id); // Id over last ID in split, returning general
        for(uint256 i = 0; i < length; i++) {
            uint256 splitId = uriSplits[i];
            if(splitId > id) return _uri(_tokenURIs[splitId]); // Batch hit
        }
        return super.uri(id);    
    }

    function _uri(string memory tokenURI) internal view returns (string memory uri_) {
        uri_ = string(abi.encodePacked(_baseURI, tokenURI, _uriSuffix));
    } 

    //////////////////////////////
    // ADMIN: ERC2981 - ROYALTY //
    //////////////////////////////

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }


    /////////////////
    // ADMIN: MINT //
    /////////////////

    /// @dev forgoing most of the restraint on the other mint/claims
    /// SAFE for _supplyCheck()
    /// designed for cheap(er) airdrops
    function adMint(address recipient, uint256 amount, uint256 tokenId) external onlyOwner {
        uint256 maxSupply = _maxSupply[tokenId];
        if(maxSupply > 0) _supplyCheck(amount, tokenId, maxSupply);
        _adMint(amount, tokenId, recipient);
    } 

    function adMintBatchRecipients(uint256 amount, address[] calldata recipients, uint256 tokenId) external onlyOwner {
        uint256 maxSupply = _maxSupply[tokenId];
        uint256 length = recipients.length;
        if(maxSupply > 0) _supplyCheck(amount * length, tokenId, maxSupply);
        for(uint256 i = 0; i < length ; i++) {
            _adMint(amount, tokenId, recipients[i]);
        }
    }

    function _adMint(uint amount, uint256 tokenId, address recipient) internal {
        _mint(recipient, tokenId, amount, "0");
    }

    /////////////////////////
    // CLAIM - MINT - BURN //
    /////////////////////////

    /// @dev saving on admin tx's cost by using dropAmount param as marker for amount of ID's in drop
    function claim(uint256 dropAmount, uint256 ltdSupply, bytes32 root, bytes32[] calldata _merkleProof) external payable {
        _claim(dropAmount, ltdSupply, root, _msgSender(), _merkleProof);
    }

    /// @notice "gas-less" version: Claiming on behalf of third party
    function claim(uint256 dropAmount, uint256 ltdSupply, bytes32 root, address recipient, bytes32[] calldata _merkleProof) external payable {
        _claim(dropAmount, ltdSupply, root, recipient, _merkleProof);
    }

    function _claim(
        uint256 dropAmount,
        uint256 ltdSupply, 
        bytes32 root, 
        address recipient, 
        bytes32[] calldata _merkleProof
    ) internal whenNotPaused() claimable(root, recipient) {
          bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(recipient, dropAmount, ltdSupply, msg.value))));
          require(MerkleProof.verify(_merkleProof, root, leaf), 'Invalid proof!');
          _claimDrop(root, recipient); //set Claimed for this drop/root
          _mint(recipient, randomID(root, dropAmount, ltdSupply), 1, "0");
      }

    /// @dev nonReentrant to avoid circumvention of restrictions like MaxMintPerTX 
    function mint(uint256 tokenID, uint256 amount) public payable whenNotPaused() mintable(amount, tokenID) nonReentrant() {
        _mint(_msgSender(), tokenID, amount, "0");
    }

    /// @notice "gas-less" version: Minting on behalf of third party
    function mint(uint256 tokenID, uint256 amount, address recipient) public payable whenNotPaused() mintable(amount, tokenID) nonReentrant() {
        _mint(recipient, tokenID, amount, "0");
    }

    function burn(address from, uint256 tokenId, uint256 amount) public nonReentrant {
        uint256 currentMaxSupply = _maxSupply[tokenId];
        if(currentMaxSupply == 0) revert MaxSupplyNotSet(tokenId);
        RegulatedBurn memory regulatedBurn_ = regulatedBurn;
        if(!regulatedBurn_.allowed) revert RegulatedBurnNotAllowed();     
        _burn(from, tokenId, amount);
        if(regulatedBurn_.decreaseMaxSupply) {
          setMaxSupply(tokenId, currentMaxSupply - amount);
        } 
    }

    function burn(uint256 tokenId, uint256 amount) external {
        burn(_msgSender(), tokenId, amount);
    }

    /////////////
    // GETTERS //
    /////////////

    function dropIsOn(bytes32 root) public view returns (bool) {
        return (_claimValue(root, address(this)) > 0);
    }

    function unClaimed(bytes32 root, address claimer) public view returns (bool) {
        return (_claimValue(root, claimer) == 0);
    }

    function getMaxSupply(uint256 tokenId) public view returns (uint256) {
        uint256 supply = _maxSupply[tokenId];
        if(supply == 0) revert MaxSupplyNotSet(tokenId);
        return supply;
    } 

    ///////////////////////////////
    // PSUEDO RANDOM ID SELECTOR //
    ///////////////////////////////

    function randomID(bytes32 root, uint256 dropAmount, uint256 ltdSupply) internal view returns (uint256 tokenID) {
        uint256 startingID = _claimValue(root, address(this));
        uint256 limitedID = startingID + dropAmount - 1; // only theoratical sub/overflow;
        uint256 plusID;
        if(totalSupply(limitedID) < ltdSupply) {
            plusID = _random() % (dropAmount);
        } else {
            plusID = _random() % (dropAmount -1);
        } 
        tokenID = startingID + plusID; //overflow only theoretical 
    }

    function _random() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp
        )));
    }

    /////////////////////
    // INTERNAL - MISC //
    /////////////////////

    function _dropSwitch(bytes32 root, uint256 startingID) internal {
        _setClaimedValue(root, startingID, address(this));
    }

    function _claimDrop(bytes32 root, address claimer) internal {
        // 1 being the claimed marker 
        _setClaimedValue(root, 1, claimer);
    }

    function _setClaimedValue(bytes32 root, uint256 idValue, address key) internal {
        _checkClaimSlot(root, idValue, key);
        _rootToClaimed[root][key] = idValue;
    }

    function _checkClaimSlot(bytes32 root, uint256 idValue, address key) internal view {
        if(_claimValue(root, key) == idValue) revert SlotValueSameAsInput(idValue);
    }

    /// @notice gets the value at the claim slot; 1 indicates claimed
    /// @dev the value at address(this) is the starting id of the drop the root corresponds to.
    function _claimValue(bytes32 root, address key) internal view returns (uint) {
        return _rootToClaimed[root][key];
    }

    /// @dev To avoid high gas costs we are foregoing this check during the claim period
    function _supplyCheck(uint256 mintAmount, uint256 tokenID, uint256 _maxSupply_) internal view {
        // at this point in code _maxSupply is set, and over totalSupply;
        uint256 available = _maxSupply_ - totalSupply(tokenID);
        if(mintAmount > available) revert MaxSupplyExceeded();   
    }

    //////////////////////////////
    //        OVERRIDES         //
    //////////////////////////////
    //
    // OPERATOR-FILTER-REGISTRY
    // https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/example/RevokableExampleERC1155.sol


    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function owner() public view override (Ownable, RevokableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC1155, ERC2981) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

}