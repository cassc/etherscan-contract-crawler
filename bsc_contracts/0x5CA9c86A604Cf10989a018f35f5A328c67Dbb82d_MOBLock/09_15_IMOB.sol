// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMOB {
    function pair() external returns(address);
    function startTradeTime() external returns(uint256);
    function removeBlist(address adr) external;
}