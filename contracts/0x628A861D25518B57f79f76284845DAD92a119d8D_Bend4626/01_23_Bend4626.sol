// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "../interfaces/IWETH.sol";
import "../interfaces/IBendLendPool.sol";
import "../interfaces/uniswap/IUniswapV2Router02.sol";

interface IBendIncentivesController {
    function getRewardsBalance(
        address[] calldata _assets,
        address _user
    ) external view returns (uint256);

    function claimRewards(
        address[] calldata _assets,
        uint256 _amount
    ) external returns (uint256);
}

/**
 * @title Storage for Bend4626
 * @author Spice Finance Inc
 */
abstract contract Bend4626Storage {
    /// @notice LendPool address
    address public poolAddress;

    /// @notice BToken address
    address public lpTokenAddress;

    /// @dev Token decimals
    uint8 internal _decimals;
}

/**
 * @title More Storage for Bend4626
 * @author Spice Finance Inc
 */
abstract contract MoreBend4626Storage {
    /// @notice Minimum reward claim amount
    uint256 public minRewardClaim;
}

/**
 * @title ERC4626 Wrapper for BendLendPool
 * @author Spice Finance Inc
 */
contract Bend4626 is
    Bend4626Storage,
    Initializable,
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlEnumerableUpgradeable,
    MoreBend4626Storage
{
    using MathUpgradeable for uint256;

    /*************/
    /* Constants */
    /*************/

    /// @notice Bend Incentives Controller address
    address public constant BEND_INCENTIVES_CONTROLLER =
        0x26FC1f11E612366d3367fc0cbFfF9e819da91C8d;

    /// @notice WETH address
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IERC20Upgradeable public constant BEND =
        IERC20Upgradeable(0x0d02755a5700414B26FF040e1dE35D337DF56218);

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

    /// @notice Not enough reward balance
    error NotEnoughRewardBalance();

    /***************/
    /* Constructor */
    /***************/

    /// @notice Bend4626 constructor (for proxy)
    /// @param name_ Receipt token name
    /// @param symbol_ Receipt token symbol
    /// @param poolAddress_ LendPool address
    /// @param lpTokenAddress_ BToken address
    function initialize(
        string calldata name_,
        string calldata symbol_,
        address poolAddress_,
        address lpTokenAddress_
    ) external initializer {
        if (poolAddress_ == address(0)) {
            revert InvalidAddress();
        }
        if (lpTokenAddress_ == address(0)) {
            revert InvalidAddress();
        }

        __ERC20_init(name_, symbol_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        poolAddress = poolAddress_;

        lpTokenAddress = lpTokenAddress_;
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
    ) external nonReentrant returns (uint256 shares) {
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
    ) external nonReentrant returns (uint256 assets) {
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
    ) external nonReentrant returns (uint256 shares) {
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
    ) external nonReentrant returns (uint256 assets) {
        if (receiver == address(0)) {
            revert InvalidAddress();
        }
        if (shares == 0) {
            revert ParameterOutOfBounds();
        }

        assets = previewRedeem(shares);

        _withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /***********/
    /* Setters */
    /***********/

    /// @notice Set the minimum reward claim amount
    /// @param _minRewardClaim Minimum reward claim amount
    function setMinRewardClaim(
        uint256 _minRewardClaim
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minRewardClaim = _minRewardClaim;
    }

    /********************/
    /* Reward Functions */
    /********************/

    /// @notice Return the pending reward balance
    /// @return rewardBalance Pending reward balance
    function getRewardsBalance() public view returns (uint256) {
        address[] memory assets = new address[](1);
        assets[0] = lpTokenAddress;
        return
            IBendIncentivesController(BEND_INCENTIVES_CONTROLLER)
                .getRewardsBalance(assets, address(this));
    }

    /// @notice Claim pending rewards
    function claimReward() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 rewardBalance = getRewardsBalance();
        if (rewardBalance < minRewardClaim) {
            revert NotEnoughRewardBalance();
        }
        address[] memory assets = new address[](1);
        assets[0] = lpTokenAddress;
        IBendIncentivesController(BEND_INCENTIVES_CONTROLLER).claimRewards(
            assets,
            rewardBalance
        );

        BEND.approve(address(UNISWAP_V2_ROUTER), rewardBalance);
        address[] memory path = new address[](2);
        path[0] = address(BEND);
        path[1] = WETH;
        uint256[] memory amounts = UNISWAP_V2_ROUTER.swapExactTokensForTokens(
            rewardBalance,
            0,
            path,
            address(this),
            block.timestamp
        );

        // load weth
        IWETH weth = IWETH(WETH);

        // approve weth deposit into underlying marketplace
        weth.approve(poolAddress, amounts[0]);

        // deposit into underlying marketplace
        IBendLendPool(poolAddress).deposit(WETH, amounts[0], address(this), 0);
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
        IWETH weth = IWETH(WETH);

        // receive weth from msg.sender
        weth.transferFrom(msg.sender, address(this), assets);

        // approve weth deposit into underlying marketplace
        weth.approve(poolAddress, assets);

        // deposit into underlying marketplace
        IBendLendPool(poolAddress).deposit(WETH, assets, address(this), 0);

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

        // get lp token contract
        IERC20Upgradeable bToken = IERC20Upgradeable(lpTokenAddress);

        // approve AToken's withdraw from the pool
        bToken.approve(poolAddress, assets);

        // withdraw weth from the pool and send it to `receiver`
        IBendLendPool(poolAddress).withdraw(WETH, assets, receiver);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }
}