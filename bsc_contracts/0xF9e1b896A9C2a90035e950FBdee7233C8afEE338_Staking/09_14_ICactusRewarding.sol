//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICactusRewarding {
    function getReferrer(address _user) external returns (address);
}