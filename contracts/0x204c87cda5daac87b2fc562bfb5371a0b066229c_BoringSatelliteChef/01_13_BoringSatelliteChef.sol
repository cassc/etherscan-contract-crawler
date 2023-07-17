// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/ILiquidate.sol";
import "../interface/IERC20Metadata.sol";
import "../interface/IOracle.sol";
import "../interface/IPair.sol";
import "../lib/SafeDecimalMath.sol";

contract BoringSatelliteChef is Ownable, ILiquidateArray {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeDecimalMath for uint256;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of BORINGs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBoringPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBoringPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    // The first pool is a virtual pool. You can’t actually get rewards by depositing
    // the corresponding tokens in the pool. It is only used to adjust the block output
    // of boring tokens.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. BORINGs to distribute per block.
        uint256 lastRewardBlock; // Last block number that BORINGs distribution occurs.
        uint256 accBoringPerShare; // Accumulated BORINGs per share, times 1e12. See below.
        bool isSingle; // single token or LP token
        uint256 _type; // 0 normal pool; 1 satelite pool
    }
    // The BORING TOKEN!
    IERC20 public boring;
    // BORING tokens created per block.
    uint256 public boringPerBlock;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BORING mining starts.
    uint256 public startBlock;
    uint256 public endBlock;
    address public dispatcher;

    address public liquidation;
    bool public tvlSwitcher;

    IOracle public oracle;
    uint256 public tvl;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        IERC20 _boring,
        address _dispatcher,
        uint256 _boringPerBlock,
        uint256 _startBlock,
        address _liquidation,
        address _oracle
    ) public {
        boring = _boring;
        boringPerBlock = _boringPerBlock;
        startBlock = _startBlock;
        // temporary peroid
        endBlock = block.number.add(10000000);
        dispatcher = _dispatcher;
        liquidation = _liquidation;
        tvlSwitcher = true;
        oracle = IOracle(_oracle);
    }

    function setTVLSwitcher(bool _status) external onlyOwner {
        tvlSwitcher = _status;
    }

    // one day, the chef will retire
    function setEndBlock(uint256 _endBlock) external onlyOwner {
        endBlock = _endBlock;
    }

    function setDispatcher(address _dispatcher) external onlyOwner {
        dispatcher = _dispatcher;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate,
        bool _isSingle,
        uint256 _type
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accBoringPerShare: 0,
                isSingle: _isSingle,
                _type: _type
            })
        );
    }

    // Update the given pool's BORING allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to > endBlock) {
            return endBlock.sub(_from);
        } else {
            return _to.sub(_from);
        }
    }

    // View function to see pending BORINGs on frontend.
    function pendingBoring(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBoringPerShare = pool.accBoringPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 boringReward =
                multiplier.mul(boringPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accBoringPerShare = accBoringPerShare.add(
                boringReward.mul(1e12).div(lpSupply)
            );
        }
        return
            user.amount.mul(accBoringPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 boringReward =
            multiplier.mul(boringPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        pool.accBoringPerShare = pool.accBoringPerShare.add(
            boringReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for BORING allocation.
    function deposit(uint256 _pid, uint256 _amount) public updateTVL{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accBoringPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeBoringTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
        }
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accBoringPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public updateTVL{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accBoringPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeBoringTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accBoringPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe boring transfer function, just in case if rounding error causes pool to not have enough BORINGs.
    function safeBoringTransfer(address _to, uint256 _amount) internal {
        boring.safeTransferFrom(dispatcher, _to, _amount);
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock, bool withUpdate)
        external
        onlyOwner
    {
        if (withUpdate) {
            massUpdatePools();
        }
        boringPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    function liquidateArray(address account, uint256[] memory pids)
        public
        override
        onlyLiquidation
    {
        require(address(account) != address(0), "SatelliteCity: empty account");

        uint256 length = pids.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 pid = pids[i];
            PoolInfo storage pool = poolInfo[pid];
            if (pool._type == 1) {
                IERC20 lpToken = pool.lpToken;
                uint256 bal = lpToken.balanceOf(address(this));
                lpToken.safeTransfer(account, bal);
            }
        }
    }

    function setTVL(uint256 _tvl) public onlyOwner {
        tvl = _tvl;
    }

    function calculateTVL() public view returns (uint256) {
        uint256 _tvl = 0;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            uint256 lpAmount = pool.lpToken.balanceOf(address(this));
            if (pool._type == 1) {
                if (pool.isSingle) {
                    string memory symbol =
                        IERC20Metadata(address(pool.lpToken)).symbol();
                    uint8 decimals =
                        IERC20Metadata(address(pool.lpToken)).decimals();
                    uint256 price = oracle.getPrice(stringToBytes32(symbol));
                    uint256 diff = uint256(18).sub(uint256(decimals));
                    _tvl = _tvl.add(
                        lpAmount.mul(10**(diff)).multiplyDecimal(price)
                    );
                } else {
                    uint256 lpSupply = pool.lpToken.totalSupply();
                    (uint112 _reserve0, , ) =
                        IPair(address(pool.lpToken)).getReserves();
                    address token0 = IPair(address(pool.lpToken)).token0();
                    // TODO: uint112 => uint256?
                    uint256 amount =
                        lpAmount.mul(uint256(_reserve0)).div(lpSupply);
                    string memory symbol = IERC20Metadata(token0).symbol();
                    uint8 decimals = IERC20Metadata(token0).decimals();
                    uint256 price = oracle.getPrice(stringToBytes32(symbol));
                    uint256 diff = uint256(18).sub(uint256(decimals));
                    _tvl = _tvl.add(
                        amount.mul(10**(diff)).multiplyDecimal(price).mul(2)
                    );
                }
            }
        }
        return _tvl;
    }

    function satelliteTVL() public view returns (uint256) {
        return tvl;
    }

    function stringToBytes32(string memory source)
        public
        pure
        returns (bytes32 result)
    {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function setLiquidation(address _liquidation) public onlyOwner {
        liquidation = _liquidation;
    }

    function setOracle(address _oracle) public onlyOwner {
        oracle = IOracle(_oracle);
    }

    modifier onlyLiquidation {
        require(msg.sender == liquidation, "caller is not liquidator");
        _;
    }

    modifier updateTVL {
        if (tvlSwitcher == true) {
            uint tvlAmount = calculateTVL();
            tvl = tvlAmount;
        }
        _;
    }

    event NewRewardPerBlock(uint256 amount);
}