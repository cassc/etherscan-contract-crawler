// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

interface IMUSD {
    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

interface ITreasury {
    function recharge(uint256 amount) external;
}

interface IPriceOracle {
    function getPrice(address token) external view returns (uint256);
}

contract LendingPool is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant MUSD = 0x22a2C54b15287472F4aDBe7587226E3c998CdD96;
    uint256 public constant ONE_DAY = 24 * 3600;
    address public priceOracle;
    address public treasury;
    uint256 private _loanId;
    uint16 public interestPercent;
    uint16[] public interestAllocRates;
    address[] public interestAllocAddrs;
    EnumerableSetUpgradeable.AddressSet collateralTokens;

    struct PoolInfo {
        uint256 duration;
        uint16 interestRate;
        uint16 penaltyRate;
    }

    PoolInfo[] public poolInfo;

    struct LoanData {
        uint256 pid;
        uint256 loanAmount;
        uint256 collateralAmount;
        uint256 dueTime;
        uint8 status;
        address collateralToken;
        address borrower;
    }
    mapping(uint256 => LoanData) public loans;
    mapping(address => EnumerableSetUpgradeable.UintSet) loanIds;
    mapping(address => uint16) public tokenCollateralRates;
    mapping(address => uint16) public tokenLiquidateRates;
    mapping(address => mapping(address => uint16)) addrCollateralRates;
    mapping(address => uint256) public liquidatedAmounts;

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);

        //init variable
        interestPercent = 1000;
        treasury = 0xD00812c7B8b85f7111012607205BB35F91AB0B6d;
        priceOracle = 0x7Bd361b08f03C6f71b153957ED69900Bbe2C9456;
    }

    function addCollateralToken(
        address token,
        uint16 collateralRate,
        uint16 liquidateRate
    ) external onlyRole(OPERATOR_ROLE) {
        require(collateralTokens.add(token), "duplicate add token");
        tokenCollateralRates[token] = collateralRate;
        tokenLiquidateRates[token] = liquidateRate;
    }

    function setTokenRates(
        address token,
        uint16 collateralRate,
        uint16 liquidateRate
    ) external onlyRole(OPERATOR_ROLE) {
        require(collateralTokens.contains(token), "invalid token");
        tokenCollateralRates[token] = collateralRate;
        tokenLiquidateRates[token] = liquidateRate;
    }

    function setAddrCollateralRate(
        address addr,
        address token,
        uint16 collateralRate
    ) external onlyRole(OPERATOR_ROLE) {
        addrCollateralRates[addr][token] = collateralRate;
    }

    function setPriceOracle(address _priceOracle) external onlyRole(OPERATOR_ROLE) {
        priceOracle = _priceOracle;
    }

    function setInterestAllocRates(address[] calldata addrs, uint16[] calldata rates) external onlyRole(OPERATOR_ROLE) {
        require(addrs.length == rates.length, "data error");
        interestAllocAddrs = addrs;
        interestAllocRates = rates;
    }

    function setInterestPercent(uint16 _interestPercent) external onlyRole(OPERATOR_ROLE) {
        interestPercent = _interestPercent;
    }

    function addPool(
        uint256 duration,
        uint16 interestRate,
        uint16 penaltyRate
    ) external onlyRole(OPERATOR_ROLE) {
        poolInfo.push(PoolInfo({duration: duration, interestRate: interestRate, penaltyRate: penaltyRate}));
    }

    function updatePool(
        uint256 pid,
        uint16 interestRate,
        uint16 penaltyRate
    ) external onlyRole(OPERATOR_ROLE) {
        PoolInfo storage pool = poolInfo[pid];
        pool.interestRate = interestRate;
        pool.penaltyRate = penaltyRate;
    }

    function setTreasury(address _treasury) external onlyRole(OPERATOR_ROLE) {
        treasury = _treasury;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "invalid amount");
        IERC20Upgradeable(USDT).safeTransferFrom(msg.sender, address(this), amount);
        IMUSD(MUSD).mint(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "invalid amount");
        require(amount <= IERC20Upgradeable(USDT).balanceOf(address(this)), "exceed pool balance");
        IMUSD(MUSD).burnFrom(msg.sender, amount);
        IERC20Upgradeable(USDT).safeTransfer(msg.sender, amount);
    }

    function borrow(
        uint256 pid,
        address collateralToken,
        uint256 loanAmount
    ) external {
        require(loanAmount > 0, "invalid amount");
        require(collateralTokens.contains(collateralToken), "unsupported collateral token");
        require(poolInfo[pid].duration > 0, "invalid lending pool");
        uint256 tokenPrice = IPriceOracle(priceOracle).getPrice(collateralToken);
        require(tokenPrice > 0, "unsupported zero price token");
        uint16 collateralRate = getCollateralRate(msg.sender, collateralToken);
        require(collateralRate > 0, "unsupported collateral token");
        uint256 collateralAmount = (loanAmount * collateralRate * 1e18) / (tokenPrice * 1000);
        uint256 interestAmount = (loanAmount * poolInfo[pid].interestRate) / 1e5;
        uint256 loanId = _loanId;
        loans[loanId] = LoanData({
            pid: pid,
            loanAmount: loanAmount,
            collateralAmount: collateralAmount,
            dueTime: block.timestamp + poolInfo[pid].duration,
            status: 0,
            collateralToken: collateralToken,
            borrower: msg.sender
        });
        loanIds[msg.sender].add(loanId);
        _loanId++;
        IERC20Upgradeable(collateralToken).safeTransferFrom(msg.sender, address(this), collateralAmount);
        IMUSD(MUSD).mint(address(this), loanAmount);
        IERC20Upgradeable(MUSD).safeTransfer(msg.sender, loanAmount - interestAmount);
        allocInterest(interestAmount);
    }

    function allocInterest(uint256 amount) internal {
        uint256 treasuryAmount = (amount * interestPercent) / 1000;
        IERC20Upgradeable(MUSD).safeApprove(treasury, treasuryAmount);
        ITreasury(treasury).recharge(treasuryAmount);
        uint256 allocAmount = amount - treasuryAmount;
        for (uint256 i = 0; i < interestAllocRates.length; i++) {
            IERC20Upgradeable(MUSD).safeTransfer(interestAllocAddrs[i], (allocAmount * interestAllocRates[i]) / 1000);
        }
    }

    function repay(uint256 loanId) external {
        require(loanIds[msg.sender].contains(loanId), "invalid loan id");
        LoanData storage data = loans[loanId];
        require(data.status == 0, "loan is liquidated or repaid");
        uint256 penaltyAmount = getPenaltyAmount(data.loanAmount, data.dueTime, block.timestamp, poolInfo[data.pid].penaltyRate);
        IMUSD(MUSD).burnFrom(msg.sender, data.loanAmount);
        IERC20Upgradeable(data.collateralToken).safeTransfer(msg.sender, data.collateralAmount);
        if (penaltyAmount > 0) {
            IERC20Upgradeable(MUSD).safeTransferFrom(msg.sender, address(this), penaltyAmount);
            allocInterest(penaltyAmount);
        }
        data.status = 1;
        loanIds[msg.sender].remove(loanId);
    }

    function getPenaltyAmount(
        uint256 loanAmount,
        uint256 dueTime,
        uint256 timestamp,
        uint16 penaltyRate
    ) public pure returns (uint256 penaltyAmount) {
        if (timestamp > dueTime) {
            penaltyAmount = (loanAmount * penaltyRate * (timestamp - dueTime)) / (ONE_DAY * 1e5);
        }
    }

    function getCollateralRate(address addr, address token) public view returns (uint16 collateralRate) {
        collateralRate = addrCollateralRates[addr][token];
        if (collateralRate == 0) {
            collateralRate = tokenCollateralRates[token];
        }
    }

    function liquidate(uint256 loanId) external onlyRole(LIQUIDATOR_ROLE) {
        LoanData storage data = loans[loanId];
        require(data.status == 0, "loan is liquidated or repaid");
        require(data.loanAmount > 0, "invalid loan");
        uint256 dueTime = data.dueTime;
        address collateralToken = data.collateralToken;
        uint256 tokenPrice = IPriceOracle(priceOracle).getPrice(collateralToken);
        uint256 penaltyAmount = getPenaltyAmount(data.loanAmount, dueTime, block.timestamp, poolInfo[data.pid].penaltyRate);
        uint256 collateralAmount = data.collateralAmount;
        uint16 collateralRate = getCollateralRate(data.borrower, collateralToken);
        require(
            (collateralAmount * tokenPrice * (tokenLiquidateRates[collateralToken] / 1000)) <
                1e18 * ((data.loanAmount * collateralRate) / 1000 + penaltyAmount),
            "liquidate value limited"
        );
        data.status = 2;
        liquidatedAmounts[collateralToken] += collateralAmount;
    }

    function allocLiquidatedToken(
        address token,
        address addr,
        uint256 amount
    ) external onlyRole(LIQUIDATOR_ROLE) {
        require(amount <= liquidatedAmounts[token], "exceed liquidated amount");
        liquidatedAmounts[token] -= amount;
        IERC20Upgradeable(token).safeTransfer(addr, amount);
    }

    function rollover(uint256 loanId) external {
        require(loanIds[msg.sender].contains(loanId), "invalid loan id");
        LoanData storage data = loans[loanId];
        uint256 loanAmount = data.loanAmount;
        require(loanAmount > 0, "invalid loan");
        require(data.status == 0, "loan is liquidated or repaid");

        uint256 pid = data.pid;
        uint256 penaltyAmount = getPenaltyAmount(loanAmount, data.dueTime, block.timestamp, poolInfo[pid].penaltyRate);
        uint256 interestAmount = (loanAmount * poolInfo[pid].interestRate) / 1e5;
        IERC20Upgradeable(MUSD).safeTransferFrom(msg.sender, address(this), interestAmount + penaltyAmount);
        allocInterest(interestAmount + penaltyAmount);
        data.dueTime += poolInfo[pid].duration;
    }

    function removeLiquidateLoan(uint256 loanId) external {
        require(loanIds[msg.sender].contains(loanId), "invalid loan id");
        require(loans[loanId].status == 2, "loan is not liquidated");
        loanIds[msg.sender].remove(loanId);
    }

    function getLoanIds(address addr) public view returns (uint256[] memory) {
        return loanIds[addr].values();
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function getCollateralTokens() public view returns (address[] memory) {
        return collateralTokens.values();
    }
}