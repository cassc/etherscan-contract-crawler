//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './SVG.sol';
import './Utils.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import './Base64.sol';

struct Coord {
  uint256 x;
  uint256 y;
}

struct Size {
  uint256 width;
  uint256 height;
}

struct SquirclePoints {
  Coord a;
  Coord b;
  Coord c;
  Coord d;
  uint256 pull;
}

contract Orb is ERC721, Ownable {
  uint16 private _tokenTokenIdMax = 769;
  uint256 private _price = 0.0 ether;
  bool private _paused = true;
  bool private _enableListMintPaused = true;
  address payable private adminWallet =
    payable(0x9011Eb570D1bE09eA4d10f38c119DCDF29725c41);

  uint16 private constant CANVAS_SIZE = 1200;
  mapping(address => uint8) private _enableList;
  string constant JSON_PROTOCOL_URI = 'data:application/json;base64,';
  string constant SVG_PROTOCOL_URI = 'data:image/svg+xml;base64,';
  uint256 private _lastMintedTokenId = 0;

  mapping(uint256 => uint256) public seeds;

  constructor() ERC721("Markov's Dream: Orb (lite)", 'MDO') {}

  function getMaxRings(uint256 seed) private pure returns (uint8) {
    return 10 + utils.randomUint8(seed + 0xff0ff) / 24;
  }

  function getMargin(uint256 seed) private pure returns (uint8) {
    return uint8(CANVAS_SIZE / 2 / getMaxRings(seed));
  }

  function squircle(
    Coord memory position,
    Size memory size,
    uint8 inst,
    uint256 seed
  ) private pure returns (string memory) {
    if (inst > getMaxRings(seed)) return '';
    SquirclePoints memory points = calculatePoints(size.width, seed);

    return
      string.concat(
        svg.el(
          'path',
          string.concat(
            svg.prop(
              'fill',
              string.concat(
                'url(&quot;#p',
                utils.uint2str((inst - 1) % getPaletteSize(seed)),
                '&quot;)'
              )
            ),
            svg.prop(
              'd',
              string.concat(
                'M',
                coordString(points.a.x + position.x, points.a.y + position.y),
                _squircleC(position, points),
                _squircleS(position, points)
              )
            )
          )
        ),
        nestedSquircle(size.width, inst, inst == 1 ? 0 : getMargin(seed), seed)
      );
  }

  function getPaletteSize(uint256 seed) public pure returns (uint8) {
    uint8 count = utils.randomUint8(seed + 666) / 8 + 1;
    if (count > getMaxRings(seed)) return getMaxRings(seed);
    return count;
  }

  function nestedSquircle(
    uint256 size,
    uint8 inst,
    uint256 margin,
    uint256 seed
  ) private pure returns (string memory) {
    uint256 newSize = size - getMargin(seed) * 2;
    return
      svg.el(
        'svg',
        string.concat(
          svg.prop('x', utils.uint2str(margin)),
          svg.prop('y', utils.uint2str(margin))
        ),
        svg.el(
          'g',
          '',
          string.concat(
            animateTransform(newSize, seed, inst),
            squircle(
              Coord({x: getMargin(seed), y: getMargin(seed)}),
              Size({width: newSize, height: newSize}),
              inst + 1,
              seed
            )
          )
        )
      );
  }

  function animateTransform(
    uint256 width,
    uint256 seed,
    uint8 inst
  ) private pure returns (string memory) {
    uint256 center = (width + getMargin(seed) * 2) / 2;
    string memory centerString = utils.uint2str(center);
    uint8 duration = utils.randomUint8(seed / inst) / 4 + 8;

    return
      string.concat(
        '<animateTransform attributeName="transform" type="rotate" from="0 ',
        centerString,
        ' ',
        centerString,
        '" to="',
        utils.randomUint8(seed + 1001 + inst) > 128 ? '-' : '',
        '360 ',
        centerString,
        ' ',
        centerString,
        '" dur="',
        utils.uint2str(duration),
        's" repeatCount="indefinite"/>'
      );
  }

  function _squircleC(Coord memory position, SquirclePoints memory points)
    private
    pure
    returns (string memory)
  {
    return
      string.concat(
        'C',
        coordString(points.a.x + position.x, points.pull + position.y),
        coordString(points.pull + position.x, points.b.y + position.y),
        coordString(points.b.x + position.x, points.b.y + position.y)
      );
  }

  function _squircleS(Coord memory position, SquirclePoints memory points)
    private
    pure
    returns (string memory)
  {
    return
      string.concat(
        'S',
        coordString(points.c.x + position.x, points.pull + position.y),
        coordString(points.c.x + position.x, points.c.y + position.y),
        coordString(
          points.c.x - points.pull + position.x,
          points.d.y + position.y
        ),
        coordString(points.d.x + position.x, points.d.y + position.y),
        coordString(
          points.a.x + position.x,
          points.d.y - points.pull + position.y
        ),
        coordString(points.a.x + position.x, points.a.y + position.y)
      );
  }

  function getPullDiv(uint256 seed) private pure returns (uint8) {
    if (utils.randomUint8(seed + 0x8f0ff) > 220) {
      return 4;
    }
    uint8 rings = getMaxRings(seed);
    if (rings > 20) {
      return 5;
    }
    if (rings > 13) {
      return 6;
    }
    return 7;
  }

  function curveString(uint256 seed) private pure returns (string memory) {
    uint8 curve = getPullDiv(seed);
    if (curve == 4) {
      return 'light';
    }
    if (curve == 5) {
      return 'mild';
    }
    if (curve == 6) {
      return 'strong';
    }
    return 'extreme';
  }

  function calculatePoints(uint256 size, uint256 seed)
    private
    pure
    returns (SquirclePoints memory)
  {
    return
      SquirclePoints({
        a: Coord({x: 0, y: size / 2}),
        b: Coord({x: size / 2, y: 0}),
        c: Coord({x: size, y: size / 2}),
        d: Coord({x: size / 2, y: size}),
        pull: size / getPullDiv(seed)
      });
  }

  function coordString(uint256 x, uint256 y)
    private
    pure
    returns (string memory)
  {
    return string.concat(utils.uint2str(x), ',', utils.uint2str(y), ' ');
  }

  function defs(uint256 seed) private pure returns (string memory) {
    return svg.el('defs', '', linearGradientRefs(seed));
  }

  function linearGradientRefs(uint256 seed)
    private
    pure
    returns (string memory)
  {
    string memory result = '';
    uint8[3] memory bias = getBias(seed);
    for (uint8 i = 0; i < getMaxRings(seed); i++) {
      result = string.concat(result, linearGradientRef(i, seed, bias));
    }
    return result;
  }

  function getBias(uint256 seed) private pure returns (uint8[3] memory) {
    uint8 bias = utils.randomUint8(seed + 11);
    if (bias > 191) return [10, 20, 16]; // warm
    if (bias > 127) return [13, 13, 10]; // cold
    if (bias > 64) return [10, 10, 10]; // unbiased
    return [10, 13, 12]; // reddish
  }

  function getBiasString(uint256 seed) public pure returns (string memory) {
    uint8 bias = utils.randomUint8(seed + 11);
    if (bias > 191) return 'horny';
    if (bias > 127) return 'deep';
    if (bias > 64) return 'innocent';
    return 'vivid';
  }

  function randomColor(uint256 seed, uint8[3] memory bias)
    private
    pure
    returns (string memory)
  {
    return
      string.concat(
        'rgba(',
        utils.uint2str((utils.randomUint8(seed) / bias[0]) * 10),
        ',',
        utils.uint2str((utils.randomUint8(seed + 10) / bias[1]) * 10),
        ',',
        utils.uint2str((utils.randomUint8(seed + 20) / bias[2]) * 10),
        ',0.',
        utils.uint2str(utils.randomUint8(seed + 30)),
        ')'
      );
  }

  function linearGradientRef(
    uint8 id,
    uint256 seed,
    uint8[3] memory bias
  ) private pure returns (string memory) {
    return
      svg.el(
        'linearGradient',
        string.concat(
          svg.prop('id', string.concat('p', utils.uint2str(id))),
          svg.prop('x2', '0'),
          svg.prop('y2', '1')
        ),
        string.concat(
          svg.el(
            'stop',
            string.concat(
              svg.prop('stop-color', randomColor(seed + 100 + id, bias)),
              svg.prop('offset', '0')
            )
          ),
          svg.el(
            'stop',
            string.concat(
              svg.prop('stop-color', randomColor(seed + 200 + id, bias)),
              svg.prop('offset', '1')
            )
          )
        )
      );
  }

  function render(uint256 seed) public pure returns (string memory) {
    return
      string.concat(
        '<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="1200" viewBox="0 0 1200 1200">',
        defs(seed),
        squircle(
          Coord({x: 0, y: 0}),
          Size({width: CANVAS_SIZE, height: CANVAS_SIZE}),
          1,
          seed
        ),
        '</svg>'
      );
  }

  function getSVG(uint256 seed) public pure returns (string memory) {
    return Base64.encode(abi.encodePacked(render(seed)));
  }

  function example() external pure returns (string memory) {
    return
      render(
        12092617800810096820759526468342665250412819988344321001321974471951203194760
      );
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      'ERC721Metadata: URI query for nonexistent token'
    );

    bytes memory image = abi.encodePacked(
      SVG_PROTOCOL_URI,
      getSVG(seeds[tokenId])
    );

    bytes memory json = abi.encodePacked(
      '{"name":"',
      'Orb (lite) #',
      utils.uint2str(tokenId),
      '",',
      '"description":"On-chain rotating nested squircles by Harm van den Dorpel, 2022",',
      '"image":"',
      image,
      traitsString(seeds[tokenId]),
      '"}]}'
    );
    return string(abi.encodePacked(JSON_PROTOCOL_URI, Base64.encode(json)));
  }

  function traitsString(uint256 seed) private pure returns (bytes memory) {
    return
      abi.encodePacked(
        '","attributes":[{"trait_type":"Colours","value":"',
        utils.uint2str(getPaletteSize(seed)),
        '"},{"trait_type": "Temperament", "value": "',
        getBiasString(seed),
        '"},{"trait_type":"Rings","value":"',
        utils.uint2str(getMaxRings(seed)),
        '"},{"trait_type":"Curve","value":"',
        curveString(seed)
      );
  }

  function mint(address recipient) external payable {
    require(!_paused, 'not activated yet');
    require(msg.value >= _price, 'send more ether');
    
    _mint(recipient);
    adminWallet.transfer(msg.value);
  }

  function _mint(address recipient) private {
    require(_lastMintedTokenId < _tokenTokenIdMax, 'all minted');
    _lastMintedTokenId = _lastMintedTokenId + 1;
    uint256 sender = uint256(uint160(address(msg.sender)));
    seeds[_lastMintedTokenId] =
      uint256(blockhash(block.number - 1)) +
      sender +
      _lastMintedTokenId;
    _safeMint(recipient, _lastMintedTokenId);
  }

  function setTokenIdMax(uint16 newTokenIdMax) external onlyOwner {
    _tokenTokenIdMax = newTokenIdMax;
  }

  function setPaused(bool newPaused) external onlyOwner {
    _paused = newPaused;
  }

  function setEnableListPaused(bool newPaused) external onlyOwner {
    _enableListMintPaused = newPaused;
  }

  function adminMint(address recipient) external onlyOwner {
    _mint(recipient);
  }

  function updateAdminWallet(address payable _adminWallet) external onlyOwner {
    adminWallet = _adminWallet;
  }

  function setPrice(uint256 newPrice) external onlyOwner {
    _price = newPrice;
  }

  function getPrice() public view returns (uint256) {
    return _price;
  }

  function totalSupply() public view returns (uint256) {
    return _lastMintedTokenId;
  }

  function setEnableListMultiple(address[] memory recipients, uint8 count)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < recipients.length; i++) {
      _enableList[recipients[i]] = count;
    }
  }

  function setEnableList(address recipient, uint8 count) external onlyOwner {
    _enableList[recipient] = count;
  }

  function getEnableList(address recipient) external view returns (uint8) {
    return _enableList[recipient];
  }

  function mintFromEnableList(address recipient) external payable {
    require(!_enableListMintPaused, 'enableList paused');
    require(_enableList[recipient] > 0, 'no credits on enablelist');
    require(msg.value >= _price, 'send more ether');

    _mint(recipient);
    _enableList[recipient] -= 1;
    adminWallet.transfer(msg.value);
  }
}