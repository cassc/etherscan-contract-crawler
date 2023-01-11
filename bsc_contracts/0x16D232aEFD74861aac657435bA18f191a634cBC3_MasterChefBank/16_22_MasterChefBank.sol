// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./BankBase.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./MasterChefWrappers.sol";
import "hardhat/console.sol";

contract MasterChefBank is ERC1155("MasterChefBank"), BankBase {
    using Address for address;
    using SaferERC20 for IERC20;

    event SetMasterChefWrapper(address masterChef, address wrapper);

    struct PoolInfo {
        address lpToken;
        uint256 lpSupply;
        mapping(address => uint256) rewardAllocationsPerShare;
        mapping(address => uint256) userShares;
        mapping(address => mapping(address => int256)) rewardDebt; // Mapping from user to reward to debt
    }

    uint256 PRECISION = 1e12;
    mapping(uint256 => PoolInfo) public poolInfo;
    mapping(address => address) public masterChefWrappers;
    address[] public supportedMasterChefs;
    mapping(address => uint256) public balances;

    constructor(address _positionsManager) BankBase(_positionsManager) {}

    function encodeId(address masterChef, uint256 pid) public pure returns (uint256) {
        return (pid << 160) | uint160(masterChef);
    }

    function setMasterChefWrapper(address masterChef, address wrapper) external onlyOwner {
        masterChefWrappers[masterChef] = wrapper;
        for (uint256 i = 0; i < supportedMasterChefs.length; i++) {
            if (supportedMasterChefs[i] == masterChef) {
                return;
            }
        }
        supportedMasterChefs.push(masterChef);
        emit SetMasterChefWrapper(masterChef, wrapper);
    }

    function decodeId(uint256 id) public view override returns (address lpToken, address masterChef, uint256 pid) {
        pid = id >> 160;
        masterChef = address(uint160(id & ((1 << 160) - 1)));
        lpToken = IMasterChefWrapper(masterChefWrappers[masterChef]).getLpToken(pid);
    }

    function getLPToken(uint256 id) public view override returns (address tokenAddress) {
        (tokenAddress, , ) = decodeId(id);
    }

    function name() public pure override returns (string memory) {
        return "Masterchef Bank";
    }

    function getIdFromLpToken(address lpToken) public view override returns (bool, uint256) {
        for (uint256 i = 0; i < supportedMasterChefs.length; i++) {
            IMasterChefWrapper wrapper = IMasterChefWrapper(masterChefWrappers[supportedMasterChefs[i]]);
            (bool success, uint256 id) = wrapper.getIdFromLpToken(lpToken);
            if (success) {
                return (true, encodeId(supportedMasterChefs[i], id));
            }
        }
        return (false, 0);
    }

    function getRewards(uint256 tokenId) external view override returns (address[] memory) {
        (, address masterChef, uint256 pid) = decodeId(tokenId);
        IMasterChefWrapper wrapper = IMasterChefWrapper(masterChefWrappers[masterChef]);
        return wrapper.getRewards(pid);
    }

    function getPendingRewardsForUser(
        uint256 tokenId,
        address user
    ) external view override returns (address[] memory rewards, uint256[] memory amounts) {
        PoolInfo storage pool = poolInfo[tokenId];
        uint256 lpSupply = pool.lpSupply;
        (, address masterChef, uint256 pid) = decodeId(tokenId);
        uint256[] memory everyonesRewardAmounts;
        (rewards, everyonesRewardAmounts) = IMasterChefWrapper(masterChefWrappers[masterChef]).getPendingRewards(pid);
        amounts = new uint256[](rewards.length);
        if (lpSupply > 0) {
            for (uint256 i = 0; i < rewards.length; i++) {
                address reward = rewards[i];
                uint256 allocationPerShare = pool.rewardAllocationsPerShare[rewards[i]] +
                    (everyonesRewardAmounts[i] * PRECISION) /
                    lpSupply;
                int256 accumulatedReward = int256((pool.userShares[user] * allocationPerShare) / PRECISION);
                uint256 pendingReward = uint256(accumulatedReward - pool.rewardDebt[user][reward]);
                amounts[i] = pendingReward;
            }
        }
    }

    function getPositionTokens(
        uint256 tokenId,
        address userAddress
    ) external view override returns (address[] memory outTokens, uint256[] memory tokenAmounts) {
        (address lpToken, , ) = decodeId(tokenId);
        uint256 amount = balanceOf(userAddress, tokenId);
        outTokens = new address[](1);
        tokenAmounts = new uint256[](1);
        outTokens[0] = lpToken;
        tokenAmounts[0] = amount;
    }

    function _harvest(address masterChef, address lpToken, uint256 pid) internal {
        IERC20(lpToken).safeIncreaseAllowance(masterChef, 10);
        address masterChefWrapperAddress = masterChefWrappers[masterChef];
        IMasterChefWrapper wrapper = IMasterChefWrapper(masterChefWrappers[masterChef]);
        masterChefWrapperAddress.functionDelegateCall(
            abi.encodeWithSelector(wrapper.harvest.selector, masterChef, pid)
        );
    }

    function updateToken(uint256 tokenId) internal onlyAuthorized {
        (address lpToken, address masterChef, uint256 pid) = decodeId(tokenId);
        PoolInfo storage pool = poolInfo[tokenId];
        uint256 lpSupply = pool.lpSupply;
        if (lpSupply > 0) {
            address[] memory rewards = IMasterChefWrapper(masterChefWrappers[masterChef]).getRewards(pid);
            uint256[] memory rewardAmounts = new uint256[](rewards.length);
            for (uint256 i = 0; i < rewards.length; i++) {
                rewardAmounts[i] = IERC20(rewards[i]).balanceOf(address(this));
            }
            _harvest(masterChef, lpToken, pid);
            for (uint256 i = 0; i < rewards.length; i++) {
                rewardAmounts[i] = IERC20(rewards[i]).balanceOf(address(this)) - rewardAmounts[i];
                pool.rewardAllocationsPerShare[rewards[i]] += (rewardAmounts[i] * PRECISION) / lpSupply;
            }
        }
    }

    function _deposit(address masterChef, uint256 pid, uint256 amount) internal {
        address masterChefWrapper = masterChefWrappers[masterChef];
        masterChefWrapper.functionDelegateCall(
            abi.encodeWithSelector(IMasterChefWrapper.deposit.selector, masterChef, pid, amount)
        );
    }

    function _withdraw(address masterChef, uint256 pid, uint256 amount) internal {
        address masterChefWrapper = masterChefWrappers[masterChef];
        masterChefWrapper.functionDelegateCall(
            abi.encodeWithSelector(IMasterChefWrapper.withdraw.selector, masterChef, pid, amount)
        );
    }

    function mint(
        uint256 tokenId,
        address userAddress,
        address[] memory suppliedTokens,
        uint256[] memory suppliedAmounts
    ) public override onlyAuthorized returns (uint256) {
        updateToken(tokenId);
        (address lpToken, address masterChef, uint256 pid) = decodeId(tokenId);
        require(lpToken == suppliedTokens[0], "6");
        IERC20(lpToken).safeIncreaseAllowance(masterChef, suppliedAmounts[0]);
        _deposit(masterChef, pid, suppliedAmounts[0]);
        PoolInfo storage pool = poolInfo[tokenId];
        pool.userShares[userAddress] += suppliedAmounts[0];
        pool.lpSupply += suppliedAmounts[0];
        address[] memory rewards = IMasterChefWrapper(masterChefWrappers[masterChef]).getRewards(pid);
        for (uint256 i = 0; i < rewards.length; i++) {
            address reward = rewards[i];
            pool.rewardDebt[userAddress][reward] += int256(
                (suppliedAmounts[0] * pool.rewardAllocationsPerShare[reward]) / PRECISION
            );
        }
        _mint(userAddress, tokenId, suppliedAmounts[0], "");
        emit Mint(tokenId, userAddress, suppliedAmounts[0]);
        return suppliedAmounts[0];
    }

    function burn(
        uint256 tokenId,
        address userAddress,
        uint256 amount,
        address receiver
    ) external override onlyAuthorized returns (address[] memory outTokens, uint256[] memory tokenAmounts) {
        updateToken(tokenId);
        (address lpToken, address masterChef, uint256 pid) = decodeId(tokenId);
        PoolInfo storage pool = poolInfo[tokenId];
        address[] memory rewards = IMasterChefWrapper(masterChefWrappers[masterChef]).getRewards(pid);
        for (uint256 i = 0; i < rewards.length; i++) {
            address reward = rewards[i];
            pool.rewardDebt[userAddress][reward] -= int256(
                (amount * pool.rewardAllocationsPerShare[reward]) / PRECISION
            );
        }
        pool.userShares[userAddress] -= amount;
        pool.lpSupply -= amount;
        _withdraw(masterChef, pid, amount);
        IERC20(lpToken).safeTransfer(receiver, amount);
        _burn(userAddress, tokenId, amount);
        emit Burn(tokenId, userAddress, amount, receiver);
        outTokens = new address[](1);
        tokenAmounts = new uint256[](1);
        outTokens[0] = lpToken;
        tokenAmounts[0] = amount;
    }

    function harvest(
        uint256 tokenId,
        address userAddress,
        address receiver
    ) external override onlyAuthorized returns (address[] memory rewardAddresses, uint256[] memory rewardAmounts) {
        updateToken(tokenId);
        PoolInfo storage pool = poolInfo[tokenId];
        (, address masterChef, uint256 pid) = decodeId(tokenId);
        address[] memory rewards = IMasterChefWrapper(masterChefWrappers[masterChef]).getRewards(pid);
        rewardAddresses = new address[](rewards.length);
        rewardAmounts = new uint256[](rewards.length);
        for (uint256 i = 0; i < rewards.length; i++) {
            address reward = rewards[i];
            int256 accumulatedReward = int256(
                (pool.userShares[userAddress] * pool.rewardAllocationsPerShare[reward]) / PRECISION
            );
            uint256 pendingReward = uint256(accumulatedReward - pool.rewardDebt[userAddress][reward]);
            pool.rewardDebt[userAddress][reward] = accumulatedReward;
            if (pendingReward != 0) {
                IERC20(reward).safeTransfer(receiver, pendingReward);
            }
            rewardAddresses[i] = rewards[i];
            rewardAmounts[i] = pendingReward;
        }
        emit Harvest(tokenId, userAddress, receiver);
    }
}