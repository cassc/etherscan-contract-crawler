//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

// ........................................................................................................................
// ........................................................................................................................
// ........................................................................................................................
// .......................................................   ..............................................................
// .................................................................   .........   ........................................
// ..............................................  ...............       ..................................................
// ...........................................        ..............   ....................................................
// ..............................................  .......................................  ...............................
// ..................................................(@@@@@@@@@@@@@@@@@@@@@@@@@@@@(....        ............................
// [email protected]@(         ,,,,,,,,,,/////////%@@.....  ...............................
// [email protected]@(       ,,,,,,,,,,,,,,///////%@@......................................
// [email protected]@@&&&&&&&//////////////%&&&&&&@@@......................................
// ..................................................(@@/////,,,,,,,,,,,,,,/////@@(........................................
// [email protected]@#////*,,,,,,,,,////#@@,..........................................
// .......................................................%@@/////,,,,*////&@%.............................................
// ........................................,@@@@%...........,@@(/////////@@/...............................................
// ......................................(@@////#@@............&@@////%@@...........,@@@@%.................................
// [email protected]@%((##(((//@@(,,.........,@@@@(.........,,#@@##((#@@...............................
// [email protected]@%(#@@#((////%@@[email protected]@%(#@@#(#@@...............................
// [email protected]@%(#@@@@&((//#&&**,................,*/&&(/(#%@@#(#@@...............................
// [email protected]@%(#@@@@@%%/////@@(****************%&%((((&@@@@#(#@@...............................
// [email protected]@%(#@@@@@@@(((//%%%%%&&&&&%%&&&&&%%(/(##%%&@@&&%%%##...............................
// [email protected]@%(#@@@@@@@((//////////(((////(((((///((@@@@@((@@%.................................
// [email protected]@&##%%@@@@@//////////**(((((***//(((((((##%%%((@@%.................................
// [email protected]@%//((@@&##(((/////////***(((((((*******(((((((@@%.................................
// [email protected]@%((**///*******((////////****/((((/////****/@@**,.................................
// .................................*@@/****((((((((((((@@@@@@@(///////****&@@@@#((((@@,...................................
// .................................*@@((((/*******((%@@  %@@##@@&///////@@%#%@@@@%((//@@%.................................
// ...............................%@&((*****/////((@@(    %@@  &@@///////((. *@@. (@@//@@%.................................
// ...............................%@&**//////////((       %@@((@@@((//(((//((%@@.    //@@%.................................
// ...............................%@&////////////((((,    /((//@@@(((((((/////((     ////#@@...............................
// [email protected]@#/////////((*,,,,((((((((((((((((((((((,,*//(((((((((//#@@...............................
// [email protected]@#//////(((,,,,,,,,,/(((((((((,,,,,,,,,,,,,,*//((((((((((//@@#............................
// [email protected]@%((((((/,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//((((((((((@@#............................
// [email protected]@(******/((((*,,,,(((((,,,,,,,,,,,,@@@@@@@@@@@@,,*//((/////@@#............................
// ...............................%@&//((/,,,,,,,,,(((((,,,,,,,,,,,,%&@@@@@@@@&&,,*//(((((((@@#............................
// ...............................%@&****///((*,,,,,,,,,(((((,,,,,,,,,(&&@@&&#,,,,*//((//#@@...............................
// ...............................%@&((((/**,,,,,,,,,,,,,,/((((((((((((((&&#(/,,%&#((((((#@@...............................
// [email protected]@#////((((((((((((,,,,,,,,,,&&&&&&&&&&&&&&&&&&&#((((((@@%.................................
// [email protected]@#////(((((**//*,,,,,,,,,,,,,,,,*&&/*/((**#&#,,(((((//@@%.................................
// [email protected]@%((//(((((**///**(((((((*,,,,,,*&&/*/((**#&%(((((((((@@%.................................
// ..........................(@@(((((//(((((**///(((((((,,,,,,,,,*%%///////#&%(((((////((#@@...............................
// ..........................(@@///////(((((**///**((/(((((((,,,,,,,%&&&&&&#((((/////((((#@@...............................
// ..........................(@@/////((((/**/////**/////,,,,,,,,,,,,,,,,,,,,,*((((((((((((//@@#............................
// ........................**#&&/////((((/**//***((((/////*,,**,,,,,,,,,,,,,**(((((((((/////&&#**..........................
// [email protected]@%(((((((//**///**////////////***//,,,,,,,,,,,,/(((((((((//((///**#@@..........................
// [email protected]@%/////////////*///(//////((**,,,,,,,,,,,,,,,,,**/(((((((//(((**//(%%##*.......................
// [email protected]@%/////////**//////////(((//*****//,,,,,,,,,,,,//((((////((////////**@@/.......................

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract MoonRunners is ERC721AQueryable, ERC721ABurnable, Ownable {
  using EnumerableSet for EnumerableSet.UintSet;

  event ForceMoon(uint256 phase);

  uint256 public constant MAX_SUPPLY = 10_000;

  uint256 public maxByWallet = 2;
  mapping(address => uint256) public mintedByWallet;

  // 0:close | 1:open
  bool public saleState;

  //baseURI
  string public baseURI;

  //uriSuffix
  string public uriSuffix;

  /// @notice the moooon
  uint256 public constant NEW_MOON = 592500; // 07/01/1970 : 21h35
  uint256 public constant MOON_CYCLE = (29530 * 86400) / 1000; // 29.53 days // 2551392
  uint256 public constant MOON_CYCLE_1_8 = MOON_CYCLE / 8; //  3.69 days //  318924
  uint256 public constant NEW_MOON_START = NEW_MOON - (MOON_CYCLE_1_8 / 2);

  uint256 public forcedPhase = 8;

  EnumerableSet.UintSet private usedPhases;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI_,
    string memory uriSuffix_
  ) ERC721A(name, symbol) {
    baseURI = baseURI_;
    uriSuffix = uriSuffix_;
    usedPhases.add(4);
  }

  /******************** PUBLIC ********************/

  function mint(uint256 amount) external {
    require(msg.sender == tx.origin, "not allowed");
    require(saleState, "Sale is closed!");
    require(_totalMinted() + amount <= MAX_SUPPLY, "Exceed MAX_SUPPLY");
    require(amount > 0, "Amount can't be 0");
    require(amount + mintedByWallet[msg.sender] <= maxByWallet, "Exceed maxByWallet");

    mintedByWallet[msg.sender] += amount;

    _safeMint(msg.sender, amount);
  }

  /******************** OVERRIDES ********************/

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    uint256 currentMoonPhase = getMoonPhase(block.timestamp);

    if (bytes(baseURI).length == 0) {
      return _toString(tokenId);
    }

    if (usedPhases.contains(currentMoonPhase)) {
      return string(abi.encodePacked(baseURI, _toString(tokenId), "_", _toString(currentMoonPhase), uriSuffix));
    }

    return string(abi.encodePacked(baseURI, _toString(tokenId), uriSuffix));
  }

  /******************** OWNER ********************/

  /// @notice Set baseURI.
  /// @param newBaseURI New baseURI.
  /// @param newUriSuffix New uriSuffix.
  function setBaseURI(string memory newBaseURI, string memory newUriSuffix) external onlyOwner {
    baseURI = newBaseURI;
    uriSuffix = newUriSuffix;
  }

  /// @notice Set saleState.
  /// @param newSaleState New sale state.
  function setSaleState(bool newSaleState) external onlyOwner {
    saleState = newSaleState;
  }

  /// @notice Set maxByWallet.
  /// @param newMaxByWallet New max by wallet
  function setMaxByWallet(uint256 newMaxByWallet) external onlyOwner {
    maxByWallet = newMaxByWallet;
  }

  /******************** ALPHA MINT ********************/

  function alphaMint(address[] calldata addresses, uint256[] calldata count) external onlyOwner {
    require(!saleState, "sale is open!");
    require(addresses.length == count.length, "mismatching lengths!");

    for (uint256 i; i < addresses.length; i++) {
      _safeMint(addresses[i], count[i]);
    }

    require(_totalMinted() <= MAX_SUPPLY, "Exceed MAX_SUPPLY");
  }

  /******************** MOON CYCLES ********************/

  function getMoonPhase(uint256 timestamp) public view returns (uint256 moonPhase) {
    if (forcedPhase >= 0 && forcedPhase <= 7) {
      return forcedPhase;
    }
    uint256 cycle_offset = (timestamp - NEW_MOON_START) % MOON_CYCLE;
    return ((cycle_offset * 10**18 * 8) / (MOON_CYCLE)) / 10**18;
  }

  function getMoonPhaseName(uint256 timestamp) public view returns (string memory phase) {
    uint256 moonPhase = getMoonPhase(timestamp);

    if (moonPhase == 0) return "0 - New Moon";
    if (moonPhase == 1) return "1 - Waxing Crescent Moon";
    if (moonPhase == 2) return "2 - First Quarter Moon";
    if (moonPhase == 3) return "3 - Waxing Gibbous Moon";
    if (moonPhase == 4) return "4 - Full Moon";
    if (moonPhase == 5) return "5 - Waning Gibbous Moon";
    if (moonPhase == 6) return "6 - Last Quarter Moon";
    if (moonPhase == 7) return "7 - Waning Crescent Moon";
  }

  function getCurrentMoonPhase() external view returns (uint256 moonPhase) {
    return getMoonPhase(block.timestamp);
  }

  function getCurrentMoonPhaseName() external view returns (string memory) {
    return getMoonPhaseName(block.timestamp);
  }

  function getUsedPhases() external view returns (uint256[] memory) {
    return usedPhases.values();
  }

  function addUsedPhase(uint256 phase) external onlyOwner {
    require(phase >= 0 && phase <= 7, "invalid phase");
    require(!usedPhases.contains(phase), "already in");
    usedPhases.add(phase);
  }

  function removeUsedPhase(uint256 phase) external onlyOwner {
    require(usedPhases.contains(phase), "not in");
    usedPhases.remove(phase);
  }

  /******************** MOON EVENTS ********************/

  /// @notice 0-7: force a phase (0:new moon, 4:full moon), > 7: default phase
  function forceMoon(uint256 phase) external onlyOwner {
    forcedPhase = phase;
    emit ForceMoon(phase);
  }
}