/**
 *Submitted for verification at Etherscan.io on 2023-09-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.4;

contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
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
    ) public returns (bool) {
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

    
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * @param s The spender
     * @param a The amount increased
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */

    function increaseAllowance(address s, uint256 a) public returns (bool) {
        _approve(msg.sender, s, allowance[msg.sender][s] + a);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * @param s The spender
     * @param a The amount subtracted
     * 
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address s, uint256 a) public returns (bool) {
        uint256 currentAllowance = allowance[msg.sender][s];
        require(currentAllowance >= a, "erc20 decreased allowance below zero");
        _approve(msg.sender, s, currentAllowance - a);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
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
    ) public {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view returns (bytes32) {
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

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    function _approve(address holder, address spender, uint256 amount) internal {
        allowance[holder][spender] = amount;

        emit Approval(msg.sender, spender, amount);
    }
}

library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

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
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

pragma solidity >=0.8.0;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function transferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function transfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function approve(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IAuthorizer {
    /**
     * @dev Returns true if `account` can perform the action described by `actionId` in the contract `where`.
     */
    function canPerform(
        bytes32 actionId,
        address account,
        address where
    ) external view returns (bool);
}


interface IAuthentication {
    /**
     * @dev Returns the action identifier associated with the external function described by `selector`.
     */
    function getActionId(bytes4 selector) external view returns (bytes32);
}

interface IBalancerMinter {
    function mint(address gauge) external returns (uint256);
}
interface IPoolSwapStructs {
    // This is not really an interface - it just defines common structs used by other interfaces: IGeneralPool and
    // IMinimalSwapInfoPool.
    //
    // This data structure represents a request for a token swap, where `kind` indicates the swap type ('given in' or
    // 'given out') which indicates whether or not the amount sent by the pool is known.
    //
    // The pool receives `tokenIn` and sends `tokenOut`. `amount` is the number of `tokenIn` tokens the pool will take
    // in, or the number of `tokenOut` tokens the Pool will send out, depending on the given swap `kind`.
    //
    // All other fields are not strictly necessary for most swaps, but are provided to support advanced scenarios in
    // some Pools.
    //
    // `poolId` is the ID of the Pool involved in the swap - this is useful for Pool contracts that implement more than
    // one Pool.
    //
    // The meaning of `lastChangeBlock` depends on the Pool specialization:
    //  - Two Token or Minimal Swap Info: the last block in which either `tokenIn` or `tokenOut` changed its total
    //    balance.
    //  - General: the last block in which *any* of the Pool's registered tokens changed its total balance.
    //
    // `from` is the origin address for the funds the Pool receives, and `to` is the destination address
    // where the Pool sends the outgoing tokens.
    //
    // `userData` is extra data provided by the caller - typically a signature from a trusted party.
    struct SwapRequest {
        IVault.SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }
}
interface IProtocolFeesCollector {
    event SwapFeePercentageChanged(uint256 newSwapFeePercentage);
    event FlashLoanFeePercentageChanged(uint256 newFlashLoanFeePercentage);

    function withdrawCollectedFees(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    ) external;

    function setSwapFeePercentage(uint256 newSwapFeePercentage) external;

    function setFlashLoanFeePercentage(uint256 newFlashLoanFeePercentage) external;

    function getSwapFeePercentage() external view returns (uint256);

    function getFlashLoanFeePercentage() external view returns (uint256);

    function getCollectedFeeAmounts(IERC20[] memory tokens) external view returns (uint256[] memory feeAmounts);

    function getAuthorizer() external view returns (IAuthorizer);

    function vault() external view returns (IVault);
}
interface IBasePool is IPoolSwapStructs {
    /**
     * @dev Called by the Vault when a user calls `IVault.joinPool` to add liquidity to this Pool. Returns how many of
     * each registered token the user should provide, as well as the amount of protocol fees the Pool owes to the Vault.
     * The Vault will then take tokens from `sender` and add them to the Pool's balances, as well as collect
     * the reported amount in protocol fees, which the pool should calculate based on `protocolSwapFeePercentage`.
     *
     * Protocol fees are reported and charged on join events so that the Pool is free of debt whenever new users join.
     *
     * `sender` is the account performing the join (from which tokens will be withdrawn), and `recipient` is the account
     * designated to receive any benefits (typically pool shares). `balances` contains the total balances
     * for each token the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * join (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as minting pool shares.
     */
    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts);

    /**
     * @dev Called by the Vault when a user calls `IVault.exitPool` to remove liquidity from this Pool. Returns how many
     * tokens the Vault should deduct from the Pool's balances, as well as the amount of protocol fees the Pool owes
     * to the Vault. The Vault will then take tokens from the Pool's balances and send them to `recipient`,
     * as well as collect the reported amount in protocol fees, which the Pool should calculate based on
     * `protocolSwapFeePercentage`.
     *
     * Protocol fees are charged on exit events to guarantee that users exiting the Pool have paid their share.
     *
     * `sender` is the account performing the exit (typically the pool shareholder), and `recipient` is the account
     * to which the Vault will send the proceeds. `balances` contains the total token balances for each token
     * the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * exit (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as burning pool shares.
     */
    function onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts);

    /**
     * @dev Returns this Pool's ID, used when interacting with the Vault (to e.g. join the Pool or swap with it).
     */
    function getPoolId() external view returns (bytes32);

    /**
     * @dev Returns the current swap fee percentage as a 18 decimal fixed point number, so e.g. 1e17 corresponds to a
     * 10% swap fee.
     */
    function getSwapFeePercentage() external view returns (uint256);

    /**
     * @dev Returns the scaling factors of each of the Pool's tokens. This is an implementation detail that is typically
     * not relevant for outside parties, but which might be useful for some types of Pools.
     */
    function getScalingFactors() external view returns (uint256[] memory);

    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}
interface IQuery {

    function queryJoin(
            bytes32 poolId,
            address sender,
            address recipient,
            IVault.JoinPoolRequest memory request) external returns (uint256 bptOut, uint256[] memory amountsIn);

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        IVault.ExitPoolRequest memory request) external returns (uint256 bptIn, uint256[] memory amountsOut);
}
interface ISignaturesValidator {
    /**
     * @dev Returns the EIP712 domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @dev Returns the next nonce used by an address to sign messages.
     */
    function getNextNonce(address user) external view returns (uint256);
}
interface ITemporarilyPausable {
    /**
     * @dev Emitted every time the pause state changes by `_setPaused`.
     */
    event PausedStateChanged(bool paused);

    /**
     * @dev Returns the current paused state.
     */
    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );
}
pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault is ISignaturesValidator, ITemporarilyPausable, IAuthentication {
    // Generalities about the Vault:
    //
    // - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
    // transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
    // `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
    // calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
    // a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
    //
    // - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
    // while execution control is transferred to a token contract during a swap) will result in a revert. View
    // functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
    // Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
    //
    // - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

    // Authorizer
    //
    // Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
    // outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
    // can perform a given action.

    /**
     * @dev Returns the Vault's Authorizer.
     */
    function getAuthorizer() external view returns (IAuthorizer);

    /**
     * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
     *
     * Emits an `AuthorizerChanged` event.
     */
    function setAuthorizer(IAuthorizer newAuthorizer) external;

    /**
     * @dev Emitted when a new authorizer is set by `setAuthorizer`.
     */
    event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

    // Relayers
    //
    // Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
    // Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
    // and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
    // this power, two things must occur:
    //  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
    //    means that Balancer governance must approve each individual contract to act as a relayer for the intended
    //    functions.
    //  - Each user must approve the relayer to act on their behalf.
    // This double protection means users cannot be tricked into approving malicious relayers (because they will not
    // have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
    // Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

    /**
     * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
     */
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    /**
     * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
     *
     * Emits a `RelayerApprovalChanged` event.
     */
    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    /**
     * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
     */
    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind { JOIN, EXIT }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    // Flash Loans

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);

    // Asset Management
    //
    // Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
    // tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
    // `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
    // controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
    // prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
    // not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
    //
    // However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
    // for example by lending unused tokens out for interest, or using them to participate in voting protocols.
    //
    // This concept is unrelated to the IAsset interface.

    /**
     * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
     *
     * Pool Balance management features batching, which means a single contract call can be used to perform multiple
     * operations of different kinds, with different Pools and tokens, at once.
     *
     * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
     */
    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    /**
     * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
     *
     * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
     *
     * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
     * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
     */
    enum PoolBalanceOpKind { WITHDRAW, DEPOSIT, UPDATE }

    /**
     * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
     */
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

    // Protocol Fees
    //
    // Some operations cause the Vault to collect tokens in the form of protocol fees, which can then be withdrawn by
    // permissioned accounts.
    //
    // There are two kinds of protocol fees:
    //
    //  - flash loan fees: charged on all flash loans, as a percentage of the amounts lent.
    //
    //  - swap fees: a percentage of the fees charged by Pools when performing swaps. For a number of reasons, including
    // swap gas costs and interface simplicity, protocol swap fees are not charged on each individual swap. Rather,
    // Pools are expected to keep track of how much they have charged in swap fees, and pay any outstanding debts to the
    // Vault when they are joined or exited. This prevents users from joining a Pool with unpaid debt, as well as
    // exiting a Pool in debt without first paying their share.

    /**
     * @dev Returns the current protocol fee module.
     */
    function getProtocolFeesCollector() external view returns (IProtocolFeesCollector);

    /**
     * @dev Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
     * error in some part of the system.
     *
     * The Vault can only be paused during an initial time period, after which pausing is forever disabled.
     *
     * While the contract is paused, the following features are disabled:
     * - depositing and transferring internal balance
     * - transferring external balance (using the Vault's allowance)
     * - swaps
     * - joining Pools
     * - Asset Manager interactions
     *
     * Internal Balance can still be withdrawn, and Pools exited.
     */
    function setPaused(bool paused) external;

    /**
     * @dev Returns the Vault's WETH instance.
     */
    function WETH() external view returns (IWETH);
    // solhint-disable-previous-line func-name-mixedcase
}
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

contract stkSWIV is ERC20 {
    using FixedPointMathLib for uint256;

    // The Swivel Multisig (or should be)
    address public admin;
    // The Swivel Token
    ERC20 immutable public SWIV;
    // The Swivel/ETH balancer LP token
    ERC20 immutable public balancerLPT;
    // The Static Balancer Vault
    IVault immutable public balancerVault;
    // The Static Balancer Query Helper
    IQuery immutable public balancerQuery;
    // The Static Balancer Token ERC20
    ERC20 immutable public balancerToken;
    // The Balancer Pool ID
    bytes32 public balancerPoolID;
    // The withdrawal cooldown length
    uint256 public cooldownLength = 2 weeks;
    // The window to withdraw after cooldown
    uint256 public withdrawalWindow = 1 weeks;
    // Mapping of user address -> unix timestamp for cooldown
    mapping (address => uint256) public cooldownTime;
    // Mapping of user address -> amount of stkSWIV shares to be withdrawn
    mapping (address => uint256) internal _cooldownAmount;
    // Determines whether the contract is paused or not
    bool public paused;
    // The most recently withdrawn BPT timestamp in unix (only when paying out insurance)
    uint256 public lastWithdrawnBPT;
    // The queued emergency withdrawal time mapping
    mapping (address => uint256) public withdrawalTime;
    // The WETH address
    IWETH immutable public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    event Donation(uint256 amount, address indexed donator);

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Paused(bool);

    event WithdrawalQueued(address indexed token, uint256 indexed timestamp);

    error Exception(uint8, uint256, uint256, address, address);

    constructor (ERC20 s, ERC20 b, bytes32 p) ERC20("Staked SWIV/ETH", "stkSWIV", s.decimals() + 18) {
        SWIV = s;
        balancerVault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        balancerLPT = b;
        balancerPoolID = p;
        balancerQuery = IQuery(0xE39B5e3B6D74016b2F6A9673D7d7493B6DF549d5);
        balancerToken = ERC20(0xba100000625a3754423978a60c9317c58a424e3D);
        admin = msg.sender;
        SafeTransferLib.approve(SWIV, address(balancerVault), type(uint256).max);
        SafeTransferLib.approve(ERC20(address(WETH)), address(balancerVault), type(uint256).max);
    }

    fallback() external payable {
    }

    // @notice: If the user's cooldown window is passed, their cooldown amount is reset to 0
    // @param: owner - address of the owner
    // @returns: the cooldown amount
    function cooldownAmount(address owner) external view returns(uint256){
        if (cooldownTime[owner] + withdrawalWindow < block.timestamp) {
            return 0;
        }
        return _cooldownAmount[owner];
    }

    function asset() public view returns (address) {
        return (address(balancerLPT));
    }

    function totalAssets() public view returns (uint256 assets) {
        return (balancerLPT.balanceOf(address(this)));
    }

    // The number of SWIV/ETH balancer shares owned / the stkSWIV total supply
    // Conversion of 1 stkSWIV share to an amount of SWIV/ETH balancer shares (scaled to 1e18) (starts at 1:1e18)
    // Buffered by 1e18 to avoid 4626 inflation attacks -- https://ethereum-magicians.org/t/address-eip-4626-inflation-attacks-with-virtual-shares-and-assets/12677
    // @returns: the exchange rate
    function exchangeRateCurrent() public view returns (uint256) {
        return (this.totalSupply() + 1e18 / totalAssets() + 1);
    }

    // Conversion of amount of SWIV/ETH balancer assets to stkSWIV shares
    // @param: assets - amount of SWIV/ETH balancer pool tokens
    // @returns: the amount of stkSWIV shares
    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        return (assets.mulDivDown(this.totalSupply() + 1e18, totalAssets() + 1));
    }

    // Conversion of amount of stkSWIV shares to SWIV/ETH balancer assets
    // @param: shares - amount of stkSWIV shares
    // @returns: the amount of SWIV/ETH balancer pool tokens
    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        return (shares.mulDivDown(totalAssets() + 1, this.totalSupply() + 1e18));
    }

    // Preview of the amount of balancerLPT required to mint `shares` of stkSWIV
    // @param: shares - amount of stkSWIV shares
    // @returns: assets the amount of balancerLPT tokens required
    function previewMint(uint256 shares) public view virtual returns (uint256 assets) {
        return (shares.mulDivUp(totalAssets() + 1, this.totalSupply() + 1e18));
    }

    // Preview of the amount of balancerLPT received from redeeming `shares` of stkSWIV
    // @param: shares - amount of stkSWIV shares
    // @returns: assets the amount of balancerLPT tokens received
    function previewRedeem(uint256 shares) public view virtual returns (uint256 assets) {
        return (convertToAssets(shares));
    }

    // Preview of the amount of stkSWIV received from depositing `assets` of balancerLPT
    // @param: assets - amount of balancerLPT tokens
    // @returns: shares the amount of stkSWIV shares received
    function previewDeposit(uint256 assets) public view virtual returns (uint256 shares) {
        return (convertToShares(assets));
    }

    // Preview of the amount of stkSWIV required to withdraw `assets` of balancerLPT
    // @param: assets - amount of balancerLPT tokens
    // @returns: shares the amount of stkSWIV shares required
    function previewWithdraw(uint256 assets) public view virtual returns (uint256 shares) {
        return (assets.mulDivUp(this.totalSupply() + 1e18, totalAssets() + 1));
    }

    // Maximum amount a given receiver can mint
    // @param: receiver - address of the receiver
    // @returns: the maximum amount of stkSWIV shares
    function maxMint(address receiver) public pure returns (uint256 maxShares) {
        return (type(uint256).max);
    }

    // Maximum amount a given owner can redeem
    // @param: owner - address of the owner
    // @returns: the maximum amount of stkSWIV shares
    function maxRedeem(address owner) public view returns (uint256 maxShares) {
        return (this.balanceOf(owner));
    }

    // Maximum amount a given owner can withdraw
    // @param: owner - address of the owner
    // @returns: the maximum amount of balancerLPT assets
    function maxWithdraw(address owner) public view returns (uint256 maxAssets) {
        return (convertToAssets(this.balanceOf(owner)));
    }

    // Maximum amount a given receiver can deposit
    // @param: receiver - address of the receiver
    // @returns: the maximum amount of balancerLPT assets
    function maxDeposit(address receiver) public pure returns (uint256 maxAssets) {
        return (type(uint256).max);
    }

    // Queues `amount` of stkSWIV shares to be withdrawn after the cooldown period
    // @param: amount - amount of stkSWIV shares to be withdrawn
    // @returns: the total amount of stkSWIV shares to be withdrawn
    function cooldown(uint256 shares) public returns (uint256) {
        // Require the total amount to be < balanceOf
        if (_cooldownAmount[msg.sender] + shares > balanceOf[msg.sender]) {
            revert Exception(3, _cooldownAmount[msg.sender] + shares, balanceOf[msg.sender], msg.sender, address(0));
        }
        // If cooldown window has passed, reset cooldownAmount + add, else add to current cooldownAmount
        if (cooldownTime[msg.sender] + withdrawalWindow < block.timestamp) {
            _cooldownAmount[msg.sender] = shares;
        }
        else {
            _cooldownAmount[msg.sender] = _cooldownAmount[msg.sender] + shares;
        }
        // Reset cooldown time
        cooldownTime[msg.sender] = block.timestamp + cooldownLength;

        return(_cooldownAmount[msg.sender]);
    }

    // Mints `shares` to `receiver` and transfers `assets` of balancerLPT tokens from `msg.sender`
    // @param: shares - amount of stkSWIV shares to mint
    // @param: receiver - address of the receiver
    // @returns: the amount of balancerLPT tokens deposited
    function mint(uint256 shares, address receiver) public payable returns (uint256) {
        // Convert shares to assets
        uint256 assets = previewMint(shares);
        // Transfer assets of balancer LP tokens from sender to this contract
        SafeTransferLib.transferFrom(balancerLPT, msg.sender, address(this), assets);
        // Mint shares to receiver
        _mint(receiver, shares);
        // Emit deposit event
        emit Deposit(msg.sender, receiver, assets, shares);

        return (assets);
    }

    // Redeems `shares` from `owner` and transfers `assets` of balancerLPT tokens to `receiver`
    // @param: shares - amount of stkSWIV shares to redeem
    // @param: receiver - address of the receiver
    // @param: owner - address of the owner
    // @returns: the amount of balancerLPT tokens withdrawn
    function redeem(uint256 shares, address receiver, address owner) Unpaused() public returns (uint256) {
        // Convert shares to assets
        uint256 assets = previewRedeem(shares);
        // Get the cooldown time
        uint256 cTime = cooldownTime[msg.sender];
        // If the sender is not the owner check allowances
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];
            // If the allowance is not max, subtract the shares from the allowance, reverts on underflow if not enough allowance
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }
        // If the cooldown time is in the future or 0, revert
        if (cTime > block.timestamp || cTime == 0 || cTime + withdrawalWindow < block.timestamp) {
            revert Exception(0, cTime, block.timestamp, address(0), address(0));
        }
        // If the redeemed shares is greater than the cooldown amount, revert
        uint256 cAmount = _cooldownAmount[msg.sender];
        if (shares > cAmount) {
            revert Exception(1, cAmount, shares, address(0), address(0));
        }
        // If the shares are greater than the balance of the owner, revert
        if (shares > this.balanceOf(owner)) {
            revert Exception(2, shares, this.balanceOf(owner), address(0), address(0));
        }
        // Transfer the balancer LP tokens to the receiver
        SafeTransferLib.transfer(balancerLPT, receiver, assets);
        // Burn the shares
        _burn(msg.sender, shares);
        // Reset the cooldown amount
        _cooldownAmount[msg.sender] = _cooldownAmount[msg.sender] - shares;
        // Emit withdraw event
        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return (assets);
    }

    // Deposits `assets` of balancerLPT tokens from `msg.sender` and mints `shares` to `receiver`
    // @param: assets - amount of balancerLPT tokens to deposit
    // @param: receiver - address of the receiver
    // @returns: the amount of stkSWIV shares minted
    function deposit(uint256 assets, address receiver) public returns (uint256) {
        // Convert assets to shares          
        uint256 shares = previewDeposit(assets);
        // Transfer assets of balancer LP tokens from sender to this contract
        SafeTransferLib.transferFrom(balancerLPT, msg.sender, address(this), assets);        
        // Mint shares to receiver
        _mint(receiver, shares);
        // Emit deposit event
        emit Deposit(msg.sender, receiver, assets, shares);

        return (shares);
    }

    // Withdraws `assets` of balancerLPT tokens to `receiver` and burns `shares` from `owner`
    // @param: assets - amount of balancerLPT tokens to withdraw
    // @param: receiver - address of the receiver
    // @param: owner - address of the owner
    // @returns: the amount of stkSWIV shares withdrawn
    function withdraw(uint256 assets, address receiver, address owner) Unpaused()  public returns (uint256) {
        // Convert assets to shares
        uint256 shares = previewWithdraw(assets);
        // Get the cooldown time
        uint256 cTime = cooldownTime[msg.sender];
        // If the sender is not the owner check allowances
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];
            // If the allowance is not max, subtract the shares from the allowance, reverts on underflow if not enough allowance
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }
        // If the cooldown time is in the future or 0, revert
        if (cTime > block.timestamp || cTime == 0 || cTime + withdrawalWindow < block.timestamp) {
            revert Exception(0, cTime, block.timestamp, address(0), address(0));
        }
        // If the redeemed shares is greater than the cooldown amount, revert
        uint256 cAmount = _cooldownAmount[msg.sender];
        if (shares > cAmount) {
            revert Exception(1, cAmount, shares, address(0), address(0));
        }
        // If the shares are greater than the balance of the owner, revert
        if (shares > this.balanceOf(owner)) {
            revert Exception(2, shares, this.balanceOf(owner), address(0), address(0));
        }
        // Transfer the balancer LP tokens to the receiver
        SafeTransferLib.transfer(balancerLPT, receiver, assets);
        // Burn the shares   
        _burn(msg.sender, shares);
        // Reset the cooldown amount
        _cooldownAmount[msg.sender] = _cooldownAmount[msg.sender] - shares;
        // Emit withdraw event
        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return (shares);
    }

    //////////////////// ZAP METHODS ////////////////////

    // Transfers a calculated amount of SWIV tokens from `msg.sender` while receiving `msg.value` of ETH
    // Then joins the balancer pool with the SWIV and ETH before minting minBPT of shares to `receiver`
    // Slippage is bound by the `shares` parameter and the calculated maximumSWIV
    // @notice: The amounts transacted in this method are based on msg.value -- `shares` is the minimum amount of shares to mint
    // @param: shares - minimum amount of stkSWIV shares to mint
    // @param: receiver - address of the receiver
    // @returns: assets the amount of SWIV tokens deposited
    // @returns: sharesToMint the actual amount of shares minted
    function mintZap(uint256 shares, address receiver, uint256 maximumSWIV) public payable returns (uint256 assets, uint256 sharesToMint, uint256[2] memory balancesSpent) {
        // Get token info from vault
        (,uint256[] memory balances,) = balancerVault.getPoolTokens(balancerPoolID);
        // Calculate SWIV transfer amount from msg.value (expecting at least enough msg.value and SWIV available to cover `shares` minted)
        uint256 swivAmount = msg.value * balances[0] / balances[1];
        // If the SWIV amount is greater than the maximum SWIV, revert
        if (swivAmount > maximumSWIV) {
            revert Exception(5, swivAmount, maximumSWIV, address(0), address(0));
        }
        // Query the pool join to get the bpt out (assets)
        (uint256 minBPT, uint256[] memory amountsIn) = queryBalancerJoin([address(SWIV), address(WETH)], [swivAmount, msg.value], 0);
        // Calculate expected shares to mint before transfering funds 
        sharesToMint = convertToShares(minBPT);
        // Wrap msg.value into WETH
        WETH.deposit{value: msg.value}();
        // Transfer assets of SWIV tokens from sender to this contract
        SafeTransferLib.transferFrom(SWIV, msg.sender, address(this), amountsIn[0]);
        // Join the balancer pool
        balancerJoin(1, [address(SWIV), address(WETH)], [amountsIn[0], amountsIn[1]], minBPT);
        // If the shares to mint is less than the minimum shares, revert
        if (sharesToMint < shares) {
            revert Exception(4, sharesToMint, shares, address(0), address(0));
        }
        // Mint shares to receiver
        _mint(receiver, sharesToMint);
        {
            // If there is any leftover SWIV, transfer it to the msg.sender
            uint256 remainingSWIV = SWIV.balanceOf(address(this));
            if (remainingSWIV > 0) {
                // Transfer the SWIV to the receiver
                SafeTransferLib.transfer(SWIV, msg.sender, remainingSWIV);
            }
            uint256 remainingWETH = WETH.balanceOf(address(this));
            // If there is any leftover ETH, transfer it to the msg.sender
            if (remainingWETH > 0) {
                // Transfer the ETH to the receiver
                WETH.withdraw(remainingWETH);
                payable(msg.sender).transfer(remainingWETH);
            }
        }
        // Emit deposit event
        emit Deposit(msg.sender, receiver, minBPT, sharesToMint);

        return (minBPT, sharesToMint, [amountsIn[0], amountsIn[1]]);
    }

    // Exits the balancer pool and transfers queried amounts of SWIV tokens and ETH to `receiver`
    // Then burns `shares` from `owner`
    // Slippage is bound by minimumETH and minimumSWIV
    // @param: shares - amount of stkSWIV shares to redeem
    // @param: receiver - address of the receiver
    // @param: owner - address of the owner
    // @returns: assets the amount of bpt withdrawn
    // @returns: sharesBurnt the amount of stkSWIV shares burnt
    function redeemZap(uint256 shares, address payable receiver, address owner, uint256 minimumETH, uint256 minimumSWIV) Unpaused()  public returns (uint256 assets, uint256 sharesBurnt, uint256[2] memory balancesReturned) {
        // Convert shares to assets
        assets = previewRedeem(shares);
        {
            // Get the cooldown time
            uint256 cTime = cooldownTime[msg.sender];
            // If the sender is not the owner check allowances
            if (msg.sender != owner) {
                uint256 allowed = allowance[owner][msg.sender];
                // If the allowance is not max, subtract the shares from the allowance, reverts on underflow if not enough allowance
                if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
            }
            // If the cooldown time is in the future or 0, revert
            if (cTime > block.timestamp || cTime == 0 || cTime + withdrawalWindow < block.timestamp) {
                revert Exception(0, cTime, block.timestamp, address(0), address(0));
            }
            {
                // If the redeemed shares is greater than the cooldown amount, revert
                uint256 cAmount = _cooldownAmount[msg.sender];
                if (shares > cAmount) {
                    revert Exception(1, cAmount, shares, address(0), address(0));
                }
            }
        }
        // If the shares are greater than the balance of the owner, revert
        if (shares > this.balanceOf(owner)) {
            revert Exception(2, shares, this.balanceOf(owner), address(0), address(0));
        }
        // Query the pool exit to get the amounts out
        (uint256 bptIn, uint256[] memory amountsOut) = queryBalancerExit([address(SWIV), address(WETH)], [minimumSWIV, minimumETH], assets);
        // If bptIn isnt equivalent to assets, overwrite shares
        if (bptIn != assets) {
            shares = convertToShares(bptIn);
            // Require the bptIn <= shares converted to assets (to account for slippage)
            if (bptIn > convertToAssets(shares)) {
                revert Exception(5, bptIn, convertToAssets(shares), address(0), address(0));
            }
        }
        // If the eth or swiv out is less than the minimum, revert
        if (amountsOut[0] < minimumSWIV || amountsOut[1] < minimumETH) {
            revert Exception(5, amountsOut[0], minimumSWIV, address(0), address(0));
        }
        // Exit the balancer pool
        balancerExit(1, [address(SWIV), address(WETH)], [amountsOut[0], amountsOut[1]], bptIn);
        // Unwrap the WETH
        WETH.withdraw(amountsOut[1]);
        // Transfer the SWIV tokens to the receiver
        SafeTransferLib.transfer(SWIV, receiver, amountsOut[0]);
        // Transfer the ETH to the receiver
        receiver.transfer(amountsOut[1]);
        // Burn the shares
        _burn(msg.sender, shares);
        // // Reset the cooldown amount
        _cooldownAmount[msg.sender] = _cooldownAmount[msg.sender] - shares;
        // // Emit withdraw event
        emit Withdraw(msg.sender, receiver, owner, bptIn, shares);

        return (bptIn, shares, [amountsOut[0], amountsOut[1]]);
    }

    // Transfers `assets` of SWIV tokens from `msg.sender` while receiving `msg.value` of ETH
    // Then joins the balancer pool with the SWIV and ETH before minting `shares` to `receiver`
    // Slippage is bound by minimumBPT
    // @param: assets - maximum amount of SWIV tokens to deposit
    // @param: receiver - address of the receiver
    // @param: minimumBPT - minimum amount of balancerLPT tokens to mint
    // @returns: the amount of stkSWIV shares minted
    // @returns: the amount of swiv actually deposited
    function depositZap(uint256 assets, address receiver, uint256 minimumBPT) public payable returns (uint256 sharesMinted, uint256 bptIn, uint256[2] memory balancesSpent) {
        // Transfer assets of SWIV tokens from sender to this contract
        SafeTransferLib.transferFrom(SWIV, msg.sender, address(this), assets);
        // Wrap msg.value into WETH
        WETH.deposit{value: msg.value}();
        // Query the pool join to get the bpt out
        (uint256 bptOut, uint256[] memory amountsIn) = queryBalancerJoin([address(SWIV), address(WETH)], [assets, msg.value], minimumBPT);
        // If the bptOut is less than the minimum bpt, revert (to account for slippage)
        if (bptOut < minimumBPT) {
            revert Exception(5, bptOut, minimumBPT, address(0), address(0));
        }
        //  Calculate shares to mint
        sharesMinted = convertToShares(bptOut);
        // Join the balancer pool
        balancerJoin(1, [address(SWIV), address(WETH)], [amountsIn[0], amountsIn[1]], bptOut);
        // // Mint shares to receiver
        _mint(receiver, sharesMinted);
        // If there is any leftover SWIV, transfer it to the msg.sender
        uint256 swivBalance = SWIV.balanceOf(address(this));
        if (swivBalance > 0) {
            // Transfer the SWIV to the receiver
            SafeTransferLib.transfer(SWIV, msg.sender, swivBalance);
        }
        // If there is any leftover ETH, transfer it to the msg.sender
        if (WETH.balanceOf(address(this)) > 0) {
            // Transfer the ETH to the receiver
            uint256 wethAmount = WETH.balanceOf(address(this));
            WETH.withdraw(wethAmount);
            payable(msg.sender).transfer(wethAmount);
        }
        // Emit deposit event
        emit Deposit(msg.sender, receiver, assets, sharesMinted);

        return (sharesMinted, bptOut, [amountsIn[0], amountsIn[1]]);
    }

    // Exits the balancer pool and transfers `assets` of SWIV tokens and the current balance of ETH to `receiver`
    // Then burns `shares` from `owner`
    // Slippage is bound by maximumBPT
    // @param: assets - amount of SWIV tokens to withdraw
    // @param: receiver - address of the receiver
    // @param: owner - address of the owner
    // @param: maximumBPT - maximum amount of balancerLPT tokens to redeem
    // @returns: the amount of stkSWIV shares burnt
    function withdrawZap(uint256 assets, uint256 ethAssets, address payable receiver, address owner, uint256 maximumBPT) Unpaused() public returns (uint256 sharesRedeemed, uint256 bptOut, uint256[2] memory balancesReturned) {
        // Get the cooldown time
        uint256 cTime = cooldownTime[msg.sender];
        // If the sender is not the owner check allowances
        // If the cooldown time is in the future or 0, revert
        if (cTime > block.timestamp || cTime + withdrawalWindow < block.timestamp) {
            revert Exception(0, cTime, block.timestamp, address(0), address(0));
        }
        // Query the pool exit to get the amounts out
        (uint256 bptOut, uint256[] memory amountsOut) = queryBalancerExit([address(SWIV), address(WETH)], [assets, ethAssets], maximumBPT);
        // Require the bptOut to be less than the maximum bpt (to account for slippage)
        if (bptOut > maximumBPT) {
            revert Exception(5, bptOut, maximumBPT, address(0), address(0));
        }
        // Calculate shares to redeem
        sharesRedeemed = convertToShares(bptOut);
        // This method is unique in that we cannot check against cAmounts before calculating shares
        // If the redeemed shares is greater than the cooldown amount, revert
        {
            uint256 cAmount = _cooldownAmount[msg.sender];
            if (sharesRedeemed > cAmount) {
                revert Exception(1, cAmount, sharesRedeemed, address(0), address(0));
            }
        }
        // If the shares are greater than the balance of the owner, revert
        if (sharesRedeemed > this.balanceOf(owner)) {
            revert Exception(2, sharesRedeemed, this.balanceOf(owner), address(0), address(0));
        }
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];
            // If the allowance is not max, subtract the shares from the allowance, reverts on underflow if not enough allowance
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - sharesRedeemed;
        }
        // Exit the balancer pool
        balancerExit(2, [address(SWIV), address(WETH)], [amountsOut[0], amountsOut[1]], bptOut);
        // Unwrap the WETH
        WETH.withdraw(amountsOut[1]);
        // Transfer the SWIV tokens to the receiver
        SafeTransferLib.transfer(SWIV, receiver, amountsOut[0]);
        // Transfer the ETH to the receiver
        receiver.transfer(amountsOut[1]);
        // Burn the shares
        _burn(msg.sender, sharesRedeemed);
        // Reset the cooldown amount
        _cooldownAmount[msg.sender] = _cooldownAmount[msg.sender] - sharesRedeemed;
        // Emit withdraw event
        emit Withdraw(msg.sender, receiver, owner, bptOut, sharesRedeemed);

        return (sharesRedeemed, bptOut, [amountsOut[0], amountsOut[1]]);
    }

     /////////////// INTERNAL BALANCER METHODS ////////////////////   
    
    // Queries the balancer pool to either get the tokens required for an amount of BPTs or the amount of BPTs required for an amount of tokens
    // @notice: Only covers weighted pools
    // @param: tokens - array of token addresses
    // @param: amounts - array of token amounts (must be sorted in the same order as addresses)
    // @param: minimumBPT - minimum amount of BPTs to be minted
    // @returns: minBPT - the minimum amount of BPTs to be minted
    // @returns: amountsIn - the amounts of tokens required to mint minBPT
    function queryBalancerJoin(address[2] memory tokens, uint256[2] memory amounts, uint256 minimumBPT) internal returns (uint256 minBPT, uint256[] memory amountsIn) {
        // Instantiate balancer request struct using SWIV and ETH alongside the amounts sent
        IAsset[] memory assetData = new IAsset[](2);
        assetData[0] = IAsset(address(tokens[0]));
        assetData[1] = IAsset(address(tokens[1]));

        uint256[] memory amountData = new uint256[](2);

        // If the minimumBPT is 0, query the balancer pool for the minimum amount of BPTs required for the given amounts of tokens
        if (minimumBPT == 0) {
            amountData[0] = amounts[0];
            amountData[1] = amounts[1];
            IVault.JoinPoolRequest memory requestData = IVault.JoinPoolRequest({
                    assets: assetData,
                    maxAmountsIn: amountData,
                    userData: abi.encode(1, amountData, 0),
                    fromInternalBalance: false
                });
            (minBPT, amountsIn) = balancerQuery.queryJoin(balancerPoolID, msg.sender, address(this), requestData);
            return (minBPT, amountsIn);
        }
        // Else query the balancer pool for the maximum amount of tokens required for the given minimumBPT (Appears to be broken on balancers end for many pools)
        else {
            amountData[0] = type(uint256).max;
            amountData[1] = type(uint256).max;
            IVault.JoinPoolRequest memory requestData = IVault.JoinPoolRequest({
                    assets: assetData,
                    maxAmountsIn: amountData,
                    userData: abi.encode(3, minimumBPT),
                    fromInternalBalance: false
                });
            (minBPT, amountsIn) = balancerQuery.queryJoin(balancerPoolID, msg.sender, address(this), requestData);
            return (minBPT, amountsIn);
        }
    }

    // Queries the balancer pool to either get the tokens received for an amount of BPTs or the amount of BPTs received for an amount of tokens
    // @notice: Only covers weighted pools
    // @param: tokens - array of token addresses
    // @param: amounts - array of token amounts (must be sorted in the same order as addresses)
    // @param: maximumBPT - maximum amount of BPTs to be withdrawn
    // @returns: maxBPT - the maximum amount of BPTs to be withdrawn
    // @returns: amountsOut - the amounts of tokens received for maxBPT
    function queryBalancerExit(address[2] memory tokens, uint256[2] memory amounts, uint256 maximumBPT) internal returns (uint256 maxBPT, uint256[] memory amountsOut) {
        // Instantiate balancer request struct using SWIV and ETH alongside the amounts sent
        IAsset[] memory assetData = new IAsset[](2);
        assetData[0] = IAsset(address(tokens[0]));
        assetData[1] = IAsset(address(tokens[1]));

        uint256[] memory amountData = new uint256[](2);
        // If the maximumBPT is max, query the balancer pool for the maximum amount of BPTs received for the given amounts of tokens
        if (maximumBPT == type(uint256).max) {
            amountData[0] = amounts[0];
            amountData[1] = amounts[1];
            IVault.ExitPoolRequest memory requestData = IVault.ExitPoolRequest({
                assets: assetData,
                minAmountsOut: amountData,
                userData: abi.encode(2, amountData, maximumBPT),
                toInternalBalance: false
            });
            (maxBPT, amountsOut) = balancerQuery.queryExit(balancerPoolID, msg.sender, address(this), requestData);
            return (maxBPT, amountsOut);
        }
        // Else query the balancer pool for the minimum amount of tokens received for the given maximumBPT
        else {
            amountData[0] = amounts[0];
            amountData[1] = amounts[1];
            IVault.ExitPoolRequest memory requestData = IVault.ExitPoolRequest({
                assets: assetData,
                minAmountsOut: amountData,
                userData: abi.encode(1, maximumBPT),
                toInternalBalance: false
            });
            (maxBPT, amountsOut) = balancerQuery.queryExit(balancerPoolID, msg.sender, address(this), requestData);
            return (maxBPT, amountsOut);
        }
    }

    // Joins the balancer pool with the given tokens and amounts, minting at least minimumBPT (if relevant to the kind of join)
    // @notice: Only covers weighted pools
    // @param: kind - the kind of join (1 = exactTokensIn, 3 = exactBPTOut)
    // @param: tokens - array of token addresses
    // @param: amounts - array of token amounts (must be sorted in the same order as addresses)
    // @param: minimumBPT - minimum amount of BPTs to be minted
    function balancerJoin(uint8 kind, address[2] memory tokens, uint256[2] memory amounts, uint256 minimumBPT) internal {
        // Instantiate balancer request struct using SWIV and ETH alongside the amounts sent
        IAsset[] memory assetData = new IAsset[](2);
        assetData[0] = IAsset(address(tokens[0]));
        assetData[1] = IAsset(address(tokens[1]));

        uint256[] memory amountData = new uint256[](2);
        amountData[0] = amounts[0];
        amountData[1] = amounts[1];
        
        if (kind == 1) {
            IVault.JoinPoolRequest memory requestData = IVault.JoinPoolRequest({
                assets: assetData,
                maxAmountsIn: amountData,
                userData: abi.encode(1, amountData, minimumBPT),
                fromInternalBalance: false
            });
            IVault(balancerVault).joinPool(balancerPoolID, address(this), address(this), requestData);
        }
        else if (kind == 3) {
            IVault.JoinPoolRequest memory requestData = IVault.JoinPoolRequest({
                assets: assetData,
                maxAmountsIn: amountData,
                userData: abi.encode(3, minimumBPT),
                fromInternalBalance: false
            });
            IVault(balancerVault).joinPool(balancerPoolID, address(this), address(this), requestData);
        }
    }

    // Exits the balancer pool with the given tokens and amounts, burning at most maximumBPT (if relevant to the kind of exit)
    // @notice: Only covers weighted pools
    // @param: kind - the kind of exit (1 = exactBPTIn, 2 = exactTokensOut)
    // @param: tokens - array of token addresses
    // @param: amounts - array of token amounts (must be sorted in the same order as addresses)
    // @param: maximumBPT - maximum amount of BPTs to be burnt
    function balancerExit(uint8 kind, address[2] memory tokens, uint256[2] memory amounts, uint256 maximumBPT) internal {
        // Instantiate balancer request struct using SWIV and ETH alongside the amounts sent
        IAsset[] memory assetData = new IAsset[](2);
        assetData[0] = IAsset(address(tokens[0]));
        assetData[1] = IAsset(address(tokens[1]));

        uint256[] memory amountData = new uint256[](2);
        amountData[0] = amounts[0];
        amountData[1] = amounts[1];
        
        if (kind == 1) {
            IVault.ExitPoolRequest memory requestData = IVault.ExitPoolRequest({
                assets: assetData,
                minAmountsOut: amountData,
                userData: abi.encode(1, maximumBPT),
                toInternalBalance: false
            });
            IVault(balancerVault).exitPool(balancerPoolID, payable(address(this)), payable(address(this)), requestData);
        }
        else if (kind == 2) {
            IVault.ExitPoolRequest memory requestData = IVault.ExitPoolRequest({
                assets: assetData,
                minAmountsOut: amountData,
                userData: abi.encode(2, amountData, maximumBPT),
                toInternalBalance: false
            });
            IVault(balancerVault).exitPool(balancerPoolID, payable(address(this)), payable(address(this)), requestData);
        }
    }

    //////////////////// FEE DONATION ////////////////////

    // Method to donate a BPT amount to the SSM
    // @param: amount - amount of BPT to donate
    // @returns: the amount of BPT donated
    function donate(uint256 amount) public {
        // Transfer the BPT to the SSM
        SafeTransferLib.transferFrom(balancerLPT, msg.sender, address(this), amount);
        // Emit donation event
        emit Donation(amount, msg.sender);
    }

    //////////////////// ADMIN FUNCTIONS ////////////////////

    // Method to redeem and withdraw BAL incentives or other stuck tokens / those needing recovery
    // @param: token - address of the token to withdraw
    // @param: receiver - address of the receiver
    // @returns: the amount of tokens withdrawn
    function adminWithdraw(address token, address payable receiver) Authorized(admin) public returns (uint256) {
        if (token == address(0)) {
            receiver.transfer(address(this).balance);
            return (address(this).balance);
        }
        else {
            // If the token is balancerBPT, transfer 30% of the held balancerBPT to receiver
            if (token == address(balancerLPT)) {
                // Require a week between bpt withdrawals
                require(block.timestamp >= lastWithdrawnBPT + 1 weeks, "Admin already withdrawn recently");
                // Calculate max balance that can be withdrawn
                uint256 bptToTransfer = balancerLPT.balanceOf(address(this)) / 3;
                // Transfer the balancer LP tokens to the receiver
                SafeTransferLib.transfer(balancerLPT, receiver, bptToTransfer);
                // Reset the last withdrawn timestamp
                lastWithdrawnBPT = block.timestamp;
                return (bptToTransfer);
            }
            else {
                // Get the balance of the token
                uint256 balance = IERC20(token).balanceOf(address(this));
                // Transfer the token to the receiver
                SafeTransferLib.transfer(ERC20(token), receiver, balance);
                return (balance);
            }
        }
    }

    // Method to queue the withdrawal of tokens in the event of an emergency
    // @param: token - address of the token to withdraw
    // @returns: the timestamp of the withdrawal
    function queueWithdrawal(address token) Authorized(admin) public returns (uint256 timestamp){
        timestamp = block.timestamp + 1 weeks;
        withdrawalTime[token] = timestamp;
        emit WithdrawalQueued(token, timestamp);
        return (timestamp);
    }

    // Method to withdraw tokens in the event of an emergency
    // @param: token - address of the token to withdraw
    // @param: receiver - address of the receiver
    // @returns: the amount of tokens withdrawn
    function emergencyWithdraw(address token, address payable receiver) Authorized(admin) public returns (uint256 amount) {
        // Require the current block.timestamp to be after the emergencyWithdrawal timestamp but before the emergencyWithdrawal timestamp + 1 week
        if (block.timestamp < withdrawalTime[token] || block.timestamp > withdrawalTime[token] + 1 weeks) {
            revert Exception(6, block.timestamp, withdrawalTime[token], address(0), address(0));
        }
        if (token == address(0)) {
            amount = address(this).balance;
            receiver.transfer(amount);
            return (amount);
        }
        else {
            // Get the balance of the token
            uint256 balance = IERC20(token).balanceOf(address(this));
            // Transfer the token to the receiver
            SafeTransferLib.transfer(ERC20(token), receiver, balance);
            return (balance);
        }
    }

    // Method to redeem BAL incentives from a given balancer gauge
    // @param: receiver - address of the receiver
    // @param: gauge - address of the balancer gauge
    // @returns: the amount of BAL withdrawn
    function adminWithdrawBAL(address balancerMinter, address gauge, address receiver) Authorized(admin) public returns (uint256) {
        // Mint BAL accrued on a given gauge
        uint256 amount = IBalancerMinter(balancerMinter).mint(gauge);
        // Transfer the tokens to the receiver
        SafeTransferLib.transfer(balancerToken, receiver, amount);
        return (amount);
    }

    // Sets a new admin address
    // @param: _admin - address of the new admin
    function setAdmin(address _admin) Authorized(admin) public {
        admin = _admin;
    }

    // Pauses all withdrawing
    function pause(bool b) Authorized(admin) public {
        paused = b;
    }

    // Authorized modifier
    modifier Authorized(address) {
        require(msg.sender == admin || msg.sender == address(this), "Not authorized");
        _;
    }

    // Unpaused modifier
    modifier Unpaused() {
        require(!paused, "Paused");
        _;
    }
}