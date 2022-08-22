//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../TypesAndDecoders.sol";

interface IDelegatable {
    /**
     * @notice Submits a batch of signed delegations for processing.
     * @param batch Invocation[] - The batch of invocations to process.
     * @return success bool - Whether the batch of invocations was successfully processed.
     */
    function contractInvoke(Invocation[] calldata batch)
        external
        returns (bool);

    /**
     * @notice Submits a batch of signed invocations for processing.
     * @param signedInvocations SignedInvocation[] - The batch of signed invocations to process.
     * @return success bool - Whether the batch of invocations was successfully processed.
     */
    function invoke(SignedInvocation[] calldata signedInvocations)
        external
        returns (bool success);

    /**
     * @notice Get Delegation type
     * @param delegation Delegation - The delegation to get the type of
     * @return bytes32 - The type of the delegation
     */
    function getDelegationTypedDataHash(Delegation memory delegation)
        external
        view
        returns (bytes32);

    /**
     * @notice Get Delegation type
     * @param invocations Invocations
     * @return bytes32 - The type of the Invocations
     */
    function getInvocationsTypedDataHash(Invocations memory invocations)
        external
        view
        returns (bytes32);

    function getEIP712DomainHash(
        string memory contractName,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) external pure returns (bytes32);

    function verifyInvocationSignature(SignedInvocation memory signedInvocation)
        external
        view
        returns (address);

    function verifyDelegationSignature(SignedDelegation memory signedDelegation)
        external
        view
        returns (address);
}