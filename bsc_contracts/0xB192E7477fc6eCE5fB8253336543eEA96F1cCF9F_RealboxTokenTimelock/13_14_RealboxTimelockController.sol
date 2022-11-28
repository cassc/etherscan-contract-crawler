// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/governance/TimelockController.sol';

/**
 * @dev Will be used as the owner of `RealboxTokenTimelock` smart contract,
 * it enforces a timelock on all `onlyOwner` maintenance operations. 
 * 
 * At the deploy time, proposer and executor should be set to a multisig address
 * In the long-term, they will be replaced by a DAO
 */
contract RealboxTimelockController is TimelockController {
    constructor(address[] memory _multisigWallet) TimelockController(3 seconds, _multisigWallet, _multisigWallet) {}
}