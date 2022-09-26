// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IFarm.sol";

contract WZDAOFarm is Ownable, ReentrancyGuard,IFarm {
    using Math for uint256;
    using SafeMath for uint256;
    using SignedMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    
    Counters.Counter private _poolIds;

    struct Pool{
        IERC20 tokenB;
        uint256 rate;
        uint256 rbase;
        bool enable;
        uint256 tokenAAmount;
        uint256 tokenBAmount;
    }

    struct Staking{
        uint256 tokenAAmount;
        uint256 tokenBAmount;
    }

    uint256 constant REWARDS_DAYS = 30 days;

    mapping(uint256=>Pool) private _pools;
    mapping(uint256=>mapping(address=>Staking)) private _stakings;
    mapping(address => bool) private _poolTokens;
    
    IERC20 public immutable tokenA;
    IERC20 public immutable wzDao;
    address public immutable defiWz;
    address public immutable defiWzWhitelist;
    uint256 public minStakingTokenAAmount;
    
    uint256 public periodFinish = 0;
    uint256 public avgRewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public totalSupply;

    mapping(address => uint256) private _userRewardPerTokenPaids;
    mapping(address => uint256) private _rewards;
    mapping(address => uint256) private _balances;

    constructor(IERC20 wzDao_,address defiWz_,address defiWzWhitelist_,uint256 minStakingTokenAAmount_) {
        wzDao = tokenA = wzDao_;
        minStakingTokenAAmount = minStakingTokenAAmount_;
        defiWz = defiWz_;
        defiWzWhitelist = defiWzWhitelist_;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
                (((lastTimeRewardApplicable() - lastUpdateTime) * getRewardRate() * 1e18) / totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return
            ((_balances[account] *
                (rewardPerToken() - _userRewardPerTokenPaids[account])) / 1e18) +
                    _rewards[account];
    }

    function getHash(address _address) public view returns (uint256) {
        return _balances[_address];
    }

    function getRewardRate()public view returns(uint256){
        return avgRewardRate.mul(totalSupply).div(1e18);
    }

    function getStaking(uint256 _pid,address _address) external view returns(Staking memory){
        return _stakings[_pid][_address];
    }

    function getPool(uint256 _pid)external view returns(Pool memory){
        return _pools[_pid];
    }

    function getPoolCount()external view returns(uint256){
        return _poolIds.current();
    }

    function stake(uint256 _pid,uint256 _amount) external updateReward(msg.sender) existsPool(_pid) nonReentrant
    {
        require(_amount>0,"The amount must be greater than 0");
        address user = msg.sender;
        Pool storage pool = _pools[_pid];
        require(pool.enable,"Pool not enable");
        uint256 tokenBAmount = _amount.mul(pool.rate).div(pool.rbase);
        require(tokenBAmount>0,"The tokenB amount must be greater than 0");
        require(pool.tokenB.balanceOf(user) >= tokenBAmount && tokenA.balanceOf(user) >= _amount,"Insufficient balance");
        require(_stakings[_pid][user].tokenAAmount.add(_amount) >= minStakingTokenAAmount,"The staking amount must be greater than minStakingTokenAAmount");

        tokenA.safeTransferFrom(user, address(this), _amount);
        _stakings[_pid][user].tokenAAmount = _stakings[_pid][user].tokenAAmount.add(_amount);
        pool.tokenAAmount = pool.tokenAAmount.add(_amount);

        uint256 payBAmount = tokenBAmount;
        if(_isDefiWz(pool.tokenB)){
            pool.tokenB.safeTransferFrom(user,defiWzWhitelist, tokenBAmount);
        }else{
            uint256 beforeBBalance = pool.tokenB.balanceOf(address(this));
            pool.tokenB.safeTransferFrom(user, address(this), tokenBAmount);
            payBAmount = pool.tokenB.balanceOf(address(this)).sub(beforeBBalance);
        }
        _stakings[_pid][user].tokenBAmount = _stakings[_pid][user].tokenBAmount.add(payBAmount);
        pool.tokenBAmount = pool.tokenBAmount.add(payBAmount);
        _stake(user, _amount);
        emit Stake(_pid,user, _amount,payBAmount);
    }

    function withdraw(uint256 _pid) external updateReward(msg.sender) existsPool(_pid) nonReentrant
    {
        address user = msg.sender;
        Pool storage pool = _pools[_pid];
        Staking storage staking = _stakings[_pid][user];
        uint256 tokenBAmount = staking.tokenBAmount;
        uint256 tokenAAmount = staking.tokenAAmount;
        staking.tokenAAmount = staking.tokenBAmount = 0;
        pool.tokenBAmount = pool.tokenBAmount.sub(tokenBAmount);
        pool.tokenAAmount = pool.tokenAAmount.sub(tokenAAmount);
        tokenA.safeTransfer(user,tokenAAmount);
        if(_isDefiWz(pool.tokenB)){
            pool.tokenB.safeTransferFrom(defiWzWhitelist, user, tokenBAmount);
        }else{
            pool.tokenB.safeTransfer(user,tokenBAmount);
        }
        _withdraw(user, tokenAAmount);
        emit Withdraw(_pid, user, tokenAAmount, tokenBAmount);
    }

    function getReward(address _user) external updateReward(_user) {
        uint256 reward = _rewards[_user];
        if (reward > 0) {
            _rewards[_user] = 0;
            wzDao.safeTransfer(_user, reward);
            emit RewardPaid(_user, reward);
        }
    }

    function _stake(address _address, uint256 _amount) private {
        totalSupply += _amount;
        _balances[_address] += _amount;
    }

    function _withdraw(address _address, uint256 _amount) private {
        totalSupply -= _amount;
        _balances[_address] -= _amount;
    }

    function _isDefiWz(IERC20 _tokenB) private view returns(bool){
        return address(_tokenB) == defiWz;
    }

    function setAvgRewardRate(uint256 _avgRewardRate)
        external
        onlyOwner
        updateReward(address(0))
    {
        avgRewardRate = _avgRewardRate;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + REWARDS_DAYS;
    }

    function setMinStakingTokenAAmount(uint256 _minStakingTokenAAmount) external onlyOwner{
        minStakingTokenAAmount = _minStakingTokenAAmount;
    }

    function createPool(IERC20 _tokenB,uint256 _rate,uint256 _rbase,bool _enable)external onlyOwner{
        require(!_poolTokens[address(_tokenB)],"Token already exists");
        _poolTokens[address(_tokenB)] = true;
        Pool memory pool = Pool(_tokenB,_rate,_rbase,_enable,0,0);
        _pools[_poolIds.current()] = pool;
        _poolIds.increment();
        emit CreatePool(_poolIds.current(), address(_tokenB), _rate, _rbase,_enable);
    }

    function updatePool(uint256 _pid,uint256 _rate,uint256 _rbase,bool _enable)external onlyOwner existsPool(_pid){
        Pool storage pool = _pools[_pid];
        pool.rate = _rate;
        pool.rbase = _rbase;
        pool.enable = _enable;
        emit UpdatePool(_pid, _rate, _rbase,_enable);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            _rewards[account] = earned(account);
            _userRewardPerTokenPaids[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier existsPool(uint256 _pid) {
        require(_pid<_poolIds.current(),"Pool not exists");
        _;
    }

    event CreatePool(uint256 id,address tokenB,uint256 rate,uint256 rbase,bool enable);
    event UpdatePool(uint256 id,uint256 rate,uint256 rbase,bool enable);
    event Stake(uint256 pid,address user, uint256 tokenAAmount,uint256 tokenBAmount);
    event Withdraw(uint256 pid,address user,uint256 tokenAAmount,uint256 tokenBAmount);
    event RewardPaid(address indexed user, uint256 reward);
}