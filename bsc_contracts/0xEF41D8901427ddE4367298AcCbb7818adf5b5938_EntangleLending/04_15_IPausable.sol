// SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.15;

interface IPausable {
    function pause() external;
    function unpause() external;
}