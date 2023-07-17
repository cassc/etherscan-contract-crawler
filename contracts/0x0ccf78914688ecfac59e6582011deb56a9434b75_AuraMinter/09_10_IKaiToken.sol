// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

interface IKaiToken {
    function minterMint(address _to, uint256 _amount) external;
}