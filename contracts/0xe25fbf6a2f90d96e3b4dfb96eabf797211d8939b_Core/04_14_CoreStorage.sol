// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "./ICore.sol";

/// @notice Storage for Core
/// @author Recursive Research Inc
abstract contract CoreStorage is ICore {
    bool public override paused;

    /// @notice The initial fee to be taken from the use of the Rift protocol out of core.MAX_FEE()
    uint256 public override protocolFee;

    /// @notice The destination address for that fee
    address public override feeTo;

    /// @notice The address of the globally accepted wrapped native contract for the chain
    address public override wrappedNative;
}