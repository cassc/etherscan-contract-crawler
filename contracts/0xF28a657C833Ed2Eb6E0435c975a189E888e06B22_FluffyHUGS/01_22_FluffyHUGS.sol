// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FluffyHUGS is ERC721, ERC721Enumerable, Pausable, AccessControl, ERC721Burnable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    bytes32 internal constant SUPPORTER_ROLE = keccak256("SUPPORTER_ROLE");

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_PER_MINT = 5;

    // Starting and stopping sale, presale and whitelist
    bool public saleActive = false;
    bool public presaleActive = false;

    uint256 public price = 0.0 ether;
    uint256 public preSalePrice = 0.0 ether;

    string public baseTokenURI;
    uint256 public startTokenURIID;

    bytes32 private _whitelistMerkleRoot;

    // keep track of those on whitelist who have claimed their NFT
    mapping(address => bool) public claimed;

    mapping(uint256 => bool) private preSold;

    uint256 public returnPercent = 0;   // 0%

    constructor() ERC721("Fluffy HUGS", "FHUGS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SUPPORTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(SUPPORTER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(SUPPORTER_ROLE) {
        _unpause();
    }

    function safeMint(address to, uint256 amount) public onlyRole(SUPPORTER_ROLE) {
        uint256 totalMinted = _tokenIdCounter.current();

        require(totalMinted.add(amount) <= MAX_SUPPLY, "Not enough NFTs left!");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, totalMinted + i);
            _tokenIdCounter.increment();
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    whenNotPaused
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
    internal
    override
    {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);

        if (to == address(0)) {
            uint256 balance = (preSold[firstTokenId] ? preSalePrice : price) * returnPercent / 100;
            if (balance > 0) require(payable(from).send(balance), "Error");
        }
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory _uri) public onlyRole(SUPPORTER_ROLE) {
        baseTokenURI = _uri;
    }

    function setStartURIID(uint256 _id) public onlyRole(SUPPORTER_ROLE) {
        startTokenURIID = _id;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = baseTokenURI;
        uint256 id = startTokenURIID + tokenId;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : "";
    }

    function setReturnPercent(uint256 _percent) public onlyRole(SUPPORTER_ROLE) {
        require(_percent < 100, "Value must be less than 100.");
        returnPercent = _percent;
    }

    // The following functions are used for minting

    function setPrice(uint256 _price) public onlyRole(SUPPORTER_ROLE) {
        price = _price;
    }

    function setPresalePrice(uint256 _price) public onlyRole(SUPPORTER_ROLE) {
        preSalePrice = _price;
    }

    // Start and stop presale
    function setPresaleActive(bool val) public onlyRole(SUPPORTER_ROLE) {
        presaleActive = val;
        if (val) saleActive = false;
    }

    // Start and stop sale
    function setSaleActive(bool val) public onlyRole(SUPPORTER_ROLE) {
        saleActive = val;
        if (val) presaleActive = false;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyRole(SUPPORTER_ROLE) {
        _whitelistMerkleRoot = _merkleRoot;
    }

    function _mintSingleNFT() private {
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        _tokenIdCounter.increment();
    }

    function preSale(bytes32[] memory proof, uint256 amount) external payable {
        uint256 totalMinted = _tokenIdCounter.current();
        uint256 preSaleMaxMint = 3;

        require(presaleActive, "Presale isn't active");
        require(totalMinted.add(amount) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(amount > 0 && amount <= preSaleMaxMint, "Cannot mint specified number of NFTs.");
        require(msg.value >= preSalePrice.mul(amount), "Not enough ether to purchase NFTs.");

        // merkle tree list related
        require(_whitelistMerkleRoot != "", "Merkle tree root not set");
        require(
            MerkleProof.verify(proof, _whitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "Presale validation failed"
        );
        require(!claimed[msg.sender], "NFT is already claimed by this wallet");

        for (uint256 i = 0; i < amount; i++) {
            _mintSingleNFT();
            preSold[totalMinted + i] = true;
        }

        claimed[msg.sender] = true;
    }

    function mintNFTs(uint256 amount) public payable {
        uint256 totalMinted = _tokenIdCounter.current();

        require(saleActive, "Sale isn't active");
        require(totalMinted.add(amount) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(amount > 0 && amount <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(msg.value >= price.mul(amount), "Not enough ether to purchase NFTs.");

        for (uint256 i = 0; i < amount; i++) {
            _mintSingleNFT();
        }
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() public payable onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        require(payable(msg.sender).send(balance), "Error");
    }
}