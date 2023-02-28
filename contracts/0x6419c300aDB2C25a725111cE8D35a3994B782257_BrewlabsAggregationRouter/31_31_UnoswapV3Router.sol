// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "@1inch/solidity-utils/contracts/EthReceiver.sol";
import "@1inch/solidity-utils/contracts/interfaces/IWETH.sol";

import "contracts/interfaces/IUniswapV3Pool.sol";
import "contracts/interfaces/IUniswapV3SwapCallback.sol";

import "contracts/helpers/RouterErrors.sol";

contract UnoswapV3Router is EthReceiver, IUniswapV3SwapCallback {
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
    uint256 private constant _ADDRESS_MASK =   0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 private constant _MIN_SQRT_RATIO = 4295128739 + 1;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 private constant _MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342 - 1;
    IWETH private immutable _WETH;  // solhint-disable-line var-name-mixedcase

    constructor(IWETH weth) {
        _WETH = weth;
    }

    /// @notice Same as `uniswapV3SwapTo` but calls permit first,
    /// allowing to approve token spending and make a swap in one transaction.
    /// @param recipient Address that will receive swap funds
    /// @param srcToken Source token
    /// @param amount Amount of source tokens to swap
    /// @param minReturn Minimal allowed returnAmount to make transaction commit
    /// @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
    /// @param permit Should contain valid permit that can be used in `IERC20Permit.permit` calls.
    /// See tests for examples
    function uniswapV3SwapToWithPermit(
        address payable recipient,
        IERC20 srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools,
        bytes calldata permit
    ) internal returns(uint256 returnAmount) {
        srcToken.safePermit(permit);
        return _uniswapV3Swap(recipient, amount, minReturn, pools, msg.value);
    }

    /// @notice Same as `uniswapV3SwapTo` but uses `msg.sender` as recipient
    /// @param amount Amount of source tokens to swap
    /// @param minReturn Minimal allowed returnAmount to make transaction commit
    /// @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
    function uniswapV3Swap(
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) internal returns(uint256 returnAmount) {
        return _uniswapV3Swap(payable(msg.sender), amount, minReturn, pools, msg.value);
    }

    /// @notice Performs swap using Uniswap V3 exchange. Wraps and unwraps ETH if required.
    /// Sending non-zero `msg.value` for anything but ETH swaps is prohibited
    /// @param recipient Address that will receive swap funds
    /// @param amount Amount of source tokens to swap
    /// @param minReturn Minimal allowed returnAmount to make transaction commit
    /// @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
    function uniswapV3SwapTo(
        address payable recipient,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools,
        uint256 msgValue
    ) internal returns(uint256 returnAmount) {
        return _uniswapV3Swap(recipient, amount, minReturn, pools, msgValue);
    }

    function _uniswapV3Swap(
        address payable recipient,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools,
        uint256 msgValue
    ) private returns(uint256 returnAmount) {
        unchecked {
            uint256 len = pools.length;
            if (len == 0) revert EmptyPools();
            uint256 lastIndex = len - 1;
            returnAmount = amount;
            bool wrapWeth = msgValue > 0;
            bool unwrapWeth = pools[lastIndex] & _WETH_UNWRAP_MASK > 0;
            if (wrapWeth) {
                if (msgValue != amount) revert RouterErrors.InvalidMsgValue();
                _WETH.deposit{value: amount}();
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

    /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata /* data */
    ) external override {
        assembly {  // solhint-disable-line no-inline-assembly
            function reRevert() {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            function validateERC20Transfer(status) {
                if iszero(status) {
                    reRevert()
                }
                let success := or(
                    iszero(returndatasize()),                       // empty return data
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
            return SafeCast.toUint256(-amount1);
        } else {
            (int256 amount0,) = IUniswapV3Pool(address(uint160(pool))).swap(
                recipient,
                zeroForOne,
                SafeCast.toInt256(amount),
                _MAX_SQRT_RATIO,
                abi.encode(payer)
            );
            return SafeCast.toUint256(-amount0);
        }
    }
}