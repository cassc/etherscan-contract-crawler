// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../interfaces/IERC1155Upgradeable.sol";
import "../librairies/LibERC1155LazyMint.sol";

interface IERC1155LazyMint is IERC1155Upgradeable {
    function mintAndTransfer(LibERC1155LazyMint.Mint1155Data memory data, address to, uint256 _amount) external;

    function transferFromOrMint(
        LibERC1155LazyMint.Mint1155Data memory data,
        address from,
        address to,
        uint256 amount
    ) external;
}