// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./X721.sol";

/**
 * @title ERC721Staking
 * @dev ERC721Staking is a contract for staking ERC721 tokens.
 */
contract ERC721Staking is ERC721Holder, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct Stake {
        uint256 since;
        uint256 balance;
        uint256 rewards;
        uint256 claimedRewards;
        address from;
    }
    mapping (uint256 => Stake) stakes; // tokenId => Stake
    mapping (address => mapping(uint256 => uint256)) public stakerToPoolToToken; // user => pool => tokenId

    bool public tokensClaimable;
    bool initialised;
    uint256 stakingStartTime;

    X721 public stakedToken;
    IERC20 public rewardToken;
    uint256 public totalStaked;
    uint256 public x11RateToUSD;
    uint256 constant STAKING_TIME = 1 days;

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount, uint256 indexed tokenId);
    event Unstaked(address indexed user, uint256 indexed tokenId);
    event RewardPaid(address indexed user, uint256 reward);
    event EmergencyUnstake(address indexed user, uint256 indexed tokenId);
    event ClaimableStatusUpdated(bool isEnabled);

    /* ========== METHODS ========== */

    /**
     * @dev Initialises the contract
     * @param _stakedToken The address of the staked token
     * @param _rewardToken The address of the reward token
     */
    constructor(address _stakedToken, address _rewardToken) public {
        stakedToken = X721(_stakedToken);
        rewardToken = IERC20(_rewardToken);   
    }
    
    /**
     * @dev Initializes the staking
     */
    function initStaking() public onlyOwner {
        require(!initialised, "Already initialized");
        stakingStartTime = block.timestamp;
        initialised = true;
    }

    /**
     * @dev Updates the claimable status
     * @param _isEnabled The status of the claimability
     */
    function setTokensClaimable(bool _isEnabled) external onlyOwner {
        tokensClaimable = _isEnabled;
        emit ClaimableStatusUpdated(_isEnabled);
    }

    /**
     * @dev Returns the owner of the staked token
     * @param _tokenId The id of the token
     * @return owner The address of the user
     */
    function getStakedTokenOwner(uint256 _tokenId) public view returns (address owner) {
        return stakes[_tokenId].from;
    }

    /**
     * @dev Performs the stake
     * @param _tokenId The address of the user
     */
    function stake(uint256 _tokenId) public {
        require(initialised, "The staking has not started.");
        require(stakedToken.ownerOf(_tokenId) == msg.sender, "User must own the token.");

        _stake(msg.sender, _tokenId);
    }

    /**
     * @dev Internal stake logic
     * @param _user The address of the user
     * @param _tokenId The id of the token
     */
    function _stake(address _user, uint256 _tokenId) internal {
        Stake memory __stake = Stake({
            since: block.timestamp,
            balance: 0,
            rewards: 0,
            claimedRewards: 0,
            from: _user
        });
        stakes[_tokenId] = __stake;
       
        __stake.balance += stakedToken.peggedAmount(_tokenId);
        
        stakedToken.safeTransferFrom(_user, address(this), _tokenId);

        uint256 poolId = stakedToken.getPoolId(_tokenId);
        stakerToPoolToToken[_user][poolId] = _tokenId;
 
        totalStaked++;   
        emit Staked(_user, 1, _tokenId);
    }

    /**
     * @dev Performs the unstake
     * @param _tokenId The id of the token
     */
    function unstake(uint256 _tokenId) public nonReentrant {
        claimReward(_tokenId);
        _unstake(msg.sender, _tokenId);
    }

    /**
     * @dev Unstake without caring about rewards. EMERGENCY ONLY.
     * @param _tokenId The id of the token
     */
    function emergencyUnstake(uint256 _tokenId) public {
        _unstake(msg.sender, _tokenId);
        emit EmergencyUnstake(msg.sender, _tokenId);
    }

    /**
     * @dev Internal unstake logic
     * @param _user The address of the user
     * @param _tokenId The id of the token
     */
    function _unstake(address _user, uint256 _tokenId) internal {
        require(stakes[_tokenId].from == _user, "User must own the token.");
       
        delete stakes[_tokenId];

        stakedToken.safeTransferFrom(address(this), _user, _tokenId);
        totalStaked--;

        emit Unstaked(_user, _tokenId);
    }

    /*
    * @dev Returns the daily reward percentage for a token
    * @param _tokenId The id of the token
    * @return The daily reward percentage
    */
    function getInvestmentTier(uint256 _tokenId) public view returns (uint256) {
        uint256 peggedAmount = stakedToken.peggedAmount(_tokenId);
        if (peggedAmount < 5000) { 
            return uint256(5) * uint256(10e8) / uint256(365); 
        } else if (peggedAmount >= 5000 && peggedAmount < 15000) {
            return uint256(8) * uint256(10e8) / uint256(365);
        } else if (peggedAmount >= 15000 && peggedAmount < 30000) {
            return uint256(10) * uint256(10e8) / uint256(365);
        } else if (peggedAmount >= 30000 && peggedAmount < 50000) {
            return uint256(15) * uint256(10e8) / uint256(365);
        } else if (peggedAmount >= 50000 && peggedAmount < 70000) {
            return uint256(20) * uint256(10e8) / uint256(365);
        } else if (peggedAmount >= 70000) {
            return uint256(30) * uint256(10e8) / uint256(365);
        }
    }

    /**
     * @dev Calculates the reward for a user
     * @param _tokenId The id of the token
     */
    function updateReward(uint256 _tokenId) public {
        uint256 stakedDays = ((block.timestamp - uint(stakes[_tokenId].since))) / STAKING_TIME;
        uint256 tier = getInvestmentTier(_tokenId);
    
        uint256 tokenRewards = stakedToken.peggedAmount(_tokenId) * stakedDays 
            * tier * 10e18 * 10e7 / (x11RateToUSD * 100); 
        stakes[_tokenId].rewards += tokenRewards; 
    }

    /**
     * @dev Returns the reward for a user
     * @param _tokenId The id of the token
     */
    function getReward(uint256 _tokenId) public view returns (uint256) {
        return stakes[_tokenId].rewards;
    }
    
    /** 
     * @dev Claim reward for the user
     * @param _tokenId Id of the token
     * @return reward Amount of reward claimed
     */
    function claimReward(uint256 _tokenId) public returns (uint256) {
        uint256 unclaimedReward = stakes[_tokenId].rewards - stakes[_tokenId].claimedRewards;
        require(tokensClaimable == true, "Tokens cannnot be claimed yet");
        require(unclaimedReward > 0 , "0 rewards yet");
        require(rewardToken.balanceOf(address(this)) >= unclaimedReward, "Not enough tokens in the contract");
        require(stakes[_tokenId].from == msg.sender, "User must be the same as msg.sender");
        
        rewardToken.transfer(stakes[_tokenId].from, unclaimedReward);

        stakes[_tokenId].claimedRewards += unclaimedReward;

        emit RewardPaid(stakes[_tokenId].from, unclaimedReward);
        return unclaimedReward;
    }

    /**
     * @dev Sets the rate of X11 to USD
     * @param _rate The rate of X11 to USD
     */
    function setRateToUSD(uint256 _rate) public onlyOwner {
        x11RateToUSD = _rate;
    }

    function getTokenId(address _user, uint256 _poolId) public view returns (uint256) {
        return stakerToPoolToToken[_user][_poolId];
    }
}