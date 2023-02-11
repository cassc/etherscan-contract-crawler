// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DungeonInterior is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 999;
    uint256 public maxWhitelistSupply = 200;
    uint256 public maxPublicMintPerTx = 3;
    uint256 public maxWhitelistMintPerTx = 1;
    uint256 public claimedWhitelist = 0;
    uint256 public publicSalePrice = .003 ether;
    uint256 public whitelistSalePrice = 0 ether;
    bool public paused = true;

    string private baseURI;
    bytes32 private merkleRoot;

    mapping(address => uint256) public totalWhitelistMint;

    constructor(string memory initBaseURI) ERC721A("Dungeon Interior", "DI") {
        baseURI = initBaseURI;
    }

    function publicMint(uint256 amount) external payable {
        require(!paused, "Sale is not active yet.");
        require(
            (totalSupply() + amount) <= maxSupply,
            "Beyond max public supply."
        );
        require(
            amount <= maxPublicMintPerTx,
            "You can not mint more than max public mint."
        );
        require(msg.value >= (publicSalePrice * amount), "Wrong mint price.");

        _safeMint(msg.sender, amount);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 amount)
        external
        payable
    {
        require(!paused, "Sale is not active yet.");
        require((totalSupply() + amount) <= maxSupply, "Beyond max supply.");
        require(
            (claimedWhitelist + amount) <= maxWhitelistSupply,
            "Beyond max whitelist supply."
        );
        require(
            (totalWhitelistMint[msg.sender] + amount) <= maxWhitelistMintPerTx,
            "You can not mint more than max whitelist mint."
        );
        require(
            msg.value >= (whitelistSalePrice * amount),
            "Wrong mint price."
        );

        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, sender),
            "You are not whitelisted."
        );

        totalWhitelistMint[msg.sender] += amount;
        claimedWhitelist += amount;
        _safeMint(msg.sender, amount);
    }

    function ownerMint(address receiver, uint256 mintAmount)
        external
        onlyOwner
    {
        _safeMint(receiver, mintAmount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function setPaused() external onlyOwner {
        paused = !paused;
    }

    function setSupply(uint256 newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function setMaxWhitelistSupply(uint256 newSupply) external onlyOwner {
        maxWhitelistSupply = newSupply;
    }

    function setClaimedWhitelist(uint256 newClaimedWhitelist)
        external
        onlyOwner
    {
        claimedWhitelist = newClaimedWhitelist;
    }

    function setPublicPrice(uint256 newPrice) external onlyOwner {
        publicSalePrice = newPrice;
    }

    function setWhitelistPrice(uint256 newPrice) external onlyOwner {
        whitelistSalePrice = newPrice;
    }

    function setMaxPublicMintPerTx(uint256 newMaxPerTx) external onlyOwner {
        maxPublicMintPerTx = newMaxPerTx;
    }

    function setMaxWhitelistMintPerTx(uint256 newMaxPerTx) external onlyOwner {
        maxWhitelistMintPerTx = newMaxPerTx;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transaction failed.");
    }
}