// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./SolRsaVerify.sol";

library VerifyLinkAttestation {
    using ECDSA for bytes32;

    function verifyAddressAttestation(bytes memory attestation, address attestorAddr) internal view returns (address attestedAddress) {
        address linkedAddress;

        (attestedAddress, linkedAddress) = decodeAttestation(attestation, attestorAddr);

        if (msg.sender != linkedAddress){
            revert("Linked address not eq sender");
        }
    }

    function decodeAttestation(bytes memory attestation, address attestorAddr)
        internal
        view
        returns (address attestedAddress, address linkedAddress)
    {
        uint256 length;
        uint256 hashIndex;
        uint256 decodeIndex;

        bytes memory curBytes;
        bytes memory sigData;

        bytes memory pubKeyModulus;
        bytes memory pubKeyExponent;

        // Main header (Signed link attestation)
        // (length, hashIndex, ) = decodeLength(attestation, 0); // (total length, primary header)
        (, hashIndex, ) = decodeLength(attestation, 0); // (total length, primary header)

        // Link attestation structure
        (length, decodeIndex, ) = decodeLength(attestation, hashIndex);

        bytes memory linkEncoded = copyDataBlock(attestation, hashIndex, (length + decodeIndex) - hashIndex); // Encoded data for link attestation

        (length, curBytes, decodeIndex, ) = decodeElement(attestation, decodeIndex); // linked ethereum address

        linkedAddress = bytesToAddress(curBytes);

        (, curBytes, decodeIndex, ) = decodeElement(attestation, decodeIndex); // Linked attestation


        (attestedAddress, pubKeyModulus, pubKeyExponent) = decodeAddressAttestation(curBytes, attestorAddr);

        (, curBytes, decodeIndex, ) = decodeElement(attestation, decodeIndex); // validity

        validateExpiry(curBytes);

        // TODO: Check for context field
        //(length, curBytes, decodeIndex, ) = decodeElement(attestation, decodeIndex); // context

        (, decodeIndex, ) = decodeLength(attestation, decodeIndex); // object identifier
        (, , decodeIndex, ) = decodeElement(attestation, decodeIndex);

        (, sigData, decodeIndex) = decodeElementOffset(attestation, decodeIndex, 1); // Signature


        if (SolRsaVerify.pkcs1Sha256VerifyRaw(linkEncoded, sigData, pubKeyExponent, pubKeyModulus) != 0) {
            revert("RSA verification failed :-(");
        }
    }

    function decodeAddressAttestation(bytes memory attestation, address attestorAddr)
        internal
        view
        returns (
            address attestedAddress,
            bytes memory pubKeyModulus,
            bytes memory pubKeyExponent
        )
    {
        uint256 length;
        uint256 hashIndex;
        uint256 decodeIndex;

        bytes memory curBytes;
        bytes memory sigData;

        (, hashIndex, ) = decodeLength(attestation, 0); // (total length, primary header)


        // Address attestation structure
        (length, decodeIndex, ) = decodeLength(attestation, hashIndex);

        bytes memory addressEncoded = copyDataBlock(attestation, hashIndex, (length + decodeIndex) - hashIndex); // Encoded data for address attestation

        (, curBytes, decodeIndex, ) = decodeElement(attestation, decodeIndex); // subject public key (public key of link attestation signature)


        (pubKeyModulus, pubKeyExponent) = decodeRsaPublicKey(curBytes);

        (, curBytes, decodeIndex, ) = decodeElement(attestation, decodeIndex); // Attested ethereum address

        attestedAddress = bytesToAddress(curBytes);


        (, curBytes, decodeIndex, ) = decodeElement(attestation, decodeIndex); // validity

        validateExpiry(curBytes);

        // TODO: Check for context field
        //(length, curBytes, decodeIndex, ) = decodeElement(attestation, decodeIndex); // context


        (, decodeIndex, ) = decodeLength(attestation, decodeIndex); // Algorithm info
        (, , decodeIndex, ) = decodeElement(attestation, decodeIndex);

        (, sigData, decodeIndex) = decodeElementOffset(attestation, decodeIndex, 1); // Signature

        address recoveredAddress = keccak256(addressEncoded).recover(sigData);

        if (recoveredAddress != attestorAddr) {
            revert("Wrong Attestor");
        }
    }

    function validateExpiry(bytes memory validity) internal view {

        uint256 length = 0;
        uint256 decodeIndex = 0;
        bytes memory curBytes;

        (length, curBytes, decodeIndex,) = decodeElement(validity, decodeIndex);

        uint from = bytesToUint(curBytes);

        (length, curBytes, decodeIndex,) = decodeElement(validity, decodeIndex);

        uint to = bytesToUint(curBytes);

        require(block.timestamp > from, "Attestation not yet valid");
        require(block.timestamp < to, "Attestation expired");
    }

    function decodeRsaPublicKey(bytes memory asnEncoded) internal pure returns (bytes memory modulus, bytes memory exponent) {
        uint256 decodeIndex;
        bytes memory curBytes;

        // (length, curBytes, decodeIndex, ) = decodeElement(asnEncoded, decodeIndex); // Skip algorithm ID
        // (length, curBytes, decodeIndex) = decodeElementOffset(asnEncoded, decodeIndex, 1);
        (, , decodeIndex, ) = decodeElement(asnEncoded, decodeIndex); // Skip algorithm ID
        (, curBytes, decodeIndex) = decodeElementOffset(asnEncoded, decodeIndex, 1);

        decodeIndex = 0;
        // bytes memory parts = curBytes;

        // (length, decodeIndex, ) = decodeLength(parts, decodeIndex);
        (, decodeIndex, ) = decodeLength(curBytes, decodeIndex);

        // (length, modulus, decodeIndex) = decodeElementOffset(parts, decodeIndex, 1);
        (, modulus, decodeIndex) = decodeElementOffset(curBytes, decodeIndex, 1);

        // (length, exponent, decodeIndex, ) = decodeElement(parts, decodeIndex);
        (, exponent, , ) = decodeElement(curBytes, decodeIndex);
    }

    // TODO: Is this more gas efficient compared to using open-zeppelin EDCSA?
    /*function recoverSigner(bytes memory prehash, bytes memory signature) internal pure returns(address signer)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(keccak256(prehash), v, r, s);
    }

    function splitSignature(bytes memory sig)
    internal pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {

        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }*/

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    //Truncates if input is greater than 32 bytes; we only handle 32 byte values.
    function bytesToUint(bytes memory b) public pure returns (uint256 conv)
    {
        if (b.length < 0x20) //if b is less than 32 bytes we need to pad to get correct value
        {
            bytes memory b2 = new bytes(32);
            uint startCopy = 0x20 + 0x20 - b.length;
            assembly
            {
                let bcc := add(b, 0x20)
                let bbc := add(b2, startCopy)
                mstore(bbc, mload(bcc))
                conv := mload(add(b2, 32))
            }
        }
        else
        {
            assembly
            {
                conv := mload(add(b, 32))
            }
        }
    }

    //////////////////////////////////////////////////////////////
    // DER Helper functions
    //////////////////////////////////////////////////////////////

    function decodeDERData(bytes memory byteCode, uint256 dIndex)
        internal
        pure
        returns (
            bytes memory data,
            uint256 index,
            uint256 length,
            bytes1 tag
        )
    {
        return decodeDERData(byteCode, dIndex, 0);
    }

    function copyDataBlock(
        bytes memory byteCode,
        uint256 dIndex,
        uint256 length
    ) internal pure returns (bytes memory data) {
        // uint256 blank;
        // uint256 index = dIndex;

        // uint256 dStart = 0x20 + dIndex;
        uint256 cycles = length / 0x20;
        uint256 requiredAlloc = length;

        if (length % 0x20 > 0) //optimise copying the final part of the bytes - remove the looping
        {
            cycles++;
            requiredAlloc += 0x20; //expand memory to allow end blank
        }

        data = new bytes(requiredAlloc);

        assembly {
            let mc := add(data, 0x20) //offset into bytes we're writing into
            let cycle := 0

            for {
                let cc := add(byteCode, add(0x20, dIndex))
            } lt(cycle, cycles) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
                cycle := add(cycle, 0x01)
            } {
                mstore(mc, mload(cc))
            }
        }

        //finally blank final bytes and shrink size
        if (length % 0x20 > 0) {
            uint256 offsetStart = 0x20 + length;
            assembly {
                let mc := add(data, offsetStart)
                // mstore(mc, mload(add(blank, 0x20)))
                mstore(mc, mload(0x20))
                //now shrink the memory back
                mstore(data, length)
            }
        }
    }

    function decodeDERData(
        bytes memory byteCode,
        uint256 dIndex,
        uint256 offset
    )
        internal
        pure
        returns (
            bytes memory data,
            uint256 index,
            uint256 length,
            bytes1 tag
        )
    {
        // index = dIndex;

        // (length, index, tag) = decodeLength(byteCode, index);

        (length, index, tag) = decodeLength(byteCode, dIndex);

        if (offset <= length) {
            // uint256 requiredLength = length - offset;
            // uint256 dStart = index + offset;

            // data = copyDataBlock(byteCode, dStart, requiredLength);
            data = copyDataBlock(byteCode, index + offset, length - offset);
        } else {
            data = bytes("");
        }

        index += length;
    }

    function decodeElement(bytes memory byteCode, uint256 decodeIndex)
        internal
        pure
        returns (
            uint256 length,
            bytes memory content,
            uint256 newIndex,
            bytes1 tag
        )
    {
        (content, newIndex, length, tag) = decodeDERData(byteCode, decodeIndex);
    }

    function decodeElementOffset(
        bytes memory byteCode,
        uint256 decodeIndex,
        uint256 offset
    )
        internal
        pure
        returns (
            uint256 length,
            bytes memory content,
            uint256 newIndex
        )
    {
        (content, newIndex, length, ) = decodeDERData(byteCode, decodeIndex, offset);
    }

    function decodeLength(bytes memory byteCode, uint256 decodeIndex)
        internal
        pure
        returns (
            uint256 length,
            uint256 newIndex,
            bytes1 tag
        )
    {
        uint256 codeLength = 1;
        // length = 0;
        newIndex = decodeIndex;
        tag = bytes1(byteCode[newIndex++]);

        if ((byteCode[newIndex] & 0x80) == 0x80) {
            codeLength = uint8((byteCode[newIndex++] & 0x7f));
        }

        for (uint256 i = 0; i < codeLength; i++) {
            length |= uint256(uint8(byteCode[newIndex++] & 0xFF)) << ((codeLength - i - 1) * 8);
        }
    }

    function decodeIA5String(
        bytes memory byteCode,
        uint256[] memory objCodes,
        uint256 objCodeIndex,
        uint256 decodeIndex
    ) internal pure returns (Status memory) {
        uint256 length = uint8(byteCode[decodeIndex++]);
        bytes32 store = 0;
        for (uint256 j = 0; j < length; j++) store |= bytes32(byteCode[decodeIndex++] & 0xFF) >> (j * 8);
        objCodes[objCodeIndex++] = uint256(store);
        Status memory retVal;
        retVal.decodeIndex = decodeIndex;
        retVal.objCodeIndex = objCodeIndex;

        return retVal;
    }

    struct Status {
        uint256 decodeIndex;
        uint256 objCodeIndex;
    }
}