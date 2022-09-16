// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract SignedRedeemer {
    using ECDSA for bytes32;

    address public signer;

    constructor(address _signer) {
        signer = _signer;
    }

    function _setSigner(address _signer) internal {
        signer = _signer;
    }

    function validateAllocation(
        bytes memory signature,
        uint256 allocated, // must be in numeric order
        address _to
    )
        public
        view
        returns (bool)
    {
        bytes memory message = abi.encodePacked(_to);
        message = abi.encodePacked(message, uint16(allocated));

        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(message));
        address _signer = messageHash.recover(signature);
        return signer == _signer;
    }

    function validateSignature(bytes memory signature, address _to) public view returns (bool) {
        bytes memory message = abi.encodePacked(_to);
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(message));
        address _signer = messageHash.recover(signature);
        return signer == _signer;
    }
}