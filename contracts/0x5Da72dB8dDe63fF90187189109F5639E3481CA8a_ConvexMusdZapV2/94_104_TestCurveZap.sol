// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {
    CurveGaugeZapBase
} from "contracts/protocols/curve/common/CurveGaugeZapBase.sol";

contract TestCurveZap is CurveGaugeZapBase {
    string public constant override NAME = "TestCurveZap";

    address[] private _underlyers;

    constructor(
        address swapAddress,
        address lpTokenAddress,
        address liquidityGaugeAddress,
        uint256 denominator,
        uint256 slippage,
        uint256 numOfCoins
    )
        public
        CurveGaugeZapBase(
            swapAddress,
            lpTokenAddress,
            liquidityGaugeAddress,
            denominator,
            slippage,
            numOfCoins
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function setUnderlyers(address[] calldata underlyers) external {
        _underlyers = underlyers;
    }

    function getSwapAddress() external view returns (address) {
        return SWAP_ADDRESS;
    }

    function getLpTokenAddress() external view returns (address) {
        return address(LP_ADDRESS);
    }

    function getGaugeAddress() external view returns (address) {
        return GAUGE_ADDRESS;
    }

    function getDenominator() external view returns (uint256) {
        return DENOMINATOR;
    }

    function getSlippage() external view returns (uint256) {
        return SLIPPAGE;
    }

    function getNumberOfCoins() external view returns (uint256) {
        return N_COINS;
    }

    function calcMinAmount(uint256 totalAmount, uint256 virtualPrice)
        external
        view
        returns (uint256)
    {
        return _calcMinAmount(totalAmount, virtualPrice);
    }

    function calcMinAmountUnderlyer(
        uint256 totalAmount,
        uint256 virtualPrice,
        uint8 decimals
    ) external view returns (uint256) {
        return _calcMinAmountUnderlyer(totalAmount, virtualPrice, decimals);
    }

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = new IERC20[](0);
        return allocations;
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        return 1;
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        return _underlyers[i];
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount // solhint-disable-next-line no-empty-blocks
    ) internal override {}
}