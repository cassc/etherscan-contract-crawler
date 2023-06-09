// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import {ActionUtil as GrappaActionUtil} from "grappa/libraries/ActionUtil.sol";
import {ActionUtil as PomaceActionUtil} from "pomace/libraries/ActionUtil.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

// interfaces
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IHashnoteVault} from "../interfaces/IHashnoteVault.sol";
import {IMarginEngineCash, IMarginEnginePhysical} from "../interfaces/IMarginEngine.sol";

import "grappa/config/types.sol" as Grappa;
import "pomace/config/types.sol" as Pomace;

import "../config/constants.sol";
import "../config/errors.sol";
import "../config/types.sol";

library StructureLib {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    event WithdrewCollateral(uint256[] amounts, address indexed manager);

    /**
     * @notice verifies that initial collaterals are present (non-zero)
     * @param collaterals is the array of collaterals passed from initParams in initializer
     */
    function verifyInitialCollaterals(Collateral[] calldata collaterals) external pure {
        unchecked {
            for (uint256 i; i < collaterals.length; ++i) {
                if (collaterals[i].id == 0) revert OV_BadCollateral();
            }
        }
    }

    /**
     * @notice Settles the vaults position(s) in grappa.
     * @param marginEngine is the address of the grappa margin engine contract
     */
    function settleOptions(IMarginEngineCash marginEngine) external {
        Grappa.ActionArgs[] memory actions = new Grappa.ActionArgs[](1);

        actions[0] = GrappaActionUtil.createSettleAction();

        marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Settles the vaults position(s) in pomace.
     * @param marginEngine is the address of the pomace margin engine contract
     */
    function settleOptions(IMarginEnginePhysical marginEngine) public {
        Pomace.ActionArgs[] memory actions = new Pomace.ActionArgs[](1);

        actions[0] = PomaceActionUtil.createSettleAction();

        marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Deposits collateral into grappa.
     * @param marginEngine is the address of the grappa margin engine contract
     */
    function depositCollateral(IMarginEngineCash marginEngine, Collateral[] calldata collaterals) external {
        Grappa.ActionArgs[] memory actions;

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            IERC20 collateral = IERC20(collaterals[i].addr);

            uint256 balance = collateral.balanceOf(address(this));

            if (balance > 0) {
                collateral.safeApprove(address(marginEngine), balance);

                actions = GrappaActionUtil.append(
                    actions, GrappaActionUtil.createAddCollateralAction(collaterals[i].id, balance, address(this))
                );
            }

            unchecked {
                ++i;
            }
        }

        if (actions.length > 0) marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Deposits collateral into pomace.
     * @param marginEngine is the address of the pomace margin engine contract
     */
    function depositCollateral(IMarginEnginePhysical marginEngine, Collateral[] calldata collaterals) external {
        Pomace.ActionArgs[] memory actions;

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            IERC20 collateral = IERC20(collaterals[i].addr);

            uint256 balance = collateral.balanceOf(address(this));

            if (balance > 0) {
                collateral.safeApprove(address(marginEngine), balance);

                actions = PomaceActionUtil.append(
                    actions, PomaceActionUtil.createAddCollateralAction(collaterals[i].id, balance, address(this))
                );
            }

            unchecked {
                ++i;
            }
        }

        if (actions.length > 0) marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Withdraws all vault collateral(s) from grappa margin account.
     * @param marginEngine is the interface to the grappa margin engine contract
     */
    function withdrawAllCollateral(IMarginEngineCash marginEngine) external {
        // gets the accounts collateral balances
        (,, Balance[] memory collaterals) = marginEngine.marginAccounts(address(this));

        Grappa.ActionArgs[] memory actions = new Grappa.ActionArgs[](collaterals.length);
        uint256[] memory withdrawAmounts = new uint256[](collaterals.length);

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            actions[i] =
                GrappaActionUtil.createRemoveCollateralAction(collaterals[i].collateralId, collaterals[i].amount, address(this));

            withdrawAmounts[i] = collaterals[i].amount;

            unchecked {
                ++i;
            }
        }

        marginEngine.execute(address(this), actions);

        emit WithdrewCollateral(withdrawAmounts, msg.sender);
    }

    /**
     * @notice Withdraws all vault collateral(s) from pomace margin account.
     * @param marginEngine is the interface to the pomace engine contract
     */
    function withdrawAllCollateral(IMarginEnginePhysical marginEngine) external {
        // gets the accounts collateral balances
        (,, Balance[] memory collaterals) = marginEngine.marginAccounts(address(this));

        Pomace.ActionArgs[] memory actions = new Pomace.ActionArgs[](collaterals.length);
        uint256[] memory withdrawAmounts = new uint256[](collaterals.length);

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            actions[i] =
                PomaceActionUtil.createRemoveCollateralAction(collaterals[i].collateralId, collaterals[i].amount, address(this));

            withdrawAmounts[i] = collaterals[i].amount;

            unchecked {
                ++i;
            }
        }

        marginEngine.execute(address(this), actions);

        emit WithdrewCollateral(withdrawAmounts, msg.sender);
    }

    /**
     * @notice Withdraws some of vault collateral(s) from grappa margin account.
     * @param marginEngine is the interface to the grappa margin engine contract
     */
    function withdrawCollaterals(
        IMarginEngineCash marginEngine,
        Collateral[] calldata collaterals,
        uint256[] calldata amounts,
        address recipient
    ) external {
        Grappa.ActionArgs[] memory actions;

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < amounts.length;) {
            if (amounts[i] > 0) {
                actions = GrappaActionUtil.append(
                    actions, GrappaActionUtil.createRemoveCollateralAction(collaterals[i].id, amounts[i], recipient)
                );
            }

            unchecked {
                ++i;
            }
        }

        if (actions.length > 0) marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Withdraws some of vault collateral(s) from pomace margin account.
     * @param marginEngine is the interface to the pomace margin engine contract
     */
    function withdrawCollaterals(
        IMarginEnginePhysical marginEngine,
        Collateral[] calldata collaterals,
        uint256[] calldata amounts,
        address recipient
    ) external {
        Pomace.ActionArgs[] memory actions;

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < amounts.length;) {
            if (amounts[i] > 0) {
                actions = PomaceActionUtil.append(
                    actions, PomaceActionUtil.createRemoveCollateralAction(collaterals[i].id, amounts[i], recipient)
                );
            }

            unchecked {
                ++i;
            }
        }

        if (actions.length > 0) marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Withdraws assets based on shares from grappa margin account.
     * @dev used to send assets from the margin account to recipient at the end of each round
     * @param marginEngine is the interface to the grappa margin engine contract
     * @param totalSupply is the total amount of outstanding shares
     * @param withdrawShares the number of shares being withdrawn
     * @param recipient is the destination address for the assets
     */
    function withdrawWithShares(IMarginEngineCash marginEngine, uint256 totalSupply, uint256 withdrawShares, address recipient)
        external
        returns (uint256[] memory amounts)
    {
        (,, Balance[] memory collaterals) = marginEngine.marginAccounts(address(this));

        uint256 collateralLength = collaterals.length;

        amounts = new uint256[](collateralLength);
        Grappa.ActionArgs[] memory actions = new Grappa.ActionArgs[](collateralLength);

        for (uint256 i; i < collateralLength;) {
            amounts[i] = FixedPointMathLib.mulDivDown(collaterals[i].amount, withdrawShares, totalSupply);

            unchecked {
                actions[i] = GrappaActionUtil.createRemoveCollateralAction(collaterals[i].collateralId, amounts[i], recipient);
                ++i;
            }
        }

        marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Withdraws assets based on shares from pomace margin account.
     * @dev used to send assets from the margin account to recipient at the end of each round
     * @param marginEngine is the interface to the grappa margin engine contract
     * @param totalSupply is the total amount of outstanding shares
     * @param withdrawShares the number of shares being withdrawn
     * @param recipient is the destination address for the assets
     */
    function withdrawWithShares(
        IMarginEnginePhysical marginEngine,
        uint256 totalSupply,
        uint256 withdrawShares,
        address recipient
    ) external returns (uint256[] memory amounts) {
        (,, Balance[] memory collaterals) = marginEngine.marginAccounts(address(this));

        uint256 collateralLength = collaterals.length;

        amounts = new uint256[](collateralLength);
        Pomace.ActionArgs[] memory actions = new Pomace.ActionArgs[](collateralLength);

        for (uint256 i; i < collateralLength;) {
            amounts[i] = FixedPointMathLib.mulDivDown(collaterals[i].amount, withdrawShares, totalSupply);

            unchecked {
                actions[i] = PomaceActionUtil.createRemoveCollateralAction(collaterals[i].collateralId, amounts[i], recipient);
                ++i;
            }
        }

        marginEngine.execute(address(this), actions);
    }
}