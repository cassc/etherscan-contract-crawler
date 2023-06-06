// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IPomace} from "pomace/interfaces/IPomace.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {UintArrayLib} from "array-lib/UintArrayLib.sol";

import {ICrossMarginEngine} from "pomace/interfaces/ICrossMarginEngine.sol";

import "pomace/libraries/TokenIdUtil.sol";
import "pomace/libraries/BalanceUtil.sol";

// Cross Margin libraries and configs
import "../libraries/AccountUtil.sol";

import {CrossMarginAccount} from "./types.sol";
import "../config/errors.sol";

/**
 * @title CrossMarginPhysicalLib
 * @dev   This library is in charge of updating the simple account struct and do validations
 */
library CrossMarginPhysicalLib {
    using BalanceUtil for Balance[];
    using AccountUtil for Position[];
    using UintArrayLib for uint256[];
    using TokenIdUtil for uint256;

    /**
     * @dev return true if the account has no short,long positions nor collateral
     */
    function isEmpty(CrossMarginAccount storage account) external view returns (bool) {
        return account.shorts.isEmpty() && account.longs.isEmpty() && account.collaterals.isEmpty();
    }

    ///@dev Increase the collateral in the account
    ///@param account CrossMarginAccount storage that will be updated
    function addCollateral(CrossMarginAccount storage account, uint8 collateralId, uint80 amount) public {
        if (amount == 0) return;

        (bool found, uint256 index) = account.collaterals.indexOf(collateralId);

        if (!found) {
            account.collaterals.push(Balance(collateralId, amount));
        } else {
            account.collaterals[index].amount += amount;
        }
    }

    ///@dev Reduce the collateral in the account
    ///@param account CrossMarginAccount storage that will be updated
    function removeCollateral(CrossMarginAccount storage account, uint8 collateralId, uint80 amount) public {
        Balance[] memory collaterals = account.collaterals;

        (bool found, uint256 index) = collaterals.indexOf(collateralId);

        if (!found) revert CM_WrongCollateralId();

        uint80 newAmount = collaterals[index].amount - amount;

        if (newAmount == 0) {
            account.collaterals.remove(index);
        } else {
            account.collaterals[index].amount = newAmount;
        }
    }

    ///@dev Increase the amount of short call or put (debt) of the account
    ///@param account CrossMarginAccount storage that will be updated
    function mintOption(CrossMarginAccount storage account, uint256 tokenId, uint64 amount) external {
        if (amount == 0) return;

        TokenType optionType = tokenId.parseTokenType();

        // engine only supports calls and puts
        if (optionType != TokenType.CALL && optionType != TokenType.PUT) revert CM_UnsupportedTokenType();

        (bool found, uint256 index) = account.shorts.indexOf(tokenId);
        if (!found) {
            account.shorts.push(Position(tokenId, amount));
        } else {
            account.shorts[index].amount += amount;
        }
    }

    ///@dev Remove the amount of short call or put (debt) of the account
    ///@param account CrossMarginAccount storage that will be updated in-place
    function burnOption(CrossMarginAccount storage account, uint256 tokenId, uint64 amount) external {
        (bool found, Position memory position, uint256 index) = account.shorts.find(tokenId);

        if (!found) revert CM_InvalidToken();

        uint64 newShortAmount = position.amount - amount;
        if (newShortAmount == 0) {
            account.shorts.removeAt(index);
        } else {
            account.shorts[index].amount = newShortAmount;
        }
    }

    ///@dev Increase the amount of long call or put (debt) of the account
    ///@param account CrossMarginAccount storage that will be updated
    function addOption(CrossMarginAccount storage account, uint256 tokenId, uint64 amount) external {
        if (amount == 0) return;

        (bool found, uint256 index) = account.longs.indexOf(tokenId);

        if (!found) {
            account.longs.push(Position(tokenId, amount));
        } else {
            account.longs[index].amount += amount;
        }
    }

    ///@dev Remove the amount of long call or put held by the account
    ///@param account CrossMarginAccount storage that will be updated in-place
    function removeOption(CrossMarginAccount storage account, uint256 tokenId, uint64 amount) external {
        (bool found, Position memory position, uint256 index) = account.longs.find(tokenId);

        if (!found) revert CM_InvalidToken();

        uint64 newLongAmount = position.amount - amount;
        if (newLongAmount == 0) {
            account.longs.removeAt(index);
        } else {
            account.longs[index].amount = newLongAmount;
        }
    }

    // ///@dev Settles the accounts longs and shorts
    // ///@param account CrossMarginAccount storage that will be updated in-place
    // function settleAtExpiry(CrossMarginAccount storage account, IPomace pomace)
    //     external
    //     returns (Balance[] memory longPayouts, Balance[] memory shortPayouts)
    // {
    //     // settling longs first as they can only increase collateral
    //     _settleLongs(pomace, account);
    //     // settling shorts last as they can only reduce collateral
    //     _settleShorts(pomace, account);
    // }

    ///@dev Exercising long, adding and removing collateral to balances
    ///@param account CrossMarginAccount memory that will be updated in-place
    ///@param pomace interface to settle long options in a batch call
    ///@param tokenId Option to exercise
    ///@param amount amount of options
    function exerciseToken(CrossMarginAccount storage account, IPomace pomace, uint256 tokenId, uint256 amount)
        external
        returns (Balance memory debt, Balance memory payout)
    {
        uint256 i;
        bool tokenFound;

        for (i; i < account.longs.length;) {
            if (tokenId == account.longs[i].tokenId) {
                (,, uint64 expiry,, uint64 exerciseWindow) = tokenId.parseTokenId();

                if (expiry > block.timestamp) revert CML_NotExpired();

                if (expiry + exerciseWindow < block.timestamp) {
                    // worthless option, removing from account
                    account.longs.removeAt(i);
                } else {
                    uint256 accountAmount = account.longs[i].amount;
                    if (amount > accountAmount) revert CML_ExceedsAmount();

                    if (amount == accountAmount) {
                        account.longs.removeAt(i);
                    } else {
                        account.longs[i].amount -= uint64(amount);
                    }
                }

                tokenFound = true;

                break;
            }

            unchecked {
                ++i;
            }
        }

        if (tokenFound) {
            (debt, payout) = pomace.settleOption(address(this), tokenId, amount);

            // add the collateral in the account storage.
            if (payout.amount > 0) addCollateral(account, payout.collateralId, payout.amount);

            // remove the collateral in the account storage.
            if (debt.amount > 0) removeCollateral(account, debt.collateralId, debt.amount);
        }

        // clean up worthless tokens
        for (i = 0; i < account.longs.length;) {
            (,, uint64 expiry,, uint64 exerciseWindow) = account.longs[i].tokenId.parseTokenId();

            if (expiry + exerciseWindow < block.timestamp) {
                account.longs.removeAt(i);
            } else {
                unchecked {
                    ++i;
                }
            }
        }
    }

    ///@dev Settles the accounts shorts, updating collateral for exercised options
    ///@param account CrossMarginAccount memory that will be updated in-place
    function settleShorts(CrossMarginAccount storage account)
        external
        returns (Balance[] memory debts, Balance[] memory payouts)
    {
        uint256 i;
        uint256[] memory tokenIds;
        uint256[] memory amounts;

        for (i; i < account.shorts.length;) {
            uint256 tokenId = account.shorts[i].tokenId;

            (,, uint64 expiry,, uint64 exerciseWindow) = tokenId.parseTokenId();

            // can only settle short options after the settlement window
            if (expiry + exerciseWindow < block.timestamp) {
                tokenIds = tokenIds.append(tokenId);
                amounts = amounts.append(account.shorts[i].amount);
                account.shorts.removeAt(i);
            } else {
                unchecked {
                    ++i;
                }
            }
        }

        ICrossMarginEngine engine = ICrossMarginEngine(address(this));

        if (tokenIds.length > 0) {
            // the engine will socialized the debt and payout for settled options
            (debts, payouts) = engine.getBatchSettlementForShorts(tokenIds, amounts);

            // debts and payouts are equal length
            for (i = 0; i < payouts.length;) {
                // add to what is paid from exerciser
                if (debts[i].amount > 0) addCollateral(account, debts[i].collateralId, debts[i].amount);

                // remove the collateral in the account storage.
                if (payouts[i].amount > 0) removeCollateral(account, payouts[i].collateralId, payouts[i].amount);

                unchecked {
                    ++i;
                }
            }
        }
    }
}