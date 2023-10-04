// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract ERC20 is IERC20 {
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function name() external pure returns (string memory) {
        return "stakeLP";
    }

    function symbol() external pure returns (string memory){
        return "SLP";
    }

    function decimals() external pure returns (uint8){
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address from, address recipient, uint256 amount) private {
        emit Transfer(from, recipient, amount);
    }

    function mint(address to, uint256 amount) internal {
        _balances[to] += amount;
//        _transfer(address(0),msg.sender,to,amount);
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function allowance(address, address) external pure returns (uint256) {
        return type(uint256).max;
    }

    function approve(address, uint256) external pure returns (bool){
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){
        _transfer(sender, recipient, amount);
        return true;
    }

}

contract Distributor is Ownable {
    IERC20 public token;
    IERC20 public voucher;
    uint256 public rate;
    bool public isOpen;
    mapping(address => uint256) public redeemed;

    event Exchange(address indexed user, uint256 amount);
    // @param rate: 1:1 _rate=10000  1:0.5 _rate=5000 1:2.5 = _rate=25000
    constructor (IERC20 _voucher, IERC20 _token, uint256 _rate) {
        token = _token;
        voucher = _voucher;
        setRate(_rate);
    }

    modifier onlyOpen() {
        require(isOpen, "not open");
        _;
    }
    function setOpen() public onlyOwner {
        isOpen = !isOpen;
    }
    function setRate(uint256 _rate) public onlyOwner{
//        require(_rate < 10000 && _rate > 500, "invalid");
        rate = _rate;
    }

    function pending(address user)public view returns(uint256){
        uint256 redeem = redeemed[user];
        uint amount = voucher.balanceOf(user);
        if (amount == 0) return 0;
        if (amount < redeem) return 0;
        return (amount-redeem)*rate/ 10000;
    }

    function exchange() public onlyOpen {
        address ua = msg.sender;
        uint256 reward = pending(ua);
        require(reward > 0, "not enough reward");
        uint256 balance = token.balanceOf(address(this));
        redeemed[ua] = voucher.balanceOf(ua);
        if (balance < reward) {
            token.transfer(ua, balance);
        } else {
            token.transfer(ua, reward);
        }
        emit Exchange(ua, reward);
    }

}

contract StakeLPEarnMultiToken is Ownable, ERC20, ReentrancyGuard {
    struct PoolInfo {
        IERC20 lpToken;
        uint256 lastRewardTime;
        uint256 accPerShare;
        uint256 amount;
        uint256 referralRate;
        uint256 perSecond;
    }

    struct UserInfo {
        uint256 amount;
        address referer;
        uint256 referralAmount;
        uint256 rewardDebt;
    }
    uint256 public constant ACCURACY = 1e12;

    PoolInfo public pool;
    Distributor[] public distributors;
    mapping(address => UserInfo) public users;

    event Deposit(address indexed user, uint256 indexed amount, address indexed referer);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, address indexed tid, uint256 amount);
    event CreateDistributor(IERC20 indexed token, uint256 _rate);
    constructor(IERC20 _lpToken) {
        pool.lpToken = _lpToken;
        pool.referralRate = 20;
        pool.perSecond = 964506172839506;
        pool.lastRewardTime = block.number;
    }

    function updatePool() public {
        if (block.number <= pool.lastRewardTime) return;
//        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (pool.amount == 0) {
            pool.lastRewardTime = block.number;
            return;
        }
        uint256 multiplier = block.number - pool.lastRewardTime;
//        if (multiplier <= 0) return;

//        uint256 timeReward = multiplier * pool.perSecond;
        uint256 accShare = multiplier * pool.perSecond * ACCURACY / pool.amount;
        pool.accPerShare += accShare;
        pool.lastRewardTime = block.number;
    }

    function pending(address user) public view returns (uint256){
        UserInfo memory u = users[user];
        if (u.amount == 0) return 0;
        uint256 accPerShare = pool.accPerShare;
        if (block.number > pool.lastRewardTime) {
//            uint256 lpSupply = pool.lpToken.balanceOf(address(this));
            uint256 lpSupply = pool.amount;
            if (lpSupply != 0) {
                uint256 multiplier = block.number - pool.lastRewardTime;
                uint256 reward = multiplier * pool.perSecond;
                accPerShare += reward * ACCURACY /lpSupply;
            }
        }
        return (u.amount * accPerShare / ACCURACY) - u.rewardDebt;
    }

    function deposit(uint256 amount, address referer) external  nonReentrant{
        UserInfo storage user = users[msg.sender];
        require(referer != address(0), "referer is none");
        require(referer != msg.sender, "referer is self");
        if (user.referer == address(0)) {
            user.referer = referer;
        } else {
            require(user.referer == referer, "invalid referer");
        }
        updatePool();
        if (user.amount > 0) {
            referral(msg.sender);
        }
        if (amount > 0) {
            pool.lpToken.transferFrom(msg.sender, address(this), amount);
            user.amount += amount;
            pool.amount += amount;
        }
        user.rewardDebt = (user.amount * pool.accPerShare / ACCURACY);
        emit Deposit(msg.sender, amount, referer);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        address ua = msg.sender;
        UserInfo storage user = users[ua];
        require(user.amount >= _amount, "not enough amount");
        updatePool();
        if (user.amount > 0) {
            referral(ua);
        }
        if (_amount > 0) {
            user.amount -= _amount;
            pool.amount -= _amount;
            pool.lpToken.transfer(ua, _amount);
        }
        user.rewardDebt = user.amount * pool.accPerShare / ACCURACY;
        emit Withdraw(ua, _amount);
    }

    function referral(address user) private {
        UserInfo storage u = users[user];
        uint256 accPerShare = pool.accPerShare;
        uint256 pendingAmount = (u.amount * accPerShare / ACCURACY) - u.rewardDebt;
        require(pendingAmount > 0, "not enough reward");

        uint256 refererAmount = pendingAmount * pool.referralRate / 100;
        pendingAmount -= refererAmount;
        mint(user, pendingAmount);
        mint(u.referer, refererAmount);
        users[u.referer].referralAmount += refererAmount;
        emit Claim(user, u.referer, pendingAmount + refererAmount);
    }

    function createDistributeToken(IERC20 _token, uint256 _rate) external onlyOwner{
        Distributor distributor = new Distributor(IERC20(address(this)), _token, _rate);
        distributors.push(distributor);
        emit CreateDistributor(_token, _rate);
    }
    function poolLength() external view returns(uint256){
        return distributors.length;
    }
    function open(uint256 idx) external onlyOwner {
        distributors[idx].setOpen();
    }

    function setRate(uint256 idx, uint256 _rate) external onlyOwner {
        distributors[idx].setRate(_rate);
    }
}