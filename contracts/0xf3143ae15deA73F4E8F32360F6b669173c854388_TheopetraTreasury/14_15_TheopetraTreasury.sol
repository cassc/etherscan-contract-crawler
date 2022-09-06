// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "../Libraries/SafeMath.sol";
import "../Libraries/SafeERC20.sol";
import "../Libraries/SignedSafeMath.sol";
import "../Libraries/SafeCast.sol";

import "../Interfaces/IERC20.sol";
import "../Interfaces/IERC20Metadata.sol";
import "../Interfaces/ITHEO.sol";
import "../Interfaces/ITokenDebt.sol";
import "../Interfaces/IBondCalculator.sol";
import "../Interfaces/ITreasury.sol";
import "../Interfaces/IYieldReporter.sol";
import "../Interfaces/IBondDepository.sol";

import "../Types/TheopetraAccessControlled.sol";

contract TheopetraTreasury is TheopetraAccessControlled, ITreasury {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeCast for uint256;
    using SignedSafeMath for int256;
    using SafeERC20 for IERC20;

    /* ========== EVENTS ========== */

    event Deposit(address indexed token, uint256 amount, uint256 value);
    event Withdrawal(address indexed token, uint256 amount, uint256 value);
    event CreateDebt(address indexed debtor, address indexed token, uint256 amount, uint256 value);
    event RepayDebt(address indexed debtor, address indexed token, uint256 amount, uint256 value);
    event Managed(address indexed token, uint256 amount);
    event ReservesAudited(uint256 indexed totalReserves);
    event Minted(address indexed caller, address indexed recipient, uint256 amount);
    event PermissionQueued(STATUS indexed status, address queued);
    event Permissioned(address addr, STATUS indexed status, bool result);
    event BondCalculatorUpdated(address addr);
    event DebtLimitUpdated(address addr, uint256 limit);
    event TimelockUpdated(bool enabled);

    /* ========== DATA STRUCTURES ========== */

    enum STATUS {
        RESERVEDEPOSITOR,
        RESERVESPENDER,
        RESERVETOKEN,
        RESERVEMANAGER,
        LIQUIDITYDEPOSITOR,
        LIQUIDITYTOKEN,
        LIQUIDITYMANAGER,
        RESERVEDEBTOR,
        REWARDMANAGER,
        STHEO,
        THEODEBTOR,
        YIELDREPORTER
    }

    struct Queue {
        STATUS managing;
        address toPermit;
        address calculator;
        uint256 timelockEnd;
        bool nullify;
        bool executed;
    }

    struct PriceInfo {
        int256 deltaTreasuryYield;
        uint256 timeLastUpdated;
        uint256 lastTokenPrice;
        uint256 currentTokenPrice;
    }

    /* ========== STATE VARIABLES ========== */

    ITHEO public immutable THEO;
    ITokenDebt public sTHEO;
    IYieldReporter private yieldReporter;
    IBondCalculator private theoBondingCalculator;

    mapping(STATUS => address[]) public registry;
    mapping(STATUS => mapping(address => bool)) public permissions;
    mapping(address => address) public bondCalculator;

    mapping(address => uint256) public debtLimit;

    uint256 public totalReserves;
    uint256 public totalDebt;
    uint256 public theoDebt;
    Queue[] public permissionQueue;
    uint256 public immutable blocksNeededForQueue;

    PriceInfo private priceInfo;

    bool public timelockEnabled;
    bool public initialized;

    uint256 public onChainGovernanceTimelock;
    bytes32 public constant BOND_ROLE = keccak256("BOND_ROLE");

    string internal constant notAccepted = "Treasury: not accepted";
    string internal constant notApproved = "Treasury: not approved";
    string internal constant invalidToken = "Treasury: invalid token";

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _theo,
        uint256 _timelock,
        address _authority
    ) TheopetraAccessControlled(ITheopetraAuthority(_authority)) {
        require(_theo != address(0), "Zero address: THEO");
        THEO = ITHEO(_theo);

        timelockEnabled = false;
        initialized = false;
        blocksNeededForQueue = _timelock;
        priceInfo.timeLastUpdated = block.timestamp;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice allow approved address to deposit an asset for THEO
     * @param _amount uint256
     * @param _token address
     * @param _profit uint256
     * @return send_ uint256
     */
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external override returns (uint256 send_) {
        if (permissions[STATUS.RESERVETOKEN][_token]) {
            require(permissions[STATUS.RESERVEDEPOSITOR][msg.sender], notApproved);
        } else if (permissions[STATUS.LIQUIDITYTOKEN][_token]) {
            require(permissions[STATUS.LIQUIDITYDEPOSITOR][msg.sender], notApproved);
        } else {
            revert(invalidToken);
        }

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 value = tokenValue(_token, _amount);
        // mint THEO needed and store amount of rewards for distribution
        send_ = value.sub(_profit);
        THEO.mint(msg.sender, send_);

        totalReserves = totalReserves.add(value);

        emit Deposit(_token, _amount, value);
    }

    /**
     * @notice allow approved address to burn THEO for reserves
     * @param _amount uint256
     * @param _token address
     */
    function withdraw(uint256 _amount, address _token) external override {
        require(permissions[STATUS.RESERVETOKEN][_token], notAccepted); // Only reserves can be used for redemptions
        require(permissions[STATUS.RESERVESPENDER][msg.sender], notApproved);

        uint256 value = tokenValue(_token, _amount);
        THEO.burnFrom(msg.sender, value);

        totalReserves = totalReserves.sub(value);

        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit Withdrawal(_token, _amount, value);
    }

    /**
     * @notice allow approved address to withdraw assets
     * @param _token address
     * @param _amount uint256
     */
    function manage(address _token, uint256 _amount) external override {
        if (permissions[STATUS.LIQUIDITYTOKEN][_token]) {
            require(permissions[STATUS.LIQUIDITYMANAGER][msg.sender], notApproved);
        } else {
            require(permissions[STATUS.RESERVEMANAGER][msg.sender], notApproved);
        }
        if (permissions[STATUS.RESERVETOKEN][_token] || permissions[STATUS.LIQUIDITYTOKEN][_token]) {
            uint256 value = tokenValue(_token, _amount);
            totalReserves = totalReserves.sub(value);
        }
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit Managed(_token, _amount);
    }

    /**
     * @notice mint new THEO using excess reserves
     * @param _recipient address
     * @param _amount uint256
     */
    function mint(address _recipient, uint256 _amount) external override {
        require(permissions[STATUS.REWARDMANAGER][msg.sender], "Caller is not a Reward manager");

        THEO.mint(_recipient, _amount);
        emit Minted(msg.sender, _recipient, _amount);
    }

    /**
     * DEBT: The debt functions allow approved addresses to borrow treasury assets
     * or THEO from the treasury, using stheo as collateral. This might allow an
     * sTHEO holder to provide theo liquidity without taking on the opportunity cost
     * of unstaking, or alter their backing without imposing risk onto the treasury.
     * Many of these use cases are yet to be defined, but they appear promising.
     * However, we urge the community to think critically and move slowly upon
     * proposals to acquire these permissions.
     */

    /**
     * @notice allow approved address to borrow reserves
     * @param _amount uint256
     * @param _token address
     */
    function incurDebt(uint256 _amount, address _token) external override {
        uint256 value;
        if (_token == address(THEO)) {
            require(permissions[STATUS.THEODEBTOR][msg.sender], notApproved);
            value = _amount;
        } else {
            require(permissions[STATUS.RESERVEDEBTOR][msg.sender], notApproved);
            require(permissions[STATUS.RESERVETOKEN][_token], notAccepted);
            value = tokenValue(_token, _amount);
        }
        require(value != 0, invalidToken);

        sTHEO.changeDebt(value, msg.sender, true);
        require(sTHEO.debtBalances(msg.sender) <= debtLimit[msg.sender], "Treasury: exceeds limit");
        totalDebt = totalDebt.add(value);

        if (_token == address(THEO)) {
            THEO.mint(msg.sender, value);
            theoDebt = theoDebt.add(value);
        } else {
            totalReserves = totalReserves.sub(value);
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
        emit CreateDebt(msg.sender, _token, _amount, value);
    }

    /**
     * @notice allow approved address to repay borrowed reserves with reserves
     * @param _amount uint256
     * @param _token address
     */
    function repayDebtWithReserve(uint256 _amount, address _token) external override {
        require(permissions[STATUS.RESERVEDEBTOR][msg.sender], notApproved);
        require(permissions[STATUS.RESERVETOKEN][_token], notAccepted);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 value = tokenValue(_token, _amount);
        sTHEO.changeDebt(value, msg.sender, false);
        totalDebt = totalDebt.sub(value);
        totalReserves = totalReserves.add(value);
        emit RepayDebt(msg.sender, _token, _amount, value);
    }

    /**
     * @notice allow approved address to repay borrowed reserves with THEO
     * @param _amount uint256
     */
    function repayDebtWithTHEO(uint256 _amount) external {
        require(
            permissions[STATUS.RESERVEDEBTOR][msg.sender] || permissions[STATUS.THEODEBTOR][msg.sender],
            notApproved
        );
        THEO.burnFrom(msg.sender, _amount);
        sTHEO.changeDebt(_amount, msg.sender, false);
        totalDebt = totalDebt.sub(_amount);
        theoDebt = theoDebt.sub(_amount);
        emit RepayDebt(msg.sender, address(THEO), _amount, _amount);
    }

    /* ======== BONDING CALCULATOR ======== */

    /**
     * @notice                  get the address of the theo bonding calculator
     * @return                  address for theo liquidity pool
     */
    function getTheoBondingCalculator() public view override returns (IBondCalculator) {
        return IBondCalculator(theoBondingCalculator);
    }

    /**
     * @notice             set the address for the theo bonding calculator
     * @param _theoBondingCalculator    address of the theo bonding calculator
     */
    function setTheoBondingCalculator(address _theoBondingCalculator) external override onlyGuardian {
        theoBondingCalculator = IBondCalculator(_theoBondingCalculator);
        emit BondCalculatorUpdated(_theoBondingCalculator);
    }

    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
     * @notice takes inventory of all tracked assets
     * @notice always consolidate to recognized reserves before audit
     */
    function auditReserves() external onlyGovernor {
        uint256 reserves;
        address[] memory reserveToken = registry[STATUS.RESERVETOKEN];
        for (uint256 i = 0; i < reserveToken.length; i++) {
            if (permissions[STATUS.RESERVETOKEN][reserveToken[i]]) {
                reserves = reserves.add(tokenValue(reserveToken[i], IERC20(reserveToken[i]).balanceOf(address(this))));
            }
        }
        address[] memory liquidityToken = registry[STATUS.LIQUIDITYTOKEN];
        for (uint256 i = 0; i < liquidityToken.length; i++) {
            if (permissions[STATUS.LIQUIDITYTOKEN][liquidityToken[i]]) {
                reserves = reserves.add(
                    tokenValue(liquidityToken[i], IERC20(liquidityToken[i]).balanceOf(address(this)))
                );
            }
        }
        totalReserves = reserves;
        emit ReservesAudited(reserves);
    }

    /**
     * @notice set max debt for address
     * @param _address address
     * @param _limit uint256
     */
    function setDebtLimit(address _address, uint256 _limit) external onlyGovernor {
        debtLimit[_address] = _limit;
        emit DebtLimitUpdated(_address, _limit);
    }

    /**
     * @notice enable permission from queue
     * @param _status STATUS
     * @param _address address
     * @param _calculator address
     */
    function enable(
        STATUS _status,
        address _address,
        address _calculator
    ) external onlyGovernor {
        require(timelockEnabled == false, "Use queueTimelock");
        if (_status == STATUS.STHEO) {
            sTHEO = ITokenDebt(_address);
        } else if (_status == STATUS.YIELDREPORTER) {
            yieldReporter = IYieldReporter(_address);
        } else {
            permissions[_status][_address] = true;

            if (_status == STATUS.LIQUIDITYTOKEN) {
                bondCalculator[_address] = _calculator;
            }

            (bool registered, ) = indexInRegistry(_address, _status);
            if (!registered) {
                registry[_status].push(_address);

                if (_status == STATUS.LIQUIDITYTOKEN || _status == STATUS.RESERVETOKEN) {
                    (bool reg, uint256 index) = indexInRegistry(_address, _status);
                    if (reg) {
                        delete registry[_status][index];
                    }
                }
            }
        }
        emit Permissioned(_address, _status, true);
    }

    /**
     *  @notice disable permission from address
     *  @param _status STATUS
     *  @param _toDisable address
     */
    function disable(STATUS _status, address _toDisable) external {
        require(msg.sender == authority.governor() || msg.sender == authority.guardian(), "Only governor or guardian");
        permissions[_status][_toDisable] = false;
        emit Permissioned(_toDisable, _status, false);
    }

    /**
     * @notice check if registry contains address
     * @return (bool, uint256)
     */
    function indexInRegistry(address _address, STATUS _status) public view returns (bool, uint256) {
        address[] memory entries = registry[_status];
        for (uint256 i = 0; i < entries.length; i++) {
            if (_address == entries[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /**
     * @notice              update the current token price and previous (last) token price.
     *                      Token price is calculated with the theoBondingCalculator, as set by the Governor
     * @dev                 this method can be called at any time but will only update contract state every 8 hours
     */
    function tokenPerformanceUpdate() public override {
        if (block.timestamp >= priceInfo.timeLastUpdated + 28800) {
            priceInfo.lastTokenPrice = priceInfo.currentTokenPrice;
            priceInfo.currentTokenPrice = IBondCalculator(theoBondingCalculator).valuation(
                address(THEO),
                1_000_000_000
            );
            priceInfo.timeLastUpdated = block.timestamp;
        }
    }

    /* ========== TIMELOCKED FUNCTIONS ========== */

    // functions are used prior to enabling on-chain governance

    /**
     * @notice queue address to receive permission
     * @param _status STATUS
     * @param _address address
     * @param _calculator address
     */
    function queueTimelock(
        STATUS _status,
        address _address,
        address _calculator
    ) external onlyGovernor {
        require(_address != address(0), "Address cannot be the zero address");
        require(timelockEnabled == true, "Timelock is disabled, use enable");

        uint256 timelock = block.number.add(blocksNeededForQueue);
        if (_status == STATUS.RESERVEMANAGER || _status == STATUS.LIQUIDITYMANAGER) {
            timelock = block.number.add(blocksNeededForQueue.mul(2));
        }
        permissionQueue.push(
            Queue({
                managing: _status,
                toPermit: _address,
                calculator: _calculator,
                timelockEnd: timelock,
                nullify: false,
                executed: false
            })
        );
        emit PermissionQueued(_status, _address);
    }

    /**
     *  @notice enable queued permission
     *  @param _index uint256
     */
    function execute(uint256 _index) external {
        require(timelockEnabled == true, "Timelock is disabled, use enable");

        Queue memory info = permissionQueue[_index];

        require(!info.nullify, "Action has been nullified");
        require(!info.executed, "Action has already been executed");
        require(block.number >= info.timelockEnd, "Timelock not complete");

        if (info.managing == STATUS.STHEO) {
            // 9
            sTHEO = ITokenDebt(info.toPermit);
        } else if (info.managing == STATUS.YIELDREPORTER) {
            yieldReporter = IYieldReporter(info.toPermit);
        } else {
            permissions[info.managing][info.toPermit] = true;

            if (info.managing == STATUS.LIQUIDITYTOKEN) {
                bondCalculator[info.toPermit] = info.calculator;
            }
            (bool registered, ) = indexInRegistry(info.toPermit, info.managing);
            if (!registered) {
                registry[info.managing].push(info.toPermit);

                if (info.managing == STATUS.LIQUIDITYTOKEN) {
                    (bool reg, uint256 index) = indexInRegistry(info.toPermit, STATUS.RESERVETOKEN);
                    if (reg) {
                        delete registry[STATUS.RESERVETOKEN][index];
                    }
                } else if (info.managing == STATUS.RESERVETOKEN) {
                    (bool reg, uint256 index) = indexInRegistry(info.toPermit, STATUS.LIQUIDITYTOKEN);
                    if (reg) {
                        delete registry[STATUS.LIQUIDITYTOKEN][index];
                    }
                }
            }
        }
        permissionQueue[_index].executed = true;
        emit Permissioned(info.toPermit, info.managing, true);
    }

    /**
     * @notice cancel timelocked action
     * @param _index uint256
     */
    function nullify(uint256 _index) external onlyGovernor {
        permissionQueue[_index].nullify = true;
        emit Permissioned(permissionQueue[_index].toPermit, permissionQueue[_index].managing, false);
    }

    /**
     * @notice disables timelocked functions
     */
    function disableTimelock() external onlyGovernor {
        require(timelockEnabled == true, "timelock already disabled");
        if (onChainGovernanceTimelock != 0 && onChainGovernanceTimelock <= block.number) {
            timelockEnabled = false;
            TimelockUpdated(false);
        } else {
            onChainGovernanceTimelock = block.number.add(blocksNeededForQueue.mul(7)); // 7-day timelock
        }
    }

    /**
     * @notice enables timelocks after initilization
     */
    function initialize() external onlyGovernor {
        require(initialized == false, "Already initialized");
        timelockEnabled = true;
        initialized = true;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns THEO valuation for an amount of Quote Tokens
     * @param _token address
     * @param _amount uint256
     * @return value_ uint256
     */
    function tokenValue(address _token, uint256 _amount) public view override returns (uint256 value_) {
        value_ = _amount.mul(10**IERC20Metadata(address(THEO)).decimals()).div(10**IERC20Metadata(_token).decimals());

        if (permissions[STATUS.LIQUIDITYTOKEN][_token]) {
            value_ = IBondCalculator(bondCalculator[_token]).valuation(_token, _amount);
        }
    }

    /**
     * @notice returns supply metric that cannot be manipulated by debt
     * @dev use this any time you need to query supply
     * @return uint256
     */
    function baseSupply() external view override returns (uint256) {
        return THEO.totalSupply() - theoDebt;
    }

    /**
     * @notice  calculate the proportional change (i.e. a percentage as a decimal) in token price, with 9 decimals
     * @dev     calculated as (currentPrice - lastPrice) / lastPrice
     *           using 9 decimals for the price values and for return value.
     * @return  int256 proportional change in treasury yield. 9 decimals
     */
    function deltaTokenPrice() public view override returns (int256) {
        return
            ((priceInfo.currentTokenPrice.toInt256()).sub(priceInfo.lastTokenPrice.toInt256()) * 10**9).div(
                priceInfo.lastTokenPrice.toInt256()
            );
    }

    /**
     * @notice  calculate the proportional change (i.e. a percentage as a decimal) in treasury yield, with 9 decimals
     * @dev     calculated as (currentYield - lastYield) / lastYield
     *           using 9 decimals for the yield values and for return value.
     *           example: ((10_000_000_000 - 15_000_000_000)*(10**9)) / 15_000_000_000 = -333333333
     *           -333333333 is equivalent to the proportion -0.333333333 (that is, -33.3333333%)
     * @return  int256 proportional change in treasury yield. 9 decimals
     */
    function deltaTreasuryYield() public view override returns (int256) {
        require(address(yieldReporter) != address(0), "Zero address: YieldReporter");
        return
            (((IYieldReporter(yieldReporter).currentYield()).sub(IYieldReporter(yieldReporter).lastYield())) * 10**9)
                .div(IYieldReporter(yieldReporter).lastYield());
    }
}