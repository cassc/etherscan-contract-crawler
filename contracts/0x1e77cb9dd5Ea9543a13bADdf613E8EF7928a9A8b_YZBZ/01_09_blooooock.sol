// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract YZBZ is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    uint256 public constant MAX_SUPPLY = 2022;
    string public uriPrefix = "ipfs://bafybeicm6qwwvzcagvpoqwzupvproebbqfu5efzjyo6o6whrytcnb2dbby/";
    string public uriSuffix = ".json";

    constructor() ERC721A("YiZhangBaiZhi", "YZBZ") {}

    function mint() external {
        require(_numberMinted(msg.sender) == 0, "Only ONE per wallet");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Reached max supply");
        _mint(msg.sender, 1);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) external onlyOwner {
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Reached max supply");
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId),uriSuffix)) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setUriPrefix(string calldata _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string calldata _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
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