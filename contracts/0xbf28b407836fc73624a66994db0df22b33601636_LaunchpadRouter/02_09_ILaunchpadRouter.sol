// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "./ILaunchpadPool.sol";

interface ILaunchpadRouter {
    function getPools(string[] calldata poolIds) external view returns (address[] memory);

    function getPoolDetails(string[] calldata poolIds) external view returns (ILaunchpadPool.PoolDetail[] memory);

    function getUserDetails(string calldata poolId, address[] calldata userAddresses) external view returns (ILaunchpadPool.UserDetail[] memory);

    function purchase(
        string calldata poolId,
        address paymentToken,
        uint256 paymentAmount,
        uint256[] calldata purchaseAmount,
        uint256[] calldata purchaseCap,
        bytes32[] calldata merkleProof,
        bytes calldata signature
    ) external payable;

    function vest(string calldata poolId, uint256[] calldata vestAmount) external;
}