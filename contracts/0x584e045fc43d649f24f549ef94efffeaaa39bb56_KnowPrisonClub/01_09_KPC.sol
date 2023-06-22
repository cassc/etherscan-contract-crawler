// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract KnowPrisonClub is ERC721A, Ownable, DefaultOperatorFilterer {

    string private baseURI = "ipfs://bafybeifmyld2xcozptt4bagb4fzl6qtnmkctkfcooy2xis2e5wdc3pkbva/";
    uint256 public maxSupply = 5000;
    uint256 public mintPrice = 0.0025 ether;
    uint256 public maxPerWallet = 8;
    bool public isMintEnabled = false;
    
    constructor() ERC721A("Know Prison Club", "KPC") {}

    function mint(uint256 quantity) external payable {
        require(isMintEnabled, "Mint not enabled");
        require(quantity + _numberMinted(msg.sender) <= maxPerWallet, "Exceeded mint limit per wallet");
        require(totalSupply() + quantity <= maxSupply, "Exceeded max supply");
        require(msg.value >= mintPrice * (quantity - (_numberMinted(msg.sender) == 0? 1: 0)), "Not enough ether sent");

        _safeMint(msg.sender, quantity);
    }

    function mintDev(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "Exceeded max supply");
        _safeMint(msg.sender, quantity);
    }

    function toggleMint() external onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }

    function setMaxPerWallet(uint256 max) external onlyOwner {
        maxPerWallet = max;
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setBaseUri(string memory newUri) external onlyOwner {
        baseURI = newUri;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
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