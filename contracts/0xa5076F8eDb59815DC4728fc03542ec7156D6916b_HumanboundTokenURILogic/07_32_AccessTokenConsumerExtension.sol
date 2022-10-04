// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/ethereum-access-token/contracts/AccessTokenConsumer.sol";
import "./IEATVerifierConnector.sol";

/**
 * @title Abstract Extension to be inherited by Extensions that have functions that wish to consume
 *        Ethereum Access Tokens
 *
 * @dev Inherit this contract to implement functions that are EAT-gated
 * @notice Exposes the `requiresAuth` modifier by child contracts
 */
abstract contract AccessTokenConsumerExtension is Extension {
    modifier requiresAuth(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry
    ) {
        require(_verify(v, r, s, expiry), "AccessToken: verification failure");
        _;
    }

    function _verify(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry
    ) internal returns (bool) {
        AccessToken memory token = constructToken(expiry);
        address verifier = IEATVerifierConnector(address(this)).getVerifier();
        return IAccessTokenVerifier(verifier).verify(token, v, r, s);
    }

    function constructToken(uint256 expiry) internal view returns (AccessToken memory token) {
        FunctionCall memory functionCall;
        functionCall.functionSignature = msg.sig;
        functionCall.target = address(this);
        functionCall.caller = msg.sender;

        functionCall.parameters = extractInputs();
        token.functionCall = functionCall;
        token.expiry = expiry;
    }

    // Takes calldata and extracts non-signature, non-expiry function inputs as a byte array
    // Removes all references to the proof object except any offsets related to
    // other inputs that are pushed by the proof
    function extractInputs() internal pure returns (bytes memory inputs) {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            mstore(0x40, add(ptr, calldatasize()))

            let startPos := 0x04
            let endOfSigExp := add(startPos, 0x80)
            let totalInputSize := sub(calldatasize(), endOfSigExp)

            // Overwrite data to calldata pointer
            inputs := ptr

            // Store expected length of total byte array as first value
            mstore(inputs, totalInputSize)

            // Copy bytes from end of signature and expiry section to end of calldata
            calldatacopy(add(inputs, 0x20), endOfSigExp, totalInputSize)
        }
    }
}