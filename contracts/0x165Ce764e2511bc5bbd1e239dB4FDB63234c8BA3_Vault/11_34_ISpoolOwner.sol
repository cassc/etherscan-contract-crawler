// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolOwner {
    function isSpoolOwner(address user) external view returns(bool);
}