// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    IStableSwap2 as IStableSwap,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {ConvexZapBase} from "../common/Imports.sol";
import {ConvexFraxUsdcConstants} from "./Constants.sol";

contract ConvexFraxUsdcZap is ConvexZapBase, ConvexFraxUsdcConstants {
    constructor()
        public
        ConvexZapBase(
            STABLE_SWAP_ADDRESS,
            LP_TOKEN_ADDRESS,
            PID,
            10000,
            10000,
            2
        )
    {} // solhint-disable no-empty-blocks

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = new IERC20[](3);
        allocations[0] = IERC20(CRV_ADDRESS);
        allocations[1] = IERC20(FRAX_ADDRESS);
        allocations[2] = IERC20(USDC_ADDRESS);
        return allocations;
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    {
        IStableSwap(SWAP_ADDRESS).add_liquidity(
            [amounts[0], amounts[1]],
            minAmount
        );
    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal override {
        require(index < 2, "INVALID_INDEX");
        require(index > 0, "CANT_WITHDRAW_PRIMARY");
        IStableSwap(SWAP_ADDRESS).remove_liquidity_one_coin(
            lpBalance,
            index,
            minAmount
        );
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        return IStableSwap(SWAP_ADDRESS).get_virtual_price();
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        return IStableSwap(SWAP_ADDRESS).coins(i);
    }
}