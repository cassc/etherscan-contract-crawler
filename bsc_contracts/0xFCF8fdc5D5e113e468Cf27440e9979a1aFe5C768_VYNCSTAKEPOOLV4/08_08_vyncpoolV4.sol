// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface BusdPrice {
    function price() external view returns (uint256); // price in 18 decimals
}

interface GetDataInterface {
    function returnData()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function returnAprData()
        external
        view
        returns (
            uint256,
            uint256,
            bool
        );

    function returnMaxStakeUnstake()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface TreasuryInterface {
    function send(address, uint256) external;
}

interface VyncMigrate {
    struct userInfoData {
        uint256 stakeBalanceWithReward;
        uint256 stakeBalance;
        uint256 lastClaimedReward;
        uint256 lastStakeUnstakeTimestamp;
        uint256 lastClaimTimestamp;
        bool isStaker;
        uint256 totalClaimedReward;
        uint256 autoClaimWithStakeUnstake;
        uint256 pendingRewardAfterFullyUnstake;
        bool isClaimAferUnstake;
        uint256 nextCompoundDuringStakeUnstake;
        uint256 nextCompoundDuringClaim;
        uint256 lastCompoundedRewardWithStakeUnstakeClaim;
        uint256 stakedVync;
    }

    function userInfo(address) external view returns (userInfoData memory);

    function compoundedReward(address user) external view returns (uint256);
}

contract VYNCSTAKEPOOLV4 is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeMath for uint256;

    struct stakeInfoData {
        uint256 compoundStart;
        bool isCompoundStartSet;
    }

    struct userInfoData {
        uint256 stakeBalanceWithReward;
        uint256 stakeBalance;
        uint256 lastClaimedReward;
        uint256 lastStakeUnstakeTimestamp;
        uint256 lastClaimTimestamp;
        bool isStaker;
        uint256 totalClaimedReward;
        uint256 autoClaimWithStakeUnstake;
        uint256 pendingRewardAfterFullyUnstake;
        bool isClaimAferUnstake;
        uint256 nextCompoundDuringStakeUnstake;
        uint256 nextCompoundDuringClaim;
        uint256 lastCompoundedRewardWithStakeUnstakeClaim;
        uint256 stakedVync;
    }

    IERC20 public vync;
    address public dataAddress;
    GetDataInterface data;
    address public busdPriceAddress;
    BusdPrice busdPrice;
    address public TreasuryAddress;
    TreasuryInterface treasury;
    address public migrateAddress;
    VyncMigrate migrate;
    mapping(address => userInfoData) public userInfo;
    mapping(address => bool) public isBlock;
    mapping(address => bool) public stopMigrate;
    stakeInfoData public stakeInfo;
    uint256 decimal4;
    uint256 decimal18;
    uint256 s; // total staking amount
    uint256 u; //total unstaking amount
    uint256 s_v; //total stake in vync
    uint256 u_v; // total unstake in vync
    bool public isClaim;
    bool public fixUnstakeAmount;
    uint256 public stake_fee;
    uint256 public unstake_fee;
    bool public isMigrate;

    event rewardClaim(address indexed user, uint256 rewards);
    event Stake(address account, uint256 stakeAmount);
    event UnStake(address account, uint256 unStakeAmount);
    event DataAddressSet(address newDataAddress);
    event TreasuryAddressSet(address newTreasuryAddresss);
    event SetCompoundStart(uint256 _blocktime);

    function initialize() public initializer {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        stakeInfo.compoundStart = block.timestamp;
        dataAddress = 0x408a227D9049d84770d311e1d279DDB2d875cc8A; // info address
        data = GetDataInterface(dataAddress);
        busdPriceAddress = 0x2486C1560C34598Bd22783C73a10265837B219ca; // busdinfo address
        busdPrice = BusdPrice(busdPriceAddress);
        TreasuryAddress = 0xe6D3c59e945202EAA617fA609b2275c11353f5D0; // treasury address
        treasury = TreasuryInterface(TreasuryAddress);
        migrateAddress = 0xd0889FDe4f3DeF6124fEdda26fc365c99b5F1C16; // old vync pool address
        migrate = VyncMigrate(migrateAddress);
        vync = IERC20(0xee1ae38BE4Ce0074C4A4A8DC821CC784778f378c);
        decimal4 = 1e4;
        isClaim = true;
        stake_fee = 5 * decimal4;
        unstake_fee = 5 * decimal4;
        isMigrate = true;
    }

    function set_compoundStart(uint256 _blocktime) public onlyOwner {
        require(stakeInfo.isCompoundStartSet == false, "already set once");
        stakeInfo.compoundStart = _blocktime;
        stakeInfo.isCompoundStartSet = true;
        emit SetCompoundStart(_blocktime);
    }

    function set_data(address _data) public onlyOwner {
        require(
            _data != address(0),
            "can not set zero address for data address"
        );
        dataAddress = _data;
        data = GetDataInterface(_data);
        emit DataAddressSet(_data);
    }

    function set_busdPriceAddress(address _address) public onlyOwner {
        require(_address != address(0),"can not set zero address for data address");
        busdPriceAddress = _address;
        busdPrice = BusdPrice(_address);
    }

    function set_treasuryAddress(address _treasury) public onlyOwner {
        require(
            _treasury != address(0),
            "can not set zero address for treasury address"
        );
        TreasuryAddress = _treasury;
        treasury = TreasuryInterface(_treasury);
        emit TreasuryAddressSet(_treasury);
    }

    function set_fee(uint256 _stakeFee, uint256 _unstakeFee) public onlyOwner {
        stake_fee = _stakeFee;
        unstake_fee = _unstakeFee;
    }

    function set_isClaim(bool _isClaim) public onlyOwner {
        isClaim = _isClaim;
    }

    function set_fixUnstakeAmount(bool _fix) public onlyOwner {
        fixUnstakeAmount = _fix;
    }

    function _block(address _address, bool is_Block) public onlyOwner {
        isBlock[_address] = is_Block;
    }

    function nextCompound() public view returns (uint256 _nextCompound) {
        (, uint256 compoundRate, ) = data.returnData();
        uint256 interval = block.timestamp - stakeInfo.compoundStart;
        interval = interval / compoundRate;
        _nextCompound =
            stakeInfo.compoundStart +
            compoundRate +
            interval *
            compoundRate;
    }
    
    function stake(uint256 amount) external nonReentrant {
        /// @notice Getting the storage reference.
        userInfoData storage _userInfo = userInfo[msg.sender];

        require(isBlock[msg.sender] == false, "blocked");

        /// @notice Returning max token stake & per tx token stake in VYNC
        (uint256 maxStakePerTx, , uint256 totalStakePerUser) = data.returnMaxStakeUnstake();
        require(amount <= maxStakePerTx, "exceed max stake limit for a tx");
        require(
            (_userInfo.stakeBalance + amount) <= totalStakePerUser,
            "exceed total stake limit"
        );

        uint256 vyncFee = stake_fee;
        require(amount > vyncFee, "amount less then stake_fee");
        amount -= vyncFee;
        vync.transferFrom(msg.sender, address(this), amount);
        vync.transferFrom(msg.sender, TreasuryAddress, vyncFee);

        _userInfo.lastCompoundedRewardWithStakeUnstakeClaim = lastCompoundedReward(msg.sender);

        if (_userInfo.isStaker) {
            uint256 _pendingReward = compoundedReward(msg.sender);
            uint256 cpending = cPendingReward(msg.sender);
            _userInfo.stakeBalanceWithReward = _userInfo.stakeBalance + _pendingReward;
            _userInfo.autoClaimWithStakeUnstake = _pendingReward;
            _userInfo.totalClaimedReward = 0;
            if (
                block.timestamp <
                _userInfo.nextCompoundDuringStakeUnstake
            ) {
                _userInfo.stakeBalanceWithReward += cpending;
                _userInfo.autoClaimWithStakeUnstake += cpending;
            }
        }

        _userInfo.stakeBalanceWithReward += amount;
        _userInfo.stakeBalance += amount;
        _userInfo.stakedVync += amount;
        _userInfo.lastStakeUnstakeTimestamp = block.timestamp;
        _userInfo.nextCompoundDuringStakeUnstake = nextCompound();
        _userInfo.isStaker = true;
        s += amount;
        s_v += amount;
        emit Stake(msg.sender, amount);
    }

    function unStake(uint256 amount) external nonReentrant {
        /// @notice Getting the storage reference.
        userInfoData storage _userInfo = userInfo[msg.sender];

        require(isBlock[msg.sender] == false, "blocked");
        require(
            amount <= _userInfo.stakedVync,
            "invalid staked amount"
        );

        /// @notice Returning MAX Vync token per tx
        (, uint256 maxUnstakePerTx, ) = data.returnMaxStakeUnstake();

        require(amount <= maxUnstakePerTx, "exceed unstake limit per tx");
        require(amount > unstake_fee, "amount less then unstake_fee");

        uint256 pending = compoundedReward(msg.sender);
        
        // reward update
        if (amount < _userInfo.stakeBalance) {
            uint256 _pendingReward = compoundedReward(msg.sender);

            _userInfo.lastCompoundedRewardWithStakeUnstakeClaim = lastCompoundedReward(msg.sender);
            _userInfo.autoClaimWithStakeUnstake = _pendingReward;
            _userInfo.lastStakeUnstakeTimestamp = block.timestamp;
            _userInfo.nextCompoundDuringStakeUnstake = nextCompound();
            _userInfo.totalClaimedReward = 0;
            _userInfo.stakeBalanceWithReward = _userInfo.stakeBalance - amount + _pendingReward;
            _userInfo.stakeBalance -= amount;
            
            _userInfo.stakedVync -= amount;

        } else if (amount >= _userInfo.stakeBalance) {
            u += _userInfo.stakeBalance;
            u_v += amount;
            _userInfo.pendingRewardAfterFullyUnstake = pending;
            _userInfo.isClaimAferUnstake = true;
            _userInfo.stakeBalanceWithReward = 0;
            _userInfo.stakeBalance = 0;
            _userInfo.stakedVync = 0;
            _userInfo.isStaker = false;
            _userInfo.totalClaimedReward = 0;
            _userInfo.autoClaimWithStakeUnstake = 0;
            _userInfo.lastCompoundedRewardWithStakeUnstakeClaim = 0;
        }

        if (_userInfo.pendingRewardAfterFullyUnstake == 0) {
            _userInfo.isClaimAferUnstake = false;
        }

        uint256 transferVync = (amount - unstake_fee);
        u += transferVync;
        u_v += transferVync + unstake_fee;
        vync.transfer(msg.sender, transferVync);
        vync.transfer(TreasuryAddress, unstake_fee);

        emit UnStake(msg.sender, transferVync);
    }

    function cPendingReward(address user)
        internal
        view
        returns (uint256 _compoundedReward)
    {
        uint256 reward;
        if (
            userInfo[user].lastClaimTimestamp <
            userInfo[user].nextCompoundDuringStakeUnstake &&
            userInfo[user].lastStakeUnstakeTimestamp <
            userInfo[user].nextCompoundDuringStakeUnstake
        ) {
            (uint256 a, uint256 compoundRate, ) = data.returnData();
            a = a / compoundRate;
            uint256 tsec = userInfo[user].nextCompoundDuringStakeUnstake -
                userInfo[user].lastStakeUnstakeTimestamp;
            uint256 stakeSec = block.timestamp -
                userInfo[user].lastStakeUnstakeTimestamp;
            uint256 sec = tsec > stakeSec ? stakeSec : tsec;
            uint256 balance = userInfo[user].stakeBalanceWithReward;
            reward = (balance.mul(a)).div(100);
            reward = reward / decimal4;
            _compoundedReward = reward * sec;
        }
    }

    function compoundedReward(address user)
        public
        view
        returns (uint256 _compoundedReward)
    {
        address _user = user;
        uint256 nextcompound = userInfo[user].nextCompoundDuringStakeUnstake;
        (, uint256 compoundRate, ) = data.returnData();
        uint256 compoundTime = block.timestamp > nextcompound
            ? block.timestamp - nextcompound
            : 0;
        uint256 loopRound = compoundTime / compoundRate;
        uint256 reward = 0;
        if (userInfo[user].isStaker == false) {
            loopRound = 0;
        }
        (uint256 a, , ) = data.returnData();
        _compoundedReward = 0;
        uint256 cpending = cPendingReward(user);
        uint256 balance = userInfo[user].stakeBalanceWithReward + cpending;

        for (uint256 i = 1; i <= loopRound; i++) {
            uint256 amount = balance.add(reward);
            reward = (amount.mul(a)).div(100);
            reward = reward / decimal4;
            _compoundedReward = _compoundedReward.add(reward);
            balance = amount;
        }

        if (_compoundedReward != 0) {
            uint256 sum = _compoundedReward +
                userInfo[user].autoClaimWithStakeUnstake;
            _compoundedReward = sum > userInfo[user].totalClaimedReward
                ? sum - userInfo[user].totalClaimedReward
                : 0;
            _compoundedReward = _compoundedReward + cPendingReward(user);
        }

        if (_compoundedReward == 0) {
            _compoundedReward = userInfo[user].autoClaimWithStakeUnstake;

            if (
                block.timestamp > userInfo[user].nextCompoundDuringStakeUnstake
            ) {
                _compoundedReward = _compoundedReward + cPendingReward(user);
            }
        }

        if (userInfo[user].isClaimAferUnstake == true) {
            _compoundedReward =
                _compoundedReward +
                userInfo[user].pendingRewardAfterFullyUnstake;
        }

        (
            uint256 aprChangeTimestamp,
            uint256 aprChangePercentage,
            bool isAprIncrease
        ) = data.returnAprData();

        if (userInfo[_user].lastStakeUnstakeTimestamp < aprChangeTimestamp) {
            if (isAprIncrease == false) {
                _compoundedReward =
                    _compoundedReward -
                    ((userInfo[_user].autoClaimWithStakeUnstake *
                        aprChangePercentage) / 100);
            }

            if (isAprIncrease == true) {
                _compoundedReward =
                    _compoundedReward +
                    ((userInfo[_user].autoClaimWithStakeUnstake *
                        aprChangePercentage) / 100);
            }
        }
    }

    function compoundedRewardInVync(address user)
        public
        view
        returns (uint256 _compoundedVyncReward)
    {
        // uint256 reward;
        // reward = compoundedReward(user);
        // uint256 _price = busdPrice.price();
        // _compoundedVyncReward = (reward * decimal4) / _price;

        _compoundedVyncReward = compoundedReward(user);
    }

    function pendingReward(address user)
        public
        view
        returns (uint256 _pendingReward)
    {
        address _user = user;
        uint256 nextcompound = userInfo[user].nextCompoundDuringStakeUnstake;
        (, uint256 compoundRate, ) = data.returnData();
        uint256 compoundTime = block.timestamp > nextcompound
            ? block.timestamp - nextcompound
            : 0;
        uint256 loopRound = compoundTime / compoundRate;
        uint256 reward = 0;
        (uint256 a, , ) = data.returnData();
        if (userInfo[user].isStaker == false) {
            loopRound = 0;
        }
        _pendingReward = 0;
        uint256 cpending = cPendingReward(user);
        uint256 balance = userInfo[user].stakeBalanceWithReward + cpending;

        for (uint256 i = 1; i <= loopRound + 1; i++) {
            uint256 amount = balance.add(reward);
            reward = (amount.mul(a)).div(100);
            reward = reward / decimal4;
            _pendingReward = _pendingReward.add(reward);
            balance = amount;
        }

        if (_pendingReward != 0) {
            _pendingReward =
                _pendingReward -
                userInfo[user].totalClaimedReward +
                userInfo[user].autoClaimWithStakeUnstake +
                cPendingReward(user);

            if (
                block.timestamp < userInfo[user].nextCompoundDuringStakeUnstake
            ) {
                _pendingReward =
                    userInfo[user].autoClaimWithStakeUnstake +
                    cPendingReward(user);
            }
        }

        if (userInfo[user].isClaimAferUnstake == true) {
            _pendingReward =
                _pendingReward +
                userInfo[user].pendingRewardAfterFullyUnstake;
        }

        (
            uint256 aprChangeTimestamp,
            uint256 aprChangePercentage,
            bool isAprIncrease
        ) = data.returnAprData();

        if (userInfo[_user].lastStakeUnstakeTimestamp < aprChangeTimestamp) {
            if (isAprIncrease == false) {
                _pendingReward =
                    _pendingReward -
                    ((userInfo[_user].autoClaimWithStakeUnstake *
                        aprChangePercentage) / 100);
            }

            if (isAprIncrease == true) {
                _pendingReward =
                    _pendingReward +
                    ((userInfo[_user].autoClaimWithStakeUnstake *
                        aprChangePercentage) / 100);
            }
        }

        _pendingReward = _pendingReward - compoundedReward(user);
    }

    function pendingRewardInVync(address user)
        public
        view
        returns (uint256 _pendingVyncReward)
    {
        // uint256 reward;
        // reward = pendingReward(user);
        // uint256 _price = busdPrice.price();
        // _pendingVyncReward = (reward * decimal4) / _price;

        _pendingVyncReward = pendingReward(user);
    }

    function lastCompoundedReward(address user)
        public
        view
        returns (uint256 _compoundedReward)
    {
        uint256 nextcompound = userInfo[user].nextCompoundDuringStakeUnstake;
        (, uint256 compoundRate, ) = data.returnData();
        uint256 compoundTime = block.timestamp > nextcompound
            ? block.timestamp - nextcompound
            : 0;
        compoundTime = compoundTime > compoundRate
            ? compoundTime - compoundRate
            : 0;
        uint256 loopRound = compoundTime / compoundRate;
        uint256 reward = 0;
        if (userInfo[user].isStaker == false) {
            loopRound = 0;
        }
        (uint256 a, , ) = data.returnData();
        _compoundedReward = 0;
        uint256 cpending = cPendingReward(user);
        uint256 balance = userInfo[user].stakeBalanceWithReward + cpending;

        for (uint256 i = 1; i <= loopRound; i++) {
            uint256 amount = balance.add(reward);
            reward = (amount.mul(a)).div(100);
            reward = reward / decimal4;
            _compoundedReward = _compoundedReward.add(reward);
            balance = amount;
        }

        if (_compoundedReward != 0) {
            uint256 sum = _compoundedReward +
                userInfo[user].autoClaimWithStakeUnstake;
            _compoundedReward = sum > userInfo[user].totalClaimedReward
                ? sum - userInfo[user].totalClaimedReward
                : 0;
            _compoundedReward = _compoundedReward + cPendingReward(user);
        }

        if (_compoundedReward == 0) {
            _compoundedReward = userInfo[user].autoClaimWithStakeUnstake;

            if (
                block.timestamp >
                userInfo[user].nextCompoundDuringStakeUnstake + compoundRate
            ) {
                _compoundedReward = _compoundedReward + cPendingReward(user);
            }
        }

        if (userInfo[user].isClaimAferUnstake == true) {
            _compoundedReward =
                _compoundedReward +
                userInfo[user].pendingRewardAfterFullyUnstake;
        }

        uint256 result = compoundedReward(user) - _compoundedReward;

        if (
            block.timestamp < userInfo[user].nextCompoundDuringStakeUnstake ||
            block.timestamp < userInfo[user].nextCompoundDuringClaim
        ) {
            result =
                result +
                userInfo[user].lastCompoundedRewardWithStakeUnstakeClaim;
        }

        _compoundedReward = result;
    }

    function rewardCalculation(address user) internal {
        (, uint256 compoundRate, ) = data.returnData();
        address _user = user;
        uint256 nextcompound = userInfo[user].nextCompoundDuringStakeUnstake;
        uint256 compoundTime = block.timestamp > nextcompound
            ? block.timestamp - nextcompound
            : 0;
        uint256 loopRound = compoundTime / compoundRate;
        (uint256 a, , ) = data.returnData();
        uint256 reward;
        if (userInfo[user].isStaker == false) {
            loopRound = 0;
        }
        uint256 totalReward;
        uint256 cpending = cPendingReward(user);
        uint256 balance = userInfo[user].stakeBalanceWithReward + cpending;

        for (uint256 i = 1; i <= loopRound; i++) {
            uint256 amount = balance.add(reward);
            reward = (amount.mul(a)).div(100);
            reward = reward / decimal4;
            totalReward = totalReward.add(reward);
            balance = amount;
        }

        if (userInfo[user].isClaimAferUnstake == true) {
            totalReward =
                totalReward +
                userInfo[user].pendingRewardAfterFullyUnstake;
        }
        totalReward = totalReward + cPendingReward(user);
        userInfo[user].lastClaimedReward =
            totalReward -
            userInfo[user].totalClaimedReward;
        userInfo[user].totalClaimedReward =
            userInfo[user].totalClaimedReward +
            userInfo[user].lastClaimedReward -
            cPendingReward(user);

        (
            uint256 aprChangeTimestamp,
            uint256 aprChangePercentage,
            bool isAprIncrease
        ) = data.returnAprData();

        if (userInfo[_user].lastStakeUnstakeTimestamp < aprChangeTimestamp) {
            if (isAprIncrease == false) {
                userInfo[_user].autoClaimWithStakeUnstake =
                    userInfo[_user].autoClaimWithStakeUnstake -
                    ((userInfo[_user].autoClaimWithStakeUnstake *
                        aprChangePercentage) / 100);
            }

            if (isAprIncrease == true) {
                userInfo[_user].autoClaimWithStakeUnstake =
                    userInfo[_user].autoClaimWithStakeUnstake +
                    (((userInfo[_user].autoClaimWithStakeUnstake) *
                        aprChangePercentage) / 100);
            }
        }
    }

    function claim() public nonReentrant {
        require(isClaim == true, "claim stopped");
        require(isBlock[msg.sender] == false, "blocked");
        require(
            userInfo[msg.sender].isStaker == true ||
                userInfo[msg.sender].isClaimAferUnstake == true,
            "user not staked"
        );
        userInfo[msg.sender]
            .lastCompoundedRewardWithStakeUnstakeClaim = lastCompoundedReward(
            msg.sender
        );

        rewardCalculation(msg.sender);
        uint256 reward = userInfo[msg.sender].lastClaimedReward +
            userInfo[msg.sender].autoClaimWithStakeUnstake;
        require(reward > 0, "can't reap zero reward");

        // uint256 _price = busdPrice.price();
        // uint256 rewardAmount = (reward * decimal4) / _price;

        treasury.send(msg.sender, reward);
        emit rewardClaim(msg.sender, reward);
        if (userInfo[msg.sender].autoClaimWithStakeUnstake != 0) {
            userInfo[msg.sender].stakeBalanceWithReward =
                userInfo[msg.sender].stakeBalanceWithReward -
                userInfo[msg.sender].autoClaimWithStakeUnstake;
        }
        userInfo[msg.sender].autoClaimWithStakeUnstake = 0;
        userInfo[msg.sender].nextCompoundDuringStakeUnstake = nextCompound();
        userInfo[msg.sender].lastStakeUnstakeTimestamp = block.timestamp;
        userInfo[msg.sender].lastClaimTimestamp = block.timestamp;
        userInfo[msg.sender].nextCompoundDuringClaim = nextCompound();

        if (
            userInfo[msg.sender].isClaimAferUnstake == true &&
            userInfo[msg.sender].isStaker == false
        ) {
            userInfo[msg.sender].lastStakeUnstakeTimestamp = 0;
            userInfo[msg.sender].lastClaimedReward = 0;
            userInfo[msg.sender].totalClaimedReward = 0;
        }

        if (
            userInfo[msg.sender].isClaimAferUnstake == true &&
            userInfo[msg.sender].isStaker == true
        ) {
            userInfo[msg.sender].totalClaimedReward =
                userInfo[msg.sender].totalClaimedReward -
                userInfo[msg.sender].pendingRewardAfterFullyUnstake;
        }
        bool c = userInfo[msg.sender].isClaimAferUnstake;
        if (c == true) {
            userInfo[msg.sender].pendingRewardAfterFullyUnstake = 0;
            userInfo[msg.sender].isClaimAferUnstake = false;
        }

        userInfo[msg.sender].totalClaimedReward = 0;
    }

    function totalStake() external view returns (uint256 stakingAmount) {
        stakingAmount = s;
    }

    function totalUnstake() external view returns (uint256 unstakingAmount) {
        unstakingAmount = u;
    }

    function totalStakeInVync() external view returns (uint256 stakingAmount) {
        stakingAmount = s_v;
    }

    function totalUnstakeInVync()
        external
        view
        returns (uint256 unstakingAmount)
    {
        unstakingAmount = u_v;
    }

    function transferAnyERC20Token(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        IERC20(_tokenAddress).transfer(_to, _amount);
    }

    function vyncPrice() public view returns (uint256 _price) {
        _price = busdPrice.price();
    }

    function set_migrate(bool _isMigrate) public onlyOwner {
        isMigrate = _isMigrate;
    }

    function _stopMigrate(address _address) public onlyOwner {
        stopMigrate[_address] = true;
    }

    function setMigratePoolAddress(address _address) public onlyOwner {
        migrateAddress = _address;
        migrate = VyncMigrate(migrateAddress);
    }

    function migrateStaking() public {
        address staker = msg.sender;
        require(isMigrate == true, "migration off");
        require(stopMigrate[staker] == false, "already migrate");

        uint256 _compoundReward = compoundedReward(staker);
        VyncMigrate.userInfoData memory user = migrate.userInfo(staker);

        userInfo[staker].stakeBalanceWithReward =
            userInfo[staker].stakeBalanceWithReward +
            user.stakeBalance +
            migrate.compoundedReward(staker) +
            _compoundReward;
        userInfo[staker].stakeBalance =
            userInfo[staker].stakeBalance +
            user.stakeBalance;
        userInfo[staker].lastClaimedReward = 0;
        userInfo[staker].lastStakeUnstakeTimestamp = block.timestamp;
        userInfo[staker].lastClaimTimestamp = block.timestamp;
        userInfo[staker].isStaker = true;
        userInfo[staker].totalClaimedReward = 0;
        userInfo[staker].autoClaimWithStakeUnstake =
            _compoundReward +
            migrate.compoundedReward(staker);
        userInfo[staker].pendingRewardAfterFullyUnstake =
            userInfo[staker].pendingRewardAfterFullyUnstake +
            user.pendingRewardAfterFullyUnstake;
        userInfo[staker].isClaimAferUnstake = user.isClaimAferUnstake;
        userInfo[staker].nextCompoundDuringStakeUnstake = nextCompound();
        userInfo[staker].nextCompoundDuringClaim = nextCompound();
        userInfo[staker].lastCompoundedRewardWithStakeUnstakeClaim = user
            .lastCompoundedRewardWithStakeUnstakeClaim;
        s = s + user.stakeBalance;
        stopMigrate[staker] = true;
    }

    function migrateStakingByOwner(address[] calldata _stakers)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _stakers.length; i++) {
            address staker = _stakers[i];
            require(stopMigrate[staker] == false, "already migrate");

            uint256 _compoundReward = compoundedReward(staker);
            VyncMigrate.userInfoData memory user = migrate.userInfo(staker);

            userInfo[staker].stakeBalanceWithReward =
                userInfo[staker].stakeBalanceWithReward +
                user.stakeBalance +
                migrate.compoundedReward(staker) +
                _compoundReward;
            userInfo[staker].stakeBalance =
                userInfo[staker].stakeBalance +
                user.stakeBalance;
            userInfo[staker].lastClaimedReward = 0;
            userInfo[staker].lastStakeUnstakeTimestamp = block.timestamp;
            userInfo[staker].lastClaimTimestamp = block.timestamp;
            userInfo[staker].isStaker = true;
            userInfo[staker].totalClaimedReward = 0;
            userInfo[staker].autoClaimWithStakeUnstake =
                _compoundReward +
                migrate.compoundedReward(staker);
            userInfo[staker].pendingRewardAfterFullyUnstake =
                userInfo[staker].pendingRewardAfterFullyUnstake +
                user.pendingRewardAfterFullyUnstake;
            userInfo[staker].isClaimAferUnstake = user.isClaimAferUnstake;
            userInfo[staker].nextCompoundDuringStakeUnstake = nextCompound();
            userInfo[staker].nextCompoundDuringClaim = nextCompound();
            userInfo[staker].lastCompoundedRewardWithStakeUnstakeClaim = user
                .lastCompoundedRewardWithStakeUnstakeClaim;
            s = s + user.stakeBalance;
            stopMigrate[staker] = true;
        }
    }

    // function manualMigrateByOwner(
    //     address staker,
    //     uint256 stakeBalance,
    //     uint256 compoundAmount
    // ) public onlyOwner {
    //     require(stopMigrate[staker] == false, "already migrate");
    //     uint256 _compoundReward = compoundedReward(staker);

    //     userInfo[staker].stakeBalanceWithReward =
    //         userInfo[staker].stakeBalanceWithReward +
    //         stakeBalance +
    //         compoundAmount +
    //         _compoundReward;
    //     userInfo[staker].stakeBalance =
    //         userInfo[staker].stakeBalance +
    //         stakeBalance;
    //     userInfo[staker].lastClaimedReward = 0;
    //     userInfo[staker].lastStakeUnstakeTimestamp = block.timestamp;
    //     userInfo[staker].lastClaimTimestamp = block.timestamp;
    //     userInfo[staker].isStaker = true;
    //     userInfo[staker].totalClaimedReward = 0;
    //     userInfo[staker].autoClaimWithStakeUnstake =
    //         _compoundReward +
    //         compoundAmount;
    //     userInfo[staker].pendingRewardAfterFullyUnstake = 0;
    //     userInfo[staker].isClaimAferUnstake = false;
    //     userInfo[staker].nextCompoundDuringStakeUnstake = nextCompound();
    //     userInfo[staker].nextCompoundDuringClaim = nextCompound();
    //     userInfo[staker].lastCompoundedRewardWithStakeUnstakeClaim = 0;
    //     s = s + stakeBalance;
    //     stopMigrate[staker] = true;
    // }

    function manualMigrateByOwnerToken(
        address staker,
        uint256 stakeTokenBalance,
        uint256 compoundTokenAmount,
        bool attachPrevBalance
    ) public onlyOwner {
        /// @notice Taking storage reference
        userInfoData storage _userInfo = userInfo[staker];

        if(attachPrevBalance) {
            _userInfo.stakeBalanceWithReward += (stakeTokenBalance + compoundTokenAmount);
            _userInfo.stakeBalance += stakeTokenBalance;
            _userInfo.stakedVync += stakeTokenBalance;
            _userInfo.autoClaimWithStakeUnstake += compoundTokenAmount;
        } else {
            _userInfo.stakeBalanceWithReward = (stakeTokenBalance + compoundTokenAmount);
            _userInfo.stakeBalance = stakeTokenBalance;
            _userInfo.stakedVync = stakeTokenBalance;
            _userInfo.autoClaimWithStakeUnstake = compoundTokenAmount;
        }

        _userInfo.lastClaimedReward = 0;
        _userInfo.lastStakeUnstakeTimestamp = block.timestamp;
        _userInfo.lastClaimTimestamp = block.timestamp;
        _userInfo.isStaker = true;
        _userInfo.totalClaimedReward = 0;
        _userInfo.pendingRewardAfterFullyUnstake = 0;
        _userInfo.isClaimAferUnstake = false;
        _userInfo.nextCompoundDuringStakeUnstake = nextCompound();
        _userInfo.nextCompoundDuringClaim = nextCompound();
        _userInfo.lastCompoundedRewardWithStakeUnstakeClaim = 0;

        s += stakeTokenBalance;
        s_v += stakeTokenBalance;
    }

    function st(uint256 staked, uint256 unstaked) public onlyOwner {
        require(staked >= unstaked, "Staked should be more than or equals to unstaked.");
        s = staked; u = unstaked;
        s_v = staked; u_v = unstaked;
    }
}