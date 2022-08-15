//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

contract NFTTransfer 
{
    using ERC165Checker for address;
    
    bytes4 private constant INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;
    bytes4 private constant INTERFACE_SIGNATURE_ERC721 = 0x80ac58cd;

     function _transfer(
        address operator,
        uint256 tokenId,
        address from,
        address to,
        uint256 value
    ) internal {
        bool erc1155 = operator.supportsInterface(
            INTERFACE_SIGNATURE_ERC1155
        );
        bool erc721 = operator.supportsInterface(
            INTERFACE_SIGNATURE_ERC721
        );
        require(erc1155 || erc721, "_transfer: unsupported token");

        if (erc721)
            IERC721(operator).safeTransferFrom(from, to, tokenId);

        if (erc1155)
            IERC1155(operator).safeTransferFrom(
                from,
                to,
                tokenId,
                value,
                ""
            );
    }
}