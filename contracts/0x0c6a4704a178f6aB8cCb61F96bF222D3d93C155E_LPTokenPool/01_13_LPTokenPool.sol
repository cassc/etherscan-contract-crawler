// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';


contract LPTokenPool is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;


    struct PoolDataInfo{
        // Introduction
        string logo_url;
        string web_site;
        string face_book;
        string twitter;
        string github;
        string telegram;
        string instagram;
        string discord;
        string reddit;
        string description;
    }

    address public rewardToken;
    address public lpt;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    address public psipad_factory;
    uint256 public duration;

    uint256 public frozenStakingTime = 0;
    uint256 public totalAccumulatedReward = 0;
    uint256 public percent = 0;

    uint256 public starttime;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    bool public isLpToken;


    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public receiveReward;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastStakeTime;
    mapping(address => address[]) public inviterAddress;
    mapping(address => uint256) public inviterSize;
    mapping(address => address) public inviter;

    // Introduction
    string public logo_url;
    string public web_site;
    string public face_book;
    string public twitter;
    string public github;
    string public telegram;
    string public instagram;
    string public discord;
    string public reddit;
    string public description;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event DevFundRewardPaid(address indexed user, uint256 reward);

    modifier checkStart() {
        require(block.timestamp >= starttime, 'LPTokenPool: not start');
        _;
    }

    modifier updateReward(address account) {
        //
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyPSIPadFactory() {
        require(psipad_factory == _msgSender(), 'UNAUTHORIZED');
        _;
    }

    constructor() {
        psipad_factory = _msgSender();
    }


    function initialize(
        uint256 _percent,
        address _rewardToken,
        address _lptoken,
        bool _isLpToken,
        uint256 _starttime,
        uint256 _duration,
        address _owner,
        uint256 _frozenStakingTime,
        PoolDataInfo calldata _dataInfo
    ) external initializer {
        require(psipad_factory == address(0) || _msgSender() == psipad_factory, 'UNAUTHORIZED');

        super.__Ownable_init();
        transferOwnership(_owner);

        rewardToken = _rewardToken;
        lpt = _lptoken;
        starttime = _starttime;
        duration = _duration;
        isLpToken = _isLpToken;
        percent = _percent;
        frozenStakingTime = _frozenStakingTime;
        // introduction
        logo_url = _dataInfo.logo_url;
        web_site = _dataInfo.web_site;
        face_book = _dataInfo.face_book;
        twitter = _dataInfo.twitter;
        github = _dataInfo.github;
        telegram = _dataInfo.telegram;
        instagram = _dataInfo.instagram;
        discord = _dataInfo.discord;
        reddit = _dataInfo.reddit;
        description = _dataInfo.description;
        psipad_factory = _msgSender();

    }


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }


    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(totalSupply())
        );
    }
    // 总秒数 * 每天收益 / 总金额

    function earned(address account) public view returns (uint256) {
        return
        balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
    }
    function stake(uint256 amount,address from)
    public
    updateReward(msg.sender)
    checkStart
    {
        require(amount > 0, 'LPTokenPool: Cannot stake 0');
        // Inviter
        bool shouldSetInviter = balanceOf(msg.sender) == 0 &&
        inviter[msg.sender] == address(0) &&
        from != address(0);
        if (shouldSetInviter) {
            inviter[msg.sender] = from;
            inviterAddress[from].push(msg.sender);
            inviterSize[from] = inviterAddress[from].length;
        }
        uint256 newDeposit = deposits[msg.sender].add(amount);
        deposits[msg.sender] = newDeposit;
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        IERC20Upgradeable(lpt).safeTransferFrom(msg.sender, address(this), amount);
        lastStakeTime[msg.sender] = block.timestamp;
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
    public
    updateReward(msg.sender)
    checkStart
    {

        require(amount > 0, 'LPTokenPool: Cannot withdraw 0');

        require(block.timestamp >= unfrozenStakeTime(msg.sender), "LPTokenPool: Cannot withdrawal during freezing");

        deposits[msg.sender] = deposits[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        IERC20Upgradeable(lpt).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        //
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;

            uint256 devPaid = reward.mul(percent).div(1000);
            uint256 remainPaid = reward;
            address inviterAdd =  inviter[msg.sender];
            if(inviterAdd != address(0) && devPaid > 0){
                remainPaid = remainPaid.sub(devPaid);
                IERC20Upgradeable(rewardToken).safeTransfer(inviterAdd, devPaid);
                emit DevFundRewardPaid(inviterAdd, devPaid);
            }

            receiveReward[msg.sender] = receiveReward[msg.sender].add(reward);
            IERC20Upgradeable(rewardToken).safeTransfer(msg.sender, remainPaid);
            emit RewardPaid(msg.sender, remainPaid);
        }
    }

    function notifyRewardAmount(uint256 reward)
    external
    onlyPSIPadFactory
    updateReward(address(0))
    {

        if (block.timestamp > starttime){
            if (block.timestamp >= periodFinish) {
                uint256 period = block.timestamp.sub(starttime).div(duration).add(1);
                periodFinish = starttime.add(period.mul(duration));
                rewardRate = reward.div(periodFinish.sub(block.timestamp));
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = reward.add(leftover).div(remaining);
            }
            lastUpdateTime = block.timestamp;
            emit RewardAdded(reward);
        }else {
            rewardRate = reward.div(duration);
            periodFinish = starttime.add(duration);
            lastUpdateTime = starttime;
            emit RewardAdded(reward);
        }

        totalAccumulatedReward = totalAccumulatedReward.add(reward);
        _checkRewardRate();
    }

    function _checkRewardRate() internal view returns (uint256) {
        return duration.mul(rewardRate).mul(1e18);
    }

    function unfrozenStakeTime(address account) public view returns (uint256) {
        return lastStakeTime[account] + frozenStakingTime;
    }


    function updateIntroduction(PoolDataInfo calldata _dataInfo) external onlyOwner {
        // introduction
        logo_url = _dataInfo.logo_url;
        web_site = _dataInfo.web_site;
        face_book = _dataInfo.face_book;
        twitter = _dataInfo.twitter;
        github = _dataInfo.github;
        telegram = _dataInfo.telegram;
        instagram = _dataInfo.instagram;
        discord = _dataInfo.discord;
        reddit = _dataInfo.reddit;
        description = _dataInfo.description;
    }

    function setFrozenStakingTime(uint256 frozenStakingTime_) external onlyPSIPadFactory {
        frozenStakingTime = frozenStakingTime_;
    }

    function setPercent(uint256 percent_) external onlyPSIPadFactory {
        percent = percent_;
    }

    function setLpToken(bool isLpToken_) external onlyPSIPadFactory {
        isLpToken = isLpToken_;
    }

}