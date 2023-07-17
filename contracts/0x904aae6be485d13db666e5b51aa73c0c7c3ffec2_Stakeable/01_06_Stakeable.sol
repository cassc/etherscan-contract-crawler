// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract Stakeable is ERC721Holder {
    IRewardToken rewardsToken;
    IERC721 nft;

    uint256 public yieldsPaid;
    uint256 public rewardRate;
    uint256 public decimals;
    uint public stakedTotal;

    mapping(uint256 => address) public tokenOwner;
    mapping(address => Staker) public stakers;

    struct Staker {
        uint256[] tokenIds;
        uint256[] stakedTimes;
        uint256 availableYield;
        uint256 lastUpdateTime;
        uint256 multiplier;
    }

    event Staked(address indexed user, uint256 tokenId, uint256 timestamp);
    event Unstaked(address indexed user, uint256 tokenId, uint256 timestamp);
    event EmergencyUnstake(address indexed user, uint256 tokenId);

    constructor(IERC721 _nft, IRewardToken _rewardsToken, uint _baseRewardRate) {
        nft = _nft;
        rewardsToken = _rewardsToken;
        rewardRate = _baseRewardRate;
        decimals = 18;
    }

    modifier updateYield {
        Staker storage staker = stakers[msg.sender];
        if (staker.tokenIds.length > 0) {
            uint256 baseYield = ((block.timestamp - staker.lastUpdateTime) * (10 ** decimals)) / rewardRate;
            staker.availableYield += ((baseYield * staker.multiplier) / 100) * staker.tokenIds.length;
        }
        staker.lastUpdateTime = block.timestamp;
        _;
    }

    function getStakedTime(address _user)
        external
        view
        returns (uint256[] memory stakedTimes)
    {
        return stakers[_user].stakedTimes;
    }

    function getStakedTokenIds(address _user)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        return stakers[_user].tokenIds;
    }

    function getYields(address _user)
        external
        view
        returns (uint256 availableYield)
    {
        return stakers[_user].availableYield;
    }

    function updateYields(address user) external updateYield {

    }

    function stake(uint256 tokenId) external updateYield {
        _stake(msg.sender, tokenId);
        _updateMultiplier();
    }

    function stakeBatch(uint256[] memory tokenIds) external updateYield {
        for (uint i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i]);
        }
        _updateMultiplier();
    }

    function unstake(uint256 _tokenId) external updateYield {
        _unstake(msg.sender, _tokenId);
        _updateMultiplier();
    }

    function unstakeBatch(uint256[] memory tokenIds) external updateYield {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenOwner[tokenIds[i]] == msg.sender);
            _unstake(msg.sender, tokenIds[i]);
        }
        _updateMultiplier();
    }

    // Unstake without caring about rewards. EMERGENCY ONLY.
    function emergencyUnstake(uint256 _tokenId) external {
        require(
            tokenOwner[_tokenId] == msg.sender,
            "nft._unstake: Sender must have staked tokenID"
        );
        _unstake(msg.sender, _tokenId);
        emit EmergencyUnstake(msg.sender, _tokenId);
    }

    function claimReward() external updateYield {
        uint256 reward = stakers[msg.sender].availableYield;
        require(reward > 0 , "0 rewards yet");
        stakers[msg.sender].availableYield = 0;
        rewardsToken.mint(msg.sender, reward);
    }

    function _updateMultiplier() internal {

        if (stakers[msg.sender].tokenIds.length > 4) {
            stakers[msg.sender].multiplier = 200;
        } else if (stakers[msg.sender].tokenIds.length > 0) {
            stakers[msg.sender].multiplier = (((stakers[msg.sender].tokenIds.length - 1) * 25) + 100);
        } else {
            stakers[msg.sender].multiplier = 0;
        }
    }

    function _stake(address _user, uint256 _tokenId) internal {
        require(
            nft.ownerOf(_tokenId) == _user,
            "user must be the owner of the token"
        );

        Staker storage staker = stakers[_user];

        staker.tokenIds.push(_tokenId);
        staker.stakedTimes.push(block.timestamp);
        staker.lastUpdateTime = block.timestamp;
        tokenOwner[_tokenId] = _user;

        nft.safeTransferFrom(_user, address(this), _tokenId);
        emit Staked(_user, _tokenId, block.timestamp);
        stakedTotal++;
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        require(
            tokenOwner[_tokenId] == _user,
            "Nft Staking System: user must be the owner of the staked nft"
        );
        Staker storage staker = stakers[_user];
        
        // Needs to iterate to find the right index in the array
        if (staker.tokenIds.length > 0) {
            for (uint i = 0; i < staker.tokenIds.length; i++){
                if (staker.tokenIds[i] == _tokenId){
                    staker.tokenIds[i] = staker.tokenIds[staker.tokenIds.length - 1];
                    staker.tokenIds.pop();
                    staker.stakedTimes[i] = staker.stakedTimes[staker.stakedTimes.length - 1];
                    staker.stakedTimes.pop();
                }
            }
        }
        delete tokenOwner[_tokenId];

        nft.safeTransferFrom(address(this), _user, _tokenId);

        emit Unstaked(_user, _tokenId, block.timestamp);
        stakedTotal--;
    }
}