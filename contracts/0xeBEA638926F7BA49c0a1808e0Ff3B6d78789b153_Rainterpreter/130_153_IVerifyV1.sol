// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

type VerifyStatus is uint256;

interface IVerifyV1 {
    function accountStatusAtTime(
        address account,
        uint256 timestamp
    ) external view returns (VerifyStatus);
}