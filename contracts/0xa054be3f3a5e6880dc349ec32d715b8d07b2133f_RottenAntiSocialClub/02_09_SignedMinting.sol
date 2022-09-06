// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";

contract SignedMinting {
    using ECDSA for bytes32;
    using ECDSA for bytes;

    using Address for address;

    address public mintingSigner;

    constructor(address _signer) {
        mintingSigner = _signer;
    }

    function _setMintingSigner(address _signer) internal {
        mintingSigner = _signer;
    }

    function validateSignature(bytes memory signature)
        internal
        view
        returns (bool)
    {
        return validateSignature(signature, msg.sender);
    }

    function validateSignature(bytes memory signature, address _to)
        internal
        view
        returns (bool)
    {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(
            bytes(toAsciiString(_to))
        );
        address _signer = messageHash.recover(signature);
        return mintingSigner == _signer;
    }

    modifier isValidSignature(bytes memory signature, address _of) {
        require(validateSignature(signature, _of), "Invalid signature");
        _;
    }

    function recoveredAddress(bytes memory signature, address _of)
        public
        pure
        returns (bytes memory)
    {
        address recoveredSigner = recover(signature, _of);
        return abi.encodePacked(recoveredSigner);
    }

    function recover(bytes memory signature, address _of)
        public
        pure
        returns (address)
    {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(
            bytes(asciiSender(_of))
        );
        address recoveredSigner = messageHash.recover(signature);
        return recoveredSigner;
    }

    function generateSenderHash(address _of) public pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(bytes(asciiSender(_of)));
    }

    function asciiSender(address _of) public pure returns (string memory) {
        return toAsciiString(_of);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}