// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.6;

import "@primitivefi/rmm-core/contracts/interfaces/callback/IPrimitiveDepositCallback.sol";

/// @title   Interface of MarginManager contract
/// @author  Primitive
interface IMarginManager is IPrimitiveDepositCallback {
    /// ERRORS ///

    /// @notice Thrown when trying to deposit or withdraw 0 risky and stable
    error ZeroDelError();

    /// EVENTS ///

    /// @notice           Emitted when funds are deposited
    /// @param payer      Address depositing the funds
    /// @param recipient  Address receiving the funds in their margin
    /// @param engine     Engine receiving the funds
    /// @param risky      Address of the risky token
    /// @param stable     Address of the stable token
    /// @param delRisky   Amount of deposited risky
    /// @param delStable  Amount of deposited stable
    event Deposit(
        address indexed payer,
        address indexed recipient,
        address indexed engine,
        address risky,
        address stable,
        uint256 delRisky,
        uint256 delStable
    );

    /// @notice           Emitted when funds are withdrawn
    /// @param payer      Address withdrawing the funds
    /// @param recipient  Address receiving the funds in their wallet
    /// @param engine     Engine where the funds are withdrawn from
    /// @param risky      Address of the risky token
    /// @param stable     Address of the stable token
    /// @param delRisky   Amount of withdrawn risky
    /// @param delStable  Amount of withdrawn stable
    event Withdraw(
        address indexed payer,
        address indexed recipient,
        address indexed engine,
        address risky,
        address stable,
        uint256 delRisky,
        uint256 delStable
    );

    /// EFFECT FUNCTIONS ///

    /// @notice           Deposits funds into the margin of a Primitive Engine
    /// @dev              Since the PrimitiveManager contract keeps track of the margins, it
    ///                   will deposit the funds into the Primitive Engine using its own address
    /// @param recipient  Address receiving the funds in their margin
    /// @param risky      Address of the risky token
    /// @param stable     Address of the stable token
    /// @param delRisky   Amount of risky token to deposit
    /// @param delStable  Amount of stable token to deposit
    function deposit(
        address recipient,
        address risky,
        address stable,
        uint256 delRisky,
        uint256 delStable
    ) external payable;

    /// @notice           Withdraws funds from the margin of a Primitive Engine
    /// @param recipient  Address receiving the funds in their wallet
    /// @param engine     Primitive Engine to withdraw from
    /// @param delRisky   Amount of risky token to withdraw
    /// @param delStable  Amount of stable token to withdraw
    function withdraw(
        address recipient,
        address engine,
        uint256 delRisky,
        uint256 delStable
    ) external;

    /// VIEW FUNCTIONS ///

    /// @notice                Returns the margin of an account for a specific Primitive Engine
    /// @param account         Address of the account
    /// @param engine          Address of the engine
    /// @return balanceRisky   Balance of risky in the margin of the user
    /// @return balanceStable  Balance of stable in the margin of the user
    function margins(address account, address engine)
        external
        view
        returns (uint128 balanceRisky, uint128 balanceStable);
}