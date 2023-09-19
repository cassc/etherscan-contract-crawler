// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../lib/PMMRangeOrder.sol";
import "../lib/Errors.sol";
import {ID3MM} from "../intf/ID3MM.sol";
import {ID3Factory} from "../intf/ID3Factory.sol";
import {IWETH} from "contracts/intf/IWETH.sol";
import {IDODOSwapCallback} from "../intf/IDODOSwapCallback.sol";
import {IDODOApproveProxy} from "contracts/intf/IDODOApproveProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ID3Vault} from "../intf/ID3Vault.sol";

contract D3Proxy is IDODOSwapCallback {
    using SafeERC20 for IERC20;

    address public immutable _DODO_APPROVE_PROXY_;
    address public immutable _WETH_;
    address public immutable _D3_VAULT_;
    address public immutable _ETH_ADDRESS_ = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct SwapCallbackData {
        bytes data;
        address payer;
    }

    // ============ Modifiers ============

    modifier judgeExpired(uint256 deadLine) {
        require(deadLine >= block.timestamp, "D3PROXY_EXPIRED");
        _;
    }

    // ============ Constructor ============

    constructor(address approveProxy, address weth, address d3Vault) {
        _DODO_APPROVE_PROXY_ = approveProxy;
        _WETH_ = weth;
        _D3_VAULT_ = d3Vault;
    }

    // ======================================

    fallback() external payable {}

    receive() external payable {
        require(msg.sender == _WETH_, "D3PROXY_NOT_WETH9");
    }

    // ======================================

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }

            results[i] = result;
        }
    }

    /// @notice Sell certain amount of tokens, i.e., fromToken amount is known
    /// @param pool The address of the pool to which you want to sell tokens
    /// @param to The address to receive the return back token
    /// @param fromToken The address of the fromToken
    /// @param toToken The address of the toToken
    /// @param fromAmount The amount of the fromToken you want to sell
    /// @param minReceiveAmount The minimal amount you expect to receive
    /// @param data Any data to be passed through to the callback
    /// @param deadLine The transaction should be processed before the deadline
    function sellTokens(
        address pool,
        address to,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minReceiveAmount,
        bytes calldata data,
        uint256 deadLine
    ) public payable judgeExpired(deadLine) returns (uint256 receiveToAmount) {
        SwapCallbackData memory swapData;
        swapData.data = data;
        swapData.payer = msg.sender;

        if (fromToken == _ETH_ADDRESS_) {
            require(msg.value == fromAmount, "D3PROXY_VALUE_INVALID");
            receiveToAmount = ID3MM(pool).sellToken(to, _WETH_, toToken, fromAmount, minReceiveAmount, abi.encode(swapData));
        } else if (toToken == _ETH_ADDRESS_) {
            receiveToAmount =
                ID3MM(pool).sellToken(address(this), fromToken, _WETH_, fromAmount, minReceiveAmount, abi.encode(swapData));
            _withdrawWETH(to, receiveToAmount);
            // multicall withdraw weth to user
        } else {
            receiveToAmount = ID3MM(pool).sellToken(to, fromToken, toToken, fromAmount, minReceiveAmount, abi.encode(swapData));
        }
    }

    /// @notice Buy certain amount of tokens, i.e., toToken amount is known
    /// @param pool The address of the pool to which you want to sell tokens
    /// @param to The address to receive the return back token
    /// @param fromToken The address of the fromToken
    /// @param toToken The address of the toToken
    /// @param quoteAmount The amount of the toToken you want to buy
    /// @param maxPayAmount The maximum amount of fromToken you would like to pay
    /// @param data Any data to be passed through to the callback
    /// @param deadLine The transaction should be processed before the deadline
    function buyTokens(
        address pool,
        address to,
        address fromToken,
        address toToken,
        uint256 quoteAmount,
        uint256 maxPayAmount,
        bytes calldata data,
        uint256 deadLine
    ) public payable judgeExpired(deadLine) returns (uint256 payFromAmount) {
        SwapCallbackData memory swapData;
        swapData.data = data;
        swapData.payer = msg.sender;

        if (fromToken == _ETH_ADDRESS_) {
            payFromAmount = ID3MM(pool).buyToken(to, _WETH_, toToken, quoteAmount, maxPayAmount, abi.encode(swapData));
            // multicall refund eth to user
        } else if (toToken == _ETH_ADDRESS_) {
            payFromAmount = ID3MM(pool).buyToken(address(this), fromToken, _WETH_, quoteAmount, maxPayAmount, abi.encode(swapData));
            _withdrawWETH(to, quoteAmount);
            // multicall withdraw weth to user
        } else {
            payFromAmount = ID3MM(pool).buyToken(to, fromToken, toToken, quoteAmount, maxPayAmount, abi.encode(swapData));
        }
    }

    /// @notice This callback is used to deposit token into D3MM
    /// @param token The address of token
    /// @param value The amount of token need to deposit to D3MM
    /// @param _data Any data to be passed through to the callback
    function d3MMSwapCallBack(address token, uint256 value, bytes calldata _data) external override {
        require(ID3Vault(_D3_VAULT_).allPoolAddrMap(msg.sender), "D3PROXY_CALLBACK_INVALID");
        SwapCallbackData memory decodeData;
        decodeData = abi.decode(_data, (SwapCallbackData));
        _deposit(decodeData.payer, msg.sender, token, value);
    }

    /// @notice LP deposit token into pool
    /// @param user the one who own dtokens
    /// @param  token The address of token
    /// @param amount The amount of token
    function userDeposit(address user, address token, uint256 amount, uint256 minDtokenAmount) external payable {
        uint256 dTokenAmount;
        if (token == _ETH_ADDRESS_) {
            require(msg.value == amount, "D3PROXY_PAYMENT_NOT_MATCH");
            _deposit(msg.sender, _D3_VAULT_, _WETH_, amount);
            dTokenAmount = ID3Vault(_D3_VAULT_).userDeposit(user, _WETH_);
        } else {
            _deposit(msg.sender, _D3_VAULT_, token, amount);
            dTokenAmount = ID3Vault(_D3_VAULT_).userDeposit(user, token);
        }
        require(dTokenAmount >= minDtokenAmount, "D3PROXY_MIN_DTOKEN_AMOUNT_FAIL");
    }

    function userWithdraw(address to, address token, uint256 dTokenAmount, uint256 minReceiveAmount) external payable returns(uint256 amount){
        if (token != _ETH_ADDRESS_) {
            (address dToken,,,,,,,,,,) = ID3Vault(_D3_VAULT_).getAssetInfo(token);
            _deposit(msg.sender, address(this), dToken, dTokenAmount);
            amount = ID3Vault(_D3_VAULT_).userWithdraw(to, msg.sender, token, dTokenAmount);    
        } else {
            (address dToken,,,,,,,,,,) = ID3Vault(_D3_VAULT_).getAssetInfo(_WETH_);
            _deposit(msg.sender, address(this), dToken, dTokenAmount);
            amount = ID3Vault(_D3_VAULT_).userWithdraw(address(this), msg.sender, _WETH_, dTokenAmount);
            _withdrawWETH(to, amount);
        }
        require(amount >= minReceiveAmount, "D3PROXY_MIN_RECEIVE_FAIL");
    }

    /// @notice Pool owner deposit token into pool
    /// @param pool The address of pool
    /// @param  token The address of token
    /// @param amount The amount of token
    function makerDeposit(address pool, address token, uint256 amount) external payable {
        if (token == _ETH_ADDRESS_) {
            require(msg.value == amount, "D3PROXY_PAYMENT_NOT_MATCH");
            _deposit(msg.sender, pool, _WETH_, amount);
            ID3MM(pool).makerDeposit(_WETH_);
        } else{
            _deposit(msg.sender, pool, token, amount);
            ID3MM(pool).makerDeposit(token);
        }
    }


    // ======= external refund =======

    /// @dev when fromToken = ETH and call buyTokens, call this function to refund user's eth
    function refundETH() external payable {
        if (address(this).balance > 0) {
            _safeTransferETH(msg.sender, address(this).balance);
        }
    }

    /// @dev when toToken == eth, call this function to get eth
    /// @param to The account address to receive ETH
    /// @param minAmount The minimum amount to withdraw
    function withdrawWETH(address to, uint256 minAmount) external payable {
        uint256 withdrawAmount = IWETH(_WETH_).balanceOf(address(this));
        require(withdrawAmount >= minAmount, "D3PROXY_WETH_NOT_ENOUGH");

        _withdrawWETH(to, withdrawAmount);
    }

    // ======= internal =======

    /// @notice Before the first pool swap, contract call _deposit to get ERC20 token through DODOApprove / transfer ETH to WETH
    /// @dev ETH transfer is allowed
    /// @param from The address which will transfer token out
    /// @param to The address which will receive the token
    /// @param token The token address
    /// @param value The token amount
    function _deposit(address from, address to, address token, uint256 value) internal {
        if (token == _WETH_ && address(this).balance >= value) {
            // pay with WETH9
            IWETH(_WETH_).deposit{value: value}(); // wrap only what is needed to pay
            IWETH(_WETH_).transfer(to, value);
        } else {
            // pull payment
            IDODOApproveProxy(_DODO_APPROVE_PROXY_).claimTokens(token, from, to, value);
        }
    }

    /// @dev Withdraw ETH from WETH
    /// @param to The account address to receive ETH
    /// @param withdrawAmount The amount to withdraw
    function _withdrawWETH(address to, uint256 withdrawAmount) internal {
        IWETH(_WETH_).withdraw(withdrawAmount);
        _safeTransferETH(to, withdrawAmount);
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `ETH_TRANSFER_FAIL`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        require(success, "D3PROXY_ETH_TRANSFER_FAIL");
    }
}