/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

/// @title BaseERC20
/// @author zefram.eth
/// @notice The base ERC20 contract used by NegativeYieldToken and PerpetualYieldToken
/// @dev Uses the same number of decimals as the vault's underlying token
contract BaseERC20 is ERC20 {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error Error_NotGate();

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    Gate public immutable gate;
    address public immutable vault;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        string memory name_,
        string memory symbol_,
        Gate gate_,
        address vault_
    ) ERC20(name_, symbol_, gate_.getUnderlyingOfVault(vault_).decimals()) {
        gate = gate_;
        vault = vault_;
    }

    /// -----------------------------------------------------------------------
    /// Gate-callable functions
    /// -----------------------------------------------------------------------

    function gateMint(address to, uint256 amount) external virtual {
        if (msg.sender != address(gate)) {
            revert Error_NotGate();
        }

        _mint(to, amount);
    }

    function gateBurn(address from, uint256 amount) external virtual {
        if (msg.sender != address(gate)) {
            revert Error_NotGate();
        }

        _burn(from, amount);
    }
}

/// @title NegativeYieldToken
/// @author zefram.eth
/// @notice The ERC20 contract representing negative yield tokens
contract NegativeYieldToken is BaseERC20 {
    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(Gate gate_, address vault_)
        BaseERC20(
            gate_.negativeYieldTokenName(vault_),
            gate_.negativeYieldTokenSymbol(vault_),
            gate_,
            vault_
        )
    {}
}

/// @title PerpetualYieldToken
/// @author zefram.eth
/// @notice The ERC20 contract representing perpetual yield tokens
contract PerpetualYieldToken is BaseERC20 {
    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(Gate gate_, address vault_)
        BaseERC20(
            gate_.perpetualYieldTokenName(vault_),
            gate_.perpetualYieldTokenSymbol(vault_),
            gate_,
            vault_
        )
    {}

    /// -----------------------------------------------------------------------
    /// ERC20 overrides
    /// -----------------------------------------------------------------------

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        // load balances to save gas
        uint256 fromBalance = balanceOf[msg.sender];
        uint256 toBalance = balanceOf[to];

        // call transfer hook
        gate.beforePerpetualYieldTokenTransfer(
            msg.sender,
            to,
            amount,
            fromBalance,
            toBalance
        );

        // do transfer
        // skip during self transfers since toBalance is cached
        // which leads to free minting, a critical issue
        if (msg.sender != to) {
            balanceOf[msg.sender] = fromBalance - amount;

            // Cannot overflow because the sum of all user
            // balances can't exceed the max uint256 value.
            unchecked {
                balanceOf[to] = toBalance + amount;
            }
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        // load balances to save gas
        uint256 fromBalance = balanceOf[from];
        uint256 toBalance = balanceOf[to];

        // call transfer hook
        gate.beforePerpetualYieldTokenTransfer(
            from,
            to,
            amount,
            fromBalance,
            toBalance
        );

        // update allowance
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        // do transfer
        // skip during self transfers since toBalance is cached
        // which leads to free minting, a critical issue
        if (from != to) {
            balanceOf[from] = fromBalance - amount;

            // Cannot overflow because the sum of all user
            // balances can't exceed the max uint256 value.
            unchecked {
                balanceOf[to] = toBalance + amount;
            }
        }

        emit Transfer(from, to, amount);

        return true;
    }
}

contract Factory is BoringOwnable {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using Bytes32AddressLib for address;
    using Bytes32AddressLib for bytes32;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error Error_ProtocolFeeRecipientIsZero();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event SetProtocolFee(ProtocolFeeInfo protocolFeeInfo_);
    event DeployYieldTokenPair(
        Gate indexed gate,
        address indexed vault,
        NegativeYieldToken nyt,
        PerpetualYieldToken pyt
    );

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    struct ProtocolFeeInfo {
        uint8 fee; // each increment represents 0.1%, so max is 25.5%
        address recipient;
    }
    /// @notice The protocol fee and the fee recipient address.
    ProtocolFeeInfo public protocolFeeInfo;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(ProtocolFeeInfo memory protocolFeeInfo_) {
        if (
            protocolFeeInfo_.fee != 0 &&
            protocolFeeInfo_.recipient == address(0)
        ) {
            revert Error_ProtocolFeeRecipientIsZero();
        }
        protocolFeeInfo = protocolFeeInfo_;
        emit SetProtocolFee(protocolFeeInfo_);
    }

    /// -----------------------------------------------------------------------
    /// User actions
    /// -----------------------------------------------------------------------

    /// @notice Deploys the NegativeYieldToken and PerpetualYieldToken associated with a vault.
    /// @dev Will revert if they have already been deployed.
    /// @param gate The gate that will use the NYT and PYT
    /// @param vault The vault to deploy NYT and PYT for
    /// @return nyt The deployed NegativeYieldToken
    /// @return pyt The deployed PerpetualYieldToken
    function deployYieldTokenPair(Gate gate, address vault)
        public
        virtual
        returns (NegativeYieldToken nyt, PerpetualYieldToken pyt)
    {
        // Use the CREATE2 opcode to deploy new NegativeYieldToken and PerpetualYieldToken contracts.
        // This will revert if the contracts have already been deployed,
        // as the salt & bytecode hash would be the same and we can't deploy with it twice.
        nyt = new NegativeYieldToken{salt: bytes32(0)}(gate, vault);
        pyt = new PerpetualYieldToken{salt: bytes32(0)}(gate, vault);

        emit DeployYieldTokenPair(gate, vault, nyt, pyt);
    }

    /// -----------------------------------------------------------------------
    /// Getters
    /// -----------------------------------------------------------------------

    /// @notice Returns the NegativeYieldToken associated with a gate & vault pair.
    /// @dev Returns non-zero value even if the contract hasn't been deployed yet.
    /// @param gate The gate to query
    /// @param vault The vault to query
    /// @return The NegativeYieldToken address
    function getNegativeYieldToken(Gate gate, address vault)
        public
        view
        virtual
        returns (NegativeYieldToken)
    {
        return
            NegativeYieldToken(_computeYieldTokenAddress(gate, vault, false));
    }

    /// @notice Returns the PerpetualYieldToken associated with a gate & vault pair.
    /// @dev Returns non-zero value even if the contract hasn't been deployed yet.
    /// @param gate The gate to query
    /// @param vault The vault to query
    /// @return The PerpetualYieldToken address
    function getPerpetualYieldToken(Gate gate, address vault)
        public
        view
        virtual
        returns (PerpetualYieldToken)
    {
        return
            PerpetualYieldToken(_computeYieldTokenAddress(gate, vault, true));
    }

    /// -----------------------------------------------------------------------
    /// Owner functions
    /// -----------------------------------------------------------------------

    /// @notice Updates the protocol fee and/or the protocol fee recipient.
    /// Only callable by the owner.
    /// @param protocolFeeInfo_ The new protocol fee info
    function ownerSetProtocolFee(ProtocolFeeInfo calldata protocolFeeInfo_)
        external
        virtual
        onlyOwner
    {
        if (
            protocolFeeInfo_.fee != 0 &&
            protocolFeeInfo_.recipient == address(0)
        ) {
            revert Error_ProtocolFeeRecipientIsZero();
        }
        protocolFeeInfo = protocolFeeInfo_;

        emit SetProtocolFee(protocolFeeInfo_);
    }

    /// -----------------------------------------------------------------------
    /// Internal utilities
    /// -----------------------------------------------------------------------

    /// @dev Computes the address of PYTs and NYTs using CREATE2.
    function _computeYieldTokenAddress(
        Gate gate,
        address vault,
        bool isPerpetualYieldToken
    ) internal view virtual returns (address) {
        return
            keccak256(
                abi.encodePacked(
                    // Prefix:
                    bytes1(0xFF),
                    // Creator:
                    address(this),
                    // Salt:
                    bytes32(0),
                    // Bytecode hash:
                    keccak256(
                        abi.encodePacked(
                            // Deployment bytecode:
                            isPerpetualYieldToken
                                ? type(PerpetualYieldToken).creationCode
                                : type(NegativeYieldToken).creationCode,
                            // Constructor arguments:
                            abi.encode(gate, vault)
                        )
                    )
                )
            ).fromLast20Bytes(); // Convert the CREATE2 hash into an address.
    }
}

abstract contract IxPYT is ERC4626 {
    function sweep(address receiver) external virtual returns (uint256 shares);
}

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall {
    function multicall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
/// @dev These functions are expected to be embedded in multicalls to allow EOAs to approve a contract and call a function
/// that requires an approval in a single transaction.
abstract contract SelfPermit {
    function selfPermit(
        ERC20 token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        token.permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    function selfPermitIfNecessary(
        ERC20 token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (token.allowance(msg.sender, address(this)) < value)
            selfPermit(token, value, deadline, v, r, s);
    }
}

/// @title Gate
/// @author zefram.eth
/// @notice Gate is the main contract users interact with to mint/burn NegativeYieldToken
/// and PerpetualYieldToken, as well as claim the yield earned by PYTs.
/// @dev Gate is an abstract contract that should be inherited from in order to support
/// a specific vault protocol (e.g. YearnGate supports YearnVault). Each Gate handles
/// all vaults & associated NYTs/PYTs of a specific vault protocol.
///
/// Vaults are yield-generating contracts used by Gate. Gate makes several assumptions about
/// a vault:
/// 1) A vault has a single associated underlying token that is immutable.
/// 2) A vault gives depositors yield denominated in the underlying token.
/// 3) A vault depositor owns shares in the vault, which represents their deposit.
/// 4) Vaults have a notion of "price per share", which is the amount of underlying tokens
///    each vault share can be redeemed for.
/// 5) If vault shares are represented using an ERC20 token, then the ERC20 token contract must be
///    the vault contract itself.
abstract contract Gate is
    ReentrancyGuard,
    Multicall,
    SelfPermit,
    BoringOwnable
{
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;
    using SafeTransferLib for ERC4626;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error Error_InvalidInput();
    error Error_VaultSharesNotERC20();
    error Error_TokenPairNotDeployed();
    error Error_EmergencyExitNotActivated();
    error Error_SenderNotPerpetualYieldToken();
    error Error_EmergencyExitAlreadyActivated();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event EnterWithUnderlying(
        address sender,
        address indexed nytRecipient,
        address indexed pytRecipient,
        address indexed vault,
        IxPYT xPYT,
        uint256 underlyingAmount
    );
    event EnterWithVaultShares(
        address sender,
        address indexed nytRecipient,
        address indexed pytRecipient,
        address indexed vault,
        IxPYT xPYT,
        uint256 vaultSharesAmount
    );
    event ExitToUnderlying(
        address indexed sender,
        address indexed recipient,
        address indexed vault,
        IxPYT xPYT,
        uint256 underlyingAmount
    );
    event ExitToVaultShares(
        address indexed sender,
        address indexed recipient,
        address indexed vault,
        IxPYT xPYT,
        uint256 vaultSharesAmount
    );
    event ClaimYieldInUnderlying(
        address indexed sender,
        address indexed recipient,
        address indexed vault,
        uint256 underlyingAmount
    );
    event ClaimYieldInVaultShares(
        address indexed sender,
        address indexed recipient,
        address indexed vault,
        uint256 vaultSharesAmount
    );
    event ClaimYieldAndEnter(
        address sender,
        address indexed nytRecipient,
        address indexed pytRecipient,
        address indexed vault,
        IxPYT xPYT,
        uint256 amount
    );

    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------

    /// @param activated True if emergency exit has been activated, false if not
    /// @param pytPriceInUnderlying The amount of underlying assets each PYT can redeem for.
    /// Should be a value in the range [0, PRECISION]
    struct EmergencyExitStatus {
        bool activated;
        uint96 pytPriceInUnderlying;
    }

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    /// @notice The decimals of precision used by yieldPerTokenStored and pricePerVaultShareStored
    uint256 internal constant PRECISION_DECIMALS = 27;

    /// @notice The precision used by yieldPerTokenStored and pricePerVaultShareStored
    uint256 internal constant PRECISION = 10**PRECISION_DECIMALS;

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    Factory public immutable factory;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice The amount of underlying tokens each vault share is worth, at the time of the last update.
    /// Uses PRECISION.
    /// @dev vault => value
    mapping(address => uint256) public pricePerVaultShareStored;

    /// @notice The amount of yield each PYT has accrued, at the time of the last update.
    /// Scaled by PRECISION.
    /// @dev vault => value
    mapping(address => uint256) public yieldPerTokenStored;

    /// @notice The amount of yield each PYT has accrued, at the time when a user has last interacted
    /// with the gate/PYT. Shifted by 1, so e.g. 3 represents 2, 10 represents 9.
    /// @dev vault => user => value
    /// The value is shifted to use 0 for representing uninitialized users.
    mapping(address => mapping(address => uint256))
        public userYieldPerTokenStored;

    /// @notice The amount of yield a user has accrued, at the time when they last interacted
    /// with the gate/PYT (without calling claimYieldInUnderlying()).
    /// Shifted by 1, so e.g. 3 represents 2, 10 represents 9.
    /// @dev vault => user => value
    mapping(address => mapping(address => uint256)) public userAccruedYield;

    /// @notice Stores info relevant to emergency exits of a vault.
    /// @dev vault => value
    mapping(address => EmergencyExitStatus) public emergencyExitStatusOfVault;

    /// -----------------------------------------------------------------------
    /// Initialization
    /// -----------------------------------------------------------------------

    constructor(Factory factory_) {
        factory = factory_;
    }

    /// -----------------------------------------------------------------------
    /// User actions
    /// -----------------------------------------------------------------------

    /// @notice Converts underlying tokens into NegativeYieldToken and PerpetualYieldToken.
    /// The amount of NYT and PYT minted will be equal to the underlying token amount.
    /// @dev The underlying tokens will be immediately deposited into the specified vault.
    /// If the NYT and PYT for the specified vault haven't been deployed yet, this call will
    /// deploy them before proceeding, which will increase the gas cost significantly.
    /// @param nytRecipient The recipient of the minted NYT
    /// @param pytRecipient The recipient of the minted PYT
    /// @param vault The vault to mint NYT and PYT for
    /// @param xPYT The xPYT contract to deposit the minted PYT into. Set to 0 to receive raw PYT instead.
    /// @param underlyingAmount The amount of underlying tokens to use
    /// @return mintAmount The amount of NYT and PYT minted (the amounts are equal)
    function enterWithUnderlying(
        address nytRecipient,
        address pytRecipient,
        address vault,
        IxPYT xPYT,
        uint256 underlyingAmount
    ) external virtual nonReentrant returns (uint256 mintAmount) {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        if (underlyingAmount == 0) {
            return 0;
        }

        /// -----------------------------------------------------------------------
        /// State updates & effects
        /// -----------------------------------------------------------------------

        // mint PYT and NYT
        mintAmount = underlyingAmount;
        _enter(
            nytRecipient,
            pytRecipient,
            vault,
            xPYT,
            underlyingAmount,
            getPricePerVaultShare(vault)
        );

        // transfer underlying from msg.sender to address(this)
        ERC20 underlying = getUnderlyingOfVault(vault);
        underlying.safeTransferFrom(
            msg.sender,
            address(this),
            underlyingAmount
        );

        // deposit underlying into vault
        _depositIntoVault(underlying, underlyingAmount, vault);

        emit EnterWithUnderlying(
            msg.sender,
            nytRecipient,
            pytRecipient,
            vault,
            xPYT,
            underlyingAmount
        );
    }

    /// @notice Converts vault share tokens into NegativeYieldToken and PerpetualYieldToken.
    /// @dev Only available if vault shares are transferrable ERC20 tokens.
    /// If the NYT and PYT for the specified vault haven't been deployed yet, this call will
    /// deploy them before proceeding, which will increase the gas cost significantly.
    /// @param nytRecipient The recipient of the minted NYT
    /// @param pytRecipient The recipient of the minted PYT
    /// @param vault The vault to mint NYT and PYT for
    /// @param xPYT The xPYT contract to deposit the minted PYT into. Set to 0 to receive raw PYT instead.
    /// @param vaultSharesAmount The amount of vault share tokens to use
    /// @return mintAmount The amount of NYT and PYT minted (the amounts are equal)
    function enterWithVaultShares(
        address nytRecipient,
        address pytRecipient,
        address vault,
        IxPYT xPYT,
        uint256 vaultSharesAmount
    ) external virtual nonReentrant returns (uint256 mintAmount) {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        if (vaultSharesAmount == 0) {
            return 0;
        }

        // only supported if vault shares are ERC20
        if (!vaultSharesIsERC20()) {
            revert Error_VaultSharesNotERC20();
        }

        /// -----------------------------------------------------------------------
        /// State updates & effects
        /// -----------------------------------------------------------------------

        // mint PYT and NYT
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);
        mintAmount = _vaultSharesAmountToUnderlyingAmount(
            vault,
            vaultSharesAmount,
            updatedPricePerVaultShare
        );
        _enter(
            nytRecipient,
            pytRecipient,
            vault,
            xPYT,
            mintAmount,
            updatedPricePerVaultShare
        );

        // transfer vault tokens from msg.sender to address(this)
        ERC20(vault).safeTransferFrom(
            msg.sender,
            address(this),
            vaultSharesAmount
        );

        emit EnterWithVaultShares(
            msg.sender,
            nytRecipient,
            pytRecipient,
            vault,
            xPYT,
            vaultSharesAmount
        );
    }

    /// @notice Converts NegativeYieldToken and PerpetualYieldToken to underlying tokens.
    /// The amount of NYT and PYT burned will be equal to the underlying token amount.
    /// @dev The underlying tokens will be immediately withdrawn from the specified vault.
    /// If the NYT and PYT for the specified vault haven't been deployed yet, this call will
    /// revert.
    /// @param recipient The recipient of the minted NYT and PYT
    /// @param vault The vault to mint NYT and PYT for
    /// @param xPYT The xPYT contract to use for burning PYT. Set to 0 to burn raw PYT instead.
    /// @param underlyingAmount The amount of underlying tokens requested
    /// @return burnAmount The amount of NYT and PYT burned (the amounts are equal)
    function exitToUnderlying(
        address recipient,
        address vault,
        IxPYT xPYT,
        uint256 underlyingAmount
    ) external virtual nonReentrant returns (uint256 burnAmount) {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        if (underlyingAmount == 0) {
            return 0;
        }

        /// -----------------------------------------------------------------------
        /// State updates & effects
        /// -----------------------------------------------------------------------

        // burn PYT and NYT
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);
        burnAmount = underlyingAmount;
        _exit(vault, xPYT, underlyingAmount, updatedPricePerVaultShare);

        // withdraw underlying from vault to recipient
        // don't check balance since user can just withdraw slightly less
        // saves gas this way
        underlyingAmount = _withdrawFromVault(
            recipient,
            vault,
            underlyingAmount,
            updatedPricePerVaultShare,
            false
        );

        emit ExitToUnderlying(
            msg.sender,
            recipient,
            vault,
            xPYT,
            underlyingAmount
        );
    }

    /// @notice Converts NegativeYieldToken and PerpetualYieldToken to vault share tokens.
    /// The amount of NYT and PYT burned will be equal to the underlying token amount.
    /// @dev Only available if vault shares are transferrable ERC20 tokens.
    /// If the NYT and PYT for the specified vault haven't been deployed yet, this call will
    /// revert.
    /// @param recipient The recipient of the minted NYT and PYT
    /// @param vault The vault to mint NYT and PYT for
    /// @param xPYT The xPYT contract to use for burning PYT. Set to 0 to burn raw PYT instead.
    /// @param vaultSharesAmount The amount of vault share tokens requested
    /// @return burnAmount The amount of NYT and PYT burned (the amounts are equal)
    function exitToVaultShares(
        address recipient,
        address vault,
        IxPYT xPYT,
        uint256 vaultSharesAmount
    ) external virtual nonReentrant returns (uint256 burnAmount) {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        if (vaultSharesAmount == 0) {
            return 0;
        }

        // only supported if vault shares are ERC20
        if (!vaultSharesIsERC20()) {
            revert Error_VaultSharesNotERC20();
        }

        /// -----------------------------------------------------------------------
        /// State updates & effects
        /// -----------------------------------------------------------------------

        // burn PYT and NYT
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);
        burnAmount = _vaultSharesAmountToUnderlyingAmountRoundingUp(
            vault,
            vaultSharesAmount,
            updatedPricePerVaultShare
        );
        _exit(vault, xPYT, burnAmount, updatedPricePerVaultShare);

        // transfer vault tokens to recipient
        ERC20(vault).safeTransfer(recipient, vaultSharesAmount);

        emit ExitToVaultShares(
            msg.sender,
            recipient,
            vault,
            xPYT,
            vaultSharesAmount
        );
    }

    /// @notice Claims the yield earned by the PerpetualYieldToken balance of msg.sender, in the underlying token.
    /// @dev If the NYT and PYT for the specified vault haven't been deployed yet, this call will
    /// revert.
    /// @param recipient The recipient of the yield
    /// @param vault The vault to claim yield from
    /// @return yieldAmount The amount of yield claimed, in underlying tokens
    function claimYieldInUnderlying(address recipient, address vault)
        external
        virtual
        nonReentrant
        returns (uint256 yieldAmount)
    {
        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // update storage variables and compute yield amount
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);
        yieldAmount = _claimYield(vault, updatedPricePerVaultShare);

        // withdraw yield
        if (yieldAmount != 0) {
            /// -----------------------------------------------------------------------
            /// Effects
            /// -----------------------------------------------------------------------

            (uint8 fee, address protocolFeeRecipient) = factory
                .protocolFeeInfo();

            if (fee != 0) {
                uint256 protocolFee = (yieldAmount * fee) / 1000;
                unchecked {
                    // can't underflow since fee < 256
                    yieldAmount -= protocolFee;
                }

                if (vaultSharesIsERC20()) {
                    // vault shares are in ERC20
                    // do share transfer
                    protocolFee = _underlyingAmountToVaultSharesAmount(
                        vault,
                        protocolFee,
                        updatedPricePerVaultShare
                    );
                    uint256 vaultSharesBalance = ERC20(vault).balanceOf(
                        address(this)
                    );
                    if (protocolFee > vaultSharesBalance) {
                        protocolFee = vaultSharesBalance;
                    }
                    if (protocolFee != 0) {
                        ERC20(vault).safeTransfer(
                            protocolFeeRecipient,
                            protocolFee
                        );
                    }
                } else {
                    // vault shares are not in ERC20
                    // withdraw underlying from vault
                    // checkBalance is set to true to prevent getting stuck
                    // due to rounding errors
                    if (protocolFee != 0) {
                        _withdrawFromVault(
                            protocolFeeRecipient,
                            vault,
                            protocolFee,
                            updatedPricePerVaultShare,
                            true
                        );
                    }
                }
            }

            // withdraw underlying to recipient
            // checkBalance is set to true to prevent getting stuck
            // due to rounding errors
            yieldAmount = _withdrawFromVault(
                recipient,
                vault,
                yieldAmount,
                updatedPricePerVaultShare,
                true
            );

            emit ClaimYieldInUnderlying(
                msg.sender,
                recipient,
                vault,
                yieldAmount
            );
        }
    }

    /// @notice Claims the yield earned by the PerpetualYieldToken balance of msg.sender, in vault shares.
    /// @dev Only available if vault shares are transferrable ERC20 tokens.
    /// If the NYT and PYT for the specified vault haven't been deployed yet, this call will
    /// revert.
    /// @param recipient The recipient of the yield
    /// @param vault The vault to claim yield from
    /// @return yieldAmount The amount of yield claimed, in vault shares
    function claimYieldInVaultShares(address recipient, address vault)
        external
        virtual
        nonReentrant
        returns (uint256 yieldAmount)
    {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        // only supported if vault shares are ERC20
        if (!vaultSharesIsERC20()) {
            revert Error_VaultSharesNotERC20();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // update storage variables and compute yield amount
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);
        yieldAmount = _claimYield(vault, updatedPricePerVaultShare);

        // withdraw yield
        if (yieldAmount != 0) {
            /// -----------------------------------------------------------------------
            /// Effects
            /// -----------------------------------------------------------------------

            // convert yieldAmount to be denominated in vault shares
            yieldAmount = _underlyingAmountToVaultSharesAmount(
                vault,
                yieldAmount,
                updatedPricePerVaultShare
            );

            (uint8 fee, address protocolFeeRecipient) = factory
                .protocolFeeInfo();
            uint256 vaultSharesBalance = getVaultShareBalance(vault);
            if (fee != 0) {
                uint256 protocolFee = (yieldAmount * fee) / 1000;
                protocolFee = protocolFee > vaultSharesBalance
                    ? vaultSharesBalance
                    : protocolFee;
                unchecked {
                    // can't underflow since fee < 256
                    yieldAmount -= protocolFee;
                }

                if (protocolFee > 0) {
                    ERC20(vault).safeTransfer(
                        protocolFeeRecipient,
                        protocolFee
                    );

                    vaultSharesBalance -= protocolFee;
                }
            }

            // transfer vault shares to recipient
            // check if vault shares is enough to prevent getting stuck
            // from rounding errors
            yieldAmount = yieldAmount > vaultSharesBalance
                ? vaultSharesBalance
                : yieldAmount;
            if (yieldAmount > 0) {
                ERC20(vault).safeTransfer(recipient, yieldAmount);
            }

            emit ClaimYieldInVaultShares(
                msg.sender,
                recipient,
                vault,
                yieldAmount
            );
        }
    }

    /// @notice Claims the yield earned by the PerpetualYieldToken balance of msg.sender, and immediately
    /// use the yield to mint NYT and PYT.
    /// @dev Introduced to save gas for xPYT compounding, since it avoids vault withdraws/transfers.
    /// If the NYT and PYT for the specified vault haven't been deployed yet, this call will
    /// revert.
    /// @param nytRecipient The recipient of the minted NYT
    /// @param pytRecipient The recipient of the minted PYT
    /// @param vault The vault to claim yield from
    /// @param xPYT The xPYT contract to deposit the minted PYT into. Set to 0 to receive raw PYT instead.
    /// @return yieldAmount The amount of yield claimed, in underlying tokens
    function claimYieldAndEnter(
        address nytRecipient,
        address pytRecipient,
        address vault,
        IxPYT xPYT
    ) external virtual nonReentrant returns (uint256 yieldAmount) {
        // update storage variables and compute yield amount
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);
        yieldAmount = _claimYield(vault, updatedPricePerVaultShare);

        // use yield to mint NYT and PYT
        if (yieldAmount != 0) {
            (uint8 fee, address protocolFeeRecipient) = factory
                .protocolFeeInfo();

            if (fee != 0) {
                uint256 protocolFee = (yieldAmount * fee) / 1000;
                unchecked {
                    // can't underflow since fee < 256
                    yieldAmount -= protocolFee;
                }

                if (vaultSharesIsERC20()) {
                    // vault shares are in ERC20
                    // do share transfer
                    protocolFee = _underlyingAmountToVaultSharesAmount(
                        vault,
                        protocolFee,
                        updatedPricePerVaultShare
                    );
                    uint256 vaultSharesBalance = ERC20(vault).balanceOf(
                        address(this)
                    );
                    if (protocolFee > vaultSharesBalance) {
                        protocolFee = vaultSharesBalance;
                    }
                    if (protocolFee != 0) {
                        ERC20(vault).safeTransfer(
                            protocolFeeRecipient,
                            protocolFee
                        );
                    }
                } else {
                    // vault shares are not in ERC20
                    // withdraw underlying from vault
                    // checkBalance is set to true to prevent getting stuck
                    // due to rounding errors
                    if (protocolFee != 0) {
                        _withdrawFromVault(
                            protocolFeeRecipient,
                            vault,
                            protocolFee,
                            updatedPricePerVaultShare,
                            true
                        );
                    }
                }
            }

            NegativeYieldToken nyt = getNegativeYieldTokenForVault(vault);
            PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);

            if (address(xPYT) == address(0)) {
                // accrue yield to pytRecipient if they're not msg.sender
                // no need to do it if the recipient is msg.sender, since
                // we already accrued yield in _claimYield
                if (pytRecipient != msg.sender) {
                    _accrueYield(
                        vault,
                        pyt,
                        pytRecipient,
                        updatedPricePerVaultShare
                    );
                }
            } else {
                // accrue yield to xPYT contract since it gets minted PYT
                _accrueYield(
                    vault,
                    pyt,
                    address(xPYT),
                    updatedPricePerVaultShare
                );
            }

            // mint NYTs and PYTs
            nyt.gateMint(nytRecipient, yieldAmount);
            if (address(xPYT) == address(0)) {
                // mint raw PYT to recipient
                pyt.gateMint(pytRecipient, yieldAmount);
            } else {
                // mint PYT to xPYT contract
                pyt.gateMint(address(xPYT), yieldAmount);

                /// -----------------------------------------------------------------------
                /// Effects
                /// -----------------------------------------------------------------------

                // call sweep to mint xPYT using the PYT
                xPYT.sweep(pytRecipient);
            }

            emit ClaimYieldAndEnter(
                msg.sender,
                nytRecipient,
                pytRecipient,
                vault,
                xPYT,
                yieldAmount
            );
        }
    }

    /// -----------------------------------------------------------------------
    /// Getters
    /// -----------------------------------------------------------------------

    /// @notice Returns the NegativeYieldToken associated with a vault.
    /// @dev Returns non-zero value even if the contract hasn't been deployed yet.
    /// @param vault The vault to query
    /// @return The NegativeYieldToken address
    function getNegativeYieldTokenForVault(address vault)
        public
        view
        virtual
        returns (NegativeYieldToken)
    {
        return factory.getNegativeYieldToken(this, vault);
    }

    /// @notice Returns the PerpetualYieldToken associated with a vault.
    /// @dev Returns non-zero value even if the contract hasn't been deployed yet.
    /// @param vault The vault to query
    /// @return The PerpetualYieldToken address
    function getPerpetualYieldTokenForVault(address vault)
        public
        view
        virtual
        returns (PerpetualYieldToken)
    {
        return factory.getPerpetualYieldToken(this, vault);
    }

    /// @notice Returns the amount of yield claimable by a PerpetualYieldToken holder from a vault.
    /// Accounts for protocol fees.
    /// @param vault The vault to query
    /// @param user The PYT holder to query
    /// @return yieldAmount The amount of yield claimable
    function getClaimableYieldAmount(address vault, address user)
        external
        view
        virtual
        returns (uint256 yieldAmount)
    {
        PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);
        uint256 userYieldPerTokenStored_ = userYieldPerTokenStored[vault][user];
        if (userYieldPerTokenStored_ == 0) {
            // uninitialized account
            return 0;
        }
        yieldAmount = _getClaimableYieldAmount(
            vault,
            user,
            _computeYieldPerToken(vault, pyt, getPricePerVaultShare(vault)),
            userYieldPerTokenStored_,
            pyt.balanceOf(user)
        );
        (uint8 fee, ) = factory.protocolFeeInfo();
        if (fee != 0) {
            uint256 protocolFee = (yieldAmount * fee) / 1000;
            unchecked {
                // can't underflow since fee < 256
                yieldAmount -= protocolFee;
            }
        }
    }

    /// @notice Computes the latest yieldPerToken value for a vault.
    /// @param vault The vault to query
    /// @return The latest yieldPerToken value
    function computeYieldPerToken(address vault)
        external
        view
        virtual
        returns (uint256)
    {
        return
            _computeYieldPerToken(
                vault,
                getPerpetualYieldTokenForVault(vault),
                getPricePerVaultShare(vault)
            );
    }

    /// @notice Returns the underlying token of a vault.
    /// @param vault The vault to query
    /// @return The underlying token
    function getUnderlyingOfVault(address vault)
        public
        view
        virtual
        returns (ERC20);

    /// @notice Returns the amount of underlying tokens each share of a vault is worth.
    /// @param vault The vault to query
    /// @return The pricePerVaultShare value
    function getPricePerVaultShare(address vault)
        public
        view
        virtual
        returns (uint256);

    /// @notice Returns the amount of vault shares owned by the gate.
    /// @param vault The vault to query
    /// @return The gate's vault share balance
    function getVaultShareBalance(address vault)
        public
        view
        virtual
        returns (uint256);

    /// @return True if the vaults supported by this gate use transferrable ERC20 tokens
    /// to represent shares, false otherwise.
    function vaultSharesIsERC20() public pure virtual returns (bool);

    /// @notice Computes the ERC20 name of the NegativeYieldToken of a vault.
    /// @param vault The vault to query
    /// @return The ERC20 name
    function negativeYieldTokenName(address vault)
        external
        view
        virtual
        returns (string memory);

    /// @notice Computes the ERC20 symbol of the NegativeYieldToken of a vault.
    /// @param vault The vault to query
    /// @return The ERC20 symbol
    function negativeYieldTokenSymbol(address vault)
        external
        view
        virtual
        returns (string memory);

    /// @notice Computes the ERC20 name of the PerpetualYieldToken of a vault.
    /// @param vault The vault to query
    /// @return The ERC20 name
    function perpetualYieldTokenName(address vault)
        external
        view
        virtual
        returns (string memory);

    /// @notice Computes the ERC20 symbol of the NegativeYieldToken of a vault.
    /// @param vault The vault to query
    /// @return The ERC20 symbol
    function perpetualYieldTokenSymbol(address vault)
        external
        view
        virtual
        returns (string memory);

    /// -----------------------------------------------------------------------
    /// PYT transfer hook
    /// -----------------------------------------------------------------------

    /// @notice SHOULD NOT BE CALLED BY USERS, ONLY CALLED BY PERPETUAL YIELD TOKEN CONTRACTS
    /// @dev Called by PYT contracts deployed by this gate before each token transfer, in order to
    /// accrue the yield earned by the from & to accounts
    /// @param from The token transfer from account
    /// @param to The token transfer to account
    /// @param fromBalance The token balance of the from account before the transfer
    /// @param toBalance The token balance of the to account before the transfer
    function beforePerpetualYieldTokenTransfer(
        address from,
        address to,
        uint256 amount,
        uint256 fromBalance,
        uint256 toBalance
    ) external virtual {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        if (amount == 0) {
            return;
        }

        address vault = PerpetualYieldToken(msg.sender).vault();
        PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);
        if (msg.sender != address(pyt)) {
            revert Error_SenderNotPerpetualYieldToken();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // accrue yield
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);
        uint256 updatedYieldPerToken = _computeYieldPerToken(
            vault,
            pyt,
            updatedPricePerVaultShare
        );
        yieldPerTokenStored[vault] = updatedYieldPerToken;
        pricePerVaultShareStored[vault] = updatedPricePerVaultShare;

        // we know the from account must have held PYTs before
        // so we will always accrue the yield earned by the from account
        userAccruedYield[vault][from] =
            _getClaimableYieldAmount(
                vault,
                from,
                updatedYieldPerToken,
                userYieldPerTokenStored[vault][from],
                fromBalance
            ) +
            1;
        userYieldPerTokenStored[vault][from] = updatedYieldPerToken + 1;

        // the to account might not have held PYTs before
        // we only accrue yield if they have
        uint256 toUserYieldPerTokenStored = userYieldPerTokenStored[vault][to];
        if (toUserYieldPerTokenStored != 0) {
            // to account has held PYTs before
            userAccruedYield[vault][to] =
                _getClaimableYieldAmount(
                    vault,
                    to,
                    updatedYieldPerToken,
                    toUserYieldPerTokenStored,
                    toBalance
                ) +
                1;
        }
        userYieldPerTokenStored[vault][to] = updatedYieldPerToken + 1;
    }

    /// -----------------------------------------------------------------------
    /// Emergency exit
    /// -----------------------------------------------------------------------

    /// @notice Activates the emergency exit mode for a certain vault. Only callable by owner.
    /// @dev Activating emergency exit allows PYT/NYT holders to do single-sided burns to redeem the underlying
    /// collateral. This is to prevent cases where a large portion of PYT/NYT is locked up in a buggy/malicious contract
    /// and locks up the underlying collateral forever.
    /// @param vault The vault to activate emergency exit for
    /// @param pytPriceInUnderlying The amount of underlying asset burning each PYT can redeem. Scaled by PRECISION.
    function ownerActivateEmergencyExitForVault(
        address vault,
        uint96 pytPriceInUnderlying
    ) external virtual onlyOwner {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        // we only allow emergency exit to be activated once (until deactivation)
        // because if pytPriceInUnderlying is ever modified after activation
        // then PYT/NYT will become unbacked
        if (emergencyExitStatusOfVault[vault].activated) {
            revert Error_EmergencyExitAlreadyActivated();
        }

        // we need to ensure the PYT price value is within the range [0, PRECISION]
        if (pytPriceInUnderlying > PRECISION) {
            revert Error_InvalidInput();
        }

        // the PYT & NYT must have already been deployed
        NegativeYieldToken nyt = getNegativeYieldTokenForVault(vault);
        if (address(nyt).code.length == 0) {
            revert Error_TokenPairNotDeployed();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        emergencyExitStatusOfVault[vault] = EmergencyExitStatus({
            activated: true,
            pytPriceInUnderlying: pytPriceInUnderlying
        });
    }

    /// @notice Deactivates the emergency exit mode for a certain vault. Only callable by owner.
    /// @param vault The vault to deactivate emergency exit for
    function ownerDeactivateEmergencyExitForVault(address vault)
        external
        virtual
        onlyOwner
    {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        // can only deactivate emergency exit when it's already activated
        if (!emergencyExitStatusOfVault[vault].activated) {
            revert Error_EmergencyExitNotActivated();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // reset the emergency exit status
        delete emergencyExitStatusOfVault[vault];
    }

    /// @notice Emergency exit NYTs into the underlying asset. Only callable when emergency exit has
    /// been activated for the vault.
    /// @param vault The vault to exit NYT for
    /// @param amount The amount of NYT to exit
    /// @param recipient The recipient of the underlying asset
    /// @return underlyingAmount The amount of underlying asset exited
    function emergencyExitNegativeYieldToken(
        address vault,
        uint256 amount,
        address recipient
    ) external virtual returns (uint256 underlyingAmount) {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        // ensure emergency exit is active
        EmergencyExitStatus memory status = emergencyExitStatusOfVault[vault];
        if (!status.activated) {
            revert Error_EmergencyExitNotActivated();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);

        // accrue yield
        _accrueYield(vault, pyt, msg.sender, updatedPricePerVaultShare);

        // burn NYT from the sender
        NegativeYieldToken nyt = getNegativeYieldTokenForVault(vault);
        nyt.gateBurn(msg.sender, amount);

        /// -----------------------------------------------------------------------
        /// Effects
        /// -----------------------------------------------------------------------

        // compute how much of the underlying assets to give the recipient
        // rounds down
        underlyingAmount = FullMath.mulDiv(
            amount,
            PRECISION - status.pytPriceInUnderlying,
            PRECISION
        );

        // withdraw underlying from vault to recipient
        // don't check balance since user can just withdraw slightly less
        // saves gas this way
        underlyingAmount = _withdrawFromVault(
            recipient,
            vault,
            underlyingAmount,
            updatedPricePerVaultShare,
            false
        );
    }

    /// @notice Emergency exit PYTs into the underlying asset. Only callable when emergency exit has
    /// been activated for the vault.
    /// @param vault The vault to exit PYT for
    /// @param xPYT The xPYT contract to use for burning PYT. Set to 0 to burn raw PYT instead.
    /// @param amount The amount of PYT to exit
    /// @param recipient The recipient of the underlying asset
    /// @return underlyingAmount The amount of underlying asset exited
    function emergencyExitPerpetualYieldToken(
        address vault,
        IxPYT xPYT,
        uint256 amount,
        address recipient
    ) external virtual returns (uint256 underlyingAmount) {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        // ensure emergency exit is active
        EmergencyExitStatus memory status = emergencyExitStatusOfVault[vault];
        if (!status.activated) {
            revert Error_EmergencyExitNotActivated();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);

        // accrue yield
        _accrueYield(vault, pyt, msg.sender, updatedPricePerVaultShare);

        if (address(xPYT) == address(0)) {
            // burn raw PYT from sender
            pyt.gateBurn(msg.sender, amount);
        } else {
            /// -----------------------------------------------------------------------
            /// Effects
            /// -----------------------------------------------------------------------

            // convert xPYT to PYT then burn
            xPYT.withdraw(amount, address(this), msg.sender);
            pyt.gateBurn(address(this), amount);
        }

        /// -----------------------------------------------------------------------
        /// Effects
        /// -----------------------------------------------------------------------

        // compute how much of the underlying assets to give the recipient
        // rounds down
        underlyingAmount = FullMath.mulDiv(
            amount,
            status.pytPriceInUnderlying,
            PRECISION
        );

        // withdraw underlying from vault to recipient
        // don't check balance since user can just withdraw slightly less
        // saves gas this way
        underlyingAmount = _withdrawFromVault(
            recipient,
            vault,
            underlyingAmount,
            updatedPricePerVaultShare,
            false
        );
    }

    /// -----------------------------------------------------------------------
    /// Internal utilities
    /// -----------------------------------------------------------------------

    /// @dev Updates the yield earned globally and for a particular user.
    function _accrueYield(
        address vault,
        PerpetualYieldToken pyt,
        address user,
        uint256 updatedPricePerVaultShare
    ) internal virtual {
        uint256 updatedYieldPerToken = _computeYieldPerToken(
            vault,
            pyt,
            updatedPricePerVaultShare
        );
        uint256 userYieldPerTokenStored_ = userYieldPerTokenStored[vault][user];
        if (userYieldPerTokenStored_ != 0) {
            userAccruedYield[vault][user] =
                _getClaimableYieldAmount(
                    vault,
                    user,
                    updatedYieldPerToken,
                    userYieldPerTokenStored_,
                    pyt.balanceOf(user)
                ) +
                1;
        }
        yieldPerTokenStored[vault] = updatedYieldPerToken;
        pricePerVaultShareStored[vault] = updatedPricePerVaultShare;
        userYieldPerTokenStored[vault][user] = updatedYieldPerToken + 1;
    }

    /// @dev Mints PYTs and NYTs to the recipient given the amount of underlying deposited.
    function _enter(
        address nytRecipient,
        address pytRecipient,
        address vault,
        IxPYT xPYT,
        uint256 underlyingAmount,
        uint256 updatedPricePerVaultShare
    ) internal virtual {
        NegativeYieldToken nyt = getNegativeYieldTokenForVault(vault);
        if (address(nyt).code.length == 0) {
            // token pair hasn't been deployed yet
            // do the deployment now
            // only need to check nyt since nyt and pyt are always deployed in pairs
            factory.deployYieldTokenPair(this, vault);
        }
        PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // accrue yield
        _accrueYield(
            vault,
            pyt,
            address(xPYT) == address(0) ? pytRecipient : address(xPYT),
            updatedPricePerVaultShare
        );

        // mint NYTs and PYTs
        nyt.gateMint(nytRecipient, underlyingAmount);
        if (address(xPYT) == address(0)) {
            // mint raw PYT to recipient
            pyt.gateMint(pytRecipient, underlyingAmount);
        } else {
            // mint PYT to xPYT contract
            pyt.gateMint(address(xPYT), underlyingAmount);

            /// -----------------------------------------------------------------------
            /// Effects
            /// -----------------------------------------------------------------------

            // call sweep to mint xPYT using the PYT
            xPYT.sweep(pytRecipient);
        }
    }

    /// @dev Burns PYTs and NYTs from msg.sender given the amount of underlying withdrawn.
    function _exit(
        address vault,
        IxPYT xPYT,
        uint256 underlyingAmount,
        uint256 updatedPricePerVaultShare
    ) internal virtual {
        NegativeYieldToken nyt = getNegativeYieldTokenForVault(vault);
        PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);
        if (address(nyt).code.length == 0) {
            revert Error_TokenPairNotDeployed();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // accrue yield
        _accrueYield(
            vault,
            pyt,
            address(xPYT) == address(0) ? msg.sender : address(this),
            updatedPricePerVaultShare
        );

        // burn NYTs and PYTs
        nyt.gateBurn(msg.sender, underlyingAmount);
        if (address(xPYT) == address(0)) {
            // burn raw PYT from sender
            pyt.gateBurn(msg.sender, underlyingAmount);
        } else {
            /// -----------------------------------------------------------------------
            /// Effects
            /// -----------------------------------------------------------------------

            // convert xPYT to PYT then burn
            xPYT.withdraw(underlyingAmount, address(this), msg.sender);
            pyt.gateBurn(address(this), underlyingAmount);
        }
    }

    /// @dev Updates storage variables for when a PYT holder claims the accrued yield.
    function _claimYield(address vault, uint256 updatedPricePerVaultShare)
        internal
        virtual
        returns (uint256 yieldAmount)
    {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);
        if (address(pyt).code.length == 0) {
            revert Error_TokenPairNotDeployed();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // accrue yield
        uint256 updatedYieldPerToken = _computeYieldPerToken(
            vault,
            pyt,
            updatedPricePerVaultShare
        );
        uint256 userYieldPerTokenStored_ = userYieldPerTokenStored[vault][
            msg.sender
        ];
        if (userYieldPerTokenStored_ != 0) {
            yieldAmount = _getClaimableYieldAmount(
                vault,
                msg.sender,
                updatedYieldPerToken,
                userYieldPerTokenStored_,
                pyt.balanceOf(msg.sender)
            );
        }
        yieldPerTokenStored[vault] = updatedYieldPerToken;
        pricePerVaultShareStored[vault] = updatedPricePerVaultShare;
        userYieldPerTokenStored[vault][msg.sender] = updatedYieldPerToken + 1;
        if (yieldAmount != 0) {
            userAccruedYield[vault][msg.sender] = 1;
        }
    }

    /// @dev Returns the amount of yield claimable by a PerpetualYieldToken holder from a vault.
    /// Assumes userYieldPerTokenStored_ != 0. Does not account for protocol fees.
    function _getClaimableYieldAmount(
        address vault,
        address user,
        uint256 updatedYieldPerToken,
        uint256 userYieldPerTokenStored_,
        uint256 userPYTBalance
    ) internal view virtual returns (uint256 yieldAmount) {
        unchecked {
            // the stored value is shifted by one
            uint256 actualUserYieldPerToken = userYieldPerTokenStored_ - 1;

            // updatedYieldPerToken - actualUserYieldPerToken won't underflow since we check updatedYieldPerToken > actualUserYieldPerToken
            yieldAmount = FullMath.mulDiv(
                userPYTBalance,
                updatedYieldPerToken > actualUserYieldPerToken
                    ? updatedYieldPerToken - actualUserYieldPerToken
                    : 0,
                PRECISION
            );

            uint256 accruedYield = userAccruedYield[vault][user];
            if (accruedYield > 1) {
                // won't overflow since the sum is at most the totalSupply of the vault's underlying, which
                // is at most 256 bits.
                // the stored accruedYield value is shifted by one
                yieldAmount += accruedYield - 1;
            }
        }
    }

    /// @dev Deposits underlying tokens into a vault
    /// @param underlying The underlying token to deposit
    /// @param underlyingAmount The amount of tokens to deposit
    /// @param vault The vault to deposit into
    function _depositIntoVault(
        ERC20 underlying,
        uint256 underlyingAmount,
        address vault
    ) internal virtual;

    /// @dev Withdraws underlying tokens from a vault
    /// @param recipient The recipient of the underlying tokens
    /// @param vault The vault to withdraw from
    /// @param underlyingAmount The amount of tokens to withdraw
    /// @param pricePerVaultShare The latest price per vault share value
    /// @param checkBalance Set to true to withdraw the entire balance if we're trying
    /// to withdraw more than the balance (due to rounding errors)
    /// @return withdrawnUnderlyingAmount The amount of underlying tokens withdrawn
    function _withdrawFromVault(
        address recipient,
        address vault,
        uint256 underlyingAmount,
        uint256 pricePerVaultShare,
        bool checkBalance
    ) internal virtual returns (uint256 withdrawnUnderlyingAmount);

    /// @dev Converts a vault share amount into an equivalent underlying asset amount
    function _vaultSharesAmountToUnderlyingAmount(
        address vault,
        uint256 vaultSharesAmount,
        uint256 pricePerVaultShare
    ) internal view virtual returns (uint256);

    /// @dev Converts a vault share amount into an equivalent underlying asset amount, rounding up
    function _vaultSharesAmountToUnderlyingAmountRoundingUp(
        address vault,
        uint256 vaultSharesAmount,
        uint256 pricePerVaultShare
    ) internal view virtual returns (uint256);

    /// @dev Converts an underlying asset amount into an equivalent vault shares amount
    function _underlyingAmountToVaultSharesAmount(
        address vault,
        uint256 underlyingAmount,
        uint256 pricePerVaultShare
    ) internal view virtual returns (uint256);

    /// @dev Computes the latest yieldPerToken value for a vault.
    function _computeYieldPerToken(
        address vault,
        PerpetualYieldToken pyt,
        uint256 updatedPricePerVaultShare
    ) internal view virtual returns (uint256) {
        uint256 pytTotalSupply = pyt.totalSupply();
        if (pytTotalSupply == 0) {
            return yieldPerTokenStored[vault];
        }
        uint256 pricePerVaultShareStored_ = pricePerVaultShareStored[vault];
        if (updatedPricePerVaultShare <= pricePerVaultShareStored_) {
            // rounding error in vault share or no yield accrued
            return yieldPerTokenStored[vault];
        }
        uint256 newYieldPerTokenAccrued;
        unchecked {
            // can't underflow since we know updatedPricePerVaultShare > pricePerVaultShareStored_
            newYieldPerTokenAccrued = FullMath.mulDiv(
                updatedPricePerVaultShare - pricePerVaultShareStored_,
                getVaultShareBalance(vault),
                pytTotalSupply
            );
        }
        return yieldPerTokenStored[vault] + newYieldPerTokenAccrued;
    }
}

/// @title XPYT
/// @author zefram.eth
/// @notice Permissionless auto-compounding vault for Timeless perpetual yield tokens
abstract contract XPYT is ERC4626, ReentrancyGuard, Multicall, SelfPermit {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error Error_InsufficientOutput();
    error Error_InvalidMultiplierValue();
    error Error_ConsultTwapOracleFailed();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Pound(
        address indexed sender,
        address indexed pounderRewardRecipient,
        uint256 yieldAmount,
        uint256 pytCompounded,
        uint256 pounderReward
    );

    /// -----------------------------------------------------------------------
    /// Enums
    /// -----------------------------------------------------------------------

    enum PreviewPoundErrorCode {
        OK,
        TWAP_FAIL,
        INSUFFICIENT_OUTPUT
    }

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    /// @notice The base unit for fixed point decimals.
    uint256 internal constant ONE = 10**18;

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The Gate associated with the PYT.
    Gate public immutable gate;

    /// @notice The vault associated with the PYT.
    address public immutable vault;

    /// @notice The NYT associated with the PYT.
    NegativeYieldToken public immutable nyt;

    /// @notice The minimum acceptable ratio between the NYT output in pound() and the expected NYT output
    /// based on the TWAP. Scaled by ONE.
    uint256 public immutable minOutputMultiplier;

    /// @notice The proportion of the yield claimed in pound() to give to the caller as reward. Scaled by ONE.
    uint256 public immutable pounderRewardMultiplier;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice The recorded balance of the deposited asset.
    /// @dev This is used instead of asset.balanceOf(address(this)) to prevent attackers from
    /// atomically increasing the vault share value and thus exploiting integrated lending protocols.
    uint256 public assetBalance;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        ERC20 asset_,
        string memory name_,
        string memory symbol_,
        uint256 pounderRewardMultiplier_,
        uint256 minOutputMultiplier_
    ) ERC4626(asset_, name_, symbol_) {
        if (minOutputMultiplier_ > ONE) {
            revert Error_InvalidMultiplierValue();
        }
        minOutputMultiplier = minOutputMultiplier_;
        pounderRewardMultiplier = pounderRewardMultiplier_;
        if (pounderRewardMultiplier_ > ONE) {
            revert Error_InvalidMultiplierValue();
        }
        Gate gate_ = PerpetualYieldToken(address(asset_)).gate();
        gate = gate_;
        address vault_ = PerpetualYieldToken(address(asset_)).vault();
        vault = vault_;
        nyt = gate_.getNegativeYieldTokenForVault(vault_);
    }

    /// -----------------------------------------------------------------------
    /// Compounding
    /// -----------------------------------------------------------------------

    /// @notice Claims the yield earned by the PYT held and sells the claimed NYT into more PYT.
    /// @dev Part of the claimed yield is given to the caller as reward, which incentivizes MEV bots
    /// to perform the auto-compounding for us.
    /// @param pounderRewardRecipient The address that will receive the caller reward
    /// @return yieldAmount The amount of PYT & NYT claimed as yield
    /// @return pytCompounded The amount of PYT distributed to XPYT holders
    /// @return pounderReward The amount of caller reward given, in PYT
    function pound(address pounderRewardRecipient)
        external
        virtual
        nonReentrant
        returns (
            uint256 yieldAmount,
            uint256 pytCompounded,
            uint256 pounderReward
        )
    {
        // claim yield from gate
        yieldAmount = gate.claimYieldAndEnter(
            address(this),
            address(this),
            vault,
            IxPYT(address(0))
        );

        // compute minXpytAmountOut based on the TWAP & minOutputMultiplier
        (bool success, uint256 twapQuoteAmountOut) = _getTwapQuote(yieldAmount);
        if (!success) {
            revert Error_ConsultTwapOracleFailed();
        }
        uint256 minXpytAmountOut = FullMath.mulDiv(
            twapQuoteAmountOut,
            minOutputMultiplier,
            ONE
        );

        // swap NYT into xPYT
        uint256 xPytAmountOut = _swap(yieldAmount);
        if (xPytAmountOut < minXpytAmountOut) {
            revert Error_InsufficientOutput();
        }

        // burn the xPYT
        uint256 pytAmountRedeemed = convertToAssets(xPytAmountOut);
        _burn(address(this), xPytAmountOut);

        // record PYT balance increase
        unchecked {
            // token balance cannot exceed 256 bits since totalSupply is an uint256
            pytCompounded = yieldAmount + pytAmountRedeemed;
            pounderReward = FullMath.mulDiv(
                pytCompounded,
                pounderRewardMultiplier,
                ONE
            );
            pytCompounded -= pounderReward;
            // don't add pytAmountRedeemed to assetBalance since it's already in the vault,
            // we just burnt the corresponding xPYT
            assetBalance = assetBalance + yieldAmount - pounderReward;
        }

        // transfer pounder reward
        asset.safeTransfer(pounderRewardRecipient, pounderReward);

        emit Pound(
            msg.sender,
            pounderRewardRecipient,
            yieldAmount,
            pytCompounded,
            pounderReward
        );
    }

    /// @notice Previews the result of calling pound()
    /// @return errorCode The end state of pound()
    /// @return yieldAmount The amount of PYT & NYT claimed as yield
    /// @return pytCompounded The amount of PYT distributed to xPYT holders
    /// @return pounderReward The amount of caller reward given, in PYT
    function previewPound()
        external
        returns (
            PreviewPoundErrorCode errorCode,
            uint256 yieldAmount,
            uint256 pytCompounded,
            uint256 pounderReward
        )
    {
        // get claimable yield amount from gate
        yieldAmount = gate.getClaimableYieldAmount(vault, address(this));

        // compute minXpytAmountOut based on the TWAP & minOutputMultiplier
        (bool twapSuccess, uint256 twapQuoteAmountOut) = _getTwapQuote(
            yieldAmount
        );
        if (!twapSuccess) {
            return (PreviewPoundErrorCode.TWAP_FAIL, 0, 0, 0);
        }
        uint256 minXpytAmountOut = FullMath.mulDiv(
            twapQuoteAmountOut,
            minOutputMultiplier,
            ONE
        );

        // simulate swapping NYT into PYT
        uint256 xPytAmountOut = _quote(yieldAmount);
        if (xPytAmountOut < minXpytAmountOut) {
            return (PreviewPoundErrorCode.INSUFFICIENT_OUTPUT, 0, 0, 0);
        }

        // burn the xPYT
        uint256 pytAmountRedeemed = convertToAssets(xPytAmountOut);

        // compute compounded PYT amount and pounder reward amount
        unchecked {
            // token balance cannot exceed 256 bits since totalSupply is an uint256
            pytCompounded = yieldAmount + pytAmountRedeemed;
            pounderReward = FullMath.mulDiv(
                pytCompounded,
                pounderRewardMultiplier,
                ONE
            );
            // don't add pytAmountRedeemed to assetBalance since it's already in the vault,
            // we just burnt the corresponding xPYT
            pytCompounded -= pounderReward;
        }

        // if execution has reached this point, the simulation was successful
        errorCode = PreviewPoundErrorCode.OK;
    }

    /// -----------------------------------------------------------------------
    /// Sweeping
    /// -----------------------------------------------------------------------

    /// @notice Uses the extra asset balance of the xPYT contract to mint shares
    /// @param receiver The recipient of the minted shares
    /// @return shares The amount of shares minted
    function sweep(address receiver) external virtual returns (uint256 shares) {
        uint256 assets = asset.balanceOf(address(this)) - assetBalance;

        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    /// -----------------------------------------------------------------------
    /// ERC4626 overrides
    /// -----------------------------------------------------------------------

    function totalAssets() public view virtual override returns (uint256) {
        return assetBalance;
    }

    function beforeWithdraw(
        uint256 assets,
        uint256 /*shares*/
    ) internal virtual override {
        unchecked {
            assetBalance -= assets;
        }
    }

    function afterDeposit(
        uint256 assets,
        uint256 /*shares*/
    ) internal virtual override {
        assetBalance += assets;
    }

    /// -----------------------------------------------------------------------
    /// Internal utilities
    /// -----------------------------------------------------------------------

    /// @dev Consults the TWAP oracle to get a quote for how much xPYT will be received from swapping
    /// `nytAmountIn` NYT.
    /// @param nytAmountIn The amount of NYT to swap
    /// @return success True if the call to the TWAP oracle was successful, false otherwise
    /// @return xPytAmountOut The amount of xPYT that will be received from the swap
    function _getTwapQuote(uint256 nytAmountIn)
        internal
        view
        virtual
        returns (bool success, uint256 xPytAmountOut);

    /// @dev Swaps `nytAmountIn` NYT into xPYT using the underlying DEX
    /// @param nytAmountIn The amount of NYT to swap
    /// @return xPytAmountOut The amount of xPYT received from the swap
    function _swap(uint256 nytAmountIn)
        internal
        virtual
        returns (uint256 xPytAmountOut);

    /// @dev Gets a quote from the underlying DEX for swapping `nytAmountIn` NYT into xPYT
    /// @param nytAmountIn The amount of NYT to swap
    /// @return xPytAmountOut The amount of xPYT that will be received from the swap
    function _quote(uint256 nytAmountIn)
        internal
        virtual
        returns (uint256 xPytAmountOut);
}

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    using Bytes32AddressLib for bytes32;

    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key)
        internal
        pure
        returns (address pool)
    {
        require(key.token0 < key.token1);
        pool = keccak256(
            abi.encodePacked(
                hex"ff",
                factory,
                keccak256(abi.encode(key.token0, key.token1, key.fee)),
                POOL_INIT_CODE_HASH
            )
        ).fromLast20Bytes();
    }
}

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        require(secondsAgo != 0, "BP");

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        ) = IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        uint160 secondsPerLiquidityCumulativesDelta = secondsPerLiquidityCumulativeX128s[
                1
            ] - secondsPerLiquidityCumulativeX128s[0];

        arithmeticMeanTick = int24(
            tickCumulativesDelta / int56(uint56(secondsAgo))
        );
        // Always round to negative infinity
        if (
            tickCumulativesDelta < 0 &&
            (tickCumulativesDelta % int56(uint56(secondsAgo)) != 0)
        ) arithmeticMeanTick--;

        // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
        uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
        harmonicMeanLiquidity = uint128(
            secondsAgoX160 /
                (uint192(secondsPerLiquidityCumulativesDelta) << 32)
        );
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(
                sqrtRatioX96,
                sqrtRatioX96,
                1 << 64
            );
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    /// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
    function getOldestObservationSecondsAgo(address pool)
        internal
        view
        returns (uint32 secondsAgo)
    {
        (
            ,
            ,
            uint16 observationIndex,
            uint16 observationCardinality,
            ,
            ,

        ) = IUniswapV3Pool(pool).slot0();
        require(observationCardinality > 0, "NI");

        (uint32 observationTimestamp, , , bool initialized) = IUniswapV3Pool(
            pool
        ).observations((observationIndex + 1) % observationCardinality);

        // The next index might not be initialized if the cardinality is in the process of increasing
        // In this case the oldest observation is always in index 0
        if (!initialized) {
            (observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
        }

        secondsAgo = uint32(block.timestamp) - observationTimestamp;
    }

    /// @notice Given a pool, it returns the tick value as of the start of the current block
    /// @param pool Address of Uniswap V3 pool
    /// @return The tick that the pool was in at the start of the current block
    function getBlockStartingTickAndLiquidity(address pool)
        internal
        view
        returns (int24, uint128)
    {
        (
            ,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            ,
            ,

        ) = IUniswapV3Pool(pool).slot0();

        // 2 observations are needed to reliably calculate the block starting tick
        require(observationCardinality > 1, "NEO");

        // If the latest observation occurred in the past, then no tick-changing trades have happened in this block
        // therefore the tick in `slot0` is the same as at the beginning of the current block.
        // We don't need to check if this observation is initialized - it is guaranteed to be.
        (
            uint32 observationTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,

        ) = IUniswapV3Pool(pool).observations(observationIndex);
        if (observationTimestamp != uint32(block.timestamp)) {
            return (tick, IUniswapV3Pool(pool).liquidity());
        }

        uint256 prevIndex = (uint256(observationIndex) +
            observationCardinality -
            1) % observationCardinality;
        (
            uint32 prevObservationTimestamp,
            int56 prevTickCumulative,
            uint160 prevSecondsPerLiquidityCumulativeX128,
            bool prevInitialized
        ) = IUniswapV3Pool(pool).observations(prevIndex);

        require(prevInitialized, "ONI");

        uint32 delta = observationTimestamp - prevObservationTimestamp;
        tick = int24(
            (tickCumulative - prevTickCumulative) / int56(uint56(delta))
        );
        uint128 liquidity = uint128(
            (uint192(delta) * type(uint160).max) /
                (uint192(
                    secondsPerLiquidityCumulativeX128 -
                        prevSecondsPerLiquidityCumulativeX128
                ) << 32)
        );
        return (tick, liquidity);
    }

    /// @notice Information for calculating a weighted arithmetic mean tick
    struct WeightedTickData {
        int24 tick;
        uint128 weight;
    }

    /// @notice Given an array of ticks and weights, calculates the weighted arithmetic mean tick
    /// @param weightedTickData An array of ticks and weights
    /// @return weightedArithmeticMeanTick The weighted arithmetic mean tick
    /// @dev Each entry of `weightedTickData` should represents ticks from pools with the same underlying pool tokens. If they do not,
    /// extreme care must be taken to ensure that ticks are comparable (including decimal differences).
    /// @dev Note that the weighted arithmetic mean tick corresponds to the weighted geometric mean price.
    function getWeightedArithmeticMeanTick(
        WeightedTickData[] memory weightedTickData
    ) internal pure returns (int24 weightedArithmeticMeanTick) {
        // Accumulates the sum of products between each tick and its weight
        int256 numerator;

        // Accumulates the sum of the weights
        uint256 denominator;

        // Products fit in 152 bits, so it would take an array of length ~2**104 to overflow this logic
        for (uint256 i; i < weightedTickData.length; i++) {
            numerator +=
                weightedTickData[i].tick *
                int256(int128(weightedTickData[i].weight));
            denominator += weightedTickData[i].weight;
        }

        weightedArithmeticMeanTick = int24(numerator / int256(denominator));
        // Always round to negative infinity
        if (numerator < 0 && (numerator % int256(denominator) != 0))
            weightedArithmeticMeanTick--;
    }

    /// @notice Returns the "synthetic" tick which represents the price of the first entry in `tokens` in terms of the last
    /// @dev Useful for calculating relative prices along routes.
    /// @dev There must be one tick for each pairwise set of tokens.
    /// @param tokens The token contract addresses
    /// @param ticks The ticks, representing the price of each token pair in `tokens`
    /// @return syntheticTick The synthetic tick, representing the relative price of the outermost tokens in `tokens`
    function getChainedPrice(address[] memory tokens, int24[] memory ticks)
        internal
        pure
        returns (int256 syntheticTick)
    {
        require(tokens.length - 1 == ticks.length, "DL");
        for (uint256 i = 1; i <= ticks.length; i++) {
            // check the tokens for address sort order, then accumulate the
            // ticks into the running synthetic tick, ensuring that intermediate tokens "cancel out"
            tokens[i - 1] < tokens[i]
                ? syntheticTick += ticks[i - 1]
                : syntheticTick -= ticks[i - 1];
        }
    }
}

/// @title UniswapV3xPYT
/// @author zefram.eth
/// @notice xPYT implementation using Uniswap V3 to swap NYT into PYT
contract UniswapV3xPYT is XPYT, IUniswapV3SwapCallback {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error Error_NotUniswapV3Pool();
    error Error_BothTokenDeltasAreZero();

    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------

    struct SwapCallbackData {
        ERC20 tokenIn;
        ERC20 tokenOut;
        uint24 fee;
    }

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick + 1. Equivalent to getSqrtRatioAtTick(MIN_TICK) + 1
    /// Copied from v3-core/libraries/TickMath.sol
    uint160 internal constant MIN_SQRT_RATIO_PLUS_ONE = 4295128740;

    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick - 1. Equivalent to getSqrtRatioAtTick(MAX_TICK) - 1
    /// Copied from v3-core/libraries/TickMath.sol
    uint160 internal constant MAX_SQRT_RATIO_MINUS_ONE =
        1461446703485210103287273052203988822378723970341;

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The official Uniswap V3 factory address
    address public immutable uniswapV3Factory;

    /// @notice The Uniswap V3 Quoter deployment
    IQuoter public immutable uniswapV3Quoter;

    /// @notice The fee used by the Uniswap V3 pool used for swapping
    uint24 public immutable uniswapV3PoolFee;

    /// @notice The number of seconds in the past from which to take the TWAP of the Uniswap V3 pool
    uint32 public immutable uniswapV3TwapSecondsAgo;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        ERC20 asset_,
        string memory name_,
        string memory symbol_,
        uint256 pounderRewardMultiplier_,
        uint256 minOutputMultiplier_,
        address uniswapV3Factory_,
        IQuoter uniswapV3Quoter_,
        uint24 uniswapV3PoolFee_,
        uint32 uniswapV3TwapSecondsAgo_
    )
        XPYT(
            asset_,
            name_,
            symbol_,
            pounderRewardMultiplier_,
            minOutputMultiplier_
        )
    {
        uniswapV3Factory = uniswapV3Factory_;
        uniswapV3Quoter = uniswapV3Quoter_;
        uniswapV3PoolFee = uniswapV3PoolFee_;
        uniswapV3TwapSecondsAgo = uniswapV3TwapSecondsAgo_;
    }

    /// -----------------------------------------------------------------------
    /// Uniswap V3 support
    /// -----------------------------------------------------------------------

    /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        // determine amount to pay
        uint256 amountToPay;
        if (amount0Delta > 0) {
            amountToPay = uint256(amount0Delta);
        } else if (amount1Delta > 0) {
            amountToPay = uint256(amount1Delta);
        } else {
            revert Error_BothTokenDeltasAreZero();
        }

        // decode callback data
        SwapCallbackData memory callbackData = abi.decode(
            data,
            (SwapCallbackData)
        );

        // verify sender
        address pool = PoolAddress.computeAddress(
            uniswapV3Factory,
            PoolAddress.getPoolKey(
                address(callbackData.tokenIn),
                address(callbackData.tokenOut),
                callbackData.fee
            )
        );
        if (msg.sender != address(pool)) {
            revert Error_NotUniswapV3Pool();
        }

        // pay tokens to the Uniswap V3 pool
        callbackData.tokenIn.safeTransfer(msg.sender, amountToPay);
    }

    /// -----------------------------------------------------------------------
    /// Internal utilities
    /// -----------------------------------------------------------------------

    /// @inheritdoc XPYT
    function _getTwapQuote(uint256 nytAmountIn)
        internal
        view
        virtual
        override
        returns (bool success, uint256 xPytAmountOut)
    {
        // get uniswap v3 pool
        address uniPool = PoolAddress.computeAddress(
            uniswapV3Factory,
            PoolAddress.getPoolKey(
                address(nyt),
                address(this),
                uniswapV3PoolFee
            )
        );

        // ensure oldest observation is at or before (block.timestamp - uniswapV3TwapSecondsAgo)
        uint32 oldestObservationSecondsAgo = OracleLibrary
            .getOldestObservationSecondsAgo(uniPool);
        if (oldestObservationSecondsAgo < uniswapV3TwapSecondsAgo) {
            return (false, 0);
        }

        // get mean tick from TWAP oracle
        (int24 arithmeticMeanTick, ) = OracleLibrary.consult(
            uniPool,
            uniswapV3TwapSecondsAgo
        );

        // convert mean tick to quote
        success = true;
        xPytAmountOut = OracleLibrary.getQuoteAtTick(
            arithmeticMeanTick,
            uint128(nytAmountIn),
            address(nyt),
            address(this)
        );
    }

    /// @inheritdoc XPYT
    function _swap(uint256 nytAmountIn)
        internal
        virtual
        override
        returns (uint256 xPytAmountOut)
    {
        // get uniswap v3 pool
        IUniswapV3Pool uniPool = IUniswapV3Pool(
            PoolAddress.computeAddress(
                uniswapV3Factory,
                PoolAddress.getPoolKey(
                    address(nyt),
                    address(this),
                    uniswapV3PoolFee
                )
            )
        );

        // do swap
        bytes memory swapCallbackData = abi.encode(
            SwapCallbackData({
                tokenIn: ERC20(address(nyt)),
                tokenOut: this,
                fee: uniswapV3PoolFee
            })
        );
        bool zeroForOne = address(nyt) < address(this);
        (int256 amount0, int256 amount1) = uniPool.swap(
            address(this),
            zeroForOne,
            int256(nytAmountIn),
            zeroForOne ? MIN_SQRT_RATIO_PLUS_ONE : MAX_SQRT_RATIO_MINUS_ONE,
            swapCallbackData
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    /// @inheritdoc XPYT
    function _quote(uint256 nytAmountIn)
        internal
        virtual
        override
        returns (uint256 xPytAmountOut)
    {
        bool zeroForOne = address(nyt) < address(this);
        return
            uniswapV3Quoter.quoteExactInputSingle(
                address(nyt),
                address(this),
                uniswapV3PoolFee,
                nytAmountIn,
                zeroForOne ? MIN_SQRT_RATIO_PLUS_ONE : MAX_SQRT_RATIO_MINUS_ONE
            );
    }
}