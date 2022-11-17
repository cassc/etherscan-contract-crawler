// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

interface IStakedNote {
    function stakeAll() external;
    function claimBAL() external;
}