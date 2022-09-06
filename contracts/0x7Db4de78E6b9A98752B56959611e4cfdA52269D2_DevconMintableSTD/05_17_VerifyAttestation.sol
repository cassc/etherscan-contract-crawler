/* Attestation decode and validation */
/* AlphaWallet 2021 - 2022 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract VerifyAttestation {

    bytes1 constant BOOLEAN_TAG         = bytes1(0x01);
    bytes1 constant INTEGER_TAG         = bytes1(0x02);
    bytes1 constant BIT_STRING_TAG      = bytes1(0x03);
    bytes1 constant OCTET_STRING_TAG    = bytes1(0x04);
    bytes1 constant NULL_TAG            = bytes1(0x05);
    bytes1 constant OBJECT_IDENTIFIER_TAG = bytes1(0x06);
    bytes1 constant EXTERNAL_TAG        = bytes1(0x08);
    bytes1 constant ENUMERATED_TAG      = bytes1(0x0a); // decimal 10
    bytes1 constant SEQUENCE_TAG        = bytes1(0x10); // decimal 16
    bytes1 constant SET_TAG             = bytes1(0x11); // decimal 17
    bytes1 constant SET_OF_TAG          = bytes1(0x11);

    bytes1 constant NUMERIC_STRING_TAG  = bytes1(0x12); // decimal 18
    bytes1 constant PRINTABLE_STRING_TAG = bytes1(0x13); // decimal 19
    bytes1 constant T61_STRING_TAG      = bytes1(0x14); // decimal 20
    bytes1 constant VIDEOTEX_STRING_TAG = bytes1(0x15); // decimal 21
    bytes1 constant IA5_STRING_TAG      = bytes1(0x16); // decimal 22
    bytes1 constant UTC_TIME_TAG        = bytes1(0x17); // decimal 23
    bytes1 constant GENERALIZED_TIME_TAG = bytes1(0x18); // decimal 24
    bytes1 constant GRAPHIC_STRING_TAG  = bytes1(0x19); // decimal 25
    bytes1 constant VISIBLE_STRING_TAG  = bytes1(0x1a); // decimal 26
    bytes1 constant GENERAL_STRING_TAG  = bytes1(0x1b); // decimal 27
    bytes1 constant UNIVERSAL_STRING_TAG = bytes1(0x1c); // decimal 28
    bytes1 constant BMP_STRING_TAG      = bytes1(0x1e); // decimal 30
    bytes1 constant UTF8_STRING_TAG     = bytes1(0x0c); // decimal 12

    bytes1 constant CONSTRUCTED_TAG     = bytes1(0x20); // decimal 28

    bytes1 constant LENGTH_TAG          = bytes1(0x30);
    bytes1 constant VERSION_TAG         = bytes1(0xA0);
    bytes1 constant COMPOUND_TAG        = bytes1(0xA3);

    uint constant TTL_GAP = 300;// 5 min

    uint256 constant IA5_CODE = uint256(bytes32("IA5")); //tags for disambiguating content
    uint256 constant DEROBJ_CODE = uint256(bytes32("OBJID"));

    uint256 constant public fieldSize = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant public curveOrder = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    event Value(uint256 indexed val);
    event RtnStr(bytes val);
    event RtnS(string val);

    uint256[2] private G = [ 21282764439311451829394129092047993080259557426320933158672611067687630484067,
    3813889942691430704369624600187664845713336792511424430006907067499686345744 ];

    uint256[2] private H = [ 10844896013696871595893151490650636250667003995871483372134187278207473369077,
    9393217696329481319187854592386054938412168121447413803797200472841959383227 ];

    uint256 constant curveOrderBitLength = 254;
    uint256 constant curveOrderBitShift = 256 - curveOrderBitLength;
    uint256 constant pointLength = 65;

    // We create byte arrays for these at construction time to save gas when we need to use them
    bytes constant GPoint = abi.encodePacked(uint8(0x04), uint256(21282764439311451829394129092047993080259557426320933158672611067687630484067),
        uint256(3813889942691430704369624600187664845713336792511424430006907067499686345744));

    bytes constant HPoint = abi.encodePacked(uint8(0x04), uint256(10844896013696871595893151490650636250667003995871483372134187278207473369077),
        uint256(9393217696329481319187854592386054938412168121447413803797200472841959383227));

    bytes constant emptyBytes = new bytes(0x00);

    struct FullProofOfExponent {
        bytes tPoint;
        uint256 challenge;
        bytes entropy;
    }

    struct Length {
        uint decodeIndex;
        uint length;
    }

    /**
    * Perform TicketAttestation verification
    * NOTE: This function DOES NOT VALIDATE whether the public key attested to is the same as the one who signed this transaction; you must perform validation of the subject from the calling function.
    **/
    function verifyTicketAttestation(bytes memory attestation, address attestor, address ticketIssuer) public view returns(address subject, bytes memory ticketId, bytes memory conferenceId, bool attestationValid)
    {
        address recoveredAttestor;
        address recoveredIssuer;

        (recoveredAttestor, recoveredIssuer, subject, ticketId, conferenceId, attestationValid) = _verifyTicketAttestation(attestation);

        if (recoveredAttestor != attestor || recoveredIssuer != ticketIssuer || !attestationValid)
        {
            subject = address(0);
            ticketId = emptyBytes;
            conferenceId = emptyBytes;
            attestationValid = false;
        }
    }

    function verifyTicketAttestation(bytes memory attestation) public view returns(address attestor, address ticketIssuer, address subject, bytes memory ticketId, bytes memory conferenceId, bool attestationValid) //public pure returns(address payable subject, bytes memory ticketId, string memory identifier, address issuer, address attestor)
    {
        (attestor, ticketIssuer, subject, ticketId, conferenceId, attestationValid) = _verifyTicketAttestation(attestation);
    }

    function _verifyTicketAttestation(bytes memory attestation) public view returns(address attestor, address ticketIssuer, address subject, bytes memory ticketId, bytes memory conferenceId, bool attestationValid) //public pure returns(address payable subject, bytes memory ticketId, string memory identifier, address issuer, address attestor)
    {
        uint256 decodeIndex = 0;
        uint256 length = 0;
        FullProofOfExponent memory pok;
        // Commitment to user identifier in Attestation
        bytes memory commitment1;
        // Commitment to user identifier in Ticket
        bytes memory commitment2;

        (length, decodeIndex, ) = decodeLength(attestation, 0); //852 (total length, primary header)

        (ticketIssuer, ticketId, conferenceId, commitment2, decodeIndex) = recoverTicketSignatureAddress(attestation, decodeIndex);

        (attestor, subject, commitment1, decodeIndex, attestationValid) = recoverSignedIdentifierAddress(attestation, decodeIndex);

        //now pull ZK (Zero-Knowledge) POK (Proof Of Knowledge) data
        (pok, decodeIndex) = recoverPOK(attestation, decodeIndex);

        if (!attestationValid || !verifyPOK(commitment1, commitment2, pok))
        {
            attestor = address(0);
            ticketIssuer = address(0);
            subject = address(0);
            ticketId = emptyBytes;
            conferenceId = emptyBytes;
            attestationValid = false;
        }
    }

    function verifyEqualityProof(bytes memory com1, bytes memory com2, bytes memory proof, bytes memory entropy) public view returns(bool result)
    {
        FullProofOfExponent memory pok;
        bytes memory attestationData;
        uint256 decodeIndex = 0;
        uint256 length = 0;

        (length, decodeIndex, ) = decodeLength(proof, 0);

        (, attestationData, decodeIndex,) = decodeElement(proof, decodeIndex);
        pok.challenge = bytesToUint(attestationData);
        (, pok.tPoint, decodeIndex,) = decodeElement(proof, decodeIndex);
        pok.entropy = entropy;

        return verifyPOK(com1, com2, pok);
    }

    //////////////////////////////////////////////////////////////
    // DER Structure Decoding
    //////////////////////////////////////////////////////////////

    function recoverSignedIdentifierAddress(bytes memory attestation, uint256 hashIndex) public view returns(address signer, address subject, bytes memory commitment1, uint256 resultIndex, bool timeStampValid)
    {
        bytes memory sigData;

        uint256 length ;
        uint256 decodeIndex ;
        uint256 headerIndex;

        (length, hashIndex, ) = decodeLength(attestation, hashIndex); //576  (SignedIdentifierAttestation)

        (length, headerIndex, ) = decodeLength(attestation, hashIndex); //493  (IdentifierAttestation)

        resultIndex = length + headerIndex; // (length + decodeIndex) - hashIndex);

        bytes memory preHash = copyDataBlock(attestation, hashIndex,  (length + headerIndex) - hashIndex);

        decodeIndex = headerIndex + length;

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); //Signature algorithm

        (length, sigData, resultIndex) = decodeElementOffset(attestation, decodeIndex + length, 1); // Signature

        //get signing address
        signer = recoverSigner(preHash, sigData);

        //Recover public key
        (length, decodeIndex, ) = decodeLength(attestation, headerIndex); //read Version

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex + length); // Serial

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex + length); // Signature type (9) 1.2.840.10045.2.1

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex + length); // Issuer Sequence (14) [[2.5.4.3, ALX]]], (Issuer: CN=ALX)

        (decodeIndex, timeStampValid) = decodeTimeBlock(attestation, decodeIndex + length);

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); // Smartcontract?

        (subject, decodeIndex) = addressFromPublicKey(attestation, decodeIndex + length);

        commitment1 = decodeCommitment(attestation, decodeIndex);
    }

    function decodeCommitment (bytes memory attestation, uint256 decodeIndex) internal virtual pure returns (bytes memory commitment) {

        uint256 length ;
        
        if (attestation[decodeIndex] != COMPOUND_TAG) {
            // its not commitment, but some other data. example:  SEQUENCE (INTEGER 42, INTEGER 1337)
            (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); // some payload
        }

        (commitment, ) = recoverCommitment(attestation, decodeIndex + length); // Commitment 1, generated by
        // IdentifierAttestation constructor
    }

    function decodeTimeBlock(bytes memory attestation, uint256 decodeIndex) public view returns (uint256 index, bool valid)
    {
        bytes memory timeBlock;
        uint256 length;
        uint256 blockLength;
        bytes1 tag;

        (blockLength, index, ) = decodeLength(attestation, decodeIndex); //30 32
        (length, decodeIndex, ) = decodeLength(attestation, index); //18 0f
        (length, timeBlock, decodeIndex, tag) = decodeElement(attestation, decodeIndex + length); //INTEGER_TAG if blockchain friendly time is used
        if (tag == INTEGER_TAG)
        {
            uint256 startTime = bytesToUint(timeBlock);
            (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); //18 0F
            (, timeBlock, decodeIndex,) = decodeElement(attestation, decodeIndex + length);
            uint256 endTime = bytesToUint(timeBlock);
            valid = block.timestamp > (startTime - TTL_GAP) && block.timestamp < endTime;

        }
        else
        {
            valid = false; //fail attestation without blockchain friendly timestamps
        }

        index = index + blockLength;
    }

    function recoverCommitment(bytes memory attestation, uint256 decodeIndex) internal pure returns(bytes memory commitment, uint256 resultIndex)
    {
        uint256 length;
        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); // Commitment tag (0x57)
        //pull Commitment
        commitment = copyDataBlock(attestation, decodeIndex + (length - 65), 65);
        resultIndex = decodeIndex + length;
    }

    function recoverTicketSignatureAddress(bytes memory attestation, uint256 hashIndex) public pure returns(address signer, bytes memory ticketId, bytes memory conferenceId, bytes memory commitment2, uint256 resultIndex)
    {
        uint256 length;
        uint256 decodeIndex;
        bytes memory sigData;

        (length, decodeIndex, ) = decodeLength(attestation, hashIndex); //163 Ticket Data

        (length, hashIndex, ) = decodeLength(attestation, decodeIndex); //5D

        bytes memory preHash = copyDataBlock(attestation, decodeIndex, (length + hashIndex) - decodeIndex); // ticket

        (length, conferenceId, decodeIndex, ) = decodeElement(attestation, hashIndex); //CONFERENCE_ID
        (length, ticketId, decodeIndex,) = decodeElement(attestation, decodeIndex); //TICKET_ID
        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); //Ticket Class

        (length, commitment2, decodeIndex,) = decodeElement(attestation, decodeIndex + length); // Commitment 2, generated by Ticket constructor
        // in class Ticket

        (length, sigData, resultIndex) = decodeElementOffset(attestation, decodeIndex, 1); // Signature

        //ecrecover
        signer = recoverSigner(preHash, sigData);
    }

    function recoverPOK(bytes memory attestation, uint256 decodeIndex) private pure returns(FullProofOfExponent memory pok, uint256 resultIndex)
    {
        bytes memory data;
        uint256 length;
        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); //68 POK data
        (length, data, decodeIndex,) = decodeElement(attestation, decodeIndex);
        pok.challenge = bytesToUint(data);
        (length, pok.tPoint, decodeIndex,) = decodeElement(attestation, decodeIndex);
        (length, pok.entropy, resultIndex,) = decodeElement(attestation, decodeIndex);
    }

    function getAttestationTimestamp(bytes memory attestation) public pure returns(string memory startTime, string memory endTime)
    {
        uint256 decodeIndex = 0;
        uint256 length = 0;

        (length, decodeIndex, ) = decodeLength(attestation, 0); //852 (total length, primary header)
        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); //Ticket (should be 163)
        (startTime, endTime) = getAttestationTimestamp(attestation, decodeIndex + length);
    }

    function getAttestationTimestamp(bytes memory attestation, uint256 decodeIndex) public pure returns(string memory startTime, string memory endTime)
    {
        uint256 length = 0;
        bytes memory timeData;

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); //576  (SignedIdentifierAttestation)
        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); //493  (IdentifierAttestation)

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); //read Version

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex + length); // Serial

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex + length); // Signature type (9) 1.2.840.10045.2.1

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex + length); // Issuer Sequence (14) [[2.5.4.3, ALX]]], (Issuer: CN=ALX)

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex + length); // Validity time

        (length, timeData, decodeIndex, ) = decodeElement(attestation, decodeIndex);
        startTime = copyStringBlock(timeData);
        (length, timeData, decodeIndex, ) = decodeElement(attestation, decodeIndex);
        endTime = copyStringBlock(timeData);
    }

    function addressFromPublicKey(bytes memory attestation, uint256 decodeIndex) public pure returns(address keyAddress, uint256 resultIndex)
    {
        uint256 length;
        bytes memory publicKeyBytes;
        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); // 307 key headerIndex
        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); // 236 header tag

        (length, publicKeyBytes, resultIndex) = decodeElementOffset(attestation, decodeIndex + length, 2); // public key

        keyAddress = publicKeyToAddress(publicKeyBytes);
    }

    //////////////////////////////////////////////////////////////
    // Cryptography & Ethereum constructs
    //////////////////////////////////////////////////////////////

    function getRiddle(bytes memory com1, bytes memory com2) public view returns(uint256[2] memory riddle)
    {
        uint256[2] memory lhs;
        uint256[2] memory rhs;
        (lhs[0], lhs[1]) = extractXYFromPoint(com1);
        (rhs[0], rhs[1]) = extractXYFromPoint(com2);

        rhs = ecInv(rhs);

        riddle = ecAdd(lhs, rhs);
    }

    /* Verify ZK (Zero-Knowledge) proof of equality of message in two
       Pedersen commitments by proving knowledge of the discrete log
       of their difference. This verifies that the message
       (identifier, such as email address) in both commitments are the
       same, and the one constructing the proof knows the secret of
       both these commitments.  See:

     Commitment1: https://github.com/TokenScript/attestation/blob/main/src/main/java/org/tokenscript/attestation/IdentifierAttestation.java

     Commitment2: https://github.com/TokenScript/attestation/blob/main/src/main/java/org/devcon/ticket/Ticket.java

     Reference implementation: https://github.com/TokenScript/attestation/blob/main/src/main/java/org/tokenscript/attestation/core/AttestationCrypto.java
    */

    function verifyPOK(bytes memory com1, bytes memory com2, FullProofOfExponent memory pok) private view returns(bool)
    {
        // Riddle is H*(r1-r2) with r1, r2 being the secret randomness of com1, respectively com2
        uint256[2] memory riddle = getRiddle(com1, com2);

        // Compute challenge in a Fiat-Shamir style, based on context specific entropy to avoid reuse of proof
        bytes memory cArray = abi.encodePacked(HPoint, com1, com2, pok.tPoint, pok.entropy);
        uint256 c = mapToCurveMultiplier(cArray);

        uint256[2] memory lhs = ecMul(pok.challenge, H[0], H[1]);
        if (lhs[0] == 0 && lhs[1] == 0) { return false; } //early revert to avoid spending more gas

        //ECPoint riddle multiply by proof (component hash)
        uint256[2] memory rhs = ecMul(c, riddle[0], riddle[1]);
        if (rhs[0] == 0 && rhs[1] == 0) { return false; } //early revert to avoid spending more gas

        uint256[2] memory point;
        (point[0], point[1]) = extractXYFromPoint(pok.tPoint);
        rhs = ecAdd(rhs, point);

        return ecEquals(lhs, rhs);
    }

    function ecEquals(uint256[2] memory ecPoint1, uint256[2] memory ecPoint2) private pure returns(bool)
    {
        return (ecPoint1[0] == ecPoint2[0] && ecPoint1[1] == ecPoint2[1]);
    }

    function publicKeyToAddress(bytes memory publicKey) pure internal returns(address keyAddr)
    {
        bytes32 keyHash = keccak256(publicKey);
        bytes memory scratch = new bytes(32);

        assembly {
            mstore(add(scratch, 32), keyHash)
            mstore(add(scratch, 12), 0)
            keyAddr := mload(add(scratch, 32))
        }
    }

    function recoverSigner(bytes memory prehash, bytes memory signature) internal pure returns(address signer)
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
    }

    function ecMul(uint256 s, uint256 x, uint256 y) public view
    returns (uint256[2] memory retP)
    {
        bool success;
        // With a public key (x, y), this computes p = scalar * (x, y).
        uint256[3] memory i = [x, y, s];

        assembly
        {
        // call ecmul precompile
        // inputs are: x, y, scalar
            success := staticcall (not(0), 0x07, i, 0x60, retP, 0x40)
        }

        if (!success)
        {
            retP[0] = 0;
            retP[1] = 0;
        }
    }

    function ecInv(uint256[2] memory point) private pure
    returns (uint256[2] memory invPoint)
    {
        invPoint[0] = point[0];
        int256 n = int256(fieldSize) - int256(point[1]);
        n = n % int256(fieldSize);
        if (n < 0) { n += int256(fieldSize); }
        invPoint[1] = uint256(n);
    }

    function ecAdd(uint256[2] memory p1, uint256[2] memory p2) public view
    returns (uint256[2] memory retP)
    {
        bool success;
        uint256[4] memory i = [p1[0], p1[1], p2[0], p2[1]];

        assembly
        {
        // call ecadd precompile
        // inputs are: x1, y1, x2, y2
            success := staticcall (not(0), 0x06, i, 0x80, retP, 0x40)
        }

        if (!success)
        {
            retP[0] = 0;
            retP[1] = 0;
        }
    }

    function extractXYFromPoint(bytes memory data) public pure returns (uint256 x, uint256 y)
    {
        assembly
        {
            x := mload(add(data, 0x21)) //copy from 33rd byte because first 32 bytes are array length, then 1st byte of data is the 0x04;
            y := mload(add(data, 0x41)) //65th byte as x value is 32 bytes.
        }
    }

    function mapTo256BitInteger(bytes memory input) public pure returns(uint256 res)
    {
        bytes32 idHash = keccak256(input);
        res = uint256(idHash);
    }

    // Note, this will return 0 if the shifted hash > curveOrder, which will cause the equate to fail
    function mapToCurveMultiplier(bytes memory input) public pure returns(uint256 res)
    {
        bytes memory nextInput = input;
        bytes32 idHash = keccak256(nextInput);
        res = uint256(idHash) >> curveOrderBitShift;
        if (res >= curveOrder)
        {
            res = 0;
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

    function decodeDERData(bytes memory byteCode, uint dIndex) internal pure returns(bytes memory data, uint256 index, uint256 length, bytes1 tag)
    {
        return decodeDERData(byteCode, dIndex, 0);
    }

    function copyDataBlock(bytes memory byteCode, uint dIndex, uint length) internal pure returns(bytes memory data)
    {
        uint256 blank = 0;
        uint256 index = dIndex;

        uint dStart = 0x20 + index;
        uint cycles = length / 0x20;
        uint requiredAlloc = length;

        if (length % 0x20 > 0) //optimise copying the final part of the bytes - remove the looping
        {
            cycles++;
            requiredAlloc += 0x20; //expand memory to allow end blank
        }

        data = new bytes(requiredAlloc);

        assembly {
            let mc := add(data, 0x20) //offset into bytes we're writing into
            let cycle := 0

            for
            {
                let cc := add(byteCode, dStart)
            } lt(cycle, cycles) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
                cycle := add(cycle, 0x01)
            } {
                mstore(mc, mload(cc))
            }
        }

        //finally blank final bytes and shrink size
        if (length % 0x20 > 0)
        {
            uint offsetStart = 0x20 + length;
            assembly
            {
                let mc := add(data, offsetStart)
                mstore(mc, mload(add(blank, 0x20)))
            //now shrink the memory back
                mstore(data, length)
            }
        }
    }

    function copyStringBlock(bytes memory byteCode) internal pure returns(string memory stringData)
    {
        uint256 blank = 0; //blank 32 byte value
        uint256 length = byteCode.length;

        uint cycles = byteCode.length / 0x20;
        uint requiredAlloc = length;

        if (length % 0x20 > 0) //optimise copying the final part of the bytes - to avoid looping with single byte writes
        {
            cycles++;
            requiredAlloc += 0x20; //expand memory to allow end blank, so we don't smack the next stack entry
        }

        stringData = new string(requiredAlloc);

        //copy data in 32 byte blocks
        assembly {
            let cycle := 0

            for
            {
                let mc := add(stringData, 0x20) //pointer into bytes we're writing to
                let cc := add(byteCode, 0x20)   //pointer to where we're reading from
            } lt(cycle, cycles) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
                cycle := add(cycle, 0x01)
            } {
                mstore(mc, mload(cc))
            }
        }

        //finally blank final bytes and shrink size (part of the optimisation to avoid looping adding blank bytes1)
        if (length % 0x20 > 0)
        {
            uint offsetStart = 0x20 + length;
            assembly
            {
                let mc := add(stringData, offsetStart)
                mstore(mc, mload(add(blank, 0x20)))
            //now shrink the memory back so the returned object is the correct size
                mstore(stringData, length)
            }
        }
    }

    function decodeDERData(bytes memory byteCode, uint dIndex, uint offset) internal pure returns(bytes memory data, uint256 index, uint256 length, bytes1 tag)
    {
        index = dIndex;

        (length, index, tag) = decodeLength(byteCode, index);

        if (offset <= length)
        {
            uint requiredLength = length - offset;
            uint dStart = index + offset;

            data = copyDataBlock(byteCode, dStart, requiredLength);
        }
        else
        {
            data = bytes("");
        }

        index += length;
    }

    function decodeElement(bytes memory byteCode, uint decodeIndex) internal pure returns(uint256 length, bytes memory content, uint256 newIndex, bytes1 tag)
    {
        (content, newIndex, length, tag) = decodeDERData(byteCode, decodeIndex);
    }

    function decodeElementOffset(bytes memory byteCode, uint decodeIndex, uint offset) internal pure returns(uint256 length, bytes memory content, uint256 newIndex)
    {
        (content, newIndex, length, ) = decodeDERData(byteCode, decodeIndex, offset);
    }

    function decodeLength(bytes memory byteCode, uint decodeIndex) internal pure returns(uint256 length, uint256 newIndex, bytes1 tag)
    {
        uint codeLength = 1;
        length = 0;
        newIndex = decodeIndex;
        tag = bytes1(byteCode[newIndex++]);

        if ((byteCode[newIndex] & 0x80) == 0x80)
        {
            codeLength = uint8((byteCode[newIndex++] & 0x7f));
        }

        for (uint i = 0; i < codeLength; i++)
        {
            length |= uint(uint8(byteCode[newIndex++] & 0xFF)) << ((codeLength - i - 1) * 8);
        }
    }

    function decodeIA5String(bytes memory byteCode, uint256[] memory objCodes, uint objCodeIndex, uint decodeIndex) internal pure returns(Status memory)
    {
        uint length = uint8(byteCode[decodeIndex++]);
        bytes32 store = 0;
        for (uint j = 0; j < length; j++) store |= bytes32(byteCode[decodeIndex++] & 0xFF) >> (j * 8);
        objCodes[objCodeIndex++] = uint256(store);
        Status memory retVal;
        retVal.decodeIndex = decodeIndex;
        retVal.objCodeIndex = objCodeIndex;

        return retVal;
    }

    struct Status {
        uint decodeIndex;
        uint objCodeIndex;
    }
}