// SPDX-License-Identifier: MIT

// DEM BOYZ
// https://twitter.com/demboyz_xyz
// https://demboyz.xyz/

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";

contract DemBoyz is ERC721A, OperatorFilterer, Ownable {
    uint256 public TOTAL_SUPPLY = 9999;

    uint256 public WHITELIST_PRICE = 0.015 ether;

    uint256 public PUBLIC_PRICE = 0.0175 ether;

    uint256 public MAX_TX = 10;

    bool public WhitelistSaleLive = false;

    bool public PublicSaleLive = false;

    bool public teamClaimed = false;

    bytes32 merkleRoot;

    string public baseURI;

    mapping(address => bool) public whitelistClaimed;

    constructor() ERC721A("Dem Boyz", "DEMBOYZ") OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), false){}

    modifier publicLive() {
        require(PublicSaleLive, "Public sale is not yet live.");
        _;
    }

    modifier whitelistLive() {
        require(WhitelistSaleLive, "Whitelist is not yet live.");
        _;
    }

    modifier teamHasClaimed() {
        require(!teamClaimed, "Team tokens already claimed.");
        _;
    }

    modifier checkSale(uint256 quantity) {
        require(quantity <= MAX_TX, "Exceeds transaction limit.");
        require(PUBLIC_PRICE * quantity == msg.value, "Transaction value invalid.");
        require(totalSupply() + quantity <= TOTAL_SUPPLY, "Exceeds total supply.");
        _;
    }

    modifier checkWhitelist(uint256 quantity) {
        require(!whitelistClaimed[msg.sender], "Whitelist tokens already claimed.");
        require(quantity <= MAX_TX, "Exceeds transaction limit.");
        require(WHITELIST_PRICE * quantity == msg.value, "Transaction value invalid.");
        require(totalSupply() + quantity <= TOTAL_SUPPLY, "Exceeds total supply.");
        _;
    }

    modifier isValidProof(bytes32[] memory proof) {
        require(validateProof(proof), "Invalid proof.");
        _;
    }

    function mint(uint256 quantity)
        external
        payable
        publicLive
        checkSale(quantity) 
    {
        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(uint256 quantity, bytes32[] memory proof)
        external
        payable
        whitelistLive
        checkWhitelist(quantity)
        isValidProof(proof)
    {
        _safeMint(msg.sender, quantity);
        whitelistClaimed[msg.sender] = true;
    }

    function teamMint()
        external
        onlyOwner
        teamHasClaimed
    {
        _safeMint(msg.sender, 50);
        teamClaimed = true;
    }

    function validateProof(bytes32[] memory _proof) internal view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    function setRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function togglePublic() external onlyOwner {
        PublicSaleLive = !PublicSaleLive;
    }

    function toggleWhitelist() external onlyOwner {
        WhitelistSaleLive = !WhitelistSaleLive;
    }

    function setTransactionLimit(uint256 _maxTx) external onlyOwner {
        MAX_TX = _maxTx;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        PUBLIC_PRICE = _price;
    }

    function setWhitelistPrice(uint256 _price) external onlyOwner {
        WHITELIST_PRICE = _price;
    }

    function setTotalSupply(uint256 _supply) external onlyOwner {
        TOTAL_SUPPLY = _supply;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }


    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}