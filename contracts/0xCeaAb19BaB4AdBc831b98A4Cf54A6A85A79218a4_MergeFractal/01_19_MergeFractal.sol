//SPDX-License-Identifier: MIT

//   ____ ______ __  __  ____ ____   ____ __ __ ___  ___    ___  ___  ____ ____    ___   ____     ____ ____   ___    ___ ______  ___  __   
//  ||    | || | ||  || ||    || \\ ||    || || ||\\//||    ||\\//|| ||    || \\  // \\ ||       ||    || \\ // \\  //   | || | // \\ ||   
//  ||==    ||   ||==|| ||==  ||_// ||==  || || || \/ ||    || \/ || ||==  ||_// (( ___ ||==     ||==  ||_// ||=|| ((      ||   ||=|| ||   
//  ||___   ||   ||  || ||___ || \\ ||___ \\_// ||    ||    ||    || ||___ || \\  \\_|| ||___    ||    || \\ || ||  \\__   ||   || || ||__|
                                                                                                                                        
// (ASCII art font: Double, via https://patorjk.com/software/taag)

// Merge Fractal NFT developed for the Ethereum Merge event
// by David Ryan (drcoder.eth, @davidryan59 on Twitter)
// Check out some more of my fractal art at Nifty Ink!
// My artist page for niftymaestro.eth: https://nifty.ink/artist/0xbFAc61D1e22EFA9d37Fc3Ff36B9dff9655131F52

pragma solidity ^0.6.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
// Learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

import './SharedFnsAndData.sol';
import './FractalStrings.sol';


contract MergeFractal is ERC721, Ownable {

  // all ETH from NFT sales goes to https://app.0xsplits.xyz/accounts/0xF29Ff96aaEa6C9A1fBa851f74737f3c069d4f1a9/
  address payable public constant recipient =
    payable(0xF29Ff96aaEa6C9A1fBa851f74737f3c069d4f1a9);

  // ----------------------------------------------

  // // Local testnet setup
  // string internal constant NETWORK = 'TESTNET 12';
  // uint256 internal constant INITIAL_PRICE = 1000000 * 1000000000; // 0.001 ETH
  // uint256 internal constant INCREMENT_PRICE = 200000 * 1000000000; // 0.0002 ETH
  // uint256 internal constant INCREMENT_STEP = 2;
  // uint24 internal constant MINT_LIMIT = 5;

  // // Goerli test deployment(s)
  // string internal constant NETWORK = 'GOERLI TEST 14';
  // uint256 internal constant INITIAL_PRICE = 1000000 * 1000000000; // 0.001 ETH
  // uint256 internal constant INCREMENT_PRICE = 200000 * 1000000000; // 0.0002 ETH
  // uint256 internal constant INCREMENT_STEP = 1;
  // uint24 internal constant MINT_LIMIT = 2;

  // Mainnet deployment
  string internal constant NETWORK = 'Ethereum';
  uint256 internal constant INITIAL_PRICE = 1000000 * 1000000000; // 0.001 ETH
  uint256 internal constant INCREMENT_PRICE = 200000 * 1000000000; // 0.0002 ETH
  uint256 internal constant INCREMENT_STEP = 50; // increments at 51, 101, 151, 201...
  uint24 internal constant MINT_LIMIT = 5875;

  // ----------------------------------------------

  // Control placement of 4 sets of rotating lines
  uint8[4] internal sectionLineTranslates = [2, 4, 36, 38];

  // Random team to thank, looks up from core dev
  uint8 internal constant TEAM_ARRAY_LEN = 25;
  string[TEAM_ARRAY_LEN] internal teams = [
    'Independent', // hidden
    '0xSplits', // hidden
    'Akula',
    'EF DevOps',
    'EF Geth',
    'EF Ipsilon',
    'EF JavaScript',
    'EF Portal',
    'EF Protocol Support',
    'EF Research',
    'EF Robust Incentives Group',
    'EF Security',
    'EF Solidity',
    'EF Testing',
    'Erigon',
    'Ethereum Cat Herders',
    'Hyperledger Besu',
    'Lighthouse',
    'Lodestar',
    'Nethermind',
    'Prysmatic',
    'Quilt',
    'Status',
    'Teku',
    'TXRX'
  ];

  // Random subtitle
  uint8 internal constant SUBTITLE_ARRAY_LEN = 30;
  string[SUBTITLE_ARRAY_LEN] internal subtitles = [
    'Ethereum Merge September 2022',
    'TTD 58750000000000000000000',
    'Proof-of-stake consensus',
    'Environmentally friendly',
    'Energy consumption -99.95%',
    'Unstoppable smart contracts',
    'Sustainable and secure',
    'Global settlement layer',
    'World Computer',
    'Run your own node',
    'Permissionless',
    'TTD 5.875 * 10^22',
    'Run your own validator',
    'Neutral settlement layer',
    'Validators > Miners',
    'Decentralise Everything',
    'PoS > PoW',
    'Validate with 32 ETH',
    'The Flippening',
    'Fight for financial privacy by default',
    'TTD 2^19 * 5^22 * 47',
    'Build on Scaffold Eth',
    'Build with the Buidl Guidl',
    'Austin Griffith is Buidling',
    'Owocki and Gitcoin are coordinating',
    'Superphiz has decentralised everything',
    'Bankless is trustless',
    'Vitalik is clapping',
    'Vitalik is dancing',
    'Anthony Sassano is dancing'
  ];

  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  SharedFnsAndData sfad;
  FractalStrings fs;
  constructor(address sfadAddress, address fsAddress) public ERC721("MergeFractals", "MERGFRAC") {
    // Using 3 contracts since there was too much for 1 contract...
    sfad = SharedFnsAndData(sfadAddress);
    fs = FractalStrings(fsAddress);
  }

  mapping (uint256 => uint256) internal generator;
  mapping (uint256 => address) internal mintooor;

  function mintItem()
    public
    payable
    returns (uint256)
  {
    require(isMintingAllowed(), "MINT LIMIT REACHED"); 
    require(msg.value == getPriceNext(), "NEED TO SEND ETH");
    _tokenIds.increment();
    uint256 id = _tokenIds.current(); // previous mintCount + 1
    _mint(msg.sender, id);
    generator[id] = uint256(keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), id)));
    mintooor[id] = msg.sender;
    // Send proceeds of NFT sales to fixed recipient
    (bool success, ) = recipient.call{value: msg.value}("");
    require(success, "ETH TO RECIPIENT FAIL");
    return id;
  }

  // Query the mint limit
  function mintLimit() public pure returns (uint24) {
    return MINT_LIMIT;
  }

  // Query the current mint count
  function mintCount() public view returns (uint24) {
    return uint24(_tokenIds.current());
  }

  // Check if minting is allowed, and has not finished
  function isMintingAllowed() public view returns (bool) {
    return _tokenIds.current() < MINT_LIMIT;
  }

  // Linear increments of mint price at certain ids
  function getPriceById(uint256 id) public pure returns (uint256) {
    return INITIAL_PRICE + INCREMENT_PRICE * ((id - 1) / INCREMENT_STEP);
  }

  // Call this function before minting to get mint price
  function getPriceNext() public view returns (uint256) {
    return getPriceById(_tokenIds.current() + 1);
  }

  function getAttribute(string memory attribType, string memory attribValue, string memory suffix) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type": "',
      attribType,
      '", "value": "',
      attribValue,
      '"}',
      suffix
    ));
  }

  function getAllAttributes(uint256 id) public view returns (string memory) {
    uint256 gen = generator[id];
    return string(abi.encodePacked(
      '[',
      getAttribute("Dev", getCoreDevName(id), ','),
      getAttribute("Team", getTeamName(id), ','),
      getAttribute("Subtitle", getSubtitle(gen), ','),
      getAttribute("Style", fs.styleText(gen), ','),
      getAttribute("Dropouts", sfad.uint2str(fs.countDropouts(gen)), ','),
      getAttribute("Twists", sfad.uint2str(fs.getTwistiness(gen)), ','),
      getAttribute("Duration", sfad.uint2str(fs.getAnimDurS(gen)), ','),
      getAttribute("Monochrome", sfad.isMonochrome(gen) ? 'Yes' : 'No', ']')
    ));
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), "not exist");
    string memory name = string(abi.encodePacked(NETWORK, ' Merge Fractal #',id.toString()));
    string memory description = string(abi.encodePacked(
      'This ',
      NETWORK,
      ' Merge Fractal is to thank ',
      getCoreDevName(id),
      '!'
    ));
    string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

    return string(abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(bytes(abi.encodePacked(
        '{"name":"',
        name,
        '", "description":"',
        description,
        '", "external_url":"https://ethereum-merge-fractals.surge.sh/token/',
        id.toString(),
        '", "attributes": ',
        getAllAttributes(id),
        ', "owner":"',
        sfad.toHexString(uint160(ownerOf(id)), 20),
        '", "image": "data:image/svg+xml;base64,',
        image,
        '"}'
      )))
    ));
  }

  function generateSVGofTokenById(uint256 id) public view returns (string memory) {
    return string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));
  }

  function renderDisk(uint256 gen) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<circle fill="',
      sfad.getRGBA(gen, 3, "1"),
      '" cx="200" cy="200" r="200"/>'
    ));
  }

  function getLinesTransform(uint8 arraySection) internal view returns (string memory) {
    uint16 num1 = sectionLineTranslates[arraySection];
    return string(abi.encodePacked(
      ' transform="translate(',
      sfad.uint2str(num1),
      ' ',
      sfad.uint2str(num1),
      ') scale(0.',
      sfad.uint2str(200 - num1),
      ')"'
    ));
  }

  // Uses 6 random bits per line set / section
  function renderLines(uint256 gen, uint8 arraySection, string memory maxAngleText) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; ',
      maxAngleText,
      ' 200 200; 0 200 200"',
      sfad.getDurText(gen, arraySection),
      ' repeatCount="indefinite"/><path fill="none" stroke-linecap="round" stroke="',
      sfad.getRGBA(gen, arraySection, "0.90"),
      '" stroke-width="9px"',
      sfad.getLinesPath(),
      getLinesTransform(arraySection),
      '/></g>'
    ));
  }

  function renderDiskAndLines(uint256 gen) internal view returns (string memory) {
    return string(abi.encodePacked(
      renderDisk(gen),
      renderLines(gen, 0, "-270"),
      renderLines(gen, 1, "270"),
      renderLines(gen, 2, "-180"),
      renderLines(gen, 3, "180")
    ));
  }

  function renderBorder(uint256 gen) internal view returns (string memory) {
    string memory rgba0 = sfad.getRGBA(gen, 0, "0.9");
    return string(abi.encodePacked(
      '<circle r="180" stroke-width="28px" stroke="',
      sfad.getRGBA(gen, 3, "0.8"),
      '" fill="none" cx="200" cy="200"/><circle r="197" stroke-width="6px" stroke="',
      rgba0,
      '" fill="none" cx="200" cy="200"/><circle r="163" stroke-width="6px" stroke="',
      rgba0,
      '" fill="none" cx="200" cy="200"/>'
    ));
  }

  function getCoreDevIdx(uint256 id) internal view returns (uint8 idx) {
    return sfad.getUint8(generator[id], 0, 8) % sfad.getCoreDevArrayLen();
  }

  function getTeamIdx(uint256 id) internal view returns (uint8 idx) {
    return sfad.getCoreDevTeamIndex(getCoreDevIdx(id));
  }

  function getCoreDevName(uint256 id) internal view returns (string memory) {
    return sfad.getCoreDevName(getCoreDevIdx(id));
  }

  function getTeamName(uint256 id) internal view returns (string memory) {
    return teams[getTeamIdx(id)];
  }

  function getCoreDevAndTeamText(uint256 id) internal view returns (string memory) {
    string memory teamText = string(abi.encodePacked(' / ', getTeamName(id)));
    if (getTeamIdx(id) < 2) { // If team = Individual or 0xSplits, don't display team
      teamText = '';
    }
    return string(abi.encodePacked(
      getCoreDevName(id),
      teamText
    ));   
  }

  // Earlier subtitles in the array are common. Later ones are increasingly rare.
  function getSubtitle(uint256 gen) internal view returns (string memory) {
    uint8 rand1 = sfad.getUint8(gen, 172, 5) % SUBTITLE_ARRAY_LEN;
    uint8 rand2 = sfad.getUint8(gen, 177, 5) % SUBTITLE_ARRAY_LEN;
    uint8 idx = (rand1 < rand2) ? rand1 : rand2; // min function 
    return subtitles[idx];
  }

  function renderText(uint256 id) internal view returns (string memory) {
    uint256 gen = generator[id];
    return string(abi.encodePacked(
      '<defs><style>text{font-size:15px;font-family:Helvetica,sans-serif;font-weight:900;fill:',
      sfad.getRGBA(gen, 0, "1"),
      ';letter-spacing:1px}</style><path id="textcircle" fill="none" stroke="rgba(255,0,0,0.5)" d="M 196 375 A 175 175 270 1 1 375 200 A 175 175 90 0 1 204 375" /></defs>',
      '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; 360 200 200" dur="120s" repeatCount="indefinite"/><text><textPath href="#textcircle">/ ',
      NETWORK,
      ' Merge Fractal #',
      sfad.uint2str(id),
      ' / ',
      getCoreDevAndTeamText(id),
      ' / ',
      getSubtitle(gen),
      ' / Minted by ',
      sfad.toHexString(uint160(mintooor[id]), 20),
      '♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦</textPath></text></g>'
    ));  
  }

  function renderTokenById(uint256 id) public view returns (string memory) {
    uint256 gen = generator[id];
    return string(abi.encodePacked(
      renderDiskAndLines(gen),
      renderBorder(gen),
      renderText(id),
      fs.renderEthereums(gen)
    ));
  }
}