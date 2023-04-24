// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/EIP712.sol";
import "../../../lib/ERC20.sol";
import "../../../lib/MathUint248.sol";
import "../../../lib/SignatureUtil.sol";
import "../../../thirdparty/BytesUtil.sol";
import "../../iface/ExchangeData.sol";

/// @title DepositTransaction
/// @author Brecht Devos - <[email protected]>
library DepositTransaction
{
    using BytesUtil for bytes;
    using MathUint248 for uint248;
    using MathUint for uint256;

    struct Deposit
    {
        uint depositType;
        address to;
        uint32 toAccountID;
        uint32 tokenID;
        uint248 amount;
    }

    function process(
        ExchangeData.State        storage S,
        ExchangeData.BlockContext memory  /*ctx*/,
        bytes                     memory  data,
        uint                              offset,
        bytes                     memory  /*auxiliaryData*/
        )
        internal
    {
        // Read in the deposit
        Deposit memory deposit;
        readTx(data, offset, deposit);
        if (deposit.amount == 0) {
            return;
        }

        // depositType 0: deposit by exchange::deposit()
        // depositType 1: deposit by transfer tokens to DepositContract directly 
        if(deposit.depositType == 0) { 
            // Process the deposit
            ExchangeData.Deposit memory pendingDeposit = S.pendingDeposits[deposit.to][deposit.tokenID];
            // Make sure the deposit was actually done
            require(pendingDeposit.timestamp > 0, "DEPOSIT_DOESNT_EXIST");

            // Processing partial amounts of the deposited amount is allowed.
            // This is done to ensure the user can do multiple deposits after each other
            // without invalidating work done by the exchange owner for previous deposit amounts.

            require(pendingDeposit.amount >= deposit.amount, "INVALID_AMOUNT");
            pendingDeposit.amount = pendingDeposit.amount.sub(deposit.amount);

            // If the deposit was fully consumed, reset it so the storage is freed up
            // and the owner receives a gas refund.
            if (pendingDeposit.amount == 0) {
                delete S.pendingDeposits[deposit.to][deposit.tokenID];
            } else {
                S.pendingDeposits[deposit.to][deposit.tokenID] = pendingDeposit;
            }

        }else if(deposit.depositType == 1) {
            uint32 tokenId = deposit.tokenID;
            uint256 unconfirmedBalance;

            if (tokenId == 0) {
                unconfirmedBalance = address(S.depositContract).balance.sub(S.tokenIdToDepositBalance[tokenId]);
            } else {
                address token = S.tokenIdToToken[tokenId];
                unconfirmedBalance = ERC20(token).balanceOf(address(S.depositContract)).sub(S.tokenIdToDepositBalance[tokenId]);
            }

            require(unconfirmedBalance >= deposit.amount, "INVALID_DIRECT_DEPOSIT_AMOUNT");

            S.tokenIdToDepositBalance[deposit.tokenID] = S.tokenIdToDepositBalance[deposit.tokenID].add(deposit.amount);
        }else{
            revert("INVALID_DEPOSIT_TYPE");
        }
    }

    function readTx(
        bytes   memory data,
        uint           offset,
        Deposit memory deposit
        )
        internal
        pure
    {
        uint _offset = offset;

        // We don't use abi.decode for this because of the large amount of zero-padding
        // bytes the circuit would also have to hash.

        deposit.depositType = data.toUint8Unsafe(_offset);
        _offset += 1;
        deposit.to = data.toAddressUnsafe(_offset);
        _offset += 20;
        deposit.toAccountID = data.toUint32Unsafe(_offset);
        _offset += 4;
        deposit.tokenID = data.toUint32Unsafe(_offset);
        _offset += 4;
        deposit.amount = data.toUint248Unsafe(_offset);
        _offset += 31;
    }
}