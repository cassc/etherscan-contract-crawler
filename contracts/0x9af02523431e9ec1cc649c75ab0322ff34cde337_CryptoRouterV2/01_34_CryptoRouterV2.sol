// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./RouterV2.sol";
import "./interfaces/IAddressBook.sol";
import "./interfaces/ICryptoPoolAdapter.sol";


contract CryptoRouterV2 is RouterV2, ICryptoRouter {

    /// @dev add (crypto) operation code
    bytes32 public constant ADD_CRYPTO_CODE = keccak256(abi.encodePacked("Ac"));
    /// @dev remove (crypto) operation code
    bytes32 public constant REMOVE_CRYPTO_CODE = keccak256(abi.encodePacked("Rc"));
    /// @dev swap (crypto) operation code
    bytes32 public constant SWAP_CRYPTO_CODE = keccak256(abi.encodePacked("Sc"));

    constructor(address addressBook_) RouterV2(addressBook_) {}

    /**
     * @dev Should be implemented for each router.
     *
     * Each implementation must:
     * Revert execution if op is not supported;
     * Return chainId if current op is cross-chain; 
     */
    function _executeOp(
        bool isOpHalfDone,
        bytes32 op,
        bytes32 nextOp,
        bytes memory params,
        MaskedParams memory prevMaskedParams
    ) internal virtual override returns (uint64 chainIdTo, bytes memory updatedParams, MaskedParams memory maskedParams, ExecutionResult result) {
        (chainIdTo, updatedParams, maskedParams, result) = super._executeOp(isOpHalfDone, op, nextOp, params, prevMaskedParams);
        if (result == ExecutionResult.Failed) {
            result = ExecutionResult.Succeeded;
            address poolAdapter = IAddressBook(addressBook).cryptoPoolAdapter(uint64(block.chainid));
            if (ADD_CRYPTO_CODE == op) {
                AddCryptoParams memory p = abi.decode(params, (AddCryptoParams));
                (p.amountIn, p.from, p.emergencyTo) = _checkMaskedParams(p.amountIn, p.from, p.emergencyTo, maskedParams);
                p.to = _checkTo(p.to, p.emergencyTo, uint64(block.chainid), nextOp);
                if (p.from != poolAdapter) {
                    SafeERC20.safeTransferFrom(IERC20(p.tokenIn), p.from, poolAdapter, p.amountIn);
                }
                maskedParams.amountOut = ICryptoPoolAdapter(poolAdapter).addLiquidity(
                    p.pool,
                    p.amountIn,
                    p.i,
                    p.to,
                    p.minAmountOut,
                    p.emergencyTo
                );
                maskedParams.to = p.to;
                maskedParams.emergencyTo = p.emergencyTo;
                if (maskedParams.amountOut == 0) {
                    result = ExecutionResult.Interrupted;
                }
            } else if (REMOVE_CRYPTO_CODE == op) {
                RemoveCryptoParams memory p = abi.decode(params, (RemoveCryptoParams));
                (p.amountIn, p.from, p.emergencyTo) = _checkMaskedParams(p.amountIn, p.from, p.emergencyTo, maskedParams);
                p.to = _checkTo(p.to, p.emergencyTo, uint64(block.chainid), nextOp);
                if (p.from != poolAdapter) {
                    SafeERC20.safeTransferFrom(IERC20(p.tokenIn), p.from, poolAdapter, p.amountIn);
                }
                maskedParams.amountOut = ICryptoPoolAdapter(poolAdapter).removeLiquidity(
                    p.pool,
                    p.i,
                    p.to,
                    p.tokenOut,
                    p.minAmountOut,
                    p.emergencyTo
                );
                maskedParams.to = p.to;
                maskedParams.emergencyTo = p.emergencyTo;
                if (maskedParams.amountOut == 0) {
                    result = ExecutionResult.Interrupted;
                }
            } else if (SWAP_CRYPTO_CODE == op) {
                SwapCryptoParams memory p = abi.decode(params, (SwapCryptoParams));
                (p.amountIn, p.from, p.emergencyTo) = _checkMaskedParams(p.amountIn, p.from, p.emergencyTo, maskedParams);
                p.to = _checkTo(p.to, p.emergencyTo, uint64(block.chainid), nextOp);
                if (p.from != poolAdapter) {
                    SafeERC20.safeTransferFrom(IERC20(p.tokenIn), p.from, poolAdapter, p.amountIn);
                }
                maskedParams.amountOut = ICryptoPoolAdapter(poolAdapter).swap(
                    p.tokenIn,
                    p.pool,
                    p.i,
                    p.j,
                    p.tokenOut,
                    p.to,
                    p.minAmountOut,
                    p.emergencyTo,
                    p.aggregationFee
                );
                maskedParams.to = p.to;
                maskedParams.emergencyTo = p.emergencyTo;
                if (maskedParams.amountOut == 0) {
                    result = ExecutionResult.Interrupted;
                }
            } else {
                result = ExecutionResult.Failed;
            }
        }
    }

    function _checkTo(address to, address emergencyTo, uint64 chainId, bytes32 nextOp) internal view virtual override returns (address correctTo) {
        correctTo = super._checkTo(to, emergencyTo, chainId, nextOp);
        if (correctTo == address(0)) {
            if (nextOp == ADD_CRYPTO_CODE || nextOp == REMOVE_CRYPTO_CODE || nextOp == SWAP_CRYPTO_CODE) {
                correctTo = IAddressBook(addressBook).cryptoPoolAdapter(chainId);
            }
        }
    }
}