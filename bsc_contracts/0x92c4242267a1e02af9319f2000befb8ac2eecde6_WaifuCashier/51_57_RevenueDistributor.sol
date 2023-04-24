// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../nodes/WaifuManager.sol";
import "../universal/IPancakeRouter.sol";
import "../universal/IPancakePair.sol";
import "../universal/IWBNB.sol";

/*
 * Used for distributing different types of revenue according to distribution
 * model.
 */
contract RevenueDistributor is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ===== CONSTANTS ===== */

    bytes32 public constant FEES_ADMIN_ROLE = keccak256("FEES_ADMIN_ROLE");
    bytes32 public constant ADDRESS_ADMIN_ROLE =
        keccak256("ADDRESS_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public constant PRECISION = 10000;

    /* ===== GENERAL ===== */

    IERC20Upgradeable public preLaunchToken;
    IERC20Upgradeable public waifuToken;
    IERC20Upgradeable public usdToken;

    IPancakeRouter01 public router;

    address public erhPaymentSplitter;
    address public reclaimManager;
    address public liquidityManager;
    address public companyWallet;

    uint32 public erhFee;
    uint32 public reclaimFee;
    uint32 public liquidityFee;

    bool public payCompanyInUsd;

    /* ===== EVENTS ===== */

    // liquidation events
    event NodeRevenueLiquidated(uint256 amount, address token);
    event TaxRevenueLiquidated(uint256 amount);
    event PerkRevenueLiquidated(uint256 amount, address token);

    // mutability events
    event NewErhPaymentSplitter(address erhPaymentSplitter);
    event NewReclaimManager(address reclaimManager);
    event NewLiquidityManager(address liquidityManager);
    event NewCompanyWallet(address companyWallet);
    event NewRouter(address router);
    event NewUsdToken(address usdToken);
    event NewFees(
        uint32 erhFee,
        uint32 reclaimFee,
        uint32 liquidityFee
    );
    event PayCompanyInUsdSet(bool enabled);

    /* ===== CONSTRUCTOR ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IERC20Upgradeable _preLaunchToken,
        IERC20Upgradeable _waifuToken,
        IERC20Upgradeable _usdToken,
        IPancakeRouter01 _router,
        address _erhPaymentSplitter,
        address _companyWallet,
        address admin
    ) public initializer {
        __AccessControlEnumerable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        preLaunchToken = _preLaunchToken;
        waifuToken = _waifuToken;
        usdToken = _usdToken;
        router = _router;

        erhPaymentSplitter = _erhPaymentSplitter;
        companyWallet = _companyWallet;

        _setFees(1000, 6500, 3000);

        _pause();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(FEES_ADMIN_ROLE, admin);
        _grantRole(ADDRESS_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        if (admin != _msgSender()) {
            _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
            _grantRole(ADDRESS_ADMIN_ROLE, _msgSender());
        }
    }

    /* ===== VIEWABLE ===== */

    function getPreLaunchTokenBalance() public view returns (uint256) {
        return preLaunchToken.balanceOf(address(this));
    }

    function getWaifuBalance() public view returns (uint256) {
        return waifuToken.balanceOf(address(this));
    }

    function getUsdBalance() public view returns (uint256) {
        return usdToken.balanceOf(address(this));
    }

    /* ===== FUNCTIONALITY ===== */

    function liquidateNodeRevenueEarly() external whenNotPaused {
        require(
            getPreLaunchTokenBalance() > 0,
            "RevenueDistributor: nothing to liquidate"
        );

        _liquidatNodeRevenue(true);
    }

    function liquidateNodeRevenue() external whenNotPaused {
        require(
            getWaifuBalance() > 0,
            "RevenueDistributor: nothing to liquidate"
        );

        _liquidatNodeRevenue(false);
    }

    function liquidateTaxRevenue() external whenNotPaused {
        require(
            getWaifuBalance() > 0,
            "RevenueDistributor: nothing to liquidate"
        );

        _liquidatTaxRevenue();
    }

    function liquidatePerkRevenue(IERC20Upgradeable revenueToken)
        external
        whenNotPaused
    {
        require(
            revenueToken.balanceOf(address(this)) > 0,
            "RevenueDistributor: nothing to liquidate"
        );

        _liquidatePerkRevenue(revenueToken);
    }

    /* ===== MUTATIVE ===== */

    function setErhPaymentSplitter(address newErhPaymentSplitter)
        external
        onlyRole(ADDRESS_ADMIN_ROLE)
    {
        require(
            newErhPaymentSplitter != address(0),
            "RevenueDistributor: zero address"
        );

        erhPaymentSplitter = newErhPaymentSplitter;

        emit NewErhPaymentSplitter(newErhPaymentSplitter);
    }

    function setReclaimManager(address newReclaimManager)
        external
        onlyRole(ADDRESS_ADMIN_ROLE)
    {
        require(
            newReclaimManager != address(0),
            "RevenueDistributor: zero address"
        );

        reclaimManager = newReclaimManager;

        emit NewReclaimManager(newReclaimManager);
    }

    function setLiquidityManager(address newLiquidityManager)
        external
        onlyRole(ADDRESS_ADMIN_ROLE)
    {
        require(
            newLiquidityManager != address(0),
            "RevenueDistributor: zero address"
        );

        liquidityManager = newLiquidityManager;

        emit NewLiquidityManager(newLiquidityManager);
    }

    function setCompanyWallet(address newCompanyWallet)
        external
        onlyRole(ADDRESS_ADMIN_ROLE)
    {
        require(
            newCompanyWallet != address(0),
            "RevenueDistributor: zero address"
        );

        companyWallet = newCompanyWallet;

        emit NewCompanyWallet(newCompanyWallet);
    }

    function setRouter(IPancakeRouter01 newRouter)
        external
        onlyRole(ADDRESS_ADMIN_ROLE)
    {
        require(
            address(newRouter) != address(0),
            "RevenueDistributor: zero address"
        );

        router = newRouter;

        emit NewRouter(address(newRouter));
    }

    function setUsdToken(IERC20Upgradeable newUsdToken)
        external
        onlyRole(ADDRESS_ADMIN_ROLE)
    {
        require(
            address(newUsdToken) != address(0),
            "RevenueDistributor: zero address"
        );

        usdToken = newUsdToken;

        emit NewUsdToken(address(newUsdToken));
    }

    function setFees(
        uint32 newErhFee,
        uint32 newReclaimFee,
        uint32 newLiquidityFee
    ) external onlyRole(FEES_ADMIN_ROLE) {
        _setFees(
            newErhFee,
            newReclaimFee,
            newLiquidityFee
        );
    }

    function setPayCompanyInUsd(bool enabled)
        external
        onlyRole(FEES_ADMIN_ROLE)
    {
        payCompanyInUsd = enabled;

        emit PayCompanyInUsdSet(enabled);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /* ===== INTERNAL ===== */

    function _setFees(
        uint32 newErhFee,
        uint32 newReclaimFee,
        uint32 newLiquidityFee
    ) private {
        require(
            newErhFee + newReclaimFee <= PRECISION,
            "RevenueDistributor: node purchase fees > PRECISION"
        );
        require(
            newErhFee + newLiquidityFee <= PRECISION,
            "RevenueDistributor: taxes fees > PRECISION"
        );

        erhFee = newErhFee;
        reclaimFee = newReclaimFee;
        liquidityFee = newLiquidityFee;

        emit NewFees(
            newErhFee,
            newReclaimFee,
            newLiquidityFee
        );
    }

    function _swap(uint256 amount, address[] memory path) private {
        if (path.length < 2 || amount == 0) {
            return;
        }

        /*
         * safeApprove requires 0 initial or resulting allowance,
         * safeIncreaseAllowance can accumulate allowance, not safe approve is
         * ok, transaction will fail anyways if it's not set.
         */
        IERC20Upgradeable(path[0]).approve(address(router), amount);
        router.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapWaifuToUsd(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(waifuToken);
        path[1] = address(usdToken);

        _swap(amount, path);
    }

    function _swapUsdToWaifu(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(usdToken);
        path[1] = address(waifuToken);

        _swap(amount, path);
    }

    /**
    @dev Takes the current balance of revenue within this contract
    and liquidates it according to the distribution split.

    Requirements:
    - SHOULD only liquidate if there are idle waifu tokens.
     */
    function _liquidatNodeRevenue(bool early) internal {
        require(
            reclaimManager != address(0),
            "RevenueDistributor: reclaimManager not set"
        );

        uint256 balance;
        if (early) {
            balance = getPreLaunchTokenBalance();
        } else {
            balance = getWaifuBalance();
        }

        uint256 reclaimAmount = (balance * reclaimFee) / PRECISION;
        uint256 erhAmount = (balance * erhFee) / PRECISION;
        // rest goes into company wallet
        uint256 companyAmount = balance - reclaimAmount - erhAmount;

        IERC20Upgradeable token;
        if (early) {
            token = preLaunchToken;
        } else {
            token = waifuToken;
        }

        token.safeTransfer(reclaimManager, reclaimAmount);
        token.safeTransfer(erhPaymentSplitter, erhAmount);

        if (!early && payCompanyInUsd) {
            // pay company in USD
            _swapWaifuToUsd(companyAmount);
            usdToken.safeTransfer(companyWallet, getUsdBalance());
        } else {
            token.safeTransfer(companyWallet, companyAmount);
        }

        emit NodeRevenueLiquidated(
            balance,
            address(token)
        );
    }

    function _liquidatTaxRevenue() internal {
        uint256 balance = getWaifuBalance();

        uint256 liquidityAmount = (balance * liquidityFee) / PRECISION;
        uint256 erhAmount = (balance * erhFee) / PRECISION;
        // rest goes into company wallet
        uint256 companyAmount = balance - liquidityAmount - erhAmount;

        waifuToken.safeTransfer(liquidityManager, liquidityAmount);
        waifuToken.safeTransfer(erhPaymentSplitter, erhAmount);

        if (payCompanyInUsd) {
            _swapWaifuToUsd(companyAmount);
            usdToken.safeTransfer(companyWallet, getUsdBalance());
        } else {
            waifuToken.safeTransfer(companyWallet, companyAmount);
        }

        emit TaxRevenueLiquidated(balance);
    }

    function _liquidatePerkRevenue(IERC20Upgradeable revenueToken) internal {
        uint256 balance = revenueToken.balanceOf(address(this));

        if (revenueToken == waifuToken) {
            uint256 erhAmount = (balance * erhFee) / PRECISION;
            uint256 companyAmount = balance - erhAmount;

            waifuToken.safeTransfer(erhPaymentSplitter, erhAmount);

            if (payCompanyInUsd) {
                _swapWaifuToUsd(companyAmount);
                usdToken.safeTransfer(companyWallet, getUsdBalance());
            } else {
                waifuToken.safeTransfer(companyWallet, companyAmount);
            }
        } else if (revenueToken == usdToken) {
            // swap to Waifu for ERHPaymentSplitter
            if (payCompanyInUsd) {
                uint256 erhAmount = (balance * erhFee) / PRECISION;
                uint256 companyAmount = balance - erhAmount;

                usdToken.safeTransfer(companyWallet, companyAmount);

                _swapUsdToWaifu(erhAmount);
                waifuToken.safeTransfer(erhPaymentSplitter, getWaifuBalance());
            } else {
                // swap all and then calcucate amount
                _swapUsdToWaifu(balance);

                uint256 waifuBalance = getWaifuBalance();

                uint256 erhAmount = (waifuBalance * erhFee) / PRECISION;
                // rest goes into company wallet
                uint256 companyAmount = waifuBalance - erhAmount;

                waifuToken.safeTransfer(erhPaymentSplitter, erhAmount);
                waifuToken.safeTransfer(companyWallet, companyAmount);
            }
        } else {
            revert("RevenueDistributor: invalid revenue token");
        }

        emit PerkRevenueLiquidated(balance, address(revenueToken));
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}