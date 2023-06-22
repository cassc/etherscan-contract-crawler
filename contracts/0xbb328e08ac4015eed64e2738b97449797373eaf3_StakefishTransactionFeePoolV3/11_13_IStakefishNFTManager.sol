// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// This function signature is copied from:
// https://github.com/stakefish/eth2-nft-validator-contract/blob/v0.5.5/interfaces/IStakefishNFTManager.sol
interface IStakefishNFTManager {
    function validatorOwner(address validator) external view returns (address);
}