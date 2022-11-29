// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ILenderVerifier {
    function isAllowed(address lender) external view returns (bool);
}