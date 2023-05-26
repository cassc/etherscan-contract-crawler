// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IAlphaGangOG {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    // change to transfer
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;
}