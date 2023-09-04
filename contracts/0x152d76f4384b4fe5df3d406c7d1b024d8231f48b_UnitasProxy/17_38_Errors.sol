// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/**
 * @notice Reverts with `errorCode` when `condition` is true
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) {
        _revert(errorCode);
    }
}

/**
 * @notice Reverts with `errorCode`
 * @dev The character length is 12, format: "Unitas: `errorCode`"
 */
function _revert(uint256 errorCode) pure {
    assembly {
        // ASCII 48 = 0
        // From right to left
        let one := add(mod(errorCode, 10), 48)
        let two := add(mod(div(errorCode, 10), 10), 48)
        let three := add(mod(div(errorCode, 100), 10), 48)
        let four := add(mod(div(errorCode, 1000), 10), 48)

        let err := shl(
            // 256 - 8 * 12
            160,
            add(
                shl(
                    // 4 spaces
                    32,
                    // "Unitas: "
                    0x556e697461733a20
                ),
                add(add(add(
                    one,
                    shl(8, two)),
                    shl(16, three)),
                    shl(24, four)
                )
            )
        )

        // bytes4(keccak256("Error(string)"))
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Offset
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // Character length
        mstore(0x24, 12)
        // Message
        mstore(0x44, err)

        // 4 + 32 + 32 + 32
        revert(0, 100)
    }
}

/**
 * @notice Error code definition to reduce contract size
 * @dev Range: 1000 - 9999
 */
library Errors {
    // ====================================================
    // Common (1000 - 1999)

    /**
     * @notice The input address is zero
     */
    uint256 internal constant ADDRESS_ZERO = 1000;
    /**
     * @notice The account code size of the input address is zero
     */
    uint256 internal constant ADDRESS_CODE_SIZE_ZERO = 1001;
    /**
     * @notice The parameters passed during function invocation are invalid
     */
    uint256 internal constant PARAMETER_INVALID = 1002;
    /**
     * @notice The input index or index + count is out of bounds of the array to be load
     */
    uint256 internal constant INPUT_OUT_OF_BOUNDS = 1003;
    /**
     * @notice There is a mismatch in the lengths of input arrays required by a function
     */
    uint256 internal constant ARRAY_LENGTH_MISMATCHED = 1004;
    /**
     * @notice The amount is zero or greater than the available pool balance
     */
    uint256 internal constant AMOUNT_INVALID = 1005;
    /**
     * @notice The address of the sender is not allowed to perform the operation
     */
    uint256 internal constant SENDER_INVALID = 1006;
    /**
     * @notice The address of the receiver is not allowed to perform the operation
     */
    uint256 internal constant RECEIVER_INVALID = 1007;
    /**
     * @notice The balance of the account is insufficient to perform the operation
     */
    uint256 internal constant BALANCE_INSUFFICIENT = 1008;
    /**
     * @notice The balance of the pool is insufficient to perform the operation
     */
    uint256 internal constant POOL_BALANCE_INSUFFICIENT = 1009;

    // ====================================================
    // Token, pair and related settings (2000 - 2099)

    /**
     * @notice The token type of the input is invalid
     */
    uint256 internal constant TOKEN_TYPE_INVALID = 2000;
    /**
     * @notice The token already exists in the pool
     */
    uint256 internal constant TOKEN_ALREADY_EXISTS = 2001;
    /**
     * @notice The token does not exist in the pool
     */
    uint256 internal constant TOKEN_NOT_EXISTS = 2002;
    /**
     * @notice The two token addresses passed as parameters are not sorted
     */
    uint256 internal constant TOKENS_NOT_SORTED = 2003;

    /**
     * @notice The pair already exists in the pool
     */
    uint256 internal constant PAIR_ALREADY_EXISTS = 2030;
    /**
     * @notice The pair does not exist in the pool
     */
    uint256 internal constant PAIR_NOT_EXISTS = 2031;
    /**
     * @notice Pairs associated with the token must be removed before removing the token
     */
    uint256 internal constant PAIRS_MUST_REMOVED = 2032;
    /**
     * @notice The two token addresses of the input are the same.
     *         One of the two token addresses must be USD1.
     */
    uint256 internal constant PAIR_INVALID = 2033;

    /**
     * @notice The min price tolerance is zero or greater than the max price tolerance
     */
    uint256 internal constant MIN_PRICE_INVALID = 2060;
    /**
     * @notice The max price tolerance is zero
     */
    uint256 internal constant MAX_PRICE_INVALID = 2061;
    /**
     * @notice A valid swapping fee numerator must be less than 1e6 (100%)
     */
    uint256 internal constant FEE_NUMERATOR_INVALID = 2062;
    /**
     * @notice A valid reserve ratio threshold must be zero or greater than or equal to 1e18 (100%)
     */
    uint256 internal constant RESERVE_RATIO_THRESHOLD_INVALID = 2063;
    /**
     * @notice When the address of USD1 is zero
     */
    uint256 internal constant USD1_NOT_SET = 2064;

    // ====================================================
    // Unitas & XOracle (2100 - 2199)

    /**
     * @notice The calculated swap result is invalid and cannot be executed
     */
    uint256 internal constant SWAP_RESULT_INVALID = 2100;
    /**
     * @notice The min and max price tolerances are invalid
     */
    uint256 internal constant PRICE_TOLERANCE_INVALID = 2101;
    /**
     * @notice The price from the oracle is not within the price tolerance range
     */
    uint256 internal constant PRICE_INVALID = 2102;
    /**
     * @notice The reserve ratio must be greater than the threshold when there is a reserve ratio limit for swapping
     */
    uint256 internal constant RESERVE_RATIO_NOT_GREATER_THAN_THRESHOLD = 2103;
    /**
     * @notice The numerator of the swapping fee must be less than the denominator when the numerator is greater than zero
     */
    uint256 internal constant FEE_FRACTION_INVALID = 2104;
    /**
     * @notice When the timestamp of the price exceeds the staleness threshold
     */
    uint256 internal constant PRICE_STALE = 2105;
}