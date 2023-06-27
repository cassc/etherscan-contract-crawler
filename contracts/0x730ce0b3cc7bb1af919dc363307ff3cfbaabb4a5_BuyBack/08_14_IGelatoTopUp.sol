// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

/// Gelato top up wallet interface
interface IGelatoTopUp {
    function depositFunds(
        address _receiver,
        address _token,
        uint256 _amount
    ) external;

    function userTokenBalance(
        address _user,
        address _token
    ) external view returns (uint256);
}