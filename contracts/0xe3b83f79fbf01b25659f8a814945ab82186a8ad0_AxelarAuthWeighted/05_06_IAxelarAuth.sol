// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IOwnable.sol';

interface IAxelarAuth is IOwnable {
    function validateProof(bytes32 messageHash, bytes calldata proof) external returns (bool currentOperators);

    function transferOperatorship(bytes calldata params) external;
}