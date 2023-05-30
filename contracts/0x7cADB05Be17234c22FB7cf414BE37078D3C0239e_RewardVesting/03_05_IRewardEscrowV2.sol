pragma solidity 0.8.6;

interface IRewardEscrowV2 {
    function appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) external;
}