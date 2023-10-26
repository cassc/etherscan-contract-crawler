// SPDX-License-Identifier: GPL-3.0
// Copyright: https://github.com/credit-cooperative/Line-Of-Credit/blob/master/COPYRIGHT.md

 pragma solidity ^0.8.16;

import {ISpigot} from "../interfaces/ISpigot.sol";
import {ISpigotedLine} from "../interfaces/ISpigotedLine.sol";
import {LineLib} from "../utils/LineLib.sol";
import {SpigotLib} from "../utils/SpigotLib.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {Denominations} from "chainlink/Denominations.sol";

library SpigotedLineLib {
    /// @notice - maximum revenue we want to be able to take from spigots if Line is in default
    uint8 constant MAX_SPLIT = 100;

    error NoSpigot();

    error TradeFailed();

    error BadTradingPair();

    error CallerAccessDenied();

    error ReleaseSpigotFailed();

    error NotInsolvent(address module);

    error ReservesOverdrawn(address token, uint256 amountAvailable);

    event TradeSpigotRevenue(
        address indexed revenueToken,
        uint256 revenueTokenAmount,
        address indexed debtToken,
        uint256 indexed debtTokensBought
    );

    event ReservesChanged(
        address indexed token,
        int256 indexed diff,
        uint256 tokenType // 0 for revenue token, 1 for credit token
    );

    /**
     * @dev                 - priviliged internal function!
     * @notice              - Allows revenue tokens in 'escrowed' to be traded for credit tokens that aren't yet used to repay debt.
                            - The newly exchanged credit tokens are held in 'unusedTokens' ready for a Lender to withdraw using useAndRepay
                            - This feature allows a Borrower to take advantage of an increase in the value of the revenue token compared
                            - to the credit token and to in effect use less revenue tokens to be later used to repay the same amount of debt.
     * @dev                 - MUST trade all available claimTokens (unused + claimed) to targetTokens
     * @param claimToken    - The revenue token escrowed in the Spigot to sell in trade
     * @param targetToken   - The credit token that needs to be bought in order to pay down debt. Always `credits[ids[0]].token`
     * @param swapTarget    - The 0x exchange router address to call for trades
     * @param spigot        - The Spigot to claim from. Must be owned by adddress(this)
     * @param unused        - Current amount of unused claimTokens
     * @param zeroExTradeData - 0x API data to use in trade to sell `claimToken` for target
     * @return (uint, uint) - amount of targetTokens bought, total unused claimTokens after trade
     */
    function claimAndTrade(
        address claimToken,
        address targetToken,
        address payable swapTarget,
        address spigot,
        uint256 unused,
        bytes calldata zeroExTradeData
    ) external returns (uint256, uint256) {
        // can't trade into same token. causes double count for unused tokens
        if (claimToken == targetToken) {
            revert BadTradingPair();
        }

        // snapshot token balances now to diff after trade executes
        uint256 oldClaimTokens = LineLib.getBalance(claimToken);

        uint256 oldTargetTokens = LineLib.getBalance(targetToken);

        // @dev claim has to be called after we get balance
        // reverts if there are no tokens to claim
        uint256 claimed = ISpigot(spigot).claimOwnerTokens(claimToken);

        trade(claimed + unused, claimToken, swapTarget, zeroExTradeData);

        // underflow revert ensures we have more tokens than we started with
        uint256 tokensBought = LineLib.getBalance(targetToken) - oldTargetTokens;

        if (tokensBought == 0) {
            revert TradeFailed();
        } // ensure tokens bought

        uint256 newClaimTokens = LineLib.getBalance(claimToken);

        // ideally we could use oracle here to calculate # of tokens to receive
        // but sellToken might not have oracle. buyToken must have oracle

        emit TradeSpigotRevenue(claimToken, claimed, targetToken, tokensBought);

        // used reserve revenue to repay debt
        if (oldClaimTokens > newClaimTokens) {
            unchecked {
                // we check all values before math so can use unchecked
                uint256 diff = oldClaimTokens - newClaimTokens;

                emit ReservesChanged(claimToken, -int256(diff), 0);

                // used more tokens than we had in revenue reserves.
                // prevent borrower from pulling idle lender funds to repay other lenders
                if (diff > unused) revert ReservesOverdrawn(claimToken, unused);
                // reduce reserves by consumed amount
                else return (tokensBought, unused - diff);
            }
        } else {
            unchecked {
                // `unused` unlikely to overflow
                // excess revenue in trade. store in reserves
                uint256 diff = newClaimTokens - oldClaimTokens;

                emit ReservesChanged(claimToken, int256(diff), 0);

                return (tokensBought, unused + diff);
            }
        }
    }

    /**
     * @dev                     - priviliged internal function!
     * @notice                  - dumb func that executes arbitry code against a target contract
     * @param amount            - amount of revenue tokens to sell
     * @param sellToken         - revenue token being sold
     * @param swapTarget        - exchange aggregator to trade against
     * @param zeroExTradeData   - Trade data to execute against exchange for target token/amount
     * @return bool             - if trade was successful
     */
    function trade(
        uint256 amount,
        address sellToken,
        address payable swapTarget,
        bytes calldata zeroExTradeData
    ) public returns (bool) {
        if (sellToken == Denominations.ETH) {
            // if claiming/trading eth send as msg.value to dex
            (bool success, ) = swapTarget.call{value: amount}(zeroExTradeData); // TODO: test with 0x api data on mainnet fork
            if (!success) {
                revert TradeFailed();
            }
        } else {
            IERC20(sellToken).approve(swapTarget, amount);
            (bool success, ) = swapTarget.call(zeroExTradeData);
            if (!success) {
                revert TradeFailed();
            }
        }

        return true;
    }

    /**
     * @notice          - cleanup function when a Line of Credit facility has expired. Called in SecuredLine.rollover
     *                  - Reuse a Spigot across a single borrower's Line contracts
     * @param spigot    - The spigot address owned by this SpigotedLine
     * @param newLine   - The new line to transfer Spigot ownership to
     * @return bool     - if Spigot ownership was transferred or not
     */
    function rollover(address spigot, address newLine) external returns (bool) {
        require(ISpigot(spigot).updateOwner(newLine));
        return true;
    }

    function canDeclareInsolvent(address spigot, address arbiter) external view returns (bool) {
        // Must have called releaseSpigot() and sold off protocol / revenue streams already
        address owner_ = ISpigot(spigot).owner();
        if (address(this) == owner_ || arbiter == owner_) {
            revert NotInsolvent(spigot);
        }

        return true;
    }

    /**
     * @notice                  - Changes the revenue split between a Borrower's treasury and the LineOfCredit based on line health, runs with updateOwnerSplit()
     * @dev                     - callable by anyone
     * @param revenueContract   - spigoted contract to update
     * @return sucesss          - whether or not split was updated
     */
    function updateSplit(
        address spigot,
        address revenueContract,
        LineLib.STATUS status,
        uint8 defaultSplit
    ) external returns (bool) {
        (uint8 split, , bytes4 transferFunc) = ISpigot(spigot).getSetting(revenueContract);

        if (transferFunc == bytes4(0)) {
            revert NoSpigot();
        }

        if (status == LineLib.STATUS.ACTIVE && split != defaultSplit) {
            // if Line of Credit is healthy then set the split to the prior agreed default split of revenue tokens
            return ISpigot(spigot).updateOwnerSplit(revenueContract, defaultSplit);
        } else if (status == LineLib.STATUS.LIQUIDATABLE && split != MAX_SPLIT) {
            // if the Line of Credit is in distress then take all revenue to repay debt
            return ISpigot(spigot).updateOwnerSplit(revenueContract, MAX_SPLIT);
        }

        return false;
    }

    /**
   * @notice - Transfers ownership of the entire Spigot and its revenuw streams from its then Owner to either
             - the Borrower (if a Line of Credit has been been fully repaid) or
             - to the Arbiter (if the Line of Credit is liquidatable).
   * @dev    - callable by `borrower` or `arbiter`
   * @return - whether or not Spigot was released
  */
    function releaseSpigot(
        address spigot,
        LineLib.STATUS status,
        address borrower,
        address arbiter,
        address to
    ) external returns (bool) {
        if (status == LineLib.STATUS.REPAID && msg.sender == borrower) {
            if (!ISpigot(spigot).updateOwner(to)) {
                revert ReleaseSpigotFailed();
            }
            return true;
        }

        if (status == LineLib.STATUS.LIQUIDATABLE && msg.sender == arbiter) {
            if (!ISpigot(spigot).updateOwner(to)) {
                revert ReleaseSpigotFailed();
            }
            return true;
        }

        revert CallerAccessDenied();
    }

    /**
      * @notice -  Sends any remaining tokens (revenue or credit tokens) in the Spigot to the Borrower after the loan has been repaid.
                  -  In case of a Borrower default (loan status = liquidatable), this is a fallback mechanism to withdraw all the tokens and send them to the Arbiter
                  -  Does not transfer anything if line is healthy
      * @dev    - callable by `borrower` or `arbiter`
      * @return - whether or not spigot was released
    */
    function sweep(
        address to,
        address token,
        uint256 amount,
        uint256 available,
        LineLib.STATUS status,
        address borrower,
        address arbiter
    ) external returns (uint256) {
        if (available == 0) {
            return 0;
        }
        if (amount == 0) {
            // use all tokens if no amount specified specified
            amount = available;
        } else {
            if (amount > available) {
                revert ReservesOverdrawn(token, available);
            }
        }

        if (status == LineLib.STATUS.REPAID && msg.sender == borrower) {
            LineLib.sendOutTokenOrETH(token, to, amount);
            return amount;
        }

        if ((status == LineLib.STATUS.LIQUIDATABLE || status == LineLib.STATUS.INSOLVENT) && msg.sender == arbiter) {
            LineLib.sendOutTokenOrETH(token, to, amount);
            return amount;
        }

        revert CallerAccessDenied();
    }
}