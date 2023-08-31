// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IPaymentSplitter {
    function releasable(address account) external view returns (uint256);

    function release(address payable account) external;
}