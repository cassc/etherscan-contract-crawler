// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


library LibValidator {

  function cchar(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }


  function addressToAsciiString(address _addr) internal pure returns (string memory) {

    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint(uint160(_addr)) / (2**(8*(19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2*i] = cchar(hi);
        s[2*i+1] = cchar(lo);            
    }
    return string(abi.encodePacked("0x",s));
  }

}