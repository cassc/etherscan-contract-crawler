// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "../interfaces/IManagerBase.sol";
import "../interfaces/IPrimitiveManager.sol";
import "./Reentrancy.sol";
import "../libraries/EngineAddress.sol";

/// @title   ManagerBase contract
/// @author  Primitive
/// @notice  Base contract of the Manager
abstract contract ManagerBase is IManagerBase, Reentrancy {
    /// @notice Data struct reused by callbacks
    struct CallbackData {
        address payer;
        address risky;
        address stable;
    }

    /// @inheritdoc IManagerBase
    address public immutable override factory;

    /// @inheritdoc IManagerBase
    address public immutable override WETH9;

    /// @inheritdoc IManagerBase
    address public immutable override positionDescriptor;

    /// @param factory_  Address of a PrimitiveFactory
    /// @param WETH9_    Address of WETH9
    /// @param positionDescriptor_    Address of the position renderer
    constructor(
        address factory_,
        address WETH9_,
        address positionDescriptor_
    ) {
        if (factory_ == address(0) || WETH9_ == address(0) || positionDescriptor_ == address(0))
            revert WrongConstructorParametersError();

        factory = factory_;
        WETH9 = WETH9_;
        positionDescriptor = positionDescriptor_;
    }
}