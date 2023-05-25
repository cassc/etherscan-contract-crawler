/**
 *Submitted for verification at Etherscan.io on 2023-05-14
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
    address private _owner;

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

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface INFT {
    function balanceOf(address owner) external view returns (uint256 balance);

    function mint(address to) external;
}

abstract contract AbsPool is Ownable {
    struct UserInfo {
        bool isActive;
        uint256 amount;
        uint256 rewardMintDebt;
        uint256 calMintReward;
        uint256 teamNum;
        bool claimNFT;
        uint256 inviteReward;
    }

    struct PoolInfo {
        uint256 totalAmount;
        uint256 accMintPerShare;
        uint256 accMintReward;
        uint256 mintPerBlock;
        uint256 lastMintBlock;
        uint256 totalMintReward;
    }

    PoolInfo private poolInfo;
    mapping(address => UserInfo) private userInfo;

    address private _lpToken;
    string private _lpTokenSymbol;
    address private _mintRewardToken;

    mapping(address => address) public _invitor;
    mapping(address => address[]) public _binder;
    uint256 public _inviteFee = 1000;
    address public _defaultInvitor;

    address public immutable _weth;
    address public immutable _usdt;
    ISwapPair public immutable _wethUsdtPair;
    INFT public _nft;

    constructor(
        address LPToken, string memory LPTokenSymbol,
        address MintRewardToken, address DefaultInvitor,
        address MinterToken, address NFTAddress,
        address WETH, address USDT, address WETHUSDTPair
    ){
        _lpToken = LPToken;
        _lpTokenSymbol = LPTokenSymbol;
        _mintRewardToken = MintRewardToken;
        poolInfo.lastMintBlock = block.number;
        _defaultInvitor = DefaultInvitor;
        userInfo[DefaultInvitor].isActive = true;

        _minterToken = MinterToken;
        _minterTokenUnit = 10 ** IERC20(MinterToken).decimals();
        _minterRewardPerAmountPerDay = 42 * 10 ** IERC20(MintRewardToken).decimals() / 100;
        _nft = INFT(NFTAddress);

        _weth = WETH;
        _usdt = USDT;
        _wethUsdtPair = ISwapPair(WETHUSDTPair);
        require(IERC20(WETH).balanceOf(WETHUSDTPair) > 0 && IERC20(USDT).balanceOf(WETHUSDTPair) > 0, "weth-usdt");
        _claimNFTLPUCondition = 20000 * 10 ** IERC20(USDT).decimals();

        poolInfo.totalMintReward = 210000000000000000000000;
    }

    receive() external payable {}

    function deposit(uint256 amount, address invitor) external {
        require(amount > 0, "=0");
        address account = msg.sender;
        _checkInvitor(account, invitor);

        UserInfo storage user = userInfo[account];
        _calReward(user);

        _takeToken(_lpToken, account, address(this), amount);

        user.amount += amount;
        poolInfo.totalAmount += amount;

        user.rewardMintDebt = user.amount * poolInfo.accMintPerShare / 1e18;
    }

    function _checkInvitor(address account, address invitor) private {
        UserInfo storage user = userInfo[account];
        uint256 inviteLen = _teamLength;
        address current = account;
        if (!user.isActive) {
            require(userInfo[invitor].isActive, "!Active");
            _invitor[account] = invitor;
            _binder[invitor].push(account);
            for (uint256 i; i < inviteLen;) {
                invitor = _invitor[current];
                if (address(0) == invitor) {
                    break;
                }
                userInfo[invitor].teamNum += 1;
                current = invitor;
            unchecked{
                ++i;
            }
            }
            user.isActive = true;
        }
    }

    function withdraw() public {
        address account = msg.sender;
        UserInfo storage user = userInfo[account];
        _calReward(user);

        uint256 amount = user.amount;
        _giveToken(_lpToken, account, amount);

        user.amount -= amount;
        poolInfo.totalAmount -= amount;

        user.rewardMintDebt = user.amount * poolInfo.accMintPerShare / 1e18;
    }

    function claim() public {
        address account = msg.sender;
        UserInfo storage user = userInfo[account];
        _calReward(user);
        uint256 pendingMint = user.calMintReward;
        if (pendingMint > 0) {
            address mintRewardToken = _mintRewardToken;
            address invitor = _invitor[account];
            if (address(0) != invitor) {
                uint256 inviteAmount = pendingMint * _inviteFee / 10000;
                if (inviteAmount > 0) {
                    pendingMint -= inviteAmount;
                    _giveToken(mintRewardToken, invitor, inviteAmount);
                    userInfo[invitor].inviteReward += inviteAmount;
                }
            }
            _giveToken(mintRewardToken, account, pendingMint);
            user.calMintReward = 0;
        }
    }

    function _updatePool() private {
        PoolInfo storage pool = poolInfo;
        uint256 blockNum = block.number;
        uint256 lastRewardBlock = pool.lastMintBlock;
        if (blockNum <= lastRewardBlock) {
            return;
        }
        pool.lastMintBlock = blockNum;

        uint256 accReward = pool.accMintReward;
        uint256 totalReward = pool.totalMintReward;
        if (accReward >= totalReward) {
            return;
        }

        uint256 totalAmount = pool.totalAmount;
        uint256 rewardPerBlock = pool.mintPerBlock;
        if (0 < totalAmount && 0 < rewardPerBlock) {
            uint256 reward = rewardPerBlock * (blockNum - lastRewardBlock);
            uint256 remainReward = totalReward - accReward;
            if (reward > remainReward) {
                reward = remainReward;
            }
            pool.accMintPerShare += reward * 1e18 / totalAmount;
            pool.accMintReward += reward;
        }
    }

    function _calReward(UserInfo storage user) private {
        _updatePool();
        if (user.amount > 0) {
            uint256 accMintReward = user.amount * poolInfo.accMintPerShare / 1e18;
            uint256 pendingMintAmount = accMintReward - user.rewardMintDebt;
            if (pendingMintAmount > 0) {
                user.rewardMintDebt = accMintReward;
                user.calMintReward += pendingMintAmount;
            }
        }
    }

    function _calPendingMintReward(address account) private view returns (uint256 reward) {
        reward = 0;
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[account];
        if (user.amount > 0) {
            uint256 poolPendingReward;
            uint256 blockNum = block.number;
            uint256 lastRewardBlock = pool.lastMintBlock;
            if (blockNum > lastRewardBlock) {
                poolPendingReward = pool.mintPerBlock * (blockNum - lastRewardBlock);
                uint256 totalReward = pool.totalMintReward;
                uint256 accReward = pool.accMintReward;
                uint256 remainReward;
                if (totalReward > accReward) {
                    remainReward = totalReward - accReward;
                }
                if (poolPendingReward > remainReward) {
                    poolPendingReward = remainReward;
                }
            }
            reward = user.amount * (pool.accMintPerShare + poolPendingReward * 1e18 / pool.totalAmount) / 1e18 - user.rewardMintDebt;
        }
    }

    function getLPPoolInfo() public view returns (
        uint256 totalAmount,
        uint256 accMintPerShare, uint256 accMintReward,
        uint256 mintPerBlock, uint256 lastMintBlock, uint256 totalMintReward
    ) {
        totalAmount = poolInfo.totalAmount;
        accMintPerShare = poolInfo.accMintPerShare;
        accMintReward = poolInfo.accMintReward;
        mintPerBlock = poolInfo.mintPerBlock;
        lastMintBlock = poolInfo.lastMintBlock;
        totalMintReward = poolInfo.totalMintReward;
    }

    function getPoolInfo() public view returns (
        uint256 totalLPAmount,
        uint256 totalLP,
        uint256 totalLPUValue,
        uint256 minterRewardPerAmountPerDay,
        uint256 minterTotalAmount,
        uint256 minterActiveAmount,
        uint256 claimNFTMinterTeamCondition,
        uint256 claimNFTLPUCondition,
        uint256 totalMinterReward,
        uint256 totalMinterInviteReward
    ){
        totalLPAmount = poolInfo.totalAmount;
        (totalLP, totalLPUValue) = getLPInfo();
        minterRewardPerAmountPerDay = _minterRewardPerAmountPerDay;
        minterTotalAmount = _minterTotalAmount;
        minterActiveAmount = _minterActiveAmount;
        claimNFTMinterTeamCondition = _claimNFTMinterTeamCondition;
        claimNFTLPUCondition = _claimNFTLPUCondition;
        totalMinterReward = _totalMinterReward;
        totalMinterInviteReward = _totalMinterInviteReward;
    }

    function getUserInfo(address account) public view returns (
        bool isActive,
        uint256 amount, uint256 lpBalance, uint256 lpAllowance,
        uint256 pendingMintReward, uint256 inviteReward,
        uint256 teamNum, bool claimedNFT
    ) {
        UserInfo storage user = userInfo[account];
        isActive = user.isActive;
        amount = user.amount;
        lpBalance = IERC20(_lpToken).balanceOf(account);
        lpAllowance = IERC20(_lpToken).allowance(account, address(this));
        pendingMintReward = _calPendingMintReward(account) + user.calMintReward;
        inviteReward = user.inviteReward;
        teamNum = user.teamNum;
        claimedNFT = user.claimNFT;
    }

    function getUserExtInfo(address account) public view returns (
        uint256 calMintReward, uint256 rewardMintDebt
    ) {
        UserInfo storage user = userInfo[account];
        calMintReward = user.calMintReward;
        rewardMintDebt = user.rewardMintDebt;
    }

    function getUserTeamInfo(address account) public view returns (
        uint256 amount, uint256 teamAmount
    ) {
        amount = userInfo[account].amount;
        teamAmount = _minterInfos[account].minterTeamAmount;
    }

    function getBaseInfo() external view returns (
        address lpToken,
        uint256 lpTokenDecimals,
        string memory lpTokenSymbol,
        address mintRewardToken,
        uint256 mintRewardTokenDecimals,
        string memory mintRewardTokenSymbol,
        address minterToken,
        uint256 minterTokenDecimals,
        string memory minterTokenSymbol
    ){
        lpToken = _lpToken;
        lpTokenDecimals = IERC20(lpToken).decimals();
        lpTokenSymbol = _lpTokenSymbol;
        mintRewardToken = _mintRewardToken;
        mintRewardTokenDecimals = IERC20(mintRewardToken).decimals();
        mintRewardTokenSymbol = IERC20(mintRewardToken).symbol();
        minterToken = _minterToken;
        minterTokenDecimals = IERC20(minterToken).decimals();
        minterTokenSymbol = IERC20(minterToken).symbol();
    }

    function getBinderLength(address account) public view returns (uint256){
        return _binder[account].length;
    }

    function setLPToken(address lpToken, string memory lpSymbol) external onlyOwner {
        require(poolInfo.totalAmount == 0, "started");
        _lpToken = lpToken;
        _lpTokenSymbol = lpSymbol;
    }

    function setMintRewardToken(address rewardToken) external onlyOwner {
        _mintRewardToken = rewardToken;
    }

    function setMintPerBlock(uint256 mintPerBlock) external onlyOwner {
        _updatePool();
        poolInfo.mintPerBlock = mintPerBlock;
    }

    function setTotalMintReward(uint256 totalReward) external onlyOwner {
        _updatePool();
        poolInfo.totalMintReward = totalReward;
    }

    function setInviteFee(uint256 fee) external onlyOwner {
        _inviteFee = fee;
    }

    function claimBalance(address to, uint256 amount) external onlyOwner {
        safeTransferETH(to, amount);
    }

    function claimToken(address token, address to, uint256 amount) external onlyOwner {
        if (token == _lpToken) {
            return;
        }
        safeTransfer(token, to, amount);
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (success && data.length > 0) {

        }
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,bytes memory data) = to.call{value : value}(new bytes(0));
        if (success && data.length > 0) {

        }
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        if (success && data.length > 0) {

        }
    }

    function setDefaultInvitor(address adr) external onlyOwner {
        _defaultInvitor = adr;
        userInfo[adr].isActive = true;
    }

    struct UserMinterInfo {
        uint256 minterAmount;
        uint256 activeRecordIndex;
        uint256 minterClaimedReward;
        uint256 minterInviteAmount;
        uint256 minterTeamAmount;
    }

    struct MinterRecord {
        uint256 minterAmount;
        uint256 minterStart;
        uint256 minterEnd;
        uint256 lastMinterRewardTime;
        uint256 claimedMinterReward;
    }

    mapping(address => UserMinterInfo) private _minterInfos;
    
    uint256 public _maxActiveRecordLen = 10;

    mapping(address => MinterRecord[]) private _minterRecords;

    uint256 private constant _teamLength = 2;
    uint256 public _minterInviteFee = 1000;
    uint256 private constant _feeDivFactor = 10000;
    address public _minterReceiveAddress = address(0x000000000000000000000000000000000000dEaD);

    address private _minterToken;
    uint256 public _minterTokenUnit;
    uint256 public _minterDuration = 30 days;
    uint256 private _minterRewardPerAmountPerDay;

    uint256 private _minterTotalAmount;
    uint256 private _minterActiveAmount;
    uint256 private _claimNFTMinterTeamCondition = 5000;
    uint256 private _claimNFTLPUCondition;

    uint256 private _totalMinterReward;
    uint256 private _totalMinterInviteReward;
    bool public _pauseNFT;

    //invitor,joiner,index,bool
    mapping(address => mapping(address => mapping(uint256 => bool))) public _hasCalTeamAmount;

    function _giveToken(address tokenAddress, address account, uint256 amount) private {
        if (0 == amount) {
            return;
        }
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "PTNE");
        safeTransfer(tokenAddress, account, amount);
    }

    function _takeToken(address tokenAddress, address from, address to, uint256 tokenNum) private {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(from)) >= tokenNum, "TNE");
        safeTransferFrom(tokenAddress, from, to, tokenNum);
    }

    function mint(uint256 amount, address invitor) external {
        require(amount > 0, "0");

        address account = msg.sender;
        _checkInvitor(account, invitor);

        _claimMinterReward(account);

        UserMinterInfo storage minterInfo = _minterInfos[account];
        uint256 userRecordLen = _minterRecords[account].length;
        require(minterInfo.activeRecordIndex + _maxActiveRecordLen > userRecordLen, "ML");
        _takeToken(_minterToken, account, _minterReceiveAddress, amount * _minterTokenUnit);

        uint256 blockTime = block.timestamp;
        uint256 endTime = blockTime + _minterDuration;
        _addRecord(account, amount, blockTime, endTime);
        minterInfo.minterAmount += amount;

        _minterTotalAmount += amount;
        _minterActiveAmount += amount;

        uint256 len = _teamLength;
        address current = account;
        UserMinterInfo storage invitorInfo;
        uint256 claimNFTTeamCondition = _claimNFTMinterTeamCondition;
        for (uint256 i; i < len;) {
            if (_minterInfos[current].minterTeamAmount >= claimNFTTeamCondition) {
                break;
            }
            invitor = _invitor[current];
            if (address(0) == invitor) {
                break;
            }
            invitorInfo = _minterInfos[invitor];
            invitorInfo.minterTeamAmount += amount;
            _hasCalTeamAmount[invitor][account][userRecordLen] = true;
            current = invitor;
        unchecked{
            ++i;
        }
        }
    }

    function _addRecord(address account, uint256 amount, uint256 blockTime, uint256 endTime) private {
        _minterRecords[account].push(
            MinterRecord(amount, blockTime, endTime, blockTime, 0)
        );
    }

    function claimMinterReward() external {
        address account = msg.sender;
        _claimMinterReward(account);
    }
    
    function _claimMinterReward(address account) private {
        UserMinterInfo storage minterInfo = _minterInfos[account];
        uint256 recordLen = _minterRecords[account].length;
        uint256 blockTime = block.timestamp;
        uint256 activeRecordIndex = minterInfo.activeRecordIndex;
        MinterRecord storage record;
        uint256 rewardPerAmountPerDay = _minterRewardPerAmountPerDay;
        uint256 pendingReward;
        for (uint256 i = activeRecordIndex; i < recordLen;) {
            record = _minterRecords[account][i];
            uint256 lastRewardTime = record.lastMinterRewardTime;
            uint256 endTime = record.minterEnd;
            uint256 amount = record.minterAmount;
            if (lastRewardTime < endTime && lastRewardTime < blockTime) {
                if (endTime > blockTime) {
                    endTime = blockTime;
                } else {
                    activeRecordIndex = i + 1;
                    _expire(account, i, amount);
                    minterInfo.minterAmount -= amount;
                }
                record.lastMinterRewardTime = endTime;
                uint256 reward = amount * rewardPerAmountPerDay * (endTime - lastRewardTime) / 1 days;
                record.claimedMinterReward += reward;
                pendingReward += reward;
            }
        unchecked{
            ++i;
        }
        }
        minterInfo.activeRecordIndex = activeRecordIndex;
        _giveToken(_mintRewardToken, account, pendingReward);
        minterInfo.minterClaimedReward += pendingReward;
        _totalMinterReward += pendingReward;
        address invitor = _invitor[account];
        if (address(0) != invitor) {
            uint256 inviteReward = pendingReward * _minterInviteFee / _feeDivFactor;
            _giveToken(_mintRewardToken, invitor, inviteReward);
            _totalMinterInviteReward += inviteReward;
            _minterInfos[invitor].minterInviteAmount += inviteReward;
        }
    }

    function _expire(address account, uint256 currentRecordIndex, uint256 amount) private {
        _minterActiveAmount -= amount;
        uint256 len = _teamLength;
        address current = account;
        address invitor;
        UserMinterInfo storage invitorInfo;
        for (uint256 i; i < len;) {
            invitor = _invitor[current];
            if (address(0) == invitor) {
                break;
            }
            if (!_hasCalTeamAmount[invitor][account][currentRecordIndex]) {
                break;
            }
            invitorInfo = _minterInfos[invitor];
            invitorInfo.minterTeamAmount -= amount;
            current = invitor;
        unchecked{
            ++i;
        }
        }
    }

    function getRecordLength(address account) public view returns (uint256){
        return _minterRecords[account].length;
    }

    function getRecords(
        address account,
        uint256 start,
        uint256 length
    ) external view returns (
        uint256 returnCount,
        uint256[] memory amount,
        uint256[] memory startTime,
        uint256[] memory endTime,
        uint256[] memory lastRewardTime,
        uint256[] memory claimedRewards,
        uint256[] memory totalRewards
    ){
        uint256 recordLen = _minterRecords[account].length;
        if (0 == length) {
            length = recordLen;
        }
        returnCount = length;

        amount = new uint256[](length);
        startTime = new uint256[](length);
        endTime = new uint256[](length);
        lastRewardTime = new uint256[](length);
        claimedRewards = new uint256[](length);
        totalRewards = new uint256[](length);
        uint256 index = 0;
        for (uint256 i = start; i < start + length; i++) {
            if (i >= recordLen) {
                return (index, amount, startTime, endTime, lastRewardTime, claimedRewards, totalRewards);
            }
            (amount[index], startTime[index], endTime[index], lastRewardTime[index], claimedRewards[index]) = getRecord(account, i);
            totalRewards[index] = getPendingMinterRecordReward(account, i);
            index++;
        }
    }

    function getUserMinterInfo(address account) public view returns (
        uint256 minterAmount,
        uint256 activeRecordIndex,
        uint256 minterClaimedReward,
        uint256 minterInviteAmount,
        uint256 minterTeamAmount,
        uint256 minterPendingReward,
        uint256 minterTokenBalance,
        uint256 minterTokenAllowance
    ){
        UserMinterInfo storage minterInfo = _minterInfos[account];
        minterAmount = minterInfo.minterAmount;
        activeRecordIndex = minterInfo.activeRecordIndex;
        minterClaimedReward = minterInfo.minterClaimedReward;
        minterInviteAmount = minterInfo.minterInviteAmount;
        minterTeamAmount = minterInfo.minterTeamAmount;
        minterPendingReward = getPendingMinterReward(account);
        minterTokenBalance = IERC20(_minterToken).balanceOf(account);
        minterTokenAllowance = IERC20(_minterToken).allowance(account, address(this));
    }

    function getPendingMinterRecordReward(address account, uint256 i) public view returns (uint256 pendingReward){
        uint256 blockTime = block.timestamp;
        MinterRecord storage record = _minterRecords[account][i];
        uint256 rewardPerAmountPerDay = _minterRewardPerAmountPerDay;
        uint256 lastRewardTime = record.lastMinterRewardTime;
        uint256 endTime = record.minterEnd;
        if (lastRewardTime < endTime && lastRewardTime < blockTime) {
            if (endTime > blockTime) {
                endTime = blockTime;
            }
            pendingReward += record.minterAmount * rewardPerAmountPerDay * (endTime - lastRewardTime) / 1 days;
        }
    }

    function getRecord(address account, uint256 i) public view returns (
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 lastRewardTime,
        uint256 claimedReward
    ){
        MinterRecord storage record = _minterRecords[account][i];
        amount = record.minterAmount;
        startTime = record.minterStart;
        endTime = record.minterEnd;
        lastRewardTime = record.lastMinterRewardTime;
        claimedReward = record.claimedMinterReward;
    }

    function getPendingMinterReward(address account) public view returns (uint256 pendingReward){
        UserMinterInfo storage minterInfo = _minterInfos[account];
        uint256 recordLen = _minterRecords[account].length;
        uint256 blockTime = block.timestamp;
        uint256 activeRecordIndex = minterInfo.activeRecordIndex;
        MinterRecord storage record;
        uint256 rewardPerAmountPerDay = _minterRewardPerAmountPerDay;
        for (uint256 i = activeRecordIndex; i < recordLen;) {
            record = _minterRecords[account][i];
            uint256 lastRewardTime = record.lastMinterRewardTime;
            uint256 endTime = record.minterEnd;
            if (lastRewardTime < endTime && lastRewardTime < blockTime) {
                if (endTime > blockTime) {
                    endTime = blockTime;
                }
                pendingReward += record.minterAmount * rewardPerAmountPerDay * (endTime - lastRewardTime) / 1 days;
            }
        unchecked{
            ++i;
        }
        }
    }

    function setMinterRewardPerAmountPerDay(uint256 a) public onlyOwner {
        _minterRewardPerAmountPerDay = a;
    }

    function setMinterDuration(uint256 d) public onlyOwner {
        if (_minterActiveAmount > 0) {
            require(d > _minterDuration, "longer");
        }
        _minterDuration = d;
    }

    function setMinterToken(address t) public onlyOwner {
        _minterToken = t;
        _minterTokenUnit = 10 ** IERC20(t).decimals();
    }

    function setMaxActiveRecordLen(uint256 l) public onlyOwner {
        _maxActiveRecordLen = l;
    }

    function setMinterInviteFee(uint256 f) public onlyOwner {
        _minterInviteFee = f;
    }

    function setMinterReceiveAddress(address r) public onlyOwner {
        _minterReceiveAddress = r;
    }

    function setClaimNFTMinterTeamCondition(uint256 c) public onlyOwner {
        _claimNFTMinterTeamCondition = c;
    }

    function setClaimNFTLPUCondition(uint256 c) public onlyOwner {
        _claimNFTLPUCondition = c;
    }

    function setNFT(address nft) public onlyOwner {
        _nft = INFT(nft);
    }

    function setPauseNFT(bool pause) public onlyOwner {
        _pauseNFT = pause;
    }

    function claimNFT() external {
        require(!_pauseNFT, "pause");
        address account = msg.sender;
        UserInfo storage user = userInfo[account];
        require(!user.claimNFT, "claimed");
        require(_minterInfos[account].minterTeamAmount >= _claimNFTMinterTeamCondition && user.amount >= getNFTRewardLPCondition(), "NAC");
        user.claimNFT = true;
        _nft.mint(account);
    }

    function getNFTRewardLPCondition() public view returns (uint256 lpCondition){
        (uint256 totalLP,uint256 totalLPValue) = getLPInfo();
        lpCondition = _claimNFTLPUCondition * totalLP / totalLPValue;
    }

    function getLPInfo() public view returns (uint256 totalLP, uint256 totalLPValue){
        (uint256 rOther,) = __getReserves();
        (uint256 rEth,uint256 rUsdt) = getETHUSDTReserves();
        totalLPValue = 2 * rOther * rUsdt / rEth;
        totalLP = IERC20(_lpToken).totalSupply();
    }

    function __getReserves() public view returns (uint256 rOther, uint256 rThis){
        ISwapPair mainPair = ISwapPair(_lpToken);
        (uint r0, uint256 r1,) = mainPair.getReserves();

        if (_weth < _minterToken) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }
    }

    function getETHUSDTReserves() public view returns (uint256 rEth, uint256 rUsdt){
        (uint r0, uint256 r1,) = _wethUsdtPair.getReserves();
        if (_weth < _usdt) {
            rEth = r0;
            rUsdt = r1;
        } else {
            rEth = r1;
            rUsdt = r0;
        }
    }

    function claimMinter(address account) external {
        _claimMinterReward(account);
    }

    function claimMinters(address[] memory accounts) external {
        uint256 len = accounts.length;
        for (uint256 i; i < len;) {
            _claimMinterReward(accounts[i]);
        unchecked{
            ++i;
        }
        }
    }
}

contract MintPool is AbsPool {
    constructor() AbsPool(
    //ZM-ETH-LP
        address(0x86E6c6Fd93eA7Bb809026dbe7CcaA9f571a6026C),
        "ZM-ETH-LP",
    //ETX
        address(0x469fc807543A766199C07d3a76A3e7A6EC1A2004),
    //DefaultInvitor
        address(0x68DAc8c072e3BF0407933984E6DBaD605D3b7874),
    //ZM
        address(0xf315EC7B1063E21d5AbaF12cA3470F57AbF47ea5),
    //NFT
        address(0x22D21831fA435B9f38E2a67Fe0a4A8CBfEAa1327),
    //WETH
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2),
    //USDT
        address(0xdAC17F958D2ee523a2206206994597C13D831ec7),
    //eth-usdt-pair
        address(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852)
    ){

    }
}