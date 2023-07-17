// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

//** HFD Staking */
//** Author: Aceson Decubate 2022.10 */

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";

import { IVesting } from "./interface/IVesting.sol";

contract HODLStaking is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 totalDeposit;
        uint256 rewardDebt;
        uint256 totalClaimed;
        uint256 depositTime;
        uint256[] depositedIds;
        mapping(uint256 => uint256) idToArrayIdx;
    }

    // Info of each pool.
    struct PoolInfo {
        uint8 isInputNFT; //0 - token, 1 - NFT
        uint8 isVested; //0 - false, 1 - true
        uint32 totalInvestors;
        address input; // Address of input token.
        uint256 allocPoint; // How many allocation points assigned to this pool. HFDs to distribute per block.
        uint256 lastRewardBlock; // Last block number that HFDs distribution occurs.
        uint256 accTknPerShare; // Accumulated HFDs per share, times 1e12. See below.
        uint256 startIdx; //Start index of NFT (if applicable)
        uint256 endIdx; //End index of NFT (if applicable)
        uint256 totalDeposit;
        uint256[] depositedIds;
        mapping(uint256 => uint256) idToArrayIdx;
    }

    struct PoolLockInfo {
        uint32 multi; //4 decimal precision
        uint32 claimFee; //2 decimal precision
        uint32 lockPeriodInSeconds; //Lock period for staked tokens
    }

    struct UserLockInfo {
        bool isWithdrawed;
        uint32 depositTime;
        uint256 actualDeposit;
    }

    // The REWARD TOKEN!
    IERC20 public immutable reward;
    //Percentage distributed per day. 2 decimals / 100000
    uint32 public percPerDay = 0;
    //Address where reward token is stored
    address public rewardWallet;
    //Address where fees are sent
    address public feeWallet;
    //Vesting contract address
    IVesting public vestingCont;

    //Number of blocks per day
    uint16 internal constant BLOCKS_PER_DAY = 7150;
    //Divisor
    uint16 internal constant DIVISOR = 10000;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    //Info of each lock term
    mapping(uint256 => PoolLockInfo) public poolLockInfo;
    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Info of users who staked tokens from bonding contract
    mapping(uint8 => mapping(address => UserLockInfo[])) public userLockInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    //Actual deposit in lock pool
    uint256 public totalActualDeposit;
    // The block number when REWARDing starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint8 indexed lid, uint256[] amounts);
    event Withdraw(address indexed user, uint256 indexed pid, uint8 indexed lid, uint256[] amounts);
    event RewardClaimed(address indexed user, uint256 indexed pid, uint256 amount);
    event PoolAdded(
        uint8 _isInputNFT,
        uint8 _isVested,
        uint256 _allocPoint,
        address _input,
        uint256 _startIdx,
        uint256 _endIdx
    );
    event PoolChanged(uint256 pid, uint256 allocPoint, uint8 isVested, uint256 startIdx, uint256 endIdx);
    event PoolLockChanged(uint256 lid, uint32 multi, uint32 claimFee, uint32 lockPeriod);
    event PoolUpdated(uint256 pid);
    event WalletsChanged(address reward, address feeWallet);
    event RewardChanged(uint32 perc);
    event VestingContractChanged(address vesting);

    constructor(address _reward, address _rewardWallet, address _feeWallet, uint256 _startBlock) {
        require(_reward != address(0) && _rewardWallet != address(0) && _feeWallet != address(0), "HODL: Zero address");
        reward = IERC20(_reward);
        rewardWallet = _rewardWallet;
        feeWallet = _feeWallet;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new pool. Can only be called by the owner.
    function add(
        uint8 _isInputNFT,
        uint8 _isVested,
        uint256 _allocPoint,
        address _input,
        uint256 _startIdx,
        uint256 _endIdx
    ) external onlyOwner {
        require(_input != address(0), "HODL: Zero address");
        massUpdatePools();

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        PoolInfo storage newPool = poolInfo.push();

        newPool.allocPoint = _allocPoint;
        newPool.input = _input;
        newPool.isInputNFT = _isInputNFT;
        newPool.isVested = _isVested;
        newPool.lastRewardBlock = lastRewardBlock;

        if (_isInputNFT == 1) {
            newPool.startIdx = _startIdx;
            newPool.endIdx = _endIdx;
        }

        emit PoolAdded(_isInputNFT, _isVested, _allocPoint, _input, _startIdx, _endIdx);
    }

    // Update the given pool. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint8 _isVested,
        uint256 _startIdx,
        uint256 _endIdx
    ) external onlyOwner {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];

        totalAllocPoint = totalAllocPoint - pool.allocPoint + _allocPoint;
        pool.allocPoint = _allocPoint;
        pool.isVested = _isVested;

        if (pool.isInputNFT == 1) {
            pool.startIdx = _startIdx;
            pool.endIdx = _endIdx;
        }

        emit PoolChanged(_pid, _allocPoint, _isVested, _startIdx, _endIdx);
    }

    function setPoolLock(uint256 _lid, uint32 _multi, uint32 _claimFee, uint32 _lockPeriod) external onlyOwner {
        PoolLockInfo storage pool = poolLockInfo[_lid];

        pool.claimFee = _claimFee;
        pool.lockPeriodInSeconds = _lockPeriod;
        pool.multi = _multi;

        emit PoolLockChanged(_lid, _multi, _claimFee, _lockPeriod);
    }

    // View function to see pending HFDs on frontend.
    function pendingTkn(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTknPerShare = pool.accTknPerShare;
        uint256 total = pool.totalDeposit;
        if (block.number > pool.lastRewardBlock && total != 0) {
            uint256 multi = block.number - pool.lastRewardBlock;
            uint256 rewardPerBlock = getRewardPerBlock();
            uint256 tknReward = (multi * rewardPerBlock * pool.allocPoint) / totalAllocPoint;
            accTknPerShare = accTknPerShare + ((tknReward * 1e12) / total);
        }
        return (user.totalDeposit * accTknPerShare) / 1e12 - user.rewardDebt;
    }

    function canWithdraw(uint8 _lid, uint256 _did, address _user) public view returns (bool) {
        return (block.timestamp >=
            userLockInfo[_lid][_user][_did].depositTime + poolLockInfo[_lid].lockPeriodInSeconds);
    }

    // Update reward variables for all pools. Be careful of gas spending!
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
        uint256 total = pool.totalDeposit;
        if (total == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multi = block.number - pool.lastRewardBlock;
        uint256 rewardPerBlock = getRewardPerBlock();
        uint256 tknReward = (multi * rewardPerBlock * pool.allocPoint) / totalAllocPoint;
        reward.safeTransferFrom(rewardWallet, address(this), tknReward);
        pool.accTknPerShare = pool.accTknPerShare + ((tknReward * 1e12) / total);
        pool.lastRewardBlock = block.number;
        emit PoolUpdated(_pid);
    }

    // Deposit tokens to staking for REWARD allocation.
    function deposit(uint256 _pid, uint8 _lid, address _benificiary, uint256[] calldata _amounts) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_benificiary];
        updatePool(_pid);
        if (user.totalDeposit > 0) {
            _claimReward(_pid, _benificiary);
        } else {
            pool.totalInvestors++;
        }

        if (pool.isInputNFT == 1) {
            IERC721 nft = IERC721(pool.input);
            uint256 poolLen = pool.depositedIds.length;
            uint256 userLen = user.depositedIds.length;
            uint256 len = _amounts.length;
            uint256 id;

            for (uint256 i = 0; i < len; ) {
                id = _amounts[i];
                require(id >= pool.startIdx && id <= pool.endIdx, "HODL: Invalid NFT");
                nft.safeTransferFrom(msg.sender, address(this), id);
                pool.depositedIds.push(id);
                pool.idToArrayIdx[id] = poolLen + i;
                user.depositedIds.push(id);
                user.idToArrayIdx[id] = userLen + i;
                unchecked {
                    i++;
                }
            }
            user.totalDeposit = user.totalDeposit + len;
            pool.totalDeposit = pool.totalDeposit + len;
        } else {
            require(_amounts.length == 1, "HODL: Invalid input");
            uint256 amount = _amounts[0];
            IERC20(pool.input).safeTransferFrom(msg.sender, address(this), amount);

            if (_pid == 0) {
                PoolLockInfo storage poolLock = poolLockInfo[_lid];
                UserLockInfo storage userLock = userLockInfo[_lid][_benificiary].push();

                require(poolLock.multi > 0, "HODL: Invalid lock id");

                userLock.depositTime = uint32(block.timestamp);
                userLock.actualDeposit = amount;
                totalActualDeposit += amount;

                uint256 weightedAmount = (amount * poolLock.multi) / DIVISOR;
                user.totalDeposit += weightedAmount;
                pool.totalDeposit += weightedAmount;
                vestingCont.mint(_benificiary, amount);
            } else {
                user.totalDeposit = user.totalDeposit + amount;
                pool.totalDeposit = pool.totalDeposit + amount;
            }
        }

        user.rewardDebt = (user.totalDeposit * pool.accTknPerShare) / 1e12;
        user.depositTime = block.timestamp;
        emit Deposit(_benificiary, _pid, _lid, _amounts);
    }

    // Withdraw tokens from staking.
    function withdraw(uint256 _pid, uint8 _lid, uint256 _did, uint256[] calldata _amounts) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);
        _claimReward(_pid, msg.sender);

        if (pool.isInputNFT == 1) {
            IERC721 nft = IERC721(pool.input);
            uint256 len = _amounts.length;
            uint256 poolLen = pool.depositedIds.length;
            uint256 userLen = user.depositedIds.length;

            require(userLen >= len, "HODL: Deposit/Withdraw Mismatch");

            for (uint256 i = 0; i < len; ) {
                uint256 id = _amounts[i];
                require(user.idToArrayIdx[id] != 0 || user.depositedIds[0] == id, "HODL: Not staked by caller");
                nft.safeTransferFrom(address(this), msg.sender, id);

                uint256 idx = user.idToArrayIdx[id];
                uint256 last = user.depositedIds[userLen - i - 1];
                user.depositedIds[idx] = last;
                user.idToArrayIdx[last] = idx;
                user.depositedIds.pop();
                user.idToArrayIdx[id] = 0;

                idx = pool.idToArrayIdx[id];
                last = pool.depositedIds[poolLen - i - 1];
                pool.depositedIds[idx] = last;
                pool.idToArrayIdx[last] = idx;
                pool.depositedIds.pop();
                pool.idToArrayIdx[id] = 0;

                unchecked {
                    i++;
                }
            }
            user.totalDeposit = user.totalDeposit - _amounts.length;
            pool.totalDeposit = pool.totalDeposit - _amounts.length;
        } else {
            IERC20 token = IERC20(pool.input);
            uint256 amount = _amounts[0];

            if (_pid == 0) {
                PoolLockInfo storage poolLock = poolLockInfo[_lid];
                UserLockInfo storage userLock = userLockInfo[_lid][msg.sender][_did];
                amount = userLock.actualDeposit;

                require(!userLock.isWithdrawed, "HODL: Stake already withdrawed");
                uint256 weightedAmount = (amount * poolLock.multi) / DIVISOR;
                user.totalDeposit -= weightedAmount;
                pool.totalDeposit -= weightedAmount;

                userLock.isWithdrawed = true;
                totalActualDeposit -= amount;

                vestingCont.burn(msg.sender, amount);

                if (canWithdraw(_lid, _did, msg.sender)) {
                    token.safeTransfer(msg.sender, amount);
                } else {
                    require(block.timestamp >= vestingCont.unlockDisabledUntil(), "HODL: Forced unlock disabled");
                    uint256 feeAmount = (amount * poolLock.claimFee) / DIVISOR;
                    token.safeTransfer(feeWallet, feeAmount);
                    amount = amount - feeAmount;
                    token.safeTransfer(msg.sender, amount);
                }
            } else {
                require(user.totalDeposit >= amount, "HODL: Amount exceeds balance");

                user.totalDeposit = user.totalDeposit - amount;
                pool.totalDeposit = pool.totalDeposit - amount;

                token.safeTransfer(msg.sender, amount);
            }
        }

        user.rewardDebt = (user.totalDeposit * pool.accTknPerShare) / 1e12;
        emit Withdraw(msg.sender, _pid, _lid, _amounts);
    }

    function claimReward(uint256 _pid) public {
        _claimReward(_pid, msg.sender);
    }

    function _claimReward(uint256 _pid, address _user) internal {
        updatePool(_pid);
        UserInfo storage user = userInfo[_pid][_user];

        if (user.totalDeposit == 0) {
            return;
        }
        uint256 pending = (user.totalDeposit * poolInfo[_pid].accTknPerShare) / 1e12 - user.rewardDebt;

        if (pending > 0) {
            user.totalClaimed = user.totalClaimed + pending;
            user.rewardDebt = (user.totalDeposit * poolInfo[_pid].accTknPerShare) / 1e12;
            if (poolInfo[_pid].isVested == 1) {
                vestingCont.addVesting(_user, pending);
                reward.safeTransfer(address(vestingCont), pending);
            } else {
                reward.safeTransfer(_user, pending);
            }
        }

        emit RewardClaimed(_user, _pid, pending);
    }

    function setWallets(address _reward, address _feeWallet) external onlyOwner {
        require(_reward != address(0) && _feeWallet != address(0), "HODL: Zero address");
        rewardWallet = _reward;
        feeWallet = _feeWallet;
        emit WalletsChanged(_reward, _feeWallet);
    }

    function setPercentagePerDay(uint32 _perc) external onlyOwner {
        percPerDay = _perc;
        emit RewardChanged(_perc);
    }

    function setVesting(address _vesting) external onlyOwner {
        require(_vesting != address(0), "HODL: Zero address");
        vestingCont = IVesting(_vesting);
        emit VestingContractChanged(_vesting);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function getDepositedIdsOfUser(uint256 _pid, address _user) external view returns (uint256[] memory) {
        return userInfo[_pid][_user].depositedIds;
    }

    function getLockTermsOfUser(
        address _user,
        uint8 _lid
    ) external view returns (uint256 count, UserLockInfo[] memory) {
        return (userLockInfo[_lid][_user].length, userLockInfo[_lid][_user]);
    }

    function getRewardPerBlock() public view returns (uint256 rpb) {
        uint256 total = reward.balanceOf(rewardWallet);
        uint256 rewardPerDay = (total * percPerDay) / DIVISOR;
        rewardPerDay = rewardPerDay / 10; //Additional precision
        rpb = rewardPerDay / BLOCKS_PER_DAY;
    }
}