// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { NameEncoder } from "./libraries/NameEncoder.sol";
import { IENSReverseRecords } from "./interfaces/IENSReverseRecords.sol";
import { INounsDescriptor } from "./interfaces/INounsDescriptor.sol";
import { INounsSeeder } from "./interfaces/INounsSeeder.sol";

contract ENounsRender is Ownable {
  using NameEncoder for string;

  string private constant ENCODING = "data:image/svg+xml;base64,";

  /// @notice NounsDescriptor instance
  address private immutable _nounsDescriptor;

  /// @notice ENSReverseRecords instance
  address private immutable _ensReverseRecords;

  constructor(address nounsDescriptor, address ensReverseRecords) public {
    _nounsDescriptor = nounsDescriptor;
    _ensReverseRecords = ensReverseRecords;
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  function render(bytes memory input) external view returns (string memory) {
    bytes32 _seedEntropy = abi.decode(input, (bytes32));
    return
      string.concat(
        ENCODING,
        INounsDescriptor(_nounsDescriptor).generateSVGImage(_generateSeed(uint256(_seedEntropy)))
      );
  }

  function renderUsingAddress(address user) external view returns (string memory) {
    return
      string.concat(
        ENCODING,
        INounsDescriptor(_nounsDescriptor).generateSVGImage(
          _generateSeed(_generateInputFromAddress(user))
        )
      );
  }

  function renderUsingEnsName(string memory ensName) external view returns (string memory) {
    return
      string.concat(
        ENCODING,
        INounsDescriptor(_nounsDescriptor).generateSVGImage(
          _generateSeed(_generateInputFromName(ensName))
        )
      );
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _generateInputFromAddress(address _address) internal view returns (uint256) {
    string memory toEnsName_ = _reverseName(_address);
    return uint256(_encodeName(toEnsName_));
  }

  function _generateInputFromSeed(bytes32 _seed) internal view returns (uint256) {
    return uint256(_seed);
  }

  function _generateInputFromName(string memory _ensName) internal pure returns (uint256) {
    return uint256(_encodeName(_ensName));
  }

  function _encodeName(string memory _name) internal pure returns (bytes32) {
    (, bytes32 _node) = _name.dnsEncodeName();
    return _node;
  }

  function _reverseName(address _address) internal view returns (string memory) {
    address[] memory t = new address[](1);
    t[0] = _address;
    return IENSReverseRecords(_ensReverseRecords).getNames(t)[0];
  }

  function _generateSeed(uint256 _pseudorandomness)
    private
    view
    returns (INounsSeeder.Seed memory)
  {
    uint256 backgroundCount = INounsDescriptor(_nounsDescriptor).backgroundCount();
    uint256 bodyCount = INounsDescriptor(_nounsDescriptor).bodyCount();
    uint256 accessoryCount = INounsDescriptor(_nounsDescriptor).accessoryCount();
    uint256 headCount = INounsDescriptor(_nounsDescriptor).headCount();
    uint256 glassesCount = INounsDescriptor(_nounsDescriptor).glassesCount();

    return
      INounsSeeder.Seed({
        background: uint48(uint48(_pseudorandomness) % backgroundCount),
        body: uint48(uint48(_pseudorandomness >> 48) % bodyCount),
        accessory: uint48(uint48(_pseudorandomness >> 96) % accessoryCount),
        head: uint48(uint48(_pseudorandomness >> 144) % headCount),
        glasses: uint48(uint48(_pseudorandomness >> 192) % glassesCount)
      });
  }

  function generate(uint256 _tokenId, string memory _alias) public view returns (string memory) {
    return string("");
  }
}