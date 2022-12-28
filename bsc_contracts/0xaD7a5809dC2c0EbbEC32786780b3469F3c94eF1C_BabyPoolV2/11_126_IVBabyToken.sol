// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface IVBabyToken {

    function setCanTransfer(bool allowed) external;

    function changePerReward(uint256 babyPerBlock) external;

    function updateBABYFeeBurnRatio(uint256 babyFeeBurnRatio) external;

    function updateBABYFeeReserveRatio(uint256 babyFeeReserve) external;

    function updateTeamAddress(address team) external;

    function updateTreasuryAddress(address treasury) external;

    function updateReserveAddress(address newAddress) external;

    function setSuperiorMinBABY(uint256 val) external;

    function _babyToken() external returns (address);

    function emergencyWithdraw() external;

    function transferOwnership(address newOwner) external;

    function setRatioValue(uint256 ratioFee) external;

    function donate(uint256 babyAmount) external;

}