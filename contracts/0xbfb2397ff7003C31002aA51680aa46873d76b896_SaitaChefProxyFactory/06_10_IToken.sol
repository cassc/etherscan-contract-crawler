// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IToken {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);

}