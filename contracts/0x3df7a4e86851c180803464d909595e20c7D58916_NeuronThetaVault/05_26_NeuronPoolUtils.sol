// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { DSMath } from "../vendor/DSMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { INeuronPool } from "../../common/interfaces/INeuronPool.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { IERC20Detailed } from "../interfaces/IERC20Detailed.sol";

library NeuronPoolUtils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice Unwraps the necessary amount of the yield-bearing yearn token
     *         and transfers amount to vault
     * @param amount is the amount of `asset` to withdraw
     * @param asset is asset to unwrap to
     * @param neuronPoolAddress is the address of the collateral token
     */
    function unwrapNeuronPool(
        uint256 amount,
        address asset,
        address neuronPoolAddress
    ) public returns (uint256 unwrappedAssetAmount) {
        INeuronPool neuronPool = INeuronPool(neuronPoolAddress);
        uint256 assetBalanceBefore = asset == ETH ? address(this).balance : IERC20(asset).balanceOf(address(this));
        neuronPool.withdraw(asset, amount);
        uint256 assetBalanceAfter = asset == ETH ? address(this).balance : IERC20(asset).balanceOf(address(this));
        return assetBalanceAfter - assetBalanceBefore;
    }

    function unwrapAndWithdraw(
        address neuronPool,
        uint256 amountToUnwrap,
        address to
    ) external {
        address unwrapToAsset = INeuronPool(neuronPool).token();
        uint256 unwrappedAssetAmount = unwrapNeuronPool(amountToUnwrap, unwrapToAsset, neuronPool);

        transferAsset(unwrapToAsset, to, unwrappedAssetAmount);
    }

    /**
     * @notice Helper function to make either an ETH transfer or ERC20 transfer
     * @param asset is the vault asset address
     * @param recipient is the receiving address
     * @param amount is the transfer amount
     */
    function transferAsset(
        address asset,
        address recipient,
        uint256 amount
    ) public {
        if (amount == 0) {
            return;
        }
        if (asset == ETH) {
            (bool success, ) = payable(recipient).call{ value: amount }("");
            require(success, "!unsuccessful ETH transfer");
            return;
        }
        IERC20(asset).safeTransfer(recipient, amount);
    }

    /**
     * @notice Returns the decimal shift between 18 decimals and asset tokens
     * @param collateralToken is the address of the collateral token
     */
    function decimalShift(address collateralToken) public view returns (uint256) {
        return 10**(uint256(18).sub(IERC20Detailed(collateralToken).decimals()));
    }
}