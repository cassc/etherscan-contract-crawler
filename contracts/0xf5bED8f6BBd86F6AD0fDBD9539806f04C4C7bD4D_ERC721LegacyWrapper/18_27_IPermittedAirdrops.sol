// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IPermittedAirdrops {
    function isValidAirdrop(bytes memory _addressSig) external view returns (bool);
}