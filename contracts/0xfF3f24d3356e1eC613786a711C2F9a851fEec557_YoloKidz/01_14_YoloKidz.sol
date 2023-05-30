// SPDX-License-Identifier: MIT
/*
________________ ▄▄ ____________________________________
________________█▌ ░▓▄▄▄▄▄▄▄▄▄▄▄▄_______________________
________________ ▓▄▓▓▓▓█████▓▓█▓▓█▄_____________________
________________▄███▓███████████▓█▓█____________________
_______________█████████████████████____________________
______________██████████████████████ ___________________
______________██████████▀▀▀▄_▄▀▀██▀_____________________
______________▀█████▀███  █ ▒ █ █▄______________________
________________▀▀██▄█░░▀ ▄   ▄  █______________________
___________________▀██▄░   ▀▀▀  ▄▀______________________
__________________ ▄▀▀▀▀▀▀▄▄▄▀█▀▄ ______________________
__________________█   █▒       █ █______________________
__________________█▀▀▀██       █▀█______________________
__________________█   ▀█████████ █______________________
__________________▀▄▄▄██▌░█▌▒░█▄▄▀______________________
_____________________███████████▄ ______________________
_____________________████████████_______________________
________________________________________________________
_▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ __▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄_
_█  ██  █▀    ▀█  █▀    ▀█__█  ██  █    █    ▀██      █_
_█      █  ██  █  █  ██  █__█     ███  ██  ██  ███▀ ▄██_
_█▀▀▀▀ ▄█  ▀▀  █  ▀▀▀▀▀  █__█  ██  ██  ▀█  ▀▀  █▀  ▀▀▀█_
_█▄▄▄▄█▀▀█▄▄▄▄█▀█▄▄▄▄▄▄▄█▀__█▄▄██▄▄█▄▄▄▄█▄▄▄▄▄▄█▄▄▄▄▄▄█_
________________________________________________________
*/

pragma solidity ^0.8.0;

import "contracts/ERC721AQueryable.sol";
import "contracts/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IMetadata {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract YoloKidz is ERC721AQueryable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;
    
    uint256 public collectionSize;
    uint256 public maxPerAddressDuringMint;
    uint256 public maxPerWhitelistMint;
    uint256 public amountForTeam;
    uint256 public maxPerTxPublic;
    uint256 public amountPerClaim;
    bool public hasDevMinted;
    bool public isFrozenMetadata;

    bytes32 public whitelistRoot;
    bytes32 public claimRoot;
    string public PROVENANCE_HASH = "d928faafec29e3a82a215331f167d57cdeed25adcd6554dafac3e6d9847f37c8";

    struct SaleConfig {
        uint32 claimStartTime;
        uint32 whitelistSaleStartTime;
        uint32 publicSaleStartTime;
        uint64 publicPrice;
        uint64 whitelistPrice;
    }
    SaleConfig public saleConfig;

    mapping(address => bool) public whitelistMinted;
    mapping(address => bool) public claimed;
    uint256 startingTokenId = 1;

    IMetadata public metadata;

    constructor(
        uint256 collectionSize_,
        uint256 maxPerAddressDuringMint_,
        uint256 maxPerWhitelistMint_,
        uint256 amountForTeam_,
        uint256 maxPerTxPublic_,
        bool hasDevMinted_,
        bytes32 whitelistRoot_,
        bytes32 claimRoot_,
        uint256 amountPerClaim_
    ) ERC721A("YOLO Kidz", "YOLOKidz") {
        collectionSize = collectionSize_;
        maxPerAddressDuringMint = maxPerAddressDuringMint_;
        maxPerWhitelistMint = maxPerWhitelistMint_;
        amountForTeam = amountForTeam_;
        maxPerTxPublic = maxPerTxPublic_;
        hasDevMinted = hasDevMinted_;
        whitelistRoot = whitelistRoot_;
        claimRoot = claimRoot_;
        amountPerClaim = amountPerClaim_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    /*
    |----------------------------|
    |------ Mint Functions ------|
    |----------------------------|
    */

    function whitelistMint(bytes32[] calldata whitelistProof, uint256 _numOfYoloKidz) external payable callerIsUser {
        uint256 price = uint256(saleConfig.whitelistPrice);
        uint256 saleStart = uint256(saleConfig.whitelistSaleStartTime);
        require(
            block.timestamp >= saleStart && 
            saleStart > 0, "whitelist sale has not begun yet");
        require(totalSupply() + _numOfYoloKidz <= collectionSize, "reached max supply");
        require(_numOfYoloKidz <= maxPerWhitelistMint, "exceeds mint allowance");
        require(whitelistMinted[msg.sender] == false, "already minted");
        require(MerkleProof.verify(whitelistProof, whitelistRoot, toBytes32(msg.sender)) == true, "invalid proof");

        whitelistMinted[msg.sender] = true;
        _safeMint(msg.sender, _numOfYoloKidz);
        refundIfOver(price * _numOfYoloKidz);
    }

    function publicSaleMint(uint256 _numOfYoloKidz) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 publicPrice = uint256(config.publicPrice);
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
        require(isPublicSaleOn(publicPrice, publicSaleStartTime), "public sale has not begun yet");
        require(totalSupply() + _numOfYoloKidz <= collectionSize, "reached max supply");
        require(_numberMinted(msg.sender) + _numOfYoloKidz <= maxPerAddressDuringMint, "can not mint this many");
        require(_numOfYoloKidz <= maxPerTxPublic, "too many per tx");

        _safeMint(msg.sender, _numOfYoloKidz);
        refundIfOver(publicPrice * _numOfYoloKidz);
    }

    function claim(bytes32[] calldata claimProof) external callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 claimLiveTime = uint256(config.claimStartTime);
        
        require(block.timestamp >= claimLiveTime, "claim period has not begun yet");
        require(totalSupply() + amountPerClaim <= collectionSize, "reached max supply");
        require(claimed[msg.sender] == false, "already claimed");
        require(MerkleProof.verify(claimProof, claimRoot, toBytes32(msg.sender)) == true, "invalid proof");

        claimed[msg.sender] = true;
        _safeMint(msg.sender, amountPerClaim);
    }

    /*
    |----------------------------|
    |---------- Reads -----------|
    |----------------------------|
    */

      // returns any extra funds sent by user, protects user from over paying
    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    // check if public sale has started
    function isPublicSaleOn(
        uint256 publicPriceWei,
        uint256 publicSaleStartTime
    ) public view returns (bool) {
        return
        publicPriceWei != 0 &&
        block.timestamp >= publicSaleStartTime;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /*
    |----------------------------|
    |----- Owner  Functions -----|
    |----------------------------|
    */

        // setup minting info
    function setupSaleInfo(
        uint32 claimStartTime,
        uint32 whitelistSaleStartTime,
        uint32 publicSaleStartTime,
        uint64 publicPrice,
        uint64 whitelistPrice

    ) external onlyOwner {
        saleConfig = SaleConfig(
        claimStartTime,
        whitelistSaleStartTime,
        publicSaleStartTime,
        publicPrice,
        whitelistPrice
        );
    }

    function freezeMetadata() external onlyOwner{
        require(!isFrozenMetadata, "Metadata is already frozen for this collection");
        isFrozenMetadata = true;
    }

    function setMetadataContract(address _contractAddress) external onlyOwner{
      require(!isFrozenMetadata, "Metadata is final for this collection");
      metadata = IMetadata(_contractAddress);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMaxPerTxPublic(uint256 _amount) external onlyOwner {
        maxPerTxPublic = _amount;
    }

    function setMaxPerWhitelistMint(uint256 _amount) external onlyOwner {
        maxPerWhitelistMint = _amount;
    }

    function setCollectionSize(uint256 _maxCollectionSize) external onlyOwner {
        require(totalSupply() < collectionSize, "Sold Out!");
        require(_maxCollectionSize >= totalSupply(), "Cannot be lower than supply");
        collectionSize = _maxCollectionSize;
    }

    function tokenURI(uint256 tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      if(address(metadata) != address(0x0)) {
        return metadata.tokenURI(tokenId);
      }
      return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, tokenId.toString())) : "";
    }

    // for team/promotions/giveaways
    function devMint() external onlyOwner {
        require(
        totalSupply() + amountForTeam <= collectionSize,
        "too many already minted before dev mint"
        );
        require(
        hasDevMinted == false, "dev has already claimed"
        );
        _safeMint(msg.sender, amountForTeam);
        hasDevMinted = true;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

    function setWhitelistRoot(bytes32 _whitelistRoot) external onlyOwner {
        whitelistRoot = _whitelistRoot;
    }

    function setClaimRoot(bytes32 _claimRoot) external onlyOwner {
        claimRoot = _claimRoot;
    }


    /*
    |----------------------------|
    |---- Operator Overrides ----|
    |----------------------------|
    */

    function setApprovalForAll(address operator, bool approved) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _startTokenId() internal override(ERC721A) view returns (uint256) {
        return startingTokenId;
    }
}