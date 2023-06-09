// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interface/IGenArtInterfaceV4.sol";
import "../interface/IGenArt.sol";
import "../access/GenArtAccess.sol";

/**
 * @title GenArtValut
 * @notice It handles the distribution of ETH loyalties
 * @notice forked from https://etherscan.io/address/0xbcd7254a1d759efa08ec7c3291b2e85c5dcc12ce#code
 */
contract GenArtLoyaltyVault is ReentrancyGuard, GenArtAccess {
    using SafeERC20 for IERC20;
    struct UserInfo {
        uint256 tokens; // shares of token staked
        uint256[] membershipIds;
        uint256 userRewardPerTokenPaid; // user reward per token paid
        uint256 rewards; // pending rewards
    }

    // Precision factor for calculating rewards and exchange rate
    uint256 public constant PRECISION_FACTOR = 10**18;

    // Reward rate (block)
    uint256 public currentRewardPerBlock;

    // Last update block for rewards
    uint256 public lastUpdateBlock;

    // Current end block for the current reward period
    uint256 public periodEndBlock;

    // Reward per token stored
    uint256 public rewardPerTokenStored;

    // Total existing shares
    uint256 public totalTokenShares;
    uint256 public totalMembershipShares;

    uint256 public minimumTokenAmount = 4_000;
    uint256 public minimumMembershipAmount = 1;

    mapping(address => UserInfo) public userInfo;

    IERC20 public immutable genartToken;
    address public immutable genartMembership;

    mapping(address => uint256) public lockedWithdraw;

    uint256 public weightFactorTokens = 2;
    uint256 public weightFactorMemberships = 1;

    mapping(uint256 => address) public membershipOwners;

    bool public emergencyWithdrawDisabled;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 harvestedAmount);
    event NewRewardPeriod(
        uint256 numberBlocks,
        uint256 rewardPerBlock,
        uint256 reward
    );
    event Withdraw(address indexed user, uint256 amount, uint256[] memberships);

    /**
     * @notice Constructor
     * @param _genartToken address of the token staked (GRNART)
     */
    constructor(address _genartMembership, address _genartToken) {
        genartToken = IERC20(_genartToken);
        genartMembership = _genartMembership;
    }

    modifier requireNotLocked(address user) {
        require(block.timestamp > lockedWithdraw[user], "assets locked");
        _;
    }

    /**
     * @notice Deposit staked tokens (and collect reward tokens if requested)
     * @param amount amount to deposit (in GENART)
     */
    function deposit(uint256[] memory membershipIds, uint256 amount)
        external
        nonReentrant
    {
        address sender = _msgSender();
        _checkDeposit(sender, membershipIds, amount);
        _deposit(sender, membershipIds, amount);
    }

    function harvest() external nonReentrant {
        address sender = _msgSender();
        uint256 pendingRewards = _harvest(sender);
        require(pendingRewards > 0, "zero rewards to harvest");
        // transfer reward token to sender
        payable(sender).transfer(pendingRewards);
    }

    /**
     * @notice Withdraw all staked tokens (and collect reward tokens if requested)
     */
    function withdraw() external requireNotLocked(msg.sender) nonReentrant {
        address sender = _msgSender();
        require(userInfo[sender].tokens > 0, "zero shares");
        _withdraw(sender);
    }

    /**
     * @notice Withdraw staked tokens and memberships
     */
    function withdrawPartial(
        uint256 amount,
        uint256[] memory membershipsToWithdraw
    ) external requireNotLocked(msg.sender) nonReentrant {
        _withdrawPartial(msg.sender, amount, membershipsToWithdraw);
    }

    /**
     * @notice Update the reward per block (in rewardToken)
     * @dev Only callable by owner. Owner is meant to be another smart contract.
     */
    function updateRewards(uint256 rewardDurationInBlocks)
        external
        payable
        onlyAdmin
    {
        // adjust the current reward per block
        if (block.number >= periodEndBlock) {
            currentRewardPerBlock = msg.value / rewardDurationInBlocks;
        } else {
            currentRewardPerBlock =
                (msg.value +
                    ((periodEndBlock - block.number) * currentRewardPerBlock)) /
                rewardDurationInBlocks;
        }

        lastUpdateBlock = block.number;
        periodEndBlock = block.number + rewardDurationInBlocks;

        emit NewRewardPeriod(
            rewardDurationInBlocks,
            currentRewardPerBlock,
            msg.value
        );
    }

    function lockUserWithdraw(address user, uint256 toTimestamp)
        external
        onlyAdmin
    {
        if (lockedWithdraw[user] >= toTimestamp) return;
        lockedWithdraw[user] = toTimestamp;
    }

    function setWeightFactors(
        uint256 newWeightFactorTokens,
        uint256 newWeightFactorMemberships
    ) external onlyAdmin {
        weightFactorTokens = newWeightFactorTokens;
        weightFactorMemberships = newWeightFactorMemberships;
    }

    function setMinTokenAndMembershipAmount(
        uint256 minimumTokenAmount_,
        uint256 minimumMembershipAmount_
    ) external onlyAdmin {
        minimumTokenAmount = minimumTokenAmount_;
        minimumMembershipAmount = minimumMembershipAmount_;
    }

    /**
     * @dev Disable emergency withdraw
     */
    function disableEmergencyWithdraw() public onlyAdmin {
        emergencyWithdrawDisabled = true;
    }

    /**
     * @dev Withdraw funds on contract to owner in case of emergency
     */
    function emergencyWithdraw() public onlyAdmin {
        require(!emergencyWithdrawDisabled, "emergency withdraw disabled");
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * Checks requirements for depositing a stake
     */
    function _checkDeposit(
        address user,
        uint256[] memory membershipIds,
        uint256 amount
    ) internal view {
        // check required amount of tokens
        require(
            amount >=
                (
                    userInfo[user].membershipIds.length == 0
                        ? minimumTokenAmount * PRECISION_FACTOR
                        : 0
                ),
            "not enough tokens"
        );
        if (userInfo[user].membershipIds.length == 0) {
            require(
                membershipIds.length >= minimumMembershipAmount,
                "not enough memberships"
            );
        }
    }

    /**
     * @notice Return share value of a membership based on tier
     */
    function _getMembershipShareValue(uint256 membershipId)
        internal
        view
        returns (uint256)
    {
        // 5 shares per gold membership. 1 share for standard memberships
        return
            (IGenArt(genartMembership).isGoldToken(membershipId) ? 5 : 1) *
            PRECISION_FACTOR;
    }

    function _deposit(
        address user,
        uint256[] memory membershipIds,
        uint256 amount
    ) internal {
        // update reward for user
        _updateReward(user);
        // send memberships to this contract
        for (uint256 i; i < membershipIds.length; i++) {
            IERC721(genartMembership).transferFrom(
                user,
                address(this),
                membershipIds[i]
            );
            // save the membership token Ids
            userInfo[user].membershipIds.push(membershipIds[i]);
            membershipOwners[membershipIds[i]] = user;
            // adjust internal membership shares
            totalMembershipShares += _getMembershipShareValue(membershipIds[i]);
        }

        // transfer GENART tokens to this address
        genartToken.transferFrom(user, address(this), amount);

        // adjust internal token shares
        userInfo[user].tokens += amount;
        totalTokenShares += amount;

        emit Deposit(user, amount);
    }

    /**
     * @notice Update reward for a user account
     * @param _user address of the user
     */
    function _updateReward(address _user) internal {
        if (block.number != lastUpdateBlock) {
            rewardPerTokenStored = _rewardPerShare();
            lastUpdateBlock = _lastRewardBlock();
        }

        userInfo[_user].rewards = _calculatePendingRewards(_user);
        userInfo[_user].userRewardPerTokenPaid = rewardPerTokenStored;
    }

    /**
     * @notice Withdraw staked tokens and memberships and collect rewards
     */
    function _withdraw(address user) internal {
        // harvest rewards
        uint256 pendingRewards = _harvest(user);
        uint256 tokens = userInfo[user].tokens;
        uint256[] memory memberships = userInfo[user].membershipIds;

        // adjust internal token shares
        userInfo[user].tokens = 0;
        totalTokenShares -= tokens;

        // transfer GENART tokens to user
        genartToken.safeTransfer(user, tokens);
        for (uint256 i = memberships.length; i >= 1; i--) {
            // remove membership token id from user info object
            userInfo[user].membershipIds.pop();
            membershipOwners[memberships[i - 1]] = address(0);
            // adjust internal membership shares
            totalMembershipShares -= _getMembershipShareValue(
                memberships[i - 1]
            );
            IERC721(genartMembership).transferFrom(
                address(this),
                user,
                memberships[i - 1]
            );
        }
        // transfer reward token to user
        payable(user).transfer(pendingRewards);
        emit Withdraw(user, tokens, memberships);
    }

    /**
     * @notice Withdraw staked tokens and memberships
     */
    function _withdrawPartial(
        address user,
        uint256 amount,
        uint256[] memory membershipsToWithdraw
    ) internal {
        // harvest rewards
        uint256 pendingRewards = _harvest(user);
        uint256 tokens = userInfo[user].tokens;

        uint256 remainingTokens;
        uint256 remainingMemberships;
        unchecked {
            remainingTokens = tokens - amount;
            remainingMemberships =
                userInfo[user].membershipIds.length -
                membershipsToWithdraw.length;
        }
        require(
            remainingTokens >= minimumTokenAmount,
            "remaining tokens less then minimumTokenAmount"
        );
        require(
            remainingMemberships >= minimumMembershipAmount,
            "remaining memberships less then minimumMembershipAmount"
        );

        // adjust internal token shares
        userInfo[user].tokens = remainingTokens;
        totalTokenShares -= amount;

        // transfer GENART tokens to user
        genartToken.safeTransfer(user, amount);
        for (uint256 i; i < membershipsToWithdraw.length; i++) {
            // remove membership token id from user info object
            uint256 vaultedMembershipIndex = findArrayIndex(
                userInfo[user].membershipIds,
                membershipsToWithdraw[i]
            );
            userInfo[user].membershipIds[vaultedMembershipIndex] = userInfo[
                user
            ].membershipIds[userInfo[user].membershipIds.length - 1];

            userInfo[user].membershipIds.pop();

            membershipOwners[membershipsToWithdraw[i]] = address(0);
            // adjust internal membership shares
            totalMembershipShares -= _getMembershipShareValue(
                membershipsToWithdraw[i]
            );
            IERC721(genartMembership).transferFrom(
                address(this),
                user,
                membershipsToWithdraw[i]
            );
        }
        // transfer reward token to user
        payable(user).transfer(pendingRewards);
        emit Withdraw(user, tokens, membershipsToWithdraw);
    }

    function findArrayIndex(uint256[] memory array, uint256 value)
        internal
        pure
        returns (uint256 index)
    {
        for (uint256 i; i < array.length; i++) {
            if (array[i] == value) return i;
        }
        revert("value not found in array");
    }

    /**
     * @notice Harvest reward tokens that are pending
     */
    function _harvest(address user) internal returns (uint256) {
        // update reward for user
        _updateReward(user);

        // retrieve pending rewards
        uint256 pendingRewards = userInfo[user].rewards;

        if (pendingRewards == 0) return 0;
        // adjust user rewards and transfer
        userInfo[user].rewards = 0;

        emit Harvest(user, pendingRewards);

        return pendingRewards;
    }

    /**
     * @notice Return last block where rewards must be distributed
     */
    function _lastRewardBlock() internal view returns (uint256) {
        return block.number < periodEndBlock ? block.number : periodEndBlock;
    }

    /**
     * @notice Return reward per share
     */
    function _rewardPerShare() internal view returns (uint256) {
        if (totalTokenShares == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((_lastRewardBlock() - lastUpdateBlock) * (currentRewardPerBlock));
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user address of the user
     */
    function _calculatePendingRewards(address user)
        internal
        view
        returns (uint256)
    {
        return
            (((getUserShares(user)) *
                (_rewardPerShare() - (userInfo[user].userRewardPerTokenPaid))) /
                PRECISION_FACTOR) + userInfo[user].rewards;
    }

    /**
     * @notice Calculate pending rewards (WETH) for a user
     * @param user address of the user
     */
    function calculatePendingRewards(address user)
        external
        view
        returns (uint256)
    {
        return _calculatePendingRewards(user);
    }

    /**
     * @notice Return last block where trading rewards were distributed
     */
    function lastRewardBlock() external view returns (uint256) {
        return _lastRewardBlock();
    }

    /**
     * @notice Return rewards per share
     */
    function rewardPerShare() external view returns (uint256) {
        return _rewardPerShare();
    }

    /**
     * @notice Return weighted shares of user
     */
    function getUserShares(address user) public view returns (uint256) {
        uint256 userMembershipShares;
        for (uint256 i = 0; i < userInfo[user].membershipIds.length; i++) {
            userMembershipShares += _getMembershipShareValue(
                userInfo[user].membershipIds[i]
            );
        }
        unchecked {
            uint256 tokenShares = totalTokenShares == 0
                ? 0
                : (weightFactorTokens *
                    userInfo[user].tokens *
                    PRECISION_FACTOR) / totalTokenShares;

            uint256 membershipShares = totalMembershipShares == 0
                ? 0
                : (weightFactorMemberships *
                    userMembershipShares *
                    PRECISION_FACTOR) / totalMembershipShares;
            return
                (tokenShares + membershipShares) /
                (weightFactorMemberships + weightFactorTokens);
        }
    }

    function getStake(address user)
        external
        view
        returns (
            uint256,
            uint256[] memory,
            uint256,
            uint256
        )
    {
        return (
            userInfo[user].tokens,
            userInfo[user].membershipIds,
            totalTokenShares == 0 ? 0 : getUserShares(user),
            _calculatePendingRewards(user)
        );
    }

    function getMembershipsOf(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userInfo[user].membershipIds;
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }
}