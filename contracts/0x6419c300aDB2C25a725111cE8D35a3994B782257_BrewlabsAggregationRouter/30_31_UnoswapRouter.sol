// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/UniERC20.sol";
import "@1inch/solidity-utils/contracts/EthReceiver.sol";

import "contracts/helpers/RouterErrors.sol";

contract UnoswapRouter is EthReceiver {
    using UniERC20 for IERC20;
    using SafeERC20 for IERC20;

    error ReservesCallFailed();
    error SwapAmountTooLarge();

    bytes4 private constant _TRANSFER_FROM_CALL_SELECTOR = 0x23b872dd;
    bytes4 private constant _WETH_DEPOSIT_CALL_SELECTOR = 0xd0e30db0;
    bytes4 private constant _WETH_WITHDRAW_CALL_SELECTOR = 0x2e1a7d4d;
    bytes4 private constant _ERC20_TRANSFER_CALL_SELECTOR = 0xa9059cbb;
    uint256 private constant _ADDRESS_MASK =   0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant _REVERSE_MASK =   0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _WETH_MASK =      0x4000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _NUMERATOR_MASK = 0x0000000000000000ffffffff0000000000000000000000000000000000000000;
    /// @dev WETH address is network-specific and needs to be changed before deployment.
    /// It can not be moved to immutable as immutables are not supported in assembly
    address private constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    bytes4 private constant _UNISWAP_PAIR_RESERVES_CALL_SELECTOR = 0x0902f1ac;
    bytes4 private constant _UNISWAP_PAIR_SWAP_CALL_SELECTOR = 0x022c0d9f;
    uint256 private constant _DENOMINATOR = 1e9;
    uint256 private constant _NUMERATOR_OFFSET = 160;
    uint256 private constant _MAX_SWAP_AMOUNT = (1 << 112) - 1;  // type(uint112).max;

    /// @notice Same as `unoswapTo` but calls permit first,
    /// allowing to approve token spending and make a swap in one transaction.
    /// @param recipient Address that will receive swapped funds
    /// @param srcToken Source token
    /// @param amount Amount of source tokens to swap
    /// @param minReturn Minimal allowed returnAmount to make transaction commit
    /// @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
    /// @param permit Should contain valid permit that can be used in `IERC20Permit.permit` calls.
    /// See tests for examples
    function unoswapToWithPermit(
        address payable recipient,
        IERC20 srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools,
        bytes calldata permit
    ) external returns(uint256 returnAmount) {
        srcToken.safePermit(permit);
        return _unoswap(recipient, srcToken, amount, minReturn, pools);
    }

    /// @notice Performs swap using Uniswap exchange. Wraps and unwraps ETH if required.
    /// Sending non-zero `msg.value` for anything but ETH swaps is prohibited
    /// @param recipient Address that will receive swapped funds
    /// @param srcToken Source token
    /// @param amount Amount of source tokens to swap
    /// @param minReturn Minimal allowed returnAmount to make transaction commit
    /// @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
    function unoswapTo(
        address payable recipient,
        IERC20 srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns(uint256 returnAmount) {
        return _unoswap(recipient, srcToken, amount, minReturn, pools);
    }

    /// @notice Performs swap using Uniswap exchange. Wraps and unwraps ETH if required.
    /// Sending non-zero `msg.value` for anything but ETH swaps is prohibited
    /// @param srcToken Source token
    /// @param amount Amount of source tokens to swap
    /// @param minReturn Minimal allowed returnAmount to make transaction commit
    /// @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
    function unoswap(
        IERC20 srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) internal returns(uint256 returnAmount) {
        return _unoswap(payable(msg.sender), srcToken, amount, minReturn, pools);
    }

    function _unoswap(
        address payable recipient,
        IERC20 srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) private returns(uint256 returnAmount) {
        bytes4 selector = srcToken.balanceOf.selector;
        assembly {
            function reRevert() {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
            function amountIn(emptyPtr, pair, reversed, balance0) -> ret {
                mstore(emptyPtr, _UNISWAP_PAIR_RESERVES_CALL_SELECTOR)
                if iszero(staticcall(gas(), pair, emptyPtr, 0x4, emptyPtr, 0x40)) {
                    reRevert()
                }
                if iszero(eq(returndatasize(), 0x60)) {
                    mstore(0, 0x85cd58dc00000000000000000000000000000000000000000000000000000000)  // ReservesCallFailed()
                    revert(0, 4)
                }
                let reserve0 := mload(emptyPtr)
                let reserve1 := mload(add(emptyPtr, 0x20))
                if reversed {
                    let tmp := reserve0
                    reserve0 := reserve1
                    reserve1 := tmp
                }
                ret := sub(balance0, reserve0)
            }
            function swap(emptyPtr, swapAmount, pair, reversed, numerator, to) -> ret {
                mstore(emptyPtr, _UNISWAP_PAIR_RESERVES_CALL_SELECTOR)
                if iszero(staticcall(gas(), pair, emptyPtr, 0x4, emptyPtr, 0x40)) {
                    reRevert()
                }
                if iszero(eq(returndatasize(), 0x60)) {
                    mstore(0, 0x85cd58dc00000000000000000000000000000000000000000000000000000000)  // ReservesCallFailed()
                    revert(0, 4)
                }

                let reserve0 := mload(emptyPtr)
                let reserve1 := mload(add(emptyPtr, 0x20))
                if reversed {
                    let tmp := reserve0
                    reserve0 := reserve1
                    reserve1 := tmp
                }
                // this will not overflow as reserve0, reserve1 and ret fit to 112 bit and numerator and _DENOMINATOR fit to 32 bit
                ret := mul(swapAmount, numerator)
                ret := div(mul(ret, reserve1), add(ret, mul(reserve0, _DENOMINATOR)))

                mstore(emptyPtr, _UNISWAP_PAIR_SWAP_CALL_SELECTOR)
                reversed := iszero(reversed)
                mstore(add(emptyPtr, 0x04), mul(ret, iszero(reversed)))
                mstore(add(emptyPtr, 0x24), mul(ret, reversed))
                mstore(add(emptyPtr, 0x44), to)
                mstore(add(emptyPtr, 0x64), 0x80)
                mstore(add(emptyPtr, 0x84), 0)
                if iszero(call(gas(), pair, 0, emptyPtr, 0xa4, 0, 0)) {
                    reRevert()
                }
            }

            // make sure that input amount fits in 112 bit
            if gt(amount, _MAX_SWAP_AMOUNT) {
                mstore(0, 0xcf0b4d3a00000000000000000000000000000000000000000000000000000000)  // SwapAmountTooLarge()
                revert(0, 4)
            }

            let emptyPtr := mload(0x40)
            mstore(0x40, add(emptyPtr, 0xc0))

            let rawPair := calldataload(pools.offset)

            switch srcToken
            case 0 {
                mstore(emptyPtr, _WETH_DEPOSIT_CALL_SELECTOR)
                if iszero(call(gas(), _WETH, amount, emptyPtr, 0x4, 0, 0)) {
                    reRevert()
                }

                mstore(emptyPtr, _ERC20_TRANSFER_CALL_SELECTOR)
                mstore(add(emptyPtr, 0x4), and(rawPair, _ADDRESS_MASK))
                mstore(add(emptyPtr, 0x24), amount)
                if iszero(call(gas(), _WETH, 0, emptyPtr, 0x44, 0, 0)) {
                    reRevert()
                }

                returnAmount := amount
            }
            default {
                mstore(emptyPtr, _TRANSFER_FROM_CALL_SELECTOR)
                mstore(add(emptyPtr, 0x4), caller())
                mstore(add(emptyPtr, 0x24), and(rawPair, _ADDRESS_MASK))
                mstore(add(emptyPtr, 0x44), amount)
                if iszero(call(gas(), srcToken, 0, emptyPtr, 0x64, 0, 0x20)) {
                    reRevert()
                }

                mstore(emptyPtr, selector)
                mstore(add(emptyPtr, 0x4), and(rawPair, _ADDRESS_MASK))
                if iszero(call(gas(), srcToken, 0, emptyPtr, 0x24, 0x0, 0x20)) {
                    reRevert()
                }
                
                returnAmount := amountIn(
                    emptyPtr, 
                    and(rawPair, _ADDRESS_MASK), 
                    and(rawPair, _REVERSE_MASK), 
                    mload(0x0)
                )
            }

            for {let i := add(pools.offset, 0x20)} lt(i, add(pools.offset, shl(5, pools.length))) {i := add(i, 0x20)} {
                let nextRawPair := calldataload(i)

                returnAmount := swap(
                    emptyPtr,
                    returnAmount,
                    and(rawPair, _ADDRESS_MASK),
                    and(rawPair, _REVERSE_MASK),
                    shr(_NUMERATOR_OFFSET, and(rawPair, _NUMERATOR_MASK)),
                    and(nextRawPair, _ADDRESS_MASK)
                )

                rawPair := nextRawPair
            }

            switch and(rawPair, _WETH_MASK)
            case 0 {
                returnAmount := swap(
                    emptyPtr,
                    returnAmount,
                    and(rawPair, _ADDRESS_MASK),
                    and(rawPair, _REVERSE_MASK),
                    shr(_NUMERATOR_OFFSET, and(rawPair, _NUMERATOR_MASK)),
                    recipient
                )
            }
            default {
                returnAmount := swap(
                    emptyPtr,
                    returnAmount,
                    and(rawPair, _ADDRESS_MASK),
                    and(rawPair, _REVERSE_MASK),
                    shr(_NUMERATOR_OFFSET, and(rawPair, _NUMERATOR_MASK)),
                    address()
                )

                mstore(emptyPtr, _WETH_WITHDRAW_CALL_SELECTOR)
                mstore(add(emptyPtr, 0x04), returnAmount)
                if iszero(call(gas(), _WETH, 0, emptyPtr, 0x24, 0, 0)) {
                    reRevert()
                }

                if iszero(call(gas(), recipient, returnAmount, 0, 0, 0, 0)) {
                    reRevert()
                }
            }
        }
        if (returnAmount < minReturn) revert RouterErrors.ReturnAmountIsNotEnough();
    }
}