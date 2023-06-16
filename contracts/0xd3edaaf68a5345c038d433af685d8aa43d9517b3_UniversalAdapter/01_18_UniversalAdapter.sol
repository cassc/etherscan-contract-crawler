// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AbstractAdapter } from "./AbstractAdapter.sol";
import { AdapterType } from "../interfaces/adapters/IAdapter.sol";
import { ICreditManagerV2 } from "../interfaces/ICreditManagerV2.sol";
import { IUniversalAdapter, RevocationPair } from "../interfaces/adapters/IUniversalAdapter.sol";
import { ZeroAddressException } from "../interfaces/IErrors.sol";

import { UNIVERSAL_CONTRACT } from "../libraries/Constants.sol";

/// @title Universal adapter
/// @notice Implements the initial version of universal adapter, which handles allowance revocations
contract UniversalAdapter is AbstractAdapter, IUniversalAdapter {
    AdapterType public constant override _gearboxAdapterType =
        AdapterType.UNIVERSAL;
    uint16 public constant override _gearboxAdapterVersion = 2;

    /// @notice Constructor
    /// @param _creditManager Credit manager address
    /// @dev Target contract is always the same special address
    constructor(address _creditManager)
        AbstractAdapter(_creditManager, UNIVERSAL_CONTRACT)
    {} // F: [UA-1]

    /// @notice Revokes allowances for specified spender/token pairs
    /// @param revocations Spender/token pairs to revoke allowances for
    function revokeAdapterAllowances(RevocationPair[] calldata revocations)
        external
        creditFacadeOnly // F: [UA-2]
    {
        address creditAccount = _creditAccount();

        uint256 numRevocations = revocations.length;
        for (uint256 i; i < numRevocations; ) {
            address spender = revocations[i].spender;
            address token = revocations[i].token;

            if (spender == address(0) || token == address(0)) {
                revert ZeroAddressException(); // F: [UA-3]
            }

            uint256 allowance = IERC20(token).allowance(creditAccount, spender);
            if (allowance > 1) {
                creditManager.approveCreditAccount(
                    _creditFacade(),
                    spender,
                    token,
                    1
                ); // F: [UA-4]
            }

            unchecked {
                ++i;
            }
        }
    }

    // /// @notice Withdraws given amount of token from the credit account to the specified address
    // /// @param token Address of the token to withdraw (must be collateral token in the credit manager)
    // /// @param to Token recipient
    // /// @param amount Amount to withdraw
    // function withdrawTo(
    //     address token,
    //     address to,
    //     uint256 amount
    // ) external creditFacadeOnly {
    //     _getMaskOrRevert(token);
    //     creditManager.executeOrder(
    //         _creditFacade(),
    //         token,
    //         abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
    //     );
    // }
}