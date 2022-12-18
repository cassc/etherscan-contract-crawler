// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155Min {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}