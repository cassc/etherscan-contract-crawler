// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IPabloDistribution {

    function recoverTokensFor(address _token, uint256 _amount, address _to) external;

}