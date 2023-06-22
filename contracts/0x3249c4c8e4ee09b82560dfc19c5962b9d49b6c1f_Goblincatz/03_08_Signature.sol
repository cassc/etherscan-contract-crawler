/**  
 SPDX-License-Identifier: GPL-3.0
*/
pragma solidity ^0.8.13;

import "./ECDSA.sol";
import "./Ownable.sol";

error AllowlistNotEnabled();
error InvalidSignature();

contract Signature is Ownable {
    using ECDSA for bytes32;

    address allowlistSigningKey = address(0);
    bytes32 private immutable DOMAIN_SEPARATOR;
    bytes32 private immutable EIP712_Domain = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private immutable NAME = keccak256("Goblincatz");
    bytes32 private immutable NUMBER = keccak256("1");

    
    bytes32 private immutable MINTER_TYPEHASH =
        keccak256("Minter(address wallet)");

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_Domain, 
                NAME, 
                NUMBER,
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev set allowlist signing address to enable allowlist
     */
    function setAllowlistSigningAddress(address newSigningKey) public onlyOwner {
        allowlistSigningKey = newSigningKey;
    }

    modifier requiresAllowlist(bytes calldata signature) {
        if(allowlistSigningKey == address(0)) revert AllowlistNotEnabled();
        
        bytes32 DIGEST = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(MINTER_TYPEHASH, msg.sender))
            )
        );

        address recoveredAddress = DIGEST.recover(signature);
        if(recoveredAddress != allowlistSigningKey) revert InvalidSignature();
        _;
    }
}