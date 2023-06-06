// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/[email protected]/contracts/token/ERC20/utils/SafeERC20.sol";
import "OpenZeppelin/[email protected]/contracts/access/Ownable.sol";
import "./LpWhitelist.sol";
import "../interfaces/IMessenger.sol";
import "./BeamerUtils.sol";
import "./Resolver.sol";

/// The fill manager.
///
/// This contract is responsible for keeping track of filled requests. In addition to allowing
/// agents to (eventually) prove that they filled requests, it also allows anyone to invalidate
/// a claim that a request was filled.
///
/// It is the only contract that agents need to interact with on the target chain.
contract FillManager is Ownable, LpWhitelist {
    using SafeERC20 for IERC20;

    /// Emitted when a request has been filled.
    ///
    /// .. seealso:: :sol:func:`fillRequest`
    event RequestFilled(
        bytes32 indexed requestId,
        bytes32 fillId,
        uint256 indexed sourceChainId,
        address indexed targetTokenAddress,
        address filler,
        uint256 amount
    );

    /// Emitted when a fill has been invalidated.
    ///
    /// .. seealso:: :sol:func:`invalidateFill`
    event FillInvalidated(bytes32 indexed requestId, bytes32 indexed fillId);

    // The messenger to send messages to L1
    //
    // It is used to send proofs to L1. The specific implementation of the
    // :sol:interface:`IMessenger` interface is chain-dependent.
    IMessenger public immutable messenger;

    /// The L1 :sol:contract:`Resolver` contract to be used for L1 resolution.
    address public l1Resolver;

    /// Maps request IDs to fill IDs.
    mapping(bytes32 requestID => bytes32 fillId) public fills;

    /// Constructor.
    ///
    /// @param _messenger The messenger.
    constructor(address _messenger) {
        messenger = IMessenger(_messenger);
    }

    /// Set the resolver's address
    ///
    /// Can only ever be set once. Before it is set, no fills or invalidations are possible
    ///
    /// @param _l1Resolver The L1 resolver address
    function setResolver(address _l1Resolver) public onlyOwner {
        require(l1Resolver == address(0), "Resolver already set");
        l1Resolver = _l1Resolver;
    }

    /// Fill the specified request.
    ///
    /// The caller must have approved at least ``amount`` tokens for :sol:contract:`FillManager`
    /// with the ERC20 token contract at ``targetTokenAddress``. The tokens will be immediately
    /// sent to ``targetReceiverAddress`` and a fill proof will be generated, which can later
    /// be used to trigger L1 resolution, if needed.
    ///
    /// @param sourceChainId The source chain ID.
    /// @param targetTokenAddress Address of the token contract on the target chain.
    /// @param targetReceiverAddress Recipient address on the target chain.
    /// @param amount Amount of tokens to transfer. Does not include fees.
    /// @param nonce The nonce used to create the request ID.
    /// @return The fill ID.
    function fillRequest(
        uint256 sourceChainId,
        address targetTokenAddress,
        address targetReceiverAddress,
        uint256 amount,
        uint96 nonce
    ) external onlyAllowed(msg.sender) returns (bytes32) {
        address _l1Resolver = l1Resolver;
        require(_l1Resolver != address(0), "Resolver address not set");
        bytes32 requestId = BeamerUtils.createRequestId(
            sourceChainId,
            block.chainid,
            targetTokenAddress,
            targetReceiverAddress,
            amount,
            nonce
        );

        require(fills[requestId] == bytes32(0), "Already filled");

        IERC20(targetTokenAddress).safeTransferFrom(
            msg.sender,
            targetReceiverAddress,
            amount
        );

        bytes32 fillId = generateFillId();
        fills[requestId] = fillId;

        messenger.sendMessage(
            _l1Resolver,
            abi.encodeCall(
                Resolver.resolve,
                (requestId, fillId, block.chainid, sourceChainId, msg.sender)
            )
        );

        emit RequestFilled(
            requestId,
            fillId,
            sourceChainId,
            targetTokenAddress,
            msg.sender,
            amount
        );

        return fillId;
    }

    /// Invalidate the specified fill.
    ///
    /// In cases that a claim has been made on the source chain, but without a corresponding fill
    /// actually happening on the target chain, anyone can call this function to mark the fill
    /// as invalid. This is typically followed by a challenge game on the source chain, which
    /// the dishonest claimer is guaranteed to lose as soon as the information about the invalid
    /// fill (so called "non-fill proof") is propagated to the source chain via L1 resolution.
    ///
    /// @param requestId The request ID.
    /// @param fillId The fill ID.
    /// @param sourceChainId The source chain ID.
    function invalidateFill(
        bytes32 requestId,
        bytes32 fillId,
        uint256 sourceChainId
    ) external {
        address _l1Resolver = l1Resolver;
        require(_l1Resolver != address(0), "Resolver address not set");
        require(fills[requestId] != fillId, "Fill valid");
        require(
            fillId != generateFillId(),
            "Cannot invalidate fills of current block"
        );

        messenger.sendMessage(
            _l1Resolver,
            abi.encodeCall(
                Resolver.resolve,
                (requestId, fillId, block.chainid, sourceChainId, address(0))
            )
        );
        emit FillInvalidated(requestId, fillId);
    }

    /// Generate a fill ID.
    ///
    /// The fill ID is defined as the previous block hash.
    ///
    /// @return The current fill ID
    function generateFillId() private view returns (bytes32) {
        return blockhash(block.number - 1);
    }
}