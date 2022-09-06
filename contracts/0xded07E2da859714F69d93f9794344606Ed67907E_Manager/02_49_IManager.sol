// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../common/IMulticall.sol";
import "./IManagerBase.sol";
import "./ISwapManager.sol";
import "./IPositionManager.sol";
import "./ISelfPermit.sol";

interface IManager is IManagerBase, ISwapManager, IPositionManager, IMulticall, ISelfPermit {}