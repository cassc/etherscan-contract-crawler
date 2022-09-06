// SPDX-License-Identifier: MIT

/**

* MIT License
* ===========
*
* Copyright (c) 2022 OLegacy
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
*/

pragma solidity 0.8.13;

abstract contract Addons {

    /* @notice Find signer
     * @param message The message that user signed
     * @return address Signer of message
     */
    function getSigner(bytes32 message, bytes memory _signature)
    public
    pure
    returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, message));
        address signer = ecrecover(prefixedHash, v, r, s);
        return signer;
    }

    /* @notice Split signature to r s v
     * @param sig signature
     */
    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
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

    /* @notice Convert bytes32 to bytes type
     * @param _bytes32 The message that need to convert
     * @return bytesArray converted bytes
     */
    function bytes32ToBytes(bytes32 _bytes32) public pure returns (bytes memory){
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return bytesArray;
    }

    /* @notice Convert bytes32 to string type
     * @param _bytes32 The message that need to convert
     */
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory){
        bytes memory bytesArray = bytes32ToBytes(_bytes32);
        return string(bytesArray);
    }

    /* @notice encode array of hashes
     * @param hashes array of bytes32
     * @return output encoded array
     */
    function encodeTightlyPacked(bytes32[] memory hashes) public pure returns(bytes memory output) {
        for (uint256 i = 0; i < hashes.length; i++) {
            output = abi.encodePacked(output, hashes[i]);
        }
        return output;
    }

}