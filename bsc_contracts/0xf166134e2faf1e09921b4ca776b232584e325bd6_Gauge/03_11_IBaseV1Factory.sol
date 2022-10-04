// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

interface IBaseV1Factory {
    function isPair(address _tokenLP) external returns (bool);
}