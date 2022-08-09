// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IClaim {
    function initClaim(address _payee, uint256 _amount) external payable;
}