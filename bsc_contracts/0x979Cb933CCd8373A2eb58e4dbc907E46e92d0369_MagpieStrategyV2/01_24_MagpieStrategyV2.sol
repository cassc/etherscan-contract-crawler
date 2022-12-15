// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import "../../strategies/IXStrategy.sol";
import "../../bridges/IXPlatformBridge.sol";
import "../../xassets/IXAsset.sol";
import "./interfaces/IPoolHelper.sol";
import "./interfaces/IPoolHelper.sol";
import "hardhat/console.sol";
import "./interfaces/IPool.sol";

contract MagpieStrategyV2 is IXStrategy, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IERC20Metadata;

    uint256 constant MAX_UINT256 = 2 ** 256 - 1;

    string  public name;

    address public magpiePoolHelper;
    address public baseToken;
    uint256 private baseTokenDenominator;
    address public magpiePool;
    address public womToken;
    address public xAsset;

    /**
     * @param baseToken_ - The base token used for different conversion
     * @param magpiePoolHelper_ - The magpie pool address
     */
    function initialize(address baseToken_,
        address magpiePoolHelper_,
        address magpiePool_,
        address womToken_) initializer external {
        __UUPSUpgradeable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        name = "MagpieStrategy";

        magpiePoolHelper = magpiePoolHelper_;
        baseToken = baseToken_;
        magpiePool = magpiePool_;
        womToken = womToken_;
        baseTokenDenominator = 10 ** IERC20Metadata(baseToken).decimals();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function invest(
        address token,
        uint256 amount,
        uint256 minAmount
    ) nonReentrant whenNotPaused onlyXAsset override external returns (uint256) {
        require(token == address(baseToken), "MagpieStrategy: Only baseToken investments are allowed");

        // Transfer the baseToken to the strategy
        IERC20Upgradeable(baseToken).safeTransferFrom(msg.sender, address(this), amount);

        // Approve the pool to spend the baseToken
        if (IERC20(baseToken).allowance(address(this), address(IPoolHelper(magpiePoolHelper).wombatStaking())) < amount) {
            IERC20Upgradeable(baseToken).safeIncreaseAllowance(address(IPoolHelper(magpiePoolHelper).wombatStaking()), amount);
        }

        console.log("strategy balance before deposit: ", IERC20(baseToken).balanceOf(address(this)));
        console.log("helper allowance before deposit: ", IERC20(baseToken).allowance(address(this), address(IPoolHelper(magpiePoolHelper).wombatStaking())));

        // Save the balance of the baseToken before the deposit
        uint256 balanceBefore = IPoolHelper(magpiePoolHelper).balance(address(this));

        // Deposit the baseToken to the pool
        console.log("lp balance before deposit: ", balanceBefore);
        IPoolHelper(magpiePoolHelper).deposit(amount, amount);

        // Save the balance of the baseToken after the deposit
        uint256 balanceAfter = IPoolHelper(magpiePoolHelper).balance(address(this));
        console.log("lp balance after deposit: ", balanceAfter);
        console.log("strategy balance after deposit: ", IERC20(baseToken).balanceOf(address(this)));

        // Calculate the amount of baseToken invested
        uint256 amountInvested = balanceAfter - balanceBefore;
        require(amountInvested >= minAmount, "MagpieStrategy: Insufficient amount invested");
        return amountInvested;
    }

    // calculate the amount of baseToken we need to convert to each of the tokens based on the balances in the pool
    //    function _calculateTokenAmounts(uint256 baseTokenAmount) private view returns (uint256, uint256) {
    //        // get conversion rates of both tokens to baseToken
    //        uint256 tokenARate = _getPrice(_tokenA);
    //        uint256 tokenBRate = _getPrice(_tokenB);
    //
    //        // calculate the amount of each token we need to convert to by getting the reserve levels
    //        (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(address(_router), address(_tokenA), address(_tokenB));
    //
    //    }

    function withdraw(
        uint256 amount,
        uint256 minAmount
    ) nonReentrant whenNotPaused onlyXAsset override external returns (uint256) {
        // Calculate the percentage of lpTokens to withdraw for the requested amount of baseToken
        uint256 totalAssets = _totalAssets();
        require(amount <= totalAssets, "MagpieStrategy: amount exceeds total assets");
        uint256 percentage = amount * 100 * baseTokenDenominator / totalAssets;
        console.log("[strategy][w] totalAssets: ", totalAssets);
        console.log("[strategy][w] amount: ", amount);
        console.log("[strategy][w] percentage: ", percentage);

        // Save balances before withdraw
        uint256 balanceBefore = IERC20(baseToken).balanceOf(address(this));
        uint256 lpBalanceBefore = IPoolHelper(magpiePoolHelper).balance(address(this));
        console.log("[strategy][w] lp balance before withdraw: ", lpBalanceBefore);

        // Calculate the amount of lpTokens to withdraw
        uint256 lpTokensToWithdraw = lpBalanceBefore * percentage / 100 / baseTokenDenominator;
        console.log("[strategy][w] lpTokensToWithdraw: ", lpTokensToWithdraw);
        uint256 lpTokensToWithdraw2 = amount * lpBalanceBefore / totalAssets;
        console.log("[strategy][w] lpTokensToWithdraw2: ", lpTokensToWithdraw2);

        // Withdraw from the Magpie pool
        IPoolHelper(magpiePoolHelper).withdraw(lpTokensToWithdraw, 0);

        // Get balances after withdraw
        uint256 lpBalanceAfter = IPoolHelper(magpiePoolHelper).balance(address(this));
        uint256 balanceAfter = IERC20(baseToken).balanceOf(address(this));
        console.log("[strategy][w] lp balance after withdraw: ", lpBalanceAfter);
        console.log("[strategy][w] balance after withdraw: ", balanceAfter);

        // Calculate the amount of baseToken withdrawn
        uint256 amountWithdrawn = balanceAfter - balanceBefore;
        console.log("[strategy][w] amountWithdrawn: ", amountWithdrawn);
        require(amountWithdrawn >= minAmount, "MagpieStrategy: Insufficient amount withdrawn");

        // Transfer the baseToken to the user
        IERC20Upgradeable(baseToken).safeTransfer(msg.sender, amountWithdrawn);
        return amountWithdrawn;
    }

    /**
     * @dev Convert amount of token to baseToken
     */
    function convert(
        address token,
        uint256 amount
    ) view override public returns (uint256) {
        require(token == address(baseToken), "FarmStrategy: only support base token");
        return amount;
    }

    function _totalAssets() internal view returns (uint256) {
        uint256 lpBalance = IPoolHelper(magpiePoolHelper).balance(address(this));
        if (lpBalance == 0) {
            return 0;
        }
        (uint256 amount, uint256 fee) = IPool(magpiePool).quotePotentialWithdraw(baseToken, lpBalance);
        // get the amount of WOM token owned by the pool

        return amount - fee;
    }

    function getTotalAssetValue() override view external returns (uint256) {
        return _totalAssets();
    }

    function compound()
    nonReentrant whenNotPaused override external {

    }

    /**
     * @notice pause strategy, restricting certain operations
     */
    function pause() external nonReentrant onlyOwner {
        _pause();
    }

    /**
     * @notice unpause strategy, enabling certain operations
     */
    function unpause() external nonReentrant onlyOwner {
        _unpause();
    }

    /**
     * @dev Transfers ownership of the contract to a new xAsset (`newXasset`).
     * Can only be called by the current owner.
     */
    function setXAsset(address newXasset) public virtual onlyOwner {
        require(xAsset == address(0), "XAsset already set");
        require(newXasset != address(0), "xAsset address can not be zero address");
        xAsset = newXasset;
    }

    /**
     * @dev Throws if called by any account other than the xAsset contract.
     */
    modifier onlyXAsset() {
        _checkXAsset();
        _;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkXAsset() internal view virtual {
        require(xAsset == _msgSender(), "Caller is not the xAsset contract");
    }

}