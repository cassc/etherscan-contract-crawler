// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./HandlerHelpers.sol";
import "../interfaces/IExecuteProposal.sol";
import "../interfaces/IGetRollupInfo.sol";
import "../../utils/rollup/RollupTypes.sol";

contract RollupHandler is IGetRollupInfo, IExecuteProposal, HandlerHelpers {
    constructor(address bridgeAddress) HandlerHelpers(bridgeAddress) {}

    mapping(uint72 => Metadata) public rollupMetadata;

    struct Metadata {
        uint8 domainID;
        bytes32 resourceID;
        uint64 nonce;
        bytes32 rootHash;
        uint64 totalBatches;
    }

    /// @notice Proposal execution should be initiated when a proposal is finalized in the Bridge contract.
    ///
    /// @notice Requirements:
    /// - It must be called by only bridge.
    /// - {resourceID} must exist.
    /// - {contractAddress} must be allowed.
    /// - {resourceID} must be equal to the resource ID from metadata
    /// - Sender resource ID must exist.
    /// - Sender contract address must be allowed.
    ///
    /// @param data Consists of {resourceID}, {lenMetaData}, and {metaData}.
    ///
    /// @notice Data passed into the function should be constructed as follows:
    /// len(data)                              uint256     bytes  0  - 32
    /// data                                   bytes       bytes  32 - END
    ///
    /// @notice If {_contractAddressToExecuteFunctionSignature}[{contractAddress}] is set,
    /// {metaData} is expected to consist of needed function arguments.
    function executeProposal(bytes32 resourceID, bytes calldata data)
        external
        onlyBridge
    {
        address contractAddress = _resourceIDToTokenContractAddress[resourceID];
        require(contractAddress != address(0), "invalid resource ID");
        require(
            _contractWhitelist[contractAddress],
            "not an allowed contract address"
        );

        Metadata memory md = abi.decode(data, (Metadata));
        require(md.resourceID == resourceID, "different resource IDs");

        uint72 nonceAndID = (uint72(md.nonce) << 8) | uint72(md.domainID);
        rollupMetadata[nonceAndID] = md;
    }

    /// @notice Returns rollup info by original domain ID, resource ID and nonce.
    ///
    /// @notice Requirements:
    /// - {resourceID} must exist.
    /// - {resourceID} must be equal to the resource ID from metadata
    function getRollupInfo(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce
    )
        external
        view
        returns (
            address,
            bytes32,
            uint64
        )
    {
        address settleableAddress = _resourceIDToTokenContractAddress[
            resourceID
        ];
        require(settleableAddress != address(0), "invalid resource ID");

        uint72 nonceAndID = (uint72(nonce) << 8) | uint72(originDomainID);
        Metadata memory md = rollupMetadata[nonceAndID];
        require(md.resourceID == resourceID, "different resource IDs");

        return (settleableAddress, md.rootHash, md.totalBatches);
    }
}