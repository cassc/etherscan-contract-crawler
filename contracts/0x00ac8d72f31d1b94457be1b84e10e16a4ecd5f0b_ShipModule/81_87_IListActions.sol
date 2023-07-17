// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IListActions {
    function list(
        address nftContract,
        uint256 tokenID,
        uint256 amount,
        uint256 duration,
        address payable[] calldata royaltyRecipients,
        uint256[] calldata royaltyAmounts
    ) external;
}