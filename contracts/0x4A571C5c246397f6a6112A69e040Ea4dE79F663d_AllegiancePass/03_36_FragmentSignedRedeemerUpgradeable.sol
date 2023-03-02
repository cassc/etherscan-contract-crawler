// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract FragmentSignedRedeemerUpgradeable is Initializable {
    using ECDSAUpgradeable for bytes32;

    address public signer;

    function __FragmentSignedRedeemer_init(address signer_) public onlyInitializing {
        signer = signer_;
    }

    /**
     * @notice Uses ECDSA to validate the provided signature was signed by the known address.
     */
    /**
     * @dev For a given unique ordered array of tokenIds,
     * a valid signature is a message keccack256(abi.encode(owner, tokenIds)) signed by the known address.
     */
    /// @param signature Signed message
    /// @param to token recipient encoded in the signed message
    /// @param data arbitrary data to encode alongside the token recipient
    function validateSignature(bytes memory signature, address to, bytes memory data) public view returns (bool) {
        bytes memory message = abi.encode(to, data);
        bytes32 messageHash = ECDSAUpgradeable.toEthSignedMessageHash(keccak256(message));
        address recovered = messageHash.recover(signature);
        return signer == recovered;
    }

    function _setSigner(address signer_) internal {
        signer = signer_;
    }


    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}