// SPDX-License-Identifier: MIT

// Zodiacmasks by The Cryptomasks Project
// author: sadat.eth

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "closedsea/OperatorFilterer.sol";

contract Zodiacmasks is ERC721, ERC2981, ReentrancyGuard, Ownable, OperatorFilterer {
    using Strings for uint256;

    // Mint status
    uint256 public currentPhase = 0;

    // Mint prices
    uint256 public phase1Price = 0.035 ether;
    uint256 public phase2Price = 0.055 ether;
    uint256 public phase3Price = 0.088 ether;
    
    // Mint allocation 
    uint256 public maxSupply = 555;
    uint256 public totalSupply = 0;
    bytes32 private snapshot1 = 0x68a1ae8508e08139f3ab925d81ee7050392225590453ddc85fca19e3e9a97f81;
    bytes32 private snapshot2 = 0xa5700c316fca5592d1fcb68b6afb091f1d96d2e594cd5ce4849d70e28c5efb6a;
    mapping(address => uint256) public mintedPhase1;
    mapping(address => uint256) public mintedPhase2;
    
    // Metadata configuration
    string public baseURI = "ipfs://bafkreihqyccmxnqtxcv5vveu7vipwpnerjyjitzarzhjffk5e65vj7ff64?";
    string public contractURI = "ipfs://bafkreidolfodn5nzjbzbd7hekazafo6iqzjlt4gqswzdudzah3khnlokwy/";

    // Funds distribution
    address private tcp = 0xB9aB0B590abC88037a45690a68e1Ee41c5ea7365;
    bool public operatorFilteringEnabled = true;
    
    constructor() ERC721("Zodiacmasks", "MASK") {
        _registerForOperatorFiltering();
        _setDefaultRoyalty(tcp, 750);
    }

    // Mint function allowlist & public

    function mint(uint256 amount, uint256 mints, bytes32[] calldata proof) public payable check() {
        require(_verify(msg.sender, mints, proof), "notAllowed");
        require(_mints(mints, msg.sender) >= amount, "maxMinted");
        require(totalSupply + amount <= maxSupply, "soldOut");
        require(msg.value >= _price(amount), "sendEth");

        uint256 tokenId = maxSupply - totalSupply;
        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, tokenId);
            --tokenId;
        }
        totalSupply += amount;
        _minted(amount);
    }

    // Custom functions internal

    modifier check() {
        require(tx.origin == msg.sender, "noBots");
        require(currentPhase != 0, "notMinting");
        _;
    }

    function _verify(address account, uint256 mints, bytes32[] memory proof) internal view returns (bool verify_) {
        if (currentPhase == 1) return MerkleProof.verify(proof, snapshot1, keccak256(abi.encodePacked(account, mints)));
        if (currentPhase == 2) return MerkleProof.verify(proof, snapshot2, keccak256(abi.encodePacked(account, mints)));
        if (currentPhase == 3) return true; // phase 3 is public, no proof required
    }

    function _mints(uint256 mints, address account) internal view returns (uint256 mints_) {
        if (currentPhase == 1) return mints - mintedPhase1[account];
        if (currentPhase == 2) return mints - mintedPhase2[account];
        if (currentPhase == 3) return 1; // phase 3 public can mint 1 per tx
    }
    
    function _price(uint256 amount) internal view returns (uint256 price_) {
        if (currentPhase == 1) return amount * phase1Price;
        if (currentPhase == 2) return amount * phase2Price;
        if (currentPhase == 3) return amount * phase3Price;
    }

    function _minted(uint256 amount) internal {
        if (currentPhase == 1) { mintedPhase1[msg.sender] += amount; }
        if (currentPhase == 2) { mintedPhase2[msg.sender] += amount; }
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    // Custom functions public onlyOwner

    function setPhase(uint256 number) public onlyOwner {
        currentPhase = number;
    }

    function setReveal(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setAllowlists(bytes32 _snapshot1, bytes32 _snapshot2) public onlyOwner {
        snapshot1 = _snapshot1;
        snapshot2 = _snapshot2;
    }

    function setDefaultRoyalty(address receiver, uint96 feeBps) public onlyOwner {
        _setDefaultRoyalty(receiver, feeBps);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(tcp).call{value: address(this).balance}("");
        require(success);
    }

    // Standard functions public overrides

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC721, ERC2981) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }
}