// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IStaker {
    function deposit(address, address) external;

    function withdraw(address) external;

    function withdraw(
        address,
        address,
        uint256
    ) external;

    function withdrawAll(address, address) external;

    function createLock(uint256, uint256) external;

    function increaseAmount(uint256) external;

    function increaseTime(uint256) external;

    function release() external;

    function claimRewards(
        address,
        address
    ) external;

    function claimFees(
        address,
        address,
        address
    ) external;

    function voteAllocations(
        uint256[] calldata,
        address[] calldata,
        uint256[] calldata
    ) external;

    function operator() external view returns (address);

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory);
}