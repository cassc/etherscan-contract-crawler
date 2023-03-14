// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../interfaces/vault/IVaultIndexActions.sol";
import "./RewardDrip.sol";

/**
 * @notice VaultIndexActions extends VaultBase and holds the logic to process index related data and actions.
 *
 * @dev
 * Index functions are executed when state changes are performed, to synchronize to vault with central Spool contract.
 * 
 * Index actions include:
 * - Redeem vault: claiming vault shares and withdrawn amount when DHW is complete
 * - Redeem user: claiming user deposit shares and/or withdrawn amount after vault claim has been processed
 */
abstract contract VaultIndexActions is IVaultIndexActions, RewardDrip {
    using SafeERC20 for IERC20;
    using Bitwise for uint256;

    /* ========== CONSTANTS ========== */

    /// @notice Value to multiply new deposit recieved to get the share amount
    uint128 private constant SHARES_MULTIPLIER = 10**6;
    
    /// @notice number of locked shares when initial shares are added
    /// @dev This is done to prevent rounding errors and share manipulation
    uint128 private constant INITIAL_SHARES_LOCKED = 10**11;

    /// @notice minimum shares size to avoid loss of share due to computation precision
    /// @dev If total shares go unders this value, new deposit is multiplied by the `SHARES_MULTIPLIER` again
    uint256 private constant MIN_SHARES_FOR_ACCURACY = INITIAL_SHARES_LOCKED * 10;

    /* ========== STATE VARIABLES ========== */

    /// @notice Holds up to 2 global indexes vault last interacted at and havent been redeemed yet
    /// @dev Second index can only be the next index of the first one
    /// Second index is used if the do-hard-work is executed in 2 transactions and actions are executed in between
    LastIndexInteracted public lastIndexInteracted;

    /// @notice Maps all vault actions to the corresponding global index
    mapping(uint256 => IndexAction) public vaultIndexAction;
    
    /// @notice Maps user actions to the corresponding global index
    mapping(address => mapping(uint256 => IndexAction)) public userIndexAction;

    /// @notice Holds up to 2 global indexes users last interacted with, and havent been redeemed yet
    mapping(address => LastIndexInteracted) public userLastInteractions;

    /// @notice Global index to deposit and withdraw vault redeem
    mapping(uint256 => Redeem) public redeems;

    // =========== VIEW FUNCTIONS ============ //

    /**
     * @notice Checks and sets the "is reallocating" flag for given index
     * @param index Index to check
     * @return isReallocating True if vault is reallocating at this `index`
     */
    function _isVaultReallocatingAtIndex(uint256 index) internal view returns (bool isReallocating) {
        if (index == reallocationIndex) {
            isReallocating = true;
        }
    }

    /**
     * @notice Check if the vault is set to reallocate
     * @dev True if in the current index or the next one
     * @return isReallocating True if vault is set to reallocate
     */
    function _isVaultReallocating() internal view returns (bool isReallocating) {
        if (reallocationIndex > 0) {
            isReallocating = true;
        }
    }

    // =========== VAULT REDEEM ============ //

    /**
     * @notice Redeem vault strategies after do hard work (DHW) has been completed
     * 
     * @dev
     * This is only possible if all vault strategy DHWs have been executed, otherwise it's reverted.
     * If the system is paused, function will revert - impacts vault functions deposit, withdraw, fastWithdraw,
     * claim, reallocate.
     * @param vaultStrategies strategies of this vault (verified internally)
     */
    function _redeemVaultStrategies(address[] memory vaultStrategies) internal systemNotPaused {
        LastIndexInteracted memory _lastIndexInteracted = lastIndexInteracted;
        if (_lastIndexInteracted.index1 > 0) {
            uint256 globalIndex1 = _lastIndexInteracted.index1;
            uint256 completedGlobalIndex = spool.getCompletedGlobalIndex();
            if (globalIndex1 <= completedGlobalIndex) {
                // redeem interacted index 1
                _redeemStrategiesIndex(globalIndex1, vaultStrategies);
                _lastIndexInteracted.index1 = 0;

                if (_lastIndexInteracted.index2 > 0) {
                    uint256 globalIndex2 = _lastIndexInteracted.index2;
                    if (globalIndex2 <= completedGlobalIndex) {
                        // redeem interacted index 2
                        _redeemStrategiesIndex(globalIndex2, vaultStrategies);
                    } else {
                        _lastIndexInteracted.index1 = _lastIndexInteracted.index2;
                    }
                    
                    _lastIndexInteracted.index2 = 0;
                }

                lastIndexInteracted = _lastIndexInteracted;
            }
        }
    }

    /**
     * @notice Redeem strategies for at index
     * @dev Causes additional gas for first interaction after DHW index has been completed
     * @param globalIndex Global index
     * @param vaultStrategies Array of vault strategy addresses
     */
    function _redeemStrategiesIndex(uint256 globalIndex, address[] memory vaultStrategies) private {
        uint128 _totalShares = totalShares;
        uint128 totalReceived = 0;
        uint128 totalWithdrawn = 0;
        uint128 totalUnderlyingAtIndex = 0;
        
        // if vault was reallocating at index claim reallocation deposit
        bool isReallocating = _isVaultReallocatingAtIndex(globalIndex);
        if (isReallocating) {
            spool.redeemReallocation(vaultStrategies, depositProportions, globalIndex);
            // Reset reallocation index to 0
            reallocationIndex = 0;
        }

        // go over strategies and redeem deposited shares and withdrawn amount
        for (uint256 i = 0; i < vaultStrategies.length; i++) {
            address strat = vaultStrategies[i];
            (uint128 receivedTokens, uint128 withdrawnTokens) = spool.redeem(strat, globalIndex);
            totalReceived += receivedTokens;
            totalWithdrawn += withdrawnTokens;
            
            totalUnderlyingAtIndex += spool.getVaultTotalUnderlyingAtIndex(strat, globalIndex);
        }

        // redeem underlying withdrawn token for all strategies at once
        if (totalWithdrawn > 0) {
            spool.redeemUnderlying(totalWithdrawn);
        }

        // substract withdrawn shares
        _totalShares -= vaultIndexAction[globalIndex].withdrawShares;

        // calculate new deposit shares
        uint128 newShares = 0;
        if (_totalShares <= MIN_SHARES_FOR_ACCURACY || totalUnderlyingAtIndex == 0) {
            // Enforce minimum shares size to avoid loss of share due to computation precision
            newShares = totalReceived * SHARES_MULTIPLIER;

            if (_totalShares < INITIAL_SHARES_LOCKED) {
                if (newShares + _totalShares >= INITIAL_SHARES_LOCKED) {
                    unchecked {
                        uint128 newLockedShares = INITIAL_SHARES_LOCKED - _totalShares;
                        _totalShares += newLockedShares;
                        newShares -= newLockedShares;
                    }
                } else {
                    unchecked {
                        _totalShares += newShares;
                    }
                    newShares = 0;
                }
            }
        } else {
            if (totalReceived < totalUnderlyingAtIndex) {
                unchecked {
                    newShares = _getProportion128(totalReceived, _totalShares, totalUnderlyingAtIndex - totalReceived);
                }
            } else {
                newShares = _totalShares;
            }
        }

        // add new deposit shares
        totalShares = _totalShares + newShares;

        redeems[globalIndex] = Redeem(newShares, totalWithdrawn);

        emit VaultRedeem(globalIndex);
    }

    // =========== USER REDEEM ============ //

    /**
     * @notice Redeem user deposit shares and withdrawn amount
     *
     * @dev
     * Check if vault has already claimed shares for itself
     */
    function _redeemUser() internal {
        LastIndexInteracted memory _lastIndexInteracted = lastIndexInteracted;
        LastIndexInteracted memory userIndexInteracted = userLastInteractions[msg.sender];

        // check if strategy for index has already been redeemed
        if (userIndexInteracted.index1 > 0 && 
            (_lastIndexInteracted.index1 == 0 || userIndexInteracted.index1 < _lastIndexInteracted.index1)) {
            // redeem interacted index 1
            _redeemUserAction(userIndexInteracted.index1, true);
            userIndexInteracted.index1 = 0;

            if (userIndexInteracted.index2 > 0) {
                if (_lastIndexInteracted.index2 == 0 || userIndexInteracted.index2 < _lastIndexInteracted.index1) {
                    // redeem interacted index 2
                    _redeemUserAction(userIndexInteracted.index2, false);
                } else {
                    userIndexInteracted.index1 = userIndexInteracted.index2;
                }
                
                userIndexInteracted.index2 = 0;
            }

            userLastInteractions[msg.sender] = userIndexInteracted;
        }
    }

    /**
     * @notice Redeem user action for the `index`
     * @param index index aw which user performed the action
     * @param isFirstIndex Is this the first user index
     */
    function _redeemUserAction(uint256 index, bool isFirstIndex) private {
        User storage user = users[msg.sender];
        IndexAction storage userIndex = userIndexAction[msg.sender][index];

        // redeem user withdrawn amount at index
        uint128 userWithdrawalShares = userIndex.withdrawShares;
        if (userWithdrawalShares > 0) {
            // calculate user withdrawn amount

            uint128 userWithdrawnAmount = _getProportion128(redeems[index].withdrawnAmount, userWithdrawalShares, vaultIndexAction[index].withdrawShares);

            user.owed += userWithdrawnAmount;

            // calculate proportionate deposit to pay for performance fees on claim
            uint128 proportionateDeposit;
            uint128 sharesAtWithdrawal = user.shares + userWithdrawalShares;
            if (isFirstIndex) {
                // if user has 2 withdraws pending sum shares from the pending one as well
                sharesAtWithdrawal += userIndexAction[msg.sender][index + 1].withdrawShares;
            }

            // check if withdrawal of all user shares was performes (all shares at the index of the action)
            if (sharesAtWithdrawal > userWithdrawalShares) {
                uint128 userTotalDeposit = user.activeDeposit;
                
                proportionateDeposit = _getProportion128(userTotalDeposit, userWithdrawalShares, sharesAtWithdrawal);
                user.activeDeposit = userTotalDeposit - proportionateDeposit;
            } else {
                proportionateDeposit = user.activeDeposit;
                user.activeDeposit = 0;
            }

            user.withdrawnDeposits += proportionateDeposit;

            // set user withdraw shares for index to 0
            userIndex.withdrawShares = 0;
        }

        // redeem user deposit shares at index
        uint128 userDepositAmount = userIndex.depositAmount;
        if (userDepositAmount > 0) {
            // calculate new user deposit shares
            uint128 newUserShares = _getProportion128(userDepositAmount, redeems[index].depositShares, vaultIndexAction[index].depositAmount);

            user.shares += newUserShares;
            user.activeDeposit += userDepositAmount;

            // set user deposit amount for index to 0
            userIndex.depositAmount = 0;
        }
        
        emit UserRedeem(msg.sender, index);
    }

    // =========== INDEX FUNCTIONS ============ //

    /**
     * @dev Saves vault last interacted global index
     * @param globalIndex Global index
     */
    function _updateInteractedIndex(uint24 globalIndex) internal {
        _updateLastIndexInteracted(lastIndexInteracted, globalIndex);
    }

    /**
     * @dev Saves last user interacted global index
     * @param globalIndex Global index
     */
    function _updateUserInteractedIndex(uint24 globalIndex) internal {
        _updateLastIndexInteracted(userLastInteractions[msg.sender], globalIndex);
    }

    /**
     * @dev Update last index with which the system interacted
     * @param lit Last interacted idex of a user or a vault
     * @param globalIndex Global index
     */
    function _updateLastIndexInteracted(LastIndexInteracted storage lit, uint24 globalIndex) private {
        if (lit.index1 > 0) {
            if (lit.index1 < globalIndex) {
                lit.index2 = globalIndex;
            }
        } else {
            lit.index1 = globalIndex;
        }

    }

    /**
     * @dev Gets current active global index from spool
     */
    function _getActiveGlobalIndex() internal view returns(uint24) {
        return spool.getActiveGlobalIndex();
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Ensures the vault is not currently reallocating
     */
    function _noReallocation() private view {
        require(!_isVaultReallocating(), "NRED");
    }

    /* ========== MODIFIERS ========== */

    /**
    * @dev Redeem given array of vault strategies
     */
    modifier redeemVaultStrategiesModifier(address[] memory vaultStrategies) {
        _redeemVaultStrategies(vaultStrategies);
        _;
    }

    /**
    * @dev Redeem user
     */
    modifier redeemUserModifier() {
        _redeemUser();
        _;
    }

    /**
     * @dev Ensures the vault is not currently reallocating
     */
    modifier noReallocation() {
        _noReallocation();
        _;
    }  
}