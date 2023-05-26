// DELTA-BUG-BOUNTY
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../../../libs/Address.sol";
import "../../../libs/SafeMath.sol";

import "../../Common/OVLBase.sol";
import "../../../../common/OVLTokenTypes.sol";
import "../../Common/OVLVestingCalculator.sol";

import "../../../../interfaces/IOVLTransferHandler.sol";
import "../../../../interfaces/IDeltaDistributor.sol";
import "../../../../interfaces/IDeltaToken.sol";

contract OVLTransferHandler is OVLBase, OVLVestingCalculator, IOVLTransferHandler {
    using SafeMath for uint256;
    using Address for address;

    address public immutable UNI_DELTA_WETH_PAIR;
    address public immutable DEEP_FARMING_VAULT;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address pair, address dfv) {
        UNI_DELTA_WETH_PAIR = pair;
        DEEP_FARMING_VAULT = dfv;
    }

    function _removeBalanceFromSender(UserInformation storage senderInfo, address sender, bool immatureReceiverWhitelisted, uint256 amount) internal returns (uint256 totalRemoved) {
        uint256 mostMatureTxIndex = senderInfo.mostMatureTxIndex;
        uint256 lastInTxIndex = senderInfo.lastInTxIndex;

        // We check if recipent can get immature tokens, if so we go from the most imature first to be most fair to the user
        if (immatureReceiverWhitelisted) {

            //////
            ////
            // we go from the least mature balance to the msot mature meaning --
            ////
            /////

            uint256 accumulatedBalance;

            while (true) {
                uint256 leastMatureTxAmount = vestingTransactions[sender][lastInTxIndex].amount;
                // Can never underflow due to if conditional
                uint256 remainingBalanceNeeded = amount - accumulatedBalance;

                if (leastMatureTxAmount >= remainingBalanceNeeded) {
                    // We got enough in this bucket to cover the amount
                    // We remove it from total and dont adjust the fully vesting timestamp
                    // Because there might be tokens left still in it
                    totalRemoved += remainingBalanceNeeded;
                    vestingTransactions[sender][lastInTxIndex].amount = leastMatureTxAmount - remainingBalanceNeeded; // safe math already checked
                    // We got what we wanted we leave the loop
                    break;
                } else {
                    //we add the whole amount of this bucket to the accumulated balance
                    accumulatedBalance = accumulatedBalance.add(leastMatureTxAmount);
                    totalRemoved += leastMatureTxAmount;
                    delete vestingTransactions[sender][lastInTxIndex];
                    // And go to the more mature tx
                    if (lastInTxIndex == 0) {
                        lastInTxIndex = QTY_EPOCHS;
                    }
                    lastInTxIndex--;
                    // If we can't get enough in this tx and this is the last one, then we bail
                    if (lastInTxIndex == mostMatureTxIndex) {
                        // If we still have enough to cover in the mature balance we use that
                        uint256 maturedBalanceNeeded = amount - accumulatedBalance;
                        // Exhaustive underflow check
                    
                        senderInfo.maturedBalance = senderInfo.maturedBalance.sub(maturedBalanceNeeded, "OVLTransferHandler: Insufficient funds");
                        totalRemoved += maturedBalanceNeeded;
                        break;
                    }
                }
            }
             // We write to storage the lastTx Index, which was in memory and we looped over it (or not)
            senderInfo.lastInTxIndex = lastInTxIndex;
            return totalRemoved; 
            // End of logic in case reciever is whitelisted ( return assures)
        }

        uint256 maturedBalance = senderInfo.maturedBalance;

        //////
        ////
        // we go from the most mature balance up
        ////
        /////

        if (maturedBalance >= amount) {
            senderInfo.maturedBalance = maturedBalance - amount; // safemath safe
            totalRemoved = amount;
        } else {
            // Possibly using a partially vested transaction
            uint256 accumulatedBalance = maturedBalance;
            totalRemoved = maturedBalance;

            // Use the entire balance to start
            senderInfo.maturedBalance = 0;

            while (amount > accumulatedBalance) {
                VestingTransaction memory mostMatureTx = vestingTransactions[sender][mostMatureTxIndex];
                // Guaranteed by `while` condition
                uint256 remainingBalanceNeeded = amount - accumulatedBalance;

                // Reduce this transaction as the final one
                VestingTransactionDetailed memory dtx = getTransactionDetails(mostMatureTx, block.timestamp);
                // credit is how much i got from this bucket
                // So if i didnt get enough from this bucket here we zero it and move to the next one
                if (remainingBalanceNeeded >= dtx.mature) {
                    totalRemoved += dtx.amount;
                    accumulatedBalance = accumulatedBalance.add(dtx.mature);
                    
                    delete vestingTransactions[sender][mostMatureTxIndex]; // refund gas
                } else {
                    // Remove the only needed amount
                    // Calculating debt based on the actual clamped credit eliminates
                    // the need for debit/credit ratio checks we initially had.
                    // Big gas savings using this one weird trick. Vitalik HATES it.
                    uint256 outputDebit = calculateTransactionDebit(dtx, remainingBalanceNeeded, block.timestamp);
                    remainingBalanceNeeded = outputDebit.add(remainingBalanceNeeded);
                    totalRemoved += remainingBalanceNeeded;

                    // We dont need to adjust timestamp
                    vestingTransactions[sender][mostMatureTxIndex].amount = mostMatureTx.amount.sub(remainingBalanceNeeded, "Removing too much from bucket");
                    break;
                }

                // If we just went throught he lasttx bucket, and we did not get enough then we bail
                // Note if its the lastTransaction it already had a break;
                if (mostMatureTxIndex == lastInTxIndex && accumulatedBalance < amount) { // accumulatedBalance < amount because of the case its exactly equal with first if
                    // Avoid ever looping around a second time because that would be bad
                    revert("OVLTransferHandler: Insufficient funds");
                }

                // We just emptied this so most mature one must be the next one
                mostMatureTxIndex++;

                if(mostMatureTxIndex == QTY_EPOCHS) {
                    mostMatureTxIndex = 0;
                }
            }
            // We remove the entire amount removed 
            // We already added amount
            senderInfo.mostMatureTxIndex = mostMatureTxIndex;
        }
    }


    // function _transferTokensToRecipient(address recipient, UserInformation memory senderInfo, UserInformation memory recipientInfo, uint256 amount) internal {
    function _transferTokensToRecipient(UserInformation storage recipientInfo, bool isSenderWhitelisted, address recipient, uint256 amount) internal {
        // If the sender can send fully or this recipent is whitelisted to not get vesting we just add it to matured balance
        (bool noVestingWhitelisted, uint256 maturedBalance, uint256 lastTransactionIndex) = (recipientInfo.noVestingWhitelisted, recipientInfo.maturedBalance, recipientInfo.lastInTxIndex);

        if(isSenderWhitelisted || noVestingWhitelisted) {
            recipientInfo.maturedBalance = maturedBalance.add(amount);
            return;
        }

        VestingTransaction storage lastTransaction = vestingTransactions[recipient][lastTransactionIndex];
  
        // Do i fit in this bucket?
        // conditions for fitting inside a bucket are
        // 1 ) Either its less than 2 days old
        // 2 ) Or its more than 14 days old
        // 3 ) Or we move to the next one - which is empty or already matured
        // Note that only the first bucket checked can logically be less than 2 days old, this is a important optimization
        // So lets take care of that case now, so its not checked in the loop.

        uint256 timestampNow = block.timestamp;
        uint256 fullVestingTimestamp = lastTransaction.fullVestingTimestamp;

        if (timestampNow >= fullVestingTimestamp) {// Its mature we move it to mature and override or we move to the next one, which is always either 0 or matured
            recipientInfo.maturedBalance = maturedBalance.add(lastTransaction.amount);

            lastTransaction.amount = amount;
            lastTransaction.fullVestingTimestamp = timestampNow + FULL_EPOCH_TIME;
        } else if (fullVestingTimestamp >= timestampNow + SECONDS_PER_EPOCH * (QTY_EPOCHS - 1)) {// we add 12 days
            // we avoid overflows from 0 fullyvestedtimestamp
            // if fullyVestingTimestamp is bigger than that we should increment
            // but not bigger than fullyVesting
            // This check is exhaustive
            // If this is the case we just put it in this bucket.
            lastTransaction.amount = lastTransaction.amount.add(amount);
            /// No need to adjust timestamp`
        } else { 

            // We move into the next one
            lastTransactionIndex++; 

            if (lastTransactionIndex == QTY_EPOCHS) { lastTransactionIndex = 0; } // Loop over

            recipientInfo.lastInTxIndex = lastTransactionIndex;

            // To figure out if this is a empty bucket or a stale one
            // Its either the most mature one 
            // Or its 0
            // There is no other logical options
            // If this is the most mature one then we go > with most mature
            uint256 mostMature = recipientInfo.mostMatureTxIndex;
            
            if (mostMature == lastTransactionIndex) {
                // It was the most mature one, so we have to increment the most mature index
                mostMature++;

                if (mostMature == QTY_EPOCHS) { mostMature = 0; }

                recipientInfo.mostMatureTxIndex = mostMature;
            }

            VestingTransaction storage evenLatestTransaction = vestingTransactions[recipient][lastTransactionIndex];

            // Its mature we move it to mature and override or we move to the next one, which is always either 0 or matured
            recipientInfo.maturedBalance = maturedBalance.add(evenLatestTransaction.amount);

            evenLatestTransaction.amount = amount;
            evenLatestTransaction.fullVestingTimestamp = timestampNow + FULL_EPOCH_TIME;
        }
    }

    function addAllowanceToDFV(address sender) internal {
        // If you transferFrom from anyone even 1 gwei unit
        // This will force dfv to have infinite allowance
        // But this is not abug because DFV has defacto infinite allowance becaose of this function
        // So there is no change
        _allowances[sender][DEEP_FARMING_VAULT] = uint(-1);
    }



    function handleUniswapAdjustmenets() internal{
        uint256 newLPSupply = IERC20(UNI_DELTA_WETH_PAIR).balanceOf(UNI_DELTA_WETH_PAIR);
        require(newLPSupply >= lpTokensInPair, "DELTAToken: Liquidity removals are forbidden");
        // We allow people to bump the number of LP tokens inside the pair, but we dont allow them to go lower
        // Making liquidity withdrawals impossible
        // Because uniswap queries banaceOf before doing a burn, that means we can detect a inflow of LP tokens
        // But someone could send them and then reset with this function
        // This is why we "lock" the bigger amount here and dont allow a lower amount than the last time
        // Making it impossible to anyone who sent the liquidity tokens to the pair (which is nessesary to burn) not be able to burn them
        lpTokensInPair = newLPSupply;

    }

    // This function does not need authentication, because this is EXCLUSIVELY
    // ever meant to be called using delegatecall() from the main token.
    // The memory it modifies in DELTAToken is what effects user balances.
    function handleTransfer(address sender, address recipient, uint256 amount) external override {
            require(sender != recipient, "DELTAToken: Can not send DELTA to yourself");
            require(sender != address(0), "ERC20: transfer from the zero address"); 
            require(recipient != address(0), "ERC20: transfer to the zero address");
            
            /// Liquidity removal protection
            if (!liquidityRebasingPermitted && (sender == UNI_DELTA_WETH_PAIR || recipient == UNI_DELTA_WETH_PAIR)) {
                handleUniswapAdjustmenets();
            }

            if(recipient == DEEP_FARMING_VAULT) {
                addAllowanceToDFV(sender);
            }

            UserInformation storage recipientInfo = _userInformation[recipient];
            UserInformation storage senderInfo = _userInformation[sender];
            uint256 totalRemoved = _removeBalanceFromSender(senderInfo, sender, recipientInfo.immatureReceiverWhitelisted, amount);
            uint256 toDistributor = totalRemoved.sub(amount, "OVLTransferHandler: Insufficient funds");

            // We remove from max balance totals
            senderInfo.maxBalance = senderInfo.maxBalance.sub(totalRemoved, "OVLTransferHandler: Insufficient funds");

            // Sanity check
            require(totalRemoved >= amount, "OVLTransferHandler: Insufficient funds");
            // Max is 90% of total removed
            require(amount.mul(9) >= toDistributor, "DELTAToken: Burned too many tokens"); 

            _creditDistributor(sender, toDistributor);
            //////
            /// We add tokens to the recipient
            //////
            _transferTokensToRecipient(recipientInfo, senderInfo.fullSenderWhitelisted, recipient, amount);
            // We add to total balance for sanity checks and uniswap router
            recipientInfo.maxBalance = recipientInfo.maxBalance.add(amount);

            emit Transfer(sender, recipient, amount);
    }

    function _creditDistributor(address creditedBy, uint256 amount) internal {
        address _distributor = distributor; // gas savings for storage reads
        UserInformation storage distributorInfo = _userInformation[distributor];
        distributorInfo.maturedBalance = distributorInfo.maturedBalance.add(amount); // Should trigger an event here
        distributorInfo.maxBalance = distributorInfo.maxBalance.add(amount); 

        IDeltaDistributor(_distributor).creditUser(creditedBy, amount);
        emit Transfer(creditedBy, _distributor, amount);
    }

}