// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IKyc {
    function isAllowed(address _address) external view returns(bool);
}