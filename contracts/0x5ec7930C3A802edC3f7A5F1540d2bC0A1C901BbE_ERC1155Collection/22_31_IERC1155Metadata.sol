// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

interface IERC1155Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}