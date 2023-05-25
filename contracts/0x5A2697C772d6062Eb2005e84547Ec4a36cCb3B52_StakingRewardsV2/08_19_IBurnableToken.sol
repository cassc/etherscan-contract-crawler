//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IBurnableToken {
    function burn(uint256 _amount) external;
}