// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error SaleClosed();
error WhitelistSaleSoldOut();
error PublicSaleSoldOut();
error ExceedsWLUserAllowance();
error ExceedsPubUserAllowance();
error InsufficientEth();
error InvalidSignature();
error AmountError();
error OutOfStock();
error ExceedsMaxSupply();
error ExceedsGiftsMax();
error NoBalance();
error ProvenanceLocked();
error WhitelistSaleClosed();
error PublicSaleClosed();
error ReallocationError();


contract NineTalesTwo is ERC721A, Ownable, ReentrancyGuard {
    
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant NTT_MAX_SUPPLY = 4444;
    uint256 public NTT_WHITELIST = 3841;
    uint256 public NTT_GIFT = 100;
    uint256 public NTT_PUBLIC = 503;
    
    uint256 public NTT_PUBLIC_PER_USER = 2;
    uint256 public NTT_WHITELIST_PRICE = 0.089 ether;
    uint256 public NTT_PUBLIC_PRICE = 0.099 ether;
        
    string private _finalProvenanceHash;
    string private _baseTokenURI;
    address private _ownerAddress;
    address private _signerAddress;

    uint64 public giftedAmount;
    uint64 public publicAmountMinted;
    uint64 public whitelistAmountMinted;

    bool public saleIsLive = false;
    bool public whitelistLive = true;
    bool public publicSaleLive = true;
    bool public provenanceLocked = false;

    struct SaleInfo {
        uint256 _NTT_MAX_SUPPLY;
        uint256 _NTT_WHITELIST;     
        uint256 _NTT_PUBLIC;
        uint256 _NTT_WHITELIST_PRICE;
        uint256 _NTT_PUBLIC_PRICE;
        uint256 _NTT_PUBLIC_PER_USER;
        bool _saleIsLive;
        bool _whitelistLive;
        bool _publicSaleLive;
        uint256 _totalSupply;
        uint64 _publicAmountMinted;
        uint64 _whitelistAmountMinted;
    }
    
    constructor(
        address safeAddr,
        address signerAddr,
        string memory unrevealed

    ) ERC721A("NineTales Phase 1", "NTP1") {
        _ownerAddress = safeAddr;
        _signerAddress = signerAddr;
        _baseTokenURI = unrevealed;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier liveSale {
        if(!saleIsLive) revert SaleClosed();
        _;
    }

    modifier tokenAmountValid(uint64 tokenQuantity) {
        if(tokenQuantity < 1) revert AmountError();
        if(_totalMinted() + tokenQuantity > NTT_MAX_SUPPLY) revert OutOfStock();
        _;
    }

    function max(uint256 a, uint256 b) private pure returns(uint256) {
        return a >= b ? a : b;
    }

    function hashTx(address sender, uint256 tokenLimit) private pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(sender, tokenLimit));
        return hash;
    }
  
    function matchAddressSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signerAddress == hash.toEthSignedMessageHash().recover(signature);
    }

    function whitelistMint(bytes memory signature, uint64 tokenQuantity, uint256 tokenLimit) external payable 
    liveSale callerIsUser tokenAmountValid(tokenQuantity) {

        if(!whitelistLive) revert WhitelistSaleClosed();
        if(whitelistAmountMinted + tokenQuantity > NTT_WHITELIST) revert WhitelistSaleSoldOut();
        if(msg.value < NTT_WHITELIST_PRICE * tokenQuantity) revert InsufficientEth();

        uint64 mintedCount = _getAux(msg.sender);
        if(mintedCount + tokenQuantity > tokenLimit) revert ExceedsWLUserAllowance();

        if(!matchAddressSigner(hashTx(msg.sender, tokenLimit), signature)) revert InvalidSignature();

        _safeMint(msg.sender, tokenQuantity);
        _setAux(msg.sender, mintedCount + tokenQuantity); 
        whitelistAmountMinted += tokenQuantity;        
    } 

    function publicMint(uint64 tokenQuantity) external payable liveSale callerIsUser tokenAmountValid(tokenQuantity) {

        if(!publicSaleLive) revert PublicSaleClosed();
        if(publicAmountMinted + tokenQuantity > NTT_PUBLIC) revert PublicSaleSoldOut();
        if(msg.value < NTT_PUBLIC_PRICE * tokenQuantity) revert InsufficientEth();

        if(tokenQuantity + max(0, _numberMinted(msg.sender) - _getAux(msg.sender)) > NTT_PUBLIC_PER_USER) revert ExceedsPubUserAllowance();

        _safeMint(msg.sender, tokenQuantity);        
        publicAmountMinted += tokenQuantity;
    }

    function gift(address[] calldata winners) external onlyOwner {

        if(_totalMinted() + winners.length > NTT_MAX_SUPPLY) revert ExceedsMaxSupply();
        if(giftedAmount + winners.length > NTT_GIFT) revert ExceedsGiftsMax(); 

        for (uint256 i = 0; i < winners.length; i++) {
            _safeMint(winners[i], 1);
        }

        giftedAmount += uint64(winners.length);
    }

    function batchGift(address user, uint64 tokenQuantity) external onlyOwner {
        if(_totalMinted() + tokenQuantity > NTT_MAX_SUPPLY) revert ExceedsMaxSupply();
        if(giftedAmount + tokenQuantity > NTT_GIFT) revert ExceedsGiftsMax(); 

        _safeMint(user, tokenQuantity);        
        giftedAmount += tokenQuantity;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if(balance <= 0) revert NoBalance();

        (bool success, ) = _ownerAddress.call{value: balance}("");
        require(success, "TRANSFER_FAIL");
    }

    function setFinalProvenanceHash(string memory provenanceHash) external onlyOwner {
      
        if(provenanceLocked) revert ProvenanceLocked();

        _finalProvenanceHash = provenanceHash;
        provenanceLocked = true;
    }

    function getFinalProvenanceHash() external view returns(string memory){
        return _finalProvenanceHash;
    }

    function changeSaleStatus() external onlyOwner {
        saleIsLive = !saleIsLive;
    }

    function changeWhitelistStatus() external onlyOwner {
        whitelistLive = !whitelistLive;
    }

    function changePublicSaleStatus() external onlyOwner {
        publicSaleLive = !publicSaleLive;
    }

    function setSignerAddress(address _addr) external onlyOwner {
        _signerAddress = _addr;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setNttPublicUserLimit(uint256 _limit) external onlyOwner {
        NTT_PUBLIC_PER_USER = _limit;
    }

    function setPublicPrice(uint256 _salePrice) external onlyOwner {
        NTT_PUBLIC_PRICE = _salePrice;
    }

    function setWhitelistPrice(uint256 _salePrice) external onlyOwner {
        NTT_WHITELIST_PRICE = _salePrice;
    }
  
    function reallocateTokens(uint256 whitelistAmount, uint256 publicAmount, uint256 giftAmount) external onlyOwner{
      if ((whitelistAmount + publicAmount + giftAmount) != NTT_MAX_SUPPLY) revert ReallocationError();

      NTT_WHITELIST = whitelistAmount;
      NTT_PUBLIC = publicAmount;
      NTT_GIFT = giftAmount;      

    }

    function getUserMintedInfo(address user) external view returns (uint256, uint256, uint256) {
        uint256 userPublicMintedCount = max(0, _numberMinted(user) - _getAux(user));
        return(_numberMinted(user),_getAux(user),userPublicMintedCount);
    }

    function getSaleInfo() external view returns (SaleInfo memory) {
        SaleInfo memory  currentInfo = SaleInfo(NTT_MAX_SUPPLY, NTT_WHITELIST, NTT_PUBLIC, NTT_WHITELIST_PRICE, NTT_PUBLIC_PRICE, NTT_PUBLIC_PER_USER, saleIsLive, whitelistLive, publicSaleLive, totalSupply(), publicAmountMinted, whitelistAmountMinted);
        return currentInfo;
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
      return _ownershipOf(tokenId);
    }    

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}