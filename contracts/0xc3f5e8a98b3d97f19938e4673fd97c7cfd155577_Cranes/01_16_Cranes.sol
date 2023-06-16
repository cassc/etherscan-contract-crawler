// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";
import "./Colors.sol";

contract Cranes is ERC721, ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;
  using Colors for Colors.Color;
  using Strings for uint256;

  uint256 public constant MAX_CRANES_PER_YEAR = 1000;
  string public constant DESCRIPTION = "Cranes are tiny, randomly generated, fully on-chain tokens of luck for special wallets. Best to keep one around, just in case.";

  uint256 public price = 0.02 ether;

  Counters.Counter private _tokenIdCounter;
  mapping(uint256 => Counters.Counter) private _yearlyCounts;
  mapping(uint256 => uint256[3]) private _seeds;

  constructor() ERC721("Cranes", "CRNS") {}

  function _mint(address destination) private {
    require(currentYearTotalSupply() <= MAX_CRANES_PER_YEAR, "YEARLY_MAX_REACHED");

    uint256 tokenId = _tokenIdCounter.current();
    uint256 destinationSeed = uint256(uint160(destination)) % 10000000;

    _safeMint(destination, tokenId);

    uint256 year = getCurrentYear();
    _yearlyCounts[year].increment();
    uint256 yearCount = _yearlyCounts[year].current();
    _seeds[tokenId][0] = year;
    _seeds[tokenId][1] = yearCount;
    _seeds[tokenId][2] = destinationSeed;

    _tokenIdCounter.increment();
  }

  function mint(address destination) public onlyOwner {
    _mint(destination);
  }

  function craftForSelf() public payable virtual {
    require(msg.value >= price, "PRICE_NOT_MET");
    _mint(msg.sender);
  }

  function craftForFriend(address walletAddress) public payable virtual {
    require(msg.value >= price, "PRICE_NOT_MET");
    _mint(walletAddress);
  }

  function setPrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
  }

  function getCurrentYear() private view returns (uint256) {
    return 1970 + block.timestamp / 31556926;
  }

  function currentYearTotalSupply() public view returns (uint256) {
    return _yearlyCounts[getCurrentYear()].current();
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    uint256[3] memory seed = _seeds[tokenId];
    string memory year = seed[0].toString();
    string memory count = seed[1].toString();
    string memory colorSeed = string(abi.encodePacked(seed[0], seed[1], seed[2]));

    string memory c0seed = string(abi.encodePacked(colorSeed, "COLOR0"));
    Colors.Color memory base = Colors.fromSeedWithMinMax(c0seed, 0, 359, 20, 100, 30, 40);
    uint256 hMin = base.hue + 359 - Colors.valueFromSeed(c0seed, 5, 60);
    uint256 hMax = base.hue + 359 + Colors.valueFromSeed(c0seed, 5, 60);
    string memory c0 = base.toHSLString();
    string memory c1 = Colors.fromSeedWithMinMax(string(abi.encodePacked(colorSeed, "COLOR1")), hMin, hMax, 70, 90, 70, 85).toHSLString();
    string memory bg = Colors.fromSeedWithMinMax(string(abi.encodePacked(colorSeed, "BACKGROUND")), 0, 359, 0, 50, 10, 100).toHSLString();

    string[43] memory parts;
    parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2048 2048" xmlns:v="https://vecta.io/nano"><defs><filter id="S" x="0" y="0"><feGaussianBlur in="SourceGraphic" stdDeviation="50"/></filter><linearGradient x1="13%" y1="99%" x2="87%" y2="21.5%" id="A"><stop stop-color="';
    parts[1] = c0;
    parts[2] = '" offset="0%"/><stop stop-color="';
    parts[3] = c1;
    parts[4] = '" offset="100%"/></linearGradient><linearGradient x1="50%" y1="92.0%" x2="61.2%" y2="79.9%" id="B"><stop stop-color="';
    parts[5] = c0;
    parts[6] = '" offset="0%"/><stop stop-color="';
    parts[7] = c1;
    parts[8] = '" offset="100%"/></linearGradient><linearGradient x1="36.3%" y1="44.3%" x2="59.0%" y2="25.9%" id="E"><stop stop-color="';
    parts[9] = c0;
    parts[10] = '" offset="0%"/><stop stop-color="';
    parts[11] = c1;
    parts[12] = '" offset="100%"/></linearGradient><linearGradient x1="-17.9%" y1="79.6%" x2="57.4%" y2="11.3%" id="F"><stop stop-color="';
    parts[13] = c0;
    parts[14] = '" offset="0%"/><stop stop-color="';
    parts[15] = c1;
    parts[16] = '" offset="100%"/></linearGradient><linearGradient x1="43.7%" y1="57.6%" x2="75.1%" y2="8.1%" id="H"><stop stop-color="';
    parts[17] = c0;
    parts[18] = '" offset="0%"/><stop stop-color="';
    parts[19] = c1;
    parts[20] = '" offset="100%"/></linearGradient><linearGradient x1="100%" y1="42.2%" x2="50%" y2="58.4%" id="I"><stop stop-color="';
    parts[21] = c0;
    parts[22] = '" offset="0%"/><stop stop-color="';
    parts[23] = c1;
    parts[24] = '" offset="100%"/></linearGradient></defs><g fill="none" fill-rule="evenodd"><path fill="';
    parts[25] = bg;
    parts[26] = '" d="M0 0h2048v2048H0z"/><polygon filter="url(#S)" fill="rgba(0,0,0,.3)" points="271 562 783 1247 1005 999 1930 643 1637 1256 1871 1510 1607 1355 1149 1775 1047 1641 55 1434 576 1195"></polygon><g><animateTransform attributeName="transform" type="translate" values="82 186;82 140;82 186" dur="4s" repeatCount="indefinite" /><path fill="url(#A)" d="M833 785l115-264 936-425-335 796-317 189z"/><path fill="url(#B)" d="M572 851L219 0l576 932z"/><path fill="';
    parts[27] = c0;
    parts[28] = '" d="M994 706l238 330-144 88z"/><path fill="';
    parts[29] = c0;
    parts[30] = '" d="M1165 1398l405-466.286L1521.949 870z"/><path d="M1550 834c20.633-11.828 63.814.701 88 30 16.124 19.533 72.457 108.199 169 266l-285-269c4.911-10.115 14.245-19.115 28-27z" fill="url(#E)"/><path d="M1063 1109l400-264c19-13 52-25 84-7 21.333 12 108 109.333 260 292l-279-216-363 484-68 41-34-330z" fill="url(#F)"/><path fill="';
    parts[31] = c0;
    parts[32] = '" d="M1097 1439l47-206-150 33z"/><path fill="url(#H)" d="M651 857l343-151 150 527z"/><path fill="url(#I)" d="M0 1035l498-267 213 62 433 403-113 52z"/></g><path fill="';
    parts[33] = c1;
    parts[34] = '" d="M0 1968h80v80H0z"/><path fill="';
    parts[35] = c0;
    parts[36] = '" d="M80 1968h80v80H80z"/></g><text font-family="ui-monospace, SFMono-Regular, Menlo, Monaco, monospace" font-size="50" font-weight="bold" fill="rgba(255,255,255,.9)" x="180" y="2023">';
    parts[37] = year;
    parts[38] = "-";
    parts[39] = count;
    parts[40] = "</text></svg>";

    string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9], parts[10]));
    output = string(abi.encodePacked(output, parts[11], parts[12], parts[13], parts[14], parts[15], parts[16], parts[17], parts[18], parts[19], parts[20]));
    output = string(abi.encodePacked(output, parts[21], parts[22], parts[23], parts[24], parts[25], parts[26], parts[27], parts[28], parts[29], parts[30]));
    output = string(abi.encodePacked(output, parts[31], parts[32], parts[33], parts[34], parts[35], parts[36], parts[37], parts[38], parts[39], parts[40]));

    output = Base64.encode(bytes(string(abi.encodePacked('{"name":"Crane #', year, "/", count, '","description":"', DESCRIPTION, '","image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
    output = string(abi.encodePacked("data:application/json;base64,", output));

    return output;
  }

  function withdrawAll() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  // The following functions are overrides required by Solidity.
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}