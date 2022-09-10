// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IAllowedAirdrops {
    function isAirdropPermitted(bytes memory _addressSig) external view returns (bool);
}