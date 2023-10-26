// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IBaseVotingVault {
    function queryVotePower(address user, uint256 blockNumber, bytes calldata extraData) external returns (uint256);

    function queryVotePowerView(address user, uint256 blockNumber) external view returns (uint256);

    function setTimelock(address timelock_) external;

    function setManager(address manager_) external;

    function timelock() external view returns (address);

    function manager() external view returns (address);
}