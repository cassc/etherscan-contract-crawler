// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { DefaultOperatorFilterer } from "./opensea/DefaultOperatorFilterer.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

abstract contract NotablesToken is ERC721A, DefaultOperatorFilterer, Ownable, IERC2981 {

    string baseURI;
    uint16 royaltyPercentage;
    address royaltyReceiver;

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

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || ERC721A.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view override returns (address _receiver, uint256 _royaltyAmount) {
        uint256 royaltyAmount = (_salePrice * royaltyPercentage) / 10000;
        return (royaltyReceiver, royaltyAmount);
    }

    function setRoyalties(uint16 _royaltyPercentage, address _royaltyReceiver) public onlyOwner {
        royaltyPercentage = _royaltyPercentage;
        royaltyReceiver = _royaltyReceiver;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), '.json'));   
    }

}