// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../tokens/WaifuToken.sol";
import "../tokens/PreLaunchToken.sol";
import "../perks/WaifuPerks.sol";
import "../revenue/RevenueDistributor.sol";

/*
 * Used for processing WaifuNodes purchase payments and granting rewards to
 * WaifuNodes tokens owners.
 */
contract WaifuCashier is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for WaifuToken;
    using SafeERC20Upgradeable for PreLaunchToken;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ===== CONSTANTS ===== */

    // PAYMENT_MANAGER_ROLE should be granted to WaifuManager after deployment
    bytes32 public constant PAYMENT_MANAGER_ROLE =
        keccak256("PAYMENT_MANAGER_ROLE");
    // NODES_ROLE should be granted to WaifuNodes after deployment
    bytes32 public constant NODES_ROLE = keccak256("NODES_ROLE");
    bytes32 public constant FINANCE_ADMIN_ROLE =
        keccak256("FINANCE_ADMIN_ROLE");
    bytes32 public constant LIMITS_ADMIN_ROLE = keccak256("LIMITS_ADMIN_ROLE");
    bytes32 public constant ADDRESS_ADMIN_ROLE =
        keccak256("ADDRESS_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public constant PRECISION = 10000;

    /* ===== GENERAL ===== */

    WaifuToken public waifuToken;
    PreLaunchToken public preLaunchToken;
    WaifuPerks public perks;
    RevenueDistributor public revenueDistributor;

    uint256 public rewardsLimit;
    uint256 public totalRewardsGranted;
    uint256 public defaultClaimTax;

    uint256 public claimTaxReductionBase;
    uint256 public claimTaxReductionPeriod;
    uint256 public maxClaimTaxReduction;

    bool public claimingEnabled;
    bool public earlyFlow; // when WaifuToken is not launched yet

    // account => collected rewards ready to be spent or claimed
    mapping(address => uint256) public accountRewards;
    // account => timestamp of last rewards claim (or first node purchase)
    mapping(address => uint256) public claimTaxReductionSince;

    /* ===== EVENTS ===== */

    // payment events
    event PaymentFrom(
        address indexed account,
        address indexed operator,
        uint256 amount
    );

    // rewards events
    event RewardsGranted(
        address indexed account,
        address indexed operator,
        uint256 amount
    );
    event RewardsSpent(address indexed account, uint256 amount);
    event RewardsClaimed(address indexed account, uint256 amount, uint256 tax);

    // mutability events
    event NewDefaultClaimTax(uint256 newTax);
    event ClaimTaxReductionBaseSet(uint256 newBase);
    event ClaimTaxReductionPeriodSet(uint256 newPeriod);
    event MaxClaimTaxReductionSet(uint256 newMax);
    event RevenueDistributorSet(address revenueDistributor);
    event PerksSet(address waifuPerks);
    event ClaimingEnabledSet(bool enabled);
    event EarlyFlowSet(bool early);

    /* ===== CONSTRUCTOR ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        PreLaunchToken _preLaunchToken,
        WaifuToken _waifuToken,
        WaifuPerks _waifuPerks,
        RevenueDistributor _revenueDistributor,
        uint256 _rewardsLimit,
        uint256 _defaultClaimTax,
        uint256 _claimTaxReductionBase,
        uint256 _claimTaxReductionPeriod,
        uint256 _maxClaimTaxReduction,
        address admin
    ) public initializer {
        __AccessControlEnumerable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        require(
            _defaultClaimTax <= PRECISION,
            "WaifuToken: invalid tax"
        );

        require(
            address(_preLaunchToken) != address(0) &&
                address(_waifuToken) != address(0) &&
                address(_waifuPerks) != address(0) &&
                address(_revenueDistributor) != address(0),
            "WaifuCashier: zero address"
        );

        preLaunchToken = _preLaunchToken;
        waifuToken = _waifuToken;
        perks = _waifuPerks;
        revenueDistributor = _revenueDistributor;

        rewardsLimit = _rewardsLimit;
        defaultClaimTax = _defaultClaimTax;

        claimTaxReductionBase = _claimTaxReductionBase;
        claimTaxReductionPeriod = _claimTaxReductionPeriod;
        maxClaimTaxReduction = _maxClaimTaxReduction;

        earlyFlow = true;

        _pause();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(FINANCE_ADMIN_ROLE, admin);
        _grantRole(LIMITS_ADMIN_ROLE, admin);
        _grantRole(ADDRESS_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        if (admin != _msgSender()) {
            _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        }
    }

    /* ===== VIEWABLE ===== */
    function rewardsAvailable() public view returns (uint256) {
        return rewardsLimit - totalRewardsGranted;
    }

    function getClaimTaxDecreaseOf(address account)
        public
        view
        returns (uint256)
    {
        uint256 since = claimTaxReductionSince[account];

        require(since > 0, "WaifuCashier: since not set for account");

        uint256 timeElapsed = block.timestamp - since;
        uint256 periodsElapsed = timeElapsed / claimTaxReductionPeriod;
        uint256 reduction = _minimumOf(
            periodsElapsed * claimTaxReductionBase,
            maxClaimTaxReduction
        );

        return reduction + perks.getPercentageBenefitOf(account);
    }

    function getClaimTaxOf(address account) public view returns (uint256) {
        uint256 taxReduction = getClaimTaxDecreaseOf(account);

        return defaultClaimTax > taxReduction ?
            defaultClaimTax - taxReduction :
            0;
    }

    /* ===== FUNCTIONALITY ===== */

    function getNodePaymentFrom(address account, uint256 amount)
        external
        whenNotPaused
        onlyRole(PAYMENT_MANAGER_ROLE)
    {
        require(amount > 0, "WaifuCashier: zero payment");

        uint256 due = _tryRewardsPaymentFrom(account, amount);

        if (due > 0) {
            due = _tryPreLaunchTokenPaymentFrom(account, due);
        }

        if (due > 0) {
            due = _tryWaifuTokenPaymentFrom(account, due);
        }

        require(due == 0, "WaifuCashier: not enough funds");

        if (earlyFlow) {
            revenueDistributor.liquidateNodeRevenueEarly();
        } else {
            revenueDistributor.liquidateNodeRevenue();
        }

        emit PaymentFrom(account, _msgSender(), amount);
    }

    function grantRewardsTo(address account, uint256 amount)
        external
        whenNotPaused
        onlyRole(PAYMENT_MANAGER_ROLE)
    {
        uint256 rewardsToGrant = _minimumOf(amount, rewardsAvailable());

        require(rewardsToGrant > 0, "WaifuCashier: no rewards to grant");

        accountRewards[account] += rewardsToGrant;
        totalRewardsGranted += rewardsToGrant;

        emit RewardsGranted(account, _msgSender(), rewardsToGrant);
    }

    function tryInitializeClaimTaxReductionFor(address account)
        external
        onlyRole(NODES_ROLE)
    {
        if (claimTaxReductionSince[account] == 0) {
            claimTaxReductionSince[account] = block.timestamp;
        }
    }

    function claimRewardsMax() external {
        claimRewards(accountRewards[_msgSender()]);
    }

    function claimRewards(uint256 amount) public whenNotPaused {
        address account = _msgSender();

        require(claimingEnabled, "WaifuCashier: claiming disabled");
        require(
            amount > 0,
            "WaifuCashier: claiming 0 rewards"
        );
        require(
            accountRewards[account] >= amount,
            "WaifuCashier: not enough rewards"
        );

        accountRewards[account] -= amount;

        uint256 claimTax = (amount * getClaimTaxOf(account)) / PRECISION;
        waifuToken.mint(account, amount - claimTax);

        if (claimTax > 0) {
            waifuToken.mint(address(revenueDistributor), claimTax);
            revenueDistributor.liquidateTaxRevenue();
        }

        claimTaxReductionSince[account] = block.timestamp;

        emit RewardsClaimed(account, amount, claimTax);
    }

    /* ===== MUTATIVE ===== */

    function setDefaultClaimTax(uint256 newTax)
        external
        onlyRole(FINANCE_ADMIN_ROLE)
    {
        require(newTax < PRECISION, "WaifuCashier: tax too high");

        defaultClaimTax = newTax;

        emit NewDefaultClaimTax(newTax);
    }

    function setClaimTaxReductionBase(uint256 newBase)
        external
        onlyRole(FINANCE_ADMIN_ROLE)
    {
        require(newBase <= defaultClaimTax, "WaifuCashier: base too high");

        claimTaxReductionBase = newBase;

        emit ClaimTaxReductionBaseSet(newBase);
    }

    function setClaimTaxReductionPeriod(uint256 newPeriod)
        external
        onlyRole(FINANCE_ADMIN_ROLE)
    {
        claimTaxReductionPeriod = newPeriod;

        emit ClaimTaxReductionPeriodSet(newPeriod);
    }

    function setMaxClaimTaxReduction(uint256 newMax)
        external
        onlyRole(FINANCE_ADMIN_ROLE)
    {
        require(newMax <= defaultClaimTax, "WaifuCashier: max too high");

        maxClaimTaxReduction = newMax;

        emit MaxClaimTaxReductionSet(newMax);
    }

    function setRevenueDistributor(address payable _revenueDistributor)
        external
        onlyRole(ADDRESS_ADMIN_ROLE)
    {
        require(
            _revenueDistributor != address(0),
            "WaifuCashier: zero address"
        );

        revenueDistributor = RevenueDistributor(_revenueDistributor);

        emit RevenueDistributorSet(_revenueDistributor);
    }

    function setClaimingEnabled(bool enabled)
        external
        onlyRole(LIMITS_ADMIN_ROLE)
    {
        claimingEnabled = enabled;

        emit ClaimingEnabledSet(enabled);
    }

    function setEarlyFlow(bool early)
        external
        onlyRole(FINANCE_ADMIN_ROLE)
    {
        earlyFlow = early;

        emit EarlyFlowSet(early);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /* ===== INTERNAL ===== */

    function _tryRewardsPaymentFrom(
        address account,
        uint256 amount
    ) private returns (uint256 due) {
        if (earlyFlow) return amount;

        uint256 rewards = accountRewards[account];
        uint256 rewardsToPay = _minimumOf(amount, rewards);

        if (rewardsToPay == 0) return amount;

        accountRewards[account] -= rewardsToPay;

        waifuToken.mint(address(revenueDistributor), rewardsToPay);

        emit RewardsSpent(account, rewards);

        return amount - rewardsToPay;
    }

    function _tryPreLaunchTokenPaymentFrom(
        address account,
        uint256 amount
    ) private returns (uint256 due) {
        uint256 balance = preLaunchToken.balanceOf(account);
        uint256 amountToPay = _minimumOf(amount, balance);

        if (amountToPay == 0) return amount;
        
        if (earlyFlow) {
            preLaunchToken.safeTransferFrom(
                account,
                address(revenueDistributor),
                amountToPay
            );
        } else {
            preLaunchToken.withdrawFromTo(
                account,
                address(revenueDistributor),
                amountToPay
            );
        }

        return amount - amountToPay;
    }

    function _tryWaifuTokenPaymentFrom(
        address account,
        uint256 amount
    ) private returns (uint256 due) {
        if (earlyFlow) return amount;

        uint256 balance = waifuToken.balanceOf(account);
        uint256 amountToPay = _minimumOf(amount, balance);

        if (amountToPay == 0) return amount;

        waifuToken.safeTransferFrom(
            account,
            address(revenueDistributor),
            amountToPay
        );

        return amount - amountToPay;
    }

    function _minimumOf(
        uint256 value1,
        uint256 value2
    ) private pure returns (uint256) {
        return value1 <= value2 ? value1 : value2;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}