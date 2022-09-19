// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interface/IGas.sol";
import "./interface/IGasStake.sol";
import "./interface/DoubleEndedQueueAddress.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

interface IRandom {
    function finalDays(uint256 k, bool first) external view returns (uint256 days_);

    function withdrawDays(uint256 k) external view returns (uint256 days_);
}

interface IAccount {
    function add(address addr, address parent_) external;

    function upgrade(address addr, uint8 target, uint256 depositTotal) external;

    function reset(address addr, uint8 level) external;

    function info(address addr) external view returns (address parent_, uint8 level_, uint256 id);

    function follows(address addr) external view returns (address[] memory);

    function parent(address addr) external view returns (address);

    function level(address addr) external view returns (uint8);

    function upGradeCount() external view returns (uint8[] memory counts, uint256 deposit);
}

interface IUniswapV2Router01 {

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}


contract BankLink is ReentrancyGuard, AccessControlEnumerable {
    using SafeERC20 for IERC20;
    using DoubleEndedQueue for DoubleEndedQueue.AddressDeque;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    string _name = "BankLink";

    function name() external view returns (string memory){
        return _name;
    }

    uint32[] versions;
    uint32 versionTimes;

    uint32 constant INTERVAL = 24 * 60 * 60;
    address usdt = 0x55d398326f99059fF775485246999027B3197955;
    address gas = 0xf038F7286f060115581598c6e0E7C6110EA955e8;
    address gasStake = 0x84594b7c24a39DbF9c81AF723e54dC4586972ecb;
    address blc  = 0x55476A6381aEB31F3ce34F363f7d2bbBECE2B311;
    address router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    function baseInit(address usdtAddr, address gasAddr, address gasStakeAddr, address blcAddr, address account, 
        address random, address routerAddr, string calldata nameStr)
    external onlyRole(DEFAULT_ADMIN_ROLE) {
        usdt = usdtAddr;
        gas = gasAddr;
        gasStake = gasStakeAddr;
        blc = blcAddr;
        iAccount = IAccount(account);
        iRandom = IRandom(random);
        router = routerAddr;
        _name = nameStr;
    }

    IRandom private iRandom;
    IAccount private iAccount;

    uint256 public flowInTotal;
    uint256 public depositTotal;
    uint256 public preTotal;
    uint256 public withdrawTotal;

    uint8[] public bonusPercents = [0, 7, 9, 11, 13, 15];
    uint8 public topBonusPercent = 1;
    uint8 public baseRate = 13;

    uint256[] public depositEach = [1000e18, 1000e18, 3000e18, 5000e18, 7000e18, 10000e18];
    uint32[] public depositInterval = [7 * INTERVAL, 7 * INTERVAL, 5 * INTERVAL, 3 * INTERVAL, 2 * INTERVAL, 1 * INTERVAL];

    struct Broker {
        uint32 currentVersion;
        uint256 depositTotal;
        uint256 depositCurrent;
        uint256 bonusCalc;
        uint256 bonusMax;
        uint256 bonusDrawed;
        uint256 punishTimes;
        int256 profitAmount;
    }

    mapping(address => Broker) public brokers;
    mapping(uint32 => uint256) public depositAmountDays;

    struct Deposit {
        uint256 amount;
        uint256 preAmount;
        uint256 finalAmount;
        uint256 withdrawAmount;
        uint8 ratePercent;
        uint32 createTimestamp;
        uint32 startFinalPayTimestamp;
        uint32 endFinalPayTimestamp;
        uint32 drawableTimestamp;
        uint8 status;
    }

    mapping(address => Deposit[]) private deposits;

    mapping(uint32 => uint256) public gasCalcs;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        iAccount = IAccount(0x8702FF9E9428396C436ca1EbbF2F919b976Cfb4A);
        iRandom = IRandom(0x00C2D7B89397861dBf6371014F99FD3015AC00b0);
        versions.push(uint32(block.timestamp));
    }

    function setDepositInterval(uint8 idx, uint32 interval) external onlyRole(OPERATOR_ROLE) {
        depositInterval[idx] = interval;
    }

    function setDepositEach(uint8 idx, uint256 amount) external onlyRole(OPERATOR_ROLE) {
        depositEach[idx] = amount;
    }

    function setBaseRate(uint8 base, uint8 topBonus) external onlyRole(OPERATOR_ROLE) {
        baseRate = base;
        topBonusPercent = topBonus;
    }

    function setBonus(uint8 idx, uint8 amount) external onlyRole(OPERATOR_ROLE) {
        bonusPercents[idx] = amount;
    }

    function versionList() external view returns (uint32[] memory) {
        return versions;
    }

    function active(address parent) external {
        accountAdd(msg.sender, parent);
    }

    function invite(address addr) external {
        accountAdd(addr, msg.sender);
    }

    function accountAdd(address addr, address parent) private {
        require(!restartStatus, "system on restart status");
        iAccount.add(addr, parent);
        burnGas(1e18);
        brokers[addr].currentVersion = versions[versionTimes];
    }

    function upgrade(uint8 target) external {
        iAccount.upgrade(msg.sender, target, brokers[msg.sender].depositTotal);
    }

    function accountInfo(address addr) external view returns (address parent, uint8 level, uint256 id)     {
        (parent, level, id) = iAccount.info(addr);
    }

    function followList(address addr) external view returns (address[] memory addrs, uint256[] memory levels) {
        addrs = iAccount.follows(addr);
        levels = new uint256[](addrs.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            (, levels[i],) = iAccount.info(addrs[i]);
        }
    }

    function upGradeCount() external view returns (uint8[] memory counts, uint256 deposit) {
        (counts, deposit) = iAccount.upGradeCount();
    }

    function preDeposit(uint256 amount) external nonReentrant {
        _lossClaim(msg.sender);
        require(amount >= 100e18, "BankLink: amount must greater than 100.");
        require(amount % 1e18 == 0, "BankLink: amount must be an integer.");
        require(!restartStatus, "BankLink: system on restart.");
        require(depositRemainToday() > 0, "BankLink: insufficient remain today.");
        (, uint8 level, uint256 id) = iAccount.info(msg.sender);
        require(id != 0, "BankLink: account have not active.");
        require(amount <= depositEach[level], "BankLink: amount limit of your level.");
        require(deposits[msg.sender].length == 0 ||
            block.timestamp - deposits[msg.sender][deposits[msg.sender].length - 1].createTimestamp >= depositInterval[level],
            "BankLink: deposit interval limit of your level."
        );
        require(!checkBlacklist(msg.sender), "BankLink: you are in blacklist");
        uint256 preAmount = amount / 10;
        Deposit storage deposit = deposits[msg.sender].push();
        deposit.amount = amount;
        deposit.preAmount = preAmount;
        deposit.finalAmount = amount - preAmount;
        deposit.ratePercent = baseRate;
        deposit.withdrawAmount = amount + (amount * deposit.ratePercent) / 100;
        deposit.createTimestamp = uint32(block.timestamp);

        uint256 days_ = iRandom.finalDays(depositWithdrawRate(), brokers[msg.sender].depositTotal == 0);
        deposit.startFinalPayTimestamp = uint32(block.timestamp + days_ * INTERVAL);
        deposit.endFinalPayTimestamp = uint32(block.timestamp + (days_ + 2) * INTERVAL);
        deposit.status = 10;

        preTotal += deposit.finalAmount;
        brokers[msg.sender].depositTotal += preAmount;
        brokers[msg.sender].depositCurrent += preAmount;
        brokers[msg.sender].bonusMax += preAmount * 3;
        brokers[msg.sender].profitAmount -= int256(preAmount);
        depositAmountDays[today()] += amount;
        flowInTotal += preAmount;
        IERC20(usdt).safeTransferFrom(msg.sender, address(this), preAmount);
        allocAmount(preAmount, amount);
    }

    function finalDeposit(uint256 idx) external nonReentrant {
        _lossClaim(msg.sender);
        require(!restartStatus, "BankLink: system on restart status");
        Deposit storage deposit = deposits[msg.sender][idx];
        require(deposit.status == 10, "BankLink: deposit status error.");
        require(block.timestamp >= deposit.startFinalPayTimestamp, "BankLink: deposit not allow final pay.");
        require(block.timestamp < deposit.endFinalPayTimestamp, "BankLink: deposit is overtime.");

        uint256 finalAmount = deposit.finalAmount;
        deposit.status = 20;

        uint256 days_ = iRandom.withdrawDays(depositWithdrawRate());
        deposit.drawableTimestamp = uint32(block.timestamp + days_ * INTERVAL);
        preTotal -= finalAmount;
        withdrawTotal += deposit.withdrawAmount;
        brokers[msg.sender].depositTotal += finalAmount;
        brokers[msg.sender].depositCurrent += finalAmount;
        brokers[msg.sender].bonusMax += finalAmount * 3;
        brokers[msg.sender].profitAmount -= int256(finalAmount); 
        flowInTotal += finalAmount;
        IERC20(usdt).safeTransferFrom(msg.sender, address(this), finalAmount);
        allocAmount(finalAmount, deposit.amount);
    }

    function withdraw(uint256 idx) external nonReentrant {
        _lossClaim(msg.sender);
        require(!restartStatus, "BankLink: system on restart status");
        require(!checkBlacklist(msg.sender), "BankLink: you are in blacklist");
        Deposit memory deposit = deposits[msg.sender][idx];
        require(deposit.status == 20 || deposit.status == 50, "BankLink: deposit can`t withdraw");
        require(deposit.drawableTimestamp <= block.timestamp, "BankLink: withdraw time have not yet.");
        uint256 fuelAmount = deposit.withdrawAmount / 100;
        withdrawTotal -= deposit.withdrawAmount;
        depositTotal -= deposit.withdrawAmount;
        brokers[msg.sender].depositCurrent -= deposit.amount;
        brokers[msg.sender].profitAmount += int256(deposit.withdrawAmount);
        if (deposit.status == 50) {
            restartSubmitTimes -= 1;
        }
        deposits[msg.sender][idx].status = 30;
        burnGas(fuelAmount);
        IERC20(usdt).safeTransfer(msg.sender, deposit.withdrawAmount);
    }

    function allocAmount(uint256 alloc, uint256 amount) private {
        uint256 brokerAmount = (alloc * 16) / 100;
        sprintBalance += (alloc * 4) / 1000;
        restartBalance += (alloc * 5) / 1000;
        depositTotal += (alloc * 795) / 1000;
        fomoBalance += (alloc * 1) / 1000;
        processBonus(msg.sender, brokerAmount);
        processFomo(msg.sender, amount);
        processSprint(msg.sender);
        burnBlc((alloc * 3) / 100);
        IERC20(usdt).safeIncreaseAllowance(gasStake, (alloc * 5) / 1000);
        IGasStake(gasStake).recharge((alloc * 5) / 1000);
    }

    function processBonus(address addr, uint256 amount) private {
        uint8 level = 0;
        uint256 _amount = amount;
        for (uint256 i = 0; i < 30; i++) {
            address parent = iAccount.parent(addr);
            if (parent == address(0)) {
                break;
            }
            uint8 parentLevel = iAccount.level(parent);
            if (parentLevel == level && level == 5) {
                uint256 bonus = verifyBonus(parent, _amount, topBonusPercent);
                amount -= bonus;
                break;
            } else if (bonusPercents[parentLevel] > bonusPercents[level]) {
                uint8 diffPercent = bonusPercents[parentLevel] - bonusPercents[level];
                uint256 bonus = verifyBonus(parent, _amount, diffPercent);
                amount -= bonus;
                level = parentLevel;
            }
            addr = parent;
        }
        if (amount > 0) {
            depositTotal += amount;
        }
    }

    function verifyBonus(
        address addr,
        uint256 amount,
        uint8 bonusPercent
    ) private returns (uint256) {
        if (versions[versionTimes] != brokers[addr].currentVersion) {
            return 0;
        }
        if (brokers[addr].depositCurrent < amount) {
            amount = brokers[addr].depositCurrent;
        }
        uint256 bonus = (amount * bonusPercent) / 16;
        brokers[addr].bonusCalc += bonus;
        return bonus;
    }

    function bonusWithdraw() external nonReentrant {
        require(brokers[msg.sender].depositCurrent > 0, "you current deposit is empty.");
        require(!checkBlacklist(msg.sender), "BankLink: you are in blacklist");
        uint256 amount = bonusDrawable(msg.sender);
        if (amount > 0) {
            brokers[msg.sender].bonusMax -= amount;
            brokers[msg.sender].bonusDrawed += amount;
            brokers[msg.sender].profitAmount += int256(amount);
        }
        if (amount > 0) {
            burnGas(amount / 100);
            IERC20(usdt).safeTransfer(msg.sender, amount);
        }
    }

    function bonusDrawable(address addr) public view returns (uint256 amount) {
        if (brokers[addr].bonusMax > 0 && brokers[addr].bonusCalc > brokers[addr].bonusDrawed) {
            amount = brokers[addr].bonusCalc - brokers[addr].bonusDrawed;
            if (amount > brokers[addr].bonusMax) {
                amount = brokers[addr].bonusMax;
            }
        }
    }

    function checkBlacklist(address addr) public view returns (bool result) {
        Deposit[] storage deposits_ = deposits[addr];
        for (uint256 i = 0; i < deposits_.length; i++) {
            if (deposits_[i].status == 10 && block.timestamp > deposits_[i].endFinalPayTimestamp) {
                return true;
            }
        }
    }

    function dealBlacklist(uint256 index) external nonReentrant {
        Deposit storage deposit = deposits[msg.sender][index];
        require(deposit.status == 10, "deposit status error.");
        require(block.timestamp > deposit.endFinalPayTimestamp, "deposit have no overtime");
        brokers[msg.sender].punishTimes += 1;
        require(block.timestamp >= deposit.endFinalPayTimestamp + 7 * INTERVAL * brokers[msg.sender].punishTimes, "deposit in punish time");
        deposit.status = 40;
        burnGas(100e18 * brokers[msg.sender].punishTimes);
    }

    function depositList(address addr, uint256 offset, uint256 size) external view returns (Deposit[] memory results, uint256 total) {
        total = deposits[addr].length;
        if (offset + size > total) {
            size = total - offset;
        }
        results = new Deposit[](size);
        for (uint256 i = 0; i < size; i++) {
            results[i] = deposits[addr][i + offset];
        }
    }

    function depositWithdrawRate() private view returns (uint256) {
        if (withdrawTotal != 0) {
            return ((depositTotal + preTotal) * 100) / withdrawTotal;
        } else {
            return 10000;
        }
    }

    uint256 public fomoStartBalance = 500e18;
    uint256 public fomoCalcAmount = 1000e18;
    uint256 public fomoWaitingSeconds = 120;

    uint256 public fomoBalance;
    address public fomoCurrentAccount;
    uint256 public fomoEndTimestamp;
    mapping(address => uint256) public fomoDrawables;

    function fomoInit(uint256 startBalance, uint256 calcAmount, uint256 waitingSeconds) external onlyRole(OPERATOR_ROLE) {
        fomoStartBalance = startBalance;
        fomoCalcAmount = calcAmount;
        fomoWaitingSeconds = waitingSeconds;
    }

    function processFomo(address addr, uint256 amount) private {
        if (fomoBalance >= fomoStartBalance && block.timestamp >= fomoEndTimestamp) {
            fomoDrawables[fomoCurrentAccount] += fomoBalance;
            fomoBalance = 0;
        }
        if (amount >= fomoCalcAmount) {
            fomoCurrentAccount = addr;
            fomoEndTimestamp = block.timestamp + fomoWaitingSeconds;
        }
    }

    function fomoWithdraw() external nonReentrant {
        require(!checkBlacklist(msg.sender), "BankLink: you are in blacklist.");
        uint256 drawable = fomoDrawables[msg.sender];
        require(drawable > 0, "BankLink: insufficient of fomo drawable.");
        brokers[msg.sender].profitAmount += int256(drawable);
        fomoDrawables[msg.sender] = 0;
        burnGas(drawable / 100);
        IERC20(usdt).safeTransfer(msg.sender, drawable);
    }

    uint256 public sprintMin = 1000e18;
    uint256 public sprintBalance;
    DoubleEndedQueue.AddressDeque private last100Accounts;
    mapping(address => bool) private isLast100Accounts;
    mapping(address => uint256) public sprintDrawables;

    function last100AccountList() external view returns (address[] memory) {
        address[] memory last100AccountList_ = new address[](last100Accounts.length());
        for (uint256 i = 0; i < last100Accounts.length(); i++) {
            last100AccountList_[i] = last100Accounts.at(i);
        }
        return last100AccountList_;
    }

    function sprintInit(uint256 min) external onlyRole(OPERATOR_ROLE) {
        sprintMin = min;
    }

    function processSprint(address addr) private {
        if (brokers[addr].depositTotal >= sprintMin) {
            if (!isLast100Accounts[addr]) {
                last100Accounts.pushBack(addr);
                isLast100Accounts[addr] = true;
            }
            if (last100Accounts.length() > 100) {
                delete isLast100Accounts[last100Accounts.popFront()];
            }
        }
    }

    function sprintWithdraw() external nonReentrant {
        require(!checkBlacklist(msg.sender), "BankLink: you are in blacklist.");
        uint256 drawable = sprintDrawables[msg.sender];
        require(drawable > 0, "BankLink: insufficient of sprint drawable.");
        sprintDrawables[msg.sender] = 0;
        burnGas(drawable / 100);
        IERC20(usdt).safeTransfer(msg.sender, drawable);
    }

    uint256 public restartBalance;
    uint256 public restartTimes = 50;
    uint256 public restartRate = 9;
    uint256 public restartWaitingTime = 29;
    bool public restartStatus;
    uint256 public restartSubmitTimes;
    uint256 public restartUntil;

    struct Loss {
        uint256 amount;
        uint256 drawedAmount;
        uint32 withdrawEndTimestamp;
        uint32 lastWithdrawTimestamp;
    }

    mapping(address => mapping(uint32 => Loss)) public losses;

    function restartInit(uint256 times, uint256 rate, uint256 waitingTime) external onlyRole(OPERATOR_ROLE) {
        restartTimes = times;
        restartRate = rate;
        restartWaitingTime = waitingTime;
    }

    function restart(uint256 depositIndex) external {
        require(deposits[msg.sender][depositIndex].status == 20, "BankLink: deposit status error.");
        require(block.timestamp > deposits[msg.sender][depositIndex].createTimestamp + restartWaitingTime * INTERVAL, 
            "BankLink: this deposit not satisfy to restart.");
        require(withdrawTotal / depositTotal >= restartRate, "BankLink: bank no need to restart.");
        restartSubmitTimes += 1;
        if (restartSubmitTimes > restartTimes) {
            restartStatus = true;
            restartUntil = block.timestamp + 2 * INTERVAL;
            uint256 sprintBalanceEach = sprintBalance / last100Accounts.length();
            for (uint256 i = 0; i < last100Accounts.length(); i++) {
                sprintDrawables[last100Accounts.at(i)] += sprintBalanceEach;
                brokers[last100Accounts.at(i)].profitAmount += int256(sprintBalanceEach);
            }
            sprintBalance = 0;
            last100Accounts.clear();
            restartSubmitTimes = 0;
        }
        deposits[msg.sender][depositIndex].status = 50;
    }

    function start() external {
        require(restartStatus, "BankLink: not in restart status.");
        require(block.timestamp > restartUntil, "BankLink: in restart time.");
        restartStatus = false;
        versions.push(uint32(block.timestamp));
        versionTimes += 1;
        depositTotal += restartBalance;
        delete restartBalance;
        delete preTotal;
        delete withdrawTotal;
        delete fomoBalance;
        delete flowInTotal;
    }

    function lossClaim() external {
        _lossClaim(msg.sender);
    }

    function _lossClaim(address addr) private {
        if (versions[versionTimes] != brokers[addr].currentVersion) {
            if (brokers[addr].profitAmount < 0) {
                Loss storage lossCompensation = losses[addr][brokers[addr].currentVersion];
                lossCompensation.withdrawEndTimestamp = uint32(block.timestamp + 2000 * INTERVAL);
                lossCompensation.lastWithdrawTimestamp = uint32(block.timestamp);
                lossCompensation.amount = uint256(- brokers[addr].profitAmount);
            }
            delete brokers[addr];
            delete deposits[addr];
            delete isLast100Accounts[addr];
            iAccount.reset(addr, 0);
            brokers[addr].currentVersion = versions[versionTimes];
        }
    }

    function lossWithdraw(uint32 version) external nonReentrant {
        uint256 drawable = lossPending(msg.sender, version);
        require(drawable > 0, "Insufficient of lossCompensation");
        losses[msg.sender][version].drawedAmount += drawable;
        losses[msg.sender][version].lastWithdrawTimestamp = uint32(block.timestamp - (block.timestamp % INTERVAL));
        IERC20(gas).safeTransfer(msg.sender, drawable);
    }

    function lossPending(address addr, uint32 version) public view returns (uint256 drawable) {
        Loss storage loss = losses[addr][version];
        if (loss.amount != 0) {
            uint256 remainSecond = block.timestamp - loss.lastWithdrawTimestamp;
            if (loss.withdrawEndTimestamp < block.timestamp) {
                remainSecond = loss.withdrawEndTimestamp - loss.lastWithdrawTimestamp;
            }
            uint256 remainDays = remainSecond / INTERVAL;
            drawable = (remainDays * loss.amount) / 2000;
        }
    }

    uint256 public baseLmt = 10000e18; 

    function setDayLmt(uint256 base) external onlyRole(OPERATOR_ROLE) {
        baseLmt = base;
    }

    function depositRemainToday() public view returns (uint256) {
        uint32 travelDays = ((uint32(block.timestamp) - versions[versionTimes])) / INTERVAL; 
        if(travelDays > 90) {
            travelDays = 90;
        } 
        return baseLmt * (6 ** travelDays / 5 ** travelDays) - depositAmountDays[today()];
    }

    function today() public view returns (uint32) {
        return uint32(block.timestamp - (block.timestamp % INTERVAL));
    }

    function burnBlc(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(blc);
        IERC20(usdt).safeApprove(router, amount);
        uint256[] memory amounts = IUniswapV2Router01(router).swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp + 30);
        if(amounts[1] != 0){
            IGas(blc).burn(amounts[1]);
        }
    }

    function burnGas(uint256 amount) internal {
        IGas(gas).burnFrom(msg.sender, amount);
        gasCalcs[versions[versionTimes]] += amount;
    }
}