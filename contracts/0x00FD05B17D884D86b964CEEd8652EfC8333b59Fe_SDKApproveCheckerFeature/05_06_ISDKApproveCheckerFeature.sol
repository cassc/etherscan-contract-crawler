/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface ISDKApproveCheckerFeature {

    struct SDKApproveInfo {
        uint8 tokenType; // 0: ERC721, 1: ERC1155, 2: ERC20, 255: other
        address tokenAddress;
        address operator;
    }

    function getSDKApprovalsAndCounter(
        address account,
        SDKApproveInfo[] calldata list
    )
        external
        view
        returns (uint256[] memory approvals, uint256 elementCounter, uint256 seaportCounter);
}