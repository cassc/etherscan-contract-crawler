// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

import "../interfaces/IAggregatorVault.sol";
import "../interfaces/IWETH.sol";

/**
 * @title Storage for SpiceFi4626
 * @author Spice Finance Inc
 */
abstract contract SpiceFi4626Storage {
    /// @notice withdrawal fees per 10_000 units
    uint256 public withdrawalFees;

    /// @notice Max Total Supply
    uint256 public maxTotalSupply;

    /// @notice Indicates whether the vault is verified or not
    bool public verified;

    /// @notice Spice dev wallet
    address public dev;

    /// @notice Spice multisig address
    address public multisig;

    /// @notice Fee recipient address
    address public feeRecipient;
}

/**
 * @title Storage for SpiceFi4626
 * @author Spice Finance Inc
 */
abstract contract SpiceFi4626StorageV2 {
    uint256 public lastTotalAssets;
    uint256 public lastTotalShares;
}

/**
 * @title SpiceFi4626
 * @author Spice Finance Inc
 */
contract SpiceFi4626 is
    IAggregatorVault,
    SpiceFi4626Storage,
    ERC4626Upgradeable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    Multicall,
    SpiceFi4626StorageV2
{
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /*************/
    /* Constants */
    /*************/

    /// @notice Rebalance vault assets using ERC4626 client interface
    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");

    /// @notice Contracts that funds can be sent to
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

    /// @notice Contracts that receive fees
    bytes32 public constant ASSET_RECEIVER_ROLE =
        keccak256("ASSET_RECEIVER_ROLE");

    /// @notice Contracts allowed to deposit
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");

    /// @notice Spice role
    bytes32 public constant SPICE_ROLE = keccak256("SPICE_ROLE");

    /// @notice Creator role
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    /**********/
    /* Errors */
    /**********/

    /// @notice Invalid address (e.g. zero address)
    error InvalidAddress();

    /// @notice Parameter out of bounds
    error ParameterOutOfBounds();

    /// @notice Slippage too high
    error SlippageTooHigh();

    /// @notice Exceed maxTotalSupply
    error ExceedMaxTotalSupply();

    /// @notice Caller not enabled
    error CallerNotEnabled();

    /// @notice Refund failed
    error RefundFailed();

    /// @notice Withdraw failed
    error WithdrawFailed();

    /**********/
    /* Events */
    /**********/

    /// @notice Emitted when withdrawal fee rate is updated
    /// @param withdrawalFees New withdrawal fees per 10_000 units
    event WithdrawalFeeRateUpdated(uint256 withdrawalFees);

    /// @notice Emitted when dev is updated
    /// @param dev New dev address
    event DevUpdated(address dev);

    /// @notice Emitted when multisig is updated
    /// @param multisig New multisig address
    event MultisigUpdated(address multisig);

    /// @notice Emitted when fee recipient is updated
    /// @param feeRecipient New fee recipient address
    event FeeRecipientUpdated(address feeRecipient);

    /*************/
    /* Modifiers */
    /*************/

    modifier takeFees() {
        _takeFees();

        _;
    }

    /***************/
    /* Constructor */
    /***************/

    /// @notice SpiceFi4626 constructor (for proxy)
    /// @param _name Token name
    /// @param _symbol Token symbol
    /// @param _asset Asset token address
    /// @param _vaults Vault addresses
    /// @param _creator Creator address
    /// @param _dev Spice dev wallet
    /// @param _multisig Spice multisig wallet
    /// @param _feeRecipient Initial fee recipient address
    function initialize(
        string memory _name,
        string memory _symbol,
        address _asset,
        address[] memory _vaults,
        address _creator,
        address _dev,
        address _multisig,
        address _feeRecipient
    ) public initializer {
        if (_asset == address(0)) {
            revert InvalidAddress();
        }
        if (_creator == address(0)) {
            revert InvalidAddress();
        }
        if (_dev == address(0)) {
            revert InvalidAddress();
        }
        if (_multisig == address(0)) {
            revert InvalidAddress();
        }
        if (_feeRecipient == address(0)) {
            revert InvalidAddress();
        }

        __ERC4626_init(IERC20Upgradeable(_asset));
        __ERC20_init(_name, _symbol);

        dev = _dev;
        multisig = _multisig;
        feeRecipient = _feeRecipient;

        uint256 length = _vaults.length;
        for (uint256 i; i != length; ++i) {
            if (_vaults[i] == address(0)) {
                revert InvalidAddress();
            }
            _setupRole(VAULT_ROLE, _vaults[i]);
        }

        _setupRole(CREATOR_ROLE, _creator);
        _setupRole(DEFAULT_ADMIN_ROLE, _dev);
        _setupRole(DEFAULT_ADMIN_ROLE, _multisig);
        _setupRole(STRATEGIST_ROLE, _dev);
        _setupRole(ASSET_RECEIVER_ROLE, _multisig);
        _setupRole(USER_ROLE, _dev);
        _setupRole(USER_ROLE, _multisig);
        _setupRole(USER_ROLE, _creator);
        _setupRole(SPICE_ROLE, _multisig);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Set withdrawal fees
    ///
    /// Emits a {WithdrawalFeeRateUpdated} event.
    ///
    /// @param withdrawalFees_ New withdrawal fees per 10_000 units
    function setWithdrawalFees(
        uint256 withdrawalFees_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (withdrawalFees_ > 10_000) {
            revert ParameterOutOfBounds();
        }
        withdrawalFees = withdrawalFees_;
        emit WithdrawalFeeRateUpdated(withdrawalFees_);
    }

    /// @notice Set the dev wallet address
    ///
    /// Emits a {DevUpdated} event.
    ///
    /// @param _dev New dev wallet
    function setDev(address _dev) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_dev == address(0)) {
            revert InvalidAddress();
        }

        address oldDev = dev;
        _revokeRole(DEFAULT_ADMIN_ROLE, oldDev);
        _revokeRole(STRATEGIST_ROLE, oldDev);
        _revokeRole(USER_ROLE, oldDev);

        dev = _dev;

        _setupRole(DEFAULT_ADMIN_ROLE, _dev);
        _setupRole(STRATEGIST_ROLE, _dev);
        _setupRole(USER_ROLE, _dev);

        emit DevUpdated(_dev);
    }

    /// @notice Set the multisig address
    ///
    /// Emits a {MultisigUpdated} event.
    ///
    /// @param _multisig New multisig address
    function setMultisig(
        address _multisig
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_multisig == address(0)) {
            revert InvalidAddress();
        }

        address oldMultisig = multisig;
        _revokeRole(DEFAULT_ADMIN_ROLE, oldMultisig);
        _revokeRole(ASSET_RECEIVER_ROLE, oldMultisig);
        _revokeRole(USER_ROLE, oldMultisig);
        _revokeRole(SPICE_ROLE, oldMultisig);

        multisig = _multisig;

        _setupRole(DEFAULT_ADMIN_ROLE, _multisig);
        _setupRole(ASSET_RECEIVER_ROLE, _multisig);
        _setupRole(USER_ROLE, _multisig);
        _setupRole(SPICE_ROLE, _multisig);

        emit MultisigUpdated(_multisig);
    }

    /// @notice Set the fee recipient address
    ///
    /// Emits a {FeeRecipientUpdated} event.
    ///
    /// @param _feeRecipient New fee recipient address
    function setFeeRecipient(
        address _feeRecipient
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_feeRecipient == address(0)) {
            revert InvalidAddress();
        }
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    /// @notice set max total supply
    /// @param maxTotalSupply_ max total supply
    function setMaxTotalSupply(
        uint256 maxTotalSupply_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        maxTotalSupply = maxTotalSupply_;
    }

    /// @notice set verified
    /// @param verified_ new verified value
    function setVerified(bool verified_) public onlyRole(SPICE_ROLE) {
        verified = verified_;
    }

    /// @notice trigger paused state
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice return to normal state
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @inheritdoc ERC20Upgradeable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!paused(), "ERC20Pausable: token transfer while paused");
        super._beforeTokenTransfer(from, to, amount);
    }

    /// @inheritdoc ERC20Upgradeable
    function _mint(address account, uint256 amount) internal override {
        if (totalSupply() + amount > maxTotalSupply) {
            revert ExceedMaxTotalSupply();
        }
        super._mint(account, amount);
    }

    /// @inheritdoc IERC4626Upgradeable
    function totalAssets() public view override returns (uint256) {
        uint256 balance = IERC20Upgradeable(asset()).balanceOf(address(this));

        IERC4626Upgradeable vault;
        uint256 count = getRoleMemberCount(VAULT_ROLE);
        for (uint256 i; i != count; ) {
            vault = IERC4626Upgradeable(getRoleMember(VAULT_ROLE, i));
            balance += vault.previewRedeem(vault.balanceOf(address(this)));
            unchecked {
                ++i;
            }
        }
        return balance;
    }

    /// @inheritdoc IERC4626Upgradeable
    function maxDeposit(address) public view override returns (uint256) {
        return
            paused()
                ? 0
                : _convertToAssets(
                    maxTotalSupply - totalSupply(),
                    MathUpgradeable.Rounding.Down
                );
    }

    /// @inheritdoc IERC4626Upgradeable
    function maxMint(address) public view override returns (uint256) {
        return paused() ? 0 : maxTotalSupply - totalSupply();
    }

    /// @inheritdoc IERC4626Upgradeable
    function maxWithdraw(address owner) public view override returns (uint256) {
        return paused() ? 0 : previewRedeem(balanceOf(owner));
    }

    /// @inheritdoc IERC4626Upgradeable
    function maxRedeem(address owner) public view override returns (uint256) {
        return paused() ? 0 : balanceOf(owner);
    }

    /// @inheritdoc IERC4626Upgradeable
    function previewWithdraw(
        uint256 assets
    ) public view override returns (uint256) {
        (
            uint256 _totalAssets,
            uint256 _totalShares,
            uint256 interestEarned
        ) = _interestEarned();
        uint256 fees = (interestEarned * withdrawalFees) / 10_000;
        return
            (assets == 0 || _totalShares == 0)
                ? assets
                : assets.mulDiv(
                    _totalShares,
                    _totalAssets - fees,
                    MathUpgradeable.Rounding.Up
                );
    }

    /// @inheritdoc IERC4626Upgradeable
    function previewRedeem(
        uint256 shares
    ) public view override returns (uint256) {
        (
            uint256 _totalAssets,
            uint256 _totalShares,
            uint256 interestEarned
        ) = _interestEarned();
        uint256 fees = (interestEarned * withdrawalFees) / 10_000;
        return
            _totalShares == 0
                ? shares
                : shares.mulDiv(
                    _totalAssets - fees,
                    _totalShares,
                    MathUpgradeable.Rounding.Down
                );
    }

    /******************/
    /* User Functions */
    /******************/

    /// @inheritdoc IERC4626Upgradeable
    function deposit(
        uint256 assets,
        address receiver
    ) public override whenNotPaused nonReentrant returns (uint256 shares) {
        shares = previewDeposit(assets);
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        IERC20Upgradeable(asset()).safeTransferFrom(
            _msgSender(),
            address(this),
            assets
        );

        _deposit(_msgSender(), receiver, assets, shares);
    }

    /// @inheritdoc IERC4626Upgradeable
    function mint(
        uint256 shares,
        address receiver
    ) public override whenNotPaused nonReentrant returns (uint256 assets) {
        assets = previewMint(shares);
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        IERC20Upgradeable(asset()).safeTransferFrom(
            _msgSender(),
            address(this),
            assets
        );

        _deposit(_msgSender(), receiver, assets, shares);
    }

    /// @inheritdoc IERC4626Upgradeable
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    )
        public
        override
        whenNotPaused
        nonReentrant
        takeFees
        returns (uint256 shares)
    {
        if (assets == 0) {
            revert ParameterOutOfBounds();
        }
        if (receiver == address(0)) {
            revert InvalidAddress();
        }

        shares = _convertToShares(assets, MathUpgradeable.Rounding.Up);

        _withdraw(_msgSender(), receiver, owner, assets, shares);

        IERC20Upgradeable(asset()).safeTransfer(receiver, assets);
    }

    /// @inheritdoc IERC4626Upgradeable
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    )
        public
        override
        whenNotPaused
        nonReentrant
        takeFees
        returns (uint256 assets)
    {
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }
        if (receiver == address(0)) {
            revert InvalidAddress();
        }

        assets = _convertToAssets(shares, MathUpgradeable.Rounding.Down);

        _withdraw(_msgSender(), receiver, owner, assets, shares);

        IERC20Upgradeable(asset()).safeTransfer(receiver, assets);
    }

    function depositETH(
        address receiver
    ) public payable whenNotPaused nonReentrant returns (uint256 shares) {
        uint256 assets = msg.value;
        shares = previewDeposit(assets);
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        IWETH(asset()).deposit{value: msg.value}();

        _deposit(_msgSender(), receiver, assets, shares);
    }

    function mintETH(
        uint256 shares,
        address receiver
    ) public payable whenNotPaused nonReentrant returns (uint256 assets) {
        assets = previewMint(shares);
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        if (msg.value < assets) {
            revert ParameterOutOfBounds();
        }

        IWETH(asset()).deposit{value: assets}();

        if (msg.value > assets) {
            (bool success, ) = msg.sender.call{value: msg.value - assets}("");
            if (!success) {
                revert RefundFailed();
            }
        }

        _deposit(_msgSender(), receiver, assets, shares);
    }

    function withdrawETH(
        uint256 assets,
        address receiver,
        address owner
    ) public whenNotPaused nonReentrant takeFees returns (uint256 shares) {
        if (assets == 0) {
            revert ParameterOutOfBounds();
        }
        if (receiver == address(0)) {
            revert InvalidAddress();
        }

        shares = _convertToShares(assets, MathUpgradeable.Rounding.Up);

        _withdraw(_msgSender(), receiver, owner, assets, shares);

        IWETH(asset()).withdraw(assets);
        (bool success, ) = receiver.call{value: assets}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    function redeemETH(
        uint256 shares,
        address receiver,
        address owner
    ) public whenNotPaused nonReentrant takeFees returns (uint256 assets) {
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }
        if (receiver == address(0)) {
            revert InvalidAddress();
        }

        assets = _convertToAssets(shares, MathUpgradeable.Rounding.Down);

        _withdraw(_msgSender(), receiver, owner, assets, shares);

        IWETH(asset()).withdraw(assets);
        (bool success, ) = receiver.call{value: assets}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    /// @inheritdoc ERC4626Upgradeable
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        uint256 balance = IERC20Upgradeable(asset()).balanceOf(address(this));
        if (balance < assets) {
            // withdraw from vaults
            _withdrawFromVaults(assets - balance);
        }

        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _burn(owner, shares);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _withdrawFromVaults(uint256 amount) internal {
        uint256 vaultCount = getRoleMemberCount(VAULT_ROLE);
        for (uint256 i; amount > 0 && i != vaultCount; ++i) {
            IERC4626Upgradeable vault = IERC4626Upgradeable(
                getRoleMember(VAULT_ROLE, i)
            );
            uint256 withdrawAmount = MathUpgradeable.min(
                amount,
                vault.maxWithdraw(address(this))
            );
            if (withdrawAmount > 0) {
                vault.withdraw(withdrawAmount, address(this), address(this));
                amount -= withdrawAmount;
            }
        }
    }

    /// @inheritdoc ERC4626Upgradeable
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override {
        if (getRoleMemberCount(USER_ROLE) > 0 && !hasRole(USER_ROLE, caller)) {
            revert CallerNotEnabled();
        }

        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    function _takeFees() internal {
        (
            uint256 _totalAssets,
            uint256 _totalShares,
            uint256 interestEarned
        ) = _interestEarned();

        if (interestEarned > 0) {
            IERC20Upgradeable currency = IERC20Upgradeable(asset());

            uint256 balance = currency.balanceOf(address(this));
            uint256 fees = (interestEarned * withdrawalFees) / 10_000;
            if (fees > 0) {
                if (balance < fees) {
                    // withdraw from vaults
                    _withdrawFromVaults(fees - balance);
                }
                uint256 half = fees / 2;
                currency.safeTransfer(multisig, half);
                currency.safeTransfer(feeRecipient, fees - half);

                _totalAssets -= fees;
            }
        }

        lastTotalAssets = _totalAssets;
        lastTotalShares = _totalShares;
    }

    function _interestEarned()
        internal
        view
        returns (
            uint256 _totalAssets,
            uint256 _totalShares,
            uint256 interestEarned
        )
    {
        _totalAssets = totalAssets();
        _totalShares = totalSupply();

        if (lastTotalShares == 0) {
            interestEarned = _totalAssets > _totalShares
                ? (_totalAssets - _totalShares)
                : 0;
        } else {
            uint256 adjusted = (lastTotalAssets * _totalShares) /
                lastTotalShares;
            interestEarned = _totalAssets > adjusted
                ? (_totalAssets - adjusted)
                : 0;
        }
    }

    /// See {IAggregatorVault-deposit}
    function deposit(
        address vault,
        uint256 assets,
        uint256 minShares
    ) public nonReentrant onlyRole(STRATEGIST_ROLE) returns (uint256 shares) {
        _checkRole(VAULT_ROLE, vault);
        SafeERC20Upgradeable.safeIncreaseAllowance(
            IERC20Upgradeable(asset()),
            vault,
            assets
        );
        shares = IERC4626Upgradeable(vault).deposit(assets, address(this));

        if (minShares > shares) {
            revert SlippageTooHigh();
        }
    }

    /// See {IAggregatorVault-mint}
    function mint(
        address vault,
        uint256 shares,
        uint256 maxAssets
    ) public nonReentrant onlyRole(STRATEGIST_ROLE) returns (uint256 assets) {
        _checkRole(VAULT_ROLE, vault);
        uint256 assets_ = IERC4626Upgradeable(vault).previewMint(shares);
        SafeERC20Upgradeable.safeIncreaseAllowance(
            IERC20Upgradeable(asset()),
            vault,
            assets_
        );
        assets = IERC4626Upgradeable(vault).mint(shares, address(this));

        if (maxAssets < assets) {
            revert SlippageTooHigh();
        }
    }

    /// See {IAggregatorVault-withdraw}
    function withdraw(
        address vault,
        uint256 assets,
        uint256 maxShares
    ) public nonReentrant onlyRole(STRATEGIST_ROLE) returns (uint256 shares) {
        _checkRole(VAULT_ROLE, vault);
        shares = IERC4626Upgradeable(vault).withdraw(
            assets,
            address(this),
            address(this)
        );

        if (maxShares < shares) {
            revert SlippageTooHigh();
        }
    }

    /// See {IAggregatorVault-redeem}
    function redeem(
        address vault,
        uint256 shares,
        uint256 minAssets
    ) public nonReentrant onlyRole(STRATEGIST_ROLE) returns (uint256 assets) {
        _checkRole(VAULT_ROLE, vault);
        assets = IERC4626Upgradeable(vault).redeem(
            shares,
            address(this),
            address(this)
        );

        if (minAssets > assets) {
            revert SlippageTooHigh();
        }
    }

    /*************/
    /* Fallbacks */
    /*************/

    receive() external payable {}
}