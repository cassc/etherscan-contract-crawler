// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "../interfaces/IWETH.sol";

/**
 * @title Storage for Blur4626
 * @author Spice Finance Inc
 */
abstract contract Blur4626Storage {
    /// @notice Blur bidder address
    address public bidder;

    /// @dev Total assets
    uint256 internal _totalAssets;
}

/**
 * @title ERC4626 Wrapper for Blur Bidder
 * @author Spice Finance Inc
 */
contract Blur4626 is
    Initializable,
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlEnumerableUpgradeable,
    Blur4626Storage
{
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /*************/
    /* Constants */
    /*************/

    /// @notice WETH address
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /**********/
    /* Events */
    /**********/

    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /// @notice Emitted when totalAssets is updated
    /// @param totalAssets Total assets
    event TotalAssets(uint256 totalAssets);

    /**********/
    /* Errors */
    /**********/

    /// @notice Invalid address (e.g. zero address)
    error InvalidAddress();

    /// @notice Parameter out of bounds
    error ParameterOutOfBounds();

    /// @notice Refund failed
    error RefundFailed();

    /// @notice Deposit failed
    error DepositFailed();

    /// @notice Withdraw failed
    error WithdrawFailed();

    /***************/
    /* Constructor */
    /***************/

    /// @notice Blur4626 constructor (for proxy)
    /// @param name_ Receipt token name
    /// @param symbol_ Receipt token symbol
    /// @param bidder_ Blur bidder address
    function initialize(
        string calldata name_,
        string calldata symbol_,
        address bidder_
    ) external initializer {
        if (bidder_ == address(0)) {
            revert InvalidAddress();
        }

        __ERC20_init(name_, symbol_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        bidder = bidder_;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /***********/
    /* Getters */
    /***********/

    /// @notice Get underlying token address
    function asset() external pure returns (address) {
        return WETH;
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
            MathUpgradeable.min(
                _convertToAssets(
                    balanceOf(owner),
                    MathUpgradeable.Rounding.Down
                ),
                IERC20Upgradeable(WETH).balanceOf(bidder)
            );
    }

    /// @notice See {IERC4626-maxRedeem}
    function maxRedeem(address owner) external view returns (uint256) {
        return
            MathUpgradeable.min(
                balanceOf(owner),
                _convertToShares(
                    IERC20Upgradeable(WETH).balanceOf(bidder),
                    MathUpgradeable.Rounding.Down
                )
            );
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
        return _convertToShares(assets, MathUpgradeable.Rounding.Up);
    }

    /// @notice See {IERC4626-previewRedeem}
    function previewRedeem(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    /******************/
    /* User Functions */
    /******************/

    /// @notice Deposits WETH into the pool and receive receipt tokens
    /// @param assets The amount of WETH being deposited
    /// @param receiver The account that will receive the receipt tokens
    /// @return shares The amount of receipt tokens minted
    function deposit(
        uint256 assets,
        address receiver
    ) external nonReentrant returns (uint256 shares) {
        if (assets == 0) {
            revert ParameterOutOfBounds();
        }
        if (receiver == address(0)) {
            revert InvalidAddress();
        }

        shares = previewDeposit(assets);
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        // Transfer WETH from user to vault
        IERC20Upgradeable(WETH).safeTransferFrom(
            msg.sender,
            address(this),
            assets
        );
        // Convert WETH to ETH
        IWETH(WETH).withdraw(assets);

        _deposit(assets, shares, receiver);
    }

    /// @notice Deposits WETH into the pool and receive receipt tokens
    /// @param shares The amount of receipt tokens to mint
    /// @param receiver The account that will receive the receipt tokens
    /// @return assets The amount of WETH deposited
    function mint(
        uint256 shares,
        address receiver
    ) external nonReentrant returns (uint256 assets) {
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }
        if (receiver == address(0)) {
            revert InvalidAddress();
        }

        assets = previewMint(shares);

        // Transfer cash from user to vault
        IERC20Upgradeable(WETH).safeTransferFrom(
            msg.sender,
            address(this),
            assets
        );
        // Convert WETH to ETH
        IWETH(WETH).withdraw(assets);

        _deposit(assets, shares, receiver);
    }

    /// @notice Withdraw WETH from the pool
    /// @param assets The amount of WETH being withdrawn
    /// @param receiver The account that will receive WETH
    /// @param owner The account that will pay receipt tokens
    /// @return shares The amount of shares burnt
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external nonReentrant returns (uint256 shares) {
        if (receiver == address(0)) {
            revert InvalidAddress();
        }
        if (assets == 0) {
            revert ParameterOutOfBounds();
        }

        shares = previewWithdraw(assets);

        _withdraw(msg.sender, receiver, owner, assets, shares);

        IERC20Upgradeable(WETH).safeTransfer(receiver, assets);
    }

    /// @notice Withdraw WETH from the pool
    /// @param shares The amount of receipt tokens being burnt
    /// @param receiver The account that will receive WETH
    /// @param owner The account that will pay receipt tokens
    /// @return assets The amount of assets redeemed
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external nonReentrant returns (uint256 assets) {
        if (receiver == address(0)) {
            revert InvalidAddress();
        }
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        assets = previewRedeem(shares);

        _withdraw(msg.sender, receiver, owner, assets, shares);

        IERC20Upgradeable(WETH).safeTransfer(receiver, assets);
    }

    /// @notice Deposits ETH into pool and receive receipt tokens
    /// @param receiver The account that will receive the receipt tokens
    /// @return shares The amount of receipt tokens minted
    function depositETH(
        address receiver
    ) external payable nonReentrant returns (uint256 shares) {
        uint256 assets = msg.value;

        // Validate amount
        if (assets == 0) {
            revert ParameterOutOfBounds();
        }
        if (receiver == address(0)) {
            revert InvalidAddress();
        }

        // Compute number of shares to mint from current vault share price
        shares = previewDeposit(assets);
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        _deposit(assets, shares, receiver);
    }

    /// @notice Deposits WETH into the pool and receive receipt tokens
    /// @param shares The amount of receipt tokens to mint
    /// @param receiver The account that will receive the receipt tokens
    /// @return assets The amount of WETH deposited
    function mintETH(
        uint256 shares,
        address receiver
    ) external payable nonReentrant returns (uint256 assets) {
        assets = previewMint(shares);
        // Validate amount
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }
        if (receiver == address(0)) {
            revert InvalidAddress();
        }

        if (msg.value < assets) {
            revert ParameterOutOfBounds();
        } else if (msg.value > assets) {
            (bool success, ) = msg.sender.call{value: msg.value - assets}("");
            if (!success) {
                revert RefundFailed();
            }
        }

        _deposit(assets, shares, receiver);
    }

    /// @notice Withdraw ETH from the pool
    /// @param assets The amount of ETH being withdrawn
    /// @param receiver The account that will receive ETH
    /// @param owner The account that will pay receipt tokens
    /// @return shares The amount of shares burnt
    function withdrawETH(
        uint256 assets,
        address receiver,
        address owner
    ) external nonReentrant returns (uint256 shares) {
        if (receiver == address(0)) {
            revert InvalidAddress();
        }
        if (assets == 0) {
            revert ParameterOutOfBounds();
        }

        // compute share amount
        shares = _convertToShares(assets, MathUpgradeable.Rounding.Up);

        _withdraw(msg.sender, receiver, owner, assets, shares);

        IWETH(WETH).withdraw(assets);
        (bool success, ) = receiver.call{value: assets}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    /// @notice Withdraw ETH from the pool
    /// @param shares The amount of receipt tokens being burnt
    /// @param receiver The account that will receive ETH
    /// @param owner The account that will pay receipt tokens
    /// @return assets The amount of assets redeemed
    function redeemETH(
        uint256 shares,
        address receiver,
        address owner
    ) external nonReentrant returns (uint256 assets) {
        if (receiver == address(0)) {
            revert InvalidAddress();
        }
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        // compute redemption amount
        assets = _convertToAssets(shares, MathUpgradeable.Rounding.Down);

        _withdraw(msg.sender, receiver, owner, assets, shares);

        IWETH(WETH).withdraw(assets);
        (bool success, ) = receiver.call{value: assets}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    /***********/
    /* Setters */
    /***********/

    /// @notice Set total assets
    ///
    /// Emits a {TotalAssets} event.
    ///
    /// @param totalAssets_ New total assets value
    function setTotalAssets(
        uint256 totalAssets_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _totalAssets = totalAssets_;

        emit TotalAssets(totalAssets_);
    }

    /*****************************/
    /* Internal Helper Functions */
    /*****************************/

    /// @dev Get estimated share amount for assets
    /// @param assets Asset token amount
    /// @param rounding Rounding mode
    /// @return shares Share amount
    function _convertToShares(
        uint256 assets,
        MathUpgradeable.Rounding rounding
    ) internal view returns (uint256 shares) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? assets
                : assets.mulDiv(supply, totalAssets(), rounding);
    }

    /// @dev Get estimated share amount for assets
    /// @param shares Share amount
    /// @param rounding Rounding mode
    /// @return assets Asset token amount
    function _convertToAssets(
        uint256 shares,
        MathUpgradeable.Rounding rounding
    ) internal view returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0)
                ? shares
                : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /// @dev Deposit/mint common workflow.
    function _deposit(
        uint256 assets,
        uint256 shares,
        address receiver
    ) internal {
        // Increase total assets value of vault
        _totalAssets += assets;

        // sent ETH to bidder
        (bool success, ) = bidder.call{value: assets}("");
        if (!success) {
            revert DepositFailed();
        }

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
        uint256 shares
    ) internal {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // Burn receipt tokens from owner
        _burn(owner, shares);

        _totalAssets -= assets;

        IERC20Upgradeable(WETH).safeTransferFrom(bidder, address(this), assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /*************/
    /* Fallbacks */
    /*************/

    receive() external payable {}
}