//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDSF {
    function totalDeposited() external returns (uint256);

    function deposited(address account) external returns (uint256);

    function totalHoldings() external returns (uint256);

    function calcManagementFee(uint256 amount) external returns (uint256);
}