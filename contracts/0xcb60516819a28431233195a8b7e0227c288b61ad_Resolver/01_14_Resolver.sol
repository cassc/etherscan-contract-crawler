// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "OpenZeppelin/[email protected]/contracts/access/Ownable.sol";
import "../interfaces/IMessenger.sol";
import "./RequestManager.sol";
import "./RestrictedCalls.sol";

/// The resolver.
///
/// This contract resides on the L1 chain and is tasked with receiving the
/// fill or non-fill proofs from the target L2 chain and forwarding them to
/// the :sol:contract:`RequestManager` on the source L2 chain.
contract Resolver is Ownable, RestrictedCalls {
    struct SourceChainInfo {
        address requestManager;
        address messenger;
    }

    /// Emitted when a fill or a non-fill proof is received and sent to the request manager.
    ///
    /// .. note:: In case of a non-fill proof, the ``filler`` will be zero.
    event Resolution(
        uint256 sourceChainId,
        uint256 fillChainId,
        bytes32 requestId,
        address filler,
        bytes32 fillId
    );

    /// Maps source chain IDs to source chain infos.
    mapping(uint256 sourceChainId => SourceChainInfo) public sourceChainInfos;

    /// Resolve the specified request.
    ///
    /// This marks the request identified by ``requestId`` as filled by ``filler``.
    /// If the ``filler`` is zero, the fill will be marked invalid.
    ///
    /// Information about the fill will be sent to the source chain's :sol:contract:`RequestManager`,
    /// using the messenger responsible for the source chain.
    ///
    /// .. note::
    ///
    ///     This function is callable only by the native L1 messenger contract,
    ///     which simply delivers the message sent from the target chain by the
    ///     Beamer's L2 :sol:interface:`messenger <IMessenger>` contract.
    ///
    /// @param requestId The request ID.
    /// @param fillId The fill ID.
    /// @param fillChainId The fill (target) chain ID.
    /// @param sourceChainId The source chain ID.
    /// @param filler The address that filled the request, or zero to invalidate the fill.
    function resolve(
        bytes32 requestId,
        bytes32 fillId,
        uint256 fillChainId,
        uint256 sourceChainId,
        address filler
    ) external restricted(fillChainId) {
        SourceChainInfo memory info = sourceChainInfos[sourceChainId];
        require(
            info.requestManager != address(0),
            "No request manager available for source chain"
        );
        require(
            info.messenger != address(0),
            "No messenger available for source chain"
        );

        bytes memory message;

        if (filler == address(0)) {
            message = abi.encodeCall(
                RequestManager.invalidateFill,
                (requestId, fillId, block.chainid)
            );
        } else {
            message = abi.encodeCall(
                RequestManager.resolveRequest,
                (requestId, fillId, block.chainid, filler)
            );
        }

        IMessenger messenger = IMessenger(info.messenger);
        messenger.sendMessage(info.requestManager, message);

        emit Resolution(sourceChainId, fillChainId, requestId, filler, fillId);
    }

    /// Add a request manager.
    ///
    /// In order to be able to send messages to the :sol:contract:`RequestManager`,
    /// the resolver contract needs to know the address of the request manager on the source
    /// chain, as well as the address of the messenger contract responsible for
    /// transferring messages to the L2 chain.
    ///
    /// .. note:: This function can only be called by the contract owner.
    ///
    /// @param chainId The source L2 chain ID.
    /// @param requestManager The request manager.
    /// @param messenger The messenger contract responsible for chain ``chainId``.
    ///                  Must implement :sol:interface:`IMessenger`.
    function addRequestManager(
        uint256 chainId,
        address requestManager,
        address messenger
    ) external onlyOwner {
        sourceChainInfos[chainId] = SourceChainInfo(requestManager, messenger);
    }
}