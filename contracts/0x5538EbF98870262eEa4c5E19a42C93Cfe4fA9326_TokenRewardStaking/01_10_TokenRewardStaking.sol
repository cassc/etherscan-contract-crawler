// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IMintableERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Staking contract that allows NFT users
 *         to temporarily lock their NFTs to earn
 *         ERC-20 token rewards
 *
 * The NFTs are locked inside this contract for the
 * duration of the staking period while allowing the
 * user to unstake at any time
 *
 * While the NFTs are staked, they are technically
 * owned by this contract and cannot be moved or placed
 * on any marketplace
 *
 * The contract allows users to stake and unstake multiple
 * NFTs efficiently, in one transaction
 *
 * Staking rewards are paid out to users once
 * they unstake their NFTs and are calculated
 * based on a rounded down number of days the NFTs
 * were staken for
 *
 * Some of the rarest NFTs are boosted by the contract
 * owner to receive bigger staking rewards
 *
 * @dev Features a contract owner that is able to change
 *      the daily rewards, the boosted NFT list and the
 *      boosted NFT daily rewards
 */
contract TokenRewardStaking is ERC721Holder, Ownable {
  using EnumerableSet for EnumerableSet.UintSet;

  /**
   * @notice Stores the ERC-20 token that will
   *         be paid out to NFT holders for staking
   */
  IMintableERC20 public immutable erc20;

  /**
   * @notice Stores the ERC-721 token that will
   *         be staken to receive ERC-20 rewards
   */
  IERC721 public immutable erc721;

  /**
   * @notice Amount of tokens earned for each
   *         day (24 hours) the token was staked for
   *
   * @dev Can be changed by contract owner via setDailyRewards()
   */
  uint128 public dailyRewards;

  /**
   * @notice Some NFTs are boosted to receive bigger token
   *         rewards. This multiplier shows how much more
   *         they will receive
   *
   * E.g. dailyRewardBoostMultiplier = 10 means that the boosted
   * NFTs will receive 10 times the dailyRewards
   *
   * @dev Can be changed by contract owner via setDailyRewardBoostMultiplier()
   */
  uint128 public dailyRewardBoostMultiplier;

  /**
   * @notice Boosted NFTs contained in this list
   *         earn bigger daily rewards
   *
   * @dev We use an EnumerableSet to store this data
   *      instead of an array to be able to query in
   *      O(1) complexity
   *
   ** @dev Can be changed by contract owner via setBoostedNftIds()
   */
  EnumerableSet.UintSet private boostedNftIds;

  /**
   * @notice Stores ownership information for staked
   *         NFTs
   */
  mapping(uint256 => address) public ownerOf;

  /**
   * @notice Stores time staking started for staked
   *         NFTs
   */
  mapping(uint256 => uint256) public stakedAt;

  /**
   * @dev Stores the staked tokens of an address
   */
  mapping(address => EnumerableSet.UintSet) private stakedTokens;

  /**
   * @dev Smart contract unique identifier, a random number
   *
   * @dev Should be regenerated each time smart contact source code is changed
   *      and changes smart contract itself is to be redeployed
   *
   * @dev Generated using https://www.random.org/bytes/
   */
	uint256 public constant UID = 0x78ea82e97e97cd54405b116b0209cbaf8bcb22911b5ad1045e81ea6caf7d47fa;

  /**
   * @dev Sets initialization variables which cannot be
   *      changed in the future
   *
   * @param _erc20Address address of erc20 rewards token
   * @param _erc721Address address of erc721 token to be staken for rewards
   * @param _dailyRewards daily amount of tokens to be paid to stakers for every day
   *                       they have staken an NFT
   * @param _boostedNftIds boosted NFTs receive bigger rewards
   * @param _dailyRewardBoostMultiplier multiplier of rewards for boosted NFTs
   */
  constructor(
    address _erc20Address,
    address _erc721Address,
    uint128 _dailyRewards,
    uint256[] memory _boostedNftIds,
    uint128 _dailyRewardBoostMultiplier
  ) {
    erc20 = IMintableERC20(_erc20Address);
    erc721 = IERC721(_erc721Address);
    setDailyRewards(_dailyRewards);
    setBoostedNftIds(_boostedNftIds);
    setDailyRewardBoostMultiplier(_dailyRewardBoostMultiplier);
  }

  /**
   * @dev Emitted every time a token is staked
   *
   * Emitted in stake()
   *
   * @param by address that staked the NFT
   * @param time block timestamp the NFT were staked at
   * @param tokenId token ID of NFT that was staken
   */
  event Staked(address indexed by, uint256 indexed tokenId, uint256 time);

  /**
   * @dev Emitted every time a token is unstaked
   *
   * Emitted in unstake()
   *
   * @param by address that unstaked the NFT
   * @param time block timestamp the NFT were staked at
   * @param tokenId token ID of NFT that was unstaken
   * @param stakedAt when the NFT initially staked at
   * @param reward how many tokens user got for the
   *               staking of the NFT
   */
  event Unstaked(address indexed by, uint256 indexed tokenId, uint256 time, uint256 stakedAt, uint256 reward);

  /**
   * @dev Emitted when the boosted NFT ids is changed
   *
   * Emitted in setDailyReward()
   *
   * @param by address that changed the daily reward
   * @param oldDailyRewards old daily reward
   * @param newDailyRewards new daily reward in effect
   */
  event DailyRewardsChanged(address indexed by, uint128 oldDailyRewards, uint128 newDailyRewards);

  /**
   * @dev Emitted when the boosted NFT daily reward
   *      multiplier is changed
   *
   * Emitted in setDailyRewardBoostMultiplier()
   *
   * @param by address that changed the daily reward boost multiplier
   * @param oldDailyRewardBoostMultiplier old daily reward boost multiplier
   * @param newDailyRewardBoostMultiplier new daily reward boost multiplier
   */
  event DailyRewardBoostMultiplierChanged(
    address indexed by,
    uint128 oldDailyRewardBoostMultiplier,
    uint128 newDailyRewardBoostMultiplier
  );

  /**
   * @dev Emitted when the boosted NFT ids change
   *
   * Emitted in setBoostedNftIds()
   *
   * @param by address that changed the boosted NFT ids
   * @param oldBoostedNftIds old boosted NFT ids
   * @param newBoostedNftIds new boosted NFT ids
   */
  event BoostedNftIdsChanged(address indexed by, uint256[] oldBoostedNftIds, uint256[] newBoostedNftIds);

  /**
   * @notice Checks whether a token is boosted to receive
   *         bigger staking rewards
   *
   * @param _tokenId ID of token to check
   * @return whether the token is boosted
   */
  function isBoostedToken(uint256 _tokenId) public view returns (bool) {
    return boostedNftIds.contains(_tokenId);
  }

  /**
   * @notice Changes the daily reward in erc20 tokens received
   *         for every NFT staked
   *
   * @dev Restricted to contract owner
   *
   * @param _newDailyRewards the new daily reward in erc20 tokens
   */
  function setDailyRewards(uint128 _newDailyRewards) public onlyOwner {
    // Emit event
    emit DailyRewardsChanged(msg.sender, dailyRewards, _newDailyRewards);

    // Change storage variable
    dailyRewards = _newDailyRewards;
  }

  /**
   * @notice Changes the daily reward boost multiplier for
   *         boosted NFTs
   *
   * @dev Restricted to contract owner
   *
   * @param _newDailyRewardBoostMultiplier the new daily reward boost multiplier
   */
  function setDailyRewardBoostMultiplier(uint128 _newDailyRewardBoostMultiplier) public onlyOwner {
    // Emit event
    emit DailyRewardBoostMultiplierChanged(msg.sender, dailyRewardBoostMultiplier, _newDailyRewardBoostMultiplier);

    // Change storage variable
    dailyRewardBoostMultiplier = _newDailyRewardBoostMultiplier;
  }

  /**
   * @notice Changes the boosted NFT ids that receive
   *         a bigger daily reward
   *
   * @dev Restricted to contract owner
   *
   * @param _newBoostedNftIds the new boosted NFT ids
   */
  function setBoostedNftIds(uint256[] memory _newBoostedNftIds) public onlyOwner {
    // Create array to store old boosted NFTs and emit
    // event later
    uint256[] memory oldBoostedNftIds = new uint256[](boostedNftIds.length());

    // Empty boosted NFT ids set
    for (uint256 i = 0; boostedNftIds.length() > 0; i++) {
      // Get a value from the set
      // Since set length is > 0 it is guaranteed
      // that there is a value at index 0
      uint256 value = boostedNftIds.at(0);

      // Remove the value
      boostedNftIds.remove(value);

      // Store the value to the old boosted NFT ids
      // list to later emit event
      oldBoostedNftIds[i] = value;
    }

    // Emit event
    emit BoostedNftIdsChanged(msg.sender, oldBoostedNftIds, _newBoostedNftIds);

    // Enumerate new boosted NFT ids
    for (uint256 i = 0; i < _newBoostedNftIds.length; i++) {
      uint256 boostedNftId = _newBoostedNftIds[i];

      // Add boosted NFT id to set
      boostedNftIds.add(boostedNftId);
    }
  }

  /**
   * @notice Calculates all the NFTs currently staken by
   *         an address
   *
   * @dev This is an auxiliary function to help with integration
   *      and is not used anywhere in the smart contract login
   *
   * @param _owner address to search staked tokens of
   * @return an array of token IDs of NFTs that are currently staken
   */
  function tokensStakedByOwner(address _owner) external view returns (uint256[] memory) {
    // Cache the length of the staked tokens set for the owner
    uint256 stakedTokensLength = stakedTokens[_owner].length();

    // Create an empty array to store the result
    // Should be the same length as the staked tokens
    // set
    uint256[] memory tokenIds = new uint256[](stakedTokensLength);

    // Copy set values to array
    for (uint256 i = 0; i < stakedTokensLength; i++) {
      tokenIds[i] = stakedTokens[_owner].at(i);
    }

    // Return array result
    return tokenIds;
  }

  /**
   * @notice Calculates the rewards that would be earned by
   *         the user for each an NFT if he was to unstake it at
   *         the current block
   *
   * @param _tokenId token ID of NFT rewards are to be calculated for
   * @return the amount of rewards for the input staken NFT
   */
  function currentRewardsOf(uint256 _tokenId) public view returns (uint256) {
    // Verify NFT is staked
    require(stakedAt[_tokenId] != 0, "not staked");

    // Get current token ID staking time by calculating the
    // delta between the current block time(`block.timestamp`)
    // and the time the token was initially staked(`stakedAt[tokenId]`)
    uint256 stakingTime = block.timestamp - stakedAt[_tokenId];

    // `stakingTime` is the staking time in seconds
    // Calculate the staking time in days by:
    //   * dividing by 60 (seconds in a minute)
    //   * dividing by 60 (minutes in an hour)
    //   * dividing by 24 (hours in a day)
    // This will yield the (rounded down) staking
    // time in days
    uint256 stakingDays = stakingTime / 60 / 60 / 24;

    // Calculate reward for token by multiplying
    // rounded down number of staked days by daily
    // rewards variable
    uint256 reward = stakingDays * dailyRewards;

    // If the NFT is boosted
    if (isBoostedToken(_tokenId)) {
      // Multiply the reward
      reward *= dailyRewardBoostMultiplier;
    }

    // Return reward
    return reward;
  }

  /**
   * @notice Stake NFTs to start earning ERC-20
   *         token rewards
   *
   * The ERC-20 token rewards will be paid out
   * when the NFTs are unstaken
   *
   * @dev Sender must first approve this contract
   *      to transfer NFTs on his behalf and NFT
   *      ownership is transferred to this contract
   *      for the duration of the staking
   *
   * @param _tokenIds token IDs of NFTs to be staken
   */
  function stake(uint256[] memory _tokenIds) public {
    // Ensure at least one token ID was sent
    require(_tokenIds.length > 0, "no token IDs sent");

    // Enumerate sent token IDs
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      // Get token ID
      uint256 tokenId = _tokenIds[i];

      // Store NFT owner
      ownerOf[tokenId] = msg.sender;

      // Add NFT to owner staked tokens
      stakedTokens[msg.sender].add(tokenId);

      // Store staking time as block timestamp the
      // the transaction was confirmed in
      stakedAt[tokenId] = block.timestamp;

      // Transfer token to staking contract
      // Will fail if the user does not own the
      // token or has not approved the staking
      // contract for transferring tokens on his
      // behalf
      erc721.safeTransferFrom(msg.sender, address(this), tokenId, "");

      // Emit event
      emit Staked(msg.sender, tokenId, stakedAt[tokenId]);
    }
  }

  /**
   * @notice Unstake NFTs to receive ERC-20 token rewards
   *
   * @dev Sender must have first staken the NFTs
   *
   * @param _tokenIds token IDs of NFTs to be unstaken
   */
  function unstake(uint256[] memory _tokenIds) public {
    // Ensure at least one token ID was sent
    require(_tokenIds.length > 0, "no token IDs sent");

    // Create a variable to store the total rewards for all
    // NFTs sent
    uint256 totalRewards = 0;

    // Enumerate sent token IDs
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      // Get token ID
      uint256 tokenId = _tokenIds[i];

      // Verify sender is token ID owner
      // Will fail if token is not staked (owner is 0x0)
      require(ownerOf[tokenId] == msg.sender, "not token owner");

      // Calculate rewards for token ID. Will revert
      // if the token is not staken
      uint256 rewards = currentRewardsOf(tokenId);

      // Increase amount of total rewards
      // for all tokens sent
      totalRewards += rewards;

      // Emit event
      emit Unstaked(msg.sender, tokenId, block.timestamp, stakedAt[tokenId], rewards);

      // Reset `ownerOf` and `stakedAt`
      // for token
      ownerOf[tokenId] = address(0);
      stakedAt[tokenId] = 0;

      // Remove NFT from owner staked tokens
      stakedTokens[msg.sender].remove(tokenId);

      // Transfer NFT back to user
      erc721.transferFrom(address(this), msg.sender, tokenId);
    }

    // Mint total rewards for all sent NFTs
    // to user
    erc20.mint(msg.sender, totalRewards);
  }
}