// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/IBuyback.sol";
import "./interfaces/IMnt.sol";
import "./libraries/PauseControl.sol";
import "./libraries/ErrorCodes.sol";
import "./InterconnectorLeaf.sol";

contract Buyback is IBuyback, Initializable, AccessControl, PauseControl, InterconnectorLeaf {
    using SafeERC20Upgradeable for IMnt;

    struct MemberData {
        bool participating; /// Marks account as legally participating in Buyback
        uint256 weight; /// Total weight of accounts' funds
        uint256 lastIndex; /// Buyback index which was claimed last time
    }

    struct AccountStakeData {
        uint256 amount; /// The amount of staked MNT
        uint256 discounted; /// The amount of staked MNT with discount
        uint256 stakedInBlock; /// Block when last stake was made
    }

    /// @dev Value is the Keccak-256 hash of "GATEKEEPER"
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);
    /// @dev Role that's allowed to initiate buyback
    /// @dev Value is the Keccak-256 hash of "DISTRIBUTOR"
    bytes32 public constant DISTRIBUTOR = bytes32(0x85faced7bde13e1a7dad704b895f006e704f207617d68166b31ba2d79624862d);

    uint256 internal constant INDEX_SCALE = 1e36;
    uint256 internal constant CURVE_SCALE = 1e18;

    /// buyback curve approximates discount rate of the e^-kt, k = 0.725, t = days/365 with the polynomial.
    /// polynomial function f(x) = A + (B * x) + (C * x^2) + (D * x^3) + (E * x^4)
    /// e^(-0.725*t) ~ 1 - 0.7120242*x + 0.2339357*x^2 - 0.04053335*x^3 + 0.00294642*x^4, x in range
    /// of 0 .. 4.44 years in seconds, with good precision
    /// e^-kt gives a steady discount rate of approximately 48% per year on the function range
    /// polynomial approximation gives similar results on most of the range and then smoothly reduces it
    /// to the constant value of about 4.75% (FLAT_RATE) starting from the kink point, i.e. when
    /// blockTime >= FLAT_SECONDS, result value equals the FLAT_RATE
    /// kink point (FLAT_SECONDS) calculated as df/dx = 0 for approximation polynomial
    /// A..E are as follows, B and D values are negative in the formula,
    /// subtraction is used in the calculations instead
    /// result formula is f(x) = A + C*x^2 + E*x^4 - B*x - D*x^3
    uint256 internal constant A = 1e18;
    uint256 internal constant B = 0.7120242e18; // negative
    uint256 internal constant C = 0.2339357e18; // positive
    uint256 internal constant D = 0.04053335e18; // negative
    uint256 internal constant E = 0.00294642e18; // positive

    /// @dev Seconds from protocol start when approximation function has minimum value
    ///     ~ 4.44 years of the perfect year, at this point df/dx == 0
    uint256 internal constant FLAT_SECONDS = 140119200;

    /// @dev Flat rate of the discounted MNTs after the kink point, equal to the percentage at FLAT_SECONDS time
    uint256 internal constant FLAT_RATE = 47563813360365998;

    /// @dev Timestamp from which the discount starts
    uint256 internal startTimestamp;

    IMnt public mnt;
    ISupervisor public supervisor;
    IRewardsHub public rewardsHub;

    mapping(address => MemberData) internal members;
    mapping(address => AccountStakeData) internal stakes;

    /// @notice The sum of all members' weights
    uint256 internal totalWeight;
    /// @notice The accumulated buyback share per 1 weight. Scaled by 1e36
    uint256 internal buybackIndex;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        IMnt mnt_,
        ISupervisor supervisor_,
        IRewardsHub rewardsHub_,
        address admin_
    ) external initializer {
        supervisor = supervisor_;
        startTimestamp = getTime();
        mnt = mnt_;
        rewardsHub = rewardsHub_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GATEKEEPER, admin_);
        _grantRole(DISTRIBUTOR, admin_);
    }

    /// @inheritdoc IBuyback
    function discountParameters()
        external
        view
        returns (
            uint256 start,
            uint256 flatSeconds,
            uint256 flatRate
        )
    {
        return (startTimestamp, FLAT_SECONDS, FLAT_RATE);
    }

    /// @inheritdoc IBuyback
    function discountAmount(uint256 amount) public view returns (uint256) {
        uint256 realPassed = getTime() - startTimestamp;
        return (amount * getPolynomialFactor(realPassed)) / CURVE_SCALE;
    }

    /// @inheritdoc IBuyback
    function getPolynomialFactor(uint256 secondsElapsed) public pure returns (uint256) {
        if (secondsElapsed >= FLAT_SECONDS) return FLAT_RATE;

        uint256 x = (CURVE_SCALE * secondsElapsed) / 365 days;
        uint256 x2 = (x * x) / CURVE_SCALE;
        uint256 bX = (B * x) / CURVE_SCALE;
        uint256 cX = (C * x2) / CURVE_SCALE;
        uint256 dX = (((D * x2) / CURVE_SCALE) * x) / CURVE_SCALE;
        uint256 eX = (((E * x2) / CURVE_SCALE) * x2) / CURVE_SCALE;

        return A + cX + eX - bX - dX;
    }

    /// @inheritdoc IBuyback
    function getMemberInfo(address account)
        external
        view
        returns (
            bool participating,
            uint256 weight,
            uint256 lastIndex,
            uint256 rawStake,
            uint256 discountedStake
        )
    {
        return (
            members[account].participating,
            members[account].weight,
            members[account].lastIndex,
            stakes[account].amount,
            stakes[account].discounted
        );
    }

    /// @inheritdoc IBuyback
    function isParticipating(address account) public view returns (bool) {
        return members[account].participating;
    }

    /// @inheritdoc IBuyback
    function getDiscountedStake(address account) external view returns (uint256) {
        return stakes[account].discounted;
    }

    /// @inheritdoc IBuyback
    function getWeight(address account) external view returns (uint256) {
        return members[account].weight;
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
    function stake(uint256 amount) external checkPaused(STAKE_OP) {
        require(whitelist().isWhitelisted(msg.sender), ErrorCodes.WHITELISTED_ONLY);
        require(isParticipating(msg.sender), ErrorCodes.NOT_PARTICIPATING_IN_BUYBACK);
        require(supervisor.isNotBlacklisted(msg.sender), ErrorCodes.ADDRESS_IS_BLACKLISTED);

        uint256 discounted = discountAmount(amount);
        require(discounted > 0, ErrorCodes.INCORRECT_AMOUNT);

        AccountStakeData storage staked = stakes[msg.sender];
        staked.amount += amount;
        staked.discounted += discounted;
        staked.stakedInBlock = block.number;

        emit Stake(msg.sender, amount, discounted);

        updateBuybackAndVotingWeightsRelaxed(msg.sender);
        mnt.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @inheritdoc IBuyback
    function unstake(uint256 amount) external checkPaused(UNSTAKE_OP) {
        require(amount > 0, ErrorCodes.INCORRECT_AMOUNT);

        AccountStakeData storage staked = stakes[msg.sender];

        require(block.number > staked.stakedInBlock, ErrorCodes.BB_UNSTAKE_TOO_EARLY);

        // Check if the sender is a member of the Buyback system
        bool isSenderParticipating = isParticipating(msg.sender);

        if (amount == type(uint256).max || amount == staked.amount) {
            amount = staked.amount;
            delete stakes[msg.sender];
        } else {
            require(amount < staked.amount, ErrorCodes.INSUFFICIENT_STAKE);
            staked.amount -= amount;
            // Recalculate the discount if the sender participates in the Buyback system
            if (isSenderParticipating) {
                uint256 newDiscounted = staked.discounted - discountAmount(amount);
                /// Stake amount can be greater if discount is high leading to small discounted delta
                staked.discounted = Math.min(newDiscounted, staked.amount);
            }
        }

        emit Unstake(msg.sender, amount);

        // Update weights of the sender if he participates in the Buyback system
        if (isSenderParticipating) {
            updateBuybackAndVotingWeights(msg.sender);
        }

        mnt.safeTransfer(msg.sender, amount);
    }

    /// @inheritdoc IBuyback
    function updateBuybackAndVotingWeights(address account) public {
        if (!isParticipating(account)) return;
        require(!isOperationPaused(UPDATE_OP, address(0)), ErrorCodes.OPERATION_PAUSED);
        updateWeights(account);
    }

    /// @inheritdoc IBuyback
    function updateBuybackAndVotingWeightsRelaxed(address account) public {
        if (!isParticipating(account)) return;
        if (isOperationPaused(UPDATE_OP, address(0))) return;
        updateWeights(account);
    }

    function updateWeights(address account) internal {
        MemberData storage member = members[account];
        _claimReward(account, member);

        uint256 oldWeight = member.weight;
        // slither-disable-next-line reentrancy-no-eth
        uint256 newWeight = weightAggregator().getBuybackWeight(account);

        if (newWeight != oldWeight) {
            uint256 newTotal = totalWeight + newWeight - oldWeight;
            member.weight = newWeight;
            totalWeight = newTotal;
            emit BuybackWeightChanged(account, newWeight, oldWeight, newTotal);
        }

        mnt.updateVotingWeight(account);
    }

    function _claimReward(address account, MemberData storage member) internal {
        uint256 currentBuybackIndex = buybackIndex;
        uint256 accountIndex = member.lastIndex;
        if (accountIndex >= currentBuybackIndex) return;

        member.lastIndex = currentBuybackIndex; // We should update buyback index even if weight is zero

        // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
        rewardsHub.accrueBuybackReward(account, currentBuybackIndex, accountIndex, member.weight);
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

        members[msg.sender].participating = true;
        emit ParticipateBuyback(msg.sender);

        AccountStakeData storage staked = stakes[msg.sender];
        if (staked.amount > 0) staked.discounted = discountAmount(staked.amount);

        updateBuybackAndVotingWeightsRelaxed(msg.sender);
    }

    /// @inheritdoc IBuyback
    function participateOnBehalf(address[] memory accounts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(buybackIndex == 0, ErrorCodes.BUYBACK_DRIPS_ALREADY_HAPPENED);
        for (uint256 i = 0; i < accounts.length; i++) {
            require(supervisor.isNotBlacklisted(accounts[i]), ErrorCodes.ADDRESS_IS_BLACKLISTED);
            members[accounts[i]].participating = true;
            emit ParticipateBuyback(accounts[i]);
        }
    }

    /// @inheritdoc IBuyback
    function leave() external {
        _leave(msg.sender);
    }

    /// @inheritdoc IBuyback
    function leaveOnBehalf(address participant) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!mnt.isParticipantActive(participant), ErrorCodes.BB_ACCOUNT_RECENTLY_VOTED);

        _leave(participant);
    }

    /// @inheritdoc IBuyback
    function leaveByAmlDecision(address participant) external {
        require(!supervisor.isNotBlacklisted(participant), ErrorCodes.ADDRESS_IS_NOT_IN_AML_SYSTEM);

        _leave(participant);
    }

    /// @notice Leave buyback participation, set discounted amount for the `_participant` to zero.
    function _leave(address participant) internal checkPaused(LEAVE_OP) {
        require(isParticipating(participant), ErrorCodes.NOT_PARTICIPATING_IN_BUYBACK);

        _claimReward(participant, members[participant]);

        totalWeight -= members[participant].weight;
        delete members[participant];
        stakes[participant].discounted = 0;

        emit LeaveBuyback(participant, stakes[participant].amount);

        mnt.updateVotingWeight(participant);
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

    function getTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function weightAggregator() internal view returns (IWeightAggregator) {
        return getInterconnector().weightAggregator();
    }

    function whitelist() internal view returns (IWhitelist) {
        return getInterconnector().whitelist();
    }
}