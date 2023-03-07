// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IHedgeExchanger {

    function buy(uint256 _amount, string calldata referral) external returns (uint256);

    function redeem(uint256 _amount) external returns (uint256);

}