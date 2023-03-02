// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "hardhat/console.sol";

/*
 * Grantable allows offchain permissioning
 *
 * by using the `granted` modifier you can specify what data (usually
 * function arguments and the caller) must be included in a `grant`
 * and what role is allowed to grant that permission.
 *
 * granted will check that the signer of the grant has the required
 * role
 */


contract Grantable is AccessControl {
    using ECDSA for bytes32;
    using ECDSA for bytes;

    // Checks that the specific callId (msg.sender and any relevant
    // args) of this call was signed by an
    // NOTICE: the permission granted is good for ANY NUMBER OF CALLS
    modifier granted(bytes memory callId, bytes memory signature, bytes32 granterRole) {
        bytes memory callSig = abi.encode(msg.sig, callId);
        address signer = callSig.toEthSignedMessageHash().recover(signature);
        require(hasRole(granterRole, signer), "Grantable: Invalid grant");
        _;
    }
}

contract GrantableTest is Grantable {
    using ECDSA for bytes32;
    using ECDSA for bytes;

    bytes32 public constant GRANTER = keccak256("GRANTER");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function testMethodA(bytes memory b, uint256 n, bytes memory grant)
        granted(abi.encode(msg.sender, b, n), grant, GRANTER)
        external view returns (bool)
    {
        return true;
    }

    // Second test method with the same argument signature to verify
    // that a grant for one can't be used for the other
    function testMethodB(bytes memory b, uint256 n, bytes memory grant)
        granted(abi.encode(msg.sender, b, n), grant, GRANTER)
        external view returns (bool)
    {
        return false;
    }
}