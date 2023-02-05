// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { FixedPointMathLib } from "../../lib/solmate/src/utils/FixedPointMathLib.sol";
import { SafeERC20 } from "../../lib/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ActionUtil } from "../../lib/grappa/src/libraries/ActionUtil.sol";
import { Vault } from "./Vault.sol";

import { IERC20 } from "../interfaces/IERC20.sol";
import { IBatchAuction } from "../interfaces/IBatchAuction.sol";
import "../interfaces/GrappaInterfaces.sol";

import "./Errors.sol";

library AuctionUtil {
    using ActionUtil for Grappa.ActionArgs[];
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev structure used in memory to start an auction
     */
    struct AuctionParams {
        address auctionAddr;
        address premiumToken;
        Vault.Collateral[] collaterals;
        uint256[] counterparty;
        uint256 duration;
        address engineAddr;
        uint256 maxStructures;
        uint256[] options;
        int256 premium;
        uint256 structures;
        address whitelist;
    }

    /**
     * @notice Starts the Batch Auction
     * @param params is the struct with all the parameters of the auction
     * @return auctionId the auction id of the newly created auction
     */
    function startAuction(AuctionParams calldata params) external returns (uint256 auctionId) {
        if (params.structures > type(uint64).max) revert VL_Overflow();

        uint256 unsignedPremium = _toUint256(params.premium);

        IERC20 premiumToken = IERC20(params.premiumToken);

        int256 premium;

        {
            uint256 decimals = premiumToken.decimals();

            unsignedPremium =
                decimals > 18 ? unsignedPremium * (10 ** (decimals - 18)) : unsignedPremium / (10 ** (uint256(18) - decimals));

            premium = params.premium < 0 ? -int256(unsignedPremium) : int256(unsignedPremium);
        }

        if (premium < 0) {
            premiumToken.safeApprove(params.auctionAddr, unsignedPremium.mulDivUp(params.structures, Vault.UNIT));
        }

        auctionId = IBatchAuction(params.auctionAddr).createAuction(
            IMarginEngine(params.engineAddr).optionToken(),
            params.options,
            params.premiumToken,
            _marginCollateralsToAuctionCollaterals(params.collaterals, params.counterparty, params.maxStructures),
            premium,
            1,
            params.structures,
            block.timestamp + params.duration,
            params.whitelist
        );
    }

    /**
     * @notice transfers bidders winnings from vault sub account
     * @dev calculates bidders portion based on how much of their bids were filled
     */
    function novate(
        address engineAddr,
        Vault.Instrument[] memory instruments,
        uint256[] memory options,
        Vault.Collateral[] memory collaterals,
        uint256[] memory counterparty,
        address recipient,
        uint256 amount
    ) external {
        IMarginEngine engine = IMarginEngine(engineAddr);

        // vault sub account that custodies counterparty side of trade
        // bidders can claim any time after the auction settles
        address cpSubAccount = address(uint160(address(this)) ^ uint160(1));

        Grappa.ActionArgs[] memory collateralActions = new Grappa.ActionArgs[](0);
        Grappa.ActionArgs[] memory longActions = new Grappa.ActionArgs[](0);
        Grappa.ActionArgs[] memory shortActions = new Grappa.ActionArgs[](0);

        uint256 i;
        for (i; i < counterparty.length;) {
            uint256 collateralAmount = amount.mulDivDown(counterparty[i], Vault.UNIT);

            collateralActions = collateralActions.append(
                ActionUtil.createTransferCollateralAction(collaterals[i].id, collateralAmount, recipient)
            );

            unchecked {
                ++i;
            }
        }

        for (i = 0; i < instruments.length;) {
            Vault.Instrument memory instrument = instruments[i];

            uint256 option = options[i];

            uint256 numOfOptions = amount.mulDivDown(_toUint256(instrument.weight), Vault.UNIT);

            // counterparty is  long negative instruments
            // counterparty is short positive instruments
            if (instrument.weight < 0) {
                longActions = longActions.append(ActionUtil.createTransferLongAction(option, numOfOptions, recipient));
            } else {
                shortActions = shortActions.append(ActionUtil.createTransferShortAction(option, numOfOptions, recipient));
            }

            unchecked {
                ++i;
            }
        }

        Grappa.ActionArgs[] memory actions = new Grappa.ActionArgs[](0);

        if (collateralActions.length != 0) actions = actions.concat(collateralActions);
        if (longActions.length != 0) actions = actions.concat(longActions);
        if (shortActions.length != 0) actions = actions.concat(shortActions);

        // if actions is empty dont execute
        if (actions.length != 0) engine.execute(cpSubAccount, actions);
    }

    /**
     * @notice helper function to convert Vault.Collateral to IBatchAuction.Collateral
     */
    function _marginCollateralsToAuctionCollaterals(
        Vault.Collateral[] calldata vaultCollaterals,
        uint256[] calldata balances,
        uint256 maxStructures
    ) internal pure returns (IBatchAuction.Collateral[] memory collaterals) {
        collaterals = new IBatchAuction.Collateral[](balances.length);

        for (uint256 i; i < balances.length;) {
            uint256 amount = balances[i].mulDivUp(Vault.UNIT, maxStructures);

            if (amount > type(uint80).max) revert VL_Overflow();

            collaterals[i] = IBatchAuction.Collateral(vaultCollaterals[i].addr, uint80(amount));

            unchecked {
                ++i;
            }
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