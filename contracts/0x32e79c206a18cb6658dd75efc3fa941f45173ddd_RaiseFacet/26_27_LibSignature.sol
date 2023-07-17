// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// OpenZeppelin
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**************************************

    Signature library

**************************************/

library LibSignature {
    // const
    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // errors
    error InvalidMessage(bytes32 verify, bytes32 message);

    /**************************************

        Verify message

     **************************************/

    function verifyMessage(bytes32 _nameHash, bytes32 _versionHash, bytes32 _rawMessage, bytes32 _message) internal view {
        // build domain separator
        bytes32 domainSeparatorV4_ = keccak256(abi.encode(EIP712_DOMAIN_TYPEHASH, _nameHash, _versionHash, block.chainid, address(this)));

        // construct EIP712 message
        bytes32 toVerify_ = ECDSA.toTypedDataHash(domainSeparatorV4_, _rawMessage);

        // verify computation against original
        if (toVerify_ != _message) {
            revert InvalidMessage(toVerify_, _message);
        }
    }

    /**************************************

        Recover signer

     **************************************/

    function recoverSigner(bytes32 _data, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        // recover EIP712 signer using provided vrs
        address signer_ = ECDSA.recover(_data, _v, _r, _s);

        // return signer
        return signer_;
    }
}