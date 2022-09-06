// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../lib/access/OwnableUpgradeable.sol";
import "../lib/util/ArrayUtil.sol";
import "../NFT/base/IBaseNftUpgradeable.sol";
import "../NFT/base/IMultiModelNftUpgradeable.sol";
import "../PriceOracle/IPriceOracleUpgradeable.sol";

contract LPStakingUpgradeable is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    /* 
    Basically, any point in time, the amount of ZONEs entitled to a user but is pending to be distributed is:
    
    pending ZONE = (user.lpAmount * pool.accZONEPerLP) - user.finishedZONE
    
    Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    1. The pool's `accZONEPerLP` (and `lastRewardTime`) gets updated.
    2. User receives the pending ZONE sent to his/her address.
    3. User's `lpAmount` gets updated.
    4. User's `finishedZONE` gets updated.
    */
    struct Pool {
        // Address of LP token
        address lpTokenAddress;
        // Total amount deposited
        uint256 lpSupply;
        // Weight of pool
        uint256 poolWeight;
        // Last block timestamp that ZONEs distribution occurs for pool
        uint256 lastRewardTime;
        // Accumulated ZONEs per LP of pool
        uint256 accZONEPerLP; 
        // Pool ID of this pool
        uint256 pid;
    }

    struct User {
        // LP token amount that user provided
        uint256 lpAmount;     
        // Finished distributed ZONEs to user
        uint256 finishedZONE;
        // Timestamp of the deposit at the time that lpAmount is zero, or the timestamp of the last withdrawal. The locked period is calculated from this timestamp
        uint256 lockStartTime;
    }

    uint256 private constant SECONDS_IN_DAY = 24 * 3600;

    uint256 private constant LP_LOCKED_AMOUNT = 5856918985268619881152;
    uint256 private constant LP_UNLOCK_DATE = 1693612800;

    // Total pool weight / Sum of all pool weights
    uint256 public totalPoolWeight;
    // Array of pools
    Pool[] public pool;
    // LP token => pool
    mapping (address => Pool) public poolMap;

    // pool id => user address => user info
    mapping (uint256 => mapping (address => User)) public user;
    // Minimum deposit amount in ETH
    uint256 public minDepositAmountInEth;

    bool public rewardInZoneEnabled;
    bool public rewardInNftEnabled;
    bool private _lpUnlockedFromUniswapV2Locker;

    // First block that DAOstake will start from
    uint256 public START_TIME;
    // Locking period to get reward
    uint256 public lockPeriod;
    // ZONE tokens distributed per block.
    uint256 public zonePerMinute;

    // ZONE amount finished by changing ZONE per minute
    uint256 private _totalFinishedZONE;
    // Last block timestamp that _totalFinishedZONE updated
    uint256 private _lastFinishUpdateTime;
    // ZONE tokens which not distributed because there are no depositor
    uint256 public unusedZone;

    // Addresse of NFT contract to reward
    address[] public nftAddresses;
    // Model id of the NFT to reward. If the NFT doesn't have a model, the value is uint256.max
    uint256[] public nftModels;
    // Price in ETH. This arrays is expected to be sorted in ascending order, and to contain no repeated elements.
    uint256[] public nftPrices;

    IERC20Upgradeable public zoneToken;
    IPriceOracleUpgradeable public priceOracle;

    address public governorTimelock;

    event SetLockPeriod(uint256 newLockPeriod);
    event SetZonePerMinute(uint256 newZonePerMinute);
    event SetMinDepositAmountInEth(uint256 newMinDepositAmountInEth);
    event EnableRewardInZone(bool enabled);
    event EnableRewardInNft(bool enabled);
    event AddPool(address indexed lpTokenAddress, uint256 indexed poolWeight, uint256 indexed lastRewardTime);
    event SetPoolWeight(uint256 indexed poolId, uint256 indexed poolWeight, uint256 totalPoolWeight);
    event UpdatePool(uint256 indexed poolId, uint256 indexed lastRewardTime, uint256 rewardToPool);
    event Deposit(address indexed account, uint256 indexed poolId, uint256 amount);
    event Withdraw(address indexed account, uint256 indexed poolId, uint256 amount);
    event RewardZone(address indexed account, uint256 indexed poolId, uint256 amount);
    event RewardNft(address indexed account, uint256 indexed poolId, address indexed rewardNftAddress, uint256 rewardNftModel, uint256 rewardNftPrice);
    event RemoveRewardNft(address indexed rewardNftAddress, uint256 indexed rewardNftModel, uint256 indexed rewardNftPrice);
    event EmergencyWithdraw(address indexed account, uint256 indexed poolId, uint256 amount);

    modifier onlyOwnerOrCommunity() {
        address sender = _msgSender();
        require((owner() == sender) || (governorTimelock == sender), "The caller should be owner or governor");
        _;
    }

    /**
     * @notice Initializes the contract.
     * @param _ownerAddress Address of owner
     * @param _priceOracle Library contract for the mint price
     * @param _zonePerMinute ZONE tokens distributed per block
     * @param _minDepositAmountInEth Minimum deposit amount in ETH
     * @param _nftAddresses Addresse of NFT contract
     * @param _nftModels Model id of the NFT. If the NFT doesn't have a model, the value is uint256.max
     * @param _nftPrices Price in ETH. This arrays is expected to be sorted in ascending order, and to contain no repeated elements.
     */
    function initialize(
        address _ownerAddress,
        address _priceOracle,
        uint256 _zonePerMinute,
        uint256 _minDepositAmountInEth,
        address[] memory _nftAddresses,
        uint256[] memory _nftModels,
        uint256[] memory _nftPrices
    ) public initializer {
        require(_ownerAddress != address(0), "Owner address is invalid");
        require(_priceOracle != address(0), "Price oracle address is invalid");

        __Ownable_init(_ownerAddress);
        __ReentrancyGuard_init();

        rewardInZoneEnabled = true;
        rewardInNftEnabled = true;

        lockPeriod = 180 * SECONDS_IN_DAY; // 180 days by default
        START_TIME = block.timestamp;
        _lastFinishUpdateTime = START_TIME;

        priceOracle = IPriceOracleUpgradeable(_priceOracle);
        zoneToken = IERC20Upgradeable(priceOracle.zoneToken());
        zonePerMinute = _zonePerMinute;
        minDepositAmountInEth = _minDepositAmountInEth;
        _setRewardNfts(_nftAddresses, _nftModels, _nftPrices);

        _addPool(address(priceOracle.lpZoneEth()), 100, false);
        pool[0].lpSupply = LP_LOCKED_AMOUNT;
    }

    function setGovernorTimelock(address _governorTimelock) external onlyOwner()  {
        governorTimelock = _governorTimelock;
    }

    /* Update the locking period */
    function setLockPeriod(uint256 _lockPeriod) external onlyOwnerOrCommunity() {
        require(SECONDS_IN_DAY * 30 <= _lockPeriod, "lockDay should be equal or greater than 30 day");
        lockPeriod = _lockPeriod;
        emit SetLockPeriod(lockPeriod);
    }

    /* Update ZONE tokens per block */
    function setZonePerMinute(uint256 _zonePerMinute) external onlyOwnerOrCommunity() {
        _setZonePerMinute(_zonePerMinute);
    }

    function _setZonePerMinute(uint256 _zonePerMinute) private {
        massUpdatePools();

        uint256 multiplier = _getMultiplier(_lastFinishUpdateTime, block.timestamp);
        _totalFinishedZONE = _totalFinishedZONE.add(multiplier.mul(zonePerMinute));
        _lastFinishUpdateTime = block.timestamp;

        zonePerMinute = _zonePerMinute;
        emit SetZonePerMinute(zonePerMinute);
    }

    /* Update the locking period */
    function setMinDepositAmountInEth(uint256 _minDepositAmountInEth) external onlyOwnerOrCommunity() {
        minDepositAmountInEth = _minDepositAmountInEth;
        emit SetMinDepositAmountInEth(minDepositAmountInEth);
    }

    /* Finish the rewarding */
    function finish() external onlyOwnerOrCommunity() {
        if (0 < zonePerMinute) {
            _setZonePerMinute(0);
        }
        uint256 length = poolLength();
        for (uint256 pid = 0; pid < length; pid++) {
            Pool memory pool_ = pool[pid];
            if (0 < pool_.lpSupply) {
                return;
            }
        }
        uint256 zoneBalance = zoneToken.balanceOf(address(this));
        if (0 < zoneBalance) {
            zoneToken.safeTransfer(owner(), zoneBalance);
        }
    }

    function enableRewardInZone(bool _enable) external onlyOwnerOrCommunity() {
        rewardInZoneEnabled = _enable;
        emit EnableRewardInZone(rewardInZoneEnabled);
    }

    function enableRewardInNft(bool _enable) external onlyOwnerOrCommunity() {
        rewardInNftEnabled = _enable;
        emit EnableRewardInNft(rewardInNftEnabled);
    }

    /**
     * @notice Set the array of NFTs to reward.
     * @param _contractAddresses Addresse of NFT contract
     * @param _modelIds Model id of the NFT. If the NFT doesn't have a model, the value is uint256.max
     * @param _pricesInEth Price in ETH. This arrays is expected to be sorted in ascending order, and to contain no repeated elements.
     */
    function setRewardNfts(
        address[] memory _contractAddresses,
        uint256[] memory _modelIds,
        uint256[] memory _pricesInEth
    ) external onlyOwner() {
        _setRewardNfts(_contractAddresses, _modelIds, _pricesInEth);
    }

    function _setRewardNfts(
        address[] memory _contractAddresses,
        uint256[] memory _modelIds,
        uint256[] memory _pricesInEth
    ) internal {
        require(
            _contractAddresses.length == _modelIds.length
            && _contractAddresses.length == _pricesInEth.length,
            "Mismatched data"
        );

        nftAddresses = _contractAddresses;
        nftModels = _modelIds;
        nftPrices = _pricesInEth;
    }

    /** 
     * @notice Return reward multiplier over given _from to _to block. [_from, _to)
     * 
     * @param _from    From block timestamp (included)
     * @param _to      To block timestamp (exluded)
     */
    function _getMultiplier(uint256 _from, uint256 _to) internal pure returns(uint256 multiplier) {
        return _to.sub(_from).div(60);
    }

    /** 
     * @notice Get pending ZONE amount of user in pool
     */
    function pendingZONE(uint256 _pid, address _account) public view returns(uint256) {
        Pool storage pool_ = pool[_pid];
        if (pool_.lpSupply == 0) {
            // If lpSupply is zero, it means that the user's lpAmount is also zero.
            return 0;
        }

        User storage user_ = user[_pid][_account];
        uint256 accZONEPerLP = pool_.accZONEPerLP;

        if (pool_.lastRewardTime < block.timestamp) {
            uint256 multiplier = _getMultiplier(pool_.lastRewardTime, block.timestamp);
            uint256 rewardToPool = multiplier.mul(zonePerMinute).mul(pool_.poolWeight).div(totalPoolWeight);
            accZONEPerLP = accZONEPerLP.add(rewardToPool.mul(1 ether).div(pool_.lpSupply));
        }

        return user_.lpAmount.mul(accZONEPerLP).div(1 ether).sub(user_.finishedZONE);
    }

    /**
     * @notice return the total finished ZONE amount
     */
    function totalFinishedZONE() public view returns(uint256) {
        uint256 multiplier = _getMultiplier(_lastFinishUpdateTime, block.timestamp);
        return _totalFinishedZONE.add(multiplier.mul(zonePerMinute));
    }

    /**
     * @notice Get the length/amount of pool
     */
    function poolLength() public view returns(uint256) {
        return pool.length;
    }

    /** 
     * @notice Add a new LP to pool. Can only be called by owner
     * DO NOT add the same LP token more than once. ZONE rewards will be messed up if you do
     */
    function addPool(address _lpTokenAddress, uint256 _poolWeight, bool _withUpdate) external onlyOwner() {
        _addPool(_lpTokenAddress, _poolWeight, _withUpdate);
    }

    function _addPool(address _lpTokenAddress, uint256 _poolWeight, bool _withUpdate) private {
        require(_lpTokenAddress.isContract(), "LP token address should be smart contract address");
        require(poolMap[_lpTokenAddress].lpTokenAddress == address(0), "LP token already added");

        if (_withUpdate) {
            massUpdatePools();
        }
        
        uint256 lastRewardTime = START_TIME < block.timestamp ? block.timestamp : START_TIME;
        totalPoolWeight = totalPoolWeight + _poolWeight;

        Pool memory newPool_ = Pool({
            lpTokenAddress: _lpTokenAddress,
            lpSupply: 0,
            poolWeight: _poolWeight,
            lastRewardTime: lastRewardTime,
            accZONEPerLP: 0,
            pid: poolLength()
        });

        pool.push(newPool_);
        poolMap[_lpTokenAddress] = newPool_;

        emit AddPool(_lpTokenAddress, _poolWeight, lastRewardTime);
    }

    /** 
     * @notice Update the given pool's weight. Can only be called by owner.
     */
    function setPoolWeight(uint256 _pid, uint256 _poolWeight, bool _withUpdate) external onlyOwnerOrCommunity() {
        if (_withUpdate) {
            massUpdatePools();
        }

        totalPoolWeight = totalPoolWeight.sub(pool[_pid].poolWeight).add(_poolWeight);
        pool[_pid].poolWeight = _poolWeight;

        emit SetPoolWeight(_pid, _poolWeight, totalPoolWeight);
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function updatePool(uint256 _pid) public {
        Pool storage pool_ = pool[_pid];
        if (block.timestamp <= pool_.lastRewardTime) {
            return;
        }

        uint256 multiplier = _getMultiplier(pool_.lastRewardTime, block.timestamp);
        uint256 rewardToPool = multiplier.mul(zonePerMinute).mul(pool_.poolWeight).div(totalPoolWeight);

        if (0 < pool_.lpSupply) {
            pool_.accZONEPerLP = pool_.accZONEPerLP.add(rewardToPool.mul(1 ether).div(pool_.lpSupply));
        } else {
            unusedZone = unusedZone.add(rewardToPool);
        }

        if (_pid == 0 && _lpUnlockedFromUniswapV2Locker == false && LP_UNLOCK_DATE < block.timestamp) {
            // LP tokens unlocked in UniswapV2Locker.
            pool_.lpSupply = pool_.lpSupply.sub(LP_LOCKED_AMOUNT);
            _lpUnlockedFromUniswapV2Locker = true;
        }

        pool_.lastRewardTime = block.timestamp;
        emit UpdatePool(_pid, pool_.lastRewardTime, rewardToPool);
    }

    /** 
     * @notice Update reward variables for all pools. Be careful of gas spending!
     * Due to gas limit, please make sure here no significant amount of pools!
     */
    function massUpdatePools() public {
        uint256 length = poolLength();
        for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
        }
    }

    function _getClaimIn(uint256 _lockStartTime) internal view returns(uint256) {
        uint256 endTs = _lockStartTime.add(lockPeriod);
        return (block.timestamp < endTs) ? endTs - block.timestamp : 0;
    }

    function _chooseRewardNft(uint256 _zoneAmount) internal view returns(bool, uint256) {
        uint256 rewardAmountInEth = priceOracle.getOutAmount(address(zoneToken), _zoneAmount);
        (bool found, uint256 index) = ArrayUtil.findLowerBound(nftPrices, rewardAmountInEth);
        return (found, index);
    }

    function getStakeInfo(uint256 _pid, address _account) external view returns (
        uint256 stakedAmount,
        uint256 claimIn,
        uint256 rewardAmount,
        address rewardNftAddress,
        uint256 rewardNftModel,
        uint256 rewardNftPrice
    ) {
        User storage user_ = user[_pid][_account];
        if (user_.lpAmount == 0) {
            return (0, 0, 0, address(0), 0, 0);
        }

        stakedAmount = user_.lpAmount;
        claimIn = _getClaimIn(user_.lockStartTime);
        rewardAmount = pendingZONE(_pid, _account);

        (bool found, uint256 index) = _chooseRewardNft(rewardAmount);
        if (found == true) {
            rewardNftAddress = nftAddresses[index];
            rewardNftModel = nftModels[index];
            rewardNftPrice = nftPrices[index];
        }
    }

    function getMinDepositLpAmount() public view returns(uint256) {
        uint256 lpPriceInEth = priceOracle.getLPFairPrice();
        return (0 < minDepositAmountInEth && 0 < lpPriceInEth) ? minDepositAmountInEth.mul(1e18).div(lpPriceInEth) : 0;
    }

    /** 
     * @notice Deposit LP tokens for ZONE rewards
     * Before depositing, user needs approve this contract to be able to spend or transfer their LP tokens
     *
     * @param _pid       Id of the pool to be deposited to
     * @param _amount    Amount of LP tokens to be deposited
     */
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant() {
        // require(0 < _pid || minDepositAmountInEth == 0 || getMinDepositLpAmount() <= _amount, "The worth of LP amount should greater than minimum value");

        // address _account = _msgSender();
        // Pool storage pool_ = pool[_pid];
        // User storage user_ = user[_pid][_account];

        // updatePool(_pid);

        // uint256 pendingZONE_;
        // if (user_.lpAmount > 0) {
        //     // Reward will be transferred in the withdrawal and claiming
        //     pendingZONE_ = user_.lpAmount.mul(pool_.accZONEPerLP).div(1 ether).sub(user_.finishedZONE);
        // } else {
        //     user_.lockStartTime = block.timestamp;
        // }

        // if(_amount > 0) {
        //     uint256 prevSupply = IERC20Upgradeable(pool_.lpTokenAddress).balanceOf(address(this));
        //     IERC20Upgradeable(pool_.lpTokenAddress).safeTransferFrom(_account, address(this), _amount);
        //     uint256 newSupply = IERC20Upgradeable(pool_.lpTokenAddress).balanceOf(address(this));
        //     uint256 depositedAmount = newSupply.sub(prevSupply);
        //     user_.lpAmount = user_.lpAmount.add(depositedAmount);
        //     pool_.lpSupply = pool_.lpSupply.add(depositedAmount);
        // }

        // user_.finishedZONE = user_.lpAmount.mul(pool_.accZONEPerLP).div(1 ether).sub(pendingZONE_);
        // emit Deposit(_account, _pid, _amount);
    }

    /** 
     * @notice Withdraw LP tokens
     *
     * @param _pid       Id of the pool to be withdrawn from
     * @param _amount    amount of LP tokens to be withdrawn
     */
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant() {
        address _account = _msgSender();
        Pool storage pool_ = pool[_pid];
        User storage user_ = user[_pid][_account];
        require(_amount <= user_.lpAmount, "Not enough LP token balance");

        updatePool(_pid);

        uint256 pendingZONE_ = user_.lpAmount.mul(pool_.accZONEPerLP).div(1 ether).sub(user_.finishedZONE);
        uint256 claimIn = _getClaimIn(user_.lockStartTime);
        if(0 < pendingZONE_ && claimIn == 0) {
            _reward(_pid, _account, pendingZONE_);
            pendingZONE_ = 0;
        } else if(0 < _amount) {
            // remove pending amount related to the withdrawing share
            pendingZONE_ = pendingZONE_.mul(user_.lpAmount.sub(_amount)).div(user_.lpAmount);
        }
        user_.lockStartTime = block.timestamp;

        if(0 < _amount) {
            pool_.lpSupply = pool_.lpSupply.sub(_amount);
            user_.lpAmount = user_.lpAmount.sub(_amount);
            IERC20Upgradeable(pool_.lpTokenAddress).safeTransfer(_account, _amount);
        }

        user_.finishedZONE = user_.lpAmount.mul(pool_.accZONEPerLP).div(1 ether).sub(pendingZONE_);
        emit Withdraw(_account, _pid, _amount);
    }

    /** 
     * @notice Claim rewards
     *
     * @param _pid       Id of the pool to be withdrawn from
     */
    function claim(uint256 _pid) external nonReentrant() {
        address _account = _msgSender();
        Pool storage pool_ = pool[_pid];
        User storage user_ = user[_pid][_account];

        updatePool(_pid);

        uint256 pendingZONE_ = user_.lpAmount.mul(pool_.accZONEPerLP).div(1 ether).sub(user_.finishedZONE);
        require(0 < pendingZONE_, "No pending ZONE to reward");

        uint256 claimIn = _getClaimIn(user_.lockStartTime);
        require(claimIn == 0, "The reward not allowed yet. please wait for more"); 

        _reward(_pid, _account, pendingZONE_);

        user_.finishedZONE = user_.lpAmount.mul(pool_.accZONEPerLP).div(1 ether);
    }

    function _reward(uint256 _pid, address _account, uint256 _pendingZONE) private {
        if (rewardInZoneEnabled) {
            _safeZONETransfer(_account, _pendingZONE);
            emit RewardZone(_account, _pid, _pendingZONE);
        }

        if (rewardInNftEnabled) {
            (bool found, uint256 index) = _chooseRewardNft(_pendingZONE);
            if (found == true) {
                address rewardNftAddress = nftAddresses[index];
                uint256 rewardNftModel = nftModels[index];
                uint256 rewardNftPrice = nftPrices[index];

                uint256 leftCapacity;
                if (rewardNftModel != type(uint256).max) {
                    IMultiModelNftUpgradeable multiModelNft = IMultiModelNftUpgradeable(rewardNftAddress);
                    address[] memory addresses = new address[](1);
                    addresses[0] = _account;
                    leftCapacity = multiModelNft.doAirdrop(rewardNftModel, addresses);
                } else {
                    IBaseNftUpgradeable baseNft = IBaseNftUpgradeable(rewardNftAddress);
                    address[] memory addresses = new address[](1);
                    addresses[0] = _account;
                    leftCapacity = baseNft.doAirdrop(addresses);
                }
                emit RewardNft(_account, _pid, rewardNftAddress, rewardNftModel, rewardNftPrice);

                if (leftCapacity == 0) {
                    // remove the reward NFT from the list
                    nftAddresses[index] = nftAddresses[nftAddresses.length - 1];
                    nftAddresses.pop();
                    nftModels[index] = nftModels[nftModels.length - 1];
                    nftModels.pop();
                    nftPrices[index] = nftPrices[nftPrices.length - 1];
                    nftPrices.pop();
                    emit RemoveRewardNft(rewardNftAddress, rewardNftModel, rewardNftPrice);
                }
            }
        }
    }

    /**
     * @notice Withdraw LP tokens without caring about rewards. EMERGENCY ONLY
     *
     * @param _pid    Id of the pool to be emergency withdrawn from
     */
    function emergencyWithdraw(uint256 _pid) external nonReentrant() {
        address _account = _msgSender();
        Pool storage pool_ = pool[_pid];
        User storage user_ = user[_pid][_account];

        uint256 amount = user_.lpAmount;
        user_.lpAmount = 0;
        pool_.lpSupply = pool_.lpSupply.sub(amount);
        IERC20Upgradeable(pool_.lpTokenAddress).safeTransfer(_account, amount);
        emit EmergencyWithdraw(_account, _pid, amount);
    }

    /** 
     * @notice Safe ZONE transfer function, just in case if rounding error causes pool to not have enough ZONEs
     *
     * @param _to        Address to get transferred ZONEs
     * @param _amount    Amount of ZONE to be transferred
     */
    function _safeZONETransfer(address _to, uint256 _amount) internal {
        uint256 balance = zoneToken.balanceOf(address(this));
        
        if (balance < _amount) {
            zoneToken.safeTransfer(_to, balance);
        } else {
            zoneToken.safeTransfer(_to, _amount);
        }
    }

    // fund the contract with ZONE. _from address must have approval to execute ZONE Token Contract transferFrom
    function fund(address _from, uint256 _amount) external {
        require(_from != address(0), '_from is invalid');
        require(0 < _amount, '_amount is invalid');
        require(_amount <= zoneToken.balanceOf(_from), 'Insufficient balance');
        zoneToken.safeTransferFrom(_from, address(this), _amount);
    }
}

contract LPStakingUpgradeableProxy is TransparentUpgradeableProxy {
    constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) public {
    }
}