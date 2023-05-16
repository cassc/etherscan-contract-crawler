// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;
pragma experimental ABIEncoderV2;

interface ICurveStrategyProxy {
    function proxy() external returns (address);

    function balanceOf(address _gauge) external view returns (uint256);

    function deposit(address _gauge, address _token) external;

    function withdraw(
        address _gauge,
        address _token,
        uint256 _amount
    ) external returns (uint256);

    function withdrawAll(
        address _gauge,
        address _token
    ) external returns (uint256);

    function harvest(address _gauge) external;

    function lock() external;

    function approveStrategy(address) external;

    function revokeStrategy(address) external;

    function claimManyRewards(address _gauge, address[] memory _token) external;
}

interface IVoter {
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool, bytes memory);

    function increaseAmount(uint256) external;
}