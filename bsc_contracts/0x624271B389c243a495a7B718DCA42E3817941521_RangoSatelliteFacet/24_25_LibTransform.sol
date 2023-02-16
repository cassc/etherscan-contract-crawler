// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library LibTransform {
    function addressToString(address a) internal pure returns (string memory) {
        bytes memory data = abi.encodePacked(a);
        bytes memory characters = '0123456789abcdef';
        bytes memory byteString = new bytes(2 + data.length * 2);

        byteString[0] = '0';
        byteString[1] = 'x';

        for (uint256 i; i < data.length; ++i) {
            byteString[2 + i * 2] = characters[uint256(uint8(data[i] >> 4))];
            byteString[3 + i * 2] = characters[uint256(uint8(data[i] & 0x0f))];
        }
        return string(byteString);
    }

    function bytesToAddress(bytes memory bs) internal pure returns (address addr) {
        return address(uint160(bytes20(bs)));
    }

    function addressToBytes32LeftPadded(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function bytes32LeftPaddedToAddress(bytes32 b) internal pure returns (address){
        return address(uint160(uint256(b)));
    }

    function stringToBytes(string memory s) internal pure returns (bytes memory){
        bytes memory b3 = bytes(s);
        return b3;
    }

    function stringToAddress(string memory s) internal pure returns (address){
        return bytesToAddress(stringToBytes(s));
    }

    function extractAddressFromEndOfBytes(bytes calldata bs) internal pure returns (address){
        if (bs.length < 20)
            return bytesToAddress(bs);
        return bytesToAddress(bs[bs.length - 20 :]);
    }

    function extractAddressWithOffsetFromEnd(bytes calldata bs, uint256 offset) internal pure returns (address){
        if (bs.length < 20 || bs.length < offset)
            return bytesToAddress(bs);
        return bytesToAddress(bs[bs.length - offset :]);
    }
}