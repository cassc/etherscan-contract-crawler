// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./TokensRecoverable.sol";
import "./interfaces/IBLL.sol";

// https://docs.synthetix.io/contracts/source/contracts/rewardsdistributionrecipient
abstract contract RewardsDistributionRecipient is OwnableUpgradeable {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardsDistribution() {
        require(
            msg.sender == rewardsDistribution,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    function setRewardsDistribution(address _rewardsDistribution)
        external
        onlyOwner
    {
        require(
            _rewardsDistribution != address(0),
            "_rewardsDistribution cannot be zero address"
        );
        rewardsDistribution = _rewardsDistribution;
    }
}

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract PiGamificationStakingSeriesAudited is
    Initializable,
    OwnableUpgradeable,
    RewardsDistributionRecipient,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    TokensRecoverable
{
    using SafeMathUpgradeable for uint256;

    /* ========== STATE VARIABLES ========== */

    IERC20Upgradeable public rewardsToken;
    IERC721Upgradeable public stakingToken;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    mapping(address => uint) public _tokenBalances;

    // Account => All NFT ids staked (not updated during withdraw)
    mapping(address => uint32[]) public tokenIdsStaked;

    // nft ids owner => stake value from BLL
    mapping(address => uint256) public stakedAtValue;

    // total worth value of staked token ids
    uint256 private _totalSupply;
    // Account => total worth value of staked token ids for the account
    mapping(address => uint256) private _balances;

    // seriesId => addresses staked
    mapping(uint32 => address[]) public allStakers;

    // if address has already staked
    mapping(address => bool) public isStaked;
    IBLL public BLLContract;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _rewardsDistribution,
        address _rewardsToken1,
        address _stakingToken, // ERC721 token
        address _BLLContract
    ) public initializer {
        __Ownable_init_unchained();
        rewardsToken = IERC20Upgradeable(_rewardsToken1);
        stakingToken = IERC721Upgradeable(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        BLLContract = IBLL(_BLLContract);

        require(
            _rewardsDistribution != address(0),
            "_rewardsDistribution cannot be zero address"
        );
        require(
            _rewardsToken1 != address(0),
            "_rewardsToken1 cannot be zero address"
        );
        require(
            _stakingToken != address(0),
            "_stakingToken cannot be zero address"
        );
        require(
            _BLLContract != address(0),
            "_BLLContract cannot be zero address"
        );

        periodFinish = 0;
        rewardRate = 0;
        rewardsDuration = 60 days;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function balanceOfNFT(address account) external  view returns (uint256) {
        return _tokenBalances[account];
    }


    function lastTimeRewardApplicable() public view returns (uint256) {
        return MathUpgradeable.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function getRewardToken1APY() external view returns (uint256) {
        //3153600000 = 365*24*60*60
        if (block.timestamp > periodFinish) return 0;
        uint256 rewardForYear = rewardRate.mul(31536000);
        if (_totalSupply <= 1e18) return rewardForYear.div(1e10);
        return rewardForYear.mul(1e8).div(_totalSupply); // put 6 dp
    }

    function getRewardToken1WPY() external view returns (uint256) {
        //60480000 = 7*24*60*60
        if (block.timestamp > periodFinish) return 0;
        uint256 rewardForWeek = rewardRate.mul(604800);
        if (_totalSupply <= 1e18) return rewardForWeek.div(1e10);
        return rewardForWeek.mul(1e8).div(_totalSupply); // put 6 dp
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint32 seriesId, uint32[] memory tokenIds)
        external
        nonReentrant
        whenNotPaused
        updateReward(_msgSender())
    {
        require(!isStaked[_msgSender()], "Already staked, can stake only once");
        require(
            BLLContract.checkSeriesForTokenIDs(seriesId, tokenIds),
            "checkSeriesForTokenIDs failed"
        );
        uint256 value = BLLContract.getPointsForSeries(seriesId, tokenIds).mul(
            1e18
        );
        stakeValue(_msgSender(), value);
        stakedAtValue[_msgSender()] = value;
        tokenIdsStaked[_msgSender()] = tokenIds;
        for (uint32 i = 0; i < tokenIds.length; i++)
            stakingToken.safeTransferFrom(
                _msgSender(),
                address(this),
                tokenIds[i]
            );

        allStakers[seriesId].push(_msgSender());
        isStaked[_msgSender()] = true;

        _tokenBalances[_msgSender()]=_tokenBalances[_msgSender()].add(tokenIds.length);        
        emit Staked(_msgSender(), tokenIds);

    }

    function updateAllPoints(uint32 seriesId) external onlyOwner {
        updatePoints(seriesId, allStakers[seriesId]);
    }

    function updatePoints(uint32 seriesId, address[] memory stakerAddresses)
        public
        onlyOwner
    {
        for (uint32 i = 0; i < stakerAddresses.length; i++) {
            uint256 value = BLLContract
                .getPointsForSeries(
                    seriesId,
                    tokenIdsStaked[stakerAddresses[i]]
                )
                .mul(1e18);
            address staker = stakerAddresses[i];
            if (isStaked[staker]) {
                uint256 prevValue = stakedAtValue[staker];
                refreshReward(staker);
                if (prevValue > value)
                    unstakeValue(staker, prevValue.sub(value));
                else stakeValue(staker, value.sub(prevValue));
                stakedAtValue[staker] = value;
            }
        }
        emit UpdatedPoints(stakerAddresses);
    }

    // removes extra stakers..
    // optional to call
    //called only if lot of users have unstaked so that while calling updatePoints() by contract owner it takes less gas
    function refresh_AllStakers(uint32 seriesId) external {
        uint32 newArrSize = 0;
        // find size of new arr
        for (uint32 i = 0; i < allStakers[seriesId].length; i++)
            if (isStaked[allStakers[seriesId][i]]) newArrSize++;

        address[] memory newStakers = new address[](newArrSize);
        uint32 j = 0;
        for (uint32 i = 0; i < allStakers[seriesId].length; i++) {
            address staker = allStakers[seriesId][i];
            if (isStaked[allStakers[seriesId][i]]) {
                newStakers[j] = staker;
                j++;
            }
        }
        allStakers[seriesId] = newStakers;
        emit RefreshedallStakers(seriesId);
    }

    function stakeValue(address account, uint256 delta) internal {
        _totalSupply = _totalSupply.add(delta);
        _balances[account] = _balances[account].add(delta);
    }

    function unstakeValue(address account, uint256 delta) internal {
        _totalSupply = _totalSupply.sub(delta);
        _balances[account] = _balances[account].sub(delta);
    }

    function setBLLContract(IBLL _BLLContract) external onlyOwner {
        BLLContract = _BLLContract;
    }

    function _withdrawAll() internal updateReward(_msgSender()) {
        uint32[] memory tokenIds = tokenIdsStaked[_msgSender()];
        uint256 value = stakedAtValue[_msgSender()];
        _totalSupply = _totalSupply.sub(value);
        _balances[_msgSender()] = 0;
        for (uint256 i = 0; i < tokenIds.length; i++)
            stakingToken.safeTransferFrom(
                address(this),
                _msgSender(),
                tokenIds[i]
            );
        isStaked[_msgSender()] = false;
        uint32[] memory newArr;
        _tokenBalances[_msgSender()]=0;
        tokenIdsStaked[_msgSender()] = newArr;
        emit WithdrawnAll(_msgSender());
    }

    function getReward() public nonReentrant updateReward(_msgSender()) {
        uint256 reward = rewards[_msgSender()];
        if (reward > 0) {
            rewards[_msgSender()] = 0;
            rewardsToken.transfer(_msgSender(), reward);
            emit RewardPaid(_msgSender(), reward);
        }
    }

    function exit() external {
        _withdrawAll();
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward)
        external
        override
        onlyRewardsDistribution
        updateReward(address(0))
    {
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
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function refreshReward(address account) internal updateReward(account) {}

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) external returns (bytes4) {
        return 0x150b7a02;
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
    event Staked(address indexed user, uint32[] tokenIds);
    event WithdrawnAll(address indexed user);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event UpdatedPoints(address[] stakers);
    event RefreshedallStakers(uint32 seriesId);
    event RefreshedTokenIdsStaked(address indexed user);
}