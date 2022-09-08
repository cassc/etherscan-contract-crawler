// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IVoterProxy {
    function createLock(uint256, uint256) external returns (bool);

    function increaseAmount(uint256) external returns (bool);

    function increaseTime(uint256) external returns (bool);

    function release(address) external returns (bool);

    function checkpointFeeRewards(address) external;

    function claimFees(
        address,
        address,
        address
    ) external returns (uint256);

    function voteGaugeWeight(address, uint256) external returns (bool);

    function booster() external view returns (address);

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory);
}