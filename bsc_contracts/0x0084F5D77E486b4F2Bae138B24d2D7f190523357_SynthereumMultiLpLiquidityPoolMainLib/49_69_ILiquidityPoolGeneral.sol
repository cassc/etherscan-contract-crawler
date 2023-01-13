// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {
  ISynthereumLiquidityPoolInteraction
} from './ILiquidityPoolInteraction.sol';
import {
  ISynthereumDeployment
} from '../../../common/interfaces/IDeployment.sol';

interface ISynthereumLiquidityPoolGeneral is
  ISynthereumDeployment,
  ISynthereumLiquidityPoolInteraction
{}