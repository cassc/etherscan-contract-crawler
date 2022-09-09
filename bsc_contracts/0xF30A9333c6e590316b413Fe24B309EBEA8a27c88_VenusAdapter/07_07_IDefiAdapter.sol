// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDefiAdapter {
    function underlying(address platformToken) external view returns(address);
    function amountUnderlying(address platformToken, uint amount) external view returns(uint);
}