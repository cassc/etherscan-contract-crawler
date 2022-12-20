// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./OperatorFilterer.sol";

contract GrumpyGrinches is ERC721A, Ownable, OperatorFilterer {
    using Strings for uint256;

    bytes32 public merkleRoot;
    string  public baseURI;
    string  public extension;
    uint256 public maxSupply                  = 2525;
    uint256 public maxPerWallet               = 3;
    uint256 public phase                      = 0;
    bool public revealed                      = false;
    bool public operatorFilteringEnabled;

    mapping(address => uint256) public _walletMints;

    constructor() ERC721A("Grumpy Grinches", "GRINCH"){
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    function mint(uint256 amount, bytes32[] calldata merkleProof) external payable {
        require(phase > 0, "Mint is not live yet");
        require(amount <= maxPerWallet, "Too many Grinches");
        require(msg.sender == tx.origin, "No contracts");
        require(totalSupply() + amount <= maxSupply, "No more Grinches");
        if (phase == 1) {
            // wholist
            require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on the WhoList");
            require(_walletMints[msg.sender] + amount <= maxPerWallet, "Too many per wallet");
            _walletMints[msg.sender] += amount;
        } else if (phase == 2) {
            // public
            require(_walletMints[msg.sender] + amount <= maxPerWallet, "Too many per wallet");
            _walletMints[msg.sender] += amount;
        }
        
        _safeMint(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        if (!revealed) {
            return "https://www.grumpygrinches.com/prereveal.json";
        }

	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), extension)) : "";
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseUri(string memory _baseuri) public onlyOwner {
        baseURI = _baseuri;
    }

    function setExtension(string memory _extension) public onlyOwner {
        extension = _extension;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPhase(uint256 _phase) external onlyOwner {
        phase = _phase;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function reserve(uint256 amount, address to) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "No more Grinches");
        _safeMint(to, amount);
    }

    function reveal(bool _state) public onlyOwner {
        revealed = _state;
    }

    function repeatRegistration() public {
        _registerForOperatorFiltering();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator, operatorFilteringEnabled)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator, operatorFilteringEnabled)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }
}