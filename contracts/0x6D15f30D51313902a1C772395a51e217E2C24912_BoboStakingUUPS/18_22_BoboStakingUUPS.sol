// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/IERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/*
    ██████╗░░░██╗██╗███████╗░░░░░░░█████╗░░█████╗░███╗░░░███╗██╗░█████╗░░██████╗
    ╚════██╗░██╔╝██║╚════██║░░░░░░██╔══██╗██╔══██╗████╗░████║██║██╔══██╗██╔════╝
    ░░███╔═╝██╔╝░██║░░░░██╔╝█████╗██║░░╚═╝██║░░██║██╔████╔██║██║██║░░╚═╝╚█████╗░
    ██╔══╝░░███████║░░░██╔╝░╚════╝██║░░██╗██║░░██║██║╚██╔╝██║██║██║░░██╗░╚═══██╗
    ███████╗╚════██║░░██╔╝░░░░░░░░╚█████╔╝╚█████╔╝██║░╚═╝░██║██║╚█████╔╝██████╔╝
    ╚══════╝░░░░░╚═╝░░╚═╝░░░░░░░░░░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═╝░╚════╝░╚═════╝░
*/

error BoboStaking__ContractNotSet();
error BoboStaking__TokenContractNotSet();
error BoboStaking__NotEnabled();
error BoboStaking__NoTokensStaked();
error BoboStaking__NotEligible();
error BoboStaking__NotEnoughRewardPool();
error BoboStaking__AlreadyClaimed();
error BoboStaking__NumMustBeGreaterThanZero();
error BoboStaking__InvalidBoboAddress();
error BoboStaking__InvalidGenesisAddress();
error BoboStaking__InvalidStudioBadgeAddress();

contract BoboStakingUUPS is
  Initializable,
  OwnableUpgradeable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable
{
  using SafeERC20 for IERC20;

  /////////////////////
  // State Variables //
  /////////////////////

  uint96 private constant BOBOS_PER_GENESIS_REWARD = 5;
  address private constant BURN_ADDRESS =
    0x000000000000000000000000000000000000dEaD;
  uint256 private constant SECONDS_PER_DAY = 86400;

  uint256 private s_rewardsPerDay;
  uint256 private s_rewardEndTimestamp;
  uint256 private s_studioBadgeMultiplier;
  uint256 private s_burnRewardMultiplier;
  uint256 private s_counter;

  IERC721A private s_boboContract;
  IERC721A private s_studioBadgeContract;
  IERC721AQueryable private s_genesisContract;
  IERC20 private s_tokenContract;

  bool private s_isStakeEnabled;
  bool private s_isUnstakeEnabled;
  bool private s_isGenesisClaimEnabled;
  bool private s_isTokenClaimEnabled;
  bool private s_genesisClaimEligible;

  struct StakerInfo {
    uint96 numGenesisEligible;
    uint96 numGenesisClaimed;
    uint32 lastStaked; // timestamp
    uint32 unstakedAt; // timestamp
    bool hasStudioBadge;
    bool burned;
    uint256 claimedTokenAmount;
    uint256[] stakedTokenIds;
  }

  struct TokenInfo {
    uint128 stakedAt;
    uint128 unstakedAt;
    bool burned;
  }

  struct Snapshot {
    address staker;
    uint16[] stakedTokenIds;
    uint16 bobosStaked;
    uint16 numGenesisEligible;
    uint8 numGenesisClaimed;
    bool hasStudioBadge;
    uint256 claimedTokenAmount;
  }

  address[] private s_stakersList;
  mapping(address => StakerInfo) private s_stakerToStakerInfo;
  mapping(uint256 => TokenInfo) private s_tokenIdToTokenInfo;
  mapping(uint256 => address) private s_badgeIdToClaimer;

  /////////////////////
  // Events          //
  /////////////////////

  event Staked(address indexed staker, uint256[] tokenIds, uint256 stakedAt);
  event Unstaked(address indexed staker, uint256 unstakedAt);
  event ClaimedGenesis(address indexed staker, uint256 numClaimed);
  event ClaimedTokens(address indexed staker, uint256 amount);
  event ClaimedTokensAndBurned(address indexed staker, uint256 amountClaimed);
  event StudioBadgeMultiplierUpdated(uint256 multiplier);
  event BurnMultiplierUpdated(uint256 multiplier);
  event RewardsPerDayUpdated(uint256 rewardsPerDay);
  event RewardEndTimestampUpdated(uint256 timestamp);

  ////////////////////
  // Main Functions //
  ////////////////////

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address boboAddress,
    address genesisAddress,
    address studioBadgeAddress
  ) public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    __ReentrancyGuard_init();

    if (
      boboAddress == address(0) ||
      genesisAddress == address(0) ||
      studioBadgeAddress == address(0)
    ) {
      revert BoboStaking__ContractNotSet();
    }
    s_boboContract = IERC721A(boboAddress);
    s_genesisContract = IERC721AQueryable(genesisAddress);
    s_studioBadgeContract = IERC721A(studioBadgeAddress);

    IERC165 boboERC165 = IERC165(boboAddress);
    IERC165 genesisERC165 = IERC165(genesisAddress);
    IERC165 studioBadgeERC165 = IERC165(studioBadgeAddress);

    bytes4 erc721InterfaceId = 0x80ac58cd; // ERC-721 interface ID

    if (!boboERC165.supportsInterface(erc721InterfaceId)) {
      revert BoboStaking__InvalidBoboAddress();
    }
    if (!genesisERC165.supportsInterface(erc721InterfaceId)) {
      revert BoboStaking__InvalidGenesisAddress();
    }
    if (!studioBadgeERC165.supportsInterface(erc721InterfaceId)) {
      revert BoboStaking__InvalidStudioBadgeAddress();
    }

    s_rewardsPerDay = 0;
    s_rewardEndTimestamp = 0;
    s_studioBadgeMultiplier = 0;
    s_burnRewardMultiplier = 0;
    s_counter = 1;

    s_isStakeEnabled = false;
    s_isUnstakeEnabled = false;
    s_isGenesisClaimEnabled = false;
    s_isTokenClaimEnabled = false;
    s_genesisClaimEligible = true;
  }

  ///////////////////////
  // Staking Functions //
  ///////////////////////

  /**
   * @notice Function used to stake BiPlane Bobos.
   * @param tokenIds - The array of Token Ids to stake.
   * @dev Each Token Id must be approved for transfer by the user.
   * @dev toggleStaking() must be on.
   */
  function stake(uint256[] calldata tokenIds) external {
    if (!s_isStakeEnabled) revert BoboStaking__NotEnabled();
    uint128 timestamp = uint128(block.timestamp);
    StakerInfo storage stakerInfo = s_stakerToStakerInfo[msg.sender];
    if (stakerInfo.stakedTokenIds.length == 0) {
      s_stakersList.push(msg.sender);
    }
    if (s_studioBadgeContract.balanceOf(msg.sender) > 0) {
      stakerInfo.hasStudioBadge = true;
    }
    if (s_genesisClaimEligible) {
      stakerInfo.numGenesisEligible += uint96(tokenIds.length);
    }
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      s_boboContract.safeTransferFrom(msg.sender, address(this), tokenId);
      stakerInfo.stakedTokenIds.push(tokenId);
      s_tokenIdToTokenInfo[tokenId].stakedAt = timestamp;
    }
    stakerInfo.lastStaked = uint32(timestamp);
    emit Staked(msg.sender, tokenIds, timestamp);
  }

  /**
   * @notice Function used to unstake BiPlane Bobos.
   * @dev toggleUnstaking() must be on.
   */
  function unstake() external nonReentrant {
    if (!s_isUnstakeEnabled) revert BoboStaking__NotEnabled();
    StakerInfo storage stakerInfo = s_stakerToStakerInfo[msg.sender];
    uint256[] memory tokenIds = stakerInfo.stakedTokenIds;
    if (tokenIds.length == 0) revert BoboStaking__NoTokensStaked();
    uint128 timestamp = uint128(block.timestamp);

    for (uint256 i = 0; i < tokenIds.length; i++) {
      s_boboContract.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
      s_tokenIdToTokenInfo[tokenIds[i]].unstakedAt = timestamp;
    }

    stakerInfo.stakedTokenIds = new uint256[](0);
    stakerInfo.numGenesisEligible = 0;
    stakerInfo.unstakedAt = uint32(timestamp);
    emit Unstaked(msg.sender, timestamp);
  }

  /**
   * @notice batch unstake BiPlane Bobos to avoid gas limit.
   * @param numToUnstake - The number of tokens to unstake.
   * @dev toggleUnstaking() must be on.
   */
  function batchUnstake(uint256 numToUnstake) external nonReentrant {
    if (!s_isUnstakeEnabled) revert BoboStaking__NotEnabled();
    if (numToUnstake == 0) revert BoboStaking__NumMustBeGreaterThanZero();
    StakerInfo storage stakerInfo = s_stakerToStakerInfo[msg.sender];
    uint256[] storage tokenIds = stakerInfo.stakedTokenIds;
    if (tokenIds.length == 0 || numToUnstake > tokenIds.length) {
      revert BoboStaking__NoTokensStaked();
    }

    uint128 timestamp = uint128(block.timestamp);

    for (uint256 i = 0; i < numToUnstake; i++) {
      uint256 index = tokenIds.length - 1;
      s_tokenIdToTokenInfo[tokenIds[index]].unstakedAt = timestamp;
      s_boboContract.safeTransferFrom(
        address(this),
        msg.sender,
        tokenIds[index]
      );
      tokenIds.pop();
    }
    stakerInfo.numGenesisEligible = 0;
    stakerInfo.unstakedAt = uint32(timestamp);
    emit Unstaked(msg.sender, timestamp);
  }

  /**
   * @notice Function used to claim one genesis reward for every 5
   * eligible staked BiPlane Bobos.
   * @notice Only one claim per staker.
   * @dev toggleGenesisClaiming() must be on.
   * @dev once toggleGenesisClaimEligibility() is toggled off, any
   * staked BiPlane Bobos will not be eligible for genesis rewards.
   */
  function claimGenesis() external nonReentrant {
    if (!s_isGenesisClaimEnabled) revert BoboStaking__NotEnabled();
    if (
      s_stakerToStakerInfo[msg.sender].numGenesisEligible <
      BOBOS_PER_GENESIS_REWARD ||
      s_stakerToStakerInfo[msg.sender].numGenesisClaimed > 0
    ) {
      revert BoboStaking__NotEligible();
    }
    uint96 genesisClaims = s_stakerToStakerInfo[msg.sender].numGenesisEligible /
      BOBOS_PER_GENESIS_REWARD;
    uint256[] memory rewardPool = s_genesisContract.tokensOfOwner(
      address(this)
    );
    if (rewardPool.length < genesisClaims) {
      revert BoboStaking__NotEnoughRewardPool();
    }
    s_stakerToStakerInfo[msg.sender].numGenesisClaimed = genesisClaims;

    uint8 counter = 0;
    while (counter < genesisClaims) {
      uint256 rand = getRandomNumber() % (rewardPool.length);
      if (s_genesisContract.ownerOf(rewardPool[rand]) != address(this)) {
        continue;
      }
      s_genesisContract.safeTransferFrom(
        address(this),
        msg.sender,
        rewardPool[rand]
      );
      counter++;
    }

    s_stakerToStakerInfo[msg.sender].numGenesisEligible = 0;
    emit ClaimedGenesis(msg.sender, genesisClaims);
  }

  /**
   * @notice gets pseudo-random number.
   * While pseudo-random numbers are generally not secure, this
   * function is only used to vary the reward pool distribution so
   * they aren't sequential.
   */
  function getRandomNumber() private returns (uint256) {
    s_counter++;
    return
      uint256(
        keccak256(
          abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            s_stakerToStakerInfo[msg.sender].stakedTokenIds.length,
            s_stakersList.length,
            s_stakerToStakerInfo[msg.sender].numGenesisEligible,
            s_counter
          )
        )
      );
  }

  /**
   * @notice Claim token rewards for staked BiPlane Bobos.
   * @dev toggleTokenClaiming() must be on.
   */
  function claimTokenRewards(uint256 studioBadgeTokenId) external nonReentrant {
    if (!s_isTokenClaimEnabled) revert BoboStaking__NotEnabled();
    StakerInfo storage stakerInfo = s_stakerToStakerInfo[msg.sender];
    uint256[] memory tokenIds = stakerInfo.stakedTokenIds;
    if (tokenIds.length == 0) revert BoboStaking__NoTokensStaked();
    if (
      stakerInfo.claimedTokenAmount > 0 ||
      s_badgeIdToClaimer[studioBadgeTokenId] != address(0)
    ) revert BoboStaking__AlreadyClaimed();

    uint256 totalRewards;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 reward = calculateReward(tokenIds[i], msg.sender);
      totalRewards += reward;
    }
    if (hasValidStudioBadge(msg.sender, studioBadgeTokenId)) {
      totalRewards = (totalRewards * s_studioBadgeMultiplier) / 100;
      s_badgeIdToClaimer[studioBadgeTokenId] = msg.sender;
    }
    stakerInfo.claimedTokenAmount = totalRewards;
    s_tokenContract.safeTransfer(msg.sender, totalRewards);
    emit ClaimedTokens(msg.sender, totalRewards);
  }

  /**
   * @notice claims token rewards and unstakes BiPlane Bobos.
   */
  function claimTokensAndUnstake(
    uint256 studioBadgeTokenId
  ) external nonReentrant {
    if (!s_isTokenClaimEnabled || !s_isUnstakeEnabled)
      revert BoboStaking__NotEnabled();
    StakerInfo storage stakerInfo = s_stakerToStakerInfo[msg.sender];
    uint256[] memory tokenIds = stakerInfo.stakedTokenIds;
    if (tokenIds.length == 0) revert BoboStaking__NoTokensStaked();
    if (
      stakerInfo.claimedTokenAmount > 0 ||
      s_badgeIdToClaimer[studioBadgeTokenId] != address(0)
    ) revert BoboStaking__AlreadyClaimed();
    uint256 totalRewards;
    uint128 timestamp = uint128(block.timestamp);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 reward = calculateReward(tokenIds[i], msg.sender);
      totalRewards += reward;
      s_tokenIdToTokenInfo[tokenIds[i]].unstakedAt = timestamp;
      s_boboContract.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
    }
    if (hasValidStudioBadge(msg.sender, studioBadgeTokenId)) {
      totalRewards = (totalRewards * s_studioBadgeMultiplier) / 100;
      s_badgeIdToClaimer[studioBadgeTokenId] = msg.sender;
    }
    stakerInfo.claimedTokenAmount = totalRewards;
    s_tokenContract.safeTransfer(msg.sender, totalRewards);

    stakerInfo.stakedTokenIds = new uint256[](0);
    stakerInfo.numGenesisEligible = 0;
    stakerInfo.unstakedAt = uint32(timestamp);
    emit Unstaked(msg.sender, timestamp);
    emit ClaimedTokens(msg.sender, totalRewards);
  }

  /**
   * @notice claims token rewards and burns staked BiPlane Bobos.
   */
  function claimTokensAndBurn(
    uint256 studioBadgeTokenId
  ) external nonReentrant {
    if (!s_isTokenClaimEnabled) revert BoboStaking__NotEnabled();
    if (s_burnRewardMultiplier == 0) {
      revert BoboStaking__ContractNotSet();
    }
    StakerInfo storage stakerInfo = s_stakerToStakerInfo[msg.sender];
    uint256[] memory tokenIds = stakerInfo.stakedTokenIds;
    if (tokenIds.length == 0) revert BoboStaking__NoTokensStaked();
    if (
      stakerInfo.claimedTokenAmount > 0 ||
      s_badgeIdToClaimer[studioBadgeTokenId] != address(0)
    ) revert BoboStaking__AlreadyClaimed();
    uint256 totalRewards;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 reward = calculateReward(tokenIds[i], msg.sender);
      totalRewards += reward;
      s_tokenIdToTokenInfo[tokenIds[i]].burned = true;
      s_boboContract.transferFrom(address(this), BURN_ADDRESS, tokenIds[i]);
    }
    if (hasValidStudioBadge(msg.sender, studioBadgeTokenId)) {
      totalRewards = (totalRewards * s_studioBadgeMultiplier) / 100;
      s_badgeIdToClaimer[studioBadgeTokenId] = msg.sender;
    }
    totalRewards = (totalRewards * s_burnRewardMultiplier) / 100;
    stakerInfo.claimedTokenAmount = totalRewards;
    s_tokenContract.safeTransfer(msg.sender, totalRewards);

    stakerInfo.stakedTokenIds = new uint256[](0);
    stakerInfo.numGenesisEligible = 0;
    stakerInfo.burned = true;
    emit ClaimedTokensAndBurned(msg.sender, totalRewards);
  }

  /**
   * @notice Calculates token rewards for a staked BiPlane Bobo.
   * @param tokenId The tokenId of the staked BiPlane Bobo.
   * @return reward The amount of token rewards for that tokenId.
   */
  function calculateReward(
    uint256 tokenId,
    address staker
  ) internal view returns (uint256 reward) {
    if (
      s_stakerToStakerInfo[staker].claimedTokenAmount > 0 ||
      s_tokenIdToTokenInfo[tokenId].stakedAt == 0 ||
      s_rewardEndTimestamp == 0
    ) {
      return 0;
    }
    reward =
      ((s_rewardEndTimestamp - s_tokenIdToTokenInfo[tokenId].stakedAt) *
        s_rewardsPerDay) /
      SECONDS_PER_DAY;
  }

  /**
   * @notice Checks if a staker had a studio badge when they staked
   * and makes sure the studio badge was not already claimed and that
   * the studio badge is still owned by the staker.
   * @param staker Address of the staker.
   * @param studioBadgeTokenId Token Id of the studio badge.
   */
  function hasValidStudioBadge(
    address staker,
    uint256 studioBadgeTokenId
  ) internal view returns (bool) {
    if (
      studioBadgeTokenId > 0 &&
      s_stakerToStakerInfo[staker].hasStudioBadge &&
      s_badgeIdToClaimer[studioBadgeTokenId] == address(0) &&
      s_studioBadgeContract.ownerOf(studioBadgeTokenId) == staker
    ) {
      return true;
    } else {
      return false;
    }
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external nonReentrant returns (bytes4) {
    return ERC721A__IERC721Receiver.onERC721Received.selector;
  }

  /////////////////////
  // Admin Functions //
  /////////////////////

  /**
   * @notice upgrades the contract to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyOwner {}

  /**
   * @notice Withdraws the specified number of unclaimed genesis rewards.
   * @param to The address to send the unclaimed rewards to.
   * @param numToWithdraw The number of unclaimed rewards to withdraw.
   * @dev The numToWithdraw param is to avoid gas limit issues.
   */
  function withdrawUnclaimedGenesis(
    address to,
    uint256 numToWithdraw
  ) external onlyOwner {
    uint256[] memory rewardPool = s_genesisContract.tokensOfOwner(
      address(this)
    );
    uint256 arrayLength;
    if (rewardPool.length < numToWithdraw) {
      arrayLength = rewardPool.length;
    } else {
      arrayLength = numToWithdraw;
    }
    for (uint256 i = 0; i < arrayLength; i++) {
      s_genesisContract.safeTransferFrom(address(this), to, rewardPool[i]);
    }
  }

  /**
   * @notice Withdraws unclaimed token rewards.
   * @param to The address to send the unclaimed rewards to.
   */
  function withdrawUnclaimedTokens(address to) external onlyOwner {
    if (address(s_tokenContract) == address(0)) {
      revert BoboStaking__ContractNotSet();
    }
    s_tokenContract.safeTransfer(to, s_tokenContract.balanceOf(address(this)));
  }

  /**
   * @notice Emergency recovery of staked bobos.
   * @param to The address to send the staked bobos back to.
   * @param tokenIds The tokenIds of the user's staked bobos.
   * @dev This function is only to be used in the extremely unlikely event
   * that a staked bobo is stuck in this contract.
   */
  function emergencyWithdrawBobos(
    address to,
    uint256[] calldata tokenIds
  ) external onlyOwner {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      s_boboContract.safeTransferFrom(address(this), to, tokenIds[i]);
    }
  }

  /**
   * @notice Sets the BiPlane Bobo contract used for staking.
   */
  function setBoboContract(address boboAddress) external onlyOwner {
    if (boboAddress == address(0)) revert BoboStaking__ContractNotSet();

    // Check if the provided address supports the ERC721 interface
    IERC165 candidateContract = IERC165(boboAddress);
    if (!candidateContract.supportsInterface(type(IERC721).interfaceId)) {
      revert BoboStaking__InvalidBoboAddress();
    }
    s_boboContract = IERC721A(boboAddress);
  }

  /**
   * @notice Sets the genesis contract used for rewards.
   */
  function setGenesisContract(address genesisAddress) external onlyOwner {
    if (genesisAddress == address(0)) revert BoboStaking__ContractNotSet();

    // Check if the provided address supports the ERC721 interface
    IERC165 candidateContract = IERC165(genesisAddress);
    if (!candidateContract.supportsInterface(type(IERC721).interfaceId)) {
      revert BoboStaking__InvalidGenesisAddress();
    }
    s_genesisContract = IERC721AQueryable(genesisAddress);
  }

  /**
   * @notice Sets the studio badge contract used for a token reward
   * multiplier.
   */
  function setStudioBadgeContract(
    address studioBadgeAddress
  ) external onlyOwner {
    if (studioBadgeAddress == address(0)) revert BoboStaking__ContractNotSet();

    // Check if the provided address supports the ERC721 interface
    IERC165 candidateContract = IERC165(studioBadgeAddress);
    if (!candidateContract.supportsInterface(type(IERC721).interfaceId)) {
      revert BoboStaking__InvalidStudioBadgeAddress();
    }
    s_studioBadgeContract = IERC721A(studioBadgeAddress);
  }

  /**
   * @notice Sets the studio badge multiplier.
   * @dev The multiplier is a percentage, so 100 = 1x, 200 = 2x, etc.
   */
  function setStudioBadgeMultiplier(uint256 multiplier) external onlyOwner {
    s_studioBadgeMultiplier = multiplier;
    emit StudioBadgeMultiplierUpdated(multiplier);
  }

  /**
   * @notice Sets the burn reward multiplier.
   * @dev The multiplier is a percentage, so 100 = 1x, 200 = 2x, etc.
   */
  function setBurnMultiplier(uint256 multiplier) external onlyOwner {
    s_burnRewardMultiplier = multiplier;
    emit BurnMultiplierUpdated(multiplier);
  }

  /**
   * @notice Sets the ERC20 token rewards contract.
   */
  function setTokenContract(address tokenAddress) external onlyOwner {
    if (tokenAddress == address(0)) revert BoboStaking__ContractNotSet();
    s_tokenContract = IERC20(tokenAddress);
  }

  /**
   * @notice Toggle whether or not staking is enabled.
   */
  function toggleStaking() external onlyOwner {
    s_isStakeEnabled = !s_isStakeEnabled;
  }

  /**
   * @notice Toggles whether or not unstaking is enabled.
   */
  function toggleUnstaking() external onlyOwner {
    s_isUnstakeEnabled = !s_isUnstakeEnabled;
  }

  /**
   * @notice Toggles whether or not genesis rewards can be claimed.
   */
  function toggleGenesisClaiming() external onlyOwner {
    s_isGenesisClaimEnabled = !s_isGenesisClaimEnabled;
  }

  /**
   * @notice Toggles whether or not token rewards can be claimed.
   * @dev claiming is not allowed until the token contract, rewards per day,
   * reward end timestamp, and studio badge multiplier are set.
   */
  function toggleTokenClaiming() external onlyOwner {
    if (
      address(s_tokenContract) == address(0) ||
      s_rewardsPerDay == 0 ||
      s_rewardEndTimestamp == 0 ||
      s_studioBadgeMultiplier == 0
    ) {
      revert BoboStaking__ContractNotSet();
    }
    s_isTokenClaimEnabled = !s_isTokenClaimEnabled;
  }

  /**
   * @notice Toggles whether or not staking a bobo will be eligible
   * for genesis rewards.
   * @dev Toggle this off when genesis eligibility ends.
   */
  function toggleGenesisClaimEligibility() external onlyOwner {
    s_genesisClaimEligible = !s_genesisClaimEligible;
  }

  /**
   * @notice Sets the number of ERC-20 rewards per day.
   * @param rewardsPerDay The number of ERC-20 rewards per day.
   */
  function setRewardsPerDay(uint256 rewardsPerDay) external onlyOwner {
    s_rewardsPerDay = rewardsPerDay;
    emit RewardsPerDayUpdated(rewardsPerDay);
  }

  /**
   * @notice Sets the timestamp at which the reward period ends.
   * @param timestamp The timestamp at which the reward period ends.
   * @dev If timestamp is 0, the timestamp will be set to the current time.
   */
  function setRewardEndTimestamp(uint256 timestamp) external onlyOwner {
    if (timestamp == 0) {
      s_rewardEndTimestamp = block.timestamp;
    } else {
      s_rewardEndTimestamp = timestamp;
    }
    emit RewardEndTimestampUpdated(s_rewardEndTimestamp);
  }

  ////////////////////
  // View Functions //
  ////////////////////

  /**
   * @notice Returns the staker info for the specified staker.
   * @param staker address of staker
   * @return stakerInfo StakerInfo struct
   */
  function getStakerInfo(
    address staker
  ) external view returns (StakerInfo memory) {
    return s_stakerToStakerInfo[staker];
  }

  /**
   * @notice Returns the token info for the specified token.
   * @param tokenId token Id of BiPlane Bobo
   * @return tokenInfo TokenInfo struct
   */
  function getTokenInfo(
    uint256 tokenId
  ) external view returns (TokenInfo memory) {
    return s_tokenIdToTokenInfo[tokenId];
  }

  /**
   * @notice Returns the list of stakers.
   * @return stakersList array of staker addresses
   */
  function getStakers() external view returns (address[] memory) {
    return s_stakersList;
  }

  /**
   * @notice Returns a snapshot of staker info.
   * @return snapshot array of info for each staker
   */
  function getSnapshot() external view returns (Snapshot[] memory) {
    Snapshot[] memory snapshot = new Snapshot[](s_stakersList.length);
    for (uint256 i = 0; i < s_stakersList.length; i++) {
      StakerInfo memory info = s_stakerToStakerInfo[s_stakersList[i]];
      uint16[] memory stakedTokenIds = new uint16[](info.stakedTokenIds.length);
      for (uint256 j = 0; j < info.stakedTokenIds.length; j++) {
        stakedTokenIds[j] = uint16(info.stakedTokenIds[j]);
      }
      snapshot[i] = Snapshot(
        s_stakersList[i],
        stakedTokenIds,
        uint16(info.stakedTokenIds.length),
        uint16(info.numGenesisEligible),
        uint8(info.numGenesisClaimed),
        info.hasStudioBadge,
        info.claimedTokenAmount
      );
    }
    return snapshot;
  }

  /**
   * @notice Returns the staking period (in seconds) of a token.
   * @param tokenId token Id of BiPlane Bobo
   * @return total total time staked in seconds
   */
  function getStakingPeriod(
    uint256 tokenId
  ) external view returns (uint256 total) {
    if (s_tokenIdToTokenInfo[tokenId].stakedAt == 0) {
      return 0;
    }
    uint256 timestamp = block.timestamp;
    if (s_rewardEndTimestamp > 0) {
      timestamp = s_rewardEndTimestamp;
    }
    return timestamp - s_tokenIdToTokenInfo[tokenId].stakedAt;
  }

  /**
   * @notice gets the amount of token rewards for a staked Bobo.
   * @param tokenId token Id of BiPlane Bobo
   * @param badgeId token Id of Studio Badge or 0 if no badge
   * @param staker address of staker
   * @return reward amount of token rewards
   */
  function getTokenReward(
    uint256 tokenId,
    uint256 badgeId,
    address staker
  ) external view returns (uint256 reward) {
    reward = calculateReward(tokenId, staker);
    if (hasValidStudioBadge(staker, badgeId)) {
      reward = (reward * s_studioBadgeMultiplier) / 100;
    }
    return reward;
  }

  /**
   * @notice gets the total unclaimed rewards for a staker.
   * @param staker address of staker
   * @param badgeId token Id of Studio Badge or 0 if no badge
   * @return totalRewards total rewards for staker
   */
  function getTotalTokenRewards(
    address staker,
    uint256 badgeId
  ) external view returns (uint256) {
    StakerInfo memory info = s_stakerToStakerInfo[staker];
    uint256[] memory tokenIds = info.stakedTokenIds;
    uint256 totalRewards = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 reward = calculateReward(tokenIds[i], staker);
      totalRewards += reward;
    }
    if (hasValidStudioBadge(staker, badgeId)) {
      totalRewards = (totalRewards * s_studioBadgeMultiplier) / 100;
    }
    return totalRewards;
  }

  /**
   * @notice returns the number of ERC-20 rewards per day.
   */
  function getRewardsPerDay() external view returns (uint256) {
    return s_rewardsPerDay;
  }

  /**
   * @notice returns the timestamp at which the reward period ends.
   */
  function getRewardEndTimestamp() external view returns (uint256) {
    return s_rewardEndTimestamp;
  }

  /**
   * @notice returns the studio badge multiplier.
   */
  function getStudioBadgeMultiplier() external view returns (uint256) {
    return s_studioBadgeMultiplier;
  }

  /**
   * @notice returns the burn reward multiplier.
   */
  function getBurnRewardMultiplier() external view returns (uint256) {
    return s_burnRewardMultiplier;
  }

  /**
   * @notice returns whether or not staking is enabled.
   */
  function getStakingEnabled() external view returns (bool) {
    return s_isStakeEnabled;
  }

  /**
   * @notice returns whether or not unstaking is enabled.
   */
  function getUnstakingEnabled() external view returns (bool) {
    return s_isUnstakeEnabled;
  }

  /**
   * @notice returns whether or not unstaking is enabled.
   */
  function getGenesisClaimingEnabled() external view returns (bool) {
    return s_isGenesisClaimEnabled;
  }

  /**
   * @notice returns whether or not token reward claiming is enabled.
   */
  function getTokenClaimingEnabled() external view returns (bool) {
    return s_isTokenClaimEnabled;
  }

  /**
   * @notice returns whether or not staking a bobo will be eligible
   * for genesis rewards.
   */
  function getGenesisClaimEligibility() external view returns (bool) {
    return s_genesisClaimEligible;
  }
}