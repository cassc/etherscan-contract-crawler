/**
 *Submitted for verification at BscScan.com on 2023-01-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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
        require(_owner == msg.sender, "!ow");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "n 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ISwapPair {
    function sync() external;
}

abstract contract AbsPool is Ownable {
    struct PoolInfo {
        uint256 queueReward;
        uint256 poolReward;
        address[] accounts;
        uint256[] accountTimes;
        uint256 rewardTime;
        uint256 queueLen;
        uint256 queueRewardIndex;
        uint256 accPoolReward;
    }

    struct UserInfo {
        uint256 queueUsdtReward;
        uint256 poolUsdtReward;
        uint256 inviteUsdtReward;
        uint256 tokenReward;
        bool active;
        uint256 claimedToken;
    }

    uint256 public _poolLen = 7;
    mapping(uint256 => bool) public _poolStart;
    mapping(uint256 => uint256) public _poolId;
    mapping(uint256 => mapping(uint256 => PoolInfo)) private _poolInfo;
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public _userPoolJoin;

    mapping(address => UserInfo) private _userInfo;

    address private _usdtAddress;
    address private _tokenAddress;
    uint256 private _perUsdtAmount;

    uint256 public _perTokenAmount;
    uint256 public _refreshDuration = 3 hours;
    uint256 public _refreshAmount;

    uint256 public _queueRewardLen = 3;
    uint256 public _queueRewardRate = 5000;
    uint256 public _poolRewardRate = 3000;
    uint256 public _buybackRate = 1200;
    uint256 public _projectRate = 500;
    uint256 public _dividendRate = 300;

    uint256 public _lastRewardRate = 7000;
    uint256 public _inviteRewardRate = 2000;

    address public _tokenLPPair;

    mapping(address => address) public _invitor;
    mapping(address => address[]) public _binder;
    mapping(address => uint256) public _teamNum;

    address[] private _projectAddress;
    address[] private _dividendAddress;

    uint256 public _showAccountLen = 3;

    uint256 public _totalProjectUsdt;
    uint256 public _totalDividendUsdt;
    bool public _calProjectAndDividend = true;

    uint256 public _inviteRewardToken;
    uint256 public _inviteRewardToken2;

    constructor(address USDTAddress, address TokenAddress, address TokenLPPair){
        _tokenLPPair = TokenLPPair;
        _usdtAddress = USDTAddress;
        _tokenAddress = TokenAddress;

        uint256 usdtUnit = 10 ** IERC20(USDTAddress).decimals();
        _perUsdtAmount = 100 * usdtUnit;
        _refreshAmount = 5000 * usdtUnit;

        uint256 tokenUnit = 10 ** IERC20(TokenAddress).decimals();
        _perTokenAmount = 2 * tokenUnit;
        _inviteRewardToken = 2 * tokenUnit / 10;
        _inviteRewardToken2 = 3 * tokenUnit / 10;
    }

    function join(uint256 index, address invitor) external {
        require(index < _poolLen, "in i");
        require(_poolStart[index], "NSt");

        uint256 poolId = _poolId[index];
        PoolInfo storage poolInfo = _poolInfo[index][poolId];
        uint256 blockTime = block.timestamp;
        if (poolInfo.rewardTime > 0 && poolInfo.rewardTime <= blockTime) {
            _calReward(index, poolId);
            poolId += 1;
            _poolId[index] = poolId;
            poolInfo = _poolInfo[index][poolId];
        }
        poolInfo.rewardTime = blockTime + _refreshDuration;

        address account = msg.sender;
        UserInfo storage userInfo = _userInfo[account];
        if (!userInfo.active) {
            if (_userInfo[invitor].active) {
                _invitor[account] = invitor;
                _binder[invitor].push(account);
                address current = invitor;
                for (uint256 i; i < 10;) {
                    _teamNum[current] += 1;
                    current = _invitor[current];
                    if (address(0) == current) {
                        break;
                    }
                unchecked{
                    ++i;
                }
                }
            }
            userInfo.active = true;
        }

        require(!_userPoolJoin[index][poolId][account], "jed");
        _userPoolJoin[index][poolId][account] = true;

        poolInfo.accounts.push(account);
        poolInfo.accountTimes.push(blockTime);

        uint256 perUsdtAmount = _perUsdtAmount;

        address usdtAddress = _usdtAddress;
        _takeToken(usdtAddress, account, address(this), perUsdtAmount);

        poolInfo.queueReward += perUsdtAmount * _queueRewardRate / 10000;
        poolInfo.queueLen += 1;
        if (poolInfo.queueLen >= _queueRewardLen) {
            poolInfo.queueLen = 0;
            address queueRewardAccount = poolInfo.accounts[poolInfo.queueRewardIndex];
            _userInfo[queueRewardAccount].queueUsdtReward += poolInfo.queueReward;
            poolInfo.queueReward = 0;
            poolInfo.queueRewardIndex += 1;
            _userPoolJoin[index][poolId][queueRewardAccount] = false;
        }

        poolInfo.poolReward += perUsdtAmount * _poolRewardRate / 10000;

        uint256 buybackUsdt = perUsdtAmount * _buybackRate / 10000;
        if (buybackUsdt > 0) {
            address tokenLPPair = _tokenLPPair;
            IERC20(usdtAddress).transfer(tokenLPPair, buybackUsdt);
            ISwapPair(tokenLPPair).sync();
        }

        _totalProjectUsdt += perUsdtAmount * _projectRate / 10000;

        _totalDividendUsdt += perUsdtAmount * _dividendRate / 10000;

        if (poolId == 0 && !_poolStart[index + 1] && poolInfo.poolReward >= _refreshAmount / 2) {
            _poolStart[index + 1] = true;
        }

        if (poolInfo.poolReward >= _refreshAmount) {
            _calReward(index, poolId);
            poolId += 1;
            _poolId[index] = poolId;
        }

        invitor = _invitor[account];

        if (invitor != address(0)) {
            _userInfo[invitor].tokenReward += _inviteRewardToken;
            invitor = _invitor[invitor];
            if (invitor != address(0)) {
                _userInfo[invitor].tokenReward += _inviteRewardToken2;
            }
        }
    }

    function calProjectUsdt() public {
        uint256 usdtAmount = _totalProjectUsdt;
        uint256 len = _projectAddress.length;
        if (0 == usdtAmount || 0 == len) {
            return;
        }
        _totalProjectUsdt = 0;
        uint256 perUsdt = usdtAmount / len;
        for (uint256 i; i < len;) {
            _userInfo[_projectAddress[i]].inviteUsdtReward += perUsdt;
        unchecked{
            ++i;
        }
        }
    }

    function calDividendUsdt() public {
        uint256 usdtAmount = _totalDividendUsdt;
        uint256 len = _dividendAddress.length;
        if (0 == usdtAmount || 0 == len) {
            return;
        }
        _totalDividendUsdt = 0;
        uint256 perUsdt = usdtAmount / len;
        for (uint256 i; i < len;) {
            _userInfo[_dividendAddress[i]].inviteUsdtReward += perUsdt;
        unchecked{
            ++i;
        }
        }
    }

    function calReward(uint256 index) public {
        uint256 poolId = _poolId[index];
        PoolInfo storage poolInfo = _poolInfo[index][poolId];
        uint256 blockTime = block.timestamp;
        if (poolInfo.rewardTime > 0 && poolInfo.rewardTime <= blockTime) {
            _calReward(index, poolId);
            poolId += 1;
            _poolId[index] = poolId;
        }
    }

    function _calReward(uint256 index, uint256 pid) private {
        PoolInfo storage poolInfo = _poolInfo[index][pid];
        if (poolInfo.accPoolReward > 0) {
            return;
        }
        uint256 poolReward = poolInfo.poolReward;
        poolInfo.accPoolReward = poolReward;

        address[] storage accounts = poolInfo.accounts;
        uint256 accountLen = accounts.length;
        address lastAccount = accounts[accountLen - 1];
        uint256 buybackUsdt = poolInfo.queueReward;
        uint256 refreshAmount = _refreshAmount;
        if (poolReward >= refreshAmount) {
            buybackUsdt += poolReward - refreshAmount;
            uint256 lastReward = refreshAmount * _lastRewardRate / 10000;
            _userInfo[lastAccount].poolUsdtReward += lastReward;
            buybackUsdt += refreshAmount - lastReward;

            uint256 totalInviteUsdt = refreshAmount * _inviteRewardRate / 10000;
            if (totalInviteUsdt > 0) {
                uint256 perInviteUsdt = totalInviteUsdt / 10;
                address current = lastAccount;
                address invitor;
                for (uint256 i; i < 10;) {
                    invitor = _invitor[current];
                    if (address(0) == invitor) {
                        break;
                    }
                    if (i < 5) {
                        _userInfo[invitor].inviteUsdtReward += perInviteUsdt;
                        buybackUsdt -= perInviteUsdt;
                    } else if (_binder[invitor].length >= 2) {
                        _userInfo[invitor].inviteUsdtReward += perInviteUsdt;
                        buybackUsdt -= perInviteUsdt;
                    }
                    current = invitor;
                unchecked{
                    ++i;
                }
                }
            }
        } else {
            _userInfo[lastAccount].poolUsdtReward += poolReward;
        }

        if (buybackUsdt > 0) {
            address tokenLPPair = _tokenLPPair;
            IERC20(_usdtAddress).transfer(tokenLPPair, buybackUsdt);
            ISwapPair(tokenLPPair).sync();
        }

        uint256 end = accountLen - 1;
        uint256 perTokenAmount = _perTokenAmount;
        for (uint256 start = poolInfo.queueRewardIndex; start < end;) {
            _userInfo[accounts[start]].tokenReward += perTokenAmount;
        unchecked{
            ++start;
        }
        }

        if (_calProjectAndDividend) {
            calProjectUsdt();
            calDividendUsdt();
        }
    }

    function _takeToken(address tokenAddress, address account, address to, uint256 amount) private {
        if (0 == amount) {
            return;
        }
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(account) >= amount, "TNE");
        token.transferFrom(account, to, amount);
    }

    function _giveToken(address tokenAddress, address account, uint256 amount) private {
        if (0 == amount) {
            return;
        }
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "PTNE");
        token.transfer(account, amount);
    }

    function claimReward() external {
        address account = msg.sender;

        UserInfo storage userInfo = _userInfo[account];
        uint256 pendingUsdt = userInfo.queueUsdtReward + userInfo.poolUsdtReward + userInfo.inviteUsdtReward;
        if (pendingUsdt > 0) {
            userInfo.queueUsdtReward = 0;
            userInfo.poolUsdtReward = 0;
            userInfo.inviteUsdtReward = 0;
            _giveToken(_usdtAddress, account, pendingUsdt);
        }

        uint256 pendingToken = userInfo.tokenReward;
        if (pendingToken > 0) {
            userInfo.tokenReward = 0;
            _giveToken(_tokenAddress, account, pendingToken);
            userInfo.claimedToken += pendingToken;
        }
    }

    function claimBalance(address to, uint256 amount) external onlyOwner {
        address payable addr = payable(to);
        addr.transfer(amount);
    }

    function claimToken(address erc20Address, address to, uint256 amount) external onlyOwner {
        IERC20 erc20 = IERC20(erc20Address);
        erc20.transfer(to, amount);
    }

    function getBinderLength(address account) external view returns (uint256){
        return _binder[account].length;
    }

    function getUserInfo(address account) external view returns (
        uint256 queueUsdtReward,
        uint256 poolUsdtReward,
        uint256 inviteUsdtReward,
        uint256 tokenReward,
        bool isActive,
        uint256 teamNum,
        uint256 inviteRewardLevel,
        uint256 usdtBalance,
        uint256 usdtAllowance,
        uint256 tokenBalance,
        uint256 claimedToken
    ){
        UserInfo storage userInfo = _userInfo[account];
        queueUsdtReward = userInfo.queueUsdtReward;
        poolUsdtReward = userInfo.poolUsdtReward;
        inviteUsdtReward = userInfo.inviteUsdtReward;
        tokenReward = userInfo.tokenReward;
        isActive = userInfo.active;
        teamNum = _teamNum[account];
        if (_binder[account].length >= 2) {
            inviteRewardLevel = 10;
        } else if (_binder[account].length >= 1) {
            inviteRewardLevel = 5;
        }
        usdtBalance = IERC20(_usdtAddress).balanceOf(account);
        usdtAllowance = IERC20(_usdtAddress).allowance(account, address(this));
        tokenBalance = IERC20(_tokenAddress).balanceOf(account);
        claimedToken = userInfo.claimedToken;
    }

    function getBaseInfo() external view returns (
        address usdtAddress, uint256 usdtDecimals, string memory usdtSymbol,
        address tokenAddress, uint256 tokenDecimals, string memory tokenSymbol,
        uint256 perUsdtAmount
    ){
        usdtAddress = _usdtAddress;
        usdtDecimals = IERC20(usdtAddress).decimals();
        usdtSymbol = IERC20(usdtAddress).symbol();
        tokenAddress = _tokenAddress;
        tokenDecimals = IERC20(tokenAddress).decimals();
        tokenSymbol = IERC20(tokenAddress).symbol();
        perUsdtAmount = _perUsdtAmount;
    }

    function getPoolInfo(uint256 index, uint256 pid) public view returns (
        uint256 poolReward, uint256 accPoolReward, uint256 rewardTime, uint256 accountLen
    ){
        PoolInfo storage poolInfo = _poolInfo[index][pid];
        poolReward = poolInfo.poolReward;
        accPoolReward = poolInfo.accPoolReward;
        rewardTime = poolInfo.rewardTime;
        accountLen = poolInfo.accounts.length;
    }

    function getAllPoolInfo() public view returns (
        bool[] memory poolStart, uint256[] memory poolReward, uint256[] memory rewardTime,
        address[][] memory showAccounts, uint256[][] memory showAccountTimes,
        address[] memory lastRewardAccount, uint256 blockTime
    ){
        uint256 len = _poolLen;
        poolStart = new bool[](len);
        poolReward = new uint256[](len);
        rewardTime = new uint256[](len);
        showAccounts = new address[][](len);
        showAccountTimes = new uint256[][](len);
        lastRewardAccount = new address[](len);
        uint256 pid;
        for (uint256 i; i < len; ++i) {
            pid = getCurrentPoolId(i);
            poolStart[i] = _poolStart[i];
            (poolReward[i],,rewardTime[i],) = getCurrentPoolInfo(i);
            (showAccounts[i], showAccountTimes[i]) = getPoolShowAccounts(i, pid);
            if (pid > 0) {
                address[] storage accounts = _poolInfo[i][pid - 1].accounts;
                uint256 accountLen = accounts.length;
                if (accountLen > 0) {
                    lastRewardAccount[i] = accounts[accountLen - 1];
                }
            }
        }
        blockTime = block.timestamp;
    }

    function getUserAllPoolInfo(address account) public view returns (
        bool[] memory joins
    ){
        uint256 len = _poolLen;
        joins = new bool[](len);
        uint256 pid;
        for (uint256 i; i < len; ++i) {
            pid = getCurrentPoolId(i);
            joins[i] = _userPoolJoin[i][pid][account];
        }
    }

    function getCurrentPoolInfo(uint256 index) public view returns (
        uint256 poolReward, uint256 accPoolReward, uint256 rewardTime, uint256 accountLen
    ){
        (poolReward, accPoolReward, rewardTime, accountLen) = getPoolInfo(index, getCurrentPoolId(index));
        uint256 blockTime = block.timestamp;
        if (rewardTime == 0) {
            rewardTime = blockTime + _refreshDuration;
        }
    }

    function getCurrentPoolId(uint256 index) public view returns (uint256 poolId){
        poolId = _poolId[index];
        PoolInfo storage poolInfo = _poolInfo[index][poolId];
        uint256 blockTime = block.timestamp;
        if (poolInfo.rewardTime > 0 && poolInfo.rewardTime <= blockTime) {
            poolId += 1;
        }
    }

    function getPoolShowAccounts(uint256 pIndex, uint256 pid) public view returns (
        address[] memory returnAccounts, uint256[] memory returnAccountTimes
    ){
        PoolInfo storage poolInfo = _poolInfo[pIndex][pid];
        address[] storage accounts = poolInfo.accounts;
        uint256[] storage accountTimes = poolInfo.accountTimes;
        uint256 accountLength = accounts.length;
        uint256 start;
        uint256 len = _showAccountLen;
        if (accountLength > len) {
            start = accountLength - len;
        } else {
            len = accountLength;
        }
        returnAccounts = new address[](len);
        returnAccountTimes = new uint256[](len);

        uint256 index = 0;
        for (uint256 i = start; i < accountLength; ++i) {
            returnAccounts[index] = accounts[i];
            returnAccountTimes[index] = accountTimes[i];
            ++index;
        }
    }

    function getPoolAccounts(uint256 pIndex, uint256 pid, uint256 start, uint256 length) external view returns (
        uint256 returnLen, address[] memory returnAccounts, uint256[] memory returnAccountTimes
    ){
        PoolInfo storage poolInfo = _poolInfo[pIndex][pid];
        address[] storage accounts = poolInfo.accounts;
        uint256[] storage accountTimes = poolInfo.accountTimes;
        uint256 accountLength = accounts.length;
        if (0 == length) {
            length = accountLength;
        }
        returnLen = length;
        returnAccounts = new address[](length);
        returnAccountTimes = new uint256[](length);

        uint256 index = 0;
        for (uint256 i = start; i < start + length; ++i) {
            if (i >= accountLength)
                return (index, returnAccounts, returnAccountTimes);
            returnAccounts[index] = accounts[i];
            returnAccountTimes[index] = accountTimes[i];
            ++index;
        }
    }

    function getPoolQueueInfo(uint256 index, uint256 pid) public view returns (
        uint256 queueReward, uint256 queueLen, uint256 queueRewardIndex
    ){
        PoolInfo storage poolInfo = _poolInfo[index][pid];
        queueReward = poolInfo.queueReward;
        queueLen = poolInfo.queueLen;
        queueRewardIndex = poolInfo.queueRewardIndex;
    }

    function getProjectAddress() external view returns (address[] memory projectAddress) {
        projectAddress = _projectAddress;
    }

    function getDividendAddress() external view returns (address[] memory dividendAddress) {
        dividendAddress = _dividendAddress;
    }

    function setPoolLen(uint256 len) external onlyOwner {
        _poolLen = len;
    }

    function setPoolStart(uint256 index, bool enable) external onlyOwner {
        _poolStart[index] = enable;
        if (enable) {
            require(IERC20(_tokenLPPair).totalSupply() > 0, "N LP");
        }
    }

    function setProjectAddress(address[] memory adr) external onlyOwner {
        require(adr.length <= 100, "M");
        calProjectUsdt();
        _projectAddress = adr;
    }

    function setDividendAddress(address[] memory adr) external onlyOwner {
        require(adr.length <= 100, "M");
        calDividendUsdt();
        _dividendAddress = adr;
    }

    function setUsdtAddress(address adr) external onlyOwner {
        _usdtAddress = adr;
    }

    function setTokenLPPair(address adr) external onlyOwner {
        _tokenLPPair = adr;
    }

    function setTokenAddress(address adr) external onlyOwner {
        _tokenAddress = adr;
    }

    function setPerUsdtAmount(uint256 perUsdtAmount) external onlyOwner {
        _perUsdtAmount = perUsdtAmount;
        require(_refreshAmount / (_perUsdtAmount * _poolRewardRate / 10000) <= 300, "adr M");
    }

    function setPerTokenAmount(uint256 perAmount) external onlyOwner {
        _perTokenAmount = perAmount;
    }

    function setInviteRewardToken(uint256 amount) external onlyOwner {
        _inviteRewardToken = amount;
    }

    function setInviteRewardToken2(uint256 amount) external onlyOwner {
        _inviteRewardToken2 = amount;
    }

    function setRefreshDuration(uint256 refreshDuration) external onlyOwner {
        _refreshDuration = refreshDuration;
    }

    function setRefreshAmount(uint256 amount) external onlyOwner {
        _refreshAmount = amount;
        require(_refreshAmount / (_perUsdtAmount * _poolRewardRate / 10000) <= 300, "adr M");
    }

    function setQueueRewardLen(uint256 queueRewardLen) external onlyOwner {
        _queueRewardLen = queueRewardLen;
    }

    function setQueueRewardRate(uint256 rate) external onlyOwner {
        _queueRewardRate = rate;
        require(_dividendRate + _projectRate + _buybackRate + _poolRewardRate + _queueRewardRate <= 10000, "M W");
    }

    function setPoolRewardRate(uint256 rate) external onlyOwner {
        _poolRewardRate = rate;
        require(_dividendRate + _projectRate + _buybackRate + _poolRewardRate + _queueRewardRate <= 10000, "M W");
        require(_refreshAmount / (_perUsdtAmount * _poolRewardRate / 10000) <= 300, "adr M");
    }

    function setBuybackRate(uint256 rate) external onlyOwner {
        _buybackRate = rate;
        require(_dividendRate + _projectRate + _buybackRate + _poolRewardRate + _queueRewardRate <= 10000, "M W");
    }

    function setProjectRate(uint256 rate) external onlyOwner {
        _projectRate = rate;
        require(_dividendRate + _projectRate + _buybackRate + _poolRewardRate + _queueRewardRate <= 10000, "M W");
    }

    function setDividendRate(uint256 rate) external onlyOwner {
        _dividendRate = rate;
        require(_dividendRate + _projectRate + _buybackRate + _poolRewardRate + _queueRewardRate <= 10000, "M W");
    }

    function setLastRewardRate(uint256 rate) external onlyOwner {
        _lastRewardRate = rate;
        require(_lastRewardRate + _inviteRewardRate <= 10000, "M W");
    }

    function setInviteRewardRate(uint256 rate) external onlyOwner {
        _inviteRewardRate = rate;
        require(_lastRewardRate + _inviteRewardRate <= 10000, "M W");
    }

    function setShowAccountLen(uint256 len) external onlyOwner {
        _showAccountLen = len;
    }

    function setCalProjectAndDividend(bool enable) external onlyOwner {
        _calProjectAndDividend = enable;
    }
}

contract FOMOPool is AbsPool {
    constructor() AbsPool(
    //usdt
        address(0x55d398326f99059fF775485246999027B3197955),
    //Token
        address(0xcd9A438cd6C2021e7b3944bC595755A47aFeFFFF),
    //TokenLP
        address(0xb1Af277613406CaFf8b2FdC548c1940315D89338)
    ){

    }
}