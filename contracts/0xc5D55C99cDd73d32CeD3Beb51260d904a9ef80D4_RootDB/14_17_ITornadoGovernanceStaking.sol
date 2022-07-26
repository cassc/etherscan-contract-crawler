// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITornadoGovernanceStaking {
    function lockWithApproval(uint256 amount) external;

    function lock(address owner, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    function unlock(uint256 amount) external;

    function Staking() external view returns (address);

    function lockedBalance(address account) external view returns (uint256);
}