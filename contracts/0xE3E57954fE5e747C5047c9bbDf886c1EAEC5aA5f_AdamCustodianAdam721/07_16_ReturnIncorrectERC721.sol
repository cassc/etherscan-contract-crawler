// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ReturnIncorrect.sol";


abstract contract ReturnIncorrectERC721 is AccessControl, ReturnIncorrect {
    event ReturnERC721Approve(address indexed operator, address indexed contract_, uint256 indexed tokenId, address to);
    event ReturnERC721Transfer(address indexed operator, address indexed contract_, uint256 indexed tokenId, address from, address to, bytes data);

    function returnERC721Approve(IERC721 erc721, address to, uint256 tokenId) public virtual onlyRole(RETURNER_ROLE) {
        erc721.approve(to, tokenId);
        emit ReturnERC721Approve(_msgSender(), address(erc721), tokenId, to);
    }

    function returnERC721SafeTransferFrom3(IERC721 erc721, address from, address to, uint256 tokenId) public virtual onlyRole(RETURNER_ROLE) {
        erc721.safeTransferFrom(from, to, tokenId);
        emit ReturnERC721Transfer(_msgSender(), address(erc721), tokenId, from, to, "");
    }

    function returnERC721SafeTransferFrom4(IERC721 erc721, address from, address to, uint256 tokenId, bytes memory data) public virtual onlyRole(RETURNER_ROLE) {
        erc721.safeTransferFrom(from, to, tokenId, data);
        emit ReturnERC721Transfer(_msgSender(), address(erc721), tokenId, from, to, data);
    }

    function returnERC721TransferFrom(IERC721 erc721, address from, address to, uint256 tokenId) public virtual onlyRole(RETURNER_ROLE) {
        erc721.transferFrom(from, to, tokenId);
        emit ReturnERC721Transfer(_msgSender(), address(erc721), tokenId, from, to, "");
    }
}