// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/// @notice interface with functions to interact with Refuel contract
interface IRefuel {
    /**
     * @notice function to deposit nativeToken to Destination-address on destinationChain
     * @param destinationChainId chainId of the Destination chain
     * @param _to recipient address
     */
    function depositNativeToken(
        uint256 destinationChainId,
        address _to
    ) external payable;
}