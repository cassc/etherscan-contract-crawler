// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./spool/ISpoolExternal.sol";
import "./spool/ISpoolReallocation.sol";
import "./spool/ISpoolDoHardWork.sol";
import "./spool/ISpoolStrategy.sol";
import "./spool/ISpoolBase.sol";

/// @notice Utility Interface for central Spool implementation
interface ISpool is ISpoolExternal, ISpoolReallocation, ISpoolDoHardWork, ISpoolStrategy, ISpoolBase {}