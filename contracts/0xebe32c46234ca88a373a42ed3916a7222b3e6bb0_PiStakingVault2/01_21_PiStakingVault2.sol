pragma solidity 0.7.4;

// SPDX-License-Identifier: MIT

import "./openzeppelinupgradeable/proxy/Initializable.sol";
import "./openzeppelinupgradeable/math/MathUpgradeable.sol";
import "./openzeppelinupgradeable/math/SafeMathUpgradeable.sol";
import "./interfaces/IERC20.sol";
import "./openzeppelinupgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/INFT.sol";


// Inheritance
import "./openzeppelinupgradeable/utils/PausableUpgradeable.sol";
import "./openzeppelinupgradeable/access/OwnableUpgradeable.sol";

import "./openzeppelinupgradeable/utils/ContextUpgradeable.sol";
import "./openzeppelinupgradeable/token/ERC1155/ERC1155HolderUpgradeable.sol";
import "./openzeppelin/TokensRecoverableUpg.sol";


// https://docs.synthetix.io/contracts/source/contracts/rewardsdistributionrecipient
abstract contract RewardsDistributionRecipient is OwnableUpgradeable {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        require(_rewardsDistribution!=address(0),"_rewardsDistribution cannot be zero address");
        rewardsDistribution = _rewardsDistribution;
    }
}

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract PiStakingVault2 is Initializable, OwnableUpgradeable, RewardsDistributionRecipient, ReentrancyGuardUpgradeable, PausableUpgradeable , TokensRecoverableUpg {
    using SafeMathUpgradeable for uint256;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC1155 public stakingToken;
    uint256 public periodFinish ;
    uint256 public rewardRate ;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    // added mapping to hold balances of ERC1155 sent to contract
    // NFT owner -> TokenID -> Quantity
    mapping(address => mapping(uint256=>uint256)) private _tokenBalances;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    function initialize(        
        address _rewardsDistribution,
        address _rewardsToken1,
        address _stakingToken // erc1155 token 
        )  public initializer  {
        
        __Ownable_init_unchained();
        rewardsToken = IERC20(_rewardsToken1);
        stakingToken = IERC1155(_stakingToken);
        rewardsDistribution = _rewardsDistribution;

        require(_rewardsDistribution!=address(0),"_rewardsDistribution cannot be zero address");
        require(_rewardsToken1!=address(0),"_rewardsToken1 cannot be zero address");
        require(_stakingToken!=address(0),"_stakingToken cannot be zero address");

        periodFinish = 0;
        rewardRate = 0;
        rewardsDuration = 60 days;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external  view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external  view returns (uint256) {
        return _balances[account];
    }

    function balanceOfNFT(address account, uint256 tokenId) external  view returns (uint256) {
        return _tokenBalances[account][tokenId];
    }


    function lastTimeRewardApplicable() public  view returns (uint256) {
        return MathUpgradeable.min(block.timestamp,periodFinish);
    }

    function rewardPerToken() public  view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) public  view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external  view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function getRewardToken1APY() external view returns (uint256) {
        //3153600000 = 365*24*60*60
        if(block.timestamp>periodFinish) return 0;
        uint256 rewardForYear = rewardRate.mul(31536000); 
        if(_totalSupply<=1e18) return rewardForYear.div(1e10);
        return rewardForYear.mul(1e8).div(_totalSupply); // put 6 dp
    }

    function getRewardToken1WPY() external view returns (uint256) {
        //60480000 = 7*24*60*60
        if(block.timestamp>periodFinish) return 0;
        uint256 rewardForWeek = rewardRate.mul(604800); 
        if(_totalSupply<=1e18) return rewardForWeek.div(1e10);
        return rewardForWeek.mul(1e8).div(_totalSupply); // put 6 dp
    }


    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 tokenId, uint256 amount ) external  nonReentrant whenNotPaused updateReward(_msgSender()) {

        require(tokenId == 2, "Token id should be 2");       
        require(amount > 0, "Cannot stake 0");

        _totalSupply = _totalSupply.add(amount.mul(1e18));
        _balances[_msgSender()] = _balances[_msgSender()].add(amount.mul(1e18));
                
        stakingToken.safeTransferFrom(_msgSender(), address(this), tokenId, amount, "0x");
        _tokenBalances[_msgSender()][tokenId]=_tokenBalances[_msgSender()][tokenId].add(amount);

        emit Staked(_msgSender(), tokenId, amount);
    }

    function withdraw(uint256 tokenId, uint256 amount) public  nonReentrant updateReward(_msgSender()) {

        require(tokenId == 2, "Token id should be 2");       
        require(amount > 0, "Cannot withdraw 0");
        _tokenBalances[_msgSender()][tokenId]=_tokenBalances[_msgSender()][tokenId].sub(amount);

        _totalSupply = _totalSupply.sub(amount.mul(1e18));
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount.mul(1e18));
        stakingToken.safeTransferFrom(address(this),_msgSender(), tokenId, amount, "0x");
        emit Withdrawn(_msgSender(), tokenId, amount, amount);
    }

    function getReward() public  nonReentrant updateReward(_msgSender()) {
        uint256 reward = rewards[_msgSender()];
        if (reward > 0) {
            rewards[_msgSender()] = 0;
            rewardsToken.transfer(_msgSender(), reward);
            emit RewardPaid(_msgSender(), reward);
        }
    }

    function exit(uint256 tokenId) external  {
        withdraw(tokenId,_tokenBalances[_msgSender()][tokenId]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external override onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }


    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress!=address(rewardsToken),"tokenAddress cannot be rewardsToken");
        address owner = OwnableUpgradeable.owner();
        IERC20(tokenAddress).transfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external  returns(bytes4){
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external  returns(bytes4){
        return 0xbc197c81;
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
    event Staked(address indexed user, uint256 tokenId, uint256 quantity);
    event Withdrawn(address indexed user,  uint256 tokenId, uint256 quantity, uint256 valuation);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}