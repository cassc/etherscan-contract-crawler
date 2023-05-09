// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Wex/WaultSwap, Synthetix
//This variant can have an approved router, set by owner, which can deposit/withdraw on behalf of users to reduce the number of required tx.
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IBlacklist.sol";
import "./Bandit.sol";

//import "hardhat/console.sol";

contract BanditMasterRoutable is Ownable {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint16 depositTaxBasis;
        uint16 withdrawTaxBasis;
        uint32 allocPoint;
        uint256 lastRewardTimestamp;
        uint256 accBanditPerShare;
        uint256 totalDeposit;
    }

    Bandit public bandit = Bandit(0x2a10CFe2300e5DF9417F7bEe99ef1e81228F0Ac7);
    uint256 public banditPerSecond;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint32 public totalAllocPoint = 0;
    uint256 public startTimestamp;
    uint256 public baseAprBasis = 25000; //250%

    IBlacklist public blacklistChecker =
        IBlacklist(0x0207bb6B0EAab9211A4249F5a00513eB5C16C2AF);

    address public router;
    address public treasury =
        address(0x745A676C5c472b50B50e18D4b59e9AeEEc597046);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event UpdateBanditPerSecond(uint256 amount);

    constructor(uint256 _startTimestamp) {
        startTimestamp = _startTimestamp;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to - _from;
    }

    function add(
        uint32 _allocPoint,
        uint16 _depositTaxBasis,
        uint16 _withdrawTaxBasis,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp
            ? block.timestamp
            : startTimestamp;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                depositTaxBasis: _depositTaxBasis,
                withdrawTaxBasis: _withdrawTaxBasis,
                allocPoint: _allocPoint,
                lastRewardTimestamp: lastRewardTimestamp,
                accBanditPerShare: 0,
                totalDeposit: 0
            })
        );
    }

    function set(
        uint256 _pid,
        uint32 _allocPoint,
        uint16 _depositTaxBasis,
        uint16 _withdrawTaxBasis,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositTaxBasis = _depositTaxBasis;
        poolInfo[_pid].withdrawTaxBasis = _withdrawTaxBasis;
    }

    function pendingBandit(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBanditPerShare = pool.accBanditPerShare;
        uint256 totalDeposit = pool.totalDeposit;
        if (block.timestamp > pool.lastRewardTimestamp && totalDeposit != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardTimestamp,
                block.timestamp
            );
            uint256 banditReward = (multiplier *
                banditPerSecond *
                pool.allocPoint) / totalAllocPoint;
            accBanditPerShare =
                accBanditPerShare +
                ((banditReward * 1e12) / totalDeposit);
        }
        return
            ((user.amount * accBanditPerShare) / 1e12) +
            user.pendingRewards -
            user.rewardDebt;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        uint256 totalDeposit = pool.totalDeposit;
        if (totalDeposit == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(
            pool.lastRewardTimestamp,
            block.timestamp
        );

        uint256 banditReward = (multiplier *
            banditPerSecond *
            pool.allocPoint) / totalAllocPoint;

        bandit.mint(address(this), banditReward);

        pool.accBanditPerShare =
            pool.accBanditPerShare +
            ((banditReward * 1e12) / totalDeposit);
        pool.lastRewardTimestamp = block.timestamp;
    }

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _withdrawRewards
    ) public {
        _deposit(_pid, _amount, _withdrawRewards, msg.sender, msg.sender);
    }

    function depositRoutable(
        uint256 _pid,
        uint256 _amount,
        bool _withdrawRewards,
        address _account,
        address _assetSender
    ) public {
        require(msg.sender == router);
        _deposit(_pid, _amount, _withdrawRewards, _account, _assetSender);
    }

    function _deposit(
        uint256 _pid,
        uint256 _amount,
        bool _withdrawRewards,
        address _account,
        address _assetSender
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_account];

        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = ((user.amount * pool.accBanditPerShare) / 1e12) -
                user.rewardDebt;

            if (pending > 0) {
                user.pendingRewards = user.pendingRewards + pending;

                if (_withdrawRewards) {
                    address yieldReceiver = blacklistChecker.isBlacklisted(
                        _account
                    )
                        ? owner()
                        : _account;
                    safeBanditTransfer(yieldReceiver, user.pendingRewards);
                    emit Claim(_account, _pid, user.pendingRewards);
                    user.pendingRewards = 0;
                }
            }
        }
        if (_amount > 0) {
            uint256 fee = (_amount * pool.depositTaxBasis) / 10000;
            require(
                pool.lpToken.transferFrom(
                    address(_assetSender),
                    address(this),
                    _amount - fee
                ),
                "CBM: Transfer failed"
            );
            require(
                pool.lpToken.transferFrom(address(_assetSender), treasury, fee),
                "CBM: Transfer fee failed"
            );

            pool.totalDeposit = pool.totalDeposit + _amount - fee;
            user.amount = user.amount + _amount - fee;
        }
        user.rewardDebt = (user.amount * pool.accBanditPerShare) / 1e12;
        if (_pid == 0) {
            _updateBanditPerSecond();
        }
        emit Deposit(_account, _pid, _amount);
    }

    function withdraw(
        uint256 _pid,
        uint256 _amount,
        bool _withdrawRewards
    ) public {
        _withdraw(_pid, _amount, _withdrawRewards, msg.sender, msg.sender);
    }

    function withdrawRoutable(
        uint256 _pid,
        uint256 _amount,
        bool _withdrawRewards,
        address _account,
        address _assetReceiver
    ) public {
        require(msg.sender == router);
        _withdraw(_pid, _amount, _withdrawRewards, _account, _assetReceiver);
    }

    function _withdraw(
        uint256 _pid,
        uint256 _amount,
        bool _withdrawRewards,
        address _account,
        address _assetReceiver
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_account];
        address assetReceiver = blacklistChecker.isBlacklisted(_account)
            ? treasury
            : _assetReceiver;
        address yieldReceiver = blacklistChecker.isBlacklisted(_account)
            ? treasury
            : _account;

        require(user.amount >= _amount, "CBM: balance too low");
        updatePool(_pid);
        uint256 pending = ((user.amount * pool.accBanditPerShare) / 1e12) -
            user.rewardDebt;
        if (pending > 0) {
            user.pendingRewards = user.pendingRewards + pending;

            if (_withdrawRewards) {
                safeBanditTransfer(yieldReceiver, user.pendingRewards);
                emit Claim(_account, _pid, user.pendingRewards);
                user.pendingRewards = 0;
            }
        }
        if (_amount > 0) {
            uint256 fee = (_amount * pool.withdrawTaxBasis) / 10000;
            pool.totalDeposit = pool.totalDeposit - _amount;
            user.amount = user.amount - _amount;
            require(
                pool.lpToken.transfer(assetReceiver, _amount - fee),
                "CBM: Transfer failed"
            );
            require(
                pool.lpToken.transfer(treasury, fee),
                "CBM: Transfer fee failed"
            );
            if (_pid == 0) {
                _updateBanditPerSecond();
            }
        }
        user.rewardDebt = (user.amount * pool.accBanditPerShare) / 1e12;
        emit Withdraw(_account, _pid, _amount);
    }

    function _updateBanditPerSecond() internal {
        //Set banditPerSecond based on the first pool's bandit stake.
        banditPerSecond =
            (poolInfo[0].totalDeposit * baseAprBasis * totalAllocPoint) /
            poolInfo[0].allocPoint /
            10000 /
            365.25 days;
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        address assetReceiver = blacklistChecker.isBlacklisted(
            address(msg.sender)
        )
            ? treasury
            : msg.sender;
        uint256 fee = (user.amount * pool.withdrawTaxBasis) / 10000;
        require(
            pool.lpToken.transfer(assetReceiver, user.amount - fee),
            "CBM: Transfer failed"
        );
        require(
            pool.lpToken.transfer(treasury, fee),
            "CBM: Transfer fee failed"
        );
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        pool.totalDeposit = pool.totalDeposit - user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.pendingRewards = 0;
        if (_pid == 0) {
            _updateBanditPerSecond();
        }
    }

    function claim(uint256 _pid) public {
        _claim(_pid, msg.sender);
    }

    function claimRoutabale(address _for, uint256 _pid) public {
        require(msg.sender == router);
        _claim(_pid, _for);
    }

    function _claim(uint256 _pid, address _for) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_for];
        updatePool(_pid);
        uint256 pending = (user.amount * pool.accBanditPerShare) /
            1e12 -
            user.rewardDebt;
        if (pending > 0 || user.pendingRewards > 0) {
            user.pendingRewards = user.pendingRewards + pending;
            safeBanditTransfer(_for, user.pendingRewards);
            emit Claim(_for, _pid, user.pendingRewards);
            user.pendingRewards = 0;
        }
        user.rewardDebt = (user.amount * pool.accBanditPerShare) / 1e12;
    }

    function safeBanditTransfer(address _to, uint256 _amount) internal {
        uint256 banditBal = bandit.balanceOf(address(this));
        if (_amount > banditBal) {
            bandit.transfer(_to, banditBal);
        } else {
            bandit.transfer(_to, _amount);
        }
    }

    function setRouter(address _router) public onlyOwner {
        router = _router;
    }

    function setBlacklistChecker(IBlacklist _to) public onlyOwner {
        blacklistChecker = _to;
    }

    function setBaseAprBasis(uint256 _to) public onlyOwner {
        baseAprBasis = _to;
    }

    function setTreasury(address _to) public onlyOwner {
        treasury = _to;
    }
}