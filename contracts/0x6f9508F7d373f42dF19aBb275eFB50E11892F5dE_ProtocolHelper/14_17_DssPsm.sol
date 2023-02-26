// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

interface DssPsm {
    function tin() external view returns (uint256);
    function tout() external view returns (uint256);

    function sellGem(address usr, uint256 gemAmt) external;
    function buyGem(address usr, uint256 gemAmt) external;
}