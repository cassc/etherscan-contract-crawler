// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Dependencies.sol";
import "./Fiefdoms.sol";
import "./FiefdomArchetype.sol";

contract BaseTokenURI {
  using Strings for uint256;

  Fiefdoms private immutable fiefdoms;

  constructor() {
    fiefdoms = Fiefdoms(msg.sender);
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    bytes memory name = abi.encodePacked('Fiefdom Vassal #', tokenId.toString());
    address fiefdomAddr = fiefdoms.tokenIdToFiefdom(tokenId);

    bool isActivated = FiefdomArchetype(fiefdomAddr).isActivated();
    uint256 foundedAt = FiefdomArchetype(fiefdomAddr).foundedAt();

    string memory pColor = isActivated ? '#fff' : '#000';
    string memory sColor = isActivated ? '#000' : '#fff';
    string memory state = isActivated ? 'Activated' : 'Unactivated';

    bytes memory attributes = abi.encodePacked(
      '[{"trait_type": "Activated", "value":',
      isActivated ? '"true"' : '"false"',
      '},{"trait_type": "Fiefdom", "value": "0x',
      toString(fiefdomAddr),
      '"},{"trait_type": "Founded At", "value": "',
      foundedAt.toString(),
      '"}]'
    );


    bytes memory background = abi.encodePacked(
      '<rect x="0" y="0" width="100%" height="100%" fill="', pColor,'"/>',
      '<rect x="23.78px" y="23.78px" width="1141.44" height="793.44px" fill="none" stroke="', sColor,'" stroke-width="2"/>'
    );

    bytes memory textName = abi.encodePacked(
      '<text x="50%" y="47%" font-size="105px" fill="',
      sColor,
      '" dominant-baseline="middle" text-anchor="middle">',
      name,
      '</text>'
    );

    bytes memory textAddr = abi.encodePacked(
      '<text x="50%" y="58%" font-size="42px" fill="', sColor,'" font-family="monospace" dominant-baseline="middle" text-anchor="middle">0x',
      toString(fiefdomAddr),
      '</text>'
    );

    bytes memory encodedImage = abi.encodePacked(
      '"data:image/svg+xml;base64,',
      Base64.encode(abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1189 841">',
        background,
        textName,
        textAddr,
        '</svg>'
      )),
      '",'
    );

    bytes memory description = abi.encodePacked(
      '"',
      state,
      ' ',
      name,
      ' of 0x',
      toString(fiefdomAddr),
      '",'
    );

    bytes memory json = abi.encodePacked(
      'data:application/json;utf8,',
      '{"name": "', name,'",',
      '"description": ', description,
      '"external_url": "https://steviep.xyz/fiefdoms",'
      '"image": ', encodedImage,
      '"attributes":', attributes,
      '}'
    );
    return string(json);
  }

  function toString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2*i] = char(hi);
      s[2*i+1] = char(lo);
    }
    return string(s);
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }
}
