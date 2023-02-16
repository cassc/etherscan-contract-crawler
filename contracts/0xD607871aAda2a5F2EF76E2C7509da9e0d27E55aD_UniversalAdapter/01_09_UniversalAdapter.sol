// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IUniversalAdapter, RevocationPair } from "../interfaces/adapters/IUniversalAdapter.sol";
import { AdapterType } from "../interfaces/adapters/IAdapter.sol";
import { ICreditManagerV2 } from "../interfaces/ICreditManagerV2.sol";
import { ZeroAddressException } from "../interfaces/IErrors.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UNIVERSAL_CONTRACT } from "../libraries/Constants.sol";

/// @title UniversalAdapter
/// @dev Implements the initial version of universal adapter, which handles allowance revocations
contract UniversalAdapter is IUniversalAdapter {
    /// @dev The target contract, which is always the same special address for the universal adapter
    address public immutable targetContract = UNIVERSAL_CONTRACT;

    /// @dev The credit manager this universal adapter connects to
    ICreditManagerV2 public immutable override creditManager;

    AdapterType public constant _gearboxAdapterType = AdapterType.UNIVERSAL;
    uint16 public constant _gearboxAdapterVersion = 1;

    /// @dev Constructor
    /// @param _creditManager Address of the Credit Manager
    constructor(address _creditManager) {
        if (_creditManager == address(0)) revert ZeroAddressException();
        creditManager = ICreditManagerV2(_creditManager);
    }

    /// @dev Sets allowances to zero for the provided spender/token pairs, for msg.sender's CA
    /// @param revocations Pairs of spenders/tokens to revoke allowances for
    function revokeAdapterAllowances(RevocationPair[] calldata revocations)
        external
    {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        _revokeAdapterAllowances(revocations, creditAccount);
    }

    /// @dev Sets allowances to zero for the provided spender/token pairs
    /// Checks that the msg.sender CA matches the expected account, since the
    /// Provided revocations can be specific to a particular CA
    /// @param revocations Pairs of spenders/tokens to revoke allowances for
    /// @param expectedCreditAccount Credit account that msg.sender is expected to have
    function revokeAdapterAllowances(
        RevocationPair[] calldata revocations,
        address expectedCreditAccount
    ) external {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        if (creditAccount != expectedCreditAccount) {
            revert UnexpectedCreditAccountException(
                expectedCreditAccount,
                creditAccount
            );
        }

        _revokeAdapterAllowances(revocations, creditAccount);
    }

    /// @dev Internal implementation for allowance revocations
    /// Checks that there are no zero addresses in a pair and sets allowance to 1
    /// through CreditManager.approveCreditAccount
    /// @param revocations Pairs of spenders/tokens to revoke allowances for
    /// @param creditAccount Credit account to revoke allowances for
    function _revokeAdapterAllowances(
        RevocationPair[] calldata revocations,
        address creditAccount
    ) internal {
        uint256 numRevocations = revocations.length;

        for (uint256 i; i < numRevocations; ) {
            address spender = revocations[i].spender;
            address token = revocations[i].token;

            if (spender == address(0) || token == address(0)) {
                revert ZeroAddressException();
            }

            uint256 allowance = IERC20(token).allowance(creditAccount, spender);

            if (allowance > 1) {
                creditManager.approveCreditAccount(
                    msg.sender,
                    spender,
                    token,
                    1
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice For demonstration purposes only. Not in V2 launch scope
    ///
    // function withdraw(address token, uint256 amount) external {
    //     address creditAccount = creditManager.getCreditAccountOrRevert(
    //         msg.sender
    //     );

    //     if (creditManager.tokenMasksMap(token) == 0)
    //         revert("Token contract is not allowed");

    //     creditManager.executeOrder(
    //         msg.sender,
    //         token,
    //         abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, amount)
    //     );

    //     creditManager.fullCollateralCheck(creditAccount);
    // }
}