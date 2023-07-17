// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20/IERC20.sol";

interface IRecoverable is IERC20{

    function claimPeriod() external view returns (uint256);
    
    function notifyClaimMade(address target) external;

    function notifyClaimDeleted(address target) external;

    function getCollateralRate(IERC20 collateral) external view returns(uint256);

    function recover(address oldAddress, address newAddress) external;

}