// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IStakeFactory {
    function impl() external view returns(address);
}