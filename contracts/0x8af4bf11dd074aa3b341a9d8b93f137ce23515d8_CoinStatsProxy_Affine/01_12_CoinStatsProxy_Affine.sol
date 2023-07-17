// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { CoinStatsBaseV1, Ownable, SafeERC20, IERC20 } from "./base/CoinStatsBaseV1.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IntegrationInterface } from "./base/IntegrationInterface.sol";

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

contract CoinStatsProxy_Affine is CoinStatsBaseV1, IntegrationInterface {
    using SafeERC20 for IERC20;

    address immutable WETH;

    mapping(address => bool) public targetWhitelist;

    error TargetIsNotWhitelited(address target);

    event Deposit(address indexed from, address indexed pool, address token, uint256 amount, address affiliate);
    event Withdraw(address indexed from, address indexed pool, address token, uint256 amount, address affiliate);
    event FillQuoteSwap(
        address swapTarget,
        address inputTokenAddress,
        uint256 inputTokenAmount,
        address outputTokenAddress,
        uint256 outputTokenAmount
    );

    constructor(
        address _target,
        address _weth,
        uint256 _goodwill,
        uint256 _affiliateSplit,
        address _vaultAddress
    ) CoinStatsBaseV1(_goodwill, _affiliateSplit, _vaultAddress) {
        WETH = _weth;
        targetWhitelist[_target] = true;

        approvedTargets[0x1111111254fb6c44bAC0beD2854e76F90643097d] = true;
    }

    function removeAssetReturn(
        address withdrawTarget,
        address,
        uint256 shares
    ) external view override returns (uint256) {
        return IERC4626(withdrawTarget).previewRedeem(shares);
    }

    function getBalance(address target, address account) public view override returns (uint256) {
        return IERC20(target).balanceOf(account);
    }

    function setTarget(address[] memory targets, bool[] memory statuses) external onlyOwner {
        for (uint8 i = 0; i < targets.length; i++) {
            targetWhitelist[targets[i]] = statuses[i];
        }
    }

    function getTotalSupply(address vaultAddress) public view returns (uint256) {
        return IERC20(vaultAddress).totalSupply();
    }

    function _fillQuote(
        address inputTokenAddress,
        uint256 inputTokenAmount,
        address outputTokenAddress,
        address swapTarget,
        bytes memory swapData
    ) private returns (uint256 outputTokenAmount) {
        if (swapTarget == WETH) {
            if (outputTokenAddress == ETH_ADDRESS) {
                IWETH(WETH).withdraw(inputTokenAmount);

                return inputTokenAmount;
            } else {
                IWETH(WETH).deposit{ value: inputTokenAmount }();

                return inputTokenAmount;
            }
        }

        uint256 value;
        if (inputTokenAddress == ETH_ADDRESS) {
            value = inputTokenAmount;
        } else {
            _approveToken(inputTokenAddress, swapTarget, inputTokenAmount);
        }

        uint256 initialOutputTokenBalance = _getBalance(outputTokenAddress);

        // solhint-disable-next-line reason-string
        require(approvedTargets[swapTarget], "FillQuote: Target is not whitelisted");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = swapTarget.call{ value: value }(swapData);
        require(success, "FillQuote: Failed to swap tokens");

        outputTokenAmount = _getBalance(outputTokenAddress) - initialOutputTokenBalance;

        // solhint-disable-next-line reason-string
        require(outputTokenAmount > 0, "FillQuote: Swapped to invalid token");

        emit FillQuoteSwap(swapTarget, inputTokenAddress, inputTokenAmount, outputTokenAddress, outputTokenAmount);
    }

    function deposit(
        address entryTokenAddress,
        uint256 entryTokenAmount,
        address depositTarget,
        address,
        uint256 minShares,
        address,
        address,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable override whenNotPaused {
        if (!targetWhitelist[depositTarget]) {
            revert TargetIsNotWhitelited(depositTarget);
        }

        if (entryTokenAddress == address(0)) {
            entryTokenAddress = ETH_ADDRESS;
        }

        entryTokenAmount = _pullTokens(entryTokenAddress, entryTokenAmount);

        entryTokenAmount -= _subtractGoodwill(entryTokenAddress, entryTokenAmount, affiliate, true);

        address asset = IERC4626(depositTarget).asset();

        if (entryTokenAddress != asset) {
            entryTokenAmount = _fillQuote(entryTokenAddress, entryTokenAmount, asset, swapTarget, swapData);
        }

        IERC20(asset).safeApprove(depositTarget, entryTokenAmount);

        // Do not call this from contracts, shares will be locked there
        uint256 shares = IERC4626(depositTarget).deposit(entryTokenAmount, msg.sender);
        require(shares >= minShares, "Got less shares than expected");

        emit Deposit(msg.sender, depositTarget, entryTokenAddress, entryTokenAmount, affiliate);
    }

    function withdraw(
        address withdrawTarget,
        uint256 withdrawAmount,
        address exitTokenAddress,
        uint256 minExitTokenAmount,
        address,
        address,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable override whenNotPaused {
        if (!targetWhitelist[withdrawTarget]) {
            revert TargetIsNotWhitelited(withdrawTarget);
        }

        withdrawAmount = _pullTokens(withdrawTarget, withdrawAmount);

        _approveToken(withdrawTarget, withdrawTarget, withdrawAmount);

        address asset = IERC4626(withdrawTarget).asset();
        uint256 exitTokenAmount;

        uint256 assets = IERC4626(withdrawTarget).redeem(withdrawAmount, address(this), address(this));

        if (exitTokenAddress != asset) {
            exitTokenAmount = _fillQuote(asset, assets, exitTokenAddress, swapTarget, swapData);
        } else {
            exitTokenAmount = assets;
        }

        exitTokenAmount -= _subtractGoodwill(exitTokenAddress, exitTokenAmount, affiliate, true);

        if (exitTokenAddress != ETH_ADDRESS) {
            IERC20(exitTokenAddress).safeTransfer(msg.sender, exitTokenAmount);
        } else {
            (bool success, ) = msg.sender.call{ value: exitTokenAmount }("");
            require(success, "NativeTransfer: unable to send value, recipient may have reverted");
        }

        require(exitTokenAmount >= minExitTokenAmount, "Got less exit tokens than expected");

        emit Withdraw(msg.sender, withdrawTarget, exitTokenAddress, exitTokenAmount, affiliate);
    }
}