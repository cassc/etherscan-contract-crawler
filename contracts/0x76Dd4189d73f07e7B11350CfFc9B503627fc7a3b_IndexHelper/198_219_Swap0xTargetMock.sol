// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../libraries/FullMath.sol";

import "../interfaces/IPhuturePriceOracle.sol";

contract Swap0xTargetMock {
    using SafeERC20 for IERC20;
    using FullMath for uint;

    IPhuturePriceOracle priceOracle;

    constructor(address _priceOracle) {
        priceOracle = IPhuturePriceOracle(_priceOracle);
    }

    function swapExact(
        address inputAsset,
        address outputAsset,
        uint inputAmount
    ) external {
        IERC20(inputAsset).safeTransferFrom(msg.sender, address(this), inputAmount);
        uint outputAmount = inputAmount.mulDiv(
            priceOracle.refreshedAssetPerBaseInUQ(outputAsset),
            priceOracle.refreshedAssetPerBaseInUQ(inputAsset)
        );
        require(
            IERC20(outputAsset).balanceOf(address(this)) >= outputAmount,
            string.concat("Swap0xTargetMock: BALANCE ", Strings.toHexString(uint160(outputAsset), 20))
        );
        IERC20(outputAsset).safeTransfer(msg.sender, outputAmount);
    }

    function swapExactAmount(
        address inputAsset,
        address outputAsset,
        uint inputAmount
    ) external returns (uint) {
        return
            inputAmount.mulDiv(
                priceOracle.refreshedAssetPerBaseInUQ(outputAsset),
                priceOracle.refreshedAssetPerBaseInUQ(inputAsset)
            );
    }

    function swap(
        address inputAsset,
        address outputAsset,
        uint inputAmount,
        uint outputAmount
    ) external {
        IERC20(inputAsset).safeTransferFrom(msg.sender, address(this), inputAmount);
        IERC20(outputAsset).safeTransfer(msg.sender, outputAmount);
    }

    function swapFails() external {
        revert("FAILED");
    }

    function emptyRevert() external {
        revert();
    }
}