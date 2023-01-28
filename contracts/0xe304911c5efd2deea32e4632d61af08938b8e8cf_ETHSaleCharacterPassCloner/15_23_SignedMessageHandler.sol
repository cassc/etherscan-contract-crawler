// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract SignedMessageHandler {
    mapping(bytes32 => bool) private consumed;

    function _consumeSigner(bytes32 message, bytes calldata signature) internal returns (address) {
        require(!consumed[message], "message already consumed");
        consumed[message] = true;
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(message), signature);
    }
}