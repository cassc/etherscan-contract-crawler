/**
 *Submitted for verification at Etherscan.io on 2023-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

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

contract StaticPool {
    address public _owner;
    constructor () {
        _owner = msg.sender;
    }

    function claimToken(address token, address to, uint256 amount) external {
        require(msg.sender == _owner, "!o");
        safeTransfer(token, to, amount);
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }
}

abstract contract AbsPool is Ownable {
    struct PoolInfo {
        uint256 minAmount;
        uint256 maxAmount;
        uint256 rewardRate;
        uint256 totalAmount;
        uint256 accReward;
        uint256 accPerShare;

        uint256 lastStaticPoolRewardTime;
        uint256 staticPoolRewardRate;
        uint256 staticPoolRewardDuration;
    }

    struct UserInfo {
        bool active;
        uint256 totalAmount;
        uint256 totalReward;
        uint256 teamAmount;

        uint256 invitorReward;
        uint256 linkReward;
        uint256 teamReward;
        uint256 worldReward;
        uint256 poolReward;
        uint256 claimedReward;
    }

    struct UserPoolInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct LevelPoolInfo {
        uint256 totalAmount;
        uint256 accReward;
        uint256 accPerShare;
    }

    struct UserLevelPoolInfo {
        uint256 level;
        uint256 rewardDebt;
    }

    PoolInfo private _poolInfo;

    mapping(address => UserInfo) private _userInfo;
    mapping(address => UserPoolInfo) private _userPoolInfo;

    mapping(uint256 => LevelPoolInfo) private _levelPoolInfo;
    mapping(address => UserLevelPoolInfo) private _userLevelPoolInfo;

    address private _tokenAddress;

    uint256 private constant _maxLevel = 9;
    mapping(uint256 => uint256) public _teamRewardRate;
    mapping(uint256 => uint256) public _teamRewardCondition;
    mapping(uint256 => uint256) public _inviteRewardCondition;
    mapping(uint256 => uint256) public _worldLevelPoolRate;

    uint256 public _backRate = 2100;
    uint256 public _poolRate = 1500;
    uint256 public _invitorRate = 1000;
    uint256 public _linkRate = 50;
    uint256 public _staticRate = 1000;
    uint256 public _worldLevelRate = 1400;

    mapping(address => address) public _invitor;
    mapping(address => address[]) public _binder;
    mapping(address => uint256) private _teamNum;
    uint256 private constant _invitorLen = 20;

    address private _defaultInvitor;
    uint256 private _accAmount;
    uint256 public _claimFee = 500;

    StaticPool public immutable _staticPool;
    address public _specialAddress;
    bool public _start;

    constructor(
        address TokenAddress, address DefaultInvitor, address SpecialAddress
    ){
        _tokenAddress = TokenAddress;
        _defaultInvitor = DefaultInvitor;
        _specialAddress = SpecialAddress;

        uint256 tokenUnit = 10 ** IERC20(TokenAddress).decimals();
        _teamRewardRate[1] = 100;
        _teamRewardRate[2] = 200;
        _teamRewardRate[3] = 400;
        _teamRewardRate[4] = 600;
        _teamRewardRate[5] = 800;
        _teamRewardRate[6] = 1100;
        _teamRewardRate[7] = 1400;
        _teamRewardRate[8] = 1700;
        _teamRewardRate[9] = 2000;

        _worldLevelPoolRate[1] = 0;
        _worldLevelPoolRate[2] = 0;
        _worldLevelPoolRate[3] = 500;
        _worldLevelPoolRate[4] = 300;
        _worldLevelPoolRate[5] = 200;
        _worldLevelPoolRate[6] = 100;
        _worldLevelPoolRate[7] = 100;
        _worldLevelPoolRate[8] = 100;
        _worldLevelPoolRate[9] = 100;

        _teamRewardCondition[1] = 5000 * tokenUnit;
        _teamRewardCondition[2] = 10000 * tokenUnit;
        _teamRewardCondition[3] = 20000 * tokenUnit;
        _teamRewardCondition[4] = 40000 * tokenUnit;
        _teamRewardCondition[5] = 80000 * tokenUnit;
        _teamRewardCondition[6] = 160000 * tokenUnit;
        _teamRewardCondition[7] = 320000 * tokenUnit;
        _teamRewardCondition[8] = 640000 * tokenUnit;
        _teamRewardCondition[9] = 1280000 * tokenUnit;

        uint256 c = 20000 * tokenUnit;
        for (uint256 i; i < _invitorLen; ++i) {
            if (i == 5) {
                c = 100000 * tokenUnit;
            } else if (i == 10) {
                c = 300000 * tokenUnit;
            }
            _inviteRewardCondition[i] = c;
        }

        _userInfo[DefaultInvitor].active = true;

        _poolInfo.minAmount = 1000 * tokenUnit;
        _poolInfo.maxAmount = 1000000000000 * tokenUnit;
        _poolInfo.rewardRate = 30000;
        _poolInfo.staticPoolRewardRate = 1000;
        _poolInfo.staticPoolRewardDuration = 1 days;

        _staticPool = new StaticPool();
    }

    function join(uint256 amount, address invitor) external {
        require(_start, "nStart");
        PoolInfo storage poolInfo = _poolInfo;
        require(amount >= poolInfo.minAmount, "min");
        require(amount <= poolInfo.maxAmount, "max");
        address account = msg.sender;
        require(tx.origin == account, "origin");
        address tokenAddress = _tokenAddress;
        require(IERC20(tokenAddress).balanceOf(account) >= amount, "BNE");

        UserInfo storage userInfo = _userInfo[account];
        if (!userInfo.active) {
            require(_userInfo[invitor].active, "invalid invitor");
            _invitor[account] = invitor;
            _binder[invitor].push(account);
            for (uint256 i; i < _invitorLen;) {
                _teamNum[invitor] += 1;
                invitor = _invitor[invitor];
                if (address(0) == invitor) {
                    break;
                }
            unchecked{
                ++i;
            }
            }
            userInfo.active = true;
        }

        address specialAddress = _specialAddress;
        uint256 backAmount = amount * _backRate / 10000;
        _takeToken(tokenAddress, account, address(this), amount - backAmount);
        claimReward(account);

        uint256 specialAmount = _calPoolReward(amount * _poolRate / 10000);
        _giveToken(tokenAddress, specialAddress, specialAmount);
        _calUserPoolReward(account);

        poolInfo.totalAmount += amount;
        _accAmount += amount;
        userInfo.totalAmount += amount;

        specialAmount = _calTeamReward(account, amount);
        _giveToken(tokenAddress, specialAddress, specialAmount);

        specialAmount = _calWorldReward(amount * _worldLevelRate / 10000, amount);
        _giveToken(tokenAddress, specialAddress, specialAmount);

        specialAmount = _calInviteReward(account, amount);
        _giveToken(tokenAddress, specialAddress, specialAmount);

        invitor = _invitor[account];
        _userInfo[invitor].invitorReward += amount * _invitorRate / 10000;

        UserPoolInfo storage userPoolInfo = _userPoolInfo[account];
        userPoolInfo.amount += amount;
        userPoolInfo.rewardDebt = userPoolInfo.amount * poolInfo.accPerShare / 1e18;
        userInfo.totalReward += amount * poolInfo.rewardRate / 10000;

        _giveToken(tokenAddress, address(_staticPool), amount * _staticRate / 10000);
    }

    function _calStaticPoolReward(address tokenAddress) private {
        uint256 nowTime = block.timestamp;
        uint256 lastStaticPoolRewardTime = _poolInfo.lastStaticPoolRewardTime;
        if (0 == lastStaticPoolRewardTime) {
            _poolInfo.lastStaticPoolRewardTime = nowTime;
            return;
        }
        if (nowTime < lastStaticPoolRewardTime + _poolInfo.staticPoolRewardDuration) {
            return;
        }
        _poolInfo.lastStaticPoolRewardTime = nowTime;

        IERC20 token = IERC20(tokenAddress);
        StaticPool staticPool = _staticPool;
        uint256 balance = token.balanceOf(address(staticPool));
        uint256 reward = balance * _poolInfo.staticPoolRewardRate / 10000;
        staticPool.claimToken(tokenAddress, address(this), reward);
        uint256 specialAmount = _calPoolReward(reward);
        _giveToken(tokenAddress, _specialAddress, specialAmount);
    }

    function _calUserPoolReward(address account) private {
        UserInfo storage userInfo = _userInfo[account];
        UserPoolInfo storage userPoolInfo = _userPoolInfo[account];
        uint256 amount;
        PoolInfo storage poolInfo = _poolInfo;
        uint256 totalReward;
        uint256 pendingReward;
        amount = userPoolInfo.amount;
        if (amount > 0) {
            totalReward = amount * poolInfo.accPerShare / 1e18;
            pendingReward = totalReward - userPoolInfo.rewardDebt;
            if (pendingReward > 0) {
                userInfo.poolReward += pendingReward;
                userPoolInfo.rewardDebt = totalReward;
            }
        }
    }

    function _calUserLevelPoolReward(address account) private {
        UserInfo storage userInfo = _userInfo[account];
        UserLevelPoolInfo storage userLevelPoolInfo = _userLevelPoolInfo[account];
        uint256 level = userLevelPoolInfo.level;
        if (0 == level) {
            return;
        }
        LevelPoolInfo storage levelPoolInfo = _levelPoolInfo[level];
        uint256 totalReward = levelPoolInfo.accPerShare / 1e18;
        uint256 pendingReward = totalReward - userLevelPoolInfo.rewardDebt;
        if (pendingReward > 0) {
            userInfo.worldReward += pendingReward;
            userLevelPoolInfo.rewardDebt = totalReward;
        }
    }

    function _calInviteReward(address account, uint256 perAmount) private returns (uint256 specialAmount){
        uint256 inviteAmount = perAmount * _linkRate / 10000;
        specialAmount = inviteAmount * _invitorLen;

        address current = account;
        address invitor;
        UserInfo storage invitorInfo;
        for (uint256 i; i < _invitorLen;) {
            invitor = _invitor[current];
            if (address(0) == invitor) {
                break;
            }
            invitorInfo = _userInfo[invitor];
            //teamAmount
            uint256 teamAmount = invitorInfo.teamAmount;
            teamAmount += perAmount;
            invitorInfo.teamAmount = teamAmount;
            //TeamLevel
            UserLevelPoolInfo storage userLevelPoolInfo = _userLevelPoolInfo[invitor];
            uint256 preLevel = userLevelPoolInfo.level;
            uint256 curLevel = _getTeamLevel(invitor);
            if (preLevel != curLevel) {
                if (preLevel > 0) {
                    _calUserLevelPoolReward(invitor);
                    _levelPoolInfo[preLevel].totalAmount -= 1;
                }
                userLevelPoolInfo.level = curLevel;
                userLevelPoolInfo.rewardDebt = _levelPoolInfo[curLevel].accPerShare / 1e18;
                if (curLevel > 0) {
                    _levelPoolInfo[curLevel].totalAmount += 1;
                }
            }
            if (invitorInfo.totalAmount >= _inviteRewardCondition[i]) {
                invitorInfo.linkReward += inviteAmount;
                specialAmount -= inviteAmount;
            }
            current = invitor;
        unchecked{
            ++i;
        }
        }
    }

    function _calPoolReward(uint256 totalReward) private returns (uint256 remainReward){
        remainReward = totalReward;
        if (totalReward > 0) {
            PoolInfo storage poolInfo = _poolInfo;
            uint256 poolAmount = poolInfo.totalAmount;
            if (poolAmount > 0) {
                remainReward = 0;
                uint256 poolReward = totalReward;
                poolInfo.accReward += poolReward;
                poolInfo.accPerShare += poolReward * 1e18 / poolAmount;
            }
        }
    }

    function _calWorldReward(
        uint256 totalReward, uint256 joinAmount
    ) private returns (uint256 remainReward){
        remainReward = totalReward;
        LevelPoolInfo storage levelPoolInfo;
        for (uint256 i = 1; i <= _maxLevel;) {
            levelPoolInfo = _levelPoolInfo[i];
            uint256 amount = levelPoolInfo.totalAmount;
            if (amount > 0) {
                uint256 reward = joinAmount * _worldLevelPoolRate[i] / 10000;
                if (reward > 0) {
                    levelPoolInfo.accReward += reward;
                    levelPoolInfo.accPerShare += reward * 1e18 / amount;
                    remainReward -= reward;
                }
            }
        unchecked{
            ++i;
        }
        }
    }

    function _calTeamReward(
        address current, uint256 perAmount
    ) private returns (uint256 teamTotalReward){
        teamTotalReward = _teamRewardRate[_maxLevel] * perAmount / 10000;
        uint256 lastRewardLevel;
        uint256 teamLevel;
        uint256 teamReward;
        address invitor;
        uint256 rewardRate;
        for (uint256 i; i < _invitorLen; ++i) {
            invitor = _invitor[current];
            if (address(0) == invitor) {
                break;
            }
            current = invitor;
            teamLevel = _getTeamLevel(invitor);
            if (teamLevel <= lastRewardLevel) {
                continue;
            }
            rewardRate = _teamRewardRate[teamLevel] - _teamRewardRate[lastRewardLevel];
            teamReward = rewardRate * perAmount / 10000;
            _userInfo[invitor].teamReward += teamReward;
            teamTotalReward -= teamReward;
            lastRewardLevel = teamLevel;
        }
    }

    function _getTeamLevel(
        address invitor
    ) private view returns (uint256){
        uint256 teamAmount = _userInfo[invitor].teamAmount;
        uint256 max = _maxLevel + 1;
        for (uint256 i = 1; i < max;) {
            if (teamAmount < _teamRewardCondition[i]) {
                return i - 1;
            }
        unchecked{
            ++i;
        }
        }
        return _maxLevel;
    }

    function _takeToken(address tokenAddress, address account, address to, uint256 amount) private {
        if (0 < amount) {
            safeTransferFrom(tokenAddress, account, to, amount);
        }
    }

    function _giveToken(address tokenAddress, address account, uint256 amount) private {
        if (0 < amount) {
            safeTransfer(tokenAddress, account, amount);
        }
    }

    function claimReward(address account) public {
        address tokenAddress = _tokenAddress;
        _calStaticPoolReward(tokenAddress);
        _calUserPoolReward(account);
        _calUserLevelPoolReward(account);
        UserInfo storage userInfo = _userInfo[account];
        uint256 pendingReward = userInfo.teamReward + userInfo.poolReward + userInfo.linkReward + userInfo.worldReward + userInfo.invitorReward;
        if (pendingReward > 0) {
            uint256 maxReward = userInfo.totalReward - userInfo.claimedReward;
            uint256 specialAmount;
            if (pendingReward > maxReward) {
                specialAmount = pendingReward - maxReward;
                pendingReward = maxReward;
            }
            userInfo.claimedReward += pendingReward;
            userInfo.teamReward = 0;
            userInfo.poolReward = 0;
            userInfo.linkReward = 0;
            userInfo.worldReward = 0;
            userInfo.invitorReward = 0;

            address specialAddress = _specialAddress;
            _giveToken(tokenAddress, _specialAddress, specialAmount);

            uint256 claimFeeAmount = pendingReward * _claimFee / 10000;
            _giveToken(tokenAddress, account, pendingReward - claimFeeAmount);
            _giveToken(tokenAddress, specialAddress, claimFeeAmount);

            uint256 amount = pendingReward * 10000 / _poolInfo.rewardRate;

            if (pendingReward == maxReward) {
                UserPoolInfo storage userPoolInfo = _userPoolInfo[account];
                _poolInfo.totalAmount -= userPoolInfo.amount;
                userPoolInfo.amount = 0;
                userPoolInfo.rewardDebt = 0;
            }

            address current = account;
            address invitor;
            UserInfo storage invitorInfo;
            for (uint256 i; i < _invitorLen;) {
                invitor = _invitor[current];
                if (address(0) == invitor) {
                    break;
                }
                invitorInfo = _userInfo[invitor];
                //teamAmount
                uint256 teamAmount = invitorInfo.teamAmount;
                if (teamAmount > amount) {
                    teamAmount -= amount;
                } else {
                    teamAmount = 0;
                }
                invitorInfo.teamAmount = teamAmount;
                //TeamLevel
                UserLevelPoolInfo storage invitorLevelPoolInfo = _userLevelPoolInfo[invitor];
                uint256 preLevel = invitorLevelPoolInfo.level;
                uint256 curLevel = _getTeamLevel(invitor);
                if (preLevel != curLevel) {
                    if (preLevel > 0) {
                        _calUserLevelPoolReward(invitor);
                        _levelPoolInfo[preLevel].totalAmount -= 1;
                    }
                    invitorLevelPoolInfo.level = curLevel;
                    invitorLevelPoolInfo.rewardDebt = _levelPoolInfo[curLevel].accPerShare / 1e18;
                    if (curLevel > 0) {
                        _levelPoolInfo[curLevel].totalAmount += 1;
                    }
                }
                current = invitor;
            unchecked{
                ++i;
            }
            }
        }
    }

    function claimBalance(address to, uint256 amount) external onlyOwner {
        safeTransferETH(to, amount);
    }

    function claimToken(address erc20Address, address to, uint256 amount) external onlyOwner {
        safeTransfer(erc20Address, to, amount);
    }

    function claimStaticPoolToken(address erc20Address, address to, uint256 amount) external onlyOwner {
        _staticPool.claimToken(erc20Address, to, amount);
    }

    function getBinderLength(address account) external view returns (uint256){
        return _binder[account].length;
    }

    function getBaseInfo() external view returns (
        address tokenAddress, uint256 tokenDecimals, string memory tokenSymbol,
        address defaultInvitor, uint256 accAmount, uint256 blockTime,
        uint256 staticPoolBalance
    ){
        tokenAddress = _tokenAddress;
        tokenDecimals = IERC20(tokenAddress).decimals();
        tokenSymbol = IERC20(tokenAddress).symbol();
        defaultInvitor = _defaultInvitor;
        accAmount = _accAmount;
        blockTime = block.timestamp;
        staticPoolBalance = IERC20(tokenAddress).balanceOf(address(_staticPool));
    }

    function getPoolInfo() public view returns (
        uint256 minAmount,
        uint256 maxAmount,
        uint256 rewardRate,
        uint256 totalAmount,
        uint256 accReward,
        uint256 accPerShare,
        uint256 lastStaticPoolRewardTime,
        uint256 staticPoolRewardRate,
        uint256 staticPoolRewardDuration
    ){
        PoolInfo storage poolInfo = _poolInfo;
        minAmount = poolInfo.minAmount;
        maxAmount = poolInfo.maxAmount;
        rewardRate = poolInfo.rewardRate;
        totalAmount = poolInfo.totalAmount;
        accReward = poolInfo.accReward;
        accPerShare = poolInfo.accPerShare;
        lastStaticPoolRewardTime = poolInfo.lastStaticPoolRewardTime;
        staticPoolRewardRate = poolInfo.staticPoolRewardRate;
        staticPoolRewardDuration = poolInfo.staticPoolRewardDuration;
    }

    function getAllLevelPoolInfo() public view returns (
        uint256[] memory totalAmount,
        uint256[] memory accReward,
        uint256[] memory accPerShare
    ){
        uint256 len = _maxLevel + 1;
        totalAmount = new uint256[](len);
        accReward = new uint256[](len);
        accPerShare = new uint256[](len);
        for (uint256 i = 1; i < len; ++i) {
            (totalAmount[i], accReward[i], accPerShare[i]) = getLevelPoolInfo(i);
        }
    }

    function getLevelPoolInfo(uint256 l) public view returns (
        uint256 totalAmount,
        uint256 accReward,
        uint256 accPerShare
    ){
        LevelPoolInfo storage levelPoolInfo = _levelPoolInfo[l];
        totalAmount = levelPoolInfo.totalAmount;
        accReward = levelPoolInfo.accReward;
        accPerShare = levelPoolInfo.accPerShare;
    }

    function getUserPoolInfo(address account) public view returns (
        uint256 amount,
        uint256 rewardDebt
    ){
        UserPoolInfo storage userPoolInfo = _userPoolInfo[account];
        amount = userPoolInfo.amount;
        rewardDebt = userPoolInfo.rewardDebt;
    }

    function getUserPoolPendingReward(address account) public view returns (uint256 pendingReward){
        UserPoolInfo storage userPoolInfo = _userPoolInfo[account];
        uint256 amount = userPoolInfo.amount;
        if (amount > 0) {
            pendingReward = userPoolInfo.amount * _poolInfo.accPerShare / 1e18 - userPoolInfo.rewardDebt;
        }
    }

    function getUserLevelPoolPendingReward(address account) public view returns (uint256 pendingReward){
        UserLevelPoolInfo storage userLevelPoolInfo = _userLevelPoolInfo[account];
        uint256 level = userLevelPoolInfo.level;
        if (level > 0) {
            pendingReward = _levelPoolInfo[level].accPerShare / 1e18 - userLevelPoolInfo.rewardDebt;
        }
    }

    function getUserPoolPendingCalReward(address account) public view returns (uint256 pendingReward){
        UserPoolInfo storage userPoolInfo = _userPoolInfo[account];
        uint256 amount = userPoolInfo.amount;
        if (amount > 0) {
            IERC20 token = IERC20(_tokenAddress);
            uint256 balance = token.balanceOf(address(_staticPool));
            uint256 reward = balance * _poolInfo.staticPoolRewardRate / 10000;
            pendingReward = amount * reward / _poolInfo.totalAmount;
        }
    }

    function getUserInfo(address account) public view returns (
        uint256 totalAmount,
        uint256 totalReward,
        uint256 invitorReward,
        uint256 linkReward,
        uint256 teamReward,
        uint256 worldReward,
        uint256 poolReward,
        uint256 claimedReward,
        uint256 tokenBalance,
        uint256 tokenAllowance,
        uint256 pendingCalPoolReward
    ){
        UserInfo storage userInfo = _userInfo[account];
        totalAmount = userInfo.totalAmount;
        totalReward = userInfo.totalReward;
        invitorReward = userInfo.invitorReward;
        linkReward = userInfo.linkReward;
        teamReward = userInfo.teamReward;
        worldReward = userInfo.worldReward + getUserLevelPoolPendingReward(account);
        poolReward = userInfo.poolReward + getUserPoolPendingReward(account);
        claimedReward = userInfo.claimedReward;
        tokenBalance = IERC20(_tokenAddress).balanceOf(account);
        tokenAllowance = IERC20(_tokenAddress).allowance(account, address(this));
        pendingCalPoolReward = getUserPoolPendingCalReward(account);
    }

    function getUserTeamInfo(address account) public view returns (
        bool active,
        uint256 teamNum,
        uint256 teamAmount,
        address invitor,
        uint256 inviteLevel,
        uint256 teamLevel
    ){
        UserInfo storage userInfo = _userInfo[account];
        active = userInfo.active;
        inviteLevel = _getInviteLevel(account);
        teamLevel = _getTeamLevel(account);
        teamNum = _teamNum[account];
        teamAmount = userInfo.teamAmount;
        invitor = _invitor[account];
    }

    function getUserOriginInfo(address account) public view returns (
        uint256 poolReward,
        uint256 worldReward
    ){
        UserInfo storage userInfo = _userInfo[account];
        poolReward = userInfo.poolReward;
        worldReward = userInfo.worldReward;
    }

    function _getInviteLevel(
        address invitor
    ) private view returns (uint256){
        uint256 totalAmount = _userInfo[invitor].totalAmount;
        for (uint256 i = _invitorLen - 1; i > 0;) {
            if (totalAmount >= _inviteRewardCondition[i]) {
                return i + 1;
            }
        unchecked{
            --i;
        }
        }
        return 0;
    }

    function setSpecialAddress(address adr) external onlyOwner {
        _specialAddress = adr;
    }

    function setTokenAddress(address adr) external onlyOwner {
        _tokenAddress = adr;
    }

    function setDefaultInvitor(address adr) external onlyOwner {
        _defaultInvitor = adr;
        _userInfo[adr].active = true;
    }

    function enableStart(bool enable) external onlyOwner {
        _start = enable;
    }

    function setMinAmount(uint256 m) external onlyOwner {
        _poolInfo.minAmount = m;
    }

    function setMaxAmount(uint256 m) external onlyOwner {
        _poolInfo.maxAmount = m;
    }

    function setStaticPoolRewardDuration(uint256 d) external onlyOwner {
        _poolInfo.staticPoolRewardDuration = d;
    }

    function setStaticPoolRewardRate(uint256 r) external onlyOwner {
        _poolInfo.staticPoolRewardRate = r;
    }

    function setWorldRate(uint256 rate) external onlyOwner maxRate {
        _worldLevelRate = rate;
    }

    function setPoolRate(uint256 rate) external onlyOwner maxRate {
        _poolRate = rate;
    }

    function setStaticRate(uint256 rate) external onlyOwner maxRate {
        _staticRate = rate;
    }

    function setLinkRate(uint256 rate) external onlyOwner maxRate {
        _linkRate = rate;
    }

    function setInvitorRate(uint256 rate) external onlyOwner maxRate {
        _invitorRate = rate;
    }

    function setBackRate(uint256 rate) external onlyOwner maxRate {
        _backRate = rate;
    }

    function setTeamRate(uint256 i, uint256 rate) external onlyOwner maxRate {
        _teamRewardRate[i] = rate;
    }

    function setLevelPoolRate(uint256 l, uint256 rate) external onlyOwner {
        _worldLevelPoolRate[l] = rate;
        uint256 totalRate;
        for (uint256 i = 1; i < _maxLevel + 1; ++i) {
            totalRate += _worldLevelPoolRate[i];
        }
        require(totalRate <= _worldLevelRate, "max");
    }

    function setTeamRewardCondition(uint256 i, uint256 c) external onlyOwner {
        _teamRewardCondition[i] = c;
    }

    function setTeamRewardConditionUnit(uint256 i, uint256 c) external onlyOwner {
        _teamRewardCondition[i] = c * 10 ** IERC20(_tokenAddress).decimals();
    }

    function batchSetTeamRewardConditionUnit(uint256[] memory ls, uint256[] memory cs) external onlyOwner {
        uint256 len = ls.length;
        uint256 tokenUnit = 10 ** IERC20(_tokenAddress).decimals();
        for (uint256 i; i < len;) {
            uint256 l = ls[i];
            _teamRewardCondition[l] = cs[i] * tokenUnit;
        unchecked{
            ++i;
        }
        }
    }

    function getTeamRewardConditionUnit() public view returns (uint256[] memory cs) {
        uint256 len = _maxLevel;
        cs = new uint256[](len);
        uint256 tokenUnit = 10 ** IERC20(_tokenAddress).decimals();
        for (uint256 i; i < len; ++i) {
            cs[i] = _teamRewardCondition[i + 1] / tokenUnit;
        }
    }

    function setInviteRewardCondition(uint256 i, uint256 c) external onlyOwner {
        _inviteRewardCondition[i] = c;
    }

    function setInviteRewardConditionUnit(uint256 i, uint256 c) external onlyOwner {
        _inviteRewardCondition[i] = c * 10 ** IERC20(_tokenAddress).decimals();
    }

    function setClaimFee(uint256 f) external onlyOwner {
        _claimFee = f;
    }

    modifier maxRate(){
        _;
        require(_teamRewardRate[_maxLevel] + _invitorRate + _linkRate * _invitorLen + _backRate + _poolRate + _worldLevelRate + _staticRate <= 10000, "M W");
    }

    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'AF');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'ETF');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TFF');
    }

    function batchSetInvitor(address[] memory accounts, address[] memory invitors) public onlyAdmin {
        uint256 len = accounts.length;
        address account;
        address invitor;
        for (uint256 i; i < len;) {
            account = accounts[i];
            invitor = invitors[i];
            _userInfo[account].active = true;
            _userInfo[invitor].active = true;
            _invitor[account] = invitor;
            _binder[invitor].push(account);
        unchecked{
            ++i;
        }
        }
    }

    function batchJoin(address[] memory accounts, uint256[] memory amounts) public onlyAdmin {
        require(0 == _poolInfo.lastStaticPoolRewardTime, "started");
        uint256 len = accounts.length;
        uint256 rewardRate = _poolInfo.rewardRate;
        address account;
        uint256 amount;
        for (uint256 i; i < len;) {
            account = accounts[i];
            UserInfo storage userInfo = _userInfo[account];
            if (!userInfo.active) {
                userInfo.active = true;
            }
            if (0 == userInfo.totalAmount) {
                amount = amounts[i];
                _accAmount += amount;
                _poolInfo.totalAmount += amount;
                userInfo.totalAmount = amount;
                userInfo.totalReward = amount * rewardRate / 10000;
                _userPoolInfo[account].amount = amount;
                _calTeamAmount(account, amount);
            }
        unchecked{
            ++i;
        }
        }
    }

    function _calTeamAmount(address account, uint256 perAmount) private {
        address current = account;
        address invitor;
        UserInfo storage invitorInfo;
        for (uint256 i; i < _invitorLen;) {
            invitor = _invitor[current];
            if (address(0) == invitor) {
                break;
            }
            invitorInfo = _userInfo[invitor];
            //teamAmount
            uint256 teamAmount = invitorInfo.teamAmount;
            teamAmount += perAmount;
            invitorInfo.teamAmount = teamAmount;
            //TeamLevel
            UserLevelPoolInfo storage userLevelPoolInfo = _userLevelPoolInfo[invitor];
            uint256 preLevel = userLevelPoolInfo.level;
            uint256 curLevel = _getTeamLevel(invitor);
            if (preLevel != curLevel) {
                if (preLevel > 0) {
                    _levelPoolInfo[preLevel].totalAmount -= 1;
                }
                userLevelPoolInfo.level = curLevel;
                if (curLevel > 0) {
                    _levelPoolInfo[curLevel].totalAmount += 1;
                }
            }
            current = invitor;
        unchecked{
            ++i;
        }
        }
    }

    mapping(address => bool) public _admin;

    function setAdmin(address a, bool e) public onlyOwner {
        _admin[a] = e;
    }
    modifier onlyAdmin() {
        require(_admin[msg.sender] || msg.sender == _owner, "!admin");
        _;
    }

    function minusReward(address account, uint256 reward) public onlyAdmin {
        _calStaticPoolReward(_tokenAddress);
        _calUserPoolReward(account);
        _calUserLevelPoolReward(account);
        UserInfo storage userInfo = _userInfo[account];
        uint256 pendingReward = reward;
        if (pendingReward > 0) {
            uint256 maxReward = userInfo.totalReward - userInfo.claimedReward;
            require(maxReward >= pendingReward, ">max");
            userInfo.claimedReward += pendingReward;

            uint256 amount = pendingReward * 10000 / _poolInfo.rewardRate;
            if (pendingReward == maxReward) {
                UserPoolInfo storage userPoolInfo = _userPoolInfo[account];
                _poolInfo.totalAmount -= userPoolInfo.amount;
                userPoolInfo.amount = 0;
                userPoolInfo.rewardDebt = 0;
            }

            address current = account;
            address invitor;
            UserInfo storage invitorInfo;
            for (uint256 i; i < _invitorLen;) {
                invitor = _invitor[current];
                if (address(0) == invitor) {
                    break;
                }
                invitorInfo = _userInfo[invitor];
                //teamAmount
                uint256 teamAmount = invitorInfo.teamAmount;
                if (teamAmount > amount) {
                    teamAmount -= amount;
                } else {
                    teamAmount = 0;
                }
                invitorInfo.teamAmount = teamAmount;
                //TeamLevel
                UserLevelPoolInfo storage invitorLevelPoolInfo = _userLevelPoolInfo[invitor];
                uint256 preLevel = invitorLevelPoolInfo.level;
                uint256 curLevel = _getTeamLevel(invitor);
                if (preLevel != curLevel) {
                    if (preLevel > 0) {
                        _calUserLevelPoolReward(invitor);
                        _levelPoolInfo[preLevel].totalAmount -= 1;
                    }
                    invitorLevelPoolInfo.level = curLevel;
                    invitorLevelPoolInfo.rewardDebt = _levelPoolInfo[curLevel].accPerShare / 1e18;
                    if (curLevel > 0) {
                        _levelPoolInfo[curLevel].totalAmount += 1;
                    }
                }
                current = invitor;
            unchecked{
                ++i;
            }
            }
        }
    }
}

contract DhxPool is AbsPool {
    constructor() AbsPool(
    //Token
        address(0x5Ca381bBfb58f0092df149bD3D243b08B9a8386e),
    //DefaultInvitor
        address(0x1D85c3E9b365be6d0257F3eFf07eE4b4d4906e19),
    //Special
        address(0x1D85c3E9b365be6d0257F3eFf07eE4b4d4906e19)
    ){

    }
}