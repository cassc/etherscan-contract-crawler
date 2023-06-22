// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title SharedSigners
 * @dev Helper functions for ECDSA message creation and signature recovery.
 */
abstract contract SharedSigners {
    using ECDSA for bytes32;

    error SignatureError(string reason);

    /**
    @notice Generates a message for a given data input that will be signed
    off-chain using ECDSA.
     */
    function _createMessage(address _to, uint256 _nonce)
        internal
        pure
        returns (bytes32)
    {
        bytes32 hash = keccak256(abi.encodePacked(_to, _nonce));
        return ECDSA.toEthSignedMessageHash(hash);
        // return hash;
    }

    /**
     * @notice Recover signing address of signature
     * @param _address the account the signature is associated to
     * @param _signature the signature by the allowance signer wallet
     * @param _nonce the nonce associated to this allowance
     * @return address the signer of the signature
     */
    function _recoverSigner(
        bytes memory _signature,
        address _address,
        uint256 _nonce
    ) internal pure returns (address) {
        bytes32 message = _createMessage(_address, _nonce);
        (address signer, ) = message.tryRecover(_signature);
        return signer;
    }
}