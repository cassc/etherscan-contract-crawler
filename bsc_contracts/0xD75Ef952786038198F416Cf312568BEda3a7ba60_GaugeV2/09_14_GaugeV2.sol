// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import './interfaces/IVoter.sol';
import './interfaces/IVotingEscrow.sol';
import './interfaces/IPair.sol';
import './interfaces/IBribe.sol';
import "./libraries/Math.sol";

interface IRewarder {
    function onReward(
        uint256 pid,
        address user,
        address recipient,
        uint256 amount,
        uint256 newLpAmount
    ) external;
}


contract GaugeV2 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public isForPair;


    IERC20 public rewardToken;
    IVotingEscrow public _VE;
    IERC20 public TOKEN;

    address public DISTRIBUTION;
    address public gaugeRewarder;
    address public internal_bribe;
    address public external_bribe;
    address public fees_collector;

    uint256 public rewarderPid;
    uint256 public DURATION;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint public fees0;
    uint public fees1;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public _totalSupply;
    mapping(address => uint256) public balances;

    uint256 public derivedSupply;
    mapping(address => uint256) public derivedBalances;

    mapping(address => uint256) public tokenIds;

    event RewardAdded(uint256 reward);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 reward);
    event ClaimFees(address indexed from, uint claimed0, uint claimed1);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyDistribution() {
        require(msg.sender == DISTRIBUTION, "Caller is not RewardsDistribution contract");
        _;
    }

    constructor(address _rewardToken,address _ve,address _token,address _distribution, address _internal_bribe, address _external_bribe, address _fees_collector, bool _isForPair) {
        require(_internal_bribe == address(0) || _fees_collector == address(0), "invalid fee address");
        rewardToken = IERC20(_rewardToken);     // main reward
        _VE = IVotingEscrow(_ve);               // vested
        TOKEN = IERC20(_token);                 // underlying (LP)
        DISTRIBUTION = _distribution;           // distro address (voter)
        DURATION = 7 * 86400;                    // distro time

        internal_bribe = _internal_bribe;       // lp fees go here or to fees_collector
        external_bribe = _external_bribe;       // bribe fees go here
        fees_collector = _fees_collector;       // lp fees go here or to internal_bribe

        isForPair = _isForPair;                       // pair boolean, if false no claim_fees

    }

    ///@notice set distribution address (should be GaugeProxyL2)
    function setDistribution(address _distribution) external onlyOwner {
        require(_distribution != address(0), "zero addr");
        require(_distribution != DISTRIBUTION, "same addr");
        DISTRIBUTION = _distribution;
    }

    ///@notice set gauge rewarder address
    function setGaugeRewarder(address _gaugeRewarder) external onlyOwner {
        require(_gaugeRewarder != address(0), "zero addr");
        require(_gaugeRewarder != gaugeRewarder, "same addr");
        gaugeRewarder = _gaugeRewarder;
    }

    ///@notice set extra rewarder pid
    function setRewarderPid(uint256 _pid) external onlyOwner {
        require(_pid >= 0, "zero");
        require(_pid != rewarderPid, "same pid");
        rewarderPid = _pid;
    }

    ///@notice total supply held
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    ///@notice balance of a user
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    ///@notice last time reward
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    ///@notice  reward for a sinle token
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        } else {
            return rewardPerTokenStored.add(lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(derivedSupply));
        }
    }

    ///@notice see earned rewards for user
    function earned(address account) public view returns (uint256) {
        return derivedBalances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    ///@notice get total reward for the duration
    function rewardForDuration() external view returns (uint256) {
        return rewardRate.mul(DURATION);
    }


    ///@notice deposit all TOKEN of msg.sender
    function depositAll(uint256 tokenId) external {
        _deposit(TOKEN.balanceOf(msg.sender), msg.sender, tokenId);
    }

    ///@notice deposit amount TOKEN 
    function deposit(uint256 amount, uint256 tokenId) external {
        _deposit(amount, msg.sender, tokenId);
    }

    ///@notice deposit internal
    function _deposit(uint256 amount, address account, uint256 tokenId) internal nonReentrant updateReward(account) {
        require(amount > 0, "deposit(Gauge): cannot stake 0");

        balances[account] = balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);

        TOKEN.safeTransferFrom(account, address(this), amount);

        if (tokenId > 0) {
            require(_VE.ownerOf(tokenId) == account);
            if (tokenIds[account] == 0) {
                tokenIds[account] = tokenId;
                IVoter(_VE.voter()).attachTokenToGauge(tokenId, account);
            }
            require(tokenIds[account] == tokenId);
        } else {
            tokenId = tokenIds[account];
        }

        uint _derivedBalance = derivedBalances[account];
        derivedSupply -= _derivedBalance;
        _derivedBalance = derivedBalance(account);
        derivedBalances[account] = _derivedBalance;
        derivedSupply += _derivedBalance;

        if (address(gaugeRewarder) != address(0)) {
            IRewarder(gaugeRewarder).onReward(rewarderPid, account, account, 0, balances[account]);
        }

        emit Deposit(account, amount);
    }

    ///@notice withdraw all token
    function withdrawAll() external {
        withdraw(balances[msg.sender]);
    }

    ///@notice withdraw a certain amount of TOKEN
    function withdraw(uint256 amount) public {
        uint256 tokenId = 0;
        if (amount == balances[msg.sender]) {
            tokenId = tokenIds[msg.sender];
        }
        _withdrawToken(amount, tokenId);
    }

    ///@notice withdraw a certain amount of TOKEN
    function withdrawToken(uint256 amount, uint256 tokenId) external {
        _withdrawToken(amount, tokenId);
    }

    ///@notice withdraw internal
    function _withdrawToken(uint256 amount, uint256 tokenId) internal nonReentrant updateReward(msg.sender) {
        require(_totalSupply.sub(amount) >= 0, "supply < 0");
        require(balances[msg.sender] > 0, "no balances");

        _totalSupply = _totalSupply.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);

        if (address(gaugeRewarder) != address(0)) {
            IRewarder(gaugeRewarder).onReward(rewarderPid, msg.sender, msg.sender, 0, balances[msg.sender]);
        }

        TOKEN.safeTransfer(msg.sender, amount);

        if (tokenId > 0) {
            require(tokenId == tokenIds[msg.sender]);
            tokenIds[msg.sender] = 0;
            IVoter(_VE.voter()).detachTokenFromGauge(tokenId, msg.sender);
        } else {
            tokenId = tokenIds[msg.sender];
        }

        uint _derivedBalance = derivedBalances[msg.sender];
        derivedSupply -= _derivedBalance;
        _derivedBalance = derivedBalance(msg.sender);
        derivedBalances[msg.sender] = _derivedBalance;
        derivedSupply += _derivedBalance;

        emit Withdraw(msg.sender, amount);
    }

    function derivedBalance(address account) public view returns (uint) {
        uint _tokenId = tokenIds[account];
        uint _balance = balances[account];
        uint _derived = _balance * 40 / 100;
        uint _adjusted = 0;
        uint _supply = _VE.totalSupply();
        if (account == _VE.ownerOf(_tokenId) && _supply > 0) {
            _adjusted = _VE.balanceOfNFT(_tokenId);
            _adjusted = (_totalSupply * _adjusted / _supply) * 60 / 100;
        }
        return Math.min((_derived + _adjusted), _balance);
    }

    ///@notice withdraw all TOKEN and harvest rewardToken
    function withdrawAllAndHarvest() external {
        withdraw(balances[msg.sender]);
        getReward();
    }

    function updateDerivedBalance() external updateReward(msg.sender) {
        require(balances[msg.sender] > 0, "no balances");

        uint _derivedBalance = derivedBalances[msg.sender];
        derivedSupply -= _derivedBalance;
        _derivedBalance = derivedBalance(msg.sender);
        derivedBalances[msg.sender] = _derivedBalance;
        derivedSupply += _derivedBalance;
    }
 
    ///@notice User harvest function
    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit Harvest(msg.sender, reward);
        }

        if (gaugeRewarder != address(0)) {
            IRewarder(gaugeRewarder).onReward(rewarderPid, msg.sender, msg.sender, reward, balances[msg.sender]);
        }
    }

    function _periodFinish() external view returns (uint256) {
        return periodFinish;
    }

    /// @dev Receive rewards from distribution
    function notifyRewardAmount(address token, uint reward) external nonReentrant onlyDistribution updateReward(address(0)) {
        require(token == address(rewardToken));
        rewardToken.safeTransferFrom(DISTRIBUTION, address(this), reward);

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardToken.balanceOf(address(this));
        require(rewardRate <= balance.div(DURATION), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    function claimFees() external nonReentrant returns (uint claimed0, uint claimed1) {
        return _claimFees();
    }

     function _claimFees() internal returns (uint claimed0, uint claimed1) {
        if (!isForPair) {
            return (0, 0);
        }
        address _token = address(TOKEN);

        (claimed0, claimed1) = IPair(_token).claimFees();

        if (claimed0 > 0 || claimed1 > 0) {
            uint _fees0 = fees0 + claimed0;
            uint _fees1 = fees1 + claimed1;
            (address _token0, address _token1) = IPair(_token).tokens();

            if (_fees0  > 0) {
                fees0 = 0;
                if (fees_collector != address(0) && internal_bribe == address(0)) {
                    IERC20(_token0).safeTransfer(fees_collector, _fees0);
                } else {
                    IERC20(_token0).approve(internal_bribe, _fees0);
                    IBribe(internal_bribe).notifyRewardAmount(_token0, _fees0);
                }
            } else {
                fees0 = _fees0;
            }


            if (_fees1  > 0) {
                fees1 = 0;
                if (fees_collector != address(0) && internal_bribe == address(0)) {
                    IERC20(_token1).safeTransfer(fees_collector, _fees1);
                } else {
                    IERC20(_token1).approve(internal_bribe, _fees1);
                    IBribe(internal_bribe).notifyRewardAmount(_token1, _fees1);
                }
                
            } else {
                fees1 = _fees1;
            }


            emit ClaimFees(msg.sender, claimed0, claimed1);
        }
    }

}