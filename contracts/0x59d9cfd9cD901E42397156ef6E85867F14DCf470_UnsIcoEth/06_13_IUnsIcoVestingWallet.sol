// contracts/IUnsIcoVestingWallet.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUnsIcoVestingWallet {
    function createVesting(address account, uint256 amount) external returns (bool);
}