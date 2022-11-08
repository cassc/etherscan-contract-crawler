/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

import {ISlippageAccounter} from "./interfaces/ISlippageAccounter.sol";
import {ICurvePool} from "gearbox_integrations/integrations/curve/ICurvePool.sol";
import {IPriceOracleV2} from "gearbox_core/interfaces/IPriceOracle.sol";
import {IAddressProvider} from "gearbox_core/interfaces/IAddressProvider.sol";

contract SlippageAccounter is ISlippageAccounter, Ownable {
    ICurvePool public curvePool =
        ICurvePool(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);
    address public FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 public MAX_BPS = 1e4;
    uint256 public leverage = 2 * 1e4;
    address public addressProvider = 0xcF64698AFF7E5f27A11dff868AF228653ba53be0;

    constructor(uint256 _leverage) {
        leverage = _leverage;
    }

    function getSlippageAccountedAmount(uint256 amountIn)
        external
        view
        returns (uint256 amountOut)
    {
        if (leverage == 0) {
            return amountIn;
        }

        IPriceOracleV2 priceOracle = IPriceOracleV2(
            IAddressProvider(addressProvider).getPriceOracle()
        );
        uint256 wethBorrowed = priceOracle.convert(
            (amountIn * leverage) / MAX_BPS,
            FRAX,
            WETH
        );

        uint256 stETHReceivedOnCurve = curvePool.get_dy(0, 1, wethBorrowed);
        uint256 stETHReceivedOnLido = wethBorrowed - 1;
        uint256 stETHConverted = stETHReceivedOnLido > stETHReceivedOnCurve
            ? stETHReceivedOnLido
            : stETHReceivedOnCurve;
        uint256 wethReturned = curvePool.get_dy(1, 0, stETHConverted);
        uint256 slippageAmount = (amountIn * (wethBorrowed - wethReturned)) /
            (2 * wethBorrowed); // half to account for only deposit
        amountOut = amountIn - slippageAmount;
    }

    function setLeverage(uint256 _leverage) external onlyOwner {
        leverage = _leverage;
    }

    function setAddressProvider(address _addressProvider) external onlyOwner {
        addressProvider = _addressProvider;
    }
}