// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./iGUA.sol";


/** @title API Contract
  * @author @0xAnimist
  * @notice A collaboration between Cai Guo-Qiang and Kanon
  */
library API {

  function guaAPI(
    uint256 _tokenId,
    uint256 _timestamp,
    uint256 _rand,
    string memory _query,
    bool _queried,
    bytes memory _guaGif,
    bytes32 _seed,
    bytes32 _queryhash
  ) public pure returns(string memory api){
    uint256 queried;
    if(_queried){
      queried = 1;
    }

    api = string(abi.encodePacked(
      '{"tokenId": ',
      Strings.toString(_tokenId),
      ', "timestamp": ',
      Strings.toString(_timestamp),
      ', "rand": ',
      Strings.toString(_rand),
      ', "query": "',
      _query,
      '"'
    ));

    api = string(abi.encodePacked(
      api,
      ', "queried": ',
      Strings.toString(queried),
      ', "guaGif": "',
      bytesToHex(_guaGif),
      '", "seed": "',
      bytesToHex(abi.encodePacked(_seed))
    ));

    api = string(abi.encodePacked(
      api,
      '", "queryhash": "',
      bytesToHex(abi.encodePacked(_queryhash)),
      '"}'
    ));

  }


  //Adapted from BytesLib
  function bytesToHex(bytes memory buffer) public pure returns (string memory) {

      // Fixed buffer size for hexadecimal convertion
      bytes memory converted = new bytes(buffer.length * 2);

      bytes memory _base = "0123456789abcdef";

      for (uint256 i = 0; i < buffer.length; i++) {
          converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
          converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
      }

      return string(abi.encodePacked(converted));
  }

  //From @goodvibration at https://ethereum.stackexchange.com/questions/90629/converting-bytes32-to-uint256-in-solidity
  function bytes32ToUint256(bytes32 x) public pure returns (uint256) {
    uint256 y;
    for (uint256 i = 0; i < 32; i++) {
        uint256 c = (uint256(x) >> (i * 8)) & 0xff;
        if (48 <= c && c <= 57)
            y += (c - 48) * 10 ** i;
        else
            break;
    }
    return y;
}




}//end API