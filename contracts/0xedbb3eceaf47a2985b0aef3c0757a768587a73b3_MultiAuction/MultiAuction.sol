/**
 *Submitted for verification at Etherscan.io on 2023-07-10
*/

// File: .deps/MultiAuction 6/libs/SafeTransferLib.sol


pragma solidity >=0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
///
/// @dev Note:
/// - For ETH transfers, please use `forceSafeTransferETH` for gas griefing protection.
/// - For ERC20s, this implementation won't check that a token has code,
/// responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    ///
    /// Note: This implementation does NOT protect against gas griefing.
    /// Please use `forceSafeTransferETH` for gas griefing protection.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // To coerce gas estimation to provide enough gas for the `create` above.
                    if iszero(gt(gas(), 1000000)) { revert(0, 0) }
                }
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overridden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // To coerce gas estimation to provide enough gas for the `create` above.
                    if iszero(gt(gas(), 1000000)) { revert(0, 0) }
                }
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x0c, 0x23b872dd000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x0c, 0x70a08231000000000000000000000000)
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            // The `amount` argument is already written to the memory word at 0x60.
            amount := mload(0x60)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x14, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x34.
            amount := mload(0x34)
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`.
            mstore(0x00, 0x095ea7b3000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x00, 0x70a08231000000000000000000000000)
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}
// File: .deps/MultiAuction 6/libs/MerkleProofLib.sol


pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
    }
}
// File: .deps/MultiAuction 6/interfaces/IDelegationRegistry.sol


pragma solidity ^0.8.17;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    /// @notice Info about a single contract-level delegation
    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(address vault, address delegate, address contract_, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Allow the delegate to act on your behalf for all contracts
     * @param delegate The hotwallet to act on your behalf
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForAll(address delegate, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific contract
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForContract(address delegate, address contract_, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForContract(address vault, address contract_) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of ContractDelegation structs
     */
    function getContractLevelDelegations(address vault)
        external
        view
        returns (ContractDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(address vault) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        external
        view
        returns (bool);
}
// File: .deps/MultiAuction 6/MultiAuction.sol



pragma solidity ^0.8.17;




contract MultiAuction {
  uint256 private constant BPS = 10_000;
  address private constant DELEGATION_REGISTRY = 0x00000000000076A84feF008CDAbe6409d2FE638B;
  address private constant FPP = 0xA8A425864dB32fCBB459Bf527BdBb8128e6abF21;
  uint256 private constant FPP_PROJECT_ID = 3;
  uint256 private constant MIN_BID = 0.01 ether;
  uint256 private constant MIN_BID_INCREASE = 1_000;
  uint256 private constant MINT_PASS_REBATE = 1_500;
  uint256 private constant SAFE_GAS_LIMIT = 30_000;
  IBaseContract public immutable BASE_CONTRACT;
  uint256 public immutable MAX_SUPPLY;


  uint256 public auctionStartTime;
  address public beneficiary1;
  address public beneficiary2;
  bool public paused;
  bytes32 public settlementRoot;

  struct Auction {
    uint24 offsetFromEnd;
    uint72 amount;
    address bidder;
  }

  mapping(uint256 => Auction) public tokenIdToAuction;

  event BidMade(uint256 indexed tokenId, address bidder, uint256 amount, uint256 timestamp);
  event Settled(uint256 indexed tokenId, uint256 timestamp);

  constructor(
    address baseContract,
    uint256 startTime,
    uint256 maxSupply
  ) {
    BASE_CONTRACT = IBaseContract(baseContract);
    auctionStartTime = startTime;
    MAX_SUPPLY = maxSupply;
    beneficiary1 = msg.sender;
    beneficiary2 = msg.sender;
  }

  function bid(
    uint256 tokenId
  ) external payable {
    require(!paused, 'Bidding is paused');
    require(isAuctionActive(tokenId), 'Auction Inactive');
    require(0 < tokenId && tokenId <= MAX_SUPPLY, 'Invalid tokenId');

    Auction memory highestBid = tokenIdToAuction[tokenId];

    require(
      msg.value >= (highestBid.amount * (BPS + MIN_BID_INCREASE) / BPS)
      && msg.value >= MIN_BID,
      'Bid not high enough'
    );

    uint256 refundAmount;
    address refundBidder;
    uint256 offset = highestBid.offsetFromEnd;
    uint256 endTime = auctionEndTime(tokenId);

    if (highestBid.amount > 0) {
      refundAmount = highestBid.amount;
      refundBidder = highestBid.bidder;
    }

    if (endTime - block.timestamp < 15 minutes) {
      offset += block.timestamp + 15 minutes - endTime;
    }

    tokenIdToAuction[tokenId] = Auction(uint24(offset), uint72(msg.value), msg.sender);

    emit BidMade(tokenId, msg.sender, msg.value, block.timestamp);

    if (refundAmount > 0) {
      SafeTransferLib.forceSafeTransferETH(refundBidder, refundAmount, SAFE_GAS_LIMIT);
    }
  }

  function bidOnFavs(
    uint256[] calldata favorites,
    uint256[] calldata expectedPrices
  ) external payable {
    require(!paused, 'Bidding is paused');
    require(favorites.length == expectedPrices.length);

    uint256 totalFailed; uint256 expectedTotal;
    for(uint256 i; i < favorites.length; ++i) {
      uint256 tokenId = favorites[i];
      uint256 expectedPrice = expectedPrices[i];
      expectedTotal += expectedPrice;
      require(0 < tokenId && tokenId <= MAX_SUPPLY, 'Invalid tokenId');
      if(!isAuctionActive(tokenId)) {
        totalFailed += expectedPrice;
        break;
      }

      Auction memory highestBid = tokenIdToAuction[tokenId];
      if (
        expectedPrice >= (highestBid.amount * (BPS + MIN_BID_INCREASE) / BPS)
        && expectedPrice >= MIN_BID
      ) {
        uint256 refundAmount;
        address refundBidder;
        uint256 offset = highestBid.offsetFromEnd;
        uint256 endTime = auctionEndTime(tokenId);

        if (highestBid.amount > 0) {
          refundAmount = highestBid.amount;
          refundBidder = highestBid.bidder;
        }

        if (endTime - block.timestamp < 15 minutes) {
          offset += block.timestamp + 15 minutes - endTime;
        }

        tokenIdToAuction[tokenId] = Auction(uint24(offset), uint72(expectedPrice), msg.sender);

        emit BidMade(tokenId, msg.sender, expectedPrice, block.timestamp);

        if (refundAmount > 0) {
          SafeTransferLib.forceSafeTransferETH(refundBidder, refundAmount, SAFE_GAS_LIMIT);
        }
      } else{
        totalFailed += expectedPrice;
      }
    }

    require(msg.value >= expectedTotal);
    if (totalFailed > 0) {
      SafeTransferLib.forceSafeTransferETH(msg.sender, totalFailed, SAFE_GAS_LIMIT);
    }
  }

  function settleAuction(
    uint256 tokenId,
    uint256 mintPassId,
    bytes32[] calldata proof
  ) external payable {
    require(settlementRoot != bytes32(0));
    Auction memory highestBid = tokenIdToAuction[tokenId];
    require(highestBid.bidder == msg.sender || owner() == msg.sender);
    require(0 < tokenId && tokenId <= MAX_SUPPLY, 'Invalid tokenId');
    require(isAuctionOver(tokenId), 'Auction for this tokenId is still active');

    uint256 amountToPay = highestBid.amount;
    if (amountToPay > 0) {
      BASE_CONTRACT.mint(highestBid.bidder, tokenId);
    } else {
      require(msg.sender == owner(), 'Ownable: caller is not the owner');
      require(msg.value >= MIN_BID, 'Bid not high enough');
      amountToPay = msg.value;

      BASE_CONTRACT.mint(msg.sender, tokenId);
    }

    uint256 totalRebate = 0;
    bool mintPassValid;
    if (mintPassId < 1_000) {
      address passHolder = IFPP(FPP).ownerOf(mintPassId);
      mintPassValid = mintPassId < 1_000 && IFPP(FPP).passUses(mintPassId, FPP_PROJECT_ID) < 1 && (
        passHolder == highestBid.bidder ||
        IDelegationRegistry(DELEGATION_REGISTRY).checkDelegateForToken(
          highestBid.bidder,
          passHolder,
          FPP,
          mintPassId
        )
      ) && (
        MerkleProofLib.verify(proof, settlementRoot, keccak256(abi.encodePacked(passHolder, mintPassId)))
      );
    }

    if (mintPassValid) {
      IFPP(FPP).logPassUse(mintPassId, FPP_PROJECT_ID);
      totalRebate = amountToPay * (MINT_PASS_REBATE) / BPS;
    }

    tokenIdToAuction[tokenId].bidder = address(0);
    emit Settled(tokenId, block.timestamp);

    if (totalRebate > 0) {
      SafeTransferLib.forceSafeTransferETH(highestBid.bidder, totalRebate, SAFE_GAS_LIMIT);
      SafeTransferLib.forceSafeTransferETH(beneficiary2, amountToPay - totalRebate, SAFE_GAS_LIMIT);
    } else {
      SafeTransferLib.forceSafeTransferETH(beneficiary1, amountToPay, SAFE_GAS_LIMIT);
    }
  }

  function settleAll(
    uint256 startId,
    uint256 endId,
    bytes calldata passData
  ) external payable onlyOwner {
    require(settlementRoot == bytes32(0), 'settleAll not active');
    require(passData.length == 2 * (endId - startId + 1), 'Invalid passData length');
    require(0 < startId && endId <= MAX_SUPPLY, 'Invalid tokenId');

    uint256 unclaimedCost; uint256 amountForBene1; uint256 amountForBene2;
    for (uint256 tokenId = startId; tokenId <= endId; ++tokenId) {
      Auction memory highestBid = tokenIdToAuction[tokenId];
      require(isAuctionOver(tokenId), 'Auction for this tokenId is still active');

      uint256 amountToPay = highestBid.amount;
      if (amountToPay > 0) {
        BASE_CONTRACT.mint(highestBid.bidder, tokenId);
      } else {
        amountToPay = MIN_BID;
        unclaimedCost += MIN_BID;
        BASE_CONTRACT.mint(msg.sender, tokenId);
      }

      uint256 totalRebate = 0;
      uint256 mintPassId = uint16(bytes2(passData[(tokenId - 1) * 2: tokenId * 2]));
      bool mintPassValid;
      if (mintPassId < 1_000) {
        address passHolder = IFPP(FPP).ownerOf(mintPassId);
        mintPassValid = mintPassId < 1_000 && IFPP(FPP).passUses(mintPassId, FPP_PROJECT_ID) < 1 && (
          passHolder == highestBid.bidder ||
          IDelegationRegistry(DELEGATION_REGISTRY).checkDelegateForToken(
            highestBid.bidder,
            passHolder,
            FPP,
            mintPassId
          )
        );
      }
  
      if (mintPassValid) {
        IFPP(FPP).logPassUse(mintPassId, FPP_PROJECT_ID);
        totalRebate = amountToPay * (MINT_PASS_REBATE) / BPS;
      }
  
      tokenIdToAuction[tokenId].bidder = address(0);
      emit Settled(tokenId, block.timestamp);
  
      if (totalRebate > 0) {
        SafeTransferLib.forceSafeTransferETH(highestBid.bidder, totalRebate, SAFE_GAS_LIMIT);
        amountForBene2 += amountToPay - totalRebate;
      } else {
        amountForBene1 += amountToPay;
      }
    }

    require(msg.value >= unclaimedCost, "Insufficient funds sent for unclaimed");
    SafeTransferLib.forceSafeTransferETH(beneficiary1, amountForBene1, SAFE_GAS_LIMIT);
    SafeTransferLib.forceSafeTransferETH(beneficiary2, amountForBene2, SAFE_GAS_LIMIT);
  }

  function owner() public view returns (address) {
    return BASE_CONTRACT.owner();
  }

  modifier onlyOwner {
    require(msg.sender == owner(), 'Ownable: caller is not the owner');
    _;
  }

  function emergencyWithdraw() external onlyOwner {
    require(block.timestamp > auctionStartTime + 48 hours);
    (bool success,) = msg.sender.call{value: address(this).balance}("");
    require(success);
  }

  function enableSelfSettlement(
    bytes32 root
  ) external onlyOwner {
    settlementRoot = root;
  }

  function rescheduele(
    uint256 newStartTime
  ) external onlyOwner {
    require(auctionStartTime > block.timestamp);
    auctionStartTime = newStartTime;
  }

  function setBeneficiary(
    address _beneficiary1,
    address _beneficiary2
  ) external onlyOwner {
    beneficiary1 = _beneficiary1;
    beneficiary2 = _beneficiary2;
  }

  function setPaused(
    bool _paused
  ) external onlyOwner {
    paused = _paused;
  }

  function auctionEndTime(
    uint256 tokenId
  ) public view returns (uint256) {
    return auctionStartTime + 24 hours + tokenIdToAuction[tokenId].offsetFromEnd;
  }

  function isAuctionActive(
    uint256 tokenId
  ) public view returns (bool) {
    uint256 endTime = auctionEndTime(tokenId);
    return (block.timestamp >= auctionStartTime && block.timestamp < endTime);
  }

  function isAuctionOver(
    uint256 tokenId
  ) public view returns (bool) {
    uint256 endTime = auctionEndTime(tokenId);
    return (block.timestamp >= endTime);
  }
}

interface IFPP {
  function logPassUse(uint256 tokenId, uint256 projectId) external;
  function ownerOf(uint256 tokenId) external returns (address);
  function passUses(uint256 tokenId, uint256 projectId) external returns (uint256);
}

interface IBaseContract {
  function mint(address to, uint256 tokenId) external;
  function owner() external view returns (address);
}