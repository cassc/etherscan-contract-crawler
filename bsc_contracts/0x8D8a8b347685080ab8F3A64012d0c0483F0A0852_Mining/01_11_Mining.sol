// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@quant-finance/solidity-datetime/contracts/DateTime.sol";

contract Mining is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    struct UserInfo {
        uint256 totalHashRate;
        uint256 minersCount;
        uint256 totalClaims;
    }


    struct MinerInfo {
        uint256 hashrate;
        uint256 rewardDebt;
        uint256 electricityLastDay;
        uint256 stakedTimestamp;
        uint256 unstakeTimestamp;
        uint256 lastAmortization;
        uint256 lastUpdated;
        uint256 totalClaims;
        uint256 minerId;
        uint256 accRewardUserShare;
        bool isStaked;
    }

    struct PoolInfo {
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    IERC20Upgradeable public rewardToken;
    uint256 public rewardPerBlock;
    uint256 public startBlock;
    uint256 public lastRewardDay;

    address public municipalityAddress;
    address public minerPublicBuilding;

    /// Info of pool.
    PoolInfo public poolInfo;
    uint256 private lastChangeBlock;
    uint256 public totalHashRate;
    uint256 public totalMintedTokens;
    bool public isPoolActive;


    /// Info of each user that staked tokens.
    mapping(address => UserInfo) public userInfo;

    /// @notice Info of each miner that assigned miner to parcel
    mapping(address => mapping(uint256 => MinerInfo)) public minersInfo;
    mapping(address => EnumerableSetUpgradeable.UintSet) private userToMiners;

    mapping(uint256 => uint256) public rewardSharesByDays;

    uint32 constant public SECONDS_PER_MONTH = 30 * 24 * 60 * 60;

    /// @notice Trigger event about assignment of miner to parcel
    event Deposit(uint256 indexed minerId);

    /// @notice Trigger event about claiming of miner rewards
    event Claim(address user, uint256 indexed minerId, uint256 amount);

    event ClaimAll(address userAddress);

    /// @notice Trigger event about unassignment of miner from the parcel
    event Withdraw(uint256 indexed minerId);

    event MunicipalitAddressSet(address indexed municipality);

    event RewardTokenAddressSet(address indexed rewardToken);

    event MinerPublicBuildingAddress(address indexed minerPublciBuilding);

    event StartRewardBlockSet(uint256 indexed startBlock);
    event MinerElectricityLastDayUpdated(uint256 indexed tokenId, uint256 electricityLastDay);

    function initialize(
        IERC20Upgradeable _rewardToken, // VBTC address
        uint256 _rewardPerBlock, // 20,25462963
        uint256 _startBlock
    ) public initializer {
        require(address(_rewardToken) != address(0), "Mining: Reward TokenAddress can not be address 0");

        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    modifier onlyAuthorizedContracts() {
        require(minerPublicBuilding == msg.sender || msg.sender == municipalityAddress, "MinerNFT: Only authorized contracts can call this function");
        _;
    }

    modifier onlyDetachedMiner(address _user, uint256 _minerId) {
        require(!minersInfo[_user][_minerId].isStaked, "Mining: This miner is already Attached");
        _;
    }

    modifier onlyAttachedMiner(address _user, uint256 _minerId) {
        require(minersInfo[_user][_minerId].isStaked, "Mining: This miner is not attached");
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function setMunicipalityAddress(address _municipalityAddress) external onlyOwner {
        municipalityAddress = _municipalityAddress;
        emit MunicipalitAddressSet(municipalityAddress);
    }

    function setRewardTokenAddress(IERC20Upgradeable _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
        emit RewardTokenAddressSet(address(rewardToken));
    }

    function setPoolInfo(
        uint256 lastRewardBlock,
        uint256 accRewardPerShare
    ) external onlyOwner {
        updatePool();

        poolInfo = PoolInfo({
        lastRewardBlock : lastRewardBlock,
        accRewardPerShare : accRewardPerShare
        });

    }

    function updateStartBlock(uint256 _startBlock) external onlyOwner {
        startBlock = _startBlock;
    }

    function setIsPoolActive(bool _isPoolActive) external onlyOwner {
        isPoolActive = _isPoolActive;
    }

    function setMinerPublicBuildingAddress(address _minerPublicBuilding) external onlyOwner {
        minerPublicBuilding = _minerPublicBuilding;
        emit MinerPublicBuildingAddress(minerPublicBuilding);
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        updatePool();
        rewardPerBlock = _rewardPerBlock;
    }

    function setStartBlock(uint256 _startBlock) external onlyOwner {
        startBlock = _startBlock;
        emit StartRewardBlockSet(startBlock);
    }


    function repairMiners(address _user) external onlyAuthorizedContracts nonReentrant {
        EnumerableSetUpgradeable.UintSet storage userMiners = userToMiners[_user];
        UserInfo storage user = userInfo[_user];
        require(user.minersCount > 0, "Mining: User does not have any Miners to repair");
        _claimAll(_user);
        for (uint256 index; index < userMiners.length(); ++index) {
            uint256 minerId = userMiners.at(index);
            MinerInfo storage miner = minersInfo[_user][minerId];
            miner.lastAmortization = 1000;
        }
    }

    function getUserMinersIdsByIndex(address _user) external view returns (uint256[] memory){
        EnumerableSetUpgradeable.UintSet storage userMiners = userToMiners[_user];
        uint256[] memory collectedArrays = new uint256[](userMiners.length());
        for (uint256 i = 0; i < userMiners.length(); i++) {
            collectedArrays[i] = userMiners.at(i);
        }
        return collectedArrays;
    }

    function getUserActiveMiners(address _user) external view returns (uint256){
        EnumerableSetUpgradeable.UintSet storage userMiners = userToMiners[_user];
        uint256 activeMiners;
        for (uint256 i = 0; i < userMiners.length(); i++) {
            uint256 minerId = userMiners.at(i);
            MinerInfo storage miner = minersInfo[_user][minerId];
            if(miner.electricityLastDay > block.timestamp) {
                activeMiners++;
            }
        }
        return activeMiners;
    }
    
    function applyVouchers(address _user, uint256[] calldata _minerIds)
    external
    onlyAuthorizedContracts
    {
        _claimAll(_user);
        for (uint32 i = 0; i < _minerIds.length; i++) {
            MinerInfo storage miner = minersInfo[_user][_minerIds[i]];
            if (miner.electricityLastDay < block.timestamp)
                miner.electricityLastDay = block.timestamp + SECONDS_PER_MONTH;
            else
                miner.electricityLastDay += SECONDS_PER_MONTH;
            emit MinerElectricityLastDayUpdated(_minerIds[i], miner.electricityLastDay);
        }

    }

    function deposit(address _user, uint256 _minerId, uint256 _hashrate)
    external
    onlyAuthorizedContracts
    nonReentrant
    onlyDetachedMiner(_user, _minerId)
    {
        updatePool();
        _deposit(_user, _minerId, _hashrate);
    }

    function depositMiners(address _user, uint256 _firstMinerId, uint256 _minersCount, uint256 _hashRate)
    external
    onlyAuthorizedContracts
    nonReentrant
    {
        updatePool();
        for (uint256 minerId = _firstMinerId; minerId < _firstMinerId + _minersCount; minerId++) {
            require(!minersInfo[_user][minerId].isStaked, "Mining: Miner is already Attached");
            _deposit(_user, minerId, _hashRate);
        }
    }

    function withdraw(address _user, uint256 _minerId)
    external
    onlyAuthorizedContracts
    nonReentrant
    onlyAttachedMiner(_user, _minerId)
    {
        updatePool();
        _withdraw(_user, _minerId);
    }

    function claim(uint256 _minerId) external nonReentrant {
        _claim(msg.sender, _minerId);
    }

    function claimAll() external nonReentrant {
        _claimAll(msg.sender);
    }


    function _withdraw(address _user, uint256 _minerId) private {
        MinerInfo storage miner = minersInfo[_user][_minerId];
        UserInfo storage _userInfo = userInfo[_user];
        PoolInfo storage pool = poolInfo;
        EnumerableSetUpgradeable.UintSet storage userIndexToMinerId = userToMiners[_user];
        _claim(_user, _minerId);
        miner.rewardDebt = (miner.hashrate * (pool.accRewardPerShare)) / (1e18);

        _userInfo.totalHashRate -= miner.hashrate;
        totalHashRate -= miner.hashrate;

        miner.isStaked = false;
        miner.hashrate = 0;
        miner.lastAmortization = ((block.timestamp - miner.unstakeTimestamp) / 86400) / 10;
        miner.unstakeTimestamp = block.timestamp;
        userIndexToMinerId.remove(_minerId);
        _userInfo.minersCount = userIndexToMinerId.length();

        emit Withdraw(_minerId);
    }

    function _deposit(address _user, uint256 _minerId, uint256 _hashrate) private {
        MinerInfo storage miner = minersInfo[_user][_minerId];
        UserInfo storage _userInfo = userInfo[_user];
        PoolInfo storage pool = poolInfo;
        EnumerableSetUpgradeable.UintSet storage userIndexToMinerId = userToMiners[_user];
        uint256 timestamp = block.timestamp + SECONDS_PER_MONTH;
        if (miner.electricityLastDay > 0) {
            timestamp = miner.electricityLastDay;
        }

        miner.hashrate = _hashrate;
        miner.rewardDebt = (miner.hashrate * (pool.accRewardPerShare)) / (1e18);
        miner.electricityLastDay = timestamp;
        miner.stakedTimestamp = block.timestamp;
        miner.unstakeTimestamp = block.timestamp;
        miner.lastAmortization = 1000;
        miner.lastUpdated = 0;
        miner.totalClaims = 0;
        miner.minerId = _minerId;
        miner.isStaked = true;

        userIndexToMinerId.add(_minerId);
        // miner = stakingDetails;
        _userInfo.totalHashRate += _hashrate;
        _userInfo.minersCount = userIndexToMinerId.length();
        totalHashRate += _hashrate;
        emit Deposit(_minerId);
    }

    function _claim(address _user, uint256 _minerId) private {
        MinerInfo storage miner = minersInfo[_user][_minerId];
        UserInfo storage _userInfo = userInfo[_user];
        updatePool();
        PoolInfo storage pool = poolInfo;

        uint256 pending = pendingReward(_user, _minerId);

        if (pending > 0) {
            rewardToken.safeTransfer(_user, pending);

            _userInfo.totalClaims += pending;
            totalMintedTokens += pending;
            miner.totalClaims += pending;
            emit Claim(_user, _minerId, pending);
        }
        miner.rewardDebt =
        (miner.hashrate * (pool.accRewardPerShare)) /
        (1e18);
    }

    function _claimAll(address _user) internal {
        UserInfo storage _userInfo = userInfo[_user];
        EnumerableSetUpgradeable.UintSet storage userIndexToMinerId = userToMiners[_user];
        PoolInfo storage pool = poolInfo;
        updatePool();
        uint256 totalPending = 0;
        for (uint256 i = 0; i < userIndexToMinerId.length(); i++) {
            uint256 _minerId = userIndexToMinerId.at(i);
            MinerInfo storage miner = minersInfo[_user][_minerId];
            uint256 pending = pendingReward(_user, _minerId);

            if (pending > 0) {
                totalPending += pending;
                miner.totalClaims += pending;
               
            }
             miner.rewardDebt = (miner.hashrate * (pool.accRewardPerShare)) / (1e18);
        }
        if (totalPending > 0) {
            _userInfo.totalClaims += totalPending;
            totalMintedTokens += totalPending;
            rewardToken.safeTransfer(_user, totalPending);
        }
        emit Claim(_user, 0, totalPending);
    }


    function getPendingRewardsFromAllMiners(address _user) external view returns (uint256)  {
        EnumerableSetUpgradeable.UintSet storage userIndexToMinerId = userToMiners[_user];

        uint256 totalRewards = 0;
        for (uint256 i = 0; i < userIndexToMinerId.length(); i++) {
            totalRewards += _getPendingRewards(_user, userIndexToMinerId.at(i));
        }

        return totalRewards;
    }

    function pendingReward(address _user, uint256 _minerId) public view returns (uint256) {
        return _getPendingRewards(_user, _minerId);
    }

    function getMinersCount(address _user) public view returns (uint256) {
        UserInfo memory _userInfo = userInfo[_user];
        return _userInfo.minersCount;
    }

    function _getPendingRewards(address _user, uint256 _minerId) private view returns (uint256) {
        MinerInfo storage miner = minersInfo[_user][_minerId];

        if (!miner.isStaked) {
            return 0;
        }

        PoolInfo storage pool = poolInfo;
        if (block.timestamp > miner.electricityLastDay) {
            uint256 userAccRewardPerShare = rewardSharesByDays[getDateTimeConcat(miner.electricityLastDay)];
            uint256 userAccReward = miner.hashrate * userAccRewardPerShare / 1e18;
            return userAccReward > miner.rewardDebt
                                 ? userAccReward - miner.rewardDebt
                                 : 0;
        }

        uint256 _accRewardPerShare = pool.accRewardPerShare;
        uint256 sharesTotal = totalHashRate;

        if (block.number > pool.lastRewardBlock && sharesTotal != 0) {
            uint256 _multiplier = block.number - pool.lastRewardBlock;
            uint256 _reward = (_multiplier * rewardPerBlock);
            _accRewardPerShare = _accRewardPerShare + ((_reward * 1e18) / sharesTotal);
        }

        return
        (miner.hashrate * _accRewardPerShare) / (1e18) - (miner.rewardDebt);
    }

    function updatePool() public {
        PoolInfo storage pool = poolInfo;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 sharesTotal = totalHashRate;
        if (sharesTotal == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number - pool.lastRewardBlock;
        if (multiplier <= 0) {
            return;
        }
        uint256 _reward = (multiplier * rewardPerBlock);
        pool.accRewardPerShare = pool.accRewardPerShare + ((_reward * 1e18) / sharesTotal);
        rewardSharesByDays[getDateTimeConcat(block.timestamp)] = pool.accRewardPerShare;

        pool.lastRewardBlock = block.number;
    }

    function getDateTimeConcat(uint256 _timestamp) public pure returns (uint256) {
        (uint256 year,uint256 month,uint256 day) = DateTime.timestampToDate(_timestamp);
        uint256 date;
        if(year == 2022 && month <= 9) 
            date = (year * 1000) + (month * 100) + day;
        else 
            date = (year * 10000) + (month * 100) + day;
        return date;
    }
}