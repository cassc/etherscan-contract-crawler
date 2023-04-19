// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

import "../interfaces/ISpiceFiNFT4626.sol";
import "../interfaces/IAggregatorVault.sol";
import "../interfaces/IERC4906.sol";
import "../interfaces/IWETH.sol";

/**
 * @title Storage for SpiceFiNFT4626
 * @author Spice Finance Inc
 */
abstract contract SpiceFiNFT4626Storage {
    /// @notice withdrawal fees per 10_000 units
    uint256 public withdrawalFees;

    /// @notice Total shares
    uint256 public totalShares;

    /// @notice Mapping TokenId => Shares
    mapping(uint256 => uint256) public tokenShares;

    /// @notice Indicates whether the vault is verified or not
    bool public verified;

    /// @notice Spice dev wallet
    address public dev;

    /// @notice Spice Multisig address
    address public multisig;

    /// @notice Fee recipient address
    address public feeRecipient;

    /// @notice NFT mint price
    uint256 public mintPrice;

    /// @notice Max totla supply
    uint256 public maxSupply;

    /// @notice Token ID Pointer
    uint256 internal _tokenIdPointer;

    /// @notice Preview Metadata URI
    string internal _previewUri;

    /// @notice Metadata URI
    string internal _baseUri;

    /// @notice Asset token address
    address internal _asset;

    /// @notice Revealed;
    bool internal _revealed;

    /// @notice Withdrawable
    bool internal _withdrawable;
}

/**
 * @title Storage for SpiceFiNFT4626
 * @author Spice Finance Inc
 */
abstract contract SpiceFiNFT4626StorageV2 {
    uint256 public lastTotalAssets;
    uint256 public lastTotalShares;
}

/**
 * @title SpiceFiNFT4626
 * @author Spice Finance Inc
 */
contract SpiceFiNFT4626 is
    ISpiceFiNFT4626,
    IAggregatorVault,
    SpiceFiNFT4626Storage,
    ERC721Upgradeable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    Multicall,
    IERC4906,
    SpiceFiNFT4626StorageV2
{
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using StringsUpgradeable for uint256;
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

    /// @notice More than one NFT
    error MoreThanOne();

    /// @notice MAX_SUPPLY NFTs are minted
    error OutOfSupply();

    /// @notice User not owning token
    error InvalidTokenId();

    /// @notice Metadata revealed
    error MetadataRevealed();

    /// @notice Withdraw before reveal
    error WithdrawBeforeReveal();

    /// @notice Withdraw is disabled
    error WithdrawDisabled();

    /// @notice Insolvent
    error Insolvent();

    /// @notice Insufficient share balance
    error InsufficientShareBalance();

    /// @notice Slippage too high
    error SlippageTooHigh();

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

    /// @notice SpiceFiNFT4626 constructor (for proxy)
    /// @param _name Token name
    /// @param _symbol Token symbol
    /// @param __asset Asset token address
    /// @param _mintPrice NFT mint price
    /// @param _maxSupply Max total supply
    /// @param _vaults Vault addresses
    /// @param _creator Creator address
    /// @param _dev Spice dev wallet
    /// @param _multisig Spice multisig wallet
    /// @param _feeRecipient Initial fee recipient address
    function initialize(
        string memory _name,
        string memory _symbol,
        address __asset,
        uint256 _mintPrice,
        uint256 _maxSupply,
        address[] memory _vaults,
        address _creator,
        address _dev,
        address _multisig,
        address _feeRecipient
    ) public initializer {
        if (__asset == address(0)) {
            revert InvalidAddress();
        }
        if (_maxSupply == 0) {
            revert ParameterOutOfBounds();
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

        __ERC721_init(_name, _symbol);

        _asset = __asset;
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
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

        dev = _dev;

        _setupRole(DEFAULT_ADMIN_ROLE, _dev);
        _setupRole(STRATEGIST_ROLE, _dev);

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
        _revokeRole(SPICE_ROLE, oldMultisig);

        multisig = _multisig;

        _setupRole(DEFAULT_ADMIN_ROLE, _multisig);
        _setupRole(ASSET_RECEIVER_ROLE, _multisig);
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

    /// @notice Sets preview uri
    /// @param previewUri New preview uri
    function setPreviewURI(
        string memory previewUri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_revealed) {
            revert MetadataRevealed();
        }
        _previewUri = previewUri;
        if (_tokenIdPointer > 0) {
            emit BatchMetadataUpdate(1, _tokenIdPointer);
        }
    }

    /// @notice Sets base uri and reveal
    /// @param baseUri Metadata base uri
    function setBaseURI(
        string memory baseUri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revealed = true;
        _baseUri = baseUri;
        if (_tokenIdPointer > 0) {
            emit BatchMetadataUpdate(1, _tokenIdPointer);
        }
    }

    /// @notice Set verified
    /// @param verified_ New verified value
    function setVerified(bool verified_) external onlyRole(SPICE_ROLE) {
        verified = verified_;
    }

    /// @notice Set withdrawable
    /// @param withdrawable_ New withdrawable value
    function setWithdrawable(
        bool withdrawable_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _withdrawable = withdrawable_;
    }

    /// @notice trigger paused state
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice return to normal state
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /***********/
    /* Getters */
    /***********/

    /// @notice See {ISpiceFiNFT4626-asset}
    function asset() public view returns (address) {
        return _asset;
    }

    /// @notice See {ISpiceFiNFT4626-totalAssets}
    function totalAssets() public view returns (uint256) {
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

    /// @notice See {ISpiceFiNFT4626-convertToShares}
    function convertToShares(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    /// @notice See {ISpiceFiNFT4626-convertToAssets}
    function convertToAssets(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    /// @notice See {ISpiceFiNFT4626-maxDeposit}
    function maxDeposit(address) public view override returns (uint256) {
        return paused() ? 0 : type(uint256).max;
    }

    /// @notice See {ISpiceFiNFT4626-maxMint}
    function maxMint(address) public view override returns (uint256) {
        return paused() ? 0 : type(uint256).max;
    }

    /// @notice See {ISpiceFiNFT4626-maxWithdraw}
    function maxWithdraw(address) public view override returns (uint256) {
        uint256 balance = IERC20Upgradeable(asset()).balanceOf(address(this));
        return paused() ? 0 : balance;
    }

    /// @notice See {ISpiceFiNFT4626-maxRedeem}
    function maxRedeem(address) public view override returns (uint256) {
        return paused() ? 0 : totalShares;
    }

    /// @notice See {ISpiceFiNFT4626-previewDeposit}
    function previewDeposit(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    /// @notice See {ISpiceFiNFT4626-previewMint}
    function previewMint(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Up);
    }

    /// @notice See {ISpiceFiNFT4626-previewWithdraw}
    function previewWithdraw(
        uint256 assets
    ) public view override returns (uint256) {
        (uint256 _totalAssets, uint256 interestEarned) = _interestEarned();
        uint256 fees = (interestEarned * withdrawalFees) / 10_000;
        return
            (assets == 0 || totalShares == 0)
                ? assets
                : assets.mulDiv(
                    totalShares,
                    _totalAssets - fees,
                    MathUpgradeable.Rounding.Up
                );
    }

    /// @notice See {ISpiceFiNFT4626-previewRedeem}
    function previewRedeem(
        uint256 shares
    ) public view override returns (uint256) {
        (uint256 _totalAssets, uint256 interestEarned) = _interestEarned();
        uint256 fees = (interestEarned * withdrawalFees) / 10_000;
        return
            totalShares == 0
                ? shares
                : shares.mulDiv(
                    _totalAssets - fees,
                    totalShares,
                    MathUpgradeable.Rounding.Down
                );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return
            interfaceId == bytes4(0x49064906) ||
            super.supportsInterface(interfaceId);
    }

    function contractURI() public pure returns (string memory) {
        return "https://b3ec853c.spicefi.xyz/metadata/os";
    }

    /// @notice See {IERC721Metadata-tokenURI}.
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);

        if (!_revealed) {
            string memory previewURI = _previewUri;
            return
                bytes(previewURI).length > 0
                    ? string(abi.encodePacked(previewURI, tokenId.toString()))
                    : "";
        }

        string memory baseURI = _baseUri;
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /// @notice Return total supply
    /// @return totalSupply Current total supply
    function totalSupply() external view returns (uint256) {
        return _tokenIdPointer;
    }

    /******************/
    /* User Functions */
    /******************/

    /// See {ISpiceFiNFT4626-deposit}.
    function deposit(
        uint256 tokenId,
        uint256 assets
    ) external whenNotPaused nonReentrant returns (uint256 shares) {
        if (tokenId == 0 && assets <= mintPrice) {
            revert ParameterOutOfBounds();
        }

        // Compute number of shares to mint from current vault share price
        shares = previewDeposit(tokenId == 0 ? assets - mintPrice : assets);
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        IERC20Upgradeable(_asset).safeTransferFrom(
            msg.sender,
            address(this),
            assets
        );

        if (tokenId == 0) {
            _transferMintFee();
            assets -= mintPrice;
        }

        _deposit(msg.sender, tokenId, assets, shares);
    }

    /// See {ISpiceFiNFT4626-mint}.
    function mint(
        uint256 tokenId,
        uint256 shares
    ) external whenNotPaused nonReentrant returns (uint256 assets) {
        // Compute number of shares to mint from current vault share price
        assets = previewMint(shares);
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        IERC20Upgradeable(_asset).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId == 0 ? assets + mintPrice : assets
        );

        if (tokenId == 0) {
            _transferMintFee();
        }

        _deposit(msg.sender, tokenId, assets, shares);
    }

    /// See {ISpiceFiNFT4626-redeem}.
    function redeem(
        uint256 tokenId,
        uint256 shares,
        address receiver
    ) external whenNotPaused nonReentrant takeFees returns (uint256 assets) {
        if (tokenId == 0) {
            revert ParameterOutOfBounds();
        }
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }
        if (receiver == address(0)) {
            revert InvalidAddress();
        }

        // compute redemption amount
        assets = _convertToAssets(shares, MathUpgradeable.Rounding.Down);

        _withdraw(msg.sender, tokenId, receiver, assets, shares);

        IERC20Upgradeable(_asset).safeTransfer(receiver, assets);
    }

    /// See {ISpiceFiNFT4626-withdraw}.
    function withdraw(
        uint256 tokenId,
        uint256 assets,
        address receiver
    ) external whenNotPaused nonReentrant takeFees returns (uint256 shares) {
        if (tokenId == 0) {
            revert ParameterOutOfBounds();
        }
        if (assets == 0) {
            revert ParameterOutOfBounds();
        }
        if (receiver == address(0)) {
            revert InvalidAddress();
        }

        // compute share amount
        shares = _convertToShares(assets, MathUpgradeable.Rounding.Up);

        _withdraw(msg.sender, tokenId, receiver, assets, shares);

        IERC20Upgradeable(_asset).safeTransfer(receiver, assets);
    }

    /// See {ISpiceFiNFT4626-depositETH}.
    function depositETH(
        uint256 tokenId
    ) external payable whenNotPaused nonReentrant returns (uint256 shares) {
        uint256 assets = msg.value;
        if (tokenId == 0 && assets <= mintPrice) {
            revert ParameterOutOfBounds();
        }

        // Compute number of shares to mint from current vault share price
        shares = previewDeposit(tokenId == 0 ? assets - mintPrice : assets);
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        IWETH(_asset).deposit{value: msg.value}();

        if (tokenId == 0) {
            _transferMintFee();
            assets -= mintPrice;
        }

        _deposit(msg.sender, tokenId, assets, shares);
    }

    /// See {ISpiceFiNFT4626-mintETH}.
    function mintETH(
        uint256 tokenId,
        uint256 shares
    ) external payable whenNotPaused nonReentrant returns (uint256 assets) {
        // Compute number of shares to mint from current vault share price
        assets = previewMint(shares);
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        uint256 transferAmount = tokenId == 0 ? assets + mintPrice : assets;
        if (msg.value < transferAmount) {
            revert ParameterOutOfBounds();
        }

        IWETH(_asset).deposit{value: transferAmount}();

        if (tokenId == 0) {
            _transferMintFee();
        }

        if (msg.value > transferAmount) {
            (bool success, ) = msg.sender.call{
                value: msg.value - transferAmount
            }("");
            if (!success) {
                revert RefundFailed();
            }
        }

        _deposit(msg.sender, tokenId, assets, shares);
    }

    /// See {ISpiceFiNFT4626-redeemETH}.
    function redeemETH(
        uint256 tokenId,
        uint256 shares,
        address receiver
    ) external whenNotPaused nonReentrant takeFees returns (uint256 assets) {
        if (tokenId == 0) {
            revert ParameterOutOfBounds();
        }
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }
        if (receiver == address(0)) {
            revert InvalidAddress();
        }

        // compute redemption amount
        assets = _convertToAssets(shares, MathUpgradeable.Rounding.Down);

        _withdraw(msg.sender, tokenId, receiver, assets, shares);

        IWETH(_asset).withdraw(assets);
        (bool success, ) = receiver.call{value: assets}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    /// See {ISpiceFiNFT4626-withdrawETH}.
    function withdrawETH(
        uint256 tokenId,
        uint256 assets,
        address receiver
    ) external whenNotPaused nonReentrant takeFees returns (uint256 shares) {
        if (tokenId == 0) {
            revert ParameterOutOfBounds();
        }
        if (assets == 0) {
            revert ParameterOutOfBounds();
        }
        if (receiver == address(0)) {
            revert InvalidAddress();
        }

        // compute share amount
        shares = _convertToShares(assets, MathUpgradeable.Rounding.Up);

        _withdraw(msg.sender, tokenId, receiver, assets, shares);

        IWETH(_asset).withdraw(assets);
        (bool success, ) = receiver.call{value: assets}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    /*****************************/
    /* Internal Helper Functions */
    /*****************************/

    function _convertToShares(
        uint256 assets,
        MathUpgradeable.Rounding rounding
    ) internal view returns (uint256 shares) {
        uint256 _totalShares = totalShares;
        return
            (assets == 0 || _totalShares == 0)
                ? assets
                : assets.mulDiv(_totalShares, totalAssets(), rounding);
    }

    function _convertToAssets(
        uint256 shares,
        MathUpgradeable.Rounding rounding
    ) internal view returns (uint256 assets) {
        uint256 _totalShares = totalShares;
        return
            (_totalShares == 0)
                ? shares
                : shares.mulDiv(totalAssets(), _totalShares, rounding);
    }

    function _mintInternal(address user) internal returns (uint256 tokenId) {
        if (balanceOf(user) > 0) {
            revert MoreThanOne();
        }

        if (_tokenIdPointer == maxSupply) {
            revert OutOfSupply();
        }

        unchecked {
            tokenId = ++_tokenIdPointer;
        }

        _mint(user, tokenId);
    }

    function _transferMintFee() internal {
        address admin = getRoleMember(SPICE_ROLE, 0);
        IERC20Upgradeable(_asset).safeTransfer(admin, mintPrice);
    }

    function _withdraw(
        address caller,
        uint256 tokenId,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal {
        if (!_revealed) {
            revert WithdrawBeforeReveal();
        }
        if (!_withdrawable) {
            revert WithdrawDisabled();
        }
        if (ownerOf(tokenId) != caller) {
            revert InvalidTokenId();
        }

        if (tokenShares[tokenId] < shares) {
            revert InsufficientShareBalance();
        }

        totalShares -= shares;
        tokenShares[tokenId] -= shares;

        IERC20Upgradeable currency = IERC20Upgradeable(_asset);
        uint256 balance = currency.balanceOf(address(this));
        if (balance < assets) {
            // withdraw from vaults
            _withdrawFromVaults(assets - balance);
        }

        emit Withdraw(caller, tokenId, receiver, assets, shares);
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

    function _deposit(
        address caller,
        uint256 tokenId,
        uint256 assets,
        uint256 shares
    ) internal {
        if (tokenId == 0) {
            // mints new NFT
            tokenId = _mintInternal(caller);
        } else if (ownerOf(tokenId) != caller) {
            revert InvalidTokenId();
        }

        tokenShares[tokenId] += shares;
        totalShares += shares;

        emit Deposit(caller, tokenId, assets, shares);
    }

    function _takeFees() internal {
        (uint256 _totalAssets, uint256 interestEarned) = _interestEarned();

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
        lastTotalShares = totalShares;
    }

    function _interestEarned()
        internal
        view
        returns (uint256 _totalAssets, uint256 interestEarned)
    {
        _totalAssets = totalAssets();

        if (lastTotalShares == 0) {
            interestEarned = _totalAssets > totalShares
                ? (_totalAssets - totalShares)
                : 0;
        } else {
            uint256 adjusted = (lastTotalAssets * totalShares) /
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
            IERC20MetadataUpgradeable(asset()),
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
            IERC20MetadataUpgradeable(asset()),
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

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    /*************/
    /* Fallbacks */
    /*************/

    receive() external payable {}
}