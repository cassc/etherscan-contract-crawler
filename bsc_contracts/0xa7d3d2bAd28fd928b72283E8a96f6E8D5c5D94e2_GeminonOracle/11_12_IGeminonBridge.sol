// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IGeminonBridge {
    function externalTotalSupply() external view returns(uint256);
}