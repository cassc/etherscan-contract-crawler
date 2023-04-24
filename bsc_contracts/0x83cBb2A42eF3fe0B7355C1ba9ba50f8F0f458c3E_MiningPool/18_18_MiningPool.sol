//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IPancakePair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IAccount {
    function info(address addr) external view returns (address parent, uint8 level);
}

contract MiningPool is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    address public constant TOKEN = 0x73C67b35D12ecA86c74AF621BA33294Bbb343f02;
    address public constant LP = 0x1a0887e8035761427ea8c464Ab90c35831d877b6;
    address public constant ACCOUNT = 0x49821Ff0909C70f879da77B739bF3ffceBE3946A;
    uint256 public constant REWARD_INTERVAL = 2 * 3600;
    uint256 public constant BASE_VLAUE = 1500000e18;
    uint256 public constant BASE_REWARD_AMOUNT = uint256(40000e18) / 12;
    uint16 public constant EXPIRE_INTERVAL = 12;

    struct DepositRecord {
        uint256 id;
        uint256 amount;
        uint256 effect;
        uint256 debtAcc;
        uint256 dueTime;
        bool status;
    }

    struct RewardInfo {
        uint256 lastRewardTime;
        uint256 amount;
    }

    struct PoolInfo {
        uint256 duration;
        uint256 rewardPercent;
        uint256 minDepositLimit;
        bool status;
    }

    PoolInfo[] public poolInfo;
    mapping(uint256 => uint256) public expireAmounts;
    mapping(uint256 => uint256) public expireEffects;
    mapping(uint256 => uint256) public accCheckpoints;
    mapping(address => mapping(uint256 => DepositRecord[])) depositRecords;
    mapping(address => RewardInfo) public rewardInfos;

    uint256 public totalAmount;
    uint256 public totalEffect;
    uint256 public acc;
    uint256 public nextRewardTime;
    uint256 private _depositId;
    bool public rewardStatus;

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        rewardStatus = true;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function addPool(uint256 duration, uint256 rewardPercent, uint256 minDepositLimit, bool status) external onlyRole(OPERATOR_ROLE) {
        poolInfo.push(PoolInfo({duration: duration, rewardPercent: rewardPercent, minDepositLimit: minDepositLimit, status: status}));
    }

    function updatePool(uint256 poolId, uint256 rewardPercent, uint256 minDepositLimit, bool status) external onlyRole(OPERATOR_ROLE) {
        PoolInfo storage pool = poolInfo[poolId];
        pool.rewardPercent = rewardPercent;
        pool.minDepositLimit = minDepositLimit;
        pool.status = status;
    }

    function setPoolStatus(uint256 poolId, bool status) external onlyRole(OPERATOR_ROLE) {
        poolInfo[poolId].status = status;
    }

    function setRewardStatus(bool _rewardStatus) external onlyRole(OPERATOR_ROLE) {
        rewardStatus = _rewardStatus;
    }

    function initRewardTime(uint256 _nextRewardTime) external onlyRole(OPERATOR_ROLE) {
        require(nextRewardTime == 0, "duplicate init");
        nextRewardTime = _nextRewardTime;
    }

    function getRewardAmount() public view returns (uint256 rewardAmount) {
        uint256 totalValue = (totalAmount * getLpPrice()) / 1e18;
        uint256 amount = BASE_VLAUE;
        rewardAmount = BASE_REWARD_AMOUNT;
        while (totalValue > amount) {
            amount *= 2;
            rewardAmount /= 2;
        }
    }

    function reward() external {
        require(nextRewardTime > 0, "reward time not init");
        require(block.timestamp >= nextRewardTime, "reward time limited");
        uint256 rewardAmount = (getRewardAmount() * 5) / 10;
        while (nextRewardTime <= block.timestamp) {
            if (rewardStatus == true && totalEffect > 0) {
                acc += (rewardAmount * 1e18) / totalEffect;
            }
            uint256 interval = nextRewardTime / REWARD_INTERVAL;
            accCheckpoints[interval] = acc;
            if (expireEffects[interval] > 0) {
                totalEffect -= expireEffects[interval];
                totalAmount -= expireAmounts[interval];
            }
            nextRewardTime += REWARD_INTERVAL;
        }
    }

    function deposit(uint256 pid, uint256 amount) external {
        require(pid < poolInfo.length, "invalid pool");
        require(amount > 0, "invalid amount");
        (address parent, ) = IAccount(ACCOUNT).info(msg.sender);
        require(parent != address(0), "account not registed");
        PoolInfo storage pool = poolInfo[pid];
        require(pool.status, "pool status limited");
        uint256 lpPrice = getLpPrice();
        uint256 depositValue = (amount * lpPrice) / 1e18;
        require(depositValue >= pool.minDepositLimit, "min amount limited");
        IERC20Upgradeable(LP).safeTransferFrom(msg.sender, address(this), amount);
        uint256 effect = (depositValue * pool.rewardPercent) / 100;
        uint256 dueTime = block.timestamp + pool.duration;
        depositRecords[msg.sender][pid].push(DepositRecord({id: _depositId, amount: amount, effect: effect, debtAcc: acc, dueTime: dueTime, status: true})); //新增质押记录
        _depositId++;
        totalAmount += amount;
        totalEffect += effect;
        expireEffects[getInterval(dueTime)] += effect;
        expireAmounts[getInterval(dueTime)] += amount;
    }

    function withdraw(uint256 pid, uint256 depositId) external {
        DepositRecord storage record = depositRecords[msg.sender][pid][depositId];
        uint256 dueTime = record.dueTime;
        require(block.timestamp > dueTime, "withdraw time limited");
        require(record.status, "duplicate withdraw");
        record.status = false;
        uint256 amount = record.amount;
        (uint256 newAcc, uint256 debtAcc) = getAcc(dueTime, record.debtAcc);
        uint256 rewardAmount = (record.effect * (newAcc - debtAcc)) / 1e18;
        record.debtAcc = newAcc;
        if (rewardAmount > 0) {
            IERC20Upgradeable(TOKEN).safeTransfer(msg.sender, rewardAmount);
            RewardInfo storage info = rewardInfos[msg.sender];
            info.lastRewardTime = block.timestamp;
            info.amount += rewardAmount;
        }
        IERC20Upgradeable(LP).safeTransfer(msg.sender, amount);
    }

    function harvest(uint256[] calldata pids, uint256[][] calldata depositIds) external {
        uint256 rewardAmount = 0;
        for (uint256 i = 0; i < pids.length; i++) {
            for (uint256 j = 0; j < depositIds[i].length; j++) {
                DepositRecord storage record = depositRecords[msg.sender][pids[i]][depositIds[i][j]];
                (uint256 newAcc, uint256 debtAcc) = getAcc(record.dueTime, record.debtAcc);
                uint256 amount = (record.effect * (newAcc - debtAcc)) / 1e18;
                rewardAmount += amount;
                record.debtAcc = newAcc;
            }
        }
        if (rewardAmount > 0) {
            IERC20Upgradeable(TOKEN).safeTransfer(msg.sender, rewardAmount);
            RewardInfo storage info = rewardInfos[msg.sender];
            info.lastRewardTime = block.timestamp;
            info.amount += rewardAmount;
        }
    }

    function pending(address addr, uint256[] calldata pids, uint256[][] calldata depositIds) external view returns (uint256[][] memory rewardAmounts) {
        rewardAmounts = new uint256[][](pids.length);
        for (uint256 i = 0; i < pids.length; i++) {
            rewardAmounts[i] = new uint256[](depositIds[i].length);
            for (uint256 j = 0; j < depositIds[i].length; j++) {
                DepositRecord storage record = depositRecords[addr][pids[i]][depositIds[i][j]];
                (uint256 newAcc, uint256 debtAcc) = getAcc(record.dueTime, record.debtAcc);
                rewardAmounts[i][j] = (record.effect * (newAcc - debtAcc)) / 1e18;
            }
        }
    }

    function getLpPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = IPancakePair(LP).getReserves();
        address token1 = IPancakePair(LP).token1();
        if (token1 == TOKEN) {
            reserve1 = reserve0;
        }
        uint256 lpTotalSupply = IERC20Upgradeable(LP).totalSupply();
        return (2 * uint256(reserve1) * 1e18) / lpTotalSupply;
    }

    function getDepositRecord(address addr, uint256 pid, uint256 depositId) public view returns (DepositRecord memory) {
        return depositRecords[addr][pid][depositId];
    }

    function getDepositRecords(address addr, uint256 pid) public view returns (DepositRecord[] memory) {
        return depositRecords[addr][pid];
    }

    function getAllDepositRecords(address addr) public view returns (uint256[] memory pids, DepositRecord[][] memory records) {
        uint256 size = poolInfo.length;
        pids = new uint256[](size);
        records = new DepositRecord[][](size);
        for (uint256 i = 0; i < size; i++) {
            pids[i] = i;
            records[i] = depositRecords[addr][i];
        }
    }

    function getPoolInfos() public view returns (PoolInfo[] memory) {
        return poolInfo;
    }

    function getAcc(uint256 dueTime, uint256 debtAcc) internal view returns (uint256 newAcc, uint256 newDebtAcc) {
        uint256 dueTimeAcc = accCheckpoints[getInterval(dueTime)];
        newAcc = dueTimeAcc > 0 ? dueTimeAcc : acc;
        uint256 expireTime = block.timestamp > dueTime ? dueTime : block.timestamp;
        uint256 expireAcc = accCheckpoints[getInterval(expireTime - REWARD_INTERVAL * EXPIRE_INTERVAL)];
        newDebtAcc = expireAcc > debtAcc ? expireAcc : debtAcc;
    }

    function getInterval(uint256 time) internal pure returns (uint256) {
        return time / REWARD_INTERVAL;
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }
}