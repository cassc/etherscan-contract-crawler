// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/IEverscale.sol";
import "../../interfaces/IERC20Metadata.sol";
import "../../interfaces/multivault/IMultiVaultFacetDepositEvents.sol";
import "../../interfaces/multivault/IMultiVaultFacetDeposit.sol";

import "../storage/MultiVaultStorage.sol";


abstract contract MultiVaultHelperEverscale is IMultiVaultFacetDepositEvents {
    function _transferToEverscaleNative(
        IMultiVaultFacetDeposit.DepositParams memory deposit,
        uint fee,
        uint value
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IEverscale.EverscaleAddress memory native = s.natives_[deposit.token];

        emit NativeTransfer(
            native.wid,
            native.addr,

            uint128(deposit.amount),
            deposit.recipient.wid,
            deposit.recipient.addr,
            value,
            deposit.expected_evers,
            deposit.payload
        );

        _emitDeposit(deposit, fee, true);
    }

    function _transferToEverscaleAlien(
        IMultiVaultFacetDeposit.DepositParams memory deposit,
        uint fee,
        uint value
    ) internal {
        emit AlienTransfer(
            block.chainid,
            uint160(deposit.token),
            IERC20Metadata(deposit.token).name(),
            IERC20Metadata(deposit.token).symbol(),
            IERC20Metadata(deposit.token).decimals(),

            uint128(deposit.amount),
            deposit.recipient.wid,
            deposit.recipient.addr,
            value,
            deposit.expected_evers,
            deposit.payload
        );

        _emitDeposit(deposit, fee, false);
    }

    function _emitDeposit(
        IMultiVaultFacetDeposit.DepositParams memory deposit,
        uint fee,
        bool isNative
    ) internal {
        emit Deposit(
            isNative ? IMultiVaultFacetTokens.TokenType.Native : IMultiVaultFacetTokens.TokenType.Alien,
            msg.sender,
            deposit.token,
            deposit.recipient.wid,
            deposit.recipient.addr,
            deposit.amount + fee,
            fee
        );
    }
}