// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IInterestRateModel {

    function blocksPerYear() external view returns (uint256); 

    function isInterestRateModel() external returns(bool);

    function getBorrowRate(
        uint256 cash, 
        uint256 borrows, 
        uint256 reserves) external view returns (uint256);

    function getSupplyRate(
        uint256 cash, 
        uint256 borrows, 
        uint256 reserves, 
        uint256 reserveFactor) external view returns (uint256);
}