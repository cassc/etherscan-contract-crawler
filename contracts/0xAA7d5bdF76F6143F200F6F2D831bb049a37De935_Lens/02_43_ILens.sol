// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "./ILensBase.sol";
import "./IPositionLens.sol";
import "./ITickLens.sol";
import "./IQuoter.sol";

interface ILens is ILensBase, IQuoter, IPositionLens, ITickLens {}