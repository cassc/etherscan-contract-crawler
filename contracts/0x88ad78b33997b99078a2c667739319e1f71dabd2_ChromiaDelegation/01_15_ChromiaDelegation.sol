// SPDX-License-Identifier: MIT

/*
    This contract has three parts: Delegation, Yield and ProviderStaking.
    IMPORTANT: User can only make 1 change at a time, meaning e.g. if they increase stake, they must delegate, before increasing stake again.
    User MUST `undelegate(..)` AFTER reqesting a withdrawal, but BEFORE actually withdrawing their stake from TWN, otherwise their records
    in TWN will gone and cannot be synced.
*/

pragma solidity ^0.8.17;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ITwoWeeksNotice} from "contracts/interfaces/ITwoWeeksNotice.sol";

struct DelegationChange {
    address delegatedTo;
    uint72 balance;
    uint16 nextChange;
}

struct DelegationState {
    uint16 claimedEpoch;
    uint16 latestChangeEpoch;
    uint96 processed;
    uint32 processedDate; // By day. Multiple by 1 day for *time*.
    uint96 balanceAtProcessed;
    mapping(uint16 => DelegationChange) delegationTimeline; // each uint key is a week starting from "startTime"
}

struct RateTimeline {
    uint16 latestChangeEpoch;
    mapping(uint16 => uint16) timeline;
    mapping(uint16 => uint16) nextChange;
}

struct ProviderStateChange {
    bool lostWhitelist; // provider got removed from whitelist this epoch
    bool gainedWhitelist; // provider got added to whitelist this epoch
    uint96 delegationsIncrease;
    uint96 delegationsDecrease;
    uint16 nextChangeDelegations;
    uint16 nextChangeWhitelist;
}

struct AdditionalReward {
    uint16 additionalRewardPerYieldPeriodPerToken;
    uint16 epoch;
}

struct ProviderState {
    bool whitelisted;
    uint16 claimedEpochReward;
    uint16 latestDelegationsChange;
    uint16 latestWhitelistChange;
    uint128 latestTotalDelegation;
    uint16 latestTotalDelegationEpoch;
    AdditionalReward[] additionalRewards;
    mapping(uint16 => ProviderStateChange) providerStateTimeline;
}

/// @title ChromiaProvider Delegation
/// @author Mustafa Koray Kaya
/// @notice TwoWeekNoticeProvider extension that allows delegation rewards for an existing TwoWeekNotice contract.
/// @dev Syncronizes state with the TWN contract when delegation is altered.
/// @dev Syncronization must also be performed before a TWN withdrawal
contract ChromiaDelegation is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    bytes32 public constant WHITELIST_ADMIN = keccak256("WHITELIST_ADMIN");
    bytes32 public constant RATE_ADMIN = keccak256("RATE_ADMIN");
    bytes32 public constant ADDITIONAL_REWARD_ADMIN = keccak256("ADDITIONAL_REWARD_ADMIN");

    uint32 public immutable yieldPeriod;
    uint32 public immutable epochLength;
    uint32 public immutable startTime;

    ITwoWeeksNotice public immutable twn;
    IERC20Metadata public immutable token;
    address public bank;

    uint128 private immutable minorTokenUnitsInMajor;

    mapping(address => DelegationState) public delegatorStates;
    mapping(address => ProviderState) public providerStates;

    RateTimeline private delegatorYieldTimeline; // The yield delegators get for delegating
    RateTimeline private providerRewardRateTimeline; // The reward the provider gets from the delegations that are delegated to them

    event Delegated(address indexed delegator, address indexed provider, uint128 amount);
    event Undelegated(address indexed delegator, address indexed provider, uint128 amount);
    event DelegatorYieldRateChanged(uint16 newRate);
    event ProviderTotalDelegationRateChanged(uint16 newRate);
    event AddedWhitelist(address provider);
    event RemovedWhitelist(address provider);
    event RevisedDelegation(address delegator);
    event ResetAccount(address delegator);
    event GrantedAdditionalReward(address provider, uint16 rate);
    event ClaimedYield(address delegator, uint128 amount);
    event ProviderClaimedTotalDelegationYield(address provider, uint128 amount);

    string private constant INVALID_WITHDRAW_ERROR = "Withdrawn without undelegating";
    string private constant TIMELINE_MISMATCH_ERROR = "Timeline does not match with TWN.";
    string private constant UNAUTHORISED_ERROR = "Unauthorized";
    string private constant CANNOT_CHANGE_WITHDRAWAL_ERROR = "Cannot change delegation while withdrawing";
    string private constant WITHDRAWAL_NOT_REQUESTED_ERROR = "Withdraw has not been requested";
    string private constant MUST_HAVE_STAKE_ERROR = "Must have a stake to delegate";
    string private constant MUST_WHITELISTED_ERROR = "Provider must be whitelisted";
    string private constant MUST_AFTER_START_ERROR = "Time must be after start time";
    string private constant CHANGE_TOO_RECENT_ERROR = "Change is too recent";
    string private constant ZERO_REWARD_ERROR = "Reward is 0";
    string private constant FIRST_DELEGATION_NEEDED_ERROR = "Address must make a first delegation.";
    string private constant ALREADY_SYNCRONISED_ERROR = "Stake is synced";

    constructor(
        IERC20Metadata _token,
        ITwoWeeksNotice _twn,
        address _owner,
        uint16 _delegatorYield, // Yield delegators get for delegating
        uint16 _totalDelegationYield, // Yield providers get on the total amount delegated to them
        address _bank,
        uint32 _yieldPeriodInSecs,
        uint32 _epochLengthInYieldPeriods
    ) {
        yieldPeriod = _yieldPeriodInSecs;
        epochLength = _epochLengthInYieldPeriods * yieldPeriod;
        startTime = uint32(block.timestamp) - epochLength;

        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(WHITELIST_ADMIN, _owner);
        _setupRole(RATE_ADMIN, _owner);
        _setupRole(ADDITIONAL_REWARD_ADMIN, _owner);

        twn = _twn;
        token = _token;
        bank = _bank;

        minorTokenUnitsInMajor = uint128(10 ** token.decimals());

        delegatorYieldTimeline.timeline[1] = _delegatorYield;
        delegatorYieldTimeline.nextChange[0] = 1;
        delegatorYieldTimeline.latestChangeEpoch = 1;

        providerRewardRateTimeline.timeline[1] = _totalDelegationYield;
        providerRewardRateTimeline.nextChange[0] = 1;
        providerRewardRateTimeline.latestChangeEpoch = 1;
    }

    /// @dev Has the delegator's stake on the TWN contract not been released or modified.
    function isStakeValid(address account) public view returns (bool) {
        (, uint128 remoteAccumulated) = twn.getAccumulated(account);
        return remoteAccumulated == delegatorStates[account].processed;
    }

    /**
     *
     * SETTERS AND GETTERS
     *
     */

    /// @notice Set the reward rate to `rewardRate` for the *next* epoch
    function setRewardRate(uint16 newRate) external {
        setNewRate(newRate, delegatorYieldTimeline);
        emit DelegatorYieldRateChanged(newRate);
    }

    /// @notice Set the provider reward rate to `newRate` at the new epoch
    function setProviderRewardRate(uint16 newRate) external {
        setNewRate(newRate, providerRewardRateTimeline);
        emit ProviderTotalDelegationRateChanged(newRate);
    }

    function setNewRate(uint16 newRate, RateTimeline storage rateTimeline) private {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(RATE_ADMIN, msg.sender), UNAUTHORISED_ERROR);
        uint16 nextEpoch = getCurrentEpoch() + 1;
        rateTimeline.timeline[nextEpoch] = newRate;
        if (rateTimeline.latestChangeEpoch != nextEpoch) {
            rateTimeline.nextChange[rateTimeline.latestChangeEpoch] = nextEpoch;
            rateTimeline.latestChangeEpoch = nextEpoch;
        }
    }

    function journalProviderWhitelistChange(ProviderState storage providerState) private returns (uint16 newLatestChange) {
        ProviderStateChange storage nextChangeMapping = providerState.providerStateTimeline[providerState.latestWhitelistChange];
        if (providerState.latestWhitelistChange != getCurrentEpoch()) {
            nextChangeMapping.nextChangeWhitelist = getCurrentEpoch();
            return getCurrentEpoch();
        }
        return providerState.latestWhitelistChange;
    }

    function journalProviderDelegationChange(ProviderState storage ps) private returns (uint16 newLatestChange) {
        uint16 changeEpoch = getCurrentEpoch() + 1;
        ProviderStateChange storage nextChangeMapping = ps.providerStateTimeline[ps.latestDelegationsChange];
        if (ps.latestDelegationsChange != changeEpoch) {
            nextChangeMapping.nextChangeDelegations = changeEpoch;
            return changeEpoch;
        }
        return ps.latestDelegationsChange;
    }

    function journalDelegationChange(uint16 epoch, DelegationState storage userState) private returns (uint16 newLatestChange) {
        DelegationChange storage nextChangeMapping = userState.delegationTimeline[userState.latestChangeEpoch];

        if (userState.latestChangeEpoch != epoch) {
            nextChangeMapping.nextChange = epoch;
            return epoch;
        }
        return userState.latestChangeEpoch;
    }

    /// @notice Gets the current active reward rate in the present epoch
    function getActiveProviderRewardRate(uint16 epoch) public view returns (uint128 activeRate, uint16 latestEpoch) {
        return getActiveRate(epoch, providerRewardRateTimeline);
    }

    /// @notice Get the reward rate active at epoch `epoch`
    function getActiveYieldRate(uint16 epoch) public view returns (uint128 activeRate, uint16 latestEpoch) {
        return getActiveRate(epoch, delegatorYieldTimeline);
    }

    function getActiveRate(uint16 epoch, RateTimeline storage rateTimeline) private view returns (uint128 activeRate, uint16 latestEpoch) {
        if (epoch >= rateTimeline.latestChangeEpoch) {
            return (rateTimeline.timeline[rateTimeline.latestChangeEpoch], rateTimeline.latestChangeEpoch);
        }

        uint16 nextChange = 0;
        while (true) {
            if (rateTimeline.nextChange[nextChange] > epoch) {
                return (rateTimeline.timeline[nextChange], nextChange);
            }
            nextChange = rateTimeline.nextChange[nextChange];
        }
    }

    /// @notice Get the active delegates state for `account` at epoch `epoch`
    function getActiveDelegation(address account, uint16 epoch) public view returns (DelegationChange memory activeDelegation, uint16 latestEpoch) {
        DelegationState storage userState = delegatorStates[account];
        if (userState.latestChangeEpoch == 0) {
            return (activeDelegation, 0);
        }
        if (epoch >= userState.latestChangeEpoch) {
            return (userState.delegationTimeline[userState.latestChangeEpoch], userState.latestChangeEpoch);
        }

        uint16 nextChange = 0;
        while (true) {
            if (userState.delegationTimeline[nextChange].nextChange > epoch) {
                return (userState.delegationTimeline[nextChange], nextChange);
            }
            nextChange = userState.delegationTimeline[nextChange].nextChange;
        }
    }

    /// @notice Get if the account has whitelist at certain epoch
    function getWhitelisted(address account, uint16 epoch) public view returns (bool whitelisted, uint16 latestEpoch) {
        ProviderState storage providerState = providerStates[account];

        if (providerState.latestWhitelistChange == 0) {
            return (false, 0);
        }

        ProviderStateChange storage psc;
        if (epoch >= providerState.latestWhitelistChange) {
            psc = providerState.providerStateTimeline[providerState.latestWhitelistChange];
            if (psc.lostWhitelist) {
                return (false, providerState.latestWhitelistChange);
            } else if (psc.gainedWhitelist) {
                return (true, providerState.latestWhitelistChange);
            }
        }

        uint16 nextChange = 0;
        while (true) {
            if (providerState.providerStateTimeline[nextChange].nextChangeWhitelist > epoch) {
                psc = providerState.providerStateTimeline[nextChange];
                if (psc.lostWhitelist) {
                    return (false, nextChange);
                } else if (psc.gainedWhitelist) {
                    return (true, nextChange);
                }
            }
            nextChange = providerState.providerStateTimeline[nextChange].nextChangeWhitelist;
        }
    }

    function getTotalDelegations(address provider) external view returns (uint128 totalDelegations) {
        ProviderState storage providerState = providerStates[provider];
        totalDelegations = providerState.latestTotalDelegation;
        uint16 next = providerState.providerStateTimeline[providerState.latestTotalDelegationEpoch].nextChangeDelegations;

        ProviderStateChange storage psc;
        while (true) {
            if (next == 0 || next > getCurrentEpoch() - 1) {
                break;
            }
            psc = providerState.providerStateTimeline[next];
            if (psc.delegationsIncrease != 0) {
                totalDelegations += psc.delegationsIncrease;
            }

            if (psc.delegationsDecrease != 0) {
                if (totalDelegations > psc.delegationsDecrease) {
                    totalDelegations -= psc.delegationsDecrease;
                } else totalDelegations = 0;
            }
            next = providerState.providerStateTimeline[next].nextChangeDelegations;
        }
    }

    /**
     *
     * DELEGATION MANAGEMENT
     *
     */

    function removeCurrentDelegationFromProvider(DelegationChange memory currentDelegation, uint16 currDelEpoch) private {
        uint16 nextEpoch = getCurrentEpoch() + 1;
        ProviderState storage ps = providerStates[currentDelegation.delegatedTo];
        // If provider has lost whitelist since delegation, dont bother to decreae since their total is already set to 0 on
        // removeWhitelist()
        if (currDelEpoch >= ps.latestWhitelistChange) {
            // Remove previous delegation from providers pool
            ps.providerStateTimeline[nextEpoch].delegationsDecrease += currentDelegation.balance;
            ps.latestDelegationsChange = journalProviderDelegationChange(ps);
        }
    }

    function addDelegation(DelegationState storage userState, uint16 epoch, address to, uint128 acc, uint64 since, uint64 delegateAmount) private {
        userState.delegationTimeline[epoch] = DelegationChange(to, delegateAmount, 0);
        userState.latestChangeEpoch = journalDelegationChange(epoch, userState);
        userState.balanceAtProcessed = delegateAmount;
        userState.processed = uint96(acc);
        userState.processedDate = uint32(since / yieldPeriod);
    }

    /// @notice Removes delegation after a withdrawal is requested. Failure to do so prior to withdrawal may result in lost.
    function undelegate(address account) external nonReentrant {
        (, , uint64 lockedUntil, uint64 since) = twn.getStakeState(account);
        require(lockedUntil > 0, WITHDRAWAL_NOT_REQUESTED_ERROR);
        DelegationState storage userState = delegatorStates[account];
        (, uint128 acc) = twn.getAccumulated(msg.sender);

        ensureSyncronisedDelegationState(userState, acc, since);

        uint16 nextEpoch = getCurrentEpoch() + 1;
        // Remove previous delegation from providers pool
        (DelegationChange memory currentDelegation, uint16 currDelEpoch) = getActiveDelegation(msg.sender, nextEpoch);
        removeCurrentDelegationFromProvider(currentDelegation, currDelEpoch);
        addDelegation(userState, getEpoch(since), address(0), acc, since, 0);

        emit Undelegated(account, currentDelegation.delegatedTo, currentDelegation.balance);
    }

    /// @notice Set the delegation of the caller for the *next* epoch
    function delegate(address to) external nonReentrant {
        DelegationState storage userState = delegatorStates[msg.sender];
        ProviderState storage ps = providerStates[to];

        (, uint128 acc) = twn.getAccumulated(msg.sender);
        (uint64 delegateAmount, , uint64 lockedUntil, uint64 since) = twn.getStakeState(msg.sender);

        require(delegateAmount > 0, MUST_HAVE_STAKE_ERROR);
        require(lockedUntil == 0, CANNOT_CHANGE_WITHDRAWAL_ERROR);
        require(ps.whitelisted, MUST_WHITELISTED_ERROR);

        uint16 nextEpoch = getCurrentEpoch() + 1;

        // Remove previous delegation from providers pool so that they cannot claim rewards from it if we have a new provider
        (DelegationChange memory currentDelegation, uint16 currDelEpoch) = getActiveDelegation(msg.sender, nextEpoch);
        if (currentDelegation.delegatedTo != address(0) && (currentDelegation.delegatedTo != to || currDelEpoch < ps.latestWhitelistChange)) {
            removeCurrentDelegationFromProvider(currentDelegation, currDelEpoch); // 40k gas
        }

        if (userState.latestChangeEpoch == 0) {
            userState.claimedEpoch = nextEpoch - 1; // If user has never delegated before, set claimedEpoch to current epoch
        } else {
            ensureSyncronisedDelegationState(userState, acc, since); // Make sure that the user hasnt decreased stake since last delegation
        }
        addDelegation(userState, nextEpoch, to, acc, since, delegateAmount); // 80k gas. Add delegation to users state

        // Add to new providers "totalDelegations" pool so they can claim rewards
        // 40k gas
        if (currentDelegation.delegatedTo != to || currDelEpoch < ps.latestWhitelistChange) {
            ps.providerStateTimeline[nextEpoch].delegationsIncrease += delegateAmount;
        } else {
            ps.providerStateTimeline[nextEpoch].delegationsIncrease += delegateAmount - currentDelegation.balance;
        }
        ps.latestDelegationsChange = journalProviderDelegationChange(ps);
        emit Delegated(msg.sender, to, delegateAmount);
    }

    /// @notice Remove the calling account's delegation status. Call only if state is "broken".
    function resetAccount() external {
        DelegationState storage userState = delegatorStates[msg.sender];
        require(userState.latestChangeEpoch > 0, FIRST_DELEGATION_NEEDED_ERROR);

        (DelegationChange memory currentDelegation, uint16 currDelEpoch) = getActiveDelegation(msg.sender, getCurrentEpoch() + 1);
        removeCurrentDelegationFromProvider(currentDelegation, currDelEpoch);
        delete delegatorStates[msg.sender];

        emit ResetAccount(msg.sender);
    }

    /// @notice Matches `account`'s delegation to the underlying stake. `isStakeValid(account)` must be false before call.
    function reviseDelegation(address account) external nonReentrant {
        require(!isStakeValid(account), ALREADY_SYNCRONISED_ERROR);

        (, , , uint64 since) = twn.getStakeState(account);
        require(block.timestamp - since > epochLength, CHANGE_TOO_RECENT_ERROR);
        DelegationState storage userState = delegatorStates[account];
        require(userState.latestChangeEpoch > 0, FIRST_DELEGATION_NEEDED_ERROR);

        uint16 currentEpoch = getCurrentEpoch();

        (DelegationChange memory currentDelegation, uint16 currDelEpoch) = getActiveDelegation(account, currentEpoch + 1);
        removeCurrentDelegationFromProvider(currentDelegation, currDelEpoch);

        userState.delegationTimeline[currentEpoch] = DelegationChange(address(0), 0, 0);
        userState.latestChangeEpoch = journalDelegationChange(currentEpoch, userState);
        emit RevisedDelegation(account);
    }

    /**
     *
     * REWARD FUNCTIONS
     *
     */

    /// @notice Estimates the additional reward providers get for the total amount delegated to them per epoch
    function updateProviderDelegationRewardEstimate(address account) external nonReentrant returns (uint128 reward) {
        return _updateProviderDelegationRewardEstimate(account);
    }

    function _updateProviderDelegationRewardEstimate(address account) internal returns (uint128 reward) {
        ProviderState storage providerState = providerStates[account];
        uint16 currentEpoch = getCurrentEpoch();

        if (currentEpoch - 1 <= providerState.claimedEpochReward) {
            return 0;
        }

        uint128 totalDelegations = providerState.latestTotalDelegation;
        uint16 nextDC = providerState.latestTotalDelegationEpoch;
        (uint128 activeRate, uint16 nextAR) = getActiveProviderRewardRate(providerState.claimedEpochReward + 1);

        uint16 latestTotalDelegationEpoch = nextDC;

        nextAR = providerRewardRateTimeline.nextChange[nextAR];
        nextDC = providerState.providerStateTimeline[nextDC].nextChangeDelegations;

        uint16 prev = providerState.claimedEpochReward + 1;
        uint16 next = findSmallestNonZero(nextAR, nextDC);
        if (next == 0 || next >= currentEpoch) {
            next = currentEpoch;
        }
        ProviderStateChange storage psc;
        while (true) {
            reward += uint128((activeRate) * totalDelegations * epochLength) * (next - prev);

            if (next == currentEpoch) break;

            if (next == nextAR) {
                activeRate = providerRewardRateTimeline.timeline[next];
                nextAR = providerRewardRateTimeline.nextChange[next];
            }
            if (next == nextDC) {
                psc = providerStates[account].providerStateTimeline[next];
                if (psc.delegationsIncrease != 0) {
                    totalDelegations += psc.delegationsIncrease;
                }
                if (psc.delegationsDecrease != 0) {
                    if (totalDelegations > psc.delegationsDecrease) {
                        totalDelegations -= psc.delegationsDecrease;
                    } else totalDelegations = 0;
                }

                latestTotalDelegationEpoch = nextDC;
                nextDC = providerState.providerStateTimeline[next].nextChangeDelegations;
            }
            prev = next;
            next = findSmallestNonZero(nextAR, nextDC);
            if (next == 0 || next >= currentEpoch) {
                next = currentEpoch;
            }
        }

        reward /= minorTokenUnitsInMajor * yieldPeriod;

        providerState.latestTotalDelegation = totalDelegations;
        providerState.latestTotalDelegationEpoch = latestTotalDelegationEpoch;
    }

    /// @notice Calculate the total accumulated reward available to `account`
    function estimateYield(address account) public view returns (uint128 reward) {
        DelegationState storage userState = delegatorStates[account];
        uint16 processedEpoch = userState.claimedEpoch;
        uint16 currentEpoch = getCurrentEpoch();

        if (currentEpoch - 1 <= processedEpoch) {
            return 0;
        }

        (uint128 activeRate, uint16 nextAR) = getActiveYieldRate(processedEpoch + 1);
        (DelegationChange memory activeDelegation, uint16 nextAD) = getActiveDelegation(account, processedEpoch + 1);
        (bool whitelisted, uint16 nextWL) = getWhitelisted(activeDelegation.delegatedTo, processedEpoch + 1);

        ProviderState storage providerState = providerStates[activeDelegation.delegatedTo];

        nextAR = delegatorYieldTimeline.nextChange[nextAR];
        nextAD = userState.delegationTimeline[nextAD].nextChange;
        nextWL = providerState.providerStateTimeline[nextWL].nextChangeWhitelist;

        uint16 prev = processedEpoch + 1;
        uint16 next = findSmallestNonZero(nextAR, nextAD, nextWL);
        if (next == 0 || next >= currentEpoch) {
            next = currentEpoch;
        }

        while (true) {
            if (whitelisted) {
                reward += uint128((activeRate) * activeDelegation.balance * epochLength) * (next - prev);

                if (providerState.additionalRewards.length > 0) {
                    for (uint i = providerState.additionalRewards.length - 1; i >= 0; i--) {
                        if (providerState.additionalRewards[i].epoch < prev) break;
                        if (
                            providerState.additionalRewards[i].epoch < next &&
                            providerState.additionalRewards[i].additionalRewardPerYieldPeriodPerToken > 0
                        ) {
                            reward += uint128(
                                (providerState.additionalRewards[i].additionalRewardPerYieldPeriodPerToken) * activeDelegation.balance * epochLength
                            );
                        }

                        if (i == 0) break;
                    }
                }
            }

            if (next == currentEpoch) break;

            if (next == nextAR) {
                activeRate = delegatorYieldTimeline.timeline[next];
                nextAR = delegatorYieldTimeline.nextChange[next];
            }
            if (next == nextAD) {
                DelegationChange memory oldDelegation = activeDelegation;
                activeDelegation = userState.delegationTimeline[next];
                if (oldDelegation.delegatedTo != activeDelegation.delegatedTo) {
                    providerState = providerStates[activeDelegation.delegatedTo];

                    (whitelisted, nextWL) = getWhitelisted(activeDelegation.delegatedTo, next);

                    nextWL = providerState.providerStateTimeline[nextWL].nextChangeWhitelist;
                }
                nextAD = userState.delegationTimeline[next].nextChange;
            }
            if (next == nextWL) {
                ProviderStateChange storage psc = providerState.providerStateTimeline[next];
                if (psc.lostWhitelist) {
                    whitelisted = false;
                } else if (psc.gainedWhitelist) {
                    whitelisted = true;
                }
                nextWL = providerState.providerStateTimeline[next].nextChangeWhitelist;
            }

            prev = next;
            next = findSmallestNonZero(nextAR, nextAD, nextWL);
            if (next == 0 || next >= currentEpoch) {
                next = currentEpoch;
            }
        }

        reward /= (minorTokenUnitsInMajor * yieldPeriod);
    }

    /// @notice Claims the rewards (which should be per `estimateYield(account)`) for `account`
    function claimYield(address account) external nonReentrant {
        require(delegatorStates[account].latestChangeEpoch > 0, FIRST_DELEGATION_NEEDED_ERROR);
        require(isStakeValid(account), TIMELINE_MISMATCH_ERROR);
        uint128 reward = estimateYield(account);
        require(reward > 0, ZERO_REWARD_ERROR);
        delegatorStates[account].claimedEpoch = getCurrentEpoch() - 1;
        token.safeTransferFrom(bank, account, reward);
        emit ClaimedYield(account, reward);
    }

    /// @notice Claims additional token rewards for the calling provider
    function claimProviderDelegationReward(address account) external nonReentrant {
        _claimProviderDelegationReward(account);
    }

    function _claimProviderDelegationReward(address account) internal {
        uint128 reward = _updateProviderDelegationRewardEstimate(account);
        providerStates[account].claimedEpochReward = getCurrentEpoch() - 1;
        token.safeTransferFrom(bank, account, reward);

        emit ProviderClaimedTotalDelegationYield(account, reward);
    }

    /**
     *
     * HELPERS
     *
     */

    function getCurrentEpoch() public view returns (uint16) {
        return getEpoch(block.timestamp);
    }

    function getEpoch(uint time) public view returns (uint16) {
        require(time > startTime, MUST_AFTER_START_ERROR);
        return uint16((time - startTime) / epochLength);
    }

    function ensureSyncronisedDelegationState(DelegationState storage userState, uint128 acc, uint64 since) private view {
        uint32 sinceYieldPeriods = uint32(since / yieldPeriod);
        require((userState.balanceAtProcessed * (sinceYieldPeriods - userState.processedDate)) + userState.processed <= acc, INVALID_WITHDRAW_ERROR);
    }

    function findSmallestNonZero(uint16 a, uint16 b, uint16 c) private pure returns (uint16 smallestNonZero) {
        if (a == 0 && b == 0 && c == 0) {
            return 0;
        }

        smallestNonZero = type(uint16).max;

        if (a != 0 && a < smallestNonZero) {
            smallestNonZero = a;
        }
        if (b != 0 && b < smallestNonZero) {
            smallestNonZero = b;
        }
        if (c != 0 && c < smallestNonZero) {
            smallestNonZero = c;
        }
    }

    function findSmallestNonZero(uint16 a, uint16 b) private pure returns (uint16 smallestNonZero) {
        if (a == 0 && b == 0) {
            return 0;
        }

        smallestNonZero = type(uint16).max;

        if (a != 0 && a < smallestNonZero) {
            smallestNonZero = a;
        }
        if (b != 0 && b < smallestNonZero) {
            smallestNonZero = b;
        }
    }

    /**
     *
     * ADMIN
     *
     */

    /// @notice Adds `account` as a valid provider on the whitelist
    function addToWhitelist(address account) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(WHITELIST_ADMIN, msg.sender), UNAUTHORISED_ERROR);
        uint16 currentEpoch = getCurrentEpoch();

        ProviderState storage providerState = providerStates[account];
        providerState.whitelisted = true;
        providerState.providerStateTimeline[currentEpoch].gainedWhitelist = true;
        providerState.latestWhitelistChange = journalProviderWhitelistChange(providerState);

        emit AddedWhitelist(account);
    }

    /// @notice Removes `account` from the provider whitelist, and process an immediate withdrawal if successful
    function removeFromWhitelist(address account) external nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(WHITELIST_ADMIN, msg.sender), UNAUTHORISED_ERROR);
        ProviderState storage providerState = providerStates[account];
        uint16 currentEpoch = getCurrentEpoch();

        _claimProviderDelegationReward(account);

        providerState.latestTotalDelegation = 0;
        // remove from whitelist
        providerState.whitelisted = false;
        providerState.providerStateTimeline[currentEpoch].lostWhitelist = true;
        // Record change
        providerState.latestWhitelistChange = journalProviderWhitelistChange(providerState);
        emit RemovedWhitelist(account);
    }

    /// @notice Grants a lump `amount` award to a provider `account` at epoch `epoch`. Admin only.
    function grantAdditionalReward(address account, uint16 epoch, uint16 amount) external onlyRole(ADDITIONAL_REWARD_ADMIN) {
        require(epoch >= getCurrentEpoch(), "Cannot grant additional rewards retroactively");
        providerStates[account].additionalRewards.push(AdditionalReward(amount, epoch));

        emit GrantedAdditionalReward(account, amount);
    }

    /// @notice Changes the bank address from which rewards are drawn to `newBank`. Admin only.
    function changeBank(address newBank) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bank = newBank;
    }

    /// @notice Sends all CHR tokens to the contract owner. Only admin can call.
    function drain() external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }
}