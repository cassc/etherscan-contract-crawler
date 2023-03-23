// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IGovToken {
    function delegates(address account) external view returns (address delegatee);
}