// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICTF {
    function solved(address student) external view returns (bool);
}