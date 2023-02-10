// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import "../BaseStrategyUpgradeable.sol";

import "../../interfaces/IGenericLender.sol";

/// @title OptimizerAPRStrategy
/// @author Angle Labs, Inc.
/// @notice A lender optimisation strategy for any ERC20 asset, leveraging multiple lenders at once
/// @dev This strategy works by taking plugins designed for standard lending platforms and automatically
/// chooses to invest its funds in the best platforms to generate yield.
/// The allocation is greedy and may be sub-optimal so there is an additional option to manually set positions
contract OptimizerAPRStrategy is BaseStrategyUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;

    // ================================= CONSTANTS =================================

    uint64 internal constant _BPS = 10000;

    // ============================ CONTRACTS REFERENCES ===========================

    IGenericLender[] public lenders;

    // ================================= PARAMETERS ================================

    uint256 public withdrawalThreshold;

    // =================================== EVENTS ==================================

    event AddLender(address indexed lender);
    event RemoveLender(address indexed lender);

    /// @notice Constructor of the `Strategy`
    /// @param _poolManager Address of the `PoolManager` lending to this strategy
    /// @param governor Address with governor privilege
    /// @param guardian Address of the guardian
    function initialize(
        address _poolManager,
        address governor,
        address guardian,
        address[] memory keepers
    ) external {
        _initialize(_poolManager, governor, guardian, keepers);
        withdrawalThreshold = 1000 * wantBase;
    }

    // ============================= INTERNAL FUNCTIONS ============================

    /// @notice Frees up profit plus `_debtOutstanding`.
    /// @param _debtOutstanding Amount to withdraw
    /// @return _profit Profit freed by the call
    /// @return _loss Loss discovered by the call
    /// @return _debtPayment Amount freed to reimburse the debt
    /// @dev If `_debtOutstanding` is more than we can free we get as much as possible.
    function _prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        _debtPayment = _debtOutstanding;

        uint256 lentAssets = lentTotalAssets();

        uint256 looseAssets = want.balanceOf(address(this));

        uint256 total = looseAssets + lentAssets;

        if (lentAssets == 0) {
            // No position to harvest or profit to report
            if (_debtPayment > looseAssets) {
                // We can only return looseAssets
                _debtPayment = looseAssets;
            }

            return (_profit, _loss, _debtPayment);
        }

        uint256 debt = poolManager.strategies(address(this)).totalStrategyDebt;

        if (total > debt) {
            _profit = total - debt;

            uint256 amountToFree = _profit + _debtPayment;
            // We need to add outstanding to our profit
            // don't need to do logic if there is nothing to free
            if (amountToFree != 0 && looseAssets < amountToFree) {
                // Withdraw what we can withdraw
                _withdrawSome(amountToFree - looseAssets);
                uint256 newLoose = want.balanceOf(address(this));

                // If we dont have enough money adjust _debtOutstanding and only change profit if needed
                if (newLoose < amountToFree) {
                    if (_profit > newLoose) {
                        _profit = newLoose;
                        _debtPayment = 0;
                    } else {
                        _debtPayment = Math.min(newLoose - _profit, _debtPayment);
                    }
                }
            }
        } else {
            // Serious loss should never happen but if it does lets record it accurately
            _loss = debt - total;

            uint256 amountToFree = _loss + _debtPayment;
            if (amountToFree != 0 && looseAssets < amountToFree) {
                // Withdraw what we can withdraw

                _withdrawSome(amountToFree - looseAssets);
                uint256 newLoose = want.balanceOf(address(this));

                // If we dont have enough money adjust `_debtOutstanding` and only change profit if needed
                if (newLoose < amountToFree) {
                    if (_loss > newLoose) {
                        _loss = newLoose;
                        _debtPayment = 0;
                    } else {
                        _debtPayment = Math.min(newLoose - _loss, _debtPayment);
                    }
                }
            }
        }
    }

    /// @notice Estimates highest and lowest apr lenders among a `lendersList`
    /// @param lendersList List of all the lender contracts associated to this strategy
    /// @return _lowest The index of the lender in the `lendersList` with lowest apr
    /// @return _highest The index of the lender with highest apr
    /// @return _investmentStrategy Whether we should invest from the lowest to the highest yielding strategy or simply invest loose assets
    /// @return _totalApr The APR computed according to (greedy) heuristics that will determine whether positions should be adjusted
    /// according to the solution proposed by the caller or according to the greedy method
    /// @dev `lendersList` is kept as a parameter to avoid multiplying reads in storage to the `lenders` array
    function _estimateGreedyAdjustPosition(IGenericLender[] memory lendersList)
        internal
        view
        returns (
            uint256 _lowest,
            uint256 _highest,
            bool _investmentStrategy,
            uint256 _totalApr
        )
    {
        // All loose assets are to be invested
        uint256 looseAssets = want.balanceOf(address(this));

        // Simple greedy algo:
        //  - Get the lowest apr strat
        //  - Cycle through and see who could take its funds to improve the overall highest APR
        uint256 lowestNav;
        uint256 highestApr;
        uint256 highestLenderNav;
        uint256 totalNav = looseAssets;
        uint256[] memory weightedAprs = new uint256[](lendersList.length);
        {
            uint256 lowestApr = type(uint256).max;
            for (uint256 i; i < lendersList.length; ++i) {
                uint256 aprAfterDeposit = lendersList[i].aprAfterDeposit(int256(looseAssets));
                uint256 nav = lendersList[i].nav();
                totalNav += nav;
                if (aprAfterDeposit > highestApr) {
                    highestApr = aprAfterDeposit;
                    highestLenderNav = nav;
                    _highest = i;
                }
                // Checking strategies that have assets
                if (nav > 10 * wantBase) {
                    uint256 apr = lendersList[i].apr();
                    weightedAprs[i] = apr * nav;
                    if (apr < lowestApr) {
                        lowestApr = apr;
                        lowestNav = nav;
                        _lowest = i;
                    }
                }
            }
        }

        // Comparing if we are better off removing from the lowest APR yielding strategy to invest in the highest or just invest
        // the loose assets in the highest yielding strategy
        if (totalNav > 0) {
            // Case where only loose assets are invested
            uint256 weightedApr1;
            // Case where funds are divested from the strategy with the lowest APR to be invested in the one with the highest APR
            uint256 weightedApr2;
            for (uint256 i; i < lendersList.length; ++i) {
                if (i == _highest) {
                    weightedApr1 += (highestLenderNav + looseAssets) * highestApr;
                    if (lowestNav != 0 && lendersList.length > 1)
                        weightedApr2 +=
                            (highestLenderNav + looseAssets + lowestNav) *
                            lendersList[_highest].aprAfterDeposit(int256(lowestNav + looseAssets));
                } else if (i == _lowest) {
                    weightedApr1 += weightedAprs[i];
                    // In the second case funds are divested so the lowest strat does not contribute to the highest APR case
                } else {
                    weightedApr1 += weightedAprs[i];
                    weightedApr2 += weightedAprs[i];
                }
            }
            if (weightedApr2 > weightedApr1 && lendersList.length > 1) {
                _investmentStrategy = true;
                _totalApr = weightedApr2 / totalNav;
            } else _totalApr = weightedApr1 / totalNav;
        }
    }

    /// @inheritdoc BaseStrategyUpgradeable
    function _adjustPosition(bytes memory data) internal override {
        // Emergency exit is dealt with at beginning of harvest
        if (emergencyExit) return;

        // Storing the `lenders` array in a cache variable
        IGenericLender[] memory lendersList = lenders;
        uint256 lendersListLength = lendersList.length;
        // We just keep all money in `want` if we dont have any lenders
        if (lendersListLength == 0) return;

        uint64[] memory lenderSharesHint = abi.decode(data, (uint64[]));

        uint256 estimatedAprHint;
        int256[] memory lenderAdjustedAmounts;
        if (lenderSharesHint.length != 0) (estimatedAprHint, lenderAdjustedAmounts) = estimatedAPR(lenderSharesHint);
        (uint256 lowest, uint256 highest, bool _investmentStrategy, uint256 _totalApr) = _estimateGreedyAdjustPosition(
            lendersList
        );

        // The hint was successful --> we find a better allocation than the current one
        if (_totalApr < estimatedAprHint) {
            uint256 deltaWithdraw;
            for (uint256 i; i < lendersListLength; ++i) {
                if (lenderAdjustedAmounts[i] < 0) {
                    deltaWithdraw +=
                        uint256(-lenderAdjustedAmounts[i]) -
                        lendersList[i].withdraw(uint256(-lenderAdjustedAmounts[i]));
                }
            }

            // If the strategy didn't succeed to withdraw the intended funds -> revert and force the greedy path
            if (deltaWithdraw > withdrawalThreshold) revert IncorrectDistribution();

            for (uint256 i; i < lendersListLength; ++i) {
                // As `deltaWithdraw` is inferior to `withdrawalThreshold` (a dust)
                // It is not critical to compensate on an arbitrary lender as it will only slightly impact global APR
                if (lenderAdjustedAmounts[i] > int256(deltaWithdraw)) {
                    lenderAdjustedAmounts[i] -= int256(deltaWithdraw);
                    deltaWithdraw = 0;
                    want.safeTransfer(address(lendersList[i]), uint256(lenderAdjustedAmounts[i]));
                    lendersList[i].deposit();
                } else if (lenderAdjustedAmounts[i] > 0) deltaWithdraw -= uint256(lenderAdjustedAmounts[i]);
            }
        } else {
            if (_investmentStrategy) {
                lendersList[lowest].withdrawAll();
            }

            uint256 bal = want.balanceOf(address(this));
            if (bal != 0) {
                want.safeTransfer(address(lendersList[highest]), bal);
                lendersList[highest].deposit();
            }
        }
    }

    /// @inheritdoc BaseStrategyUpgradeable
    function _adjustPosition() internal override {
        _adjustPosition(abi.encode(new uint64[](0)));
    }

    /// @inheritdoc BaseStrategyUpgradeable
    function _adjustPosition(uint256) internal override {
        _adjustPosition(abi.encode(new uint64[](0)));
    }

    /// @notice Withdraws a given amount from lenders
    /// @param _amount The amount to withdraw
    /// @dev Cycle through withdrawing from worst rate first
    function _withdrawSome(uint256 _amount) internal returns (uint256 amountWithdrawn) {
        IGenericLender[] memory lendersList = lenders;
        uint256 lendersListLength = lendersList.length;
        if (lendersListLength == 0) {
            return 0;
        }

        // Don't withdraw dust
        uint256 _withdrawalThreshold = withdrawalThreshold;
        if (_amount < _withdrawalThreshold) {
            return 0;
        }

        amountWithdrawn;
        // In most situations this will only run once. Only big withdrawals will be a gas guzzler
        uint256 j;
        while (amountWithdrawn < _amount - _withdrawalThreshold) {
            uint256 lowestApr = type(uint256).max;
            uint256 lowest;
            for (uint256 i; i < lendersListLength; ++i) {
                if (lendersList[i].hasAssets()) {
                    uint256 apr = lendersList[i].apr();
                    if (apr < lowestApr) {
                        lowestApr = apr;
                        lowest = i;
                    }
                }
            }
            if (!lendersList[lowest].hasAssets()) {
                return amountWithdrawn;
            }
            uint256 amountWithdrawnFromStrat = lendersList[lowest].withdraw(_amount - amountWithdrawn);
            // To avoid staying on the same strat if we can't withdraw anythin from it
            amountWithdrawn += amountWithdrawnFromStrat;
            ++j;
            // not best solution because it would be better to move to the 2nd lowestAPR instead of quiting
            if (amountWithdrawnFromStrat == 0) {
                return amountWithdrawn;
            }
            // To avoid want infinite loop
            if (j >= 6) {
                return amountWithdrawn;
            }
        }
    }

    /// @notice Liquidates up to `_amountNeeded` of `want` of this strategy's positions,
    /// irregardless of slippage. Any excess will be re-invested with `_adjustPosition()`.
    /// This function should return the amount of `want` tokens made available by the
    /// liquidation. If there is a difference between them, `_loss` indicates whether the
    /// difference is due to a realized loss, or if there is some other sitution at play
    /// (e.g. locked funds) where the amount made available is less than what is needed.
    ///
    /// NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
    function _liquidatePosition(uint256 _amountNeeded) internal override returns (uint256 _amountFreed, uint256 _loss) {
        uint256 _balance = want.balanceOf(address(this));

        if (_balance >= _amountNeeded) {
            //if we don't set reserve here withdrawer will be sent our full balance
            return (_amountNeeded, 0);
        } else {
            uint256 received = _withdrawSome(_amountNeeded - _balance) + (_balance);
            if (received >= _amountNeeded) {
                return (_amountNeeded, 0);
            } else {
                return (received, 0);
            }
        }
    }

    /// @notice Liquidates everything and returns the amount that got freed.
    /// This function is used during emergency exit instead of `_prepareReturn()` to
    /// liquidate all of the Strategy's positions back to the Manager.
    function _liquidateAllPositions() internal override returns (uint256 _amountFreed) {
        (_amountFreed, ) = _liquidatePosition(estimatedTotalAssets());
    }

    // =============================== VIEW FUNCTIONS ==============================

    /// @notice View function to check the current state of the strategy
    /// @return Returns the status of all lenders attached the strategy
    function lendStatuses() external view returns (LendStatus[] memory) {
        uint256 lendersLength = lenders.length;
        LendStatus[] memory statuses = new LendStatus[](lendersLength);
        for (uint256 i; i < lendersLength; ++i) {
            LendStatus memory s;
            s.name = lenders[i].lenderName();
            s.add = address(lenders[i]);
            s.assets = lenders[i].nav();
            s.rate = lenders[i].apr();
            statuses[i] = s;
        }
        return statuses;
    }

    /// @notice View function to check the total assets lent
    function lentTotalAssets() public view returns (uint256) {
        uint256 nav;
        uint256 lendersLength = lenders.length;
        for (uint256 i; i < lendersLength; ++i) {
            nav += lenders[i].nav();
        }
        return nav;
    }

    /// @notice View function to check the total assets managed by the strategy
    function estimatedTotalAssets() public view override returns (uint256 nav) {
        nav = lentTotalAssets() + want.balanceOf(address(this));
    }

    /// @notice View function to check the number of lending platforms
    function numLenders() external view returns (uint256) {
        return lenders.length;
    }

    /// @notice Returns the weighted apr of all lenders
    /// @dev It's computed by doing: `sum(nav * apr) / totalNav`
    function estimatedAPR() external view returns (uint256) {
        uint256 bal = estimatedTotalAssets();
        if (bal == 0) {
            return 0;
        }

        uint256 weightedAPR;
        uint256 lendersLength = lenders.length;
        for (uint256 i; i < lendersLength; ++i) {
            weightedAPR += lenders[i].weightedApr();
        }

        return weightedAPR / bal;
    }

    /// @notice Returns the weighted apr in an hypothetical world where the strategy splits its nav
    /// in respect to shares
    /// @param shares List of shares (in bps of the nav) that should be allocated to each lender
    function estimatedAPR(uint64[] memory shares)
        public
        view
        returns (uint256 weightedAPR, int256[] memory lenderAdjustedAmounts)
    {
        uint256 lenderLength = lenders.length;
        lenderAdjustedAmounts = new int256[](lenderLength);
        if (lenderLength != shares.length) revert IncorrectListLength();

        uint256 bal = estimatedTotalAssets();
        if (bal == 0) return (weightedAPR, lenderAdjustedAmounts);

        uint256 share;
        for (uint256 i; i < lenderLength; ++i) {
            share += shares[i];
            uint256 futureDeposit = (bal * shares[i]) / _BPS;
            // It won't overflow for `decimals <= 18`, as it would mean gigantic amounts
            int256 adjustedAmount = int256(futureDeposit) - int256(lenders[i].nav());
            lenderAdjustedAmounts[i] = adjustedAmount;
            weightedAPR += futureDeposit * lenders[i].aprAfterDeposit(adjustedAmount);
        }
        if (share != 10000) revert InvalidShares();

        weightedAPR /= bal;
    }

    /// @notice Prevents governance from withdrawing `want` tokens
    function _protectedTokens() internal view override returns (address[] memory) {
        address[] memory protected = new address[](1);
        protected[0] = address(want);
        return protected;
    }

    // ================================= GOVERNANCE ================================

    /// @notice Changes the withdrawal threshold
    /// @param _threshold New withdrawal threshold
    /// @dev governor, guardian or `PoolManager` only
    function setWithdrawalThreshold(uint256 _threshold) external onlyRole(GUARDIAN_ROLE) {
        withdrawalThreshold = _threshold;
    }

    /// @notice Add lenders for the strategy to choose between
    /// @param newLender The adapter to the added lending platform
    /// @dev Governor, guardian or `PoolManager` only
    function addLender(IGenericLender newLender) external onlyRole(GUARDIAN_ROLE) {
        if (newLender.strategy() != address(this)) revert UndockedLender();
        uint256 lendersLength = lenders.length;
        for (uint256 i; i < lendersLength; ++i) {
            if (address(newLender) == address(lenders[i])) revert LenderAlreadyAdded();
        }
        lenders.push(newLender);

        emit AddLender(address(newLender));
    }

    /// @notice Removes a lending platform and fails if total withdrawal is impossible
    /// @param lender The address of the adapter to the lending platform to remove
    function safeRemoveLender(address lender) external onlyRole(KEEPER_ROLE) {
        _removeLender(lender, false);
    }

    /// @notice Removes a lending platform even if total withdrawal is impossible
    /// @param lender The address of the adapter to the lending platform to remove
    function forceRemoveLender(address lender) external onlyRole(GUARDIAN_ROLE) {
        _removeLender(lender, true);
    }

    /// @notice Internal function to handle lending platform removal
    /// @param lender The address of the adapter for the lending platform to remove
    /// @param force Whether it is required that all the funds are withdrawn prior to removal
    function _removeLender(address lender, bool force) internal {
        IGenericLender[] memory lendersList = lenders;
        uint256 lendersListLength = lendersList.length;
        for (uint256 i; i < lendersListLength; ++i) {
            if (lender == address(lendersList[i])) {
                bool allWithdrawn = lendersList[i].withdrawAll();

                if (!force && !allWithdrawn) revert FailedWithdrawal();

                // Put the last index here
                // then remove last index
                if (i != lendersListLength - 1) {
                    lenders[i] = lendersList[lendersListLength - 1];
                }

                // Pop shortens array by 1 thereby deleting the last index
                lenders.pop();

                // If balance to spend we might as well put it into the best lender
                if (want.balanceOf(address(this)) != 0) {
                    _adjustPosition();
                }

                emit RemoveLender(lender);

                return;
            }
        }
        revert NonExistentLender();
    }

    // ============================= MANAGER FUNCTIONS =============================

    /// @notice Adds a new guardian address and echoes the change to the contracts
    /// that interact with this collateral `PoolManager`
    /// @param _guardian New guardian address
    /// @dev This internal function has to be put in this file because `AccessControl` is not defined
    /// in `PoolManagerInternal`
    function addGuardian(address _guardian) external override onlyRole(POOLMANAGER_ROLE) {
        // Granting the new role
        // Access control for this contract
        _grantRole(GUARDIAN_ROLE, _guardian);
        // Propagating the new role to underyling lenders
        uint256 lendersLength = lenders.length;
        for (uint256 i; i < lendersLength; ++i) {
            lenders[i].grantRole(GUARDIAN_ROLE, _guardian);
        }
    }

    /// @notice Revokes the guardian role and propagates the change to other contracts
    /// @param guardian Old guardian address to revoke
    function revokeGuardian(address guardian) external override onlyRole(POOLMANAGER_ROLE) {
        _revokeRole(GUARDIAN_ROLE, guardian);
        uint256 lendersLength = lenders.length;
        for (uint256 i; i < lendersLength; ++i) {
            lenders[i].revokeRole(GUARDIAN_ROLE, guardian);
        }
    }
}