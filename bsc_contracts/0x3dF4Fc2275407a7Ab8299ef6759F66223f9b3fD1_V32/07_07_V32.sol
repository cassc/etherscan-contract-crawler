// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

interface IUniswapV3SwapCallback {
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

interface IUniswapV3Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function fee() external view returns (uint24);
}

library RouterErrors {
error ReturnAmountIsNotEnough();
error InvalidMsgValue();
error ERC20TransferFailed();
}

library SafeERC20 {
error SafeTransferFailed();
error SafeTransferFromFailed();
function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
bytes4 selector = token.transferFrom.selector;
bool success;
/// @solidity memory-safe-assembly
assembly {// solhint-disable-line no-inline-assembly
let data := mload(0x40)

mstore(data, selector)
mstore(add(data, 0x04), from)
mstore(add(data, 0x24), to)
mstore(add(data, 0x44), amount)
success := call(gas(), token, 0, data, 100, 0x0, 0x20)
if success {
switch returndatasize()
case 0 {success := gt(extcodesize(token), 0)}
default {success := and(gt(returndatasize(), 31), eq(mload(0), 1))}
}
}
if (!success) revert SafeTransferFromFailed();
}

function safeTransfer(IERC20 token, address to, uint256 value) internal {
if (!_makeCall(token, token.transfer.selector, to, value)) {
revert SafeTransferFailed();
}
}

function _makeCall(IERC20 token, bytes4 selector, address to, uint256 amount) private returns (bool success) {
/// @solidity memory-safe-assembly
assembly {// solhint-disable-line no-inline-assembly
let data := mload(0x40)

mstore(data, selector)
mstore(add(data, 0x04), to)
mstore(add(data, 0x24), amount)
success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
if success {
switch returndatasize()
case 0 {success := gt(extcodesize(token), 0)}
default {success := and(gt(returndatasize(), 31), eq(mload(0), 1))}
}
}
}

}

contract V32 is IUniswapV3SwapCallback {
using Address for address payable;
using SafeERC20 for IERC20;
error EmptyPools();
error BadPool();
uint256 private constant _ONE_FOR_ZERO_MASK = 1 << 255;
uint256 private constant _WETH_UNWRAP_MASK = 1 << 253;
bytes32 private constant _POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
bytes32 private constant _FF_FACTORY = 0xff1F98431c8aD98523631AE4a59f267346ea31F9840000000000000000000000;
// concatenation of token0(), token1() fee(), transfer() and transferFrom() selectors
bytes32 private constant _SELECTORS = 0x0dfe1681d21220a7ddca3f43a9059cbb23b872dd000000000000000000000000;
uint256 private constant _ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
/// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
uint160 private constant _MIN_SQRT_RATIO = 4295128739 + 1;
/// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
uint160 private constant _MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342 - 1;
IWETH private immutable _WETH;  // solhint-disable-line var-name-mixedcase

constructor(IWETH weth) {
_WETH = weth;
}

function uniswapV3Swap(
uint256 amount,
uint256 minReturn,
uint256[] calldata pools
) external payable returns (uint256 returnAmount) {
return _uniswapV3Swap(payable(msg.sender), amount, minReturn, pools);
}

function uniswapV3SwapTo(
address payable recipient,
uint256 amount,
uint256 minReturn,
uint256[] calldata pools
) external payable returns (uint256 returnAmount) {
return _uniswapV3Swap(recipient, amount, minReturn, pools);
}

function _uniswapV3Swap(
address payable recipient,
uint256 amount,
uint256 minReturn,
uint256[] calldata pools
) private returns (uint256 returnAmount) {
unchecked {
uint256 len = pools.length;
if (len == 0) revert EmptyPools();
uint256 lastIndex = len - 1;
returnAmount = amount;
bool wrapWeth = msg.value > 0;
bool unwrapWeth = pools[lastIndex] & _WETH_UNWRAP_MASK > 0;
if (wrapWeth) {
if (msg.value != amount) revert RouterErrors.InvalidMsgValue();
_WETH.deposit{value : amount}();
}
if (len > 1) {
returnAmount = _makeSwap(address(this), wrapWeth ? address(this) : msg.sender, pools[0], returnAmount);

for (uint256 i = 1; i < lastIndex; i++) {
returnAmount = _makeSwap(address(this), address(this), pools[i], returnAmount);
}
returnAmount = _makeSwap(unwrapWeth ? address(this) : recipient, address(this), pools[lastIndex], returnAmount);
} else {
returnAmount = _makeSwap(unwrapWeth ? address(this) : recipient, wrapWeth ? address(this) : msg.sender, pools[0], returnAmount);
}

if (returnAmount < minReturn) revert RouterErrors.ReturnAmountIsNotEnough();

if (unwrapWeth) {
_WETH.withdraw(returnAmount);
recipient.sendValue(returnAmount);
}
}
}

function uniswapV3SwapCallback(
int256 amount0Delta,
int256 amount1Delta,
bytes calldata /* data */
) external override {
assembly {// solhint-disable-line no-inline-assembly
function reRevert() {
returndatacopy(0, 0, returndatasize())
revert(0, returndatasize())
}

function validateERC20Transfer(status) {
if iszero(status) {
reRevert()
}
let success := or(
iszero(returndatasize()), // empty return data
and(gt(returndatasize(), 31), eq(mload(0), 1))  // true in return data
)
if iszero(success) {
mstore(0, 0xf27f64e400000000000000000000000000000000000000000000000000000000)  // ERC20TransferFailed()
revert(0, 4)
}
}

let emptyPtr := mload(0x40)
let resultPtr := add(emptyPtr, 0x15)  // 0x15 = _FF_FACTORY size

mstore(emptyPtr, _SELECTORS)
if iszero(staticcall(gas(), caller(), emptyPtr, 0x4, resultPtr, 0x20)) {
reRevert()
}
if iszero(staticcall(gas(), caller(), add(emptyPtr, 0x4), 0x4, add(resultPtr, 0x20), 0x20)) {
reRevert()
}
if iszero(staticcall(gas(), caller(), add(emptyPtr, 0x8), 0x4, add(resultPtr, 0x40), 0x20)) {
reRevert()
}

let token
let amount
switch sgt(amount0Delta, 0)
case 1 {
token := mload(resultPtr)
amount := amount0Delta
}
default {
token := mload(add(resultPtr, 0x20))
amount := amount1Delta
}

mstore(emptyPtr, _FF_FACTORY)
mstore(resultPtr, keccak256(resultPtr, 0x60)) // Compute the inner hash in-place
mstore(add(resultPtr, 0x20), _POOL_INIT_CODE_HASH)
let pool := and(keccak256(emptyPtr, 0x55), _ADDRESS_MASK)
if xor(pool, caller()) {
mstore(0, 0xb2c0272200000000000000000000000000000000000000000000000000000000)  // BadPool()
revert(0, 4)
}

let payer := calldataload(0x84)
mstore(emptyPtr, _SELECTORS)
switch eq(payer, address())
case 1 {
// token.safeTransfer(msg.sender,amount)
mstore(add(emptyPtr, 0x10), caller())
mstore(add(emptyPtr, 0x30), amount)
validateERC20Transfer(
call(gas(), token, 0, add(emptyPtr, 0x0c), 0x44, 0, 0x20)
)
}
default {
// token.safeTransferFrom(payer, msg.sender, amount);
mstore(add(emptyPtr, 0x14), payer)
mstore(add(emptyPtr, 0x34), caller())
mstore(add(emptyPtr, 0x54), amount)
validateERC20Transfer(
call(gas(), token, 0, add(emptyPtr, 0x10), 0x64, 0, 0x20)
)
}
}
}

function _makeSwap(address recipient, address payer, uint256 pool, uint256 amount) private returns (uint256) {
bool zeroForOne = pool & _ONE_FOR_ZERO_MASK == 0;
if (zeroForOne) {
(, int256 amount1) = IUniswapV3Pool(address(uint160(pool))).swap(
recipient,
zeroForOne,
SafeCast.toInt256(amount),
_MIN_SQRT_RATIO,
abi.encode(payer)
);
return SafeCast.toUint256(- amount1);
} else {
(int256 amount0,) = IUniswapV3Pool(address(uint160(pool))).swap(
recipient,
zeroForOne,
SafeCast.toInt256(amount),
_MAX_SQRT_RATIO,
abi.encode(payer)
);
return SafeCast.toUint256(- amount0);
}
}
}

// contract UnoswapRouter  {
//     using SafeERC20 for IERC20;
//     error ReservesCallFailed();
//     error SwapAmountTooLarge();
//     bytes4 private constant _TRANSFER_FROM_CALL_SELECTOR = 0x23b872dd;
//     bytes4 private constant _WETH_DEPOSIT_CALL_SELECTOR = 0xd0e30db0;
//     bytes4 private constant _WETH_WITHDRAW_CALL_SELECTOR = 0x2e1a7d4d;
//     bytes4 private constant _ERC20_TRANSFER_CALL_SELECTOR = 0xa9059cbb;
//     uint256 private constant _ADDRESS_MASK =   0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
//     uint256 private constant _REVERSE_MASK =   0x8000000000000000000000000000000000000000000000000000000000000000;
//     uint256 private constant _WETH_MASK =      0x4000000000000000000000000000000000000000000000000000000000000000;
//     uint256 private constant _NUMERATOR_MASK = 0x0000000000000000ffffffff0000000000000000000000000000000000000000;
//     /// @dev WETH address is network-specific and needs to be changed before deployment.
//     /// It can not be moved to immutable as immutables are not supported in assembly
//     address private constant _WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
//     bytes4 private constant _UNISWAP_PAIR_RESERVES_CALL_SELECTOR = 0x0902f1ac;
//     bytes4 private constant _UNISWAP_PAIR_SWAP_CALL_SELECTOR = 0x022c0d9f;
//     uint256 private constant _DENOMINATOR = 1e9;
//     uint256 private constant _NUMERATOR_OFFSET = 160;
//     uint256 private constant _MAX_SWAP_AMOUNT = (1 << 112) - 1;  // type(uint112).max;

//     /// @notice Same as `unoswapTo` but calls permit first,
//     /// allowing to approve token spending and make a swap in one transaction.
//     /// @param recipient Address that will receive swapped funds
//     /// @param srcToken Source token
//     /// @param amount Amount of source tokens to swap
//     /// @param minReturn Minimal allowed returnAmount to make transaction commit
//     /// @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
//     /// @param permit Should contain valid permit that can be used in `IERC20Permit.permit` calls.
//     /// See tests for examples
//     // function unoswapToWithPermit(
//     //     address payable recipient,
//     //     IERC20 srcToken,
//     //     uint256 amount,
//     //     uint256 minReturn,
//     //     uint256[] calldata pools,
//     //     bytes calldata permit
//     // ) external returns(uint256 returnAmount) {
//     //     srcToken.safePermit(permit);
//     //     return _unoswap(recipient, srcToken, amount, minReturn, pools);
//     // }

//     /// @notice Performs swap using Uniswap exchange. Wraps and unwraps ETH if required.
//     /// Sending non-zero `msg.value` for anything but ETH swaps is prohibited
//     /// @param recipient Address that will receive swapped funds
//     /// @param srcToken Source token
//     /// @param amount Amount of source tokens to swap
//     /// @param minReturn Minimal allowed returnAmount to make transaction commit
//     /// @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
//     function unoswapTo(
//         address payable recipient,
//         IERC20 srcToken,
//         uint256 amount,
//         uint256 minReturn,
//         uint256[] calldata pools
//     ) external payable returns(uint256 returnAmount) {
//         return _unoswap(recipient, srcToken, amount, minReturn, pools);
//     }

//     /// @notice Performs swap using Uniswap exchange. Wraps and unwraps ETH if required.
//     /// Sending non-zero `msg.value` for anything but ETH swaps is prohibited
//     /// @param srcToken Source token
//     /// @param amount Amount of source tokens to swap
//     /// @param minReturn Minimal allowed returnAmount to make transaction commit
//     /// @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
//     function unoswap(
//         IERC20 srcToken,
//         uint256 amount,
//         uint256 minReturn,
//         uint256[] calldata pools
//     ) external payable returns(uint256 returnAmount) {
//         return _unoswap(payable(msg.sender), srcToken, amount, minReturn, pools);
//     }

//     function _unoswap(
//         address payable recipient,
//         IERC20 srcToken,
//         uint256 amount,
//         uint256 minReturn,
//         uint256[] calldata pools
//     ) private returns(uint256 returnAmount) {
//         assembly {  // solhint-disable-line no-inline-assembly
//             function reRevert() {
//                 returndatacopy(0, 0, returndatasize())
//                 revert(0, returndatasize())
//             }

//             function validateERC20Transfer(status) {
//                 if iszero(status) {
//                     reRevert()
//                 }
//                 let success := or(
//                     iszero(returndatasize()),                       // empty return data
//                     and(gt(returndatasize(), 31), eq(mload(0), 1))  // true in return data
//                 )
//                 if iszero(success) {
//                     mstore(0, 0xf27f64e400000000000000000000000000000000000000000000000000000000)  // ERC20TransferFailed()
//                     revert(0, 4)
//                 }
//             }

//             function swap(emptyPtr, swapAmount, pair, reversed, numerator, to) -> ret {
//                 mstore(emptyPtr, _UNISWAP_PAIR_RESERVES_CALL_SELECTOR)
//                 if iszero(staticcall(gas(), pair, emptyPtr, 0x4, emptyPtr, 0x40)) {
//                     reRevert()
//                 }
//                 if iszero(eq(returndatasize(), 0x60)) {
//                     mstore(0, 0x85cd58dc00000000000000000000000000000000000000000000000000000000)  // ReservesCallFailed()
//                     revert(0, 4)
//                 }

//                 let reserve0 := mload(emptyPtr)
//                 let reserve1 := mload(add(emptyPtr, 0x20))
//                 if reversed {
//                     let tmp := reserve0
//                     reserve0 := reserve1
//                     reserve1 := tmp
//                 }
//                 // this will not overflow as reserve0, reserve1 and ret fit to 112 bit and numerator and _DENOMINATOR fit to 32 bit
//                 ret := mul(swapAmount, numerator)
//                 ret := div(mul(ret, reserve1), add(ret, mul(reserve0, _DENOMINATOR)))

//                 mstore(emptyPtr, _UNISWAP_PAIR_SWAP_CALL_SELECTOR)
//                 reversed := iszero(reversed)
//                 mstore(add(emptyPtr, 0x04), mul(ret, iszero(reversed)))
//                 mstore(add(emptyPtr, 0x24), mul(ret, reversed))
//                 mstore(add(emptyPtr, 0x44), to)
//                 mstore(add(emptyPtr, 0x64), 0x80)
//                 mstore(add(emptyPtr, 0x84), 0)
//                 if iszero(call(gas(), pair, 0, emptyPtr, 0xa4, 0, 0)) {
//                     reRevert()
//                 }
//             }

//             // make sure that input amount fits in 112 bit
//             if gt(amount, _MAX_SWAP_AMOUNT) {
//                 mstore(0, 0xcf0b4d3a00000000000000000000000000000000000000000000000000000000)  // SwapAmountTooLarge()
//                 revert(0, 4)
//             }

//             let emptyPtr := mload(0x40)
//             mstore(0x40, add(emptyPtr, 0xc0))

//             let poolsEndOffset := add(pools.offset, shl(5, pools.length))
//             let rawPair := calldataload(pools.offset)
//             switch srcToken
//             case 0 {
//                 if iszero(eq(amount, callvalue())) {
//                     mstore(0, 0x1841b4e100000000000000000000000000000000000000000000000000000000)  // InvalidMsgValue()
//                     revert(0, 4)
//                 }

//                 mstore(emptyPtr, _WETH_DEPOSIT_CALL_SELECTOR)
//                 if iszero(call(gas(), _WETH, amount, emptyPtr, 0x4, 0, 0)) {
//                     reRevert()
//                 }

//                 mstore(emptyPtr, _ERC20_TRANSFER_CALL_SELECTOR)
//                 mstore(add(emptyPtr, 0x4), and(rawPair, _ADDRESS_MASK))
//                 mstore(add(emptyPtr, 0x24), amount)
//                 if iszero(call(gas(), _WETH, 0, emptyPtr, 0x44, 0, 0)) {
//                     reRevert()
//                 }
//             }
//             default {
//                 if callvalue() {
//                     mstore(0, 0x1841b4e100000000000000000000000000000000000000000000000000000000)  // InvalidMsgValue()
//                     revert(0, 4)
//                 }

//                 mstore(emptyPtr, _TRANSFER_FROM_CALL_SELECTOR)
//                 mstore(add(emptyPtr, 0x4), caller())
//                 mstore(add(emptyPtr, 0x24), and(rawPair, _ADDRESS_MASK))
//                 mstore(add(emptyPtr, 0x44), amount)
//                 validateERC20Transfer(
//                     call(gas(), srcToken, 0, emptyPtr, 0x64, 0, 0x20)
//                 )
//             }

//             returnAmount := amount

//             for {let i := add(pools.offset, 0x20)} lt(i, poolsEndOffset) {i := add(i, 0x20)} {
//                 let nextRawPair := calldataload(i)

//                 returnAmount := swap(
//                     emptyPtr,
//                     returnAmount,
//                     and(rawPair, _ADDRESS_MASK),
//                     and(rawPair, _REVERSE_MASK),
//                     shr(_NUMERATOR_OFFSET, and(rawPair, _NUMERATOR_MASK)),
//                     and(nextRawPair, _ADDRESS_MASK)
//                 )

//                 rawPair := nextRawPair
//             }

//             switch and(rawPair, _WETH_MASK)
//             case 0 {
//                 returnAmount := swap(
//                     emptyPtr,
//                     returnAmount,
//                     and(rawPair, _ADDRESS_MASK),
//                     and(rawPair, _REVERSE_MASK),
//                     shr(_NUMERATOR_OFFSET, and(rawPair, _NUMERATOR_MASK)),
//                     recipient
//                 )
//             }
//             default {
//                 returnAmount := swap(
//                     emptyPtr,
//                     returnAmount,
//                     and(rawPair, _ADDRESS_MASK),
//                     and(rawPair, _REVERSE_MASK),
//                     shr(_NUMERATOR_OFFSET, and(rawPair, _NUMERATOR_MASK)),
//                     address()
//                 )

//                 mstore(emptyPtr, _WETH_WITHDRAW_CALL_SELECTOR)
//                 mstore(add(emptyPtr, 0x04), returnAmount)
//                 if iszero(call(gas(), _WETH, 0, emptyPtr, 0x24, 0, 0)) {
//                     reRevert()
//                 }

//                 if iszero(call(gas(), recipient, returnAmount, 0, 0, 0, 0)) {
//                     reRevert()
//                 }
//             }
//         }
//         if (returnAmount < minReturn) revert RouterErrors.ReturnAmountIsNotEnough();
//     }
// }