// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

interface IUSDT {
    function approve(address _spender, uint256 _value) external;
    function balanceOf(address who) external view returns (uint256);
}