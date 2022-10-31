// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OasisStaking is Ownable, ReentrancyGuard {
    /// STRUCTS ///

    struct Staker {
        uint256 amountStaked;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
    }

    /// STATE VARIABLES ///

    IERC20 public immutable oasisToken;
    IERC721 public immutable evolvedCamels;

    uint256 private rewardsPerHour = 100000000000000000000;
    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public stakerAddress;

    address[] public stakersArray;

    /// CONSTRUCTOR ///

    constructor(IERC721 _nftCollection, IERC20 _rewardsToken) {
        evolvedCamels = _nftCollection;
        oasisToken = _rewardsToken;
    }

    /// USER FUNCTIONS ///

    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        } else {
            stakersArray.push(msg.sender);
        }
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            require(evolvedCamels.ownerOf(_tokenIds[i]) == msg.sender, "Can't stake tokens you don't own!");
            evolvedCamels.transferFrom(msg.sender, address(this), _tokenIds[i]);
            stakerAddress[_tokenIds[i]] = msg.sender;
        }
        stakers[msg.sender].amountStaked += len;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
        require(stakers[msg.sender].amountStaked > 0, "You have no tokens staked");
        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            require(stakerAddress[_tokenIds[i]] == msg.sender);
            stakerAddress[_tokenIds[i]] = address(0);
            evolvedCamels.transferFrom(address(this), msg.sender, _tokenIds[i]);
        }
        stakers[msg.sender].amountStaked -= len;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        if (stakers[msg.sender].amountStaked == 0) {
            for (uint256 i; i < stakersArray.length; ++i) {
                if (stakersArray[i] == msg.sender) {
                    stakersArray[i] = stakersArray[stakersArray.length - 1];
                    stakersArray.pop();
                }
            }
        }
    }

    function claimRewards() external {
        uint256 rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        if (!oasisToken.transfer(msg.sender, rewards)) revert("Transfer issue");
    }

    /// OWNER FUNCTIONS ///

    function setRewardsPerHour(uint256 _newValue) public onlyOwner {
        address[] memory _stakers = stakersArray;
        uint256 len = _stakers.length;
        for (uint256 i; i < len; ++i) {
            address user = _stakers[i];
            stakers[user].unclaimedRewards += calculateRewards(user);
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        }
        rewardsPerHour = _newValue;
    }

    /// VIEW FUNCTIONS ///

    function userStakeInfo(address _user) public view returns (uint256 _tokensStaked, uint256 _availableRewards) {
        return (stakers[_user].amountStaked, availableRewards(_user));
    }

    function availableRewards(address _user) internal view returns (uint256) {
        if (stakers[_user].amountStaked == 0) {
            return stakers[_user].unclaimedRewards;
        }
        uint256 _rewards = stakers[_user].unclaimedRewards + calculateRewards(_user);
        return _rewards;
    }

    /// INTERNAL FUNCTIONS ///

    function calculateRewards(address _staker) internal view returns (uint256 _rewards) {
        Staker memory staker = stakers[_staker];
        return (((((block.timestamp - staker.timeOfLastUpdate) * staker.amountStaked)) * rewardsPerHour) / 3600);
    }
}