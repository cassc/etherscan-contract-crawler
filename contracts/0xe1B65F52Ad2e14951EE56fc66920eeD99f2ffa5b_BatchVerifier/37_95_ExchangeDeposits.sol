// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/AddressUtil.sol";
import "../../../lib/MathUint248.sol";
import "../../../lib/MathUint.sol";
import "../../iface/ExchangeData.sol";
import "./ExchangeMode.sol";
import "./ExchangeTokens.sol";


/// @title ExchangeDeposits.
/// @author Daniel Wang  - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library ExchangeDeposits
{
    using AddressUtil       for address payable;
    using MathUint248       for uint248;
    using MathUint          for uint;
    using ExchangeMode      for ExchangeData.State;
    using ExchangeTokens    for ExchangeData.State;

    event DepositRequested(
        address from,
        address to,
        address token,
        uint32  tokenId,
        uint248  amount
    );

    event DepositFee(
        uint256  amount
    );

    function deposit(
        ExchangeData.State storage S,
        address from,
        address to,
        address tokenAddress,
        uint248  amount,                 // can be zero
        bytes   memory extraData
        )
        internal  // inline call
    {
        require(to != address(0), "ZERO_ADDRESS");

        // Deposits are still possible when the exchange is being shutdown, or even in withdrawal mode.
        // This is fine because the user can easily withdraw the deposited amounts again.
        // We don't want to make all deposits more expensive just to stop that from happening.

        (uint32 tokenID, bool tokenFound) = S.findTokenID(tokenAddress);
        if(!tokenFound) {
            tokenID = S.registerToken(tokenAddress, false);
        }

        if (tokenID == 0 && amount == 0) {
            require(msg.value == 0, "INVALID_ETH_DEPOSIT");
        }

        // A user may need to pay a fixed ETH deposit fee, set by the protocol.
        uint256 depositFeeETH = 0;
        if (needChargeDepositFee(S)) {
            depositFeeETH = S.depositState.depositFee;
            emit DepositFee(depositFeeETH);
        }

        // Check ETH value sent
        require(msg.value >= depositFeeETH, "INSUFFICIENT_DEPOSIT_FEE");

        uint256 ethAmountToDeposit = msg.value - depositFeeETH;

        // Transfer the tokens to this contract
        uint248 amountDeposited = S.depositContract.deposit{value: ethAmountToDeposit}(
            from,
            tokenAddress,
            amount,
            extraData
        );

        // Add the amount to the deposit request and reset the time the operator has to process it
        ExchangeData.Deposit memory _deposit = S.pendingDeposits[to][tokenID];
        _deposit.timestamp = uint64(block.timestamp);
        _deposit.amount = _deposit.amount.add(amountDeposited);
        S.pendingDeposits[to][tokenID] = _deposit;


        S.tokenIdToDepositBalance[tokenID] = S.tokenIdToDepositBalance[tokenID].add(amountDeposited);

        emit DepositRequested(
            from,
            to,
            tokenAddress,
            tokenID,
            amountDeposited
        );
    }

    function setDepositParams(
        ExchangeData.State storage S,
        uint256 freeDepositMax,
        uint256 freeDepositRemained,
        uint256 freeSlotPerBlock,
        uint256 depositFee
    ) internal {
        S.depositState.freeDepositMax = freeDepositMax;
        S.depositState.freeDepositRemained = freeDepositRemained;
        S.depositState.freeSlotPerBlock = freeSlotPerBlock;
        S.depositState.depositFee = depositFee;
    }

    function needChargeDepositFee(ExchangeData.State storage S)
        private
        returns (bool)
    {
        bool needCharge = false;

        // S.depositState.freeDepositRemained + (block.number - S.depositState.lastDepositBlockNum) * S.depositState.freeSlotPerBlock;
        uint256 freeDepositRemained = S.depositState.freeDepositRemained.add(
            (block.number.sub(S.depositState.lastDepositBlockNum)).mul(S.depositState.freeSlotPerBlock)
        );
        
        if (freeDepositRemained > S.depositState.freeDepositMax) {
            freeDepositRemained = S.depositState.freeDepositMax;
        }

        if (freeDepositRemained > 0) {
            freeDepositRemained -= 1;
        } else {
            needCharge = true;
        }

        S.depositState.freeDepositRemained = freeDepositRemained;
        S.depositState.lastDepositBlockNum = block.number;

        return needCharge;
    }
}