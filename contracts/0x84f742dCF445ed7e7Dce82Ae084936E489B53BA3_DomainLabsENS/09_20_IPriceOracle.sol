//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPriceOracle {
    function price(string calldata name, uint expires, uint duration) external view returns(uint);
}