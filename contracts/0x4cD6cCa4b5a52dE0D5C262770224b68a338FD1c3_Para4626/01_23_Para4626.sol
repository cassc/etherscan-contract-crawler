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
import "../interfaces/IPoolCore.sol";
import "../interfaces/ITimeLock.sol";

/**
 * @title Storage for Para4626
 * @author Spice Finance Inc
 */
abstract contract Para4626Storage {
    /// @notice ParaPool address
    address public poolAddress;

    /// @notice BToken address
    address public lpTokenAddress;
}

/**
 * @title Storage v2 for Para4626
 * @author Spice Finance Inc
 */
abstract contract Para4626StorageV2 {
    /// @notice TimeLock address
    address public timelock;

    /// @notice Indicates if there's pending withdrawl
    bool internal dirty;

    /// @notice Last totalAssets before initiating withdrawl
    uint256 internal lastTotalAssets;

    /// @notice Beneficiary address
    address internal beneficiary;

    /// @notice Claim amount
    uint256 internal claimAmount;
}

/**
 * @title ERC4626 Wrapper for ParaPool
 * @author Spice Finance Inc
 */
contract Para4626 is
    Para4626Storage,
    Initializable,
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlEnumerableUpgradeable,
    Para4626StorageV2
{
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /*************/
    /* Constants */
    /*************/

    /// @notice WETH address
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice Whitelist role
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

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

    /**********/
    /* Errors */
    /**********/

    /// @notice Invalid address (e.g. zero address)
    error InvalidAddress();

    /// @notice Parameter out of bounds
    error ParameterOutOfBounds();

    /// @notice Less withdrawn from the pool
    error LessWithdrawn();

    /***************/
    /* Constructor */
    /***************/

    /// @notice Para4626 constructor (for proxy)
    /// @param name_ Receipt token name
    /// @param symbol_ Receipt token symbol
    /// @param poolAddress_ LendPool address
    /// @param lpTokenAddress_ BToken address
    /// @param timelock_ TimeLock address
    function initialize(
        string calldata name_,
        string calldata symbol_,
        address poolAddress_,
        address lpTokenAddress_,
        address timelock_
    ) external initializer {
        if (poolAddress_ == address(0)) {
            revert InvalidAddress();
        }
        if (lpTokenAddress_ == address(0)) {
            revert InvalidAddress();
        }
        if (timelock_ == address(0)) {
            revert InvalidAddress();
        }

        __ERC20_init(name_, symbol_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        poolAddress = poolAddress_;

        lpTokenAddress = lpTokenAddress_;

        timelock = timelock_;
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
        if (dirty) return lastTotalAssets;
        return IERC20Upgradeable(lpTokenAddress).balanceOf(address(this));
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
            _convertToAssets(balanceOf(owner), MathUpgradeable.Rounding.Down);
    }

    /// @notice See {IERC4626-maxRedeem}
    function maxRedeem(address owner) external view returns (uint256) {
        return balanceOf(owner);
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

    /***********/
    /* Setters */
    /***********/

    /// @notice Set timelock contract address
    /// @param _timelock TimeLock address
    function setTimeLock(
        address _timelock
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_timelock == address(0)) {
            revert InvalidAddress();
        }
        timelock = _timelock;
    }

    /******************/
    /* User Functions */
    /******************/

    /// @notice Deposits weth into Bend pool and receive receipt tokens
    /// @param assets The amount of weth being deposited
    /// @param receiver The account that will receive the receipt tokens
    /// @return shares The amount of receipt tokens minted
    function deposit(
        uint256 assets,
        address receiver
    ) external nonReentrant onlyRole(WHITELIST_ROLE) returns (uint256 shares) {
        if (assets == 0) {
            revert ParameterOutOfBounds();
        }
        if (receiver == address(0)) {
            revert InvalidAddress();
        }

        shares = previewDeposit(assets);

        _deposit(assets, shares, receiver);
    }

    /// @notice Deposits weth into Bend pool and receive receipt tokens
    /// @param shares The amount of receipt tokens to mint
    /// @param receiver The account that will receive the receipt tokens
    /// @return assets The amount of weth deposited
    function mint(
        uint256 shares,
        address receiver
    ) external nonReentrant onlyRole(WHITELIST_ROLE) returns (uint256 assets) {
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }
        if (receiver == address(0)) {
            revert InvalidAddress();
        }

        assets = previewMint(shares);

        _deposit(assets, shares, receiver);
    }

    /// @notice Withdraw weth from the pool
    /// @param assets The amount of weth being withdrawn
    /// @param receiver The account that will receive weth
    /// @param owner The account that will pay receipt tokens
    /// @return shares The amount of shares burnt
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external nonReentrant onlyRole(WHITELIST_ROLE) returns (uint256 shares) {
        if (receiver == address(0)) {
            revert InvalidAddress();
        }
        if (assets == 0) {
            revert ParameterOutOfBounds();
        }

        shares = previewWithdraw(assets);

        _withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /// @notice Withdraw weth from the pool
    /// @param shares The amount of receipt tokens being burnt
    /// @param receiver The account that will receive weth
    /// @param owner The account that will pay receipt tokens
    /// @return assets The amount of assets redeemed
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external nonReentrant onlyRole(WHITELIST_ROLE) returns (uint256 assets) {
        if (receiver == address(0)) {
            revert InvalidAddress();
        }
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        assets = previewRedeem(shares);

        _withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /// @notice Claim WETH from Paraspace
    /// @param agreementIds Agreement IDs to claim
    function claim(
        uint256[] memory agreementIds
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ITimeLock(timelock).claim(agreementIds);
        dirty = false;

        // load weth
        IERC20Upgradeable weth = IERC20Upgradeable(WETH);

        // transfer to beneficiary
        weth.safeTransfer(beneficiary, claimAmount);
        // resset beneficiary and claimAmount
        delete beneficiary;
        delete claimAmount;
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
        // load weth
        IERC20Upgradeable weth = IERC20Upgradeable(WETH);

        // receive weth from msg.sender
        weth.safeTransferFrom(msg.sender, address(this), assets);

        // approve weth deposit into underlying marketplace
        weth.safeApprove(poolAddress, 0);
        weth.safeApprove(poolAddress, assets);

        // deposit into underlying marketplace
        IPoolCore(poolAddress).supply(WETH, assets, address(this), 0);

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

        lastTotalAssets = totalAssets();
        dirty = true;

        // Burn receipt tokens from owner
        _burn(owner, shares);

        // get lp token contract
        IERC20Upgradeable pWETH = IERC20Upgradeable(lpTokenAddress);

        pWETH.safeApprove(poolAddress, 0);
        pWETH.safeApprove(poolAddress, assets);

        // withdraw weth from the pool and send it to `receiver`
        uint256 withdrawn = IPoolCore(poolAddress).withdraw(WETH, assets, address(this));

        if (assets != withdrawn) {
            revert LessWithdrawn();
        }

        claimAmount = assets;
        beneficiary = receiver;

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }
}