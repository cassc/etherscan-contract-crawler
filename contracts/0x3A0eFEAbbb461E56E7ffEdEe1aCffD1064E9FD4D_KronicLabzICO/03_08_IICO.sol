//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IICO{

    function updatePriceForOneToken(uint256 price) external;

    function buy() external payable;

    function claimProfits() external;

    function claimTokensNotSold() external;

    function exchangeRate() external view returns (uint256);
}