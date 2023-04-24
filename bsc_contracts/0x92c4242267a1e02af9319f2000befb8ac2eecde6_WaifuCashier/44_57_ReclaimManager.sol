// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../tokens/WaifuToken.sol";
import "../tokens/PreLaunchToken.sol";
import "../nodes/WaifuNodes.sol";
import "../nodes/WaifuManager.sol";
import "../perks/WaifuPerks.sol";

/*
 * Keeps a part of funds acquired for WaifuNodes tokens purchases for further
 * refunds, when WaifuNodes life cycle is over.
 */
contract ReclaimManager is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for WaifuToken;

    /* ===== CONSTANTS ===== */

    // MANAGER_ROLE should be granted to WaifuManager
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public constant PRECISION = 10000;

    /* ===== GENERAL ===== */

    WaifuToken public waifuToken;
    PreLaunchToken public preLaunchToken;
    WaifuNodes public waifuNodes;
    WaifuPerks public waifuPerks;

    uint256 public defaultReclaimPercentage;
    uint256 public nodePrice;

    /* ===== EVENTS ===== */

    event FundsReclaimed(address indexed to, uint256 amount);
    event FundsWithdrawn(address indexed to, uint256 amount);

    /* ===== CONSTRUCTOR ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // currencies are expected to have the same value and decimals
    function initialize(
        WaifuToken _waifuToken,
        PreLaunchToken _preLaunchToken,
        WaifuNodes _waifuNodes,
        WaifuManager _waifuManager,
        WaifuPerks _waifuPerks,
        uint256 _defaultReclaimPercentage,
        address admin
    ) public initializer {
        __AccessControlEnumerable_init();
        __UUPSUpgradeable_init();

        require(
            address(_waifuToken) != address(0) &&
                address(_preLaunchToken) != address(0) &&
                address(_waifuManager) != address(0) &&
                address(_waifuPerks) != address(0),
            "WaifuCashier: zero address"
        );

        waifuToken = _waifuToken;
        preLaunchToken = _preLaunchToken;
        waifuNodes = _waifuNodes;
        waifuPerks = _waifuPerks;
        defaultReclaimPercentage = _defaultReclaimPercentage;

        require(
            defaultReclaimPercentage + waifuPerks.getMaxPercentageBenefit() <
                PRECISION,
            "WaifuCashier: invalid percentage"
        );

        nodePrice = _waifuManager.nodePrice();

        _pause();

        _grantRole(MANAGER_ROLE, address(_waifuManager));

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(WITHDRAWER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
    }

    /* ===== VIEWABLE ===== */

    function calculateReclaimAmount(
        address account,
        uint256 nodeAmount
    ) public view returns (uint256) {
        return nodeAmount * nodePrice * getReclaimPercentageOf(account)
            / PRECISION;
    }

    function getReclaimPercentageOf(address account)
        public
        view
        returns (uint256)
    {
        uint256 perkBenefit = waifuPerks.getPercentageBenefitOf(account);

        return defaultReclaimPercentage + perkBenefit;
    }

    function availableForWithdrawal() public view returns (uint256) {
        uint256 nodeSupply = waifuNodes.aggregateSupply();
        uint256 maxReclaimPercentage =
            defaultReclaimPercentage + waifuPerks.getMaxPercentageBenefit();

        uint256 maxReclaimAmount =
            (nodeSupply * nodePrice * maxReclaimPercentage) / PRECISION;

        uint256 preLaunchBalance = preLaunchToken.balanceOf(address(this));
        uint256 waifuBalance = waifuToken.balanceOf(address(this));

        return preLaunchBalance + waifuBalance - maxReclaimAmount;
    }

    /* ===== FUNCTIONALITY ===== */

    function reclaimFor(
        address account,
        uint256 nodeAmount
    ) external whenNotPaused onlyRole(MANAGER_ROLE) {
        uint256 reclaimAmount = calculateReclaimAmount(account, nodeAmount);

        require(reclaimAmount > 0, "ReclaimManager: nothing to reclaim");

        _tryWithdrawPrelaunchToken();
        waifuToken.safeTransfer(account, reclaimAmount);

        emit FundsReclaimed(account, reclaimAmount);
    }

    function withdrawAvailable() external onlyRole(WITHDRAWER_ROLE) {
        _withdrawAvailable(_msgSender());
    }

    function withdrawAvailableTo(address to)
        external
        onlyRole(WITHDRAWER_ROLE)
    {
        _withdrawAvailable(to);
    }

    /* ===== MUTATIVE ===== */

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /* ===== INTERNAL ===== */

    function _withdrawAvailable(address to) private {
        _tryWithdrawPrelaunchToken();

        uint256 amount = availableForWithdrawal();
        require(amount > 0, "ReclaimManager: nothing to withdraw");

        waifuToken.safeTransfer(to, amount);

        emit FundsWithdrawn(to, amount);
    }

    function _tryWithdrawPrelaunchToken() private {
        uint256 preLaunchTokenBalance = preLaunchToken.balanceOf(address(this));
        if (preLaunchTokenBalance > 0) {
            preLaunchToken.withdraw(preLaunchTokenBalance);
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}