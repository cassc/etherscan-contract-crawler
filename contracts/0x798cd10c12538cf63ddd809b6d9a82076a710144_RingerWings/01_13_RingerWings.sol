//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from  "@openzeppelin/contracts/access/Ownable.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract RingerWings is ERC721A, DefaultOperatorFilterer, ERC2981, Ownable {

    string public baseUri = "ipfs://bafybeigxtjfachainxdpgoon72chfydvl6l3ak7vll2n5v5uc2cqjdszeu/";
    bool public mintingEnabled = false;

    uint256 public constant MAX_SUPPLY = 6666;
    uint256 public constant MAX_PER_WALLET = 5;
    uint256 public constant PRICE = 0.0035 ether;

    constructor() ERC721A("RingerWings", "RGWG") {
        setDefaultRoyalty(msg.sender, 500);
        _mint(msg.sender, 1);
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

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool){
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function mint(uint256 quantity) external payable {
        require(mintingEnabled, "Mint not active");
        require(msg.sender == tx.origin, "No contracts allowed");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Sold Out");
        require(balanceOf(msg.sender) + quantity <= MAX_PER_WALLET, "Exceeds max per wallet");

        uint256 payForCount = quantity;
        uint256 freeMintCount = _getAux(msg.sender);

        if (freeMintCount < 1) {
            payForCount = quantity - 1;
            _setAux(msg.sender, 1);
        }

        if (payForCount > 0) {
            require(PRICE * payForCount <= msg.value,"Insufficient funds sent");
        }
    
        _mint(msg.sender, quantity);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function freeMinted(address owner) external view returns (uint64) {
        return _getAux(owner);
    }

    function flipMint() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function setBaseUri(string memory _uri) external onlyOwner {
        baseUri = _uri;
    }
}