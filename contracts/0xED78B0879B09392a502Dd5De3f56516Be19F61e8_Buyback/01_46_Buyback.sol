// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./interfaces/IBuyback.sol";
import "./interfaces/IMnt.sol";
import "./libraries/PauseControl.sol";
import "./libraries/ErrorCodes.sol";
import "./InterconnectorLeaf.sol";

contract Buyback is IBuyback, Initializable, AccessControl, PauseControl, InterconnectorLeaf {
    using SafeERC20Upgradeable for IMnt;
    using SafeCast for uint256;

    struct ParticipantInfo {
        bool participating; /// Flag that marks account as legally participating in Buyback
        uint32 lastStakeInBlock; /// Block when last stake was made
        uint32 loyaltyStart; /// Start timestamp of the loyalty rewards functionality
        uint256 weight; /// Last calculated buyback weight of the user
        uint256 lastIndex; /// Buyback index from the last buyback claim
        uint256 lastBalance; /// The last account's balance was locked in protocol contracts.
        uint256 coreBalance; /// Minimal amount of MNTs the participant should preserve to save current loyalty factor
    }

    /// @dev Value is the Keccak-256 hash of "GATEKEEPER"
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);
    /// @dev Role that's allowed to initiate buyback
    /// @dev Value is the Keccak-256 hash of "DISTRIBUTOR"
    bytes32 public constant DISTRIBUTOR = bytes32(0x85faced7bde13e1a7dad704b895f006e704f207617d68166b31ba2d79624862d);

    uint256 internal constant INDEX_SCALE = 1e36;
    uint256 internal constant LOYALTY_SCALE = 1e18;
    uint32 internal constant STRATA_NUMBER = 24;
    uint32 internal constant STRATUM_DURATION = (60 * 60 * 24 * 365) / 24; // 1,314,000 seconds (half a month)

    IMnt public mnt;
    ISupervisor public supervisor;
    IRewardsHub public rewardsHub;

    mapping(address => ParticipantInfo) internal participants;

    // Buyback storage

    mapping(address => uint256) internal stakes;
    uint256 internal totalWeight;
    uint256 internal buybackIndex;

    // Loyalty factor storage

    uint256[STRATA_NUMBER] internal loyaltyStrata; /// Array of loyalty factors per stratum
    uint256[] internal loyaltyGroupThresholds; /// MNT tokens required to get into the loyalty group
    uint32[] internal loyaltyGroupStartStrata; /// Array of strata indexes each loyalty group begins with
    uint256 internal loyaltyCoreFactor; /// Portion of balance increase that goes to the core balance
    uint32 internal coreResetPenalty; /// Amount of groups account will lose in case of their core reset

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin_,
        IMnt mnt_,
        ISupervisor supervisor_,
        IRewardsHub rewardsHub_,
        uint256 loyaltyCoreFactor_,
        uint32 coreResetPenalty_,
        uint256[STRATA_NUMBER] memory loyaltyStrata_,
        uint256[] memory loyaltyGroupThresholds_,
        uint32[] memory loyaltyGroupStartStrata_
    ) external initializer {
        supervisor = supervisor_;
        mnt = mnt_;
        rewardsHub = rewardsHub_;

        require(loyaltyCoreFactor_ < LOYALTY_SCALE, ErrorCodes.NUMBER_IS_NOT_IN_SCALE);
        require(
            loyaltyGroupThresholds_.length == loyaltyGroupStartStrata_.length,
            ErrorCodes.INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL
        );
        require(loyaltyGroupStartStrata_[0] == 0, ErrorCodes.BB_STRATUM_OF_FIRST_LOYALTY_GROUP_IS_NOT_ZERO);

        loyaltyCoreFactor = loyaltyCoreFactor_;
        coreResetPenalty = coreResetPenalty_;

        for (uint256 i = 0; i < STRATA_NUMBER; i++) {
            require(loyaltyStrata_[i] < LOYALTY_SCALE, ErrorCodes.NUMBER_IS_NOT_IN_SCALE);
            loyaltyStrata[i] = loyaltyStrata_[i];
        }

        loyaltyGroupThresholds = new uint256[](loyaltyGroupThresholds_.length);
        loyaltyGroupStartStrata = new uint32[](loyaltyGroupThresholds_.length);
        for (uint256 i = 0; i < loyaltyGroupThresholds_.length; i++) {
            require(loyaltyGroupStartStrata_[i] < STRATA_NUMBER);
            loyaltyGroupThresholds[i] = loyaltyGroupThresholds_[i];
            loyaltyGroupStartStrata[i] = loyaltyGroupStartStrata_[i];
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GATEKEEPER, admin_);
        _grantRole(DISTRIBUTOR, admin_);
    }

    /// @inheritdoc IBuyback
    function getMemberInfo(address account)
        external
        view
        returns (
            bool participating,
            uint256 weight,
            uint256 lastIndex,
            uint256 stakeAmount
        )
    {
        return (
            participants[account].participating,
            participants[account].weight,
            participants[account].lastIndex,
            stakes[account]
        );
    }

    /// @inheritdoc IBuyback
    function getLoyaltyInfo(address account)
        external
        view
        returns (
            uint32,
            uint256,
            uint256
        )
    {
        ParticipantInfo memory info = participants[account];
        return (info.loyaltyStart, info.coreBalance, info.lastBalance);
    }

    /// @inheritdoc IBuyback
    function isParticipating(address account) public view returns (bool) {
        return participants[account].participating;
    }

    /// @inheritdoc IBuyback
    function getStakedAmount(address account) external view returns (uint256) {
        return stakes[account];
    }

    /// @inheritdoc IBuyback
    function getWeight(address account) external view returns (uint256) {
        return participants[account].weight;
    }

    /// @inheritdoc IBuyback
    function getTotalWeight() external view returns (uint256) {
        return totalWeight;
    }

    /// @inheritdoc IBuyback
    function getBuybackIndex() external view returns (uint256) {
        return buybackIndex;
    }

    /// @inheritdoc IBuyback
    function getLoyaltyFactorForBalance(address account, uint256 balance) public view returns (uint256) {
        if (balance < loyaltyGroupThresholds[0]) return 0;

        uint32 loyaltyStart = participants[account].loyaltyStart;
        if (loyaltyStart == 0) return 0;

        uint32 deltaTime = getTimestamp() - loyaltyStart;
        if (deltaTime < STRATUM_DURATION) return 0;

        return loyaltyStrata[_findStratumIndex(deltaTime, balance)];
    }

    /// @inheritdoc IBuyback
    function getLoyaltyParameters()
        external
        view
        returns (
            uint256[STRATA_NUMBER] memory,
            uint256[] memory,
            uint32[] memory,
            uint256,
            uint32
        )
    {
        return (loyaltyStrata, loyaltyGroupThresholds, loyaltyGroupStartStrata, loyaltyCoreFactor, coreResetPenalty);
    }

    // // // // Buyback // // // //

    /// @inheritdoc IBuyback
    function stake(uint256 amount) external checkPaused(STAKE_OP) {
        require(whitelist().isWhitelisted(msg.sender), ErrorCodes.WHITELISTED_ONLY);
        require(isParticipating(msg.sender), ErrorCodes.NOT_PARTICIPATING_IN_BUYBACK);
        require(supervisor.isNotBlacklisted(msg.sender), ErrorCodes.ADDRESS_IS_BLACKLISTED);

        ParticipantInfo storage info = participants[msg.sender];

        // Accounts should not receive higher loyalty factors if they are entering new
        // loyalty group via stake after long period of inactivity. In that case their
        // new loyalty factor would be at the start of their new group.
        //
        // To achieve that we should update weights and loyalties before stake, then
        // check condition of entering new group and in that case reset accounts loyaltyStart.
        updateBuybackAndVotingWeights(msg.sender);

        uint256 lastBalance = info.lastBalance;
        uint32 prevGroup = _findGroupByBalance(lastBalance);
        uint32 newGroup = _findGroupByBalance(lastBalance + amount);
        if (newGroup > prevGroup) {
            uint32 newGroupStratum = loyaltyGroupStartStrata[newGroup];
            // May underflow if timestamp is less than a year from Unix epoch %).
            uint32 toGroupStart = getTimestamp() - (newGroupStratum + 1) * STRATUM_DURATION;
            // Use <highest start timestamp> that equals to <lowest delta time>
            // This part actually checks that account has enough delta time for the new group.
            if (toGroupStart > info.loyaltyStart) info.loyaltyStart = toGroupStart;
        }

        stakes[msg.sender] += amount;
        info.lastStakeInBlock = block.number.toUint32();

        emit Stake(msg.sender, amount);

        updateBuybackAndVotingWeightsRelaxed(msg.sender);
        mnt.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @inheritdoc IBuyback
    function unstake(uint256 amount) external checkPaused(UNSTAKE_OP) {
        require(amount > 0, ErrorCodes.INCORRECT_AMOUNT);

        require(block.number > participants[msg.sender].lastStakeInBlock, ErrorCodes.BB_UNSTAKE_TOO_EARLY);

        // Check if the sender is a member of the Buyback system
        bool isSenderParticipating = participants[msg.sender].participating;
        uint256 staked = stakes[msg.sender];

        if (amount == type(uint256).max || amount == staked) {
            amount = staked;
            delete stakes[msg.sender];
        } else {
            require(amount < staked, ErrorCodes.INSUFFICIENT_STAKE);
            stakes[msg.sender] = staked - amount;
        }

        emit Unstake(msg.sender, amount);

        // Update weights of the sender if he participates in the Buyback system
        if (isSenderParticipating) {
            updateBuybackAndVotingWeights(msg.sender);
        }

        mnt.safeTransfer(msg.sender, amount);
    }

    /// @inheritdoc IBuyback
    function buyback(uint256 amount) external onlyRole(DISTRIBUTOR) {
        require(amount > 0, ErrorCodes.NOTHING_TO_DISTRIBUTE);
        require(totalWeight > 0, ErrorCodes.NOT_ENOUGH_PARTICIPATING_ACCOUNTS);
        require(address(rewardsHub) != address(0));

        uint256 shareMantissa = (amount * INDEX_SCALE) / totalWeight;
        buybackIndex += shareMantissa;

        emit NewBuyback(amount, shareMantissa);

        mnt.safeTransferFrom(msg.sender, address(rewardsHub), amount);
    }

    /// @inheritdoc IBuyback
    function participate() external {
        require(supervisor.isNotBlacklisted(msg.sender), ErrorCodes.ADDRESS_IS_BLACKLISTED);
        require(!isParticipating(msg.sender), ErrorCodes.ALREADY_PARTICIPATING_IN_BUYBACK);

        participants[msg.sender].participating = true;
        emit ParticipateBuyback(msg.sender);

        updateBuybackAndVotingWeights(msg.sender);
    }

    /// @inheritdoc IBuyback
    function leave() external {
        _leave(msg.sender);
    }

    /// @inheritdoc IBuyback
    function leaveByAmlDecision(address participant) external {
        require(!supervisor.isNotBlacklisted(participant), ErrorCodes.ADDRESS_IS_NOT_IN_AML_SYSTEM);
        _leave(participant);
    }

    function _leave(address participant) internal checkPaused(LEAVE_OP) {
        require(isParticipating(participant), ErrorCodes.NOT_PARTICIPATING_IN_BUYBACK);

        _claimReward(participant);

        totalWeight -= participants[participant].weight;

        // Deletes all weight and loyalty info
        delete participants[participant];

        // Do not delete stakes here!

        emit LeaveBuyback(participant, stakes[participant]);

        mnt.updateVotingWeight(participant);
    }

    /// @inheritdoc IBuyback
    function updateBuybackAndVotingWeights(address account) public {
        if (!isParticipating(account)) return;
        require(!isOperationPaused(UPDATE_OP, address(0)), ErrorCodes.OPERATION_PAUSED);
        _updateWeights(account);
    }

    /// @inheritdoc IBuyback
    function updateBuybackAndVotingWeightsRelaxed(address account) public {
        if (!isParticipating(account)) return;
        if (isOperationPaused(UPDATE_OP, address(0))) return;
        _updateWeights(account);
    }

    function _updateWeights(address account) internal {
        _claimReward(account);

        ParticipantInfo storage info = participants[account];
        uint256 oldWeight = info.weight;
        // slither-disable-next-line reentrancy-no-eth

        uint256 newBalance = weightAggregator().getAccountFunds(account);
        _updateLoyaltyFactor(account, newBalance);

        uint256 loyaltyFactor = getLoyaltyFactorForBalance(account, newBalance);
        uint256 newWeight = newBalance + (newBalance * loyaltyFactor) / LOYALTY_SCALE;

        if (newWeight != oldWeight) {
            uint256 newTotal = totalWeight + newWeight - oldWeight;
            info.weight = newWeight;
            totalWeight = newTotal;
            emit BuybackWeightChanged(account, newWeight, oldWeight, newTotal);
        }

        mnt.updateVotingWeight(account);
    }

    function _claimReward(address account) internal {
        ParticipantInfo storage info = participants[account];

        uint256 currentBuybackIndex = buybackIndex;
        uint256 accountIndex = info.lastIndex;
        if (accountIndex >= currentBuybackIndex) return;

        info.lastIndex = currentBuybackIndex; // We should update buyback index even if weight is zero

        uint256 deltaIndex = currentBuybackIndex - accountIndex;
        uint256 rewardMnt = (info.weight * deltaIndex) / INDEX_SCALE;

        // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
        rewardsHub.accrueBuybackReward(account, rewardMnt);
    }

    // // // // Loyalty factor // // // //

    function _updateLoyaltyFactor(address account, uint256 newBalance) internal {
        ParticipantInfo storage info = participants[account];

        uint256 lastBalance = info.lastBalance;
        if (newBalance == lastBalance) return;

        uint256 baseThreshold = loyaltyGroupThresholds[0];
        if (newBalance < baseThreshold) {
            if (lastBalance >= baseThreshold) _leaveLoyalty(account);
            return;
        }

        if (newBalance > lastBalance) _accrueLoyalty(account, lastBalance, newBalance);
        else _withdrawLoyalty(account, newBalance);

        info.lastBalance = newBalance;
    }

    function _accrueLoyalty(
        address account,
        uint256 lastBalance,
        uint256 newBalance
    ) internal {
        ParticipantInfo storage info = participants[account];

        if (lastBalance == 0) {
            // We update lastBalance only when balance > baseThreshold.
            // This way in the first time it reaches threshold delta
            // would be equal to (newBalance - 0).
            info.loyaltyStart = getTimestamp();
        }

        uint256 deltaBalance = newBalance - lastBalance;
        uint256 coreIncrease = (deltaBalance * loyaltyCoreFactor) / LOYALTY_SCALE;
        info.coreBalance += coreIncrease.toUint224();
    }

    function _withdrawLoyalty(address account, uint256 newBalance) internal {
        ParticipantInfo storage info = participants[account];

        if (newBalance > info.coreBalance) return;

        uint32 rightNow = getTimestamp();
        uint32 deltaTime = rightNow - info.loyaltyStart;
        uint32 newLoyaltyStart = rightNow;

        if (deltaTime >= STRATUM_DURATION) {
            uint32 currentStratum = _findStratumIndex(deltaTime, newBalance);
            uint32 groupAtStratum = _findGroupByStratum(currentStratum);
            uint32 resetToStratum = groupAtStratum >= coreResetPenalty
                ? loyaltyGroupStartStrata[groupAtStratum - coreResetPenalty]
                : 0;

            // Add 1 to stratum to counteract first month (0 stratum is on the 1st month)
            newLoyaltyStart -= (resetToStratum + 1) * STRATUM_DURATION;
        }
        info.loyaltyStart = newLoyaltyStart;

        uint256 newCoreBalance = (newBalance * loyaltyCoreFactor) / LOYALTY_SCALE;
        info.coreBalance = newCoreBalance.toUint224();
    }

    function _leaveLoyalty(address account) internal {
        ParticipantInfo storage info = participants[account];

        // Clear only loyalty related values
        info.loyaltyStart = 0;
        info.lastBalance = 0;
        info.coreBalance = 0;
    }

    /// @dev deltaTime should be >= STRATUM_DURATION
    function _findStratumIndex(uint32 deltaTime, uint256 balance) internal view returns (uint32) {
        // Stratum by time. Skips zero month
        uint32 stratumIndex = deltaTime / STRATUM_DURATION - 1;
        uint32 balanceGroup = _findGroupByBalance(balance);

        // Skip last group because it has no limit
        if (balanceGroup < loyaltyGroupThresholds.length - 1) {
            uint32 nextGroupStratum = loyaltyGroupStartStrata[balanceGroup + 1];
            if (stratumIndex >= nextGroupStratum) stratumIndex = nextGroupStratum - 1;
        }

        // Don't let to overflow if user in the last group for too long
        if (stratumIndex >= STRATA_NUMBER) return STRATA_NUMBER - 1;

        return stratumIndex;
    }

    /// @dev assuming that balance is greater that the base threshold
    function _findGroupByBalance(uint256 balance) internal view returns (uint32) {
        uint32 len = loyaltyGroupThresholds.length.toUint32();
        for (uint32 i = 1; i < len; i++) {
            if (balance < loyaltyGroupThresholds[i]) return i - 1;
        }
        return len - 1;
    }

    function _findGroupByStratum(uint32 stratum) internal view returns (uint32) {
        uint32 len = loyaltyGroupThresholds.length.toUint32();
        for (uint32 i = 1; i < len; i++) {
            if (stratum < loyaltyGroupStartStrata[i]) return i - 1;
        }
        return len - 1;
    }

    // // // // Admin zone // // // //

    /// @inheritdoc IBuyback
    function participateOnBehalf(address[] memory accounts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(buybackIndex == 0, ErrorCodes.BUYBACK_DRIPS_ALREADY_HAPPENED);
        for (uint256 i = 0; i < accounts.length; i++) {
            require(supervisor.isNotBlacklisted(accounts[i]), ErrorCodes.ADDRESS_IS_BLACKLISTED);
            participants[accounts[i]].participating = true;
            emit ParticipateBuyback(accounts[i]);
        }
    }

    /// @inheritdoc IBuyback
    function leaveOnBehalf(address participant) external onlyRole(GATEKEEPER) {
        require(!mnt.isParticipantActive(participant), ErrorCodes.BB_ACCOUNT_RECENTLY_VOTED);

        _leave(participant);
    }

    /// @inheritdoc IBuyback
    function setLoyaltyParameters(uint256 coreFactor_, uint32 coreResetPenalty_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(coreFactor_ < LOYALTY_SCALE, ErrorCodes.NUMBER_IS_NOT_IN_SCALE);
        require(coreResetPenalty_ < STRATA_NUMBER, ErrorCodes.NUMBER_IS_NOT_IN_SCALE);
        loyaltyCoreFactor = coreFactor_;
        coreResetPenalty = coreResetPenalty_;

        emit LoyaltyParametersChanged(coreFactor_, coreResetPenalty_);
    }

    /// @inheritdoc IBuyback
    function setLoyaltyStrata(uint256[STRATA_NUMBER] memory loyaltyStrata_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < STRATA_NUMBER; i++) {
            require(loyaltyStrata_[i] < LOYALTY_SCALE);
            loyaltyStrata[i] = loyaltyStrata_[i];
        }
        emit LoyaltyStrataChanged();
    }

    /// @inheritdoc IBuyback
    function setLoyaltyGroups(uint256[] memory loyaltyGroupThresholds_, uint32[] memory loyaltyGroupStartStrata_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(loyaltyGroupThresholds_.length > 0, ErrorCodes.INPUT_ARRAY_IS_EMPTY);
        require(
            loyaltyGroupThresholds_.length == loyaltyGroupStartStrata_.length,
            ErrorCodes.INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL
        );
        require(loyaltyGroupStartStrata_[0] == 0, ErrorCodes.BB_STRATUM_OF_FIRST_LOYALTY_GROUP_IS_NOT_ZERO);

        loyaltyGroupThresholds = new uint256[](loyaltyGroupThresholds_.length);
        loyaltyGroupStartStrata = new uint32[](loyaltyGroupThresholds_.length);
        for (uint256 i = 0; i < loyaltyGroupThresholds_.length; i++) {
            require(loyaltyGroupStartStrata_[i] < STRATA_NUMBER, ErrorCodes.NUMBER_IS_NOT_IN_SCALE);
            loyaltyGroupThresholds[i] = loyaltyGroupThresholds_[i];
            loyaltyGroupStartStrata[i] = loyaltyGroupStartStrata_[i];
        }

        emit LoyaltyGroupsChanged(loyaltyGroupThresholds_.length);
    }

    // // // // Pause control // // // //

    bytes32 internal constant STAKE_OP = "Stake";
    bytes32 internal constant UNSTAKE_OP = "Unstake";
    bytes32 internal constant UPDATE_OP = "Update";
    bytes32 internal constant LEAVE_OP = "Leave";

    function validatePause(address) internal view override {
        require(hasRole(GATEKEEPER, msg.sender), ErrorCodes.UNAUTHORIZED);
    }

    function validateUnpause(address) internal view override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), ErrorCodes.UNAUTHORIZED);
    }

    // // // // Utils // // // //

    function getTimestamp() internal view virtual returns (uint32) {
        return block.timestamp.toUint32();
    }

    function weightAggregator() internal view returns (IWeightAggregator) {
        return getInterconnector().weightAggregator();
    }

    function whitelist() internal view returns (IWhitelist) {
        return getInterconnector().whitelist();
    }
}