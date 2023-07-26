// SPDX-License-Identifier: MIT
// By @marcu5aurelius
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Permutations is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable maxPerAddressDuringMint = 5;
    uint256 public maxPublicSaleAmount = 944;
    uint256 public collectionSize = 999;

    struct SaleConfig {
        uint32 freeMintSaleStartTime;
        uint32 whitelistSaleStartTime;
        uint32 publicSaleStartTime;
        uint64 whitelistPrice;
        uint64 publicPrice;
        uint32 publicSaleKey;
    }

    bytes32 private whitelistRoot;
    mapping(address => bool) private whitelistClaimed;
    bytes32 private freeMintRoot;
    mapping(address => bool) private freeMintClaimed;

    SaleConfig public saleConfig;

    constructor(string memory name_, string memory symbol_)
        ERC721A(name_, symbol_)
    {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function whitelistMint(bytes32[] calldata _proof)
        external
        payable
        callerIsUser
    {
        uint256 price = uint256(saleConfig.whitelistPrice);
        require(isWhitelistSaleOn(), "whitelist sale has not begun yet");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, whitelistRoot, leaf),
            "Invalid proof"
        );
        require(!whitelistClaimed[msg.sender], "You have already minted");
        require(
            totalSupply() + 1 <= maxPublicSaleAmount &&
                totalSupply() + 1 <= collectionSize,
            "reached max supply"
        );
        _safeMint(msg.sender, 1);
        whitelistClaimed[msg.sender] = true;
        require(msg.value >= price, "Need to send more ETH.");
    }

    function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey)
        external
        payable
        callerIsUser
    {
        SaleConfig memory config = saleConfig;
        uint256 publicSaleKey = uint256(config.publicSaleKey);
        uint256 publicPrice = uint256(config.publicPrice);
        require(isPublicSaleOn(), "public sale has not begun yet");
        require(
            publicSaleKey == callerPublicSaleKey,
            "called with incorrect public sale key"
        );
        require(
            totalSupply() + quantity <= maxPublicSaleAmount &&
                totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
        require(msg.value >= publicPrice * quantity, "Need to send more ETH.");
    }

    function freeMint(bytes32[] calldata _proof) external payable callerIsUser {
        require(isFreeMintOn(), "free mint sale has not begun yet");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, freeMintRoot, leaf),
            "Invalid proof"
        );
        require(!freeMintClaimed[msg.sender], "You have already minted");
        require(totalSupply() + 1 <= collectionSize, "reached max supply");
        _safeMint(msg.sender, 1);
        freeMintClaimed[msg.sender] = true;
    }

    function isWhitelistSaleOn() public view returns (bool) {
        return
            uint256(saleConfig.whitelistPrice) != 0 &&
            uint256(saleConfig.whitelistSaleStartTime) != 0 &&
            block.timestamp >= uint256(saleConfig.whitelistSaleStartTime);
    }

    function isPublicSaleOn() public view returns (bool) {
        return
            uint256(saleConfig.publicPrice) != 0 &&
            uint256(saleConfig.publicSaleKey) != 0 &&
            block.timestamp >= uint256(saleConfig.publicSaleStartTime);
    }

    function isFreeMintOn() public view returns (bool) {
        return
            uint256(saleConfig.freeMintSaleStartTime) != 0 &&
            block.timestamp >= uint256(saleConfig.freeMintSaleStartTime);
    }

    function setupWhitelist(uint64 whitelistPriceWei, uint32 timestamp)
        external
        onlyOwner
    {
        saleConfig.whitelistSaleStartTime = timestamp;
        saleConfig.whitelistPrice = whitelistPriceWei;
    }

    function setupPublicSale(
        uint32 key,
        uint64 publicPriceWei,
        uint32 publicSaleStartTime
    ) external onlyOwner {
        saleConfig.publicSaleKey = key;
        saleConfig.publicSaleStartTime = publicSaleStartTime;
        saleConfig.publicPrice = publicPriceWei;
    }

    function setupFreeMint(uint32 freeMintSaleStartTime) external onlyOwner {
        saleConfig.freeMintSaleStartTime = freeMintSaleStartTime;
    }

    function setWhitelistRoot(bytes32 _root) public onlyOwner {
        whitelistRoot = _root;
    }

    function setFreeMintRoot(bytes32 _root) public onlyOwner {
        freeMintRoot = _root;
    }

    string public metadataURI;
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function contractURI() public view returns (string memory) {
        return metadataURI;
    }

    function setMetadataURI(string memory _newMetadataURI) public onlyOwner {
        metadataURI = _newMetadataURI;
    }

    function setCollectionSize(uint256 _newCollectionSize) public onlyOwner {
        collectionSize = _newCollectionSize;
    }

    function setMaxPublicSaleAmount(uint256 _newMaxPublicSaleAmount)
        public
        onlyOwner
    {
        maxPublicSaleAmount = _newMaxPublicSaleAmount;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}