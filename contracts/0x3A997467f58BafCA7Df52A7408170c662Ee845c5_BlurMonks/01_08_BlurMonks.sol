// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BlurMonks is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 1024;
    uint256 public MAX_WHITELIST_SUPPLY = 224;
    uint256 public MAX_PUBLIC_MINT_PER_TX = 3;
    uint256 public MAX_WHITELIST_MINT_PER_TX = 1;
    uint256 public TOTAL_WHITELIST_MINT = 0;
    uint256 public PUBLIC_COST = .005 ether;
    uint256 public WHITELIST_COST = 0 ether;
    bool public PAUSED = true;

    string private baseURI;
    bytes32 private merkleRoot;

    mapping(address => uint256) public CLAIMED_WHITELIST_COUNT;

    constructor(string memory initBaseURI) ERC721A("Blur Monks", "BM") {
        baseURI = initBaseURI;
    }

    function mint(uint256 amount) external payable {
        require(!PAUSED, "// MINT_INACTIVE");
        require(
            (_totalMinted() + amount) <= MAX_SUPPLY,
            "// REACHED_MAX_PUBLIC_MINT_CAP"
        );
        require(
            amount <= MAX_PUBLIC_MINT_PER_TX,
            "// REACHED_MAX_MINT_CAP_PER_TX"
        );
        require(msg.value >= (PUBLIC_COST * amount), "// INVALID_MINT_PRICE");

        _safeMint(msg.sender, amount);
    }

    function allowlistMint(bytes32[] calldata _merkleProof, uint256 amount)
        external
        payable
    {
        require(!PAUSED, "// MINT_INACTIVE");
        require(
            (_totalMinted() + amount) <= MAX_SUPPLY,
            "REACHED_MAX_MINT_CAP"
        );
        require(
            (TOTAL_WHITELIST_MINT + amount) <= MAX_WHITELIST_SUPPLY,
            "// REACHED_MAX_WHITELIST_MINT_CAP"
        );
        require(
            (CLAIMED_WHITELIST_COUNT[msg.sender] + amount) <=
                MAX_WHITELIST_MINT_PER_TX,
            "// REACHED_MAX_MINT_CAP_PER_TX"
        );
        require(
            msg.value >= (WHITELIST_COST * amount),
            "// INVALID_MINT_PRICE"
        );

        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, sender),
            "// NOT_ALLOWED_TO_MINT"
        );

        CLAIMED_WHITELIST_COUNT[msg.sender] += amount;
        TOTAL_WHITELIST_MINT += amount;
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
        PAUSED = !PAUSED;
    }

    function setSupply(uint256 newSupply) external onlyOwner {
        MAX_SUPPLY = newSupply;
    }

    function setMaxWhitelistSupply(uint256 newSupply) external onlyOwner {
        MAX_WHITELIST_SUPPLY = newSupply;
    }

    function setTotalWhitelistMint(uint256 newTotalWhitelistMint)
        external
        onlyOwner
    {
        TOTAL_WHITELIST_MINT = newTotalWhitelistMint;
    }

    function setPublicCost(uint256 newPrice) external onlyOwner {
        PUBLIC_COST = newPrice;
    }

    function setWhitelistPrice(uint256 newPrice) external onlyOwner {
        WHITELIST_COST = newPrice;
    }

    function setMaxPublicMintPerTx(uint256 newMaxPerTx) external onlyOwner {
        MAX_PUBLIC_MINT_PER_TX = newMaxPerTx;
    }

    function setMaxWhitelistMintPerTx(uint256 newMaxPerTx) external onlyOwner {
        MAX_WHITELIST_MINT_PER_TX = newMaxPerTx;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "// WITHDRAW_FAILED");
    }
}