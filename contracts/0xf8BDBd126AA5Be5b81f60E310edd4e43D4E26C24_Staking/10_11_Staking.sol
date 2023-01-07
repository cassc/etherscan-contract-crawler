// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@andskur/contracts/contracts/extension/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@andskur/contracts/contracts/eip/interface/IERC20.sol";
import "@andskur/contracts/contracts/eip/interface/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IMLC.sol";

import "hardhat/console.sol";


contract Staking is Ownable, PausableUpgradeable {

    // Collection data type with reward amount, reward interval and minimal time of staking
    struct StakedCollection {
        uint256 rewardAmount;
        uint256 rewardInterval;
        uint256 minStaking;
    }

    // Staked Token data type that identifier by collection address and token ID
    struct StakedToken {
        address collection;
        uint256 tokenId;
        address staker;
        uint256 totalStakingTime;
    }

    // Staker data type of token holder user
    struct Staker {
        uint256 amountStaked;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
        uint256 claimedRewards;
        StakedToken[] stakedTokens;
    }

    // Interface for ERC20 rewards token
    IMLC public rewardsToken;

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;

    // Mapping of Collection addresses Token Id to staker
    mapping(address => mapping(uint256 => address)) public stakerAddresses;

    // Added collections for stacking
    //collection address => stacking params see `stakedCollection` data type
    mapping(address => StakedCollection) private _stakedCollections;

    // init function, like constructor but for upgradable contracts
    function initialize(address _rewardsTokenAddress) external initializer {
        require(_rewardsTokenAddress != address(0), "Address of rewards ERC20 should not be 0 address!");
        _setupOwner(msg.sender);
        rewardsToken = IMLC(_rewardsTokenAddress);
    }

    // setRewardsTokenAddress set new rewardsToken address
    function setRewardsTokenAddress(address _rewardsTokenAddress) external onlyOwner whenNotPaused {
        require(_rewardsTokenAddress != address(0), "Rewards address should not be 0 address!");
        rewardsToken = IMLC(_rewardsTokenAddress);
    }

    /*
    * @dev Adds `_amount` of available rewards to claim for given `_staker` address
    *
    * Requirements:
    * - Caller should be owner
    * - Contract should not be paused
    *
    * @param _staker  user address
    * @param _amount  amount of rewards that will be added to available rewards to claim
    */
    function addInitialReward(address _staker, uint256 _amount) external onlyOwner whenNotPaused {
        _addInitialReward(_staker, _amount);
    }

    function addInitialRewardsArray(address[] memory _stakers, uint256[] memory _amounts) external onlyOwner whenNotPaused {
        require(_stakers.length > 0, "There must be at least one staker address");
        require(_amounts.length > 0, "There must be at least one amount value");
        require(_amounts.length == _stakers.length, "stakers length should be the same as _amounts length");

        for (uint256 i = 0; i < _stakers.length; i ++) {
            _addInitialReward(_stakers[i], _amounts[i]);
        }
    }

    function _addInitialReward(address _staker, uint256 _amount) internal {
        require(_staker != address(0), "Staker should not be 0 address!");
        require(_amount > 0, "Amount should be more than 0!");

        if (stakers[_staker].amountStaked > 0) {
            uint256 rewards = calculateRewards(_staker);
            stakers[_staker].unclaimedRewards += rewards;
            _updateTotalTimeStaked(_staker);
        }

        stakers[_staker].unclaimedRewards += _amount;

        stakers[_staker].timeOfLastUpdate = block.timestamp;
    }

    /*
    * @dev If address already has ERC721 Token/s staked, calculate the rewards.
    * Increment the amountStaked and map msg.sender to the Token Id of the staked
    * Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    * value of now.
    *
    * @param _collectionAddress  NFT collection address
    * @param _tokenIds[]  NFT collection token IDs to stake
    */
    function stake(address _collectionAddress, uint256[] memory _tokenIds) external whenNotPaused {
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
            _updateTotalTimeStaked(msg.sender);
        }

        require(_stakedCollections[_collectionAddress].minStaking > 0, "Collection not registered or stacking interval is null");
        require(_stakedCollections[_collectionAddress].rewardInterval > 0, "Collection rewardInterval is null");
        require(_stakedCollections[_collectionAddress].minStaking > 0, "Collection rewardInterval is null");
        require(_tokenIds.length > 0, "There must be at least one token id");

        for (uint256 i = 0; i < _tokenIds.length; i ++) {
            require(IERC721(_collectionAddress).ownerOf(_tokenIds[i]) == msg.sender, "You don't own this token");

            IERC721(_collectionAddress).transferFrom(msg.sender, address(this), _tokenIds[i]);

            StakedToken memory stakedToken = StakedToken(_collectionAddress, _tokenIds[i], msg.sender, 0);

            stakers[msg.sender].stakedTokens.push(stakedToken);

            stakers[msg.sender].amountStaked++;

            stakerAddresses[_collectionAddress][_tokenIds[i]] = msg.sender;
        }

        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    /*
    * @dev Check if user has any ERC721 Tokens Staked and if they tried to withdraw,
    * calculate the rewards and store them in the unclaimedRewards
    * decrement the amountStaked of the user and transfer the ERC721 token back to them
    *
    * @param _collectionAddress  NFT collection address
    * @param _tokenIds  NFT collection token IDs to withdraw
    */
    function withdraw(address _collectionAddress, uint256[] memory _tokenIds) external whenNotPaused {
        require(stakers[msg.sender].amountStaked > 0, "You have no tokens staked");

        for (uint256 l = 0; l < _tokenIds.length; l++) {
            require(stakerAddresses[_collectionAddress][_tokenIds[l]] == msg.sender, "You don't own this token");
        }

        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;

        for (uint256 j = 0; j < _tokenIds.length; j++) {

            uint256 index = 0;
            for (uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
                if (
                    stakers[msg.sender].stakedTokens[i].tokenId == _tokenIds[j]
                    &&
                    stakers[msg.sender].stakedTokens[i].staker != address(0)
                ) {
                    index = i;
                    break;
                }
            }

            stakers[msg.sender].stakedTokens[index].staker = address(0);
            stakers[msg.sender].amountStaked--;
            stakerAddresses[_collectionAddress][_tokenIds[j]] = address(0);

            IERC721(_collectionAddress).transferFrom(address(this), msg.sender, _tokenIds[j]);

        }

        _updateTotalTimeStaked(msg.sender);
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    /*
    * @dev Calculate rewards for the msg.sender, check if there are any rewards
    * claim given amount, set unclaimedRewards to calculated rewards - amount to claim
    * and transfer the ERC20 Reward token to the user
    *
    * @param amountToClaim  how much coins user want to claim
    */
    function claimRewards(uint256 amountToClaim) external whenNotPaused {
        require(amountToClaim > 0, "Amount to claim should be more than 0");
        uint256 rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        _updateTotalTimeStaked(msg.sender);
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = rewards - amountToClaim;
        stakers[msg.sender].claimedRewards = amountToClaim + stakers[msg.sender].claimedRewards;
        rewardsToken.mintTo(msg.sender, amountToClaim);
    }

    /*
    * @dev Calculate rewards for the msg.sender, check if there are any rewards
    * claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token to the user
    *
    */
    function claimAllRewards() external whenNotPaused {
        uint256 rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        _updateTotalTimeStaked(msg.sender);
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        stakers[msg.sender].claimedRewards = rewards + stakers[msg.sender].claimedRewards;
        rewardsToken.mintTo(msg.sender, rewards);
    }

    /*
    * @dev Return available for given _staker address
    *
    * @param _staker   user address
    */
    function availableRewards(address _staker) public view returns (uint256) {
        uint256 rewards = calculateRewards(_staker) + stakers[_staker].unclaimedRewards;
        return rewards;
    }

    /*
    * @dev Return total claimed rewards for given _staker address
    *
    * @param _staker   user address
    */
    function claimedRewards(address _staker) public view returns (uint256) {
        return stakers[_staker].claimedRewards;
    }

    /*
    * @dev Return all staked tokens for given _staker address
    *
    * @param _staker   user address
    */
    function getStakedTokens(address _staker) public view returns (StakedToken[] memory) {
        if (stakers[_staker].amountStaked > 0) {
            StakedToken[] memory _stakedTokens = new StakedToken[](stakers[_staker].amountStaked);
            uint256 _index = 0;

            for (uint256 j = 0; j < stakers[_staker].stakedTokens.length; j++) {
                if (stakers[_staker].stakedTokens[j].staker != (address(0))) {
                    _stakedTokens[_index] = stakers[_staker].stakedTokens[j];
                    _stakedTokens[_index].totalStakingTime += block.timestamp - stakers[_staker].timeOfLastUpdate;
                    _index++;
                }
            }

            return _stakedTokens;
        }

        else {
            return new StakedToken[](0);
        }
    }

    /*
    * @dev Return one staked token for given _collectionAddress and _tokenID
    *
    * @param _collectionAddress   collection address
    * @param _tokenID             token id
    */
    function getStakedToken(address _collectionAddress, uint256 _tokenID) public view returns(StakedToken memory) {
        if (_stakedCollections[_collectionAddress].minStaking > 0) {
            if (stakerAddresses[_collectionAddress][_tokenID] != address(0)) {
                for (uint256 j = 0; j < stakers[stakerAddresses[_collectionAddress][_tokenID]].stakedTokens.length; j++) {
                    StakedToken memory token = stakers[stakerAddresses[_collectionAddress][_tokenID]].stakedTokens[j];

                    if (
                        token.staker != (address(0)) &&
                        token.tokenId == _tokenID &&
                        token.collection == _collectionAddress
                    ) {
                        uint256 totalStakingTime = stakers[stakerAddresses[_collectionAddress][_tokenID]].stakedTokens[j].totalStakingTime;
                        return StakedToken(
                            token.collection,
                            token.tokenId,
                            token.staker,
                            totalStakingTime += block.timestamp - stakers[stakerAddresses[_collectionAddress][_tokenID]].timeOfLastUpdate
                        );
                    }
                }
            }
        }

        return StakedToken(address(0), 0, address(0), 0);
    }

    /*
    * @dev Calculate rewards for given _staker address
    *
    * @param _staker   user address to calculate available reward
    */
    function calculateRewards(address _staker) internal view returns (uint256 _rewards) {
        Staker memory staker = stakers[_staker];

        for (uint256 i = 0; i < staker.stakedTokens.length; i++) {
            StakedToken memory token = staker.stakedTokens[i];
            StakedCollection memory collection = _stakedCollections[token.collection];

            if (block.timestamp - stakers[stakerAddresses[token.collection][token.tokenId]].timeOfLastUpdate < collection.minStaking) {
                continue;
            }

            if (token.staker != (address(0))) {
                _rewards += ((block.timestamp - staker.timeOfLastUpdate) * collection.rewardAmount) / collection.rewardInterval;
            }
        }
        return _rewards;
    }

    /*
    * @dev Adds `collectionAddress` with given params to `_stakedCollections` mapping
    *
    * Requirements:
    * - `collectionAddress` should not be 0
    * - `collectionAddress` should not be added to `_stakedCollections` mapping
    * - `rewardAmount` should not be 0
    * - `rewardInterval` should not be 0
    * - `minStaking` should not be 0
    * - only owner of the contract
    *
    * @param collectionAddress  address of the collection
    * @param rewardAmount       amount of coins as a reward for staking
    * @param rewardInterval     amount in block that could be produced in ethereum chain before users can take their reward
    * @param minStaking        amount in block that user could wait before he could be able to unstake tokens
    */
    function addCollection(
        address collectionAddress,
        uint256 rewardAmount,
        uint256 rewardInterval,
        uint256 minStaking
    ) external onlyOwner whenNotPaused {
        require(collectionAddress != address(0), "Collection address is a zero address!");
        require(_stakedCollections[collectionAddress].rewardAmount == 0, "Collection is already added!");
        require(rewardAmount != 0, "Reward amount should not be 0!");
        require(rewardInterval != 0, "Reward interval should not be 0!");
        require(minStaking != 0, "Minimal time of staking should not be 0!");

        _stakedCollections[collectionAddress] = StakedCollection(rewardAmount, rewardInterval, minStaking);
    }


    /*
     * @dev shows added collection params
     *
     * Requirements:
     * - `collectionAddress` must not be zero address
     * - `collectionAddress` must be in `_stakedCollections` mapping
     *
     * @param `collectionAddress`- address of a collection contract
     * @return `stakedCollection` data type with params of the collection such as
     * reward amount, reward interval and minimal time of staking
     */
    function showCollection(address collectionAddress) public view returns(StakedCollection memory) {
        require(collectionAddress != address(0), "Collection address is a zero address!");
        require(_stakedCollections[collectionAddress].rewardAmount != 0, "Collection is not added!");

        return _stakedCollections[collectionAddress];
    }

    /*
     * @dev allows to edit amount of the reward for given collection. Changes `stakedCollection.rewardAmount`
     *
     * Requirements:
     * - `collectionAddress` must be in `_stakedCollections` mapping
     * - `newRewardAmount` should not be 0
     * - only owner of the contract
     *
     * @param `collectionAddress`- address of a collection contract
     * @param `newRewardAmount`- new amount of coins as a reward for staking
     */
    function editRewardAmount(address collectionAddress, uint256 newRewardAmount) external onlyOwner whenNotPaused {
        require(_stakedCollections[collectionAddress].rewardAmount != 0, "Collection is not added!");
        require(newRewardAmount != 0, "Reward amount should not be 0!");

        _stakedCollections[collectionAddress].rewardAmount = newRewardAmount;
    }

    /*
     * @dev allows to edit reward interval for given collection. Changes `stakedCollection.rewardInterval`
     *
     * Requirements:
     * - `collectionAddress` must be in `_stakedCollections` mapping
     * - `newRewardInterval` should not be 0
     * - only owner of the contract
     *
     * @param `collectionAddress`- address of a collection contract
     * @param `newRewardInterval`- new amount in block that could be produced in ethereum chain before users can take their reward
     */
    function editRewardInterval(address collectionAddress, uint256 newRewardInterval) external onlyOwner whenNotPaused {
        require(_stakedCollections[collectionAddress].rewardAmount != 0, "Collection is not added!");
        require(newRewardInterval != 0, "Reward interval should not be 0!");

        _stakedCollections[collectionAddress].rewardInterval = newRewardInterval;
    }

    /*
     * @dev allows to edit minimal time of staking for given collection. Changes `stakedCollection.minStaking`
     *
     * Requirements:
     * - `collectionAddress` must be in `_stakedCollections` mapping
     * - `newMinStaking` should not be 0
     * - only owner of the contract
     *
     * @param `collectionAddress`- address of a collection contract
     * @param `newMinStaking`- new amount in block that user could wait before he could be able to unstake tokens
     */
    function editMinStaking(address collectionAddress, uint256 newMinStaking) external onlyOwner whenNotPaused {
        require(_stakedCollections[collectionAddress].rewardAmount != 0, "Collection is not added!");
        require(newMinStaking != 0, "Minimal time of staking should not be 0!");

        _stakedCollections[collectionAddress].minStaking = newMinStaking;
    }

    /*
     * @dev allows to set all not view only operations on pause
     *
     * Requirements:
     * - contract must not be paused
     * - only owner of the contract
     *
     */
    function pause() external onlyOwner {
        _pause();
    }

    /*
     * @dev allows to set all not view-only operations to normal state
     *
     * Requirements:
     * - contract must be paused
     * - only owner of the contract
     *
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view override returns (bool) {
        return msg.sender == owner();
    }

    function _updateTotalTimeStaked(address stakerAddress) internal {
        for (uint256 i = 0; i < stakers[stakerAddress].stakedTokens.length; i++) {
            stakers[stakerAddress].stakedTokens[i].totalStakingTime += (
            block.timestamp - stakers[stakerAddress].timeOfLastUpdate
            );
        }

    }
}