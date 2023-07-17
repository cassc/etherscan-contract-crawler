// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KitchenSkreppies is  ERC721A, ERC2981, DefaultOperatorFilterer, Ownable {

    uint256 public constant MAX_SUPPLY = 3636;
    uint256 public constant PER_WALLET = 5;
    uint256 public constant COST = 0.0036 ether;

event Mint(address indexed owner, uint256 amount);

    bool public mintOpen = false;
    string private baseUri;


    constructor() ERC721A("Kitchen Skreppies", "KS") {
        setDefaultRoyalty(msg.sender, 500);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function mint(uint256 amount) public payable {
        require(mintOpen, "Mint not started");
        require(balanceOf(msg.sender) + amount <= PER_WALLET, "Exceeds max per wallet");
        require(_totalMinted() + amount <= MAX_SUPPLY, "SOLD OUT");
        require(COST * amount <= msg.value,"Insufficient funds sent");
        _mint(msg.sender, amount);
        emit Mint(msg.sender, amount);
    }

    function ownerMint(address adress, uint256 amount) external payable onlyOwner {
        require(_totalMinted() + amount <= MAX_SUPPLY, "SOLD OUT");
        _mint(adress, amount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseUri(string calldata _newBaseURI) external onlyOwner {
        baseUri = _newBaseURI;
    }

    function flipMint() external onlyOwner {
        mintOpen = !mintOpen;
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function withdrawBalance(address _ownerAddr) external onlyOwner  {
        // Get the balance of the contract and transfer it to the specified address
        uint256 fullBalance = address(this).balance;
        payable (_ownerAddr).transfer(fullBalance);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    //     internal
    //     override(ERC721A)
    // {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool){
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
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