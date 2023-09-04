// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IPartyBid  {
    function totalContributed(address) external view returns(uint256);
}