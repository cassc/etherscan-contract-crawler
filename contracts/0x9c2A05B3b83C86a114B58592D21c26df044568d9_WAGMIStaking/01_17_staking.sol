// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract WAGMIStaking is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    IERC721 public nftCollection;
    IERC20 public rewardsToken;
    address public treasury;

    uint256 public minimumStakingTime = 14 * 24;
    uint256 public minimumVIPStakingTime = 100 * 24;

    event NFTStaked (
        address indexed staker,
        uint256[] tokenIds
    );

    event NFTUnStaked (
        address indexed staker,
        uint256[] tokenIds
    );

    event Pay (
        address indexed staker,
        string itemId,
        string itemType,
        uint256 amount
    );

    event RewardClaimed (
        address indexed staker,
        uint256 amount
    );

    function initialize(
        IERC721 _nftCollection,
        IERC20 _rewardsToken,
        address _treasury,
        uint256[] memory _vipTokenIds
    )
    public
    initializer
    {
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
        treasury = _treasury;

        for (uint256 i = 0; i < _vipTokenIds.length; i++) {
            vipTokenIds[_vipTokenIds[i]] = true;
        }

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    // Staker info
    struct Staker {
        // Amount of tokens staked by the staker
        uint256 amountStaked;

        // Last time of the rewards were calculated for this user
        uint256 timeOfLastUpdate;

        // Calculated, but unclaimed rewards for the User. The rewards are
        // calculated each time the user writes to the Smart Contract
        uint256 unclaimedRewards;
    }

    // Rewards per hour per token deposited in wei.
    uint256 private rewardsPerHour = 1000000000000000000;

    mapping(uint256 => bool) public vipTokenIds;
    mapping(address => uint256[]) public stakerTokens;
    mapping(uint256 => address) public stakerAddress;
    mapping(uint256 => uint256) public tokenStakeTime;

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;

    // Mapping of Token Id to staker. Made for the SC to remeber
    // who to send back the ERC721 Token to.


    function setMinimumStakingHours (uint _hours) public onlyOwner {
        minimumStakingTime = _hours;
    }

    function setVIPMinimumStakingHours (uint _hours) public onlyOwner {
        minimumVIPStakingTime = _hours;
    }

    function setRewardPerHour (uint _reward) public onlyOwner {
        rewardsPerHour = _reward;
    }

    // If address already has ERC721 Token/s staked, calculate the rewards.
    // Increment the amountStaked and map msg.sender to the Token Id of the staked
    // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    // value of now.
    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        // If wallet has tokens staked, calculate the rewards before adding the new token
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _stake(_tokenIds[i]);
        }

        emit NFTStaked(msg.sender, _tokenIds);

        // Update the timeOfLastUpdate for the staker
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    function _stake(uint _tokenId) internal {
        // Wallet must own the token they are trying to stake
        require(
            nftCollection.ownerOf(_tokenId) == msg.sender,
            "You don't own this token!"
        );

        // Transfer the token from the wallet to the Smart contract
        nftCollection.transferFrom(msg.sender, address(this), _tokenId);

        // Create StakedToken
        stakerTokens[msg.sender].push(_tokenId);
        tokenStakeTime[_tokenId] = block.timestamp;

        // Increment the amount staked for this wallet
        stakers[msg.sender].amountStaked++;

        // Update the mapping of the tokenId to the staker's address
        stakerAddress[_tokenId] = msg.sender;
    }

    function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
        // Make sure the user has at least one token staked before withdrawing
        require(
            stakers[msg.sender].amountStaked > 0,
            "You have no tokens staked"
        );

        // Update the rewards for this user, as the amount of rewards decreases with less tokens.
        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _withdraw(_tokenIds[i]);
        }

        emit NFTUnStaked(msg.sender, _tokenIds);
        // Update the timeOfLastUpdate for the withdrawer
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    // Check if user has any ERC721 Tokens Staked and if they tried to withdraw,
    // calculate the rewards and store them in the unclaimedRewards
    // decrement the amountStaked of the user and transfer the ERC721 token back to them
    function _withdraw(uint256 _tokenId) internal {
        // Wallet must own the token they are trying to withdraw
        require(stakerAddress[_tokenId] == msg.sender, "You don't own this token!");
        // Find the index of this token id in the stakedTokens array
        uint256 index = 0;
        for (uint256 i = 0; i < stakerTokens[msg.sender].length; i++) {
            if (stakerTokens[msg.sender][i] == _tokenId) {
                index = i;
                break;
            }
        }

        uint256 stakingTime = vipTokenIds[_tokenId] ? minimumVIPStakingTime : minimumStakingTime;
        require(tokenStakeTime[stakerTokens[msg.sender][index]] + (stakingTime * 1 hours) <= block.timestamp, "You cannot withdraw before minimum staking time is passed !");
        // Remove staked token
        delete stakerTokens[msg.sender][index];

        // Decrement the amount staked for this wallet
        stakers[msg.sender].amountStaked--;

        // Update the mapping of the tokenId to the be address(0) to indicate that the token is no longer staked
        stakerAddress[_tokenId] = address(0);

        // Transfer the token back to the withdrawer
        nftCollection.transferFrom(address(this), msg.sender, _tokenId);
    }

    // Calculate rewards for the msg.sender, check if there are any rewards
    // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
    // to the user.
    function claimRewards() external {
        uint256 rewards = calculateRewards(msg.sender) +
        stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        rewardsToken.safeTransfer(msg.sender, rewards);
        emit RewardClaimed(msg.sender, rewards);
    }


    function pay(string memory itemId, string memory itemType, uint256 amount) external {
        uint256 rewards = calculateRewards(msg.sender) +
        stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        require(rewards > amount, "You dont have enough payment");
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = rewards - amount;
        rewardsToken.safeTransfer(treasury, amount);
        emit Pay(msg.sender, itemId, itemType, amount);
    }


    //////////
    // View //
    //////////

    function availableRewards(address _staker) public view returns (uint256) {
        uint256 rewards = calculateRewards(_staker) +
        stakers[_staker].unclaimedRewards;
        return rewards;
    }

    function getStakedTokens(address _user) public view returns (uint256[] memory) {
        return stakerTokens[_user];
    }

    /////////////
    // Internal//
    /////////////

    // Calculate rewards for param _staker by calculating the time passed
    // since last update in hours and mulitplying it to ERC721 Tokens Staked
    // and rewardsPerHour.
    function calculateRewards(address _staker)
    internal
    view
    returns (uint256 _rewards)
    {
        return (((
        ((block.timestamp - stakers[_staker].timeOfLastUpdate) *
        stakers[_staker].amountStaked)
        ) * rewardsPerHour) / 3600);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}