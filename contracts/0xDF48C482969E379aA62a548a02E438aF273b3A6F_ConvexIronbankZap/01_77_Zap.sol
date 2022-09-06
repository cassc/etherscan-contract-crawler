// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ConvexZapBase} from "../common/Imports.sol";
import {ConvexIronbankConstants} from "./Constants.sol";

import {SafeERC20, SafeMath} from "contracts/libraries/Imports.sol";
import {
    IStableSwap
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

contract ConvexIronbankZap is ConvexZapBase, ConvexIronbankConstants {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor()
        public
        ConvexZapBase(STABLE_SWAP_ADDRESS, LP_TOKEN_ADDRESS, PID, 10000, 100, 3)
    {} // solhint-disable no-empty-blocks

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        return _createErc20AllocationArray(0);
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    {
        IStableSwap(SWAP_ADDRESS).add_liquidity(
            [amounts[0], amounts[1], amounts[2]],
            minAmount,
            true
        );
    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal override {
        IERC20(LP_TOKEN_ADDRESS).safeApprove(SWAP_ADDRESS, 0);
        IERC20(LP_TOKEN_ADDRESS).safeApprove(SWAP_ADDRESS, lpBalance);
        IStableSwap(SWAP_ADDRESS).remove_liquidity_one_coin(
            lpBalance,
            index,
            minAmount,
            true
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
        return IStableSwap(SWAP_ADDRESS).underlying_coins(i);
    }
}