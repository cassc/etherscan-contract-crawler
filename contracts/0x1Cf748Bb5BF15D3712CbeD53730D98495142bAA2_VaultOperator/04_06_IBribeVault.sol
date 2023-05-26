// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IBribeVault {
    function depositBribeERC20(
        bytes32 bribeIdentifier,
        bytes32 rewardIdentifier,
        address token,
        uint256 amount,
        address briber
    ) external;

    function getBribe(bytes32 bribeIdentifier)
        external
        view
        returns (address token, uint256 amount);

    function depositBribe(
        bytes32 bribeIdentifier,
        bytes32 rewardIdentifier,
        address briber
    ) external payable;

    function transferBribes(bytes32[] calldata rewardIdentifiers) external;
}