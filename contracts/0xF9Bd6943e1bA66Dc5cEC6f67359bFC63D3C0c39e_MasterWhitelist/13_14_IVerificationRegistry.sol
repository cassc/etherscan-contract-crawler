// SPDX-License-Identifier: MIT
//slither-disable-next-line solc-version
pragma solidity =0.8.14;

interface IVerificationRegistry {
    function isVerified(address subject) external view returns (bool);
}