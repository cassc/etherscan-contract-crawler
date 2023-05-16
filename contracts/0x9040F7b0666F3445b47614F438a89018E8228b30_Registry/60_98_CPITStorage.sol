// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Accountant } from '../Accountant.sol';
import { Transport } from '../transport/Transport.sol';
import { ExecutorIntegration } from '../executors/IExecutor.sol';

import { IntegrationDataTracker } from '../IntegrationDataTracker.sol';
import { GmxConfig } from '../GmxConfig.sol';

import { ILayerZeroEndpoint } from '@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol';

library CPITStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256('valio.storage.CPIT');

    struct Layout {
        uint256 lockedUntil; // timestamp of when vault is locked until
        mapping(uint256 => uint) deviation; // deviation for each window
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}