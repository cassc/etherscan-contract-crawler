// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { Accountant } from './Accountant.sol';
import { ITransport } from './transport/ITransport.sol';
import { ExecutorIntegration } from './executors/IExecutor.sol';
import { IntegrationDataTracker } from './IntegrationDataTracker.sol';

import { IGmxRouter } from './interfaces/IGmxRouter.sol';
import { IGmxVault } from './interfaces/IGmxVault.sol';
import { IGmxPositionRouter } from './interfaces/IGmxPositionRouter.sol';

contract GmxConfig {
    IGmxRouter public router;
    IGmxPositionRouter public positionRouter;
    IGmxVault public vault;
    bytes32 public referralCode;
    uint public maxPositions = 2;
    uint public maxOpenRequests = 2; // The number of unexecuted requests a vault can have open at 1 time.
    uint public acceptablePriceDeviationBasisPoints = 200; // 2%

    constructor(
        address _gmxRouter,
        address _gmxPositionRouter,
        address _gmxVault
    ) {
        router = IGmxRouter(_gmxRouter);
        positionRouter = IGmxPositionRouter(_gmxPositionRouter);
        vault = IGmxVault(_gmxVault);
    }
}