//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IAgent {
    function transfer(
        address _token,
        address _to,
        uint256 _value
    ) external;
}