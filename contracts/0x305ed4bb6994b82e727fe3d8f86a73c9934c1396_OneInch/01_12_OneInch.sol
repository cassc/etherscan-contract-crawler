// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../errors.sol";
import {Swap} from "./Swap.sol";
import {ISwapFactory} from "../interfaces/ISwapFactory.sol";
import {IAggregationRouterV4, SwapDescription} from "../interfaces/external/IOneInch.sol";

struct AggregationRouterV4CallData {
    address caller;
    SwapDescription desc;
    bytes data;
}

contract OneInch is Swap {
    using SafeERC20 for IERC20;

    IAggregationRouterV4 public constant ROUTER =
        IAggregationRouterV4(0x1111111254fb6c44bAC0beD2854e76F90643097d);

    function approveTokens() public {
        address[] memory wt = ISwapFactory(factory).whitelistedTokens();
        IERC20 token;
        for (uint256 i = 0; i < wt.length; i++) {
            token = IERC20(wt[i]);
            if (token.allowance(address(this), address(ROUTER)) == 0) {
                token.safeApprove(address(ROUTER), type(uint256).max);
            }
        }
    }

    function use1inch(AggregationRouterV4CallData calldata data)
        external
        checkToken(data.desc.srcToken)
        checkToken(data.desc.dstToken)
        onlyOwner
    {
        if (data.desc.dstReceiver != owner) revert OnlyOwner();
        ROUTER.swap(data.caller, data.desc, data.data);
    }

    function _postInit() internal override {
        approveTokens();
    }
}