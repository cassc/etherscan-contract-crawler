// Copyright (C) 2021 Zapper (Zapper.Fi)

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU Affero General Public License for more details.

///@author Zapper, modified and adapted for Grizzly.fi.
///@notice This contract removes liquidity from Grizzly Vaults to ETH or ERC20 Tokens.
///@notice These files have been changed from the original Zapper ones.

// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.8.0;

import {IVault} from "./interfaces/IVault.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {ICurveSwap} from "./interfaces/ICurveSwap.sol";
import {ICurveEthSwap} from "./interfaces/ICurveEthSwap.sol";
import {ICurveRegistry} from "./interfaces/ICurveRegistry.sol";

import {ZapOutBase} from "./ZapOutBase.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";
import {Address} from "./libraries/Address.sol";

contract ZapOutCurveGVault is ZapOutBase {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    ICurveRegistry public curveReg;

    mapping(address => bool) internal v2Pool;

    constructor(ICurveRegistry _curveRegistry) {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        v2Pool[0xD51a44d3FaE010294C616388b506AcdA1bfAAE46] = true;
        curveReg = _curveRegistry;
    }

    event zapCurveOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );
    event curveRegistryUpdated(
        ICurveRegistry newCurveReg,
        ICurveRegistry oldCurveReg
    );
    event approvedV2Pool(address pool, bool approved);
    event Sweep(address indexed token, uint256 amount);

    /**
    @notice This method removes the liquidity from curve pools to ETH/ERC tokens
    @param gVault Grizzly Vault from which to remove liquidity
    @param amountIn Indicates the quantity of Vault tokens to remove (shares)
    @param swapAddress indicates Curve swap address for the pool
    @param intermediateToken specifies in which token to exit the curve pool
    @param toToken indicates the ETH/ERC token to which tokens to convert
    @param minToTokens indicates the minimum amount of toTokens to receive
    @param _swapTarget Execution target for the first swap
    @param _swapCallData DEX quote data
    @return toTokensBought- indicates the amount of toTokens received
    */
    function ZapOut(
        address gVault,
        uint256 amountIn,
        address swapAddress,
        address intermediateToken,
        address toToken,
        uint256 minToTokens,
        address _swapTarget,
        bytes calldata _swapCallData
    ) external stopInEmergency returns (uint256) {
        address underlyingToken = IVault(gVault).token();
        address poolTokenAddress = curveReg.getTokenAddress(swapAddress); // ERC20 Curve LP Token
        // Safety check for underlying Vault Token = address LP
        require(poolTokenAddress == underlyingToken, "Wrong LpAddress");

        _pullTokens(gVault, amountIn);

        // Get the LP Tokens by withdrawing from Vault
        uint256 underlyingTokenReceived = _vaultWithdraw(
            gVault,
            amountIn,
            underlyingToken
        );

        if (intermediateToken == address(0)) {
            intermediateToken = ETHAddress;
        }

        // Perform zapOut
        uint256 toTokensBought = _zapOut(
            swapAddress,
            underlyingTokenReceived,
            intermediateToken,
            toToken,
            _swapTarget,
            _swapCallData
        );

        require(toTokensBought >= minToTokens, "High Slippage");

        // Transfer tokens
        if (toToken == address(0)) {
            Address.sendValue(payable(msg.sender), toTokensBought);
        } else {
            IERC20(toToken).safeTransfer(msg.sender, toTokensBought);
        }

        emit zapCurveOut(msg.sender, swapAddress, toToken, toTokensBought);

        return toTokensBought;
    }

    function _vaultWithdraw(
        address fromVault,
        uint256 amount,
        address underlyingVaultToken
    ) internal returns (uint256 underlyingReceived) {
        uint256 iniUnderlyingBal = _getBalance(underlyingVaultToken);

        IVault(fromVault).withdraw(amount, address(this), 10, msg.sender);

        underlyingReceived =
            _getBalance(underlyingVaultToken) -
            iniUnderlyingBal;
    }

    function _zapOut(
        address swapAddress,
        uint256 incomingCrv,
        address intermediateToken,
        address toToken,
        address _swapTarget,
        bytes memory _swapCallData
    ) internal returns (uint256 toTokensBought) {
        /// @return true if the pool contains the token, false otherwise
        /// @return index of the token in the pool, 0 if pool does not contain the token
        (bool isUnderlying, uint256 underlyingIndex) = curveReg
            .isUnderlyingToken(swapAddress, intermediateToken);

        // Not Metapool
        if (isUnderlying) {
            uint256 intermediateBought = _exitCurve(
                swapAddress,
                incomingCrv,
                underlyingIndex,
                intermediateToken
            );

            if (intermediateToken == ETHAddress) intermediateToken = address(0);

            toTokensBought = _fillQuote(
                intermediateToken,
                toToken,
                intermediateBought,
                _swapTarget,
                _swapCallData
            );
        } else {
            // From Metapool: Token that trades with another underlying base pool [MIM, 3Pool]
            address[4] memory poolTokens = curveReg.getPoolTokens(swapAddress);
            address intermediateSwapAddress;
            uint8 i;
            for (; i < 4; i++) {
                if (curveReg.getSwapAddress(poolTokens[i]) != address(0)) {
                    intermediateSwapAddress = curveReg.getSwapAddress(
                        poolTokens[i]
                    );
                    break;
                }
            }
            // _exitCurve to intermediateSwapAddress Token
            uint256 intermediateCrvBought = _exitMetaCurve(
                swapAddress,
                incomingCrv,
                i,
                poolTokens[i]
            );
            // _performZapOut: fromPool = intermediateSwapAddress
            toTokensBought = _zapOut(
                intermediateSwapAddress,
                intermediateCrvBought,
                intermediateToken,
                toToken,
                _swapTarget,
                _swapCallData
            );
        }
    }

    /**
    @notice This method removes the liquidity from meta curve pools
    @param swapAddress indicates the curve pool address from which liquidity to be removed.
    @param incomingCrv indicates the amount of liquidity to be removed from the pool
    @param index indicates the index of underlying token of the pool in which liquidity will be removed. 
    @return tokensReceived- indicates the amount of reserve tokens received 
    */
    function _exitMetaCurve(
        address swapAddress,
        uint256 incomingCrv,
        uint256 index,
        address exitTokenAddress
    ) internal returns (uint256) {
        address tokenAddress = curveReg.getTokenAddress(swapAddress);
        _approveToken(tokenAddress, swapAddress);

        uint256 iniTokenBal = IERC20(exitTokenAddress).balanceOf(address(this));
        ICurveSwap(swapAddress).remove_liquidity_one_coin(
            incomingCrv,
            int128(uint128(index)),
            0
        );
        uint256 tokensReceived = (
            IERC20(exitTokenAddress).balanceOf(address(this))
        ) - iniTokenBal;

        require(tokensReceived > 0, "Could not receive reserve tokens");

        return tokensReceived;
    }

    /**
    @notice This method removes the liquidity from given curve pool
    @param swapAddress indicates the curve pool address from which liquidity to be removed.
    @param incomingCrv indicates the amount of liquidity to be removed from the pool
    @param index indicates the index of underlying token of the pool in which liquidity will be removed. 
    @return tokensReceived- indicates the amount of reserve tokens received 
    */
    function _exitCurve(
        address swapAddress,
        uint256 incomingCrv,
        uint256 index,
        address exitTokenAddress
    ) internal returns (uint256) {
        address depositAddress = curveReg.getDepositAddress(swapAddress);

        address tokenAddress = curveReg.getTokenAddress(swapAddress);
        _approveToken(tokenAddress, depositAddress);

        address balanceToken = exitTokenAddress == ETHAddress
            ? address(0)
            : exitTokenAddress;

        uint256 iniTokenBal = _getBalance(balanceToken);

        if (curveReg.shouldAddUnderlying(swapAddress)) {
            // Aave
            ICurveSwap(depositAddress).remove_liquidity_one_coin(
                incomingCrv,
                int128(uint128(index)),
                0,
                true
            );
        } else if (v2Pool[swapAddress]) {
            ICurveSwap(depositAddress).remove_liquidity_one_coin(
                incomingCrv,
                index,
                0
            );
        } else {
            ICurveSwap(depositAddress).remove_liquidity_one_coin(
                incomingCrv,
                int128(uint128(index)),
                0
            );
        }

        uint256 tokensReceived = _getBalance(balanceToken) - iniTokenBal;

        require(tokensReceived > 0, "Could not receive reserve tokens");

        return tokensReceived;
    }

    /**
    @notice This method swaps the fromToken to toToken using the 0x swap
    @param _fromTokenAddress indicates the ETH/ERC20 token
    @param _toTokenAddress indicates the ETH/ERC20 token
    @param _amount indicates the amount of from tokens to swap
    @param _swapTarget Execution target for the first swap
    @param _swapCallData DEX quote data
    */
    function _fillQuote(
        address _fromTokenAddress,
        address _toTokenAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory _swapCallData
    ) internal returns (uint256 amountBought) {
        if (_fromTokenAddress == _toTokenAddress) return _amount;

        if (
            _fromTokenAddress == wethTokenAddress &&
            _toTokenAddress == address(0)
        ) {
            IWETH(wethTokenAddress).withdraw(_amount);
            return _amount;
        } else if (
            _fromTokenAddress == address(0) &&
            _toTokenAddress == wethTokenAddress
        ) {
            IWETH(wethTokenAddress).deposit{value: _amount}();
            return _amount;
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) valueToSend = _amount;
        else _approveToken(_fromTokenAddress, _swapTarget, _amount);

        uint256 iniBal = _getBalance(_toTokenAddress);
        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{value: valueToSend}(_swapCallData);
        require(success, "Error Swapping Tokens");
        uint256 finalBal = _getBalance(_toTokenAddress);

        amountBought = finalBal - iniBal;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    /**
    @notice Utility function to determine the quantity and address of a token being removed
    @param swapAddress indicates the curve pool address from which liquidity to be removed
    @param tokenAddress token to be removed
    @param liquidity Quantity of LP tokens to remove
    @return amount Quantity of token removed
    */
    function removeLiquidityReturn(
        address swapAddress,
        address tokenAddress,
        uint256 liquidity
    ) external view returns (uint256 amount) {
        if (tokenAddress == address(0)) tokenAddress = ETHAddress;
        (bool underlying, uint256 index) = curveReg.isUnderlyingToken(
            swapAddress,
            tokenAddress
        );
        if (underlying) {
            if (v2Pool[swapAddress]) {
                return
                    ICurveSwap(curveReg.getDepositAddress(swapAddress))
                        .calc_withdraw_one_coin(liquidity, uint256(index));
            } else if (curveReg.shouldAddUnderlying(swapAddress)) {
                return
                    ICurveSwap(curveReg.getDepositAddress(swapAddress))
                        .calc_withdraw_one_coin(
                            liquidity,
                            int128(uint128(index)),
                            true
                        );
            } else {
                return
                    ICurveSwap(curveReg.getDepositAddress(swapAddress))
                        .calc_withdraw_one_coin(
                            liquidity,
                            int128(uint128(index))
                        );
            }
        } else {
            address[4] memory poolTokens = curveReg.getPoolTokens(swapAddress);
            address intermediateSwapAddress;
            for (uint256 i = 0; i < 4; i++) {
                intermediateSwapAddress = curveReg.getSwapAddress(
                    poolTokens[i]
                );
                if (intermediateSwapAddress != address(0)) break;
            }
            uint256 metaTokensRec = ICurveSwap(swapAddress)
                .calc_withdraw_one_coin(liquidity, int128(1));

            (, index) = curveReg.isUnderlyingToken(
                intermediateSwapAddress,
                tokenAddress
            );

            return
                ICurveSwap(intermediateSwapAddress).calc_withdraw_one_coin(
                    metaTokensRec,
                    int128(uint128(index))
                );
        }
    }

    function updateCurveRegistry(ICurveRegistry newCurveRegistry)
        external
        onlyOwner
    {
        require(newCurveRegistry != curveReg, "Already using this Registry");
        ICurveRegistry oldCurveReg = curveReg;
        curveReg = newCurveRegistry;
        emit curveRegistryUpdated(curveReg, oldCurveReg);
    }

    function setV2Pool(address[] calldata pool, bool[] calldata isV2Pool)
        external
        onlyOwner
    {
        require(pool.length == isV2Pool.length, "Invalid Input length");

        for (uint256 i = 0; i < pool.length; i++) {
            v2Pool[pool[i]] = isV2Pool[i];
            emit approvedV2Pool(pool[i], isV2Pool[i]);
        }
    }

    /// @notice Sweep tokens or ETH in case they get stuck in the contract
    function sweep(address[] memory _tokens, bool _ETH) external onlyOwner {
        if (_ETH) {
            uint256 balance = address(this).balance;
            (bool success, ) = msg.sender.call{value: address(this).balance}(
                ""
            );
            require(success, "Sending ETH failed");
            emit Sweep(ETHAddress, balance);
        }
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 amount = IERC20(_tokens[i]).balanceOf(address(this));
            IERC20(_tokens[i]).safeTransfer(owner(), amount);
            emit Sweep(_tokens[i], amount);
        }
    }
}