// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "./DefaultOperatorFilterer.sol";

contract HEBI is ERC721A, Ownable, DefaultOperatorFilterer {

    string public baseURI;
    uint256 public maxSupply;
    uint256 public price;
    uint256 public maxMintsPerAddress;
    uint256 public freeMintsPerAddress;
    bool public salePaused = true;

    mapping (address => uint256) public addressMints;

    constructor(
        uint256 _maxSupply,
        uint256 _price,
        uint256 _maxMintsPerAddress,
        uint256 _freeMintsPerAddress
    ) ERC721A("HEBI", "HEBI") {
        maxSupply = _maxSupply;
        price = _price;
        maxMintsPerAddress = _maxMintsPerAddress;
        freeMintsPerAddress = _freeMintsPerAddress;
    }

    function mint(uint256 quantity) external payable {
        require(!salePaused, "Sale paused");
        require(tx.origin == msg.sender, "Contract caller");
        require(quantity > 0 && quantity <= maxMintsPerAddress, "Quantity exceeds max allowed mints per wallet");
        require(addressMints[msg.sender] + quantity <= maxMintsPerAddress, "Quantity exceeds max allowed mints for address");
        require(totalSupply() + quantity <= maxSupply, "Quantity exceeds max supply");
        
        uint256 freeMintsAllowed = addressMints[msg.sender] < freeMintsPerAddress ? freeMintsPerAddress - addressMints[msg.sender] : 0;
        uint256 cost = freeMintsAllowed >= quantity ? 0 : price * (quantity - freeMintsAllowed);

        require(msg.value >= cost, "Not enough ETH, free mints may be out of stock");
        addressMints[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function toggleSalePaused() external onlyOwner {
        salePaused = !salePaused;
    }

    function airdrop(uint256 quantity, address recipient) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "Quantity exceeds max supply");
        _safeMint(recipient, quantity);
    }

    function setFreeMintsPerAddressLimit(uint256 _freeMintsPerAddress) external onlyOwner {
        freeMintsPerAddress = _freeMintsPerAddress;
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
   
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}