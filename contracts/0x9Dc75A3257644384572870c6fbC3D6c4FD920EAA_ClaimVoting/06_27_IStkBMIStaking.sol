// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IStkBMIStaking {
    function stakedStkBMI(address user) external view returns (uint256);

    function totalStakedStkBMI() external view returns (uint256);

    function lockStkBMI(uint256 amount) external;

    function unlockStkBMI(uint256 amount) external;

    function slashUserTokens(address user, uint256 amount) external;
}