// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '../Admin.sol';
pragma solidity ^0.8.4;

/**
 * @dev Simple relaying for Niftys Worker Minting
 *

 */
error InvalidNonce();
error InvalidSignature();
error InvalidArray();
error FailedExecution();

contract NiftyForwarder is Admin {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        bytes32 nonce;
        bytes data;
    }
    event CallSuccess(bool success, bytes data);
    mapping(bytes32 => bool) public _nonces;

    constructor() Admin(tx.origin) {}

    function verify(ForwardRequest calldata req, bytes calldata sig) internal returns (bool) {
        address signer = hashForwardRequest(req).toEthSignedMessageHash().recover(sig);
        return hasRole(SIGNER, signer);
    }

    function batchRoleGrant(address[] memory users, bytes32[] memory roles) public isGlobalAdmin {
        //require(users.length == roles.length, 'user length does not match roles');
        if (users.length != roles.length) revert InvalidArray();
        for (uint256 i = 0; i < roles.length; i++) {
            grantRole(roles[i], users[i]);
        }
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        whenNotPaused
        returns (bool, bytes memory)
    {
        //require(verify(req, signature), 'MinimalForwarder: signature does not match request');
        if (!verify(req, signature)) revert InvalidSignature();
        if (_nonces[req.nonce]) revert InvalidNonce();
        _nonces[req.nonce] = true;

        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );
        if (!success) revert FailedExecution();
        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /// @solidity memory-safe-assembly
            assembly {
                invalid()
            }
        }
        emit CallSuccess(success, returndata);
        return (success, returndata);
    }

    function hashForwardRequest(ForwardRequest calldata req) public view returns (bytes32) {
        return keccak256(abi.encode(getContractHash(), abi.encode(req)));
    }

    function getContractHash() public view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this)));
    }
}