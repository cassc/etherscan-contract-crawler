// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Dependencies.sol";
import "./Fiefdoms.sol";
import "./FiefdomArchetype.sol";

contract DefaultTokenURI {
  using Strings for uint256;

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    FiefdomArchetype fiefdom = FiefdomArchetype(msg.sender);


    bytes memory name = abi.encodePacked('Fiefdom ', fiefdom.fiefdomId().toString(), ', Token ', tokenId.toString());

    bytes memory background = abi.encodePacked(
      '<rect x="0" y="0" width="100%" height="100%" fill="#000"/>',
      '<rect x="23.78px" y="23.78px" width="1141.44" height="793.44px" fill="none" stroke="#fff" stroke-width="5"/>'
    );

    bytes memory textFiefdom = abi.encodePacked(
      '<text x="50%" y="38%" class="t">',
      'Fiefdom ',
      fiefdom.fiefdomId().toString(),
      '</text>'
    );

    bytes memory textToken = abi.encodePacked(
      '<text x="50%" y="62%" class="t">',
      'Token ',
      tokenId.toString(),
      '</text>'
    );

    bytes memory encodedImage = abi.encodePacked(
      '"data:image/svg+xml;base64,',
      Base64.encode(abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1189 841"><style>.t{font-size:160px;font-family:sans-serif;fill:#fff;dominant-baseline:middle;text-anchor:middle;}</style>',
        background,
        textFiefdom,
        textToken,
        '</svg>'
      )),
      '"'
    );


    bytes memory json = abi.encodePacked(
      'data:application/json;utf8,',
      '{"name": "', name,'",',
      '"description": "The start of something new.",',
      '"image": ', encodedImage,
      '}'
    );
    return string(json);
  }
}
