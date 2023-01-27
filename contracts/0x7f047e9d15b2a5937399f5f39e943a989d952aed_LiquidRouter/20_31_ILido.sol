// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface ILido {
    function submit(address _referral) external payable;
}