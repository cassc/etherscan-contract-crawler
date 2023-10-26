//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./EIP712Base.sol";

contract EIP712Whitelisting is AccessControl, EIP712Base {
    using ECDSA for bytes32;
    bytes32 public constant WHITELISTING_ROLE = keccak256("WHITELISTING_ROLE");

    mapping(bytes32 => bool) public signatureUsed;

    // The typehash for the data type specified in the structured data
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-typehash
    // This should match whats in the client side whitelist signing code
    // https://github.com/msfeldstein/EIP712-whitelisting/blob/main/test/signWhitelist.ts#L22
    bytes32 public constant MINTER_TYPEHASH =
        keccak256("Minter(address wallet,uint256 nonce)");

    constructor(string memory name) {
        setUpDomain(name);
        _setupRole(WHITELISTING_ROLE, msg.sender);
    }

    modifier requiresWhitelist(
        bytes calldata signature,
        uint256 nonce
    ) {
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 structHash = keccak256(
            abi.encode(MINTER_TYPEHASH, msg.sender, nonce)
        );
        bytes32 digest = toTypedMessageHash(structHash); /*Calculate EIP712 digest*/
        require(!signatureUsed[digest], "signature used");
        signatureUsed[digest] = true;
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = digest.recover(signature);
        require(
            hasRole(WHITELISTING_ROLE, recoveredAddress),
            "Invalid Signature"
        );
        _;
    }
}