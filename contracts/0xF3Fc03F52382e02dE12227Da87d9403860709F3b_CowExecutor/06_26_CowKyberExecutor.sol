// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/Kyber.sol";
import "../Errors.sol";

/**
 * @title KyberExecutor
 * @notice Base contract that contains Kyber specific logic.
 * Kyber requires specific interface to be implemented so we have to provide a compliant implementation
 */
abstract contract CowKyberExecutor is ISwapCallback {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    bytes32 private constant SELECTORS = 0x0dfe1681d21220a7c79a590e0000000000000000000000000000000000000000;
    bytes32 private constant INIT_CODE_HASH = 0xc597aba1bb02db42ba24a8878837965718c032f8b46be94a6e46452a9f89ca01;
    bytes32 private constant PREFIXED_FACTORY = 0xff5f1dddbf348ac2fbe22a163e30f99f9ece3dd50a0000000000000000000000;
    uint256 private constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    function swapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        bool isBadPool;
        uint256 amountIn;
        uint256 amountOut;
        IERC20 token;

        uint256 minReturn;
        address cowSettlement;

        assembly {
            function reRevert() {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }

            let workingAddress := mload(0x40) // EVM free memory pointer
            mstore(workingAddress, SELECTORS)

            // we need to write hash just after the address PREFIXED_FACTORY constant in place of its zeroes,
            // hence offset is 21 bytes
            let feeTokensAddress := add(workingAddress, 21)
            if iszero(staticcall(gas(), caller(), workingAddress, 0x4, feeTokensAddress, 0x20)) {
                reRevert()
            }
            if iszero(staticcall(gas(), caller(), add(workingAddress, 0x4), 0x4, add(feeTokensAddress, 32), 0x20)) {
                reRevert()
            }
            if iszero(staticcall(gas(), caller(), add(workingAddress, 0x8), 0x4, add(feeTokensAddress, 64), 0x20)) {
                reRevert()
            }

            switch sgt(amount0Delta, 0)
            case 1 {
                amountIn := amount0Delta
                amountOut := sub(0, amount1Delta) // negate
                token := mload(feeTokensAddress)
            }
            default {
                amountIn := amount1Delta
                amountOut := sub(0, amount0Delta) // negate
                token := mload(add(feeTokensAddress, 32))
            }

            mstore(workingAddress, PREFIXED_FACTORY)
            mstore(feeTokensAddress, keccak256(feeTokensAddress, 96))
            mstore(add(feeTokensAddress, 32), INIT_CODE_HASH)
            let pool := and(keccak256(workingAddress, 85), ADDRESS_MASK)
            isBadPool := xor(pool, caller())

            minReturn := calldataload(data.offset)
            cowSettlement := calldataload(add(data.offset, 32))
        }

        if (isBadPool) {
            revert BadUniswapV3LikePool(UniswapV3LikeProtocol.Uniswap);
        }

        if (amountOut < minReturn) {
            revert MinReturnError(amountOut, minReturn);
        }

        token.safeTransferFrom(cowSettlement, msg.sender, amountIn);
    }
}