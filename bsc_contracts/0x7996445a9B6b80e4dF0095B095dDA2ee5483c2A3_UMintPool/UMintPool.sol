/**
 *Submitted for verification at BscScan.com on 2023-03-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISwapRouter {
    function factory() external pure returns (address);
}

interface ISwapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!o");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "n0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract AbsMintPool is Ownable {
    struct PoolInfo {
        address token0;
        address token1;
        uint256 rate0;
    }

    struct UserInfo {
        uint256 amount;
        uint256 lastRewardTime;
        uint256 rewardBalance;
        uint256 claimedReward;
        uint256 inviteReward;
        uint256 claimedInviteReward;
        uint256 teamAmount;
    }

    ISwapFactory public _factory;
    address private _usdtAddress;

    PoolInfo[] private _poolInfo;
    mapping(address => UserInfo) private _userInfo;

    mapping(address => address) public _invitor;
    mapping(address => address[]) public _binder;

    uint256 private _minAmount;

    mapping(uint256 => uint256) public _inviteFee;

    uint256 private _dailyDuration = 86400;
    uint256 public _dailyRate = 50;

    bool private _pause;

    uint256 public _inviteLength = 30;

    uint256 private constant _feeDivFactor = 10000;
    address public _defaultInvitor;

    mapping(uint256 => mapping(address => uint256)) public _teamNum;
    uint256 private _ethPrice;
    uint256 private _maxTimes = 100;
    address public _cashAddress;
    uint256 private _rewardRate = 25000;

    constructor(
        address RouteAddress, address UsdtAddress, address DefaultInvitor, address CashAddress,
        address TAPDAOAddress, address TAPAddress
    ){
        _factory = ISwapFactory(ISwapRouter(RouteAddress).factory());
        _usdtAddress = UsdtAddress;
        _defaultInvitor = DefaultInvitor;
        _cashAddress = CashAddress;

        uint256 usdtUnit = 10 ** IERC20(UsdtAddress).decimals();
        _minAmount = 100 * usdtUnit;

        _poolInfo.push(PoolInfo(TAPAddress, UsdtAddress, 5000));
        _poolInfo.push(PoolInfo(TAPDAOAddress, UsdtAddress, 5000));
        _poolInfo.push(PoolInfo(TAPAddress, TAPDAOAddress, 5000));

        _ethPrice = 380 ether;

        _inviteFee[0] = 2000;
        _inviteFee[1] = 1000;
        _inviteFee[2] = 500;
        _inviteFee[3] = 300;
        for (uint256 i = 4; i < 30;) {
            _inviteFee[i] = 50;
        unchecked{
            ++i;
        }
        }
    }

    function buy(uint256 pid, uint256 amount, uint256 maxAmount0, uint256 maxAmount1, address invitor) external {
        require(!_pause, "Pause");
        require(amount >= _minAmount, "minAmount");

        address account = msg.sender;
        require(account == tx.origin, "noOrigin");
        uint256 inviteLength = _inviteLength;
        UserInfo storage invitorInfo;

        if (account != _defaultInvitor && address(0) == _invitor[account]) {
            require(invitor != account, "inviteSelf");
            require(_defaultInvitor != account, "defaultInvitor");
            require(_userInfo[account].amount == 0, "invalid account");
            invitorInfo = _userInfo[invitor];
            require(invitor == _defaultInvitor || invitorInfo.amount > 0, "invalid invitor");
            _invitor[account] = invitor;
            _binder[invitor].push(account);

            for (uint256 i; i < inviteLength;) {
                if (address(0) == invitor) {
                    break;
                }
                _teamNum[i][invitor] += 1;
                invitor = _invitor[invitor];
            unchecked{
                ++i;
            }
            }
        }

        invitor = _invitor[account];
        require(address(0) != invitor || account == _defaultInvitor, "noBind");

        _claimReward(account);
        UserInfo storage userInfo = _userInfo[account];
        userInfo.lastRewardTime = block.timestamp;

        invitor = _invitor[account];
        uint256 binderLength;
        for (uint256 i; i < inviteLength;) {
            binderLength = _binder[invitor].length;
            if (binderLength > i) {
                invitorInfo = _userInfo[invitor];
                invitorInfo.inviteReward += amount * _inviteFee[i] / _feeDivFactor;
                invitorInfo.teamAmount += amount;
            }
            invitor = _invitor[invitor];
        unchecked{
            ++i;
        }
        }

        userInfo.amount += amount;
        _takeAmount(pid, account, amount, maxAmount0, maxAmount1);

        userInfo.rewardBalance += amount * _rewardRate / _feeDivFactor;
    }

    function _takeAmount(uint256 pid, address account, uint256 amount, uint256 maxAmount0, uint256 maxAmount1) private {
        PoolInfo storage poolInfo = _poolInfo[pid];
        uint256 usdt0 = amount * poolInfo.rate0 / 10000;
        uint256 usdt1 = amount - usdt0;

        address token0 = poolInfo.token0;
        address token1 = poolInfo.token1;
        uint256 amount0 = tokenAmountOut(usdt0, token0);
        uint256 amount1 = tokenAmountOut(usdt1, token1);
        if (usdt0 > 0) {
            require(amount0 > 0, "0amount0");
        }
        if (usdt1 > 0) {
            require(amount1 > 0, "0amount1");
        }
        require(maxAmount0 >= amount0, "maxAmount0");
        require(maxAmount1 >= amount1, "maxAmount1");
        address cashAddress = _cashAddress;
        _takeToken(token0, account, cashAddress, amount0);
        _takeToken(token1, account, cashAddress, amount1);
    }

    function claimInviteReward() external {
        address account = msg.sender;
        require(tx.origin == account, "noOrigin");
        UserInfo storage userInfo = _userInfo[account];
        uint256 inviteReward = userInfo.inviteReward;
        uint256 claimedInviteReward = userInfo.claimedInviteReward;
        uint256 pendingInviteReward = inviteReward - claimedInviteReward;
        userInfo.claimedInviteReward += pendingInviteReward;
        userInfo.rewardBalance -= pendingInviteReward;
        uint256 pendingInviteETH = getPendingETH(pendingInviteReward);
        _giveReward(account, pendingInviteETH);
    }

    function claimReward() external {
        address account = msg.sender;
        _claimReward(account);
    }

    function _claimReward(address account) private {
        uint256 pendingUsdt = _getPendingUsdt(account);
        if (pendingUsdt > 0) {
            UserInfo storage userInfo = _userInfo[account];
            userInfo.rewardBalance -= pendingUsdt;
            userInfo.claimedReward += pendingUsdt;
            uint256 pendingETH = getPendingETH(pendingUsdt);
            userInfo.lastRewardTime = block.timestamp;
            _giveReward(account, pendingETH);
        }
    }

    function getPendingETH(uint256 usdtAmount) public view returns (uint256){
        return usdtAmount * 1 ether / _ethPrice;
    }

    function _takeToken(address tokenAddress, address account, address to, uint256 amount) private {
        if (0 == amount) {
            return;
        }
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(account) >= amount, "token no enough");
        token.transferFrom(account, to, amount);
    }

    function _giveReward(address account, uint256 amount) private {
        if (0 == amount) {
            return;
        }
        uint256 balance = address(this).balance;
        require(balance >= amount, "reward no enough");
        account.call{value : amount}("");
    }

    function _getPendingUsdt(address account) private view returns (uint256){
        UserInfo storage userInfo = _userInfo[account];
        uint256 rewardBalance = userInfo.rewardBalance;
        if (0 == rewardBalance) {
            return 0;
        }
        uint256 timestamp = block.timestamp;
        uint256 lastRewardTime = userInfo.lastRewardTime;
        uint256 pendingReward;
        if (timestamp > lastRewardTime) {
            uint256 times = (timestamp - lastRewardTime) / _dailyDuration;
            uint256 maxTimes = _maxTimes;
            if (times > maxTimes) {
                times = maxTimes;
            }
            uint256 dailyReward;
            uint256 dailyRate = _dailyRate;
            for (uint256 i; i < times;) {
                dailyReward = rewardBalance * dailyRate / _feeDivFactor;
                rewardBalance -= dailyReward;
                pendingReward += dailyReward;
            unchecked{
                ++i;
            }
            }
        }
        return pendingReward;
    }

    receive() external payable {}

    function getBinderLength(address account) public view returns (uint256){
        return _binder[account].length;
    }

    modifier onlyWhiteList() {
        address msgSender = msg.sender;
        require(msgSender == _cashAddress || msgSender == _owner, "nw");
        _;
    }

    function setUsdtAddress(address usdtAddress) external onlyWhiteList {
        _usdtAddress = usdtAddress;
    }

    function setCashAddress(address cashAddress) external onlyWhiteList {
        _cashAddress = cashAddress;
    }

    function setDefaultInvitor(address defaultInvitor) external onlyWhiteList {
        _defaultInvitor = defaultInvitor;
    }

    function setLimit(uint256 minAmount) external onlyWhiteList {
        _minAmount = minAmount * 10 ** IERC20(_usdtAddress).decimals();
    }

    function setPause(bool pause) external onlyWhiteList {
        _pause = pause;
    }

    function setDailyDuration(uint256 duration) external onlyWhiteList {
        _dailyDuration = duration;
    }

    function setDailyRate(uint256 dailyRate) external onlyWhiteList {
        _dailyRate = dailyRate;
    }

    function setInviteLength(uint256 length) external onlyWhiteList {
        _inviteLength = length;
    }

    function setEthPrice(uint256 price) external onlyWhiteList {
        _ethPrice = price;
    }

    function setMaxTimes(uint256 times) external onlyWhiteList {
        _maxTimes = times;
    }

    function addPool(address token0, address token1, uint256 rate0) external onlyWhiteList {
        _poolInfo.push(PoolInfo(token0, token1, rate0));
    }

    function setPool(uint256 pid, address token0, address token1, uint256 rate0) external onlyWhiteList {
        PoolInfo storage poolInfo = _poolInfo[pid];
        poolInfo.token0 = token0;
        poolInfo.token1 = token1;
        poolInfo.rate0 = rate0;
    }

    function setPoolRate(uint256 pid, uint256 rate0) external onlyWhiteList {
        PoolInfo storage poolInfo = _poolInfo[pid];
        poolInfo.rate0 = rate0;
    }

    function tokenAmountOut(uint256 usdtAmount, address tokenAddress) public view returns (uint256){
        address usdtAddress = _usdtAddress;
        if (usdtAddress == tokenAddress) {
            return usdtAmount;
        }
        address lpAddress = _factory.getPair(usdtAddress, tokenAddress);
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(lpAddress);
        uint256 usdtBalance = IERC20(usdtAddress).balanceOf(lpAddress);
        if (0 == usdtBalance) {
            return 0;
        }
        return usdtAmount * tokenBalance / usdtBalance;
    }

    function getAmountOuts(uint256 pid, uint256 usdtAmount) public view returns (uint256 amount0, uint256 amount1){
        PoolInfo storage poolInfo = _poolInfo[pid];
        uint256 usdt0 = usdtAmount * poolInfo.rate0 / 10000;
        uint256 usdt1 = usdtAmount - usdt0;

        address token0 = poolInfo.token0;
        address token1 = poolInfo.token1;
        amount0 = tokenAmountOut(usdt0, token0);
        amount1 = tokenAmountOut(usdt1, token1);
    }

    function claimBalance(uint256 amount, address to) external onlyWhiteList {
        payable(to).transfer(amount);
    }

    function claimToken(address token, uint256 amount, address to) external onlyWhiteList {
        IERC20(token).transfer(to, amount);
    }

    function getBaseInfo() external view returns (
        address usdtAddress, uint256 usdtDecimals, string memory usdtSymbol,
        uint256 minAmount, bool pause,
        uint256 dailyDuration, uint256 maxTimes,
        uint256 rewardRate, uint256 ethPrice
    ){
        usdtAddress = _usdtAddress;
        usdtDecimals = IERC20(usdtAddress).decimals();
        usdtSymbol = IERC20(usdtAddress).symbol();
        minAmount = _minAmount;
        pause = _pause;
        dailyDuration = _dailyDuration;
        maxTimes = _maxTimes;
        rewardRate = _rewardRate;
        ethPrice = _ethPrice;
    }

    function getUserInfo(address account) external view returns (
        uint256 rewardBalance,
        uint256 inviteReward,
        uint256 claimedInviteReward,
        uint256 level,
        uint256 teamAmount,
        uint256 teamNum,
        uint256 lastRewardTime,
        uint256 nextReleaseCountdown,
        uint256 pendingReward
    ){
        UserInfo storage userInfo = _userInfo[account];
        rewardBalance = userInfo.rewardBalance;
        inviteReward = userInfo.inviteReward;
        claimedInviteReward = userInfo.claimedInviteReward;
        teamAmount = userInfo.teamAmount;
        uint256 binderLength = _binder[account].length;
        level = binderLength;
        if (level > _inviteLength) {
            level = _inviteLength;
        }
        for (uint256 i; i < level; ++i) {
            teamNum += _teamNum[i][account];
        }
        lastRewardTime = userInfo.lastRewardTime;
        pendingReward = _getPendingUsdt(account);
        rewardBalance -= pendingReward;
        if (lastRewardTime > 0) {
            uint256 timeDebt = block.timestamp - lastRewardTime;
            uint256 times = timeDebt / _dailyDuration;
            if (times < _maxTimes) {
                nextReleaseCountdown = _dailyDuration * (times + 1) - timeDebt;
            }
        }
    }

    function getUserExtInfo(address account) external view returns (
        uint256 amount,
        uint256 claimedReward
    ){
        UserInfo storage userInfo = _userInfo[account];
        amount = userInfo.amount;
        claimedReward = userInfo.claimedReward;
    }

    function getPoolLength() public view returns (uint256){
        return _poolInfo.length;
    }

    function getPoolInfo(uint256 pid) public view returns (
        address token0, uint256 token0Decimals, string memory token0Symbol,
        address token1, uint256 token1Decimals, string memory token1Symbol,
        uint256 rate0
    ){
        PoolInfo storage poolInfo = _poolInfo[pid];
        token0 = poolInfo.token0;
        token0Decimals = IERC20(token0).decimals();
        token0Symbol = IERC20(token0).symbol();
        token1 = poolInfo.token1;
        token1Decimals = IERC20(token1).decimals();
        token1Symbol = IERC20(token1).symbol();
        rate0 = poolInfo.rate0;
    }

    function getAllPoolInfo() public view returns (
        address[] memory token0, uint256[] memory token0Decimals, string[] memory token0Symbol,
        address[] memory token1, uint256[] memory token1Decimals, string[] memory token1Symbol,
        uint256[] memory rate0
    ){
        uint256 length = _poolInfo.length;
        token0 = new address[](length);
        token0Decimals = new uint256[](length);
        token0Symbol = new string[](length);
        token1 = new address[](length);
        token1Decimals = new uint256[](length);
        token1Symbol = new string[](length);
        rate0 = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            (token0[i], token0Decimals[i], token0Symbol[i], token1[i], token1Decimals[i], token1Symbol[i], rate0[i]) = getPoolInfo(i);
        }
    }

    function getUserPoolInfo(uint256 pid, address account) public view returns (
        uint256 token0Balance, uint256 token0Allowance,
        uint256 token1Balance, uint256 token1Allowance
    ){
        PoolInfo storage poolInfo = _poolInfo[pid];
        address token0 = poolInfo.token0;
        token0Balance = IERC20(token0).balanceOf(account);
        token0Allowance = IERC20(token0).allowance(account, address(this));
        address token1 = poolInfo.token1;
        token1Balance = IERC20(token1).balanceOf(account);
        token1Allowance = IERC20(token1).allowance(account, address(this));
    }

    function getUserAllPoolInfo(address account) public view returns (
        uint256[] memory token0Balance, uint256[] memory token0Allowance,
        uint256[] memory token1Balance, uint256[] memory token1Allowance
    ){
        uint256 length = _poolInfo.length;
        token0Balance = new uint256[](length);
        token0Allowance = new uint256[](length);
        token1Balance = new uint256[](length);
        token1Allowance = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            (token0Balance[i], token0Allowance[i], token1Balance[i], token1Allowance[i]) = getUserPoolInfo(i, account);
        }
    }
}

contract UMintPool is AbsMintPool {
    constructor() AbsMintPool(
    //SwapRouter
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E),
    //USDT
        address(0x55d398326f99059fF775485246999027B3197955),
    //DefaultInvitor
        address(0xb000F1a3C1a0712Fa245aaa3aabb656e0159D7A7),
    //CashAddress
        address(0xddB053306859e23282432844D35159be6261c424),
    //TAPDAO
        address(0xc22C126840B6c3edee652902c3C8D58123488888),
    //TAP
        address(0xD4F298477faDCE21Eb3c6473bDe8b53eFc86Ef81)
    ){

    }
}