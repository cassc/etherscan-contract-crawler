// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@violetprotocol/mauve-periphery/contracts/base/PeripheryValidation.sol';

abstract contract PeripheryValidationExtended is PeripheryValidation {
    modifier checkPreviousBlockhash(bytes32 previousBlockhash) {
        require(blockhash(block.number - 1) == previousBlockhash, 'Blockhash');
        _;
    }
}