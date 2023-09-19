/*

    Copyright 2022 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import "contracts/DODOV3MM/lib/PMMRangeOrder.sol";
import {ID3MM} from "contracts/DODOV3MM/intf/ID3MM.sol";
import {IWETH} from "contracts/intf/IWETH.sol";
import {IDODOSwapCallback} from "contracts/DODOV3MM/intf/IDODOSwapCallback.sol";
import {IDODOApproveProxy} from "contracts/intf/IDODOApproveProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockFailD3Proxy is IDODOSwapCallback {
    using SafeERC20 for IERC20;

    address immutable public _DODO_APPROVE_PROXY_;
    address immutable public _WETH_;
    address immutable public _ETH_ADDRESS_ = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct SwapCallbackData {
        bytes data;
        address payer;
    }

    // ============ Modifiers ============

    modifier judgeExpired(uint256 deadLine) {
        require(deadLine >= block.timestamp, "DODORouteProxy: EXPIRED");
        _;
    }

    // ============ Constructor ============
    
    constructor(address approveProxy, address weth) {
        _DODO_APPROVE_PROXY_ = approveProxy;
        _WETH_ = weth;
    }

    function sellTokens(
        address pool,
        address to,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minReceiveAmount,
        bytes calldata data,
        uint256 deadLine
    ) public payable judgeExpired(deadLine) returns(uint256 receiveToAmount) {
        receiveToAmount = ID3MM(pool).sellToken(to, fromToken, toToken, fromAmount, minReceiveAmount, data);
    }

    function buyTokens(
        address pool,
        address to,
        address fromToken,
        address toToken,
        uint256 quoteAmount,
        uint256 maxPayAmount,
        bytes calldata data,
        uint256 deadLine
    ) public payable judgeExpired(deadLine) returns(uint256 payFromAmount) {
        payFromAmount = ID3MM(pool).buyToken(to, fromToken, toToken, quoteAmount, maxPayAmount, data);
    }

    function d3MMSwapCallBack(
        address token,
        uint256 /* value */,
        bytes calldata _data
    ) external override {
        SwapCallbackData memory decodeData;
        decodeData = abi.decode(_data, (SwapCallbackData));
        _deposit(decodeData.payer, msg.sender, token, 1000);
    }

    // ======= internal =======

    /// @notice before the first pool swap, contract call _deposit to get ERC20 token through DODOApprove/transfer ETH to WETH
    function _deposit(
        address from,
        address to,
        address token,
        uint256 value
    ) internal {
        if (token == _WETH_ && address(this).balance >= value) {
            // pay with WETH9
            IWETH(_WETH_).deposit{value: value}(); // wrap only what is needed to pay
            IWETH(_WETH_).transfer(to, value);
        } else if (from == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            SafeERC20.safeTransfer(IERC20(token), to, value);
        } else {
            // pull payment
            IDODOApproveProxy(_DODO_APPROVE_PROXY_).claimTokens(token, from, to, value);
        }
    }

    function testSuccess() public {}
}