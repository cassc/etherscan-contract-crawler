//SPDX-License-Identifier: CC-BY-NC-ND

pragma solidity ^0.8.0;

interface IErcForgeERC1155Mintable {
    function mint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external payable;
}