// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Goodboi_Borzoi is ERC721A, ERC721ABurnable, Ownable {
    uint256 public MAX_SUPPLY = 5555;

    uint256 public PRICE = 0.025 ether;

    uint256 public WHITELIST_PRICE = 0.02 ether;

    uint256 public MAX_TX = 5;

    bool public whitelistSaleActive = false;

    bool public publicSaleActive = false;

    bool public burnActive = false;

    bool public teamClaimed = false;

    bytes32 merkleRoot;

    string public baseURI;

    mapping(address => bool) public whitelistSaleClaimed;

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}

    function mint(uint256 quantity)
        public
        payable
        publicSaleOpen
        validatePublicSale(quantity) 
    {
        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata proof)
        public
        payable
        allowlistSaleOpen
        validateAllowlistSale(quantity)
        isValidProof(proof)
    {
        _safeMint(msg.sender, quantity);
        whitelistSaleClaimed[msg.sender] = true;
    }

    function teamMint()
        public
        onlyOwner
        teamHasClaimed
    {
        _safeMint(msg.sender, 50);
        teamClaimed = true;
    }


    function burnTokens(uint256[] calldata tokenIds) 
        public 
        tokenBurnActive 
    {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            burn(tokenIds[i]);
        }
    }

    function checkProof(bytes32[] memory _proof) internal view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function togglePublic() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function toggleWhitelist() external onlyOwner {
        whitelistSaleActive = !whitelistSaleActive;
    }

    function toggleBurn() external onlyOwner {
        burnActive = !burnActive;
    }

    function setMaxTx(uint256 _maxTx) public onlyOwner {
        MAX_TX = _maxTx;
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    function setWhitelistPrice(uint256 _price) public onlyOwner {
        WHITELIST_PRICE = _price;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    modifier publicSaleOpen() {
        require(publicSaleActive, "Badboi! Public sale is closed.");
        _;
    }

    modifier allowlistSaleOpen() {
        require(whitelistSaleActive, "Badboi! Private sale is closed.");
        _;
    }

    modifier teamHasClaimed() {
        require(!teamClaimed, "Badboi! Team has already claimed their tokens.");
        _;
    }

    modifier tokenBurnActive() {
        require(burnActive, "Badboi! Token burning is not yet active.");
        _;
    }

    modifier validatePublicSale(uint256 quantity) {
        require(quantity <= MAX_TX, "Badboi! Too many tokens per mint.");
        require(PRICE * quantity == msg.value, "Badboi! Incorrect transaction value.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Badboi! Transaction exceeds max supply.");
        _;
    }

    modifier validateAllowlistSale(uint256 quantity) {
        require(!whitelistSaleClaimed[msg.sender], "Badboi! You have already claimed your tokens.");
        require(quantity <= MAX_TX, "Badboi! Too many tokens per mint.");
        require(WHITELIST_PRICE * quantity == msg.value, "Badboi! Incorrect transaction value.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Badboi! Transaction exceeds max supply.");
        _;
    }

    modifier isValidProof(bytes32[] memory proof) {
        require(checkProof(proof), "BadBoi! Invalid proof.");
        _;
    }
}