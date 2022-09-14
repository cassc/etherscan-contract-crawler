// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

interface IIntermediaryOriginalToken {
    function canonical() external view returns (address);
}