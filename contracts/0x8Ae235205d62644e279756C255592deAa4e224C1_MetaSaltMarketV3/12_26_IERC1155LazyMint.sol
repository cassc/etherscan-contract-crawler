// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.3;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "../lib/LibERC1155LazyMint.sol";

interface IERC1155LazyMint is IERC1155Upgradeable {
    event Supply(
        uint256 tokenId,
        uint256 value
    );

    event Creator(
        uint256 tokenId,
        address creator
    );

    function mintAndTransfer(
        LibERC1155LazyMint.Mint1155Data memory data,
        address to,
        uint256 _amount
    ) external;

    function transferFromOrMint(
        LibERC1155LazyMint.Mint1155Data memory data,
        address from,
        address to,
        uint256 amount
    ) external;

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address, uint256 
    );
}