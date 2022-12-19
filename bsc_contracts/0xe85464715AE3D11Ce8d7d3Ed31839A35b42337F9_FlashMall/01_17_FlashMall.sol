// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IExt {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function deposit(
        address token,
        uint8 method,
        uint256 amount
    ) external returns (uint256 back);

    function accounts(address addr)
        external
        view
        returns (
            uint256 srd,
            uint256 srw,
            address head
        );
}

contract FlashMall is AccessControlUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint32 constant HOUR = 3600;
    uint16 constant UNIT = 10000;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    mapping(uint16 => uint32) public daysResRate;
    mapping(uint16 => uint32) public hoursResRate;

    uint16 public pointRate;
    address public musd;
    address public point;
    address public pointFeeReceiver;
    address public mai;
    address public exchangePool;
    address public dao;
    address public metabill;

    mapping(address => address) public parents;
    mapping(address => uint256) public contributes;
    mapping(address => uint32) public contributeLastTimes;
    mapping(address => uint256) public pointBalances;
    mapping(address => uint256) public tradeFlows;

    uint256 public memberPrice;
    mapping(address => bool) public members;
    mapping(address => bool) public merchants;
    mapping(address => uint16) public merchantDiscounts;
    mapping(address => uint8) public agentLevels;
    mapping(address => uint8) public majorLevels;

    uint256 public tradeMemberContributeLimit;
    uint16 public tradeContributeSelfRate;
    uint16 public tradeContributeDaoRate;
    uint16[] public tradeRewardRate;
    uint16[] public tradeMerchantRewardRate;
    uint16[] public agentLevelDiffRate;
    uint16[] public majorLevelDiffRate;

    uint16 public merchantDiscountMin;
    uint16 public merchantDiscountMax;

    event LogTrade(address from, address merchant, uint256 amount);
    event LogContributeChange(address addr, uint256 amount);

    function initialize() external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(OPERATOR_ROLE, _msgSender());
        _grantRole(ORACLE_ROLE, _msgSender());

        musd = 0x22a2C54b15287472F4aDBe7587226E3c998CdD96;
        point = 0x6a1462da7f1aE4a139120e27B4d18b1B4B99413f;
        pointFeeReceiver = 0x1Edd2F81acAa8163FB49E7692A24C7614ab0639C;
        mai = 0x35803e77c3163FEd8A942536C1c8e0d5bF90f906;
        exchangePool = 0x0663C4b19D139b9582539f6053a9C69a2bCEBC9f;
        dao = 0x4db314CFec6cb83150A18832815Ff0Bd17A62B22;
        metabill = 0x0a29702D828C3bd9bA20C8d0cD46Dfb853422E98;

        members[_msgSender()] = true;
        pointRate = 6950;
        memberPrice = 1000e18;
        tradeContributeSelfRate = 50000;
        tradeContributeDaoRate = 5000;
        tradeMemberContributeLimit = 1000;
        tradeRewardRate = [5000, 2500, 1250, 625, 313, 157];
        tradeMerchantRewardRate = [2500, 1250, 625, 313, 157, 79];
        agentLevelDiffRate = [0, 300, 600, 900, 1100, 1300, 1500];
        majorLevelDiffRate = [0, 150, 300, 500];
    }

    function register(address addr) external {
        require(parents[_msgSender()] == address(0), "Already registered");
        (, , address parent) = IExt(metabill).accounts(_msgSender());
        if (parent != address(0)) {
            addr = parent;
        }
        parents[_msgSender()] = addr;
    }

    function pointMint(uint256 amount) external {
        require(amount > 0, "zero amount");
        IExt(musd).burnFrom(_msgSender(), amount);
        uint256 pointAmount = (amount * pointRate) / 1000;
        IExt(point).mint(_msgSender(), pointAmount);
    }

    function pointBack(uint256 amount) external {
        require(amount > 0, "zero amount");
        IExt(point).burnFrom(_msgSender(), amount);
        uint256 musdAmount = (amount * 1000) / pointRate;
        IExt(musd).mint(_msgSender(), musdAmount);
    }

    function pointWithdraw(uint256 amount) external {
        processPointRelease(_msgSender());
        require(pointBalances[_msgSender()] >= amount, "Insufficient of point");
        IExt(point).mint(pointFeeReceiver, amount / 10);
        IExt(point).mint(_msgSender(), (amount * 9) / 10);
        pointBalances[_msgSender()] -= amount;
    }

    function pointToMai(uint256 amount) external {
        processPointRelease(_msgSender());
        require(pointBalances[_msgSender()] >= amount, "Insufficient of point");
        pointBalances[_msgSender()] -= amount;
        processPointToMai(_msgSender(), amount, 2);
    }

    function pointToMember() external {
        processPointRelease(_msgSender());
        require(pointBalances[_msgSender()] >= memberPrice, "Insufficient of point");
        pointBalances[_msgSender()] -= memberPrice;
        processBeMember(_msgSender());
    }

    function pointRelease() external {
        processPointRelease(_msgSender());
    }

    function pointReleasePending(address addr) public view returns (uint256 remainBalance, uint32 remainSecond) {
        if (contributeLastTimes[addr] != 0) {
            remainSecond = uint32(block.timestamp - contributeLastTimes[addr]);
            uint16 day = uint16(remainSecond / (24 * HOUR));
            if (daysResRate[day] == 0) {
                revert("Out of days range");
            }
            remainSecond = remainSecond % (24 * HOUR);
            remainBalance = (contributes[addr] * daysResRate[day] * hoursResRate[uint16(remainSecond / HOUR)]) / 1e18;
            remainSecond = remainSecond % HOUR;
        }
    }

    function buyMember() external {
        require(parents[_msgSender()] != address(0), "Not register");
        IExt(point).burnFrom(_msgSender(), memberPrice);
        processBeMember(_msgSender());
    }

    function setMerchantDiscount(uint8 discount) external {
        require(discount >= merchantDiscountMin && discount <= merchantDiscountMax, "Invail discount");
        merchantDiscounts[_msgSender()] = discount;
    }

    function trade(address merchant, uint256 amount) external {
        require(_msgSender() != merchant, "Not allow trade with self");
        require(parents[_msgSender()] != address(0), "Not register");
        require(merchants[merchant], "Not merchant");
        require(merchantDiscounts[merchant] != 0, "Merchant unregister");
        IExt(point).burnFrom(_msgSender(), amount);
        tradeFlows[_msgSender()] += amount;
        uint256 merchantContribute = (amount * merchantDiscounts[merchant]) / UNIT;
        uint256 merchantPoint = amount - merchantContribute;
        IExt(point).mint(merchant, merchantPoint);
        processPointToMai(_msgSender(), (merchantContribute * 2) / 10, 2);
        processContributeAdd(merchant, merchantContribute);
        processContributeAdd(_msgSender(), (merchantContribute * tradeContributeSelfRate) / UNIT);
        processContributeAdd(dao, (merchantContribute * tradeContributeDaoRate) / UNIT);
        tradeContributeReward(_msgSender(), merchant, merchantContribute);
        emit LogTrade(_msgSender(), merchant, amount);
    }

    function setAgentLevel(address agent, uint8 level) external onlyRole(ORACLE_ROLE) {
        require(level < 7, "Invail level");
        agentLevels[agent] = level;
    }

    function setMajorLevel(address major, uint8 level) external onlyRole(ORACLE_ROLE) {
        require(level < 4, "Invail level");
        majorLevels[major] = level;
    }

    function setMerchant(
        address merchant,
        bool result,
        uint16 discount
    ) external onlyRole(ORACLE_ROLE) {
        require(discount >= merchantDiscountMin && discount <= merchantDiscountMax, "Invail discount");
        merchants[merchant] = result;
        merchantDiscounts[merchant] = discount;
    }

    function setPointRate(uint16 rate) external onlyRole(ORACLE_ROLE) {
        require(rate >= 1_000 && rate <= 10_000);
        pointRate = rate;
    }

    function setBaseAddress(
        address newMusd,
        address newPoint,
        address newPointFeeReceiver,
        address newMai,
        address newExchangePool,
        address newDao,
        address newMetabill
    ) external onlyRole(OPERATOR_ROLE) {
        musd = newMusd;
        point = newPoint;
        pointFeeReceiver = newPointFeeReceiver;
        mai = newMai;
        exchangePool = newExchangePool;
        dao = newDao;
        metabill = newMetabill;
    }

    function setDaysResRate(uint16[] calldata idx, uint32[] calldata values) external onlyRole(OPERATOR_ROLE) {
        for (uint16 i = 0; i < idx.length; i++) {
            daysResRate[idx[i]] = values[i];
        }
    }

    function setHoursResRate(uint16[] calldata idx, uint32[] calldata values) external onlyRole(OPERATOR_ROLE) {
        for (uint16 i = 0; i < idx.length; i++) {
            hoursResRate[idx[i]] = values[i];
        }
    }

    function setMemberParam(uint256 price, uint256 limit) external onlyRole(OPERATOR_ROLE) {
        memberPrice = price;
        tradeMemberContributeLimit = limit;
    }

    function setTradeContributeSelfRate(uint16 rate) external onlyRole(OPERATOR_ROLE) {
        tradeContributeSelfRate = rate;
    }

    function setTradeContributeDaoRate(uint16 rate) external onlyRole(OPERATOR_ROLE) {
        tradeContributeDaoRate = rate;
    }

    function setTradeRewardRate(uint16 idx, uint16 rate) external onlyRole(OPERATOR_ROLE) {
        tradeRewardRate[idx] = rate;
    }

    function setMerchantTradeRewardRate(uint16 idx, uint16 rate) external onlyRole(OPERATOR_ROLE) {
        tradeMerchantRewardRate[idx] = rate;
    }

    function setAgentLevelDiffRate(uint16 idx, uint16 rate) external onlyRole(OPERATOR_ROLE) {
        agentLevelDiffRate[idx] = rate;
    }

    function setMajorLevelDiffRate(uint16 idx, uint16 rate) external onlyRole(OPERATOR_ROLE) {
        majorLevelDiffRate[idx] = rate;
    }

    function setMerchantDiscountLimit(uint16 min, uint16 max) external onlyRole(OPERATOR_ROLE) {
        require(min > 0 && max < 1_0000, "Invail discount");
        merchantDiscountMin = min;
        merchantDiscountMax = max;
    }

    function initUserBatch(address[] calldata addrs, address[] calldata parents_) external onlyRole(OPERATOR_ROLE) {
        for (uint256 i = 0; i < addrs.length; i++) {
            parents[addrs[i]] = parents_[i];
        }
    }

    function tradeContributeReward(
        address self,
        address merchant,
        uint256 merchantContribute
    ) private {
        uint16[] memory agentLevelDiffRateMemory = agentLevelDiffRate;
        uint16[] memory majorLevelDiffRateMemory = majorLevelDiffRate;
        uint8 currentMember = 0;
        uint8 currentAgentLevel = 0;
        uint8 currentMajorLevel = majorLevels[self];
        if (currentMajorLevel > 0) {
            processSpeedUp(self, (merchantContribute * majorLevelDiffRateMemory[currentMajorLevel]) / UNIT);
        }
        address parent = parents[self];
        for (uint8 i = 0; i < 50; i++) {
            if (currentMember < 6 && contributes[parent] >= tradeMemberContributeLimit) {
                processContributeAdd(parent, (merchantContribute * tradeRewardRate[currentMember]) / UNIT);
                currentMember += 1;
            }
            if (currentAgentLevel < 6 && agentLevels[parent] > currentAgentLevel) {
                uint16 diff = agentLevelDiffRateMemory[agentLevels[parent]] - agentLevelDiffRateMemory[currentAgentLevel];
                currentAgentLevel = agentLevels[parent];
                uint256 speedUpAmount = (merchantContribute * diff) / UNIT;
                processSpeedUp(parent, (speedUpAmount * 8) / 10);
                processManageReward(parent, currentAgentLevel, (speedUpAmount * 2) / 10);
            }
            if (currentMajorLevel < 3 && majorLevels[parent] > currentMajorLevel) {
                uint16 diff = majorLevelDiffRateMemory[majorLevels[parent]] - majorLevelDiffRateMemory[currentMajorLevel];
                currentMajorLevel = majorLevels[parent];
                processSpeedUp(parent, (merchantContribute * diff) / UNIT);
            }
            parent = parents[parent];
            if (parent == address(0)) {
                break;
            }
            if (currentMember > 5 && currentAgentLevel > 5 && currentMajorLevel > 2) {
                break;
            }
        }
        uint256 daoSpeedUpAmount = 0;
        if (currentAgentLevel < 6) {
            uint16 diff = agentLevelDiffRateMemory[6] - agentLevelDiffRateMemory[currentAgentLevel];
            daoSpeedUpAmount = (merchantContribute * diff) / UNIT;
        }
        if (currentMajorLevel < 3) {
            uint16 diff = majorLevelDiffRateMemory[3] - majorLevelDiffRateMemory[currentMajorLevel];
            daoSpeedUpAmount += (merchantContribute * diff) / UNIT;
        }
        processSpeedUp(dao, daoSpeedUpAmount);
        uint8 currentMerchant = 0;
        parent = parents[merchant];
        for (uint8 i = 0; i < 50; i++) {
            if (currentMerchant > 5) {
                break;
            }
            if (contributes[parent] > tradeMemberContributeLimit) {
                processContributeAdd(parent, (merchantContribute * tradeMerchantRewardRate[currentMerchant]) / UNIT);
                currentMerchant += 1;
            }
            parent = parents[parent];
            if (parent == address(0)) {
                break;
            }
        }
    }

    function processPointRelease(address addr) private {
        (uint256 remainBalance, uint32 remainSecond) = pointReleasePending(addr);
        pointBalances[addr] += contributes[addr] - remainBalance;
        contributes[addr] = remainBalance;
        contributeLastTimes[addr] = uint32(block.timestamp - remainSecond);
        emit LogContributeChange(addr, remainBalance);
    }

    function processPointToMai(
        address addr,
        uint256 amount,
        uint8 method
    ) private {
        uint256 musdAmount = (amount * 1000) / pointRate;
        IExt(musd).mint(address(this), musdAmount);
        IERC20Upgradeable(musd).safeApprove(exchangePool, musdAmount);
        uint256 maiAmount = IExt(exchangePool).deposit(musd, method, musdAmount);
        IERC20Upgradeable(mai).transfer(addr, maiAmount);
    }

    function processBeMember(address addr) private {
        require(!members[addr], "Already is member");
        processPointToMai(addr, memberPrice / 5, 1);
        processContributeAdd(addr, (memberPrice * 12) / 10);
        processSpeedUp(parents[addr], (memberPrice * 3) / 10);
        members[addr] = true;
    }

    function processContributeAdd(address addr, uint256 amount) private {
        processPointRelease(addr);
        contributes[addr] += amount;
        emit LogContributeChange(addr, contributes[addr]);
    }

    function processSpeedUp(address addr, uint256 amount) private {
        if (addr != address(0) && amount != 0) {
            processPointRelease(addr);
            if (contributes[addr] < amount) {
                amount = contributes[addr];
            }
            contributes[addr] -= amount;
            pointBalances[addr] += amount;
            emit LogContributeChange(addr, contributes[addr]);
        }
    }

    function processManageReward(
        address addr,
        uint8 currentLevel,
        uint256 amount
    ) private {
        for (uint8 i = 0; i < 3; i++) {
            addr = parents[addr];
            if (addr == address(0)) {
                break;
            }
            if (agentLevels[addr] == currentLevel) {
                processSpeedUp(addr, amount);
                break;
            }
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}