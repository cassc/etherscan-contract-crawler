// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/*
 _____ _         _____               
|     |_|___ ___|   __|_ _ _ ___ ___ 
| | | | |   | . |__   | | | | .'| . |
|_|_|_|_|_|_|___|_____|_____|__,|  _|
                                |_| 
*
* MIT License
* ===========
*
* Copyright (c) 2022 MinoSwap
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE

*/

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IVestingMaster.sol";
import "./interfaces/IMinoVault.sol";
import "./interfaces/IMinoDistributor.sol";

contract MinoSupporterFarm is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event UpdateEmissionRate(address indexed user, uint256 tokenPerBlock);
    event UpdateEndBlock(address indexed user, uint256 endBlock);
    event SetEarlyExitFee(address indexed user, uint256 earlyExitFee);
    event SetDevAddress(address indexed user, address devAddress);
    event SetVestingMaster(address indexed user, address vestingMaster);
    event SetDevSupply(address indexed user, uint256 devSupply);

    struct UserInfo {
        uint256 shares;
        uint256 rewardDebt;
        uint256 lastDepositedTime;
    }

    struct PoolInfo {
        IERC20 want;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
    }

    /* ========== CONSTANTS ============= */

    // Denominator for fee calculations.
    uint256 public constant FEE_DENOM = 10000;

    // Mino token
    IERC20 public immutable mino;

    // The block number when mining starts.
    uint256 public immutable startBlock;

    IMinoVault public immutable minoVault;

    /* ========== STATE VARIABLES ========== */

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Mino tokens rewarded per block.
    uint256 public minoPerBlock;
    
    // The block number when mining ends.
    uint256 public endBlock;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // Developer address.
    address public devAddress;

    // Vesting contract that vested rewards get sent to.
    IVestingMaster public vestingMaster;

    IMinoDistributor public minoDistributor;

    /* ========== MODIFIERS ========== */

    modifier validatePid(uint256 _pid) {
        require(
            _pid < poolInfo.length,
            "MinoSupporterFarm::validatePid: Not exist"
        );
        _;
    }

    modifier onlyGovernance() {
        require(
            (msg.sender == devAddress || msg.sender == owner()),
            "MinoSupporterFarm::onlyGovernance: Not gov"
        );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _minoVault,
        address _vestingMaster,
        address _mino,
        uint256 _minoPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        address _devAddress
    ) {
        require(
            _startBlock < _endBlock,
            "MinoSupporterFarm::constructor: End less than start"
        );
        minoVault = IMinoVault(_minoVault);
        vestingMaster = IVestingMaster(_vestingMaster);
        mino = IERC20(_mino);
        minoPerBlock = _minoPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
        devAddress = _devAddress;
    }

    function initDistributor(address _minoDistributor) external onlyOwner {
        require(address(minoDistributor) == address(0), "MinoSupporterFarm::initDistributor: Distributor already set");
        minoDistributor = IMinoDistributor(_minoDistributor);
    }
    

    /* ========== VIEWS ========== */

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function pendingMino(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        if (block.number > pool.lastRewardBlock && user.shares != 0) {
            uint256 tokenReward = getStakingReward(_pid);
            accTokenPerShare = accTokenPerShare + (
                tokenReward * 1e12 / totalAllocPoint
            );
        }
        return user.shares * accTokenPerShare / 1e12 - user.rewardDebt;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock || pool.lastRewardBlock >= endBlock) {
            return;
        }
        uint256 lastRewardBlock = block.number >= endBlock ? endBlock : block.number;
        uint256 lpSupply = pool.want.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = lastRewardBlock;
            return;
        }
        uint256 tokenReward = getStakingReward(_pid);
        pool.accTokenPerShare += tokenReward * 1e12 / lpSupply;
        pool.lastRewardBlock = lastRewardBlock;
        minoDistributor.withdrawReward(2);
        (address supporterAddress,,,) = minoDistributor.distributees(1);
        if (supporterAddress == address(this)) {
            minoDistributor.withdrawReward(1);
        }

    }

    function deposit(uint256 _pid, uint256 _wantAmt) external nonReentrant{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.shares > 0) {
            uint256 pending =
                user.shares * pool.accTokenPerShare / 1e12 - (
                    user.rewardDebt
                );
            if (pending > 0) {
                uint256 locked;
                if (address(vestingMaster) != address(0)) {
                    locked = pending * (vestingMaster.lockedPeriodAmount() + 1) / vestingMaster.lockedPeriodAmount();
                }
                safeTokenTransfer(msg.sender, pending - locked);
                if (locked > 0) {
                    uint256 actualAmount = safeTokenTransfer(
                        address(vestingMaster),
                        locked
                    );
                    vestingMaster.lock(msg.sender, actualAmount);
                }
            }
        }
        if (_wantAmt > 0) {
            pool.want.safeTransferFrom(
                address(msg.sender),
                address(this),
                _wantAmt
            );

            user.shares += _wantAmt;
            user.lastDepositedTime = block.timestamp;
        }
        user.rewardDebt = user.shares * pool.accTokenPerShare / 1e12;
        emit Deposit(msg.sender, _pid, _wantAmt);
    }

    function withdraw(uint256 _pid, uint256 _wantAmt)
        public
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.shares > 0) {
            uint256 pending =
                user.shares * pool.accTokenPerShare / 1e12 - user.rewardDebt;
            if (pending > 0) {
                uint256 locked;
                if (address(vestingMaster) != address(0)) {
                    locked = pending / (vestingMaster.lockedPeriodAmount() + 1) * vestingMaster.lockedPeriodAmount();
                }
                safeTokenTransfer(msg.sender, pending - locked);
                if (locked > 0) {
                    uint256 actualAmount = safeTokenTransfer(
                        address(vestingMaster),
                        locked
                    );
                    vestingMaster.lock(msg.sender, actualAmount);
                }
            }
        }

        if (_wantAmt > user.shares) {
            _wantAmt = user.shares;
        }
        if (_wantAmt > 0) {
            user.shares -= _wantAmt;
            pool.want.safeTransfer(address(msg.sender), _wantAmt);
        }
        user.rewardDebt = user.shares * pool.accTokenPerShare / 1e12;
        emit Withdraw(msg.sender, _pid, _wantAmt);
    }

    function withdrawAll(uint256 _pid) external {
        withdraw(_pid, type(uint256).max);
    }

    function emergencyWithdraw(uint256 _pid)
        external
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _wantAmt = user.shares;
        user.shares = 0;
        user.rewardDebt = 0;
        pool.want.safeTransfer(address(msg.sender), _wantAmt);
        emit EmergencyWithdraw(msg.sender, _pid, _wantAmt);
    }

    function getStakingReward(uint256 _pid) internal view returns (uint256 tokenReward) {
        PoolInfo storage pool = poolInfo[_pid];
        require(
            pool.lastRewardBlock < block.number,
            "MinoSupporterFarm::getStakingReward: Must less than block number"
        );

        (,,, uint256 stakingReward) = minoDistributor.distributees(2);
        (address supporterAddress,,, uint256 accReward) = minoDistributor.distributees(1);
        if (supporterAddress == address(this)) {
            stakingReward += accReward;
        }

        uint256 multiplier = block.number - pool.lastRewardBlock;
        if (block.number >= endBlock) {
            multiplier = pool.lastRewardBlock - endBlock;
        }
        tokenReward = multiplier * minoPerBlock + stakingReward;
    }

    /* ========== UTILITY FUNCTIONS ========== */

    function safeTokenTransfer(address _to, uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 balance = mino.balanceOf(address(this));
        if (_amount > balance) {
            _amount = minoVault.minoSupporterWithdraw(_amount - balance);
        }

        require(
            mino.transfer(_to, _amount),
            "MinoSupporterFarm::safeTokenTransfer: Transfer failed"
        );
        return _amount;
    }
}