// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../interfaces/IVault.sol";

/**
 * @title Storage for Vault
 * @author Spice Finance Inc
 */
abstract contract VaultStorageV1 {
    /// @dev Asset token
    IERC20Upgradeable internal _asset;

    /// @dev Token decimals;
    uint8 internal _decimals;

    /// @dev withdrawal fees per 10_000 units
    uint256 internal _withdrawalFees;

    /// @dev Total assets value
    uint256 internal _totalAssets;
}

/**
 * @title Storage for Vault, aggregated
 * @author Spice Finance Inc
 */
abstract contract VaultStorage is VaultStorageV1 {

}

/**
 * @title Vault
 * @author Spice Finance Inc
 */
contract Vault is
    IVault,
    VaultStorage,
    Initializable,
    UUPSUpgradeable,
    ERC20Upgradeable,
    IERC4626Upgradeable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721Holder
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUpgradeable for uint256;

    /*************/
    /* Constants */
    /*************/

    /// @notice Implementation version
    string public constant IMPLEMENTATION_VERSION = "1.0";

    /************************/
    /* Access Control Roles */
    /************************/

    /// @notice Keeper role
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    /// @notice Liquidator role
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

    /// @notice Bidder role
    bytes32 public constant BIDDER_ROLE = keccak256("BIDDER_ROLE");

    /// @notice Whitelist role
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    /// @notice Marketplace role
    bytes32 public constant MARKETPLACE_ROLE = keccak256("MARKETPLACE_ROLE");

    /// @notice Asset receiver role
    bytes32 public constant ASSET_RECEIVER_ROLE =
        keccak256("ASSET_RECEIVER_ROLE");

    /**********/
    /* Errors */
    /**********/

    /// @notice Invalid address (e.g. zero address)
    error InvalidAddress();

    /// @notice Parameter out of bounds
    error ParameterOutOfBounds();

    /// @notice Insufficient balance
    error InsufficientBalance();

    /// @notice Not whitelisted
    error NotWhitelisted();

    /**********/
    /* Events */
    /**********/

    /// @notice Emitted when withdrawal fee rate is updated
    /// @param withdrawalFees New withdrawal fees per 10_000 units
    event WithdrawalFeeRateUpdated(uint256 withdrawalFees);

    /// @notice Emitted when totalAssets is updated
    /// @param totalAssets Total assets
    event TotalAssets(uint256 totalAssets);

    /***************/
    /* Constructor */
    /***************/

    /// @notice Vault constructor (for proxy)
    /// @param name_ receipt token name
    /// @param symbol_ receipt token symbol
    /// @param asset_ asset token contract
    /// @param withdrawalFees_ initial withdrawal fees
    function initialize(
        string calldata name_,
        string calldata symbol_,
        IERC20Upgradeable asset_,
        uint256 withdrawalFees_
    ) external initializer {
        if (address(asset_) == address(0)) {
            revert InvalidAddress();
        }
        if (withdrawalFees_ > 10_000) {
            revert ParameterOutOfBounds();
        }

        __ERC20_init(name_, symbol_);
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _withdrawalFees = withdrawalFees_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ASSET_RECEIVER_ROLE, msg.sender);
        _grantRole(KEEPER_ROLE, msg.sender);
        _grantRole(LIQUIDATOR_ROLE, msg.sender);

        uint8 decimals_;
        try IERC20MetadataUpgradeable(address(asset_)).decimals() returns (
            uint8 value
        ) {
            decimals_ = value;
        } catch {
            decimals_ = super.decimals();
        }

        _asset = asset_;
        _decimals = decimals_;
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /***********/
    /* Getters */
    /***********/

    /// @notice See {IERC20Metadata-decimals}.
    function decimals()
        public
        view
        override(ERC20Upgradeable, IERC20MetadataUpgradeable)
        returns (uint8)
    {
        return _decimals;
    }

    /// @notice See {IERC4626-asset}.
    function asset() external view returns (address) {
        return address(_asset);
    }

    /// @notice See {IERC4626-totalAssets}
    function totalAssets() public view returns (uint256) {
        return _totalAssets;
    }

    /// @notice See {IERC4626-convertToShares}
    function convertToShares(uint256 assets) external view returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    /// @notice See {IERC4626-convertToAssets}
    function convertToAssets(uint256 shares) external view returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    /// @notice See {IERC4626-maxDeposit}
    function maxDeposit(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    /// @notice See {IERC4626-maxMint}
    function maxMint(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    /// @notice See {IERC4626-maxWithdraw}
    function maxWithdraw(address owner) external view returns (uint256) {
        return
            _convertToAssets(
                balanceOf(owner).mulDiv(10_000 - _withdrawalFees, 10_000),
                MathUpgradeable.Rounding.Up
            );
    }

    /// @notice See {IERC4626-maxRedeem}
    function maxRedeem(address owner) external view returns (uint256) {
        return balanceOf(owner).mulDiv(10_000 - _withdrawalFees, 10_000);
    }

    /// @notice See {IERC4626-previewDeposit}
    function previewDeposit(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    /// @notice See {IERC4626-previewMint}
    function previewMint(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Up);
    }

    /// @notice See {IERC4626-previewWithdraw}
    function previewWithdraw(uint256 assets) public view returns (uint256) {
        return
            _convertToShares(
                assets.mulDiv(10_000, 10_000 - _withdrawalFees),
                MathUpgradeable.Rounding.Up
            );
    }

    /// @notice See {IERC4626-previewRedeem}
    function previewRedeem(uint256 shares) public view returns (uint256) {
        return
            _convertToAssets(
                shares.mulDiv(10_000 - _withdrawalFees, 10_000),
                MathUpgradeable.Rounding.Down
            );
    }

    /******************/
    /* User Functions */
    /******************/

    /// See {IERC4626-deposit}.
    function deposit(uint256 assets, address receiver)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 shares)
    {
        // Validate amount
        if (assets == 0) {
            revert ParameterOutOfBounds();
        }

        // Compute number of shares to mint from current vault share price
        shares = previewDeposit(assets);

        _deposit(msg.sender, assets, shares, receiver);

        // Transfer cash from user to vault
        _asset.safeTransferFrom(msg.sender, address(this), assets);
    }

    /// See {IERC4626-mint}.
    function mint(uint256 shares, address receiver)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 assets)
    {
        // Validate amount
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        // Compute number of shares to mint from current vault share price
        assets = previewMint(shares);

        _deposit(msg.sender, assets, shares, receiver);

        // Transfer cash from user to vault
        _asset.safeTransferFrom(msg.sender, address(this), assets);
    }

    /// See {IERC4626-redeem}.
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external whenNotPaused nonReentrant returns (uint256 assets) {
        if (receiver == address(0)) {
            revert InvalidAddress();
        }
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        // compute redemption amount
        assets = previewRedeem(shares);

        // compute fee
        uint256 fees = _convertToAssets(shares, MathUpgradeable.Rounding.Down) -
            assets;

        _withdraw(msg.sender, receiver, owner, assets, shares, fees);
    }

    /// See {IERC4626-withdraw}.
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external whenNotPaused nonReentrant returns (uint256 shares) {
        if (receiver == address(0)) {
            revert InvalidAddress();
        }
        if (assets == 0) {
            revert ParameterOutOfBounds();
        }

        // compute share amount
        shares = previewWithdraw(assets);

        // compute fee
        uint256 fees = _convertToAssets(
            shares - _convertToShares(assets, MathUpgradeable.Rounding.Up),
            MathUpgradeable.Rounding.Down
        );

        _withdraw(msg.sender, receiver, owner, assets, shares, fees);
    }

    /*****************************/
    /* Internal Helper Functions */
    /*****************************/

    function _convertToShares(uint256 assets, MathUpgradeable.Rounding rounding)
        internal
        view
        returns (uint256 shares)
    {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? assets
                : assets.mulDiv(supply, totalAssets(), rounding);
    }

    function _convertToAssets(uint256 shares, MathUpgradeable.Rounding rounding)
        internal
        view
        returns (uint256 assets)
    {
        uint256 supply = totalSupply();
        return
            (supply == 0)
                ? shares
                : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /// @dev Deposit/mint common workflow.
    function _deposit(
        address caller,
        uint256 assets,
        uint256 shares,
        address receiver
    ) internal {
        // Check caller role
        if (
            getRoleMemberCount(WHITELIST_ROLE) > 0 &&
            !hasRole(WHITELIST_ROLE, caller)
        ) {
            revert NotWhitelisted();
        }

        // Increase total assets value of vault
        _totalAssets += assets;

        // Mint receipt tokens to receiver
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @dev Withdraw/redeem common workflow.
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares,
        uint256 fees
    ) internal {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        if (_asset.balanceOf(address(this)) < assets)
            revert InsufficientBalance();

        _burn(owner, shares);

        _asset.safeTransfer(receiver, assets);

        address feesAddr = getRoleMember(ASSET_RECEIVER_ROLE, 0);
        _asset.safeTransfer(feesAddr, fees);

        _totalAssets = _totalAssets - assets;

        emit Withdraw(msg.sender, msg.sender, owner, assets, shares);
    }

    /***********/
    /* Setters */
    /***********/

    /// @notice Set the admin fee rate
    ///
    /// Emits a {WithdrawalFeeRateUpdated} event.
    ///
    /// @param withdrawalFees Withdrawal fees per 10_000 units
    function setWithdrawalFees(uint256 withdrawalFees)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (withdrawalFees > 10_000) {
            revert ParameterOutOfBounds();
        }
        _withdrawalFees = withdrawalFees;
        emit WithdrawalFeeRateUpdated(withdrawalFees);
    }

    /// @notice Set total assets
    ///
    /// Emits a {TotalAssets} event.
    ///
    /// @param totalAssets_ New total assets value
    function setTotalAssets(uint256 totalAssets_)
        external
        onlyRole(KEEPER_ROLE)
    {
        _totalAssets = totalAssets_;

        emit TotalAssets(totalAssets_);
    }

    /// @notice Pause contract
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause contract
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /*************/
    /* Admin API */
    /*************/

    /// @notice Approves asset to spender
    /// @param spender Spender address
    /// @param amount Approve amount
    function approveAsset(address spender, uint256 amount) external {
        require(
            hasRole(BIDDER_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
        );
        _checkRole(MARKETPLACE_ROLE, spender);
        _asset.approve(spender, amount);
    }

    /// @notice Transfer NFT out of vault
    /// @param nft NFT contract address
    /// @param nftId NFT token ID
    function transferNFT(address nft, uint256 nftId)
        external
        onlyRole(LIQUIDATOR_ROLE)
    {
        IERC721Upgradeable token = IERC721Upgradeable(nft);
        require(token.ownerOf(nftId) == address(this));

        token.safeTransferFrom(address(this), msg.sender, nftId);
    }

    /************/
    /* ERC-1271 */
    /************/

    /// See {IERC1271-isValidSignature}
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue)
    {
        // Validate signatures
        (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(
            hash,
            signature
        );
        if (
            err == ECDSA.RecoverError.NoError &&
            signer == getRoleMember(DEFAULT_ADMIN_ROLE, 0)
        ) {
            // bytes4(keccak256("isValidSignature(bytes32,bytes)")
            return 0x1626ba7e;
        } else {
            return 0xffffffff;
        }
    }
}