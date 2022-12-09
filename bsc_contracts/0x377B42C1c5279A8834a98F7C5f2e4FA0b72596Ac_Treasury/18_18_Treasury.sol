// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IBonds {
    function ownerOf(uint256 tokenId) external view returns (address);

    function mint(address to) external returns (uint256 tokenId);

    function burn(uint256 tokenId) external;
}

interface IMUSD {
    function mint(address account, uint256 amount) external;
}

contract Treasury is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant MUSD = 0x6F7AC1715F73583a77409d9242A4d110791038d9;
    address public constant BONDS = 0x8999f34550fe5585115ECFf0e911C6F6C8b0E8cd;
    uint256 public constant REWARD_INTERVAL = 24 * 3600;
    address public lendingPool;

    struct BondsInfo {
        uint256 amount;
        uint256 shareAmount;
        uint256 dueTime;
        uint256 rewardDebt;
    }
    mapping(uint256 => BondsInfo) public bondsInfo;
    mapping(uint256 => uint256) public expireAmounts;
    mapping(uint256 => uint256) public accCheckpoints;

    struct PoolInfo {
        uint256 allocPoint;
        uint256 duration;
    }
    PoolInfo[] public poolInfo;
    uint256 public totalAllocPoint;
    uint256 public totalBondsAmount;
    uint256 public totalShareAmount;
    uint256 public totalRewardAmount;
    uint256 public accRewardPerShare;
    uint256 public nextRewardTime;
    uint16 public rewardPercent;

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);

        //init variable
        rewardPercent = 1000;
    }

    function addPool(uint256 allocPoint, uint256 duration) external onlyRole(OPERATOR_ROLE) {
        poolInfo.push(PoolInfo({allocPoint: allocPoint, duration: duration}));
        totalAllocPoint += allocPoint;
    }

    function updatePool(uint256 pid, uint256 allocPoint) external onlyRole(OPERATOR_ROLE) {
        totalAllocPoint = totalAllocPoint - poolInfo[pid].allocPoint + allocPoint;
        poolInfo[pid].allocPoint = allocPoint;
    }

    function setRewardPercent(uint16 _rewardPercent) external onlyRole(OPERATOR_ROLE) {
        rewardPercent = _rewardPercent;
    }

    function initRewardTime(uint256 _nextRewardTime) external onlyRole(OPERATOR_ROLE) {
        require(nextRewardTime == 0, "duplicate init");
        nextRewardTime = _nextRewardTime;
    }

    function setLendingPool(address _lendingPool) external onlyRole(OPERATOR_ROLE) {
        lendingPool = _lendingPool;
    }

    function mint(uint256 pid, uint256 amount) external {
        require(amount > 0, "invalid amount");
        require(poolInfo[pid].allocPoint > 0, "invalid pool");
        IERC20Upgradeable(USDT).safeTransferFrom(msg.sender, lendingPool, amount);
        uint256 tokenId = IBonds(BONDS).mint(msg.sender);
        uint256 shareAmount = (amount * poolInfo[pid].allocPoint) / totalAllocPoint;
        uint256 dueTime = block.timestamp + poolInfo[pid].duration;
        bondsInfo[tokenId] = BondsInfo({amount: amount, shareAmount: shareAmount, dueTime: dueTime, rewardDebt: (shareAmount * accRewardPerShare) / 1e18});
        totalBondsAmount += amount;
        totalShareAmount += shareAmount;
        expireAmounts[getInterval(dueTime)] += shareAmount;
    }

    function redeem(uint256 tokenId) external {
        require(IBonds(BONDS).ownerOf(tokenId) == msg.sender, "not token owner");
        BondsInfo memory data = bondsInfo[tokenId];
        uint256 amount = data.amount;
        require(block.timestamp > data.dueTime, "redeem time limited");
        IBonds(BONDS).burn(tokenId);
        IMUSD(MUSD).mint(msg.sender, amount);
        totalBondsAmount -= amount;
        uint256 acc = getAccRwardPerShare(data.dueTime);
        uint256 rewardAmount = (data.shareAmount * acc) / 1e18 - data.rewardDebt;
        if (rewardAmount > 0) {
            IERC20Upgradeable(MUSD).safeTransfer(msg.sender, rewardAmount);
        }
        delete bondsInfo[tokenId];
    }

    function recharge(uint256 amount) external {
        IERC20Upgradeable(MUSD).safeTransferFrom(msg.sender, address(this), amount);
        totalRewardAmount += amount;
    }

    function processReward() external {
        require(nextRewardTime > 0, "reward time not init");
        require(block.timestamp > nextRewardTime, "reward time limited");
        uint256 rewardAmount = (totalRewardAmount * rewardPercent) / (1000 * 365);
        if (totalShareAmount > 0) {
            accRewardPerShare += (rewardAmount * 1e18) / totalShareAmount;
            totalRewardAmount -= rewardAmount;
        }
        uint256 interval = nextRewardTime / REWARD_INTERVAL;
        if (expireAmounts[interval] > 0) {
            accCheckpoints[interval] = accRewardPerShare;
            totalShareAmount -= expireAmounts[interval];
        }
        nextRewardTime += REWARD_INTERVAL;
    }

    function pending(uint256[] calldata tokenIds) external view returns (uint256[] memory rewards) {
        rewards = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            BondsInfo storage data = bondsInfo[tokenIds[i]];
            uint256 acc = getAccRwardPerShare(data.dueTime);
            rewards[i] = (data.shareAmount * acc) / 1e18 - data.rewardDebt;
        }
    }

    function harvest(uint256[] calldata tokenIds) external {
        uint256 rewardAmount = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            BondsInfo storage data = bondsInfo[tokenIds[i]];
            if (IBonds(BONDS).ownerOf(tokenIds[i]) != msg.sender) revert("not token owner");
            uint256 acc = getAccRwardPerShare(data.dueTime);
            uint256 rewardWithDebt = (data.shareAmount * acc) / 1e18;
            rewardAmount += (rewardWithDebt - data.rewardDebt);
            data.rewardDebt = rewardWithDebt;
        }
        if (rewardAmount > 0) IERC20Upgradeable(MUSD).safeTransfer(msg.sender, rewardAmount);
    }

    function getAccRwardPerShare(uint256 dueTime) internal view returns (uint256) {
        uint256 expireAcc = accCheckpoints[getInterval(dueTime)];
        return expireAcc > 0 ? expireAcc : accRewardPerShare;
    }

    function getInterval(uint256 time) internal pure returns (uint256) {
        return (time + REWARD_INTERVAL - 1) / REWARD_INTERVAL;
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }
}