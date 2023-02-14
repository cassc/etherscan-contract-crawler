// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/IReward.sol";
import "../interfaces/IInvestable.sol";

interface IStrategy is IInvestable, IReward {}