// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/*
// FOX BLOCKCHAIN \\

FoxChain works to connect all Blockchains in one platform with one click access to any network.

Website     : https://foxchain.app/
Dex         : https://foxdex.finance/
Telegram    : https://t.me/FOXCHAINNEWS
Twitter     : https://twitter.com/FoxchainLabs
Github      : https://github.com/FoxChainLabs

*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@fox.chain/contracts/contracts/v0.8/access/ContractWhitelist.sol";
import "./interfaces/IRewarderV2.sol";
import "./interfaces/IMasterFoxV2.sol";
import "./interfaces/IMasterFox.sol";

contract MasterFoxV2 is
    IMasterFoxV2,
    Initializable,
    Ownable,
    ContractWhitelist,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    /// @notice Info of each user's pool deposit
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided
        uint256 rewardDebt; // Reward debt. See explanation below
    }

    /// @notice Info of each pool.
    struct PoolInfo {
        IERC20 stakeToken; // Address of stake token contract.
        IRewarderV2 rewarder; // Address of rewarder contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. FOXLAYERs to distribute per block.
        uint256 totalStaked; // Amount of tokens staked in given pool
        uint256 lastRewardTime; // Last timestamp FOXLAYERs distribution occurs.
        uint256 accFoxlayerPerShare; // Accumulated FOXLAYERs per share, times SCALING_FACTOR. Check code.
        uint16 depositFeeBP; // Deposit fee in basis points
    }

    /// @notice Address which is eligible to accept ownership of the MasterFoxV1. Set by the current owner.
    address public pendingMasterFoxV1Owner;
    /// @notice Address of MAV1 contract.
    IMasterFox public immutable MasterFox;
    /// @notice The pool id of the MAV2 mock token pool in MAV1.
    uint256 public immutable masterPid;
    /// @notice The FOXLAYER TOKEN!
    IERC20 public immutable foxlayer;
    ///  @notice 10 FOXLAYERs per block in MAV1
    uint256 public constant MASTER_FOX_FOXLAYER_PER_BLOCK = 10 ether;
    /// @notice BNB Chain has 3 second block times at the time of deployment
    uint256 public constant MASTER_FOX_FOXLAYER_PER_SECOND_ESTIMATE =
        MASTER_FOX_FOXLAYER_PER_BLOCK / 3;
    uint256 public foxlayerPerSecond;
    uint256 public hardCap = 420000000 ether;
    /// @notice keeps track of unallocated FOXLAYER in the contract
    uint256 public unallocatedFoxlayer;
    /// @notice keeps track of the reward FOXLAYER balance in the contract
    uint256 public availableFoxlayerRewards;

    /// @notice Deposit Fee address
    address public feeAddress;
    /// @dev Max deposit fee is 10% or 1000 BP
    uint256 public constant MAX_DEPOSIT_FEE_BP = 1000;
    uint256 private constant DEPOSIT_FEE_BP = 10000;
    /// @dev Scaling this up increases support for high supply tokens
    uint256 private constant SCALING_FACTOR = 1e18;

    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;

    /// @notice Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// @notice Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    /// @dev tracks existing pools to avoid duplicates
    mapping(IERC20 => bool) public poolExistence;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event DepositFoxlayerRewards(address indexed user, uint256 amount);
    event UpdateEmissionRate(address indexed user, uint256 foxlayerPerSecond);
    event UpdateHardCap(address indexed user, uint256 hardCap);

    event LogPoolAddition(
        uint256 indexed pid,
        uint256 allocPoint,
        IERC20 indexed stakeToken,
        uint16 depositFee,
        IRewarderV2 indexed rewarder
    );
    event LogSetPool(
        uint256 indexed pid,
        uint256 allocPoint,
        uint16 depositFee,
        IRewarderV2 indexed rewarder
    );
    event LogUpdatePool(
        uint256 indexed pid,
        uint256 lastRewardBlock,
        uint256 stakeSupply,
        uint256 accFoxlayerPerShare
    );
    event SetPendingMasterFoxV1Owner(address pendingMasterFoxOwner);

    /// @dev modifier to avoid adding duplicate pools
    modifier nonDuplicated(IERC20 _stakeToken) {
        require(
            poolExistence[_stakeToken] == false,
            "nonDuplicated: duplicated"
        );
        _;
    }

    /// @param foxlayer_ the address of the FOXLAYER token
    /// @param MasterFox_ the address of MasterFox
    /// @param masterPid_ the pool id that will control all allocations
    /// @param foxlayerPerSecond_ the emission rates by second
    constructor(
        IERC20 foxlayer_,
        IMasterFox MasterFox_,
        uint256 masterPid_,
        uint256 foxlayerPerSecond_
    ) {
        foxlayer = foxlayer_;
        MasterFox = MasterFox_;
        masterPid = masterPid_;
        _updateEmissionRate(foxlayerPerSecond_);
        /// @dev init foxlayer pool with an allocation of 0
        add(0, foxlayer_, false, 0, IRewarderV2(address(0)));
    }

    /// @notice Deposits a dummy token to `MasterFox` MAV1.
    /// This is required because MAV1 holds the minting permission of FOXLAYER.
    /// It will transfer all the `dummyToken` in the tx sender address.
    /// The allocation point for the dummy pool on MAV1 should be equal to the total amount of allocPoint.
    function initialize() external initializer onlyOwner {
        (address lpToken, , , ) = MasterFox.getPoolInfo(masterPid);
        IERC20 dummyToken = IERC20(lpToken);
        uint256 balance = dummyToken.balanceOf(msg.sender);
        require(balance != 0, "MasterFoxV2: bad balance");
        dummyToken.safeTransferFrom(msg.sender, address(this), balance);
        dummyToken.approve(address(MasterFox), balance);
        MasterFox.deposit(masterPid, balance);
    }

    /// @notice deposit tokens on behalf of sender
    /// @dev depositTo is nonReentrant
    /// @param _pid pool id in which to make deposit
    /// @param _amount amount of tokens to deposit
    function deposit(uint256 _pid, uint256 _amount) external {
        depositTo(_pid, _amount, msg.sender);
    }

    /// @notice withdraw tokens on behalf of sender
    /// @dev withdrawTo is nonReentrant
    /// @param _pid pool id in which to make withdraw
    /// @param _amount amount of tokens to withdraw
    function withdraw(uint256 _pid, uint256 _amount) external {
        withdrawTo(_pid, _amount, msg.sender);
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) external nonReentrant {
        _updatePool(_pid);
    }

    /// @notice Harvests FOXLAYER from `MasterFox` MAV1 and pool `masterPid` to MAV2.
    function harvestFromMasterFox() external nonReentrant {
        _harvestFromMasterFox();
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        uint256 lastPoolStake = pool.totalStaked;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.totalStaked -= amount;
        // Handle onReward
        if (address(pool.rewarder) != address(0)) {
            pool.rewarder.onReward(
                _pid,
                msg.sender,
                msg.sender,
                0,
                0,
                lastPoolStake
            );
        }
        pool.stakeToken.safeTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /// @notice updates the deposit fee receiver
    /// @param _feeAddress address that receives the fee
    function setFeeAddress(address _feeAddress) external {
        require(
            msg.sender == feeAddress || msg.sender == owner(),
            "setFeeAddress: FORBIDDEN"
        );
        require(_feeAddress != address(0), "setFeeAddress: address(0)");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    /// @notice updates the emission rate
    /// @dev reverts if above 3.33 per second
    /// @param _foxlayerPerSecond how many FOXLAYER per second
    /// @param _withUpdate flag to call massUpdatePool before update
    function updateEmissionRate(
        uint256 _foxlayerPerSecond,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        _updateEmissionRate(_foxlayerPerSecond);
    }

    /// @notice Set an address as the pending admin of the MasterFox. The address must accept to take ownership.
    /// @param _pendingMasterFoxV1Owner Address to set as the pending owner of the MasterFox.
    function setPendingMasterFoxV1Owner(
        address _pendingMasterFoxV1Owner
    ) external onlyOwner {
        pendingMasterFoxV1Owner = _pendingMasterFoxV1Owner;
        emit SetPendingMasterFoxV1Owner(pendingMasterFoxV1Owner);
    }

    /// @notice The pendingMasterFoxOwner takes ownership through this call
    /// @dev Transferring MasterFox ownership away from this contract can brick this contract.
    function acceptMasterFoxV1Ownership() external {
        require(msg.sender == pendingMasterFoxV1Owner, "not pending owner");
        MasterFox.transferOwnership(pendingMasterFoxV1Owner);
        pendingMasterFoxV1Owner = address(0);
    }

    /// @notice updates the hard cap
    /// @dev reverts if less than current
    /// @param _hardCap the new hard cap
    function updateHardCap(uint256 _hardCap) external onlyOwner {
        _updateHardCap(_hardCap);
    }

    /// @notice returns the amount of pools created
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @notice View function to see pending FOXLAYERs on frontend.
    /// @param _pid PID on which to check pending FOXLAYER
    /// @param _user address of which balance is being checked on
    function pendingFoxlayer(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accFoxlayerPerShare = pool.accFoxlayerPerShare;
        uint256 stakeSupply = pool.totalStaked;
        if (
            block.timestamp > pool.lastRewardTime &&
            stakeSupply != 0 &&
            totalAllocPoint != 0
        ) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 foxlayerReward = (multiplier *
                foxlayerPerSecond *
                pool.allocPoint) / totalAllocPoint;
            accFoxlayerPerShare +=
                (foxlayerReward * SCALING_FACTOR) /
                stakeSupply;
        }
        return
            ((user.amount * accFoxlayerPerShare) / SCALING_FACTOR) -
            user.rewardDebt;
    }

    /// @notice Adds a new pool into the Master Fox
    /// @param _allocPoint allocation points of new pool
    /// @param _stakeToken stake token of new pool. It cannot be duplicated
    /// @param _withUpdate if we should mass update all existing pools
    /// @param _depositFeeBP the basis points of the deposit fee
    /// @param _rewarder A rewarder compliant smart contract
    function add(
        uint256 _allocPoint,
        IERC20 _stakeToken,
        bool _withUpdate,
        uint16 _depositFeeBP,
        IRewarderV2 _rewarder
    ) public onlyOwner nonDuplicated(_stakeToken) {
        require(
            _depositFeeBP <= MAX_DEPOSIT_FEE_BP,
            "add: invalid deposit fee"
        );

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardTime = block.timestamp;
        totalAllocPoint += _allocPoint;
        poolExistence[_stakeToken] = true;

        poolInfo.push(
            PoolInfo({
                stakeToken: _stakeToken,
                rewarder: _rewarder,
                allocPoint: _allocPoint,
                lastRewardTime: lastRewardTime,
                accFoxlayerPerShare: 0,
                totalStaked: 0,
                depositFeeBP: _depositFeeBP
            })
        );

        emit LogPoolAddition(
            poolInfo.length - 1,
            _allocPoint,
            _stakeToken,
            _depositFeeBP,
            _rewarder
        );
    }

    /// @notice  Update the given pool's FOXLAYER allocation point and deposit fee. Can only be called by the owner.
    /// @param _pid id of pool to update
    /// @param _allocPoint allocation points of new pool
    /// @param _withUpdate if we should mass update all existing pools
    /// @param _depositFeeBP the basis points of the deposit fee
    /// @param _rewarder A rewarder compliant smart contract
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate,
        uint16 _depositFeeBP,
        IRewarderV2 _rewarder
    ) external onlyOwner {
        require(
            _depositFeeBP <= MAX_DEPOSIT_FEE_BP,
            "set: invalid deposit fee"
        );
        if (_withUpdate) {
            massUpdatePools();
        } else {
            _updatePool(_pid);
        }

        totalAllocPoint =
            (totalAllocPoint - poolInfo[_pid].allocPoint) +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].rewarder = _rewarder;

        emit LogSetPool(_pid, _allocPoint, _depositFeeBP, _rewarder);
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    /// @notice Deposit tokens to MasterFox for FOXLAYER allocation.
    /// @param _pid pool id in which to make deposit
    /// @param _amount amount of tokens to deposit
    /// @param _to who receives the staked amount
    function depositTo(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) public nonReentrant checkEOAorWhitelist {
        _updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_to];
        uint256 finalDepositAmount;
        uint256 pendingRewards;
        if (user.amount > 0) {
            pendingRewards =
                ((user.amount * pool.accFoxlayerPerShare) / SCALING_FACTOR) -
                user.rewardDebt;
            if (pendingRewards > 0) {
                _safeFoxlayerTransfer(_to, pendingRewards);
            }
        }
        if (_amount > 0) {
            // Prefetch balance to account for transfer fees
            IERC20 stakeToken = pool.stakeToken;
            uint256 preStakeBalance = stakeToken.balanceOf(address(this));
            stakeToken.safeTransferFrom(msg.sender, address(this), _amount);
            finalDepositAmount =
                stakeToken.balanceOf(address(this)) -
                preStakeBalance;

            if (pool.depositFeeBP > 0) {
                uint256 depositFee = (finalDepositAmount * pool.depositFeeBP) /
                    DEPOSIT_FEE_BP;
                stakeToken.safeTransfer(feeAddress, depositFee);
                finalDepositAmount -= depositFee;
            }

            user.amount += finalDepositAmount;
        }
        // Handle onReward
        if (address(pool.rewarder) != address(0)) {
            pool.rewarder.onReward(
                _pid,
                _to,
                _to,
                pendingRewards,
                user.amount,
                pool.totalStaked
            );
        }
        /// @dev pool.totalStaked must be updated after rewarder.onReward()
        pool.totalStaked += finalDepositAmount;
        user.rewardDebt =
            (user.amount * pool.accFoxlayerPerShare) /
            SCALING_FACTOR;
        emit Deposit(_to, _pid, finalDepositAmount);
    }

    /// @notice Withdraw tokens from MasterFox.
    /// @param _pid pool id in which to make withdraw
    /// @param _amount amount of tokens to withdraw
    /// @param _to address who receives the withdrawn amount
    function withdrawTo(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) public nonReentrant {
        _updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: insufficient");
        uint256 pendingRewards = ((user.amount * pool.accFoxlayerPerShare) /
            SCALING_FACTOR) - user.rewardDebt;
        if (pendingRewards > 0) {
            _safeFoxlayerTransfer(_to, pendingRewards);
        }
        user.amount -= _amount;
        // Handle onReward
        if (address(pool.rewarder) != address(0)) {
            pool.rewarder.onReward(
                _pid,
                msg.sender,
                _to,
                pendingRewards,
                user.amount,
                pool.totalStaked
            );
        }
        if (_amount > 0) {
            /// @dev pool.totalStaked must be updated after rewarder.onReward()
            pool.totalStaked -= _amount;
            pool.stakeToken.safeTransfer(_to, _amount);
        }
        user.rewardDebt =
            (user.amount * pool.accFoxlayerPerShare) /
            SCALING_FACTOR;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Deposits FOXLAYER from `MasterFox` MAV1 and pool `masterPid` to MAV2.
    /// @param _amount Amount of FOXLAYER to add to FOXLAYER rewards
    function depositFoxlayerRewards(
        uint256 _amount
    ) external nonReentrant checkEOAorWhitelist {
        require(_amount > 0, "amount is 0");
        foxlayer.safeTransferFrom(msg.sender, address(this), _amount);
        unallocatedFoxlayer += _amount;
        availableFoxlayerRewards += _amount;
        emit DepositFoxlayerRewards(msg.sender, _amount);
    }

    /// @notice returns all pool info
    function getPoolInfo(
        uint256 _pid
    )
        public
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            IRewarderV2 rewarder,
            uint256 lastRewardTime,
            uint256 accFoxlayerPerShare,
            uint256 totalStaked,
            uint16 depositFeeBP
        )
    {
        return (
            address(poolInfo[_pid].stakeToken),
            poolInfo[_pid].allocPoint,
            poolInfo[_pid].rewarder,
            poolInfo[_pid].lastRewardTime,
            poolInfo[_pid].accFoxlayerPerShare,
            poolInfo[_pid].totalStaked,
            poolInfo[_pid].depositFeeBP
        );
    }

    /// @notice Return reward multiplier over the given _from to _to block.
    /// @param _from from what timestamp
    /// @param _to to what timestamp
    /// @return uint256
    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public pure returns (uint256) {
        return _to - _from;
    }

    /// @dev Safe foxlayer transfer function, just in case if rounding error causes pool to not have enough FOXLAYERs.
    function _safeFoxlayerTransfer(address _to, uint256 _amount) internal {
        if (_amount > availableFoxlayerRewards) {
            _harvestFromMasterFox();
        }
        /// @dev availableFoxlayerRewards is updated inside harvestFromMasterFox()
        if (_amount > availableFoxlayerRewards) {
            _amount = availableFoxlayerRewards;
            availableFoxlayerRewards = 0;
            foxlayer.safeTransfer(_to, _amount);
        } else {
            availableFoxlayerRewards -= _amount;
            foxlayer.safeTransfer(_to, _amount);
        }
    }

    function _updateEmissionRate(uint256 _foxlayerPerSecond) private {
        require(
            _foxlayerPerSecond <= MASTER_FOX_FOXLAYER_PER_SECOND_ESTIMATE,
            "More than maximum rate"
        );
        foxlayerPerSecond = _foxlayerPerSecond;
        emit UpdateEmissionRate(msg.sender, _foxlayerPerSecond);
    }

    function _updateHardCap(uint256 _hardCap) private {
        require(
            _hardCap > foxlayer.totalSupply(),
            "Updated cap is less than total supply"
        );
        hardCap = _hardCap;
        emit UpdateHardCap(msg.sender, _hardCap);
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 stakeSupply = pool.totalStaked;
        if (stakeSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(
            pool.lastRewardTime,
            block.timestamp
        );
        pool.lastRewardTime = block.timestamp;
        uint256 poolFoxlayer = (multiplier *
            foxlayerPerSecond *
            pool.allocPoint) / totalAllocPoint;
        if (poolFoxlayer == 0) return;
        if (poolFoxlayer > unallocatedFoxlayer) _harvestFromMasterFox();
        /// @dev FOXLAYER hard cap and emissions will be hit at separate times. This handles the emission rate.
        if (
            foxlayer.totalSupply() + poolFoxlayer - unallocatedFoxlayer > hardCap
        ) {
            // This is true when assigning more rewards than possible within the bounds of the hardcap
            _harvestFromMasterFox();
            // Make sure we have the latest number for unallocatedFoxlayer before doing any crazy stuff
            if (poolFoxlayer >= unallocatedFoxlayer) {
                // This can only be true if emissions stopped
                // (or if we are allocating more than 3.333 per second which should not be possible)
                // See _updateEmissionRate
                poolFoxlayer = unallocatedFoxlayer;
                if (foxlayerPerSecond != 0) {
                    // If we get here MasterFoxV1 Emissions already stopped
                    // we allocate the remainder unallocatedFoxlayer and stop emissions on MAv2
                    _updateEmissionRate(0);
                }
            }
        }
        /// @dev This ensures that enough rewards were harvested from MasterFoxV1. This can happen when:
        ///  1. `MasterFoxV2.foxlayerPerSecond()` is set too HIGH compared to `MasterFoxV1.foxlayerPerBlock() * MasterFoxV1.BONUS_MULTIPLIER()`
        ///  2. More FOXLAYER rewards need to be deposited through `MasterFoxV2.depositFoxlayerRewards()`
        require(
            unallocatedFoxlayer >= poolFoxlayer,
            "updatePool: Rewards misallocation"
        );
        unallocatedFoxlayer -= poolFoxlayer;
        pool.accFoxlayerPerShare += (poolFoxlayer * SCALING_FACTOR) / stakeSupply;
        emit LogUpdatePool(
            _pid,
            pool.lastRewardTime,
            stakeSupply,
            pool.accFoxlayerPerShare
        );
    }

    /// @notice Harvests FOXLAYER from `MasterFox` MAV1 and pool `masterPid` to MAV2.
    function _harvestFromMasterFox() internal returns (uint256 newFoxlayer) {
        // TEST that this works with ghost farm for this set to zero
        uint256 beforeFoxlayerBal = foxlayer.balanceOf(address(this));
        MasterFox.deposit(masterPid, 0);
        newFoxlayer = foxlayer.balanceOf(address(this)) - beforeFoxlayerBal;
        unallocatedFoxlayer += newFoxlayer;
        availableFoxlayerRewards += newFoxlayer;

        uint256 foxlayerTotalSupply = foxlayer.totalSupply();
        if (
            foxlayerTotalSupply >= hardCap && MasterFox.BONUS_MULTIPLIER() > 0
        ) {
            /// @dev FOXLAYER hard cap and emissions will be hit at separate times. This handles the hard cap.
            MasterFox.updateMultiplier(0);
            uint256 surplus = foxlayerTotalSupply - hardCap;
            if (availableFoxlayerRewards >= surplus) {
                unallocatedFoxlayer = unallocatedFoxlayer > surplus
                    ? unallocatedFoxlayer - surplus
                    : 0;
                _safeFoxlayerTransfer(
                    0x000000000000000000000000000000000000dEaD,
                    surplus
                );
            } else {
                /// @dev These are safeguards to avoid bricking the contract
                /// nevertheless off-chain checks and interactions should make this case impossible
                /// This happens when the hard-cap block is missed by so much
                /// that the surplus in the dev wallet exceeds what this contract can burn by itself
                unallocatedFoxlayer = 0;
                _safeFoxlayerTransfer(
                    0x000000000000000000000000000000000000dEaD,
                    availableFoxlayerRewards
                );
            }
        }
    }
}