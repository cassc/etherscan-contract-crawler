//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

// TODO : remove
import "hardhat/console.sol";

abstract contract BasicRNG {
  uint256 private _nonces;

  ///@notice generate 'random' bytes
  function randomBytes() internal returns (bytes32) {
    // console.log("coinbase ",block.coinbase);
    // console.log("difficulty ", block.difficulty);
    // console.log("_nonces ",_nonces);
    return keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, _nonces++));
  }

  ///@notice generate a 'random' number < mod
  function random(uint256 mod) internal returns (uint256) {
    bytes32 randBytes = randomBytes();
    return uint256(randBytes) % mod;
  }

  ///@notice generate a 'random' array of uint16 with number < mod
  function randomUint16Array(uint256 size, uint256 mod) internal returns (uint256[] memory) {
    require(size <= 16, "Exceed max size 16");
    require(mod <= type(uint16).max, "Exceed max uint16");
    bytes32 randBytes = randomBytes();
    uint256[] memory output = new uint256[](size);

    //console.logBytes32(randBytes);

    for (uint256 i; i < size; ++i) {
      output[i] = uint256(randBytes >> (i * 16)) % mod;
      //console.log(output[i]);
    }
    return output;
  }

  ///@notice generate a 'random' array of bool of defined size 50%/50%
  function randomBoolArray(uint256 size) internal returns (bool[] memory ) {
    require(size <= 256, "Exceed max size : 256");
    bool[] memory output = new bool[](size);
    uint256 rand = uint256(randomBytes());
    for (uint256 i; i < size; i++) output[i] = (rand >> i) & 1 == 1;
    return output;
  }
}