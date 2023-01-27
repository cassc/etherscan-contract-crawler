// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {Permitter} from "src/actions/Permitter.sol";
import {Aggregators} from "src/actions/Aggregators.sol";
import {ClaimRewards} from "src/actions/ClaimRewards.sol";
import {LockerDeposit} from "src/actions/LockerDeposit.sol";
import {StrategyDeposit} from "src/actions/StrategyDeposit.sol";
import {UNIV2LiquidityProviding} from "src/actions/UNIV2LiquidityProviding.sol";
import {AngleLiquidityProviding} from "src/actions/AngleLiquidityProviding.sol";
import {CurveLiquidityProviding} from "src/actions/CurveLiquidityProviding.sol";
import {BalancerLiquidityProviding} from "src/actions/BalancerLiquidityProviding.sol";

/// @title Router
abstract contract Router is
    Permitter,
    Aggregators,
    ClaimRewards,
    LockerDeposit,
    StrategyDeposit,
    UNIV2LiquidityProviding,
    AngleLiquidityProviding,
    CurveLiquidityProviding,
    BalancerLiquidityProviding
{}