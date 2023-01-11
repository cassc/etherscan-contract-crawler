// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./BankBase.sol";
import "../interfaces/MasterChefInterfaces.sol";
import "../libraries/AddressArray.sol";
import "../libraries/UintArray.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

abstract contract IMasterChefWrapper is Ownable {
    using AddressArray for address[];
    using UintArray for uint256[];
    using Address for address;

    event LPTokenAdded(address masterChef, address lpToken, uint256 poolId);

    mapping(address => bool) public supportedLps;
    mapping(address => uint256) public supportedLpIndices;
    address public masterChef;
    address public baseReward;
    string public pendingRewardGetter;

    function getRewards(uint256 pid) external view virtual returns (address[] memory) {
        address[] memory rewards = new address[](1);
        rewards[0] = baseReward;
        return rewards;
    }

    function initialize() public virtual {
        uint256 poolLength = IMasterChefV1(masterChef).poolLength();
        for (uint256 i = 0; i < poolLength; i++) {
            setSupported(i);
        }
    }

    function setSupported(uint256 pid) public virtual {
        address lpToken = getLpToken(pid);
        supportedLpIndices[lpToken] = pid;
        supportedLps[lpToken] = true;
    }

    function getIdFromLpToken(address lpToken) external view virtual returns (bool, uint256) {
        if (!supportedLps[lpToken] || lpToken == baseReward) return (false, 0);
        else return (true, supportedLpIndices[lpToken]);
    }

    function getPendingRewards(
        uint256 pid
    ) external view virtual returns (address[] memory rewards, uint256[] memory amounts) {
        bytes memory returnData = masterChef.functionStaticCall(
            abi.encodeWithSignature(pendingRewardGetter, pid, msg.sender)
        );
        uint256 pending = abi.decode(returnData, (uint256));
        rewards = new address[](1);
        rewards[0] = baseReward;
        amounts = new uint256[](1);
        amounts[0] = pending;
    }

    function getLpToken(uint256 pid) public view virtual returns (address);

    function deposit(address masterChef, uint256 pid, uint256 amount) external virtual;

    function withdraw(address masterChef, uint256 pid, uint256 amount) external virtual;

    function harvest(address masterChef, uint256 pid) external virtual;
}

contract MasterChefV1Wrapper is IMasterChefWrapper {
    using AddressArray for address[];
    using UintArray for uint256[];
    using Address for address;

    constructor(address _masterChef, address _baseReward, string memory _pendingRewardGetter) {
        masterChef = _masterChef;
        baseReward = _baseReward;
        pendingRewardGetter = _pendingRewardGetter;
        initialize();
    }

    // function getIdFromLpToken(address lpToken) override external view returns (bool, uint) {
    //     uint poolLength = IMasterChefV1(masterChef).poolLength();
    //     for (uint i = 0; i<poolLength; i++) {
    //         IMasterChefV1.PoolInfo memory poolInfo = IMasterChefV1(masterChef).poolInfo(i);
    //         if (poolInfo.lpToken==lpToken) {
    //             return (true, i);
    //         }
    //     }
    //     return (false, 0);
    // }

    function getLpToken(uint256 pid) public view override returns (address) {
        IMasterChefV1.PoolInfo memory pool = IMasterChefV1(masterChef).poolInfo(pid);
        return pool.lpToken;
    }

    function deposit(address masterChef, uint256 pid, uint256 amount) external override {
        IMasterChefV1(masterChef).deposit(pid, amount);
    }

    function withdraw(address masterChef, uint256 pid, uint256 amount) external override {
        IMasterChefV1(masterChef).withdraw(pid, amount);
    }

    function harvest(address masterChef, uint256 pid) external override {
        IMasterChefV1(masterChef).withdraw(pid, 10);
        IMasterChefV1(masterChef).deposit(pid, 10);
    }
}

contract MasterChefV2Wrapper is IMasterChefWrapper {
    using AddressArray for address[];
    using UintArray for uint256[];
    using Address for address;
    mapping(uint256 => address) extraRewards;

    constructor(address _masterChef, address _baseReward, string memory _pendingRewardGetter) {
        masterChef = _masterChef;
        baseReward = _baseReward;
        pendingRewardGetter = _pendingRewardGetter;
        initialize();
    }

    // function getIdFromLpToken(address lpToken) override external view returns (bool, uint) {
    //     uint poolLength = ISushiSwapMasterChefV2(masterChef).poolLength();
    //     for (uint i = 0; i<poolLength; i++) {
    //         if (ISushiSwapMasterChefV2(masterChef).lpToken(i)==lpToken) {
    //             return (true, i);
    //         }
    //     }
    //     return (false, 0);
    // }

    function getLpToken(uint256 pid) public view override returns (address) {
        return ISushiSwapMasterChefV2(masterChef).lpToken(pid);
    }

    function getRewards(uint256 pid) external view override returns (address[] memory) {
        address[] memory rewards = new address[](1);
        rewards[0] = baseReward;
        address rewarder = ISushiSwapMasterChefV2(masterChef).rewarder(pid);
        if (rewarder != address(0)) {
            (address[] memory tokens, ) = IRewarder(rewarder).pendingTokens(0, address(this), 0);
            rewards = rewards.concat(tokens);
        }
        return rewards;
    }

    function getPendingRewards(
        uint256 pid
    ) external view override returns (address[] memory rewards, uint256[] memory rewardAmounts) {
        bytes memory returnData = masterChef.functionStaticCall(
            abi.encodeWithSignature(pendingRewardGetter, pid, msg.sender)
        );
        uint256 pending = abi.decode(returnData, (uint256));
        rewards = new address[](1);
        rewards[0] = baseReward;
        rewardAmounts = new uint256[](1);
        rewardAmounts[0] = pending;
        address rewarder = ISushiSwapMasterChefV2(masterChef).rewarder(pid);
        if (rewarder != address(0)) {
            (address[] memory tokens, uint256[] memory amounts) = IRewarder(rewarder).pendingTokens(pid, msg.sender, 0);
            rewards = rewards.concat(tokens);
            rewardAmounts = rewardAmounts.concat(amounts);
        }
    }

    function deposit(address masterChef, uint256 pid, uint256 amount) external override {
        ISushiSwapMasterChefV2(masterChef).deposit(pid, amount, address(this));
    }

    function withdraw(address masterChef, uint256 pid, uint256 amount) external override {
        ISushiSwapMasterChefV2(masterChef).withdraw(pid, amount, address(this));
    }

    function harvest(address masterChef, uint256 pid) external override {
        try ISushiSwapMasterChefV2(masterChef).pendingSushi(pid, address(this)) returns (uint256) {
            ISushiSwapMasterChefV2(masterChef).harvest(pid, address(this));
        } catch {}
    }
}

contract PancakeSwapMasterChefV2Wrapper is IMasterChefWrapper {
    using AddressArray for address[];
    using UintArray for uint256[];
    using Address for address;

    constructor(address _masterChef, address _baseReward, string memory _pendingRewardGetter) {
        masterChef = _masterChef;
        baseReward = _baseReward;
        pendingRewardGetter = _pendingRewardGetter;
        initialize();
    }

    // function getIdFromLpToken(address lpToken) override external view returns (bool, uint) {
    //     uint poolLength = IPancakeSwapMasterChefV2(masterChef).poolLength();
    //     for (uint i = 0; i<poolLength; i++) {
    //         if (IPancakeSwapMasterChefV2(masterChef).lpToken(i)==lpToken) {
    //             return (true, i);
    //         }
    //     }
    //     return (false, 0);
    // }

    function getLpToken(uint256 pid) public view override returns (address) {
        return ISushiSwapMasterChefV2(masterChef).lpToken(pid);
    }

    function deposit(address masterChef, uint256 pid, uint256 amount) external override {
        IMasterChefV1(masterChef).deposit(pid, amount);
    }

    function withdraw(address masterChef, uint256 pid, uint256 amount) external override {
        IMasterChefV1(masterChef).withdraw(pid, amount);
    }

    function harvest(address masterChef, uint256 pid) external override {
        IMasterChefV1(masterChef).withdraw(pid, 10);
        IMasterChefV1(masterChef).deposit(pid, 10);
    }
}