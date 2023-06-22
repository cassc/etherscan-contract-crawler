//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract TimeTrav3lers is ERC721A, ERC2981, DefaultOperatorFilterer, Ownable {

    address private constant DEPLOYER_ADDRESS = 0xfb4E2fcb9F1230f4AF294dE4965Cc619c4304ad2;
    address private constant TEAM_ADDRESS = 0xC55642685f6e4711Dc3e9147de6Ec1534C9C755A;

    uint256 public constant MAX_SUPPLY = 2500;
    uint256 public constant PER_WALLET = 5;
    uint256 public constant COST = 0.005 ether;

    bool public mintingEnabled = false;
    string private baseUri;

    event Mint(address indexed owner, uint256 amount);

    constructor(string memory _baseUri) ERC721A("TimeTrav3lers", "TTS") {
        baseUri = _baseUri;
        setDefaultRoyalty(msg.sender, 500);
        _mint(msg.sender, 1);
    }

    function mint(uint256 amount) public payable {
        require(mintingEnabled, "Sale not active");
        require(balanceOf(msg.sender) + amount <= PER_WALLET, "Exceeds max per wallet");
        require(_totalMinted() + amount <= MAX_SUPPLY, "SOLD OUT");
        require(msg.sender == tx.origin, "No contracts");
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

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance / 100;
        payable(TEAM_ADDRESS).transfer(balance * 85);
        payable(DEPLOYER_ADDRESS).transfer(balance * 15);
    }

    function setBaseUri(string memory newURI) external onlyOwner {
        baseUri = newURI;
    }

    function flipMint() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

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