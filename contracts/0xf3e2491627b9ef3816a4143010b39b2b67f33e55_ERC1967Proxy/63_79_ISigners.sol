// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISigners {
    /**
     * @notice the function to check the signature and increment the nonce associated with the method selector
     * @param methodId_ the method id
     * @param contractAddress_ the contract address to which the method id belongs
     * @param signHash_ the sign hash to be verified
     * @param signature_ the signature to be checked
     */
    function checkSignatureAndIncrementNonce(
        uint8 methodId_,
        address contractAddress_,
        bytes32 signHash_,
        bytes calldata signature_
    ) external;

    /**
     * @notice the function to validate the address change signature
     * @param methodId_ the method id
     * @param contractAddress_ the contract address to which the method id belongs
     * @param newAddress_ the new signed address
     * @param signature_ the signature to be checked
     */
    function validateChangeAddressSignature(
        uint8 methodId_,
        address contractAddress_,
        address newAddress_,
        bytes calldata signature_
    ) external;

    /**
     * @notice the function to get signature components
     * @param methodId_ the method id
     * @param contractAddress_ the contract address to which the method id belongs
     * @return chainName_ the name of the chain
     * @return nonce_ the current nonce value associated with the method selector
     */
    function getSigComponents(
        uint8 methodId_,
        address contractAddress_
    ) external view returns (string memory chainName_, uint256 nonce_);
}