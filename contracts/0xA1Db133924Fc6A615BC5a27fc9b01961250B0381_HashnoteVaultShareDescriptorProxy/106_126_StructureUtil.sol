// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { FixedPointMathLib } from "../../lib/solmate/src/utils/FixedPointMathLib.sol";
import { SafeERC20 } from "../../lib/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ActionUtil } from "../../lib/grappa/src/libraries/ActionUtil.sol";
import { Vault } from "./Vault.sol";

import { IERC20 } from "../interfaces/IERC20.sol";
import "../interfaces/GrappaInterfaces.sol";

import "./Errors.sol";

library StructureUtil {
    using ActionUtil for Grappa.ActionArgs[];
    using ActionUtil for Grappa.BatchExecute[];
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev structure used in memory to mint structures in grappa
     */
    struct CreateStructuresParams {
        address batchAuctionAddr;
        Vault.Collateral[] collaterals;
        uint256[] counterparty;
        address engineAddr;
        Vault.Instrument[] instruments;
        uint256[] options;
        uint256 structuresToMint;
        uint256 maxStructures;
        uint256[] vault;
    }

    /**
     * @notice Sets the next option the vault will be writing
     * @param engineAddr is the address of the margin engine
     * @param strikes is the new prices for each instruments
     * @param instruments is the linear combination of options
     * @param roundConfig the round configuration
     * @return options is the ids of the new options
     */
    function stageStructure(
        address engineAddr,
        uint256[] calldata strikes,
        Vault.Instrument[] calldata instruments,
        Vault.RoundConfig storage roundConfig
    ) external view returns (uint256[] memory options, uint256 expiry) {
        IMarginEngine engine = IMarginEngine(engineAddr);
        IGrappa grappa = IGrappa(engine.grappa());

        expiry = _getNextExpiry(roundConfig);

        options = new uint256[](instruments.length);

        for (uint256 i = 0; i < instruments.length; i++) {
            uint40 productId = grappa.getProductId(
                instruments[i].oracle, engineAddr, instruments[i].underlying, instruments[i].strike, instruments[i].collateral
            );

            options[i] = grappa.getTokenId(instruments[i].tokenType, productId, expiry, strikes[i], 0);
        }
    }

    /**
     * @notice Creates the Grappa option position
     * @dev depositings collateral on behalf of vault and counterparty
     * @dev counterparty positions are held in the vaults sub account until bidders novate their portion
     */
    function createStructures(CreateStructuresParams memory params) external returns (uint256[] memory depositAmounts) {
        // if set then premium paid by vault, removing allowance incase it wasnt fully used in auction
        if (params.batchAuctionAddr != address(0)) {
            IERC20(params.collaterals[0].addr).safeApprove(params.batchAuctionAddr, 0);
        }

        IMarginEngine engine = IMarginEngine(params.engineAddr);

        Grappa.ActionArgs[] memory vActions;
        Grappa.ActionArgs[] memory cpActions;

        // vaults collateral deposit action
        (vActions, depositAmounts) = _createMarginDepositActions(
            params.engineAddr, params.structuresToMint, params.maxStructures, params.collaterals, params.vault
        );

        // counterparty collateral deposit action
        (cpActions,) = _createMarginDepositActions(
            params.engineAddr, params.structuresToMint, params.maxStructures, params.collaterals, params.counterparty
        );

        // vault sub account to store counterparty position
        address cpSubAccount = address(uint160(address(this)) ^ uint160(1));

        for (uint256 i; i < params.options.length;) {
            Vault.Instrument memory instrument = params.instruments[i];

            uint256 option = params.options[i];

            // number of options to mint given total structured sold in last auction
            uint256 amount = params.structuresToMint.mulDivDown(_toUint256(instrument.weight), Vault.UNIT);

            // vault receives positive weighted instruments (vault is long)
            // counterparty receives negative weighted instruments (vault is short)
            if (instrument.weight < 0) {
                vActions = vActions.append(ActionUtil.createMintIntoAccountAction(option, amount, cpSubAccount));
            } else {
                cpActions = cpActions.append(ActionUtil.createMintIntoAccountAction(option, amount, address(this)));
            }

            unchecked {
                ++i;
            }
        }

        Grappa.BatchExecute[] memory batch = new Grappa.BatchExecute[](1);

        // batch execute vault actions
        batch[0] = Grappa.BatchExecute(address(this), vActions);

        if (cpActions.length != 0) {
            // batch execute counterparty actions
            batch = batch.append(Grappa.BatchExecute(cpSubAccount, cpActions));
        }

        engine.batchExecute(batch);
    }

    /**
     * @notice Settles the vaults position(s) in grappa.
     * @param engineAddress is the address of the grappa margin engine contract
     * @return withdrawAmounts is the amounts returned to the vault
     */
    function settleOptions(address engineAddress) external returns (uint256[] memory withdrawAmounts) {
        IMarginEngine engine = IMarginEngine(engineAddress);

        Grappa.ActionArgs[] memory actions = new Grappa.ActionArgs[](1);

        actions[0] = ActionUtil.createSettleAction();

        engine.execute(address(this), actions);

        // gets the accounts collateral balances
        (,, Grappa.Balance[] memory collaterals) = engine.marginAccounts(address(this));

        actions = new Grappa.ActionArgs[](collaterals.length);
        withdrawAmounts = new uint256[](collaterals.length);

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            actions[i] =
                ActionUtil.createRemoveCollateralAction(collaterals[i].collateralId, collaterals[i].amount, address(this));

            withdrawAmounts[i] = collaterals[i].amount;

            unchecked {
                ++i;
            }
        }

        if (actions.length != 0) engine.execute(address(this), actions);
    }

    /**
     * @notice Helper function to setup deposit collateral action
     * @dev calculates collateral deposit based on total structures sold in last auction
     * @dev increases margin engines allowance to pull funds across vault + counterparty deposit actions
     * @return actions array of collateral deposits
     * @return amounts of asset desposited
     */
    function _createMarginDepositActions(
        address engineAddr,
        uint256 structuresToMint,
        uint256 maxStructures,
        Vault.Collateral[] memory collaterals,
        uint256[] memory balances
    ) internal returns (Grappa.ActionArgs[] memory actions, uint256[] memory amounts) {
        actions = new Grappa.ActionArgs[](balances.length);

        amounts = new uint256[](balances.length);

        for (uint256 i; i < balances.length;) {
            amounts[i] = balances[i].mulDivDown(structuresToMint, maxStructures);

            IERC20(collaterals[i].addr).safeIncreaseAllowance(engineAddr, amounts[i]);

            actions[i] = ActionUtil.createAddCollateralAction(collaterals[i].id, amounts[i], address(this));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Gets the next option expiry from the given timestamp
     * @param roundConfig the configuration used to calculate the option expiry
     */
    function _getNextExpiry(Vault.RoundConfig storage roundConfig) internal view returns (uint256 nextTime) {
        uint256 offset = block.timestamp + roundConfig.duration;

        // The offset will always be greater than the options expiry, so we subtract a week in order to get the day the option should expire, or subtract a day to get the hour the option should start if the dayOfWeek is wild (8)
        if (roundConfig.dayOfWeek != 8) offset -= 1 weeks;
        else offset -= 1 days;

        nextTime = _getNextDayTimeOfWeek(offset, roundConfig.dayOfWeek, roundConfig.hourOfDay);

        //if timestamp is in the past relative to the offset, it means we've tried to calculate an expiry of an option which has too short of length. I.e trying to run a 1 day option on a Tuesday which should expire Friday
        if (nextTime < offset) revert VL_BadExpiryDate();
    }

    /**
     * @notice Calculates the next day/hour of the week
     * @param timestamp is the expiry timestamp of the current option
     * @param dayOfWeek is the day of the week we're looking for (sun:0/7 - sat:6), 8 will be treated as disabled and the next available hourOfDay will be returned
     * @param hourOfDay is the next hour of the day we want to expire on (midnight:0)
     *
     * Examples when day = 5, hour = 8:
     * getNextDayTimeOfWeek(week 1 thursday) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday) -> week 2 friday:0800
     * getNextDayTimeOfWeek(week 1 saturday) -> week 2 friday:0800
     *
     * Examples when day = 7, hour = 8:
     * getNextDayTimeOfWeek(week 1 thursday) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday:0500) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday:0900) -> week 1 saturday:0800
     * getNextDayTimeOfWeek(week 1 saturday) -> week 1 sunday:0800
     */
    function _getNextDayTimeOfWeek(uint256 timestamp, uint256 dayOfWeek, uint256 hourOfDay)
        internal
        pure
        returns (uint256 nextStartTime)
    {
        // we want sunday to have a value of 7
        if (dayOfWeek == 0) dayOfWeek = 7;

        // dayOfWeek = 0 (sunday) - 6 (saturday) calculated from epoch time
        uint256 timestampDayOfWeek = ((timestamp / 1 days) + 4) % 7;
        //Calculate the nextDayOfWeek by figuring out how much time is between now and then in seconds
        uint256 nextDayOfWeek =
            timestamp + ((7 + (dayOfWeek == 8 ? timestampDayOfWeek : dayOfWeek) - timestampDayOfWeek) % 7) * 1 days;
        //Calculate the nextStartTime by removing the seconds past midnight, then adding the amount seconds after midnight we wish to start
        nextStartTime = nextDayOfWeek - (nextDayOfWeek % 24 hours) + (hourOfDay * 1 hours);

        // If the date has passed, we simply increment it by a week to get the next dayOfWeek, or by a day if we only want the next hourOfDay
        if (timestamp >= nextStartTime) {
            if (dayOfWeek == 8) nextStartTime += 1 days;
            else nextStartTime += 7 days;
        }
    }

    /**
     * @notice helper function to convert int256 to uint256
     */
    function _toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) return uint256(-value);
        else return uint256(value);
    }
}