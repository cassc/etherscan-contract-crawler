// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/******************************************************************************\
* Custom implementation of the StakingRewards contract by Synthetix.
*
* https://docs.synthetix.io/contracts/source/contracts/stakingrewards
* https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol
/******************************************************************************/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILandWorks.sol";
import "./interfaces/IDecentralandEstateRegistry.sol";

contract LandWorksDecentralandStaking is ERC721Holder, ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    ILandWorks public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    mapping(uint256 => address) public stakedAssets;

    // metaverseId as per LandWorks protocol
    uint256 public metaverseId;
    address public landRegistry;
    IDecentralandEstateRegistry public estateRegistry;
    mapping(uint256 => uint256) public stakedAssetSizes;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _stakingToken,
        address _rewardsToken,
        uint256 _rewardsDuration,
        uint256 _metaverseId,
        address _landRegistry,
        address _estateRegistry
    ) {
        stakingToken = ILandWorks(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        rewardsDuration = _rewardsDuration;

        metaverseId = _metaverseId;
        landRegistry = _landRegistry;
        estateRegistry = IDecentralandEstateRegistry(_estateRegistry);
    }

    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
                (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return
            ((balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
                    rewards[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    /// @notice Computes the represented amount to be staked, based on the LandWorks NFT
    /// @param tokenId The tokenId of the LandWorks NFT
    function computeAmount(uint256 tokenId) public view returns (uint256) {
        // Get the asset struct from Landworks
        ILandWorks.Asset memory landworksAsset = stakingToken.assetAt(tokenId);
        require(landworksAsset.metaverseId == metaverseId, "Staking: Invalid metaverseId");
        require(landworksAsset.metaverseRegistry == landRegistry
            || landworksAsset.metaverseRegistry == address(estateRegistry),
            "Staking: Invalid metaverseRegistry");

        // If the asset is LAND, amount is 1
        uint256 computedAmount = 1;
        // If the asset is ESTATE, query the number of LAND's that it represents
        if (landworksAsset.metaverseRegistry == address(estateRegistry)) {
            computedAmount = estateRegistry.getEstateSize(
                landworksAsset.metaverseAssetId
            );
        }
        return computedAmount;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Stakes user's LandWorks NFTs
    /// @param tokenIds The tokenIds of the LandWorks NFTs which will be staked
    function stake(uint256[] memory tokenIds) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(tokenIds.length != 0, "Staking: No tokenIds provided");

        uint256 amount;
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            // Transfer user's LandWorks NFTs to the staking contract
            stakingToken.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            // Change the consumer of the LandWorks NFT to be the person who staked it
            stakingToken.changeConsumer(msg.sender, tokenIds[i]);
            // Compute the amount/weight of the tokenId
            uint256 computedAmount = computeAmount(tokenIds[i]);
            // Increment the amount which will be staked
            amount += computedAmount;
            // Save the size, to be used on withdraw
            stakedAssetSizes[tokenIds[i]] = computedAmount;
            // Save who is the staker/depositor of the token
            stakedAssets[tokenIds[i]] = msg.sender;
        }
        _stake(amount);
        emit Staked(msg.sender, amount, tokenIds);
    }

    /// @notice Withdraws staked user's LandWorks NFTs
    /// @param tokenIds The tokenIds of the LandWorks NFT which will be withdrawn
    function withdraw(uint256[] memory tokenIds) public nonReentrant updateReward(msg.sender) {
        require(tokenIds.length != 0, "Staking: No tokenIds provided");

        uint256 amount;
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            // Check if the user who withdraws is the owner
            require(
                stakedAssets[tokenIds[i]] == msg.sender,
                "Staking: Not the staker of the token"
            );
            // Transfer LandWorks NFTs back to the owner
            stakingToken.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            amount += stakedAssetSizes[tokenIds[i]];
            // Cleanup stakedAssetSizes for the current tokenId
            stakedAssetSizes[tokenIds[i]] = 0;
            // Cleanup stakedAssets for the current tokenId
            stakedAssets[tokenIds[i]] = address(0);
        }
        _withdraw(amount);

        emit Withdrawn(msg.sender, amount, tokenIds);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit(uint256[] memory tokenIds) external {
        withdraw(tokenIds);
        getReward();
    }

    function _stake(uint256 _amount) internal {
        totalSupply += _amount;
        balances[msg.sender] += _amount;
    }

    function _withdraw(uint256 _amount) internal {
        totalSupply -= _amount;
        balances[msg.sender] -= _amount;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice Calculates and sets the reward rate
    /// @param reward The amount of the reward which will be distributed during the entire period
    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance / rewardsDuration, "Staking: Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Staking: Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount, uint256[] tokenIds);
    event Withdrawn(address indexed user, uint256 amount, uint256[] tokenIds);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
}