// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IGnosisSafe} from "./interfaces/IGnosisSafe.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {GelatoRelayContext} from "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";

/// @title Signless Safe Module
/// @author kevincharm
/// @notice Delegated child-key registry module for Gnosis Safe
contract SignlessSafeModule is EIP712, GelatoRelayContext {
    struct DelegatedSigner {
        /// @notice Timestamp of when this delegate was created
        /// @dev 8B
        uint64 createdAt;
        /// @notice Timestamp of when this delegate is no longer valid
        /// @dev 8B
        uint64 expiry;
    }

    event DelegateRegistered(
        address indexed safe,
        address delegate,
        uint64 expiry
    );
    event DelegateRevoked(address indexed safe, address delegate);

    /// @notice EIP-712 typehash
    bytes32 public constant EIP712_EXEC_SAFE_TX_TYPEHASH =
        keccak256(
            "ExecSafeTx(address safe,address to,uint256 value,bytes32 dataHash,uint256 nonce)"
        );

    /// @notice Nonce per user, for EIP-712 messages
    mapping(address => uint256) private userNonces;

    /// @notice Linked-list of delegates per safe
    ///     safe => delegates[]
    /// @dev We probably don't need this in prod; can be made redundant if we
    ///     index DelegateRegistered events.
    mapping(address => address[]) private delegatesList;

    /// @notice Information about delegated signers per safe
    ///     safe => delegate => info
    mapping(address => mapping(address => DelegatedSigner))
        private delegatesInfo;

    constructor() EIP712("SignlessSafeModule", "1.0.0") {}

    /// @notice Get the current nonce for `user` (for EIP-712 messages)
    /// @param user User to get current nonce for
    /// @return nonce
    function getNonce(address user) external view returns (uint256) {
        return userNonces[user];
    }

    /// @notice Get info of registered delegate
    /// @param safe Gnosis Safe
    /// @param delegate Registered delegate to get info of
    function getDelegateInfo(
        address safe,
        address delegate
    ) external view returns (uint64 createdAt, uint64 expiry) {
        DelegatedSigner memory signer = delegatesInfo[safe][delegate];
        return (signer.createdAt, signer.expiry);
    }

    /// @notice Returns true if the `delegatee` pubkey is registered as a
    ///     delegated signer for `safe`
    /// @param safe The Gnosis Safe
    /// @param delegate The (truncated) ECDSA public key that has been
    ///     registered as a delegate for `safe`
    /// @return truth or dare
    function isValidDelegate(
        address safe,
        address delegate
    ) external view returns (bool) {
        DelegatedSigner memory delegateSigner = delegatesInfo[safe][delegate];
        return block.timestamp < delegateSigner.expiry;
    }

    /// @notice Get count of delegated signers for a safe
    /// @param safe The Gnosis Safe
    function getDelegateSignersCount(
        address safe
    ) external view returns (uint256) {
        return delegatesList[safe].length;
    }

    /// @notice Get a paginated list of delegated signers
    /// @param safe The Gnosis Safe
    /// @param offset Offset in the list to start fetching from
    /// @param maxPageSize Maximum number of signers to fetch
    function getDelegateSignersPaginated(
        address safe,
        uint256 offset,
        uint256 maxPageSize
    ) external view returns (address[] memory signers) {
        uint256 len = delegatesList[safe].length;
        if (offset >= len) return new address[](0);

        uint256 pageSize = offset + maxPageSize > len
            ? len - offset
            : maxPageSize;
        signers = new address[](pageSize);
        for (uint256 i = 0; i < pageSize; ++i)
            signers[i] = delegatesList[safe][offset + i];
    }

    /// @notice Register a delegate public key of which the safe has
    ///     control. Must be called by the Gnosis Safe.
    /// @param delegate Truncated ECDSA public key that the delegator wishes
    ///     to delegate to.
    /// @param expiry When the delegation becomes invalid, as UNIX timestamp
    function registerDelegateSigner(address delegate, uint64 expiry) external {
        require(delegate != address(0), "Invalid delegate address");

        // NB: registered delegates are isolated to each safe
        address safe = msg.sender;
        require(
            delegatesInfo[safe][delegate].createdAt == 0,
            "Delegate already registered"
        );
        // Insert delegate into list for Safe
        delegatesList[safe].push(delegate);
        // Record delegate information
        delegatesInfo[safe][delegate] = DelegatedSigner({
            createdAt: uint64(block.timestamp),
            expiry: expiry
        });

        emit DelegateRegistered(safe, delegate, expiry);
    }

    /// @notice Revoke a delegate public key
    /// @param delegateIndex Index of the delegate to revoke
    function revokeDelegateSigner(uint256 delegateIndex) external {
        // NB: Only safe txes may revoke delegate signers
        address safe = msg.sender;
        require(
            delegateIndex < delegatesList[safe].length,
            "Delegate index out-of-bounds"
        );

        // Pop it off the list
        uint256 lastIndex = delegatesList[safe].length - 1;
        address delegate = delegatesList[safe][delegateIndex];
        delegatesList[safe][delegateIndex] = delegatesList[safe][lastIndex];
        delegatesList[safe].pop();
        // Clear delegate info
        delegatesInfo[safe][delegate] = DelegatedSigner({
            createdAt: 0,
            expiry: 0
        });

        emit DelegateRevoked(safe, delegate);
    }

    /// @notice Execute a transaction on the Gnosis Safe using this module
    /// @param delegate Delegate key that is signing the transaction
    /// @param safe The Gnosis Safe that this transaction is being executed
    ///     through
    /// @param to Tx target
    /// @param value Tx value
    /// @param data Tx calldata
    /// @param sig EIP-712 signature over `EIP712_EXEC_SAFE_TX_TYPEHASH`,
    ///     signed by `delegate`
    function exec(
        address delegate,
        address safe,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata sig
    ) public {
        // Check that the delegatooor for this delegate is an owner of the safe
        DelegatedSigner memory delegateSigner = delegatesInfo[safe][delegate];
        require(
            block.timestamp < delegateSigner.expiry,
            "Delegate key expired"
        );

        uint256 nonce = userNonces[delegate]++;
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    EIP712_EXEC_SAFE_TX_TYPEHASH,
                    safe,
                    to,
                    value,
                    keccak256(data),
                    nonce
                )
            )
        );
        require(
            ECDSA.recover(digest, sig) == delegate,
            "Invalid signature for delegate"
        );

        require(
            IGnosisSafe(safe).execTransactionFromModule(
                to,
                value,
                data,
                IGnosisSafe.Operation.Call
            ),
            "Transaction reverted"
        );
    }

    /// @notice Invoke {exec}, via Gelato relay
    /// @notice maxFee Maximum fee payable to Gelato relayer
    function execViaRelay(
        uint256 maxFee,
        address delegate,
        address safe,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata sig
    ) external onlyGelatoRelay {
        uint256 fee = _getFee();
        require(fee <= maxFee, "Relay fee exceeds maxFee");
        require(
            _getFeeToken() == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            "Only ETH payment supported"
        );
        require(
            IGnosisSafe(safe).execTransactionFromModule(
                _getFeeCollector(),
                fee,
                bytes(""),
                IGnosisSafe.Operation.Call
            ),
            "Fee payment failed"
        );

        // Execute transaction
        exec(delegate, safe, to, value, data, sig);
    }
}