// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IERC20MetadataUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

import {BaseStrategyVault} from "src/vaults/locked/BaseStrategyVault.sol";
import {DetailedShare} from "src/utils/Detailed.sol";
import {uncheckedInc} from "src/libs/Unchecked.sol";

contract StrategyVault is UUPSUpgradeable, BaseStrategyVault, ERC4626Upgradeable, PausableUpgradeable, DetailedShare {
    using SafeTransferLib for ERC20;
    using MathUpgradeable for uint256;

    function initialize(address _governance, address vaultAsset, string memory _name, string memory _symbol)
        external
        initializer
    {
        BaseStrategyVault.baseInitialize(_governance, ERC20(vaultAsset));
        __ERC20_init(_name, _symbol);
        __ERC4626_init(IERC20MetadataUpgradeable(vaultAsset));
        _grantRole(GUARDIAN_ROLE, governance);
        tvlCap = 10_000 * 10 ** _asset.decimals();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGovernance {}

    function asset() public view override(BaseStrategyVault, ERC4626Upgradeable) returns (address) {
        return BaseStrategyVault.asset();
    }

    /// @dev E.g. if the asset has 18 decimals, and initialSharesPerAsset is 1e8, then the vault has 26 decimals. And
    /// "one" `asset` will be worth "one" share (where "one" means 10 ** token.decimals()).
    function decimals() public view virtual override(ERC20Upgradeable, IERC20MetadataUpgradeable) returns (uint8) {
        return _asset.decimals() + _initialShareDecimals();
    }
    /// @notice The amount of shares to mint per wei of `asset` at genesis.

    function initialSharesPerAsset() public pure virtual returns (uint256) {
        return 1e8;
    }

    /// @notice Each wei of `asset` at genesis is worth 10 ** (initialShareDecimals) shares.
    function _initialShareDecimals() internal pure virtual returns (uint8) {
        return 8;
    }

    /// @notice See {IERC4626-totalAssets}
    function totalAssets() public view virtual override returns (uint256) {
        return vaultTVL() - lockedProfit();
    }

    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN");

    /// @notice Pause the contract
    function pause() external onlyRole(GUARDIAN_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract
    function unpause() external onlyRole(GUARDIAN_ROLE) {
        _unpause();
    }

    function maxDeposit(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @dev See {IERC4262-deposit}.
     */
    function deposit(uint256 assets, address receiver) public virtual override whenNotPaused returns (uint256) {
        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        return shares;
    }

    /**
     * @dev See {IERC4262-mint}.
     */
    function mint(uint256 shares, address receiver) public virtual override whenNotPaused returns (uint256) {
        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /**
     * @dev See {IERC4262-withdraw}.
     */
    function withdraw(uint256 assets, address receiver, address owner)
        public
        virtual
        override
        whenNotPaused
        returns (uint256)
    {
        uint256 shares = _convertToShares(assets, MathUpgradeable.Rounding.Up);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /**
     * @dev See {IERC4262-redeem}.
     */
    function redeem(uint256 shares, address receiver, address owner)
        public
        virtual
        override
        whenNotPaused
        returns (uint256)
    {
        uint256 assets = _convertToAssets(shares, MathUpgradeable.Rounding.Down);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual override {
        require(shares > 0, "Vault: zero shares");
        uint256 tvl = totalAssets();
        uint256 allowedAssets = tvl >= tvlCap ? 0 : tvlCap - tvl;
        assets = Math.min(allowedAssets, assets);
        require(assets > 0, "Vault: deposit limit reached");
        _mint(receiver, shares);
        _asset.safeTransferFrom(caller, address(this), assets);
        _depositIntoStrategy(assets);
        emit Deposit(caller, receiver, assets, shares);
    }

    event DebtRegistration(address caller, address receiver, address indexed owner, uint256 shares);

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        virtual
        override
    {
        // If vault is illiquid, lock shares
        if (!epochEnded) {
            _transfer({from: owner, to: address(debtEscrow), amount: shares});
            debtEscrow.registerWithdrawalRequest(owner, shares);
            emit DebtRegistration(caller, receiver, owner, shares);
            return;
        }

        _withdrawFromStrategy(assets);

        // Slippage during liquidation means we might get less than `assets` amount of `_asset`
        assets = Math.min(_asset.balanceOf(address(this)), assets);
        uint256 assetsFee = _getWithdrawalFee(assets);
        uint256 assetsToUser = assets - assetsFee;

        // Burn shares and give user equivalent value in `_asset` (minus withdrawal fees)
        if (caller != owner) _spendAllowance(owner, caller, shares);
        _burn(owner, shares);
        emit Withdraw(caller, receiver, owner, assets, shares);

        _asset.safeTransfer(receiver, assetsToUser);
        _asset.safeTransfer(governance, assetsFee);
    }

    /*//////////////////////////////////////////////////////////////
                             EXCHANGE RATES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC4262-previewWithdraw}.
     */
    function previewWithdraw(uint256 assetsToUser) public view virtual override returns (uint256) {
        // assets * ((1e4 - feeBps) / 1e4) = assetsToUser
        uint256 assets = assetsToUser.mulDiv(MAX_BPS, MAX_BPS - withdrawalFee, MathUpgradeable.Rounding.Up);
        return _convertToShares(assets, MathUpgradeable.Rounding.Up);
    }

    /**
     * @dev See {IERC4262-previewRedeem}.
     */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        uint256 assets = _convertToAssets(shares, MathUpgradeable.Rounding.Down);
        return assets - _getWithdrawalFee(assets);
    }

    function _convertToShares(uint256 assets, MathUpgradeable.Rounding rounding)
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        uint256 _totalSupply = totalSupply() + initialSharesPerAsset();
        uint256 _totalAssets = totalAssets() + 1;
        return assets.mulDiv(_totalSupply, _totalAssets, rounding);
    }

    function _convertToAssets(uint256 shares, MathUpgradeable.Rounding rounding)
        internal
        view
        virtual
        override
        returns (uint256 assets)
    {
        uint256 _totalSupply = totalSupply() + initialSharesPerAsset();
        uint256 _totalAssets = totalAssets() + 1;
        return shares.mulDiv(_totalAssets, _totalSupply, rounding);
    }

    /*//////////////////////////////////////////////////////////////
                                  FEES
    //////////////////////////////////////////////////////////////*/

    uint256 constant MAX_BPS = 10_000;
    /// @notice Fee charged to vault over a year, number is in bps
    uint256 public managementFee;
    /// @notice  Fee charged on redemption of shares, number is in bps
    uint256 public withdrawalFee;

    event ManagementFeeSet(uint256 oldFee, uint256 newFee);
    event WithdrawalFeeSet(uint256 oldFee, uint256 newFee);

    function setManagementFee(uint256 feeBps) external onlyGovernance {
        emit ManagementFeeSet({oldFee: managementFee, newFee: feeBps});
        managementFee = feeBps;
    }

    function setWithdrawalFee(uint256 feeBps) external onlyGovernance {
        emit WithdrawalFeeSet({oldFee: withdrawalFee, newFee: feeBps});
        withdrawalFee = feeBps;
    }

    uint256 constant SECS_PER_YEAR = 365 days;

    function _assessFees() internal virtual override {
        // duration / SECS_PER_YEAR * feebps / MAX_BPS * totalSupply
        uint256 duration = block.timestamp - lastHarvest;

        uint256 feesBps = (duration * managementFee) / SECS_PER_YEAR;
        uint256 numSharesToMint = (feesBps * totalSupply()) / MAX_BPS;

        if (numSharesToMint == 0) {
            return;
        }
        _mint(governance, numSharesToMint);
    }

    /// @dev  Return amount of `asset` to be given to user after applying withdrawal fee
    function _getWithdrawalFee(uint256 assets) internal view virtual returns (uint256) {
        return assets.mulDiv(withdrawalFee, MAX_BPS, MathUpgradeable.Rounding.Up);
    }
    /*//////////////////////////////////////////////////////////////
                           CAPITAL MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function endEpoch() external virtual override {
        require(msg.sender == address(strategy), "SV: only strategy");
        epochEnded = true;
        _updateTVL();

        // Transfer assets from strategy to escrow to resolve all pending withdrawals
        uint256 lockedShares = balanceOf(address(debtEscrow));
        uint256 assets = _convertToAssets(lockedShares, MathUpgradeable.Rounding.Down);
        if (assets == 0) return;
        _withdrawFromStrategy(assets);

        // Tell escrow that the funds are ready to be withdrawn. The escrow will redeem the shares.
        debtEscrow.resolveDebtShares();
        emit EndEpoch(epoch);
    }

    /// @notice Temporary tvl cap
    uint256 tvlCap;

    function setTvlCap(uint256 _tvlCap) external onlyGovernance {
        tvlCap = _tvlCap;
    }

    function tearDown(address[] calldata users) external onlyGovernance {
        uint256 length = users.length;
        for (uint256 i = 0; i < length; i = uncheckedInc(i)) {
            address user = users[i];
            uint256 shares = balanceOf(user);
            uint256 assets = convertToAssets(shares);
            uint256 amountToSend = Math.min(assets, _asset.balanceOf(address(this)));

            _burn(user, shares);
            _asset.safeTransfer(user, amountToSend);
        }
    }

    /*//////////////////////////////////////////////////////////////
                          DETAILED PRICE INFO
    //////////////////////////////////////////////////////////////*/

    function detailedTVL() external view override returns (Number memory tvl) {
        tvl = Number({num: totalAssets(), decimals: _asset.decimals()});
    }

    function detailedPrice() external view override returns (Number memory price) {
        price = Number({num: convertToAssets(10 ** decimals()), decimals: _asset.decimals()});
    }

    function detailedTotalSupply() external view override returns (Number memory supply) {
        supply = Number({num: totalSupply(), decimals: decimals()});
    }
}