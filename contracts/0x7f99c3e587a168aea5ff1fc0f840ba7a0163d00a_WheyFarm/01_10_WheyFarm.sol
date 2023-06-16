// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./WheyToken.sol";

contract WheyFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of WHEY
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accWheyPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accWheyPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. WHEY to distribute per block.
        uint256 lastRewardBlock; // Last block number that WHEY distribution occurs.
        uint256 accWheyPerShare; // Accumulated WHEY per share, times 1e12. See below.
        uint256 totalDeposit; // Total tokens deposited
        uint256 nextEmissionIndex;
    }
    // The WHEY TOKEN!
    WheyToken public whey;
    // Dev address.
    address public devaddr;

    // Schedule for whey emission (blocks per epoch)
    uint256[] public wheyEmissionSchedule;
    // WHEY tokens created per block for each epoch.
    uint256[] public wheyEmissionPerEpoch;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when WHEY mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        address _devaddr,
        uint256 _startBlock,
        uint256[] memory _wheyEmissionSchedule,
        uint256[] memory _wheyEmissionPerEpoch
    ) public {
        // Deploy WHEY
        whey = new WheyToken();
        // LP Mint
        whey.mint(_devaddr, 250000 ether);

        devaddr = _devaddr;
        startBlock = _startBlock;

        require(_wheyEmissionSchedule.length == _wheyEmissionPerEpoch.length, "WheyFarm: Mismatch inputs");
        wheyEmissionSchedule = _wheyEmissionSchedule;
        wheyEmissionPerEpoch = _wheyEmissionPerEpoch;

    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        uint256 nextEmissionIndex = 0;
        if (lastRewardBlock > wheyEmissionSchedule[nextEmissionIndex].add(startBlock)) {
            for (uint256 i = nextEmissionIndex; i < wheyEmissionSchedule.length; i++) {
                if (lastRewardBlock < wheyEmissionSchedule[i].add(startBlock)) {
                    nextEmissionIndex = i;
                    break;
                }
            }
        }

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accWheyPerShare: 0,
                totalDeposit: 0,
                nextEmissionIndex: nextEmissionIndex
            })
        );
    }

    // Update the given pool's WHEY allocation point. Can only be called by the owner.
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

    function getWheyReward(uint _nextEmissionIndex, uint _from, uint _to) public view returns (uint256) {
        require(_to > _from, 'WheyFarm: _to less than _from');

        if (_from < startBlock) {
            _from = startBlock;
        }

        if (_from > wheyEmissionSchedule[_nextEmissionIndex].add(startBlock)) {
            return 0;
        }

        uint256 reward = 0;
        
        for (uint256 i = _nextEmissionIndex; i < wheyEmissionSchedule.length; i++) {
            if (_from < wheyEmissionSchedule[i].add(startBlock)) {
                
                uint256 indexBlock = _from;
                for (uint256 n = i; n < wheyEmissionSchedule.length; n++) {
                    if (_to > wheyEmissionSchedule[n].add(startBlock)) {
                        reward = reward.add((wheyEmissionSchedule[n].add(startBlock).sub(indexBlock)).mul(wheyEmissionPerEpoch[n]));
                        indexBlock = wheyEmissionSchedule[n].add(startBlock);
                    } else {
                        reward = reward.add((_to.sub(indexBlock)).mul(wheyEmissionPerEpoch[n]));
                        indexBlock = wheyEmissionSchedule[n].add(startBlock);
                        break;
                    }
                }
                break;
            }
            
        }
        
        return reward;
    }

    // View function to see pending WHEY on frontend.
    function pendingWhey(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accWheyPerShare = pool.accWheyPerShare;
        uint256 lpSupply = pool.totalDeposit;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 wheyReward = getWheyReward(pool.nextEmissionIndex, pool.lastRewardBlock, block.number);
            uint256 poolWheyReward = wheyReward.mul(pool.allocPoint).div(totalAllocPoint);

            accWheyPerShare = accWheyPerShare.add(
                (poolWheyReward.mul(85).div(100)).mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accWheyPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 lpSupply = pool.totalDeposit;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;

            if (pool.lastRewardBlock > wheyEmissionSchedule[pool.nextEmissionIndex].add(startBlock)) {
                for (uint256 i = pool.nextEmissionIndex; i < wheyEmissionSchedule.length; i++) {
                    if (pool.lastRewardBlock < wheyEmissionSchedule[i].add(startBlock)) {
                        pool.nextEmissionIndex = i;
                        break;
                    }

                    if (pool.lastRewardBlock > wheyEmissionSchedule[i].add(startBlock) && i == wheyEmissionSchedule.length-1) {
                        pool.nextEmissionIndex = i;
                        break;
                    }
                }
            }
            return;
        }

        uint256 wheyReward = getWheyReward(pool.nextEmissionIndex, pool.lastRewardBlock, block.number);
        uint256 poolWheyReward = wheyReward.mul(pool.allocPoint).div(totalAllocPoint);

        if (poolWheyReward > 0) {
            uint256 devReward = poolWheyReward.mul(15).div(100);
            uint256 poolReward = poolWheyReward.sub(devReward);
            whey.mint(devaddr, devReward);
            whey.mint(address(this), poolReward);
            pool.accWheyPerShare = pool.accWheyPerShare.add(
                poolReward.mul(1e12).div(lpSupply)
            );
        }
        pool.lastRewardBlock = block.number;

        if (pool.lastRewardBlock > wheyEmissionSchedule[pool.nextEmissionIndex].add(startBlock)) {
            for (uint256 i = pool.nextEmissionIndex; i < wheyEmissionSchedule.length; i++) {
                if (pool.lastRewardBlock < wheyEmissionSchedule[i].add(startBlock)) {
                    pool.nextEmissionIndex = i;
                    break;
                }

                if (pool.lastRewardBlock > wheyEmissionSchedule[i].add(startBlock) && i == wheyEmissionSchedule.length-1) {
                    pool.nextEmissionIndex = i;
                    break;
                }
            }
        }   
    }

    // Deposit LP tokens to WheyFarm for WHEY allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accWheyPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                safeWheyTransfer(msg.sender, pending);
            }
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accWheyPerShare).div(1e12);

        pool.totalDeposit = pool.totalDeposit.add(_amount);

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from WheyFarm.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accWheyPerShare).div(1e12).sub(
                user.rewardDebt
            );
        if (pending > 0) {
            safeWheyTransfer(msg.sender, pending);
        }
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accWheyPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);

        pool.totalDeposit = pool.totalDeposit.sub(_amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function harvestAll() public {
        uint pending = 0;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            if (userInfo[i][msg.sender].amount > 0) {
                PoolInfo storage pool = poolInfo[i];
                UserInfo storage user = userInfo[i][msg.sender];
                updatePool(i);
                pending +=
                user.amount.mul(pool.accWheyPerShare).div(1e12).sub(
                    user.rewardDebt
                );
                user.rewardDebt = user.amount.mul(pool.accWheyPerShare).div(1e12);
            }
        }
        require(pending > 0, "harvest: not good");
        safeWheyTransfer(msg.sender, pending);
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

    // Safe WHEY transfer function, just in case if rounding error causes pool to not have enough WHEY.
    function safeWheyTransfer(address _to, uint256 _amount) internal {
        uint256 wheyBal = whey.balanceOf(address(this));
        if (_amount > wheyBal) {
            whey.transfer(_to, wheyBal);
        } else {
            whey.transfer(_to, _amount);
        }
    }

    function updateDev(address _devaddr) onlyOwner public {
        devaddr = _devaddr;
    }

    function updateWheyEmission(uint[] memory _wheyEmissionSchedule, uint[] memory _wheyEmissionPerEpoch) external onlyOwner {
        require(_wheyEmissionSchedule.length == _wheyEmissionPerEpoch.length, "WheyFarm: Mismatch inputs");
        wheyEmissionSchedule = _wheyEmissionSchedule;
        wheyEmissionPerEpoch = _wheyEmissionPerEpoch;
        massUpdatePools();
    }

    function getWheyPerBlock() public view returns (uint256) {
        for (uint256 i = 0; i < wheyEmissionSchedule.length; i++) {
            if (block.number < wheyEmissionSchedule[i].add(startBlock)) {
                return wheyEmissionPerEpoch[i];
            }
        }
        
        return 0;
    }
}