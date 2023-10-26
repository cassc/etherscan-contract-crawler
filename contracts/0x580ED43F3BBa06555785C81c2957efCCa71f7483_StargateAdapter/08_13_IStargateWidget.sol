// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

interface IStargateWidget {
    function partnerSwap(bytes2 _partnerId) external;
}