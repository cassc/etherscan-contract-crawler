// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Dependencies.sol";
import "./OffOn.sol";


contract OffOnURI {
  using Strings for uint256;

  OffOn public baseContract;
  string public description = 'To turn the artwork off and on, go to https://steviep.xyz/offon';
  string public externalUrl = 'https://steviep.xyz/offon';
  string public license = 'CC BY-NC 4.0';

  constructor() {
    baseContract = OffOn(msg.sender);
  }

  function tokenURI(uint256) external view returns (string memory) {
    uint256 hash = baseContract.latestHash();
    string memory state = baseContract.latestHash() == 0 ? 'Off' : 'On';

    bytes memory json = abi.encodePacked(
      'data:application/json;utf8,',
      '{"name": "Have You Tried Turning It Off and On Again?",'
      '"description": "', description, '",'
      '"license": "', license, '",'
      '"external_url": "', externalUrl, '",'
      '"attributes": [{"trait_type": "State", "value": "', state,'"}, {"trait_type": "Last Turned On", "value": "', baseContract.lastTurnedOn().toString(),'"}, {"trait_type": "Last Turned Off", "value": "', baseContract.lastTurnedOff().toString(),'"}],'
      '"image": "', encodedSVG(hash),
      '"}'
    );
    return string(json);
  }

  function encodedSVG(uint256 hash) public view returns (string memory) {
    return string(abi.encodePacked(
      'data:image/svg+xml;base64,',
      Base64.encode(rawSVG(hash))
    ));
  }

  function rawSVG(uint256 hash) public view returns (bytes memory) {
    string memory bgColor = hash > 0 ? '#fff' : '#000';

    bytes memory svg = abi.encodePacked(
      '<svg viewBox="0 0 2048 2048" xmlns="http://www.w3.org/2000/svg">'
      '<rect x="0" y="0" width="2048" height="2048" fill="', bgColor, '" />'
      '<style>.blink{animation:Blink 2s steps(2,start) infinite}@keyframes Blink{to{visibility:hidden}}</style>'
    );

    if (hash > 0) {
      svg = abi.encodePacked(
        svg,
        drawSubdivision(0, 0, hash, 0, hash % 20)
      );
    }

    return abi.encodePacked(svg, '</svg>');
  }

  function drawSubdivision(
    uint256 xOff,
    uint256 yOff,
    uint256 hash,
    uint256 level,
    uint256 globalDelay
  ) public view returns (bytes memory) {
    uint256 newHash = uint256(keccak256(abi.encodePacked(
      hash, xOff, yOff
    )));

    bool drawSquare = (
      level == 0 ? hash % 10 < 1 :
      level == 4 ? newHash % 10 < 9 :
      level == 5 ? newHash % 20 < 19 :
      level == 6 ? newHash % 40 < 39 :
      level == 7 ? true :
      newHash % 10 < 2
    );

    uint256 boxSize = (2048/(2**level));
    uint256 nextBoxSize = (2048/(2**(level+1)));


    if (drawSquare) {
      return drawSubdivisionShape(xOff, yOff, boxSize, globalDelay, hash);
    } else {
      return abi.encodePacked(
        drawSubdivision(xOff, yOff, hash, level + 1, globalDelay),
        drawSubdivision(xOff + nextBoxSize, yOff, hash, level + 1, globalDelay),
        drawSubdivision(xOff, yOff + nextBoxSize, hash, level + 1, globalDelay),
        drawSubdivision(xOff + nextBoxSize, yOff + nextBoxSize, hash, level + 1, globalDelay)
      );
    }
  }

  function drawSubdivisionShape(
    uint256 xOff,
    uint256 yOff,
    uint256 boxSize,
    uint256 globalDelay,
    uint256 hash
  ) public pure returns (bytes memory) {
    uint256 localHash = uint256(
      keccak256(
        abi.encodePacked(hash, xOff, yOff)
      )
    );

    bytes memory square = abi.encodePacked(
      '<rect fill="none" x="',
      xOff.toString(),
      '" y="',
      yOff.toString(),
      '" width="',
      boxSize.toString(),
      '" height="',
      boxSize.toString(),
      '" />'
    );

    uint256 fontSize = (boxSize*7/8);
    uint256 animationDelay = localHash % 20000;

    bytes memory computer = abi.encodePacked(
      '<text class="blink" font-size="',
      fontSize.toString(),
      'px" x="',
      (xOff+(boxSize*3/64)).toString(),
      '" y="',
      (yOff+(fontSize*29/32)).toString(),
      '" style="animation-delay: calc(-2s*(',
      globalDelay.toString(),
      '/20) *',
      animationDelay.toString(),
      '/20000)">',
      unicode'🖥️',
      '</text>'
    );

    return abi.encodePacked(square, computer);
  }


  function updateMetadata(string calldata _externalUrl, string calldata _description, string calldata _license) external {
    require(msg.sender == baseContract.owner(), 'Ownable: caller is not the owner');

    externalUrl = _externalUrl;
    description = _description;
    license = _license;
  }
}
