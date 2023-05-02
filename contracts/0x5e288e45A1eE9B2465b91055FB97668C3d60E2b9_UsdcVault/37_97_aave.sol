// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {ILendingPoolAddressesProvider} from "./aave/ILendingPoolAddressesProvider.sol";
import {IAaveIncentivesController} from "./aave/IAaveIncentivesController.sol";
import {ILendingPool} from "./aave/ILendingPool.sol";
import {IAToken} from "./aave/IAToken.sol";
import {ILendingPoolAddressesProviderRegistry} from "./aave/ILendingPoolAddressesProviderRegistry.sol";
import {IProtocolDataProvider} from "./aave/IProtocolDataProvider.sol";