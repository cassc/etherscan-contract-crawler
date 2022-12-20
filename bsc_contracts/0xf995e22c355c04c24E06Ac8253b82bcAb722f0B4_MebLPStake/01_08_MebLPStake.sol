// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract MebLPStake is Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor() {
        rewardPercent[60 * 24 * 3600] = 150;
        rewardPercent[180 * 24 * 3600] = 300;
        rewardPercent[360 * 24 * 3600] = 650;
    }

    address public constant lp = 0xCCf2410dB619c759F901D568Bc993d4f4231F560;

    uint256 public depositInterval = 12 * 3600;
    mapping(address => uint256) public lastDeposit;

    function setDepositInterval(uint256 _depositInterval) external onlyOwner {
        depositInterval = _depositInterval;
    }

    struct DepositInfo {
        uint256 amount;
        uint256 effect;
        uint256 createTime;
        uint256 lockUtil;
        bool status;
        mapping(address => uint256) debts;
        mapping(address => uint256) rewards;
    }

    uint256 public totalEffect;
    uint256 public totalAmount;

    mapping(address => DepositInfo[]) public userDeposits;

    EnumerableSet.AddressSet private rewardTokens;
    mapping(uint256 => uint256) public rewardPercent;
    mapping(address => uint256) public accs;
    mapping(address => mapping(address => uint256)) public withdrawables;

    function setRewardPercent(uint256 lockTimeSecond, uint256 percent) external onlyOwner {
        rewardPercent[lockTimeSecond] = percent;
    }

    function rewardTokenAdd(address token) external onlyOwner {
        require(rewardTokens.add(token), "token already exist.");
    }

    function rewardTokenList() external view returns (address[] memory) {
        return rewardTokens.values();
    }

    function award(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        if (totalEffect != 0 && amount != 0) {
            accs[token] += (amount * 1e18) / totalEffect;
        }
    }

    function deposit(uint256 lockSecond, uint256 amount) external {
        require(rewardPercent[lockSecond] != 0, "MebLPStake : lockSecond invalid");
        require(lastDeposit[msg.sender] + depositInterval < block.timestamp, "MebLPStake : depositInterval limit");
        IERC20(lp).safeTransferFrom(msg.sender, address(this), amount);
        uint256 effect = (rewardPercent[lockSecond] * amount) / 100;
        DepositInfo storage depositInfo = userDeposits[msg.sender].push();
        depositInfo.amount = amount;
        depositInfo.effect = effect;
        depositInfo.createTime = block.timestamp;
        depositInfo.lockUtil = block.timestamp + lockSecond;
        depositInfo.status = true;

        for (uint256 i = 0; i < rewardTokens.length(); i++) {
            depositInfo.debts[rewardTokens.at(i)] = (effect * accs[rewardTokens.at(i)]) / 1e18;
        }
        totalEffect += effect;
        totalAmount += amount;
    }

    function withdraw(uint256 _index) external {
        DepositInfo storage depositInfo = userDeposits[msg.sender][_index];
        require(depositInfo.status, "MebLPStake : deposit is already withdraw");
        require(depositInfo.lockUtil <= block.timestamp, "MebLPStake : deposit is locked");
        for (uint256 i = 0; i < rewardTokens.length(); i++) {
            address token = rewardTokens.at(i);
            uint256 _pending = pending3(msg.sender, _index, token);
            depositInfo.rewards[token] += _pending;
            withdrawables[msg.sender][token] += _pending;
        }
        depositInfo.status = false;

        totalEffect -= depositInfo.effect;
        totalAmount -= depositInfo.amount;
        IERC20(lp).safeTransfer(msg.sender, depositInfo.amount);
    }

    function harvest(address token) external {
        DepositInfo[] storage deposits = userDeposits[msg.sender];
        uint256 totalPedding;
        for (uint256 i = 0; i < deposits.length; i++) {
            if (!deposits[i].status) {
                continue;
            }
            uint256 _pending = pending3(msg.sender, i, token);
            deposits[i].debts[token] += _pending;
            deposits[i].rewards[token] += _pending;
            totalPedding += _pending;
        }

        if (withdrawables[msg.sender][token] > 0) {
            totalPedding += withdrawables[msg.sender][token];
            withdrawables[msg.sender][token] = 0;
        }
        if (totalPedding > 0) {
            IERC20(token).safeTransfer(msg.sender, totalPedding);
        }
    }

    function pending1(address addr) external view returns (address[] memory addrs, uint256[] memory pendings) {
        addrs = rewardTokens.values();
        pendings = new uint256[](addrs.length);
        DepositInfo[] storage userDepositInfosPool = userDeposits[addr];
        for (uint256 i = 0; i < addrs.length; i++) {
            for (uint256 j = 0; j < userDepositInfosPool.length; j++) {
                pendings[i] += pending3(addr, j, addrs[i]);
            }
        }
    }

    function pending2(address addr, uint256 _index) external view returns (address[] memory addrs, uint256[] memory pendings) {
        addrs = rewardTokens.values();
        pendings = new uint256[](addrs.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            addrs[i] = rewardTokens.at(i);
            pendings[i] = pending3(addr, _index, addrs[i]);
        }
    }

    function pending3(
        address addr,
        uint256 _index,
        address token
    ) public view returns (uint256) {
        if (!rewardTokens.contains(token)) {
            return 0;
        }
        DepositInfo storage depositInfo = userDeposits[addr][_index];
        if (!depositInfo.status) {
            return 0;
        }
        return (depositInfo.effect * accs[token]) / 1e18 - depositInfo.debts[token];
    }

    function userDebts(address addr, uint256 _index) external view returns (address[] memory addrs, uint256[] memory debts) {
        addrs = rewardTokens.values();
        debts = new uint256[](addrs.length);
        DepositInfo storage depositInfo = userDeposits[addr][_index];

        for (uint256 i = 0; i < addrs.length; i++) {
            debts[i] = depositInfo.debts[addrs[i]];
        }
    }

    function userAllDeposits(address addr)
        external
        view
        returns (
            uint256[] memory amounts,
            uint256[] memory effects,
            uint256[] memory createTime,
            uint256[] memory lockUtils,
            bool[] memory status
        )
    {
        DepositInfo[] storage depositInfos = userDeposits[addr];
        uint256 count = depositInfos.length;
        amounts = new uint256[](count);
        effects = new uint256[](count);
        createTime = new uint256[](count);
        lockUtils = new uint256[](count);
        status = new bool[](count);
        for (uint256 i = 0; i < count; i++) {
            amounts[i] = depositInfos[i].amount;
            effects[i] = depositInfos[i].effect;
            createTime[i] = depositInfos[i].createTime;
            lockUtils[i] = depositInfos[i].lockUtil;
            status[i] = depositInfos[i].status;
        }
    }
}