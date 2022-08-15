// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IRewardToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

error Staking__AlreadyInitialized();
error Staking__NotStarted();
error Staking__NotOwner();
error Staking__NotTokenOwner();
error Staking__NoRewardsToClaim();

contract Staking is Ownable, ERC721Holder {
    using SafeERC20 for IRewardToken;

    uint256 public stakedTotal;
    uint256 public stakingStartTime;

    // rewards rate in WEI
    uint256 private rewardsPerHour = 1 ether;

    // interfaces for nft and rewards conttracts
    IERC721 public immutable nft;
    IRewardToken public immutable rewardsToken;

    struct Staker {
        uint256[] tokenIds;
        uint256 rewardsReleased;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
    }

    // map Staker to address
    mapping(address => Staker) public stakers;

    // map token id to owners
    mapping(uint256 => address) public tokenOwner;

    bool initialised;

    // Events
    event Staked(address indexed owner, uint256 tokenId, uint256 timestamp);
    event Unstaked(address indexed owner, uint256 tokenId, uint256 timestamp);
    event RewardPaid(address indexed user, uint256 reward);
    event ClaimableStatusUpdated(bool status);

    constructor(IERC721 _nft, IRewardToken _rewardsToken) {
        nft = _nft;
        rewardsToken = _rewardsToken;
    }

    function getStakeInitStatus() public view returns (bool) {
        return initialised;
    }

    function initStaking() public onlyOwner {
        if (initialised) {
            revert Staking__AlreadyInitialized();
        }
        stakingStartTime = block.timestamp;
        initialised = true;
    }

    function getRewardsHourlyRate() public view returns (uint256) {
        return rewardsPerHour;
    }

    // tokens staked by particular address
    function getStakedTokens(address _user)
        public
        view
        returns (uint256[] memory tokenIds)
    {
        return stakers[_user].tokenIds;
    }

    function stake(uint256 tokenId) public {
        _stake(msg.sender, tokenId);
    }

    function stakeBatch(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i]);
        }
    }

    function _stake(address _user, uint256 _tokenId) internal {
        if (!initialised) {
            revert Staking__NotStarted();
        }

        Staker storage staker = stakers[_user];

        if (nft.ownerOf(_tokenId) != msg.sender) {
            revert Staking__NotTokenOwner();
        }

        staker.tokenIds.push(_tokenId);
        tokenOwner[_tokenId] = _user;

        nft.safeTransferFrom(_user, address(this), _tokenId);

        emit Staked(_user, _tokenId, block.timestamp);
        staker.timeOfLastUpdate = block.timestamp;
        stakedTotal++;
    }

    function unstake(uint256 _tokenId) public {
        claimRewards(msg.sender);
        _unstake(msg.sender, _tokenId);
    }

    function unstakeBatch(uint256[] memory tokenIds) public {
        claimRewards(msg.sender);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenOwner[tokenIds[i]] == msg.sender) {
                _unstake(msg.sender, tokenIds[i]);
            }
        }
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        if (tokenOwner[_tokenId] != _user) {
            revert Staking__NotOwner();
        }
        Staker storage staker = stakers[_user];

        // find index of token in users staked tokens
        uint tokenIndex;
        for (uint i = 0; i < staker.tokenIds.length; i++) {
            if (staker.tokenIds[i] == _tokenId) {
                tokenIndex = i;
                break;
            }
        }

        // remove from list of the address' staked tokens
        for (uint i = tokenIndex; i < staker.tokenIds.length - 1; i++) {
            staker.tokenIds[i] = staker.tokenIds[i + 1];
        }
        staker.tokenIds.pop();

        delete tokenOwner[_tokenId];

        nft.safeTransferFrom(address(this), _user, _tokenId);

        emit Unstaked(_user, _tokenId, block.timestamp);
        staker.timeOfLastUpdate = block.timestamp;
        stakedTotal--;
    }

    // Calculate rewards for the msg.sender, check if there are any rewards
    // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
    // to the user.
    function claimRewards(address _user) public {
        uint256 rewards = calculateRewards(_user) +
            stakers[_user].unclaimedRewards;
        if (rewards <= 0) {
            revert Staking__NoRewardsToClaim();
        }

        stakers[_user].rewardsReleased += stakers[_user].unclaimedRewards;
        stakers[_user].unclaimedRewards = 0;
        stakers[_user].timeOfLastUpdate = block.timestamp;

        rewardsToken.safeTransfer(_user, rewards);

        emit RewardPaid(_user, rewards);
    }

    // Calculate rewards for param _stakerAddress by calculating the time passed
    // since last update in hours and mulitplying it to ERC721 Tokens Staked
    // and rewardsPerHour.
    function calculateRewards(address _stakerAddress)
        internal
        view
        returns (uint256 _rewards)
    {
        // calculate based on no of staked, and time passed
        return (((
            ((block.timestamp - stakers[_stakerAddress].timeOfLastUpdate) *
                stakers[_stakerAddress].tokenIds.length)
        ) * rewardsPerHour) / 3600);
    }

    function getTotalRewards(address _user) external view returns (uint256) {
        uint256 rewards = calculateRewards(_user) +
            stakers[_user].unclaimedRewards;
        return rewards;
    }

    function getTotalStaked() external view returns (uint256) {
        return stakedTotal;
    }
}