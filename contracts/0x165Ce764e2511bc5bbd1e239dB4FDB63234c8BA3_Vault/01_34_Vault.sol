// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./vault/VaultRestricted.sol";

/**
 * @notice Implementation of the {IVault} interface.
 *
 * @dev
 * All vault instances are meant to be deployed via the Controller
 * as a proxy and will not be recognizable by the Spool if they are
 * not done so.
 *
 * The vault contract is capable of supporting a single currency underlying
 * asset and deposit to multiple strategies at once, including dual-collateral
 * ones.
 *
 * The vault also supports the additional distribution of extra reward tokens as
 * an incentivization mechanism proportionate to each user's deposit amount within
 * the vhe vault.
 *
 * Vault implementation consists of following contracts:
 * 1. VaultImmutable: reads vault specific immutable variable from vault proxy contract
 * 2. VaultBase: holds vault state variables and provides some of the common vault functions
 * 3. RewardDrip: distributes vault incentivized rewards to users participating in the vault
 * 4. VaultIndexActions: implements functions to synchronize the vault with central Spool contract
 * 5. VaultRestricted: exposes functions restricted for other Spool specific contracts
 * 6. Vault: exposes unrestricted functons to interact with the core vault functionality (deposit/withdraw/claim)
 */
contract Vault is VaultRestricted {
    using SafeERC20 for IERC20;
    using Bitwise for uint256;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Sets the initial immutable values of the contract.
     *
     * @dev
     * All values have been sanitized by the controller contract, meaning
     * that no additional checks need to be applied here.
     *
     * @param _spool the spool implemenation
     * @param _controller the controller implemenation
     * @param _fastWithdraw fast withdraw implementation
     * @param _feeHandler fee handler implementation
     * @param _spoolOwner spool owner contract
     */
    constructor(
        ISpool _spool,
        IController _controller,
        IFastWithdraw _fastWithdraw,
        IFeeHandler _feeHandler,
        ISpoolOwner _spoolOwner
    )
        VaultBase(
            _spool,
            _controller,
            _fastWithdraw,
            _feeHandler
        )
        SpoolOwnable(_spoolOwner)
    {}

    /* ========== DEPOSIT ========== */

    /**
     * @notice Allows a user to perform a particular deposit to the vault.
     *
     * @dev
     * Emits a {Deposit} event indicating the amount newly deposited for index.
     *
     * Perform redeem if possible:
     * - Vault: Index has been completed (sync deposits/withdrawals)
     * - User: Claim deposit shares or withdrawn amount
     * 
     * Requirements:
     *
     * - the provided strategies must be valid
     * - the caller must have pre-approved the contract for the token amount deposited
     * - the caller cannot deposit zero value
     * - the system should not be paused
     *
     * @param vaultStrategies strategies of this vault (verified internally)
     * @param amount amount to deposit
     * @param transferFromVault if the transfer should occur from the funds transfer(controller) address
     */
    function deposit(address[] memory vaultStrategies, uint128 amount, bool transferFromVault)
        external
        verifyStrategies(vaultStrategies)
        hasStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
        redeemUserModifier
        updateRewards
    {
        require(amount > 0, "NDP");

        // get next possible index to deposit
        uint24 activeGlobalIndex = _getActiveGlobalIndex();

        // Mark user deposited amount for active index
        vaultIndexAction[activeGlobalIndex].depositAmount += amount;
        userIndexAction[msg.sender][activeGlobalIndex].depositAmount += amount;

        // Mark vault strategies to deposit at index
        _distributeInStrats(vaultStrategies, amount, activeGlobalIndex);

        // mark that vault and user have interacted at this global index
        _updateInteractedIndex(activeGlobalIndex);
        _updateUserInteractedIndex(activeGlobalIndex);

        // transfer user deposit to Spool
        _transferDepositToSpool(amount, transferFromVault);

        // store user deposit amount
        _addInstantDeposit(amount);

        emit Deposit(msg.sender, activeGlobalIndex, amount);
    }

    /**
     * @notice Distributes a deposit to the various strategies based on the allocations of the vault.
     */
    function _distributeInStrats(
        address[] memory vaultStrategies,
        uint128 amount,
        uint256 activeGlobalIndex
    ) private {
        uint128 amountLeft = amount;
        uint256 lastElement = vaultStrategies.length - 1;
        uint256 _proportions = proportions;

        for (uint256 i; i < lastElement; i++) {
            uint128 proportionateAmount = _getStrategyDepositAmount(_proportions, i, amount);
            if (proportionateAmount > 0) {
                spool.deposit(vaultStrategies[i], proportionateAmount, activeGlobalIndex);
                amountLeft -= proportionateAmount;
            }
        }

        if (amountLeft > 0) {
            spool.deposit(vaultStrategies[lastElement], amountLeft, activeGlobalIndex);
        }
    }

    /* ========== WITHDRAW ========== */

    /**
     * @notice Allows a user to withdraw their deposited funds from the vault at next possible index.
     * The withdrawal is queued for when do hard work for index is completed.
     * 
     * @dev
     * Perform redeem if possible:
     * - Vault: Index has been completed (sync deposits/withdrawals)
     * - User: Claim deposit shares or withdrawn amount
     *
     * Emits a {Withdrawal} event indicating the shares burned, index of the withdraw and the amount of funds withdrawn.
     *
     * Requirements:
     *
     * - vault must not be reallocating
     * - the provided strategies must be valid
     * - the caller must have a non-zero amount of shares to withdraw
     * - the caller must have enough shares to withdraw the specified share amount
     * - the system should not be paused
     *
     * @param vaultStrategies strategies of this vault (verified internally)
     * @param sharesToWithdraw shares amount to withdraw
     * @param withdrawAll if all shares should be removed
     */
    function withdraw(
        address[] memory vaultStrategies,
        uint128 sharesToWithdraw,
        bool withdrawAll
    )
        external
        verifyStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
        noReallocation
        redeemUserModifier
        updateRewards
    {
        sharesToWithdraw = _withdrawShares(sharesToWithdraw, withdrawAll);
        
        // get next possible index to withdraw
        uint24 activeGlobalIndex = _getActiveGlobalIndex();

        // mark user withdrawn shares amount for active index
        userIndexAction[msg.sender][activeGlobalIndex].withdrawShares += sharesToWithdraw;
        vaultIndexAction[activeGlobalIndex].withdrawShares += sharesToWithdraw;

        // mark strategies in the spool contract to be withdrawn at next possible index
        _withdrawFromStrats(vaultStrategies, sharesToWithdraw, activeGlobalIndex);

        // mark that vault and user interacted at this global index
        _updateInteractedIndex(activeGlobalIndex);
        _updateUserInteractedIndex(activeGlobalIndex);

        emit Withdraw(msg.sender, activeGlobalIndex, sharesToWithdraw);
    }

    /* ========== FAST WITHDRAW ========== */

    /**
     * @notice Allows a user to withdraw their deposited funds right away.
     *
     * @dev
     * @dev
     * User can execute the withdrawal of his shares from the vault at any time without
     * waiting for the DHW to process it. This is done independently of other events (e.g. DHW)
     * and the gas cost is paid entirely by the user.
     * Shares belonging to the user and are sent back to the FastWithdraw contract
     * where an actual withdrawal can be peformed, where user recieves the underlying tokens
     * right away.
     *
     * Requirements:
     *
     * - vault must not be reallocating
     * - the spool system must not be mid reallocation
     *   (started DHW and not finished, at index the reallocation was initiated)
     * - the provided strategies must be valid
     * - the sistem must not be in the middle of the reallocation
     * - the system should not be paused
     *
     * @param vaultStrategies strategies of this vault
     * @param sharesToWithdraw shares amount to withdraw
     * @param withdrawAll if all shares should be removed
     * @param fastWithdrawParams extra parameters to perform fast withdraw
     */
    function withdrawFast(
        address[] memory vaultStrategies,
        uint128 sharesToWithdraw,
        bool withdrawAll,
        FastWithdrawParams memory fastWithdrawParams
    )
        external
        noMidReallocation
        verifyStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
        noReallocation
        redeemUserModifier
        updateRewards
    {
        sharesToWithdraw = _withdrawShares(sharesToWithdraw, withdrawAll);

        uint256 vaultShareProportion = _getVaultShareProportion(sharesToWithdraw);
        totalShares -= sharesToWithdraw;

        uint128[] memory strategyRemovedShares = spool.removeShares(vaultStrategies, vaultShareProportion);

        uint256 proportionateDeposit = _getUserProportionateDeposit(sharesToWithdraw);

        // transfer removed shares to fast withdraw contract
        fastWithdraw.transferShares(
            vaultStrategies,
            strategyRemovedShares,
            proportionateDeposit,
            msg.sender,
            fastWithdrawParams
        );

        emit WithdrawFast(msg.sender, sharesToWithdraw);
    }

    /**
     * @dev Updates storage values according to shares withdrawn.
     *      If `withdrawAll` is true, all shares are removed from the users
     * @param sharesToWithdraw Amount of shares to withdraw
     * @param withdrawAll Withdraw all user shares
     */
    function _withdrawShares(uint128 sharesToWithdraw, bool withdrawAll) private returns(uint128) {
        User storage user = users[msg.sender];
        uint128 userShares = user.shares;

        uint128 userActiveInstantDeposit = user.instantDeposit;

        // Substract the not processed instant deposit
        // This way we don't consider the deposit that was not yet processed by the DHW
        // when calculating amount of it withdrawn
        LastIndexInteracted memory userIndexInteracted = userLastInteractions[msg.sender];
        if (userIndexInteracted.index1 > 0) {
            userActiveInstantDeposit -= userIndexAction[msg.sender][userIndexInteracted.index1].depositAmount;
            // also check if user second index has pending actions
            if (userIndexInteracted.index2 > 0) {
                userActiveInstantDeposit -= userIndexAction[msg.sender][userIndexInteracted.index2].depositAmount;
            }
        }
        
        // check if withdraw all flag was set or user requested
        // withdraw of all shares in `sharesToWithdraw`
        if (withdrawAll || (userShares > 0 && userShares == sharesToWithdraw)) {
            sharesToWithdraw = userShares;
            // set user shares to 0
            user.shares = 0;

            // substract all the users instant deposit processed till now
            // substract the same amount from vault total instand deposit value
            totalInstantDeposit -= userActiveInstantDeposit;
            user.instantDeposit -= userActiveInstantDeposit;
        } else {
            require(
                userShares >= sharesToWithdraw &&
                sharesToWithdraw > 0, 
                "WSH"
            );

            // if we didnt withdraw all calculate the proportion of
            // the instant deposit to substract it from the user and vault amounts
            uint128 instantDepositWithdrawn = _getProportion128(userActiveInstantDeposit, sharesToWithdraw, userShares);

            totalInstantDeposit -= instantDepositWithdrawn;
            user.instantDeposit -= instantDepositWithdrawn;

            // susrtact withdrawn shares from the user
            // NOTE: vault shares will be substracted when the at the redeem
            // for the current active index is processed. This way we substract it
            // only once for all the users.
            unchecked {
                user.shares = userShares - sharesToWithdraw;
            }
        }
        
        return sharesToWithdraw;
    }

    /**
     * @notice Calculates user proportionate deposit when withdrawing and updated user deposit storage
     * @dev Checks user index action to see if user already has some withdrawn shares
     *      pending to be processed.
     *      Called when performing the fast withdraw
     *
     * @param sharesToWithdraw shares amount to withdraw
     *
     * @return User deposit amount proportionate to the amount of shares being withdrawn
     */
    function _getUserProportionateDeposit(uint128 sharesToWithdraw) private returns(uint256) {
        User storage user = users[msg.sender];
        LastIndexInteracted memory userIndexInteracted = userLastInteractions[msg.sender];

        uint128 proportionateDeposit;
        uint128 sharesAtWithdrawal = user.shares + sharesToWithdraw;

        if (userIndexInteracted.index1 > 0) {
            sharesAtWithdrawal += userIndexAction[msg.sender][userIndexInteracted.index1].withdrawShares;

            if (userIndexInteracted.index2 > 0) {
                sharesAtWithdrawal += userIndexAction[msg.sender][userIndexInteracted.index2].withdrawShares;
            }
        }

        if (sharesAtWithdrawal > sharesToWithdraw) {
            uint128 userTotalDeposit = user.activeDeposit;
            proportionateDeposit = _getProportion128(userTotalDeposit, sharesToWithdraw, sharesAtWithdrawal);
            user.activeDeposit = userTotalDeposit - proportionateDeposit;
        } else {
            proportionateDeposit = user.activeDeposit;
            user.activeDeposit = 0;
        }

        return proportionateDeposit;
    }

    function _withdrawFromStrats(address[] memory vaultStrategies, uint128 totalSharesToWithdraw, uint256 activeGlobalIndex) private {
        uint256 vaultShareProportion = _getVaultShareProportion(totalSharesToWithdraw);
        for (uint256 i; i < vaultStrategies.length; i++) {
            spool.withdraw(vaultStrategies[i], vaultShareProportion, activeGlobalIndex);
        }
    }

    /* ========== CLAIM ========== */

    /**
     * @notice Allows a user to claim their debt from the vault after withdrawn shares were processed.
     *
     * @dev
     * Fee is taken from the profit
     * Perform redeem on user demand
     *
     * Emits a {DebtClaim} event indicating the debt the user claimed.
     *
     * Requirements:
     *
     * - if `doRedeemVault` is true, the provided strategies must be valid
     * - the caller must have a non-zero debt owed
     * - the system should not be paused (if doRedeemVault)
     *
     * @param doRedeemVault flag, to execute redeem for the vault (synchronize deposit/withdrawals with the system)
     * @param vaultStrategies vault stratigies
     * @param doRedeemUser flag, to execute redeem for the caller
     *
     * @return claimAmount amount of underlying asset, claimed by the caller
     */
    function claim(
        bool doRedeemVault,
        address[] memory vaultStrategies,
        bool doRedeemUser
    ) external returns (uint128 claimAmount) {
        User storage user = users[msg.sender];

        if (doRedeemVault) {
            _verifyStrategies(vaultStrategies);
            _redeemVaultStrategies(vaultStrategies);
        }

        if (doRedeemUser) {
            _redeemUser();
        }

        claimAmount = user.owed;
        require(claimAmount > 0, "CA0");

        user.owed = 0;

        // Calculate profit and take fees
        uint128 userWithdrawnDeposits = user.withdrawnDeposits;
        if (claimAmount > userWithdrawnDeposits) {
            user.withdrawnDeposits = 0;
            uint128 profit = claimAmount - userWithdrawnDeposits;

            uint128 feesPaid = _payFeesAndTransfer(profit);

            // Substract fees paid from claim amount
            claimAmount -= feesPaid;
        } else {
            user.withdrawnDeposits = userWithdrawnDeposits - claimAmount;
        }

        _underlying().safeTransfer(msg.sender, claimAmount);

        emit Claimed(msg.sender, claimAmount);
    }

    /* ========== REDEEM ========== */

    /**
     * @notice Redeem vault and user deposit and withdrawals
     *
     * Requirements:
     *
     * - the provided strategies must be valid
     *
     * @param vaultStrategies vault stratigies
     */
    function redeemVaultAndUser(address[] memory vaultStrategies)
        external
        verifyStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
        redeemUserModifier
    {}

    /**
     * @notice Redeem vault and user and return the user state
     * @dev Intended to be called as a static call for view purposes
     *
     * Requirements:
     *
     * - the provided strategies must be valid
     *
     * @param vaultStrategies vault strategies
     *
     * @return userShares current user shares
     * @return activeDeposit user active deposit (already processed by the DHW)
     * @return userOwed user total unclaimed amount
     * @return userWithdrawnDeposits unclaimed withdrawn deposit amount
     * @return userTotalUnderlying current user total underlying
     * @return pendingDeposit1 pending user deposit for the next index 
     * @return pendingWithdrawalShares1 pending user withdrawal shares for the next index 
     * @return pendingDeposit2 pending user deposit for the index after the next one 
     * @return pendingWithdrawalShares2 pending user withdrawal shares for the after the next one 
     */
    function getUpdatedUser(address[] memory vaultStrategies)
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 totalUnderlying, , , , , ) = getUpdatedVault(vaultStrategies);
        _redeemUser();
        
        User storage user = users[msg.sender];

        uint256 userTotalUnderlying;
        if (totalShares > 0 && user.shares > 0) {
            userTotalUnderlying = (totalUnderlying * user.shares) / totalShares;
        }

        IndexAction storage indexAction1 = userIndexAction[msg.sender][userLastInteractions[msg.sender].index1];
        IndexAction storage indexAction2 = userIndexAction[msg.sender][userLastInteractions[msg.sender].index2];

        return (
            user.shares,
            user.activeDeposit, // amount of user deposited underlying token
            user.owed, // underlying token claimable amount
            user.withdrawnDeposits, // underlying token withdrawn amount
            userTotalUnderlying,
            indexAction1.depositAmount,
            indexAction1.withdrawShares,
            indexAction2.depositAmount,
            indexAction2.withdrawShares
        );
    }

    /**
     * @notice Redeem vault strategy deposits and withdrawals after do hard work.
     *
     * Requirements:
     *
     * - the provided strategies must be valid
     *
     * @param vaultStrategies vault strategies
     */
    function redeemVaultStrategies(address[] memory vaultStrategies)
        external
        verifyStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
    {}

    /**
     * @notice Redeem vault strategy deposits and withdrawals after do hard work.
     * @dev Intended to be called as a static call for view purposes
     *
     * Requirements:
     *
     * - the provided strategies must be valid
     *
     * @param vaultStrategies vault strategies
     *
     * @return totalUnderlying total vault underlying
     * @return totalShares total vault shares
     * @return pendingDeposit1 pending vault deposit for the next index 
     * @return pendingWithdrawalShares1 pending vault withdrawal shares for the next index 
     * @return pendingDeposit2 pending vault deposit for the index after the next one 
     * @return pendingWithdrawalShares2 pending vault withdrawal shares for the after the next one 
     */
    function getUpdatedVault(address[] memory vaultStrategies)
        public
        verifyStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 totalUnderlying = 0;
        for (uint256 i; i < vaultStrategies.length; i++) {
            totalUnderlying += spool.getUnderlying(vaultStrategies[i]);
        }

        IndexAction storage indexAction1 = vaultIndexAction[lastIndexInteracted.index1];
        IndexAction storage indexAction2 = vaultIndexAction[lastIndexInteracted.index2];

        return (
            totalUnderlying,
            totalShares,
            indexAction1.depositAmount,
            indexAction1.withdrawShares,
            indexAction2.depositAmount,
            indexAction2.withdrawShares
        );
    }

    /**
     * @notice Redeem user deposits and withdrawals
     *
     * @dev Can only redeem user up to last index vault has redeemed
     */
    function redeemUser()
        external
    {
        _redeemUser();
    }

    /* ========== STRATEGY REMOVED ========== */

    /**
     * @notice Notify a vault a strategy was removed from the Spool system
     * @dev
     * This can be called by anyone after a strategy has been removed from the system.
     * After the removal of the strategy that the vault contains, all actions
     * calling central Spool contract will revert. This function must be called,
     * to remove the strategy from the vault and update the strategy hash according
     * to the new strategy array.
     *
     * Requirements:
     *
     * - The Spool system must finish reallocation if it's in progress
     * - the provided strategies must be valid
     * - The strategy must belong to this vault
     * - The strategy must be removed from the system
     *
     * @param vaultStrategies Array of current vault strategies (including the removed one)
     * @param i Index of the removed strategy in the `vaultStrategies`
     */
    function notifyStrategyRemoved(
        address[] memory vaultStrategies,
        uint256 i
    )
        external
        reallocationFinished
        verifyStrategies(vaultStrategies)
        hasStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
    {
        require(
            i < vaultStrategies.length &&
            !controller.validStrategy(vaultStrategies[i]),
            "BSTR"
        );

        uint256 lastElement = vaultStrategies.length - 1;

        address[] memory newStrategies = new address[](lastElement);

        if (lastElement > 0) {
            for (uint256 j; j < lastElement; j++) {
                newStrategies[j] = vaultStrategies[j];
            }

            if (i < lastElement) {
                newStrategies[i] = vaultStrategies[lastElement];
            }

            uint256 _proportions = proportions;
            uint256 proportionsLeft = FULL_PERCENT - _proportions.get14BitUintByIndex(i);
            if (lastElement > 1 && proportionsLeft > 0) {
                if (i == lastElement) {
                    _proportions = _proportions.reset14BitUintByIndex(i);
                } else {
                    uint256 lastProportion = _proportions.get14BitUintByIndex(lastElement);
                    _proportions = _proportions.reset14BitUintByIndex(i);
                    _proportions = _proportions.set14BitUintByIndex(i, lastProportion);
                }

                uint256 newProportions;

                uint256 lastNewElement = lastElement - 1;
                uint256 newProportionsLeft = FULL_PERCENT;
                for (uint256 j; j < lastNewElement; j++) {
                    uint256 propJ = _proportions.get14BitUintByIndex(j);
                    propJ = (propJ * FULL_PERCENT) / proportionsLeft;
                    newProportions = newProportions.set14BitUintByIndex(j, propJ);
                    newProportionsLeft -= propJ;
                }

                newProportions = newProportions.set14BitUintByIndex(lastNewElement, newProportionsLeft);

                proportions = newProportions;
            } else {
                proportions = FULL_PERCENT;
            }
        } else {
            proportions = 0;
        }

        _updateStrategiesHash(newStrategies);
        emit StrategyRemoved(i, vaultStrategies[i]);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @notice Throws if given array of strategies is empty
     */
    function _hasStrategies(address[] memory vaultStrategies) private pure {
        require(vaultStrategies.length > 0, "NST");
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Throws if given array of strategies is empty
     */
    modifier hasStrategies(address[] memory vaultStrategies) {
        _hasStrategies(vaultStrategies);
        _;
    }

    /**
     * @notice Revert if reallocation is not finished for this vault
     */
    modifier reallocationFinished() {
        require(
            !_isVaultReallocating() ||
            reallocationIndex <= spool.getCompletedGlobalIndex(),
            "RNF"
        );
        _;
    }
}