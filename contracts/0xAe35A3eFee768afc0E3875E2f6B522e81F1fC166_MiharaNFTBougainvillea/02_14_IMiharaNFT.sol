//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMiharaNFT {

    //******************************
    // view functions
    //******************************

    function remainingFree() external view returns (uint256);
    function isOnSale() external view returns (bool);
    function nextTokenId() external view returns (uint256);

    //******************************
    // public functions
    //******************************

    function buy() external payable;

    //******************************
    // admin functions
    //******************************

    function mintFree(address to) external;
    function updateSaleStatus(bool __isOnSale) external;
    function withdrawETH() external;
}