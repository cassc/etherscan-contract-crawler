//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&@@,*@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@,#@&&&&&&&&&&&&&&&&&&&&&&#*&
// &&&&&&&&&&&&&&&&&&&&&&&&@@,*@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@,#@&&&##&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&,*&&&&&&&&&&&&@@,*(@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%&&&&&&&&&&&&&&&&&&&&&@#(,#@&&&&&&&&&&&&&&&&&&&&&&&&&
// ##&&&&&&&&&&&&&&&&&&&&&&@@,,*@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%&&&&&&&&&&&&&&&&&&&&&@/*,#@&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&@@,,*&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@/*,#@&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&@@,,*((@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@&(/*,#@&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&@@,,,*/&&&&&&&&&&&&&&&&&&&%%&&&&&&&&&&&&&&&&&&&&&&&&&#(&&&&&&&&&%*,,,#@&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&@@,,,**(%@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##&&&&&&&&&@@((*,,,#@&&&&&&&&&&&&&&&&*/&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&%,***((@@&&&&&&&&&&&#%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@%(***,,&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&*%&&&&&&&&&&&&&&&&&@&,,,*(((#@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@(((**,,,@&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&@&,,,***(((@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@#((/***,,,@&&&&&&&&&&&&&&&%&&&&&&&&&&&
// &&&&&&&&&&&&&&&&(*&&&&&&&&&&@*,***(((((@&&&&&&&&&&&&&@@@@@@@@@@@@@&&&&&&&&&&&&&@&((((/***,,,@&&&&&&&&&&&&&%%,(%&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&@*,,***/((((((@@@@@(((((((((((((((((((((((((#@@@@#((((((***,,,&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&@*,,*****(((((((((((((*/((((((((((((((((*(((((((((((((/****,,,&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&@*,,,,***((****/((((((((****/((((((****/((((((((****/(/***,,,,&@&&&&&@//@@&&&&&&&&&&&&&&&&&&
// &&&&#&&&&&&&&&&&&&&&&&&&&&&&&@@,,,***********//((((((/************(((((((/************,,*@&&&&@((/&@&&&&&&&&&&&&&&&&%&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@,,,****************(((/************(((/****************,,*@&&&@@//,&@&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&##&&&&&@#/@@&&&&&&&&&&&@(,,,****************/*************//****************,,,@@&&&@#/,*@&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&@(/@@&&&&&&&&&&&@(,,,************************************************,,,@@&&&@#/,*@&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&@(//(@&&&&&&&&&&@(,,,,**,***************************************,,*,,,,,@@&&&@#/,,,&@&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&@/,/(@&&&&&&&&&&@(,,,,**,,,************************************,,**,,,,,@@&&&@#///,&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&@@,,/@@&&&&&&&&@(,,,,,,,,,,,********************************,,,,,,,,,,,@@&&&@#//*,,,@@&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&@@..*/(%%%@@&@@%##,,,,,,**,,********************************,**,,,,,,/#@&&@@(///*,,,(%@&&&&&&&&&&#&&&&&&
// &&&&&&&&&&&&&&&&&&@&.///(((#@#((%@,,,,,,/(**,,,**************************,,,*((,,,,,,%@&&&@@(///*,,,.(@&&&&&&&&&&&&&&&&&
// &&&&&&&&&&@%*@@&&&&&&,.,*///((((&@..,,,,,*#####,,,,*****************,,,,*####**,,,,,.#@&&@#(///,,,...(@&&&@@@@&&&&&&&&&&
// &&&&&**&&&@%,@@&&&&&@,.,*////(((((@&.,,,,,,*(%%%(,,,****************,,,%%%((,,,,,,[email protected]@@@&(/////,,,[email protected]@&&&@*,@@&&&&&&&&&&
// &&&&&&&&&&&&@,.,%@&&&@@.,,,,////((@&...,,,,,,,,(/,,,,*************,,,,,(/,,,,,,,,[email protected]%(((////*,,,.&@&&&@&,,,@@&&&&&&&&&&
// &&&&&&&&&&&&@,.,%@&&&&&@/.,,,*////(#@*,..,,,,,,,,,,,,*************,,,,,,,,,,,,,..,&@(((/////,,,..,&@&&@/*,&@&&&&&&&&&&&&
// &&&&&&&&&&&&&@@.,,/(@&&&@@..,,,//////&@...,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,...*@#(////*,,,....,@@@/*,,*@&&&&&&&&&&&&&&
// &&&&&&&&&&&&&@&/,,,,/%%&@@/*.,,,**/////%(/..,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.*/&%(///**,,,...*/&%(//*,,.,@&&&&&&&&&&&%(&
// &&&&&&&&&&&&&&&@*...,///%@@@@,..,,,,,///%@...,,,,,,,,,,,,,,,,,,,,,,,,,,,,,...%@((///,,,.....(((///,,,[email protected]@&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&@@...,,,*****((((((/,,,,*/@&...,,,,,,,,,,,,,,,,,,,,,,,,,,..,@#(///,,,...,(////*,,,[email protected]@&&&&&&&&&&&&&&&
// &&&&&&&#%&&&&&&%%%&%...,/(,,****/((((((,*/@&...,,,,,,,,,,,,,,,,,,,,,,,,,,..,@(//*,,,...((///*,,(/....(&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&%%%%%%((%&%(*,(/,,,,*////(((((//@,...,,,,,,,,,,,,,,,,,,,,,,[email protected]@///,,,...*////,,,**,,/..&%%&&%((%%%&&&&&&&&&
// &&&&&&&&&&&&%%%%((*/(%%&* ...,,,,,/////((((#@,....,,,,,,,,,,,,,,,,,,,[email protected]@/,,,,...////*,,,/((/*,/(%%%&%(/*(#%&&&&&&&&&
// &&&&&&&&&&&&%%%%%% .%%%&/..,&,...,,,,/////(((@@...,,,,,,,,,,,,,,,,,,,...*@///,,...***,,,,......&&&&&%%&%%(,,(#%%%&&&&&&&
// &&&&&&&&&&&&&%%%%%%%%%%@* ,*@*,...,,,,,///(((@@...,,,,,,,,,,,,,,,,,,,...*@//,,,...***,,,.....#@     @&&&&#,.%%%&&&&&&&&&
// &&&&&&&&&&&&&&&&@@  ,&@@/.,*@@@.....,,,,*///(@@.....,,,,,,,,,,,,,,,,....*@//,....*  *,[email protected]@@  ,,,@@&@& [email protected]@&&&&&&&&&&
// &&&&&&&&&&&&&&&&@@ .,&@*,,,,*&@&%%.....,,,//(@@.*(**...,,,,,,,,,,...*/(.*@*,.(#,,.  .  ###@@@@@..,,,@@&@&.,,@@&&&&&&&&&&
// &&&&&&&&&&@@@@@@*.,,,&@.,,,,.&@@@@@@@@@@@@@&/&@,*(((*....,,,,,,...*/(((,/@,,@@@     .,,,,/@@@/...,,,,#@@&,,,@@@&&&&&&&&&
// @@@@@@@@*...//*.....,......./.....***********&@@#,,*(((.........,(((,,,@%.,,,,,..*..,..,,,..,,,,,.,,...,,,..,,,*/@@@@@@@
// .../@......,/......,///.*/.,#.../######////////@#,,,,,,,,,,,,,,,,,,,,,,@%,(((((.,((((,.,*((((((((.,,(*.(((((,/(((,((((**
// ***/(/**********,.*/%**.*************((************/@@@@@@@@@@@@@@@@****/(/***********,***#%(/***,**********(/**********

import {Controllable} from "./base/Controllable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IERC721A} from "erc721a/contracts/IERC721A.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IMoonrunners} from "./interface/IMoonrunners.sol";
import {IMoonrunnersLoot} from "./interface/IMoonrunnersLoot.sol";
import {IMoonrunnersTrophies} from "./interface/IMoonrunnersTrophies.sol";
import {BasicRNG} from "./base/BasicRNG.sol";


error AwwoooooOnly();
error CaveIsClosed();
error CallerIsNotMoonrunnerHolder();
error CallerIsNotLootHolder();
error CallerIsNotNFTHolder();
error InvalidWeaponId();
error NotApprovedForAll();
error CantFightMore();

error InvalidImmuneIdsConfig();
error InvalidDropRatesConfig();
error InvalidDragonRatesConfig();

error ExploreIsClosed();
error CantExploreWithoutFighting();
error CantExploreMore();

error ZeroBalance();

error AwwwwooError();
error CantLootMe();
error MismatchingArrayLength();
error NotOwnerOrController();

struct NFTItem {
  address nftAddress;
  uint32 nftId;
}

contract MoonrunnersS2 is Controllable, ERC1155Holder, BasicRNG {
  using EnumerableSet for EnumerableSet.UintSet;

  event DragonBigFiraFira(address indexed owner, uint256 moonrunnerId);
  event DragonWhips(address indexed owner, uint256 moonrunnerId);
  event DragonAttack(address indexed owner, uint256 moonrunnerId, uint256 rand);
  event LootItem(address indexed owner, uint256 itemId);

  event ExploreLucky(address indexed owner, uint256 moonrunnerId, uint256 amount);
  event ExploreRescue(address indexed owner, uint256 moonrunnerId, uint256 moonrunnerRescuedId);
  event ExploreLootItem(address indexed owner, uint256 itemId);
  event ExploreLootPooPoopPeeDoo(address indexed owner, uint256 moonrunnerId);
  event ExploreNFT(address indexed owner, address nftAddress, uint32 nftId);

  IMoonrunners public moonrunners;
  IMoonrunnersLoot public moonrunnersLoot;
  IMoonrunnersTrophies public moonrunnersTrophies;

  bool public isOpen;
  bool public isExploreOpen;

  // allowed weaponsId
  EnumerableSet.UintSet private weaponsIds;

  // moonSpeakers - moonLegendaries - dragon helmets
  EnumerableSet.UintSet private immuneIds;

  //lootId => maxSupply
  mapping(uint256 => uint256) public maxSupplyOf;

  //moonrunnerId => fightCount
  mapping(uint256 => uint256) public fightCountOf;

  //moonrunnerId => hasExplore
  mapping(uint256 => bool) public hasExplored;

  //moonrunnerId => isKatanaFighter
  mapping(uint256 => bool) public isKatanaFighter;

  //moonrunnerId => isStaffFighter
  mapping(uint256 => bool) public isStaffFighter;

  uint256[] public capturedMR;

  NFTItem[] public NFTs;

  // 0:default 1:katana 2:staff 3:katana+staff => []
  // 0:eth 1:rescueMR 2:lostVials 3:voucher 4:NFTs
  uint32[5][4] private dropRates;

  // 0:default 1:tombholder => []
  // 0:deathRate 1:captureRate
  uint32[2][2] private dragonRates;

  uint256 private constant AWO = 0x16345785D8A0000;

  constructor(
    address moonrunnersAddress,
    address moonrunnersLootAddress,
    address moonrunnersTrophiesAddress
  ) {
    moonrunners = IMoonrunners(moonrunnersAddress);
    moonrunnersLoot = IMoonrunnersLoot(moonrunnersLootAddress);
    moonrunnersTrophies = IMoonrunnersTrophies(moonrunnersTrophiesAddress);

    // set allowed weaponIds
    weaponsIds.add(0); // 0: raygun
    weaponsIds.add(1); // 1: scroll
    weaponsIds.add(2); // 2: ar15
    weaponsIds.add(3); // 3: claws

    weaponsIds.add(8); // 8: katana
    weaponsIds.add(9); // 9: staff

    // loot maxSupply
    maxSupplyOf[4] = 5; //huge  (10 - 5)
    maxSupplyOf[5] = 228; //big (523 - 295)
    maxSupplyOf[6] = 1727; //medium (3100 - 1373)
    maxSupplyOf[7] = 3917; //small (6300 - 2383)

    // voucher
    maxSupplyOf[10] = 10; // voucher free
    maxSupplyOf[11] = 20; // voucher 50%
  }

  modifier onlyOwnerOrController() {
    if (!(owner() == _msgSender() || isController(_msgSender()))) revert NotOwnerOrController();
    _;
  }

  /* -------------------------------------------------------------------------- */
  /*                                   Entry                                    */
  /* -------------------------------------------------------------------------- */

  function fight(
    uint256 moonrunnerId,
    uint256 weaponId,
    uint256 tombId
  ) external {
    if (tx.origin != _msgSender()) revert AwwoooooOnly();
    if (!isOpen) revert CaveIsClosed();
    if (!moonrunners.isApprovedForAll(_msgSender(), address(this))) revert NotApprovedForAll();
    if (moonrunners.ownerOf(moonrunnerId) != _msgSender()) revert CallerIsNotMoonrunnerHolder();
    if (moonrunnersLoot.balanceOf(_msgSender(), weaponId) == 0) revert CallerIsNotLootHolder();
    if (!weaponsIds.contains(weaponId)) revert InvalidWeaponId();
    if (fightCountOf[moonrunnerId] > 1) revert CantFightMore();

    //burn weapon
    moonrunnersLoot.controlledBurn(_msgSender(), weaponId, 1);

    //special weapons
    if (weaponId == 8) {
      isKatanaFighter[moonrunnerId] = true;
    }
    if (weaponId == 9) {
      isStaffFighter[moonrunnerId] = true;
    }

    //awooooo
    uint256[] memory rand = randomUint16Array(2, 10_000);

    //moonrunner attack
    uint256 lootableId = packAttack(weaponId, rand[0]);

    // dragon attack
    bool isAlive = dragonAttack(moonrunnerId, tombId, rand[1]);

    if (isAlive) {
      //mint vial
      moonrunnersLoot.mint(_msgSender(), lootableId, 1);
      emit LootItem(_msgSender(), lootableId);
    } else {
      //mint vial for explore
      moonrunnersLoot.mint(address(this), lootableId, 1);
    }
  }

  function explore(uint256 moonrunnerId) external {
    if (tx.origin != _msgSender()) revert AwwoooooOnly();
    if (!isExploreOpen) revert ExploreIsClosed();
    if (moonrunners.ownerOf(moonrunnerId) != _msgSender()) revert CallerIsNotMoonrunnerHolder();
    if (fightCountOf[moonrunnerId] < 1) revert CantExploreWithoutFighting();
    if (hasExplored[moonrunnerId]) revert CantExploreMore();

    hasExplored[moonrunnerId] = true;

    uint256[] memory rand = randomUint16Array(2, 10_000);

    doExplore(moonrunnerId, rand);
  }

  /* -------------------------------------------------------------------------- */
  /*                                   Logic                                    */
  /* -------------------------------------------------------------------------- */

  function dragonAttack(
    uint256 moonrunnerId,
    uint256 tombId,
    uint256 rand
  ) internal returns (bool) {
    bool isImmune = immuneIds.contains(moonrunnerId);
    bool isTombHolder = isTombHolderAddr(_msgSender(), tombId);
    uint32[2] memory steps = isTombHolder ? dragonRates[1] : dragonRates[0];

    fightCountOf[moonrunnerId] += 1;

    if (rand < steps[0] && !isImmune) {
      // RIP : big fira fira)
      moonrunners.burn(moonrunnerId);
      emit DragonBigFiraFira(_msgSender(), moonrunnerId);
      return false;
    } else if (rand > steps[1] && !isImmune) {
      // CAPTURED : dragon whips
      capturedMR.push(moonrunnerId);
      moonrunners.transferFrom(_msgSender(), address(this), moonrunnerId);
      emit DragonWhips(_msgSender(), moonrunnerId);
      return false;
    }

    emit DragonAttack(_msgSender(), moonrunnerId, rand);
    return true;
  }

  //4 : huge | 5 : big | 6 : medium | 7 : small
  function packAttack(uint256 weaponId, uint256 rand) internal returns (uint256) {
    uint256 lootId = 7;

    if (weaponId == 0) {
      // console.log("raygun");
      if (rand < 200 && moonrunnersLoot.totalSupply(4) < maxSupplyOf[4]) {
        lootId = 4;
      } else if (rand < 4700 && moonrunnersLoot.totalSupply(5) < maxSupplyOf[5]) {
        lootId = 5;
      } else {
        lootId = 6;
      }
    } else if (weaponId == 8) {
      // console.log("katana");
      if (rand < 900 && moonrunnersLoot.totalSupply(5) < maxSupplyOf[5]) {
        lootId = 5;
      } else if (rand < 4900 && moonrunnersLoot.totalSupply(6) < maxSupplyOf[6]) {
        lootId = 6;
      }
    } else if (weaponId == 1) {
      // console.log("scroll");
      if (rand < 800 && moonrunnersLoot.totalSupply(5) < maxSupplyOf[5]) {
        lootId = 5;
      } else if (rand < 6300 && moonrunnersLoot.totalSupply(6) < maxSupplyOf[6]) {
        lootId = 6;
      }
    } else if (weaponId == 2) {
      // console.log("ar15");
      if (rand < 300 && moonrunnersLoot.totalSupply(5) < maxSupplyOf[5]) {
        lootId = 5;
      } else if (rand < 3400 && moonrunnersLoot.totalSupply(6) < maxSupplyOf[6]) {
        lootId = 6;
      }
    } else if (weaponId == 9) {
      // console.log("staff");
      if (rand < 200 && moonrunnersLoot.totalSupply(5) < maxSupplyOf[5]) {
        lootId = 5;
      } else if (rand < 3100 && moonrunnersLoot.totalSupply(6) < maxSupplyOf[6]) {
        lootId = 6;
      }
    } else if (weaponId == 3) {
      // console.log("claws");
      if (rand < 100 && moonrunnersLoot.totalSupply(5) < maxSupplyOf[5]) {
        lootId = 5;
      } else if (rand < 2300 && moonrunnersLoot.totalSupply(6) < maxSupplyOf[6]) {
        lootId = 6;
      }
    }

    if (lootId == 7 && !(moonrunnersLoot.totalSupply(7) < maxSupplyOf[7])) {
      // no small vial left awooo
      revert CantLootMe();
    }

    return lootId;
  }

  /*************************************************************/

  function doExplore(uint256 moonrunnerId, uint256[] memory rand) internal {
    uint256 balance = address(this).balance;

    uint32[5] memory dropRate = dropRates[0];
    if (isKatanaFighter[moonrunnerId] && isStaffFighter[moonrunnerId]) {
      dropRate = dropRates[3];
    } else if (isKatanaFighter[moonrunnerId]) {
      dropRate = dropRates[1];
    } else if (isStaffFighter[moonrunnerId]) {
      dropRate = dropRates[2];
    }

    if (rand[0] < dropRate[0] && balance >= AWO) {
      //console.log("-- ETH PRICE");
      // send AWO
      emit ExploreLucky(_msgSender(), moonrunnerId, AWO);
      (bool success, ) = payable(_msgSender()).call{value: AWO}("");
      if (!success) revert AwwwwooError();
      return;
    } else if (rand[0] < dropRate[1]) {
      //console.log("-- MR PRICE");
      if (capturedMR.length > 0) {
        //send random MR
        uint256 idx = rand[1] % capturedMR.length;
        uint256 id = capturedMR[idx];
        capturedMR[idx] = capturedMR[capturedMR.length - 1];
        capturedMR.pop();

        moonrunners.transferFrom(address(this), _msgSender(), id);
        emit ExploreRescue(_msgSender(), moonrunnerId, id);
        return;
      }
    } else if (rand[0] < dropRate[2]) {
      //console.log("-- LOOT PRICE");
      //4 : huge | 5 : big | 6 : medium | 7 : small
      uint256 lootId;
      if (rand[1] < 500 && moonrunnersLoot.balanceOf(address(this), 4) > 0) {
        lootId = 4;
      } else if (rand[1] < 1500 && moonrunnersLoot.balanceOf(address(this), 5) > 0) {
        lootId = 5;
      } else if (rand[1] < 4000 && moonrunnersLoot.balanceOf(address(this), 6) > 0) {
        lootId = 6;
      } else if (moonrunnersLoot.balanceOf(address(this), 7) > 0) {
        lootId = 7;
      }
      if (lootId > 0) {
        //send lootId
        moonrunnersLoot.safeTransferFrom(address(this), _msgSender(), lootId, 1, bytes(""));
        emit ExploreLootItem(_msgSender(), lootId);
        return;
      }
    } else if (rand[0] < dropRate[3]) {
      // nft voucher
      //console.log("-- VOUCHER PRICE");
      uint256 voucherId;
      if (rand[1] < 3333 && moonrunnersLoot.totalSupply(10) < maxSupplyOf[10]) {
        voucherId = 10;
      } else if (moonrunnersLoot.totalSupply(11) < maxSupplyOf[11]) {
        voucherId = 11;
      }
      if (voucherId > 0) {
        moonrunnersLoot.mint(_msgSender(), voucherId, 1);
        emit ExploreLootItem(_msgSender(), voucherId);

        return;
      }
    } else if (rand[0] < dropRate[4]) {
      //console.log("-- NFT PRICE");
      if (NFTs.length > 0) {
        //send random NFT
        uint256 idx = rand[1] % NFTs.length;
        NFTItem memory nft = NFTs[idx];
        NFTs[idx] = NFTs[NFTs.length - 1];
        NFTs.pop();
        IERC721(nft.nftAddress).transferFrom(address(this), _msgSender(), nft.nftId);
        emit ExploreNFT(_msgSender(), nft.nftAddress, nft.nftId);
        return;
      }
    }

    emit ExploreLootPooPoopPeeDoo(_msgSender(), moonrunnerId);
  }

  /* -------------------------------------------------------------------------- */
  /*                                    Getters                                 */
  /* -------------------------------------------------------------------------- */

  function getFightCountBatch(uint256[] calldata moonrunnerIds) external view returns (uint256[] memory) {
    uint256[] memory fightCounts = new uint256[](moonrunnerIds.length);
    for (uint256 i; i < moonrunnerIds.length; ++i) fightCounts[i] = fightCountOf[moonrunnerIds[i]];
    return fightCounts;
  }

  function getHasExploredBatch(uint256[] calldata moonrunnerIds) external view returns (bool[] memory) {
    bool[] memory _hasExplored = new bool[](moonrunnerIds.length);
    for (uint256 i; i < moonrunnerIds.length; ++i) _hasExplored[i] = hasExplored[moonrunnerIds[i]];
    return _hasExplored;
  }

  function getIsKatanaFighterBatch(uint256[] calldata moonrunnerIds) external view returns (bool[] memory) {
    bool[] memory _isKatanaFighter = new bool[](moonrunnerIds.length);
    for (uint256 i; i < moonrunnerIds.length; ++i) _isKatanaFighter[i] = isKatanaFighter[moonrunnerIds[i]];
    return _isKatanaFighter;
  }

  function getIsStaffFighterBatch(uint256[] calldata moonrunnerIds) external view returns (bool[] memory) {
    bool[] memory _isStaffFighter = new bool[](moonrunnerIds.length);
    for (uint256 i; i < moonrunnerIds.length; ++i) _isStaffFighter[i] = isStaffFighter[moonrunnerIds[i]];
    return _isStaffFighter;
  }

  function getCapturedMR() external view returns (uint256[] memory) {
    return capturedMR;
  }

  function getCapturedNFTs() external view returns (NFTItem[] memory) {
    return NFTs;
  }

  function getCapturedNFT(uint256 idx) external view returns (NFTItem memory) {
    return NFTs[idx];
  }

  function getDropRates() external view returns (uint32[5][4] memory) {
    return dropRates;
  }

  function isTombHolderAddr(address addr, uint256 tombId) public view returns (bool) {
    uint256 balance = IERC1155(moonrunnersTrophies).balanceOf(addr, tombId);
    return balance > 0;
  }

  /* -------------------------------------------------------------------------- */
  /*                                  Only Owner                                */
  /* -------------------------------------------------------------------------- */

  function setIsOpen(bool newIsOpen) external onlyOwner {
    if (newIsOpen && immuneIds.length() == 0) revert InvalidImmuneIdsConfig();
    if (newIsOpen && dropRates[0][0] == 0) revert InvalidDropRatesConfig();
    if (newIsOpen && dragonRates[0][0] == 0) revert InvalidDragonRatesConfig();
    isOpen = newIsOpen;
  }

  function setIsExploreOpen(bool newIsExploreOpen) external onlyOwner {
    isExploreOpen = newIsExploreOpen;
  }

  /* -------------------------------------------------------------------------- */
  /*                       Manage tokens in  contract                          */
  /* -------------------------------------------------------------------------- */

  /// @notice rescue ERC721 without updating storage
  function rescueERC721(
    address collectionAddress,
    uint256[] memory ids,
    address to
  ) external onlyOwner {
    for (uint256 i; i < ids.length; ++i) {
      uint256 id = ids[i];
      IERC721(collectionAddress).transferFrom(address(this), to, id);
    }
  }

  /// @notice remove 1 nft by idx updating storage
  function removeNFT(
    uint256 idx,
    address to,
    bool transfer
  ) external onlyOwner {
    NFTItem memory nft = NFTs[idx];
    NFTs[idx] = NFTs[NFTs.length - 1];
    NFTs.pop();

    if (transfer) {
      IERC721(nft.nftAddress).transferFrom(address(this), to, nft.nftId);
    }
  }

  function withdraw() external payable onlyOwner {
    uint256 balance = address(this).balance;
    if (balance == 0) revert ZeroBalance();

    (bool success, ) = payable(_msgSender()).call{value: balance}("");
    require(success, "");
  }

  /* -------------------------------------------------------------------------- */
  /*                                  Capture                                   */
  /* -------------------------------------------------------------------------- */

  /// @notice capture moonrunners
  function captureMoonrunners(uint256[] memory moonrunnerIds) external onlyOwnerOrController {
    if (!moonrunners.isApprovedForAll(_msgSender(), address(this))) revert NotApprovedForAll();

    for (uint256 i; i < moonrunnerIds.length; ++i) {
      uint256 moonrunnerId = moonrunnerIds[i];
      if (moonrunners.ownerOf(moonrunnerId) != _msgSender()) revert CallerIsNotMoonrunnerHolder();
      capturedMR.push(moonrunnerId);
      moonrunners.transferFrom(_msgSender(), address(this), moonrunnerId);
    }
  }

  /// @notice capture ids of collectionAddress
  /// @param collectionAddress ERC721 collection address
  /// @param ids list of ids
  function captureERC721(address collectionAddress, uint256[] memory ids) external onlyOwnerOrController {
    if (!IERC721(collectionAddress).isApprovedForAll(_msgSender(), address(this))) revert NotApprovedForAll();

    for (uint256 i; i < ids.length; ++i) {
      uint256 nftId = ids[i];
      if (IERC721(collectionAddress).ownerOf(nftId) != _msgSender()) revert CallerIsNotNFTHolder();
      NFTItem memory item = NFTItem(collectionAddress, uint32(nftId));
      NFTs.push(item);
      IERC721(collectionAddress).transferFrom(_msgSender(), address(this), nftId);
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                    Config                                 */
  /* -------------------------------------------------------------------------- */

  function setImmuneIds(uint256[] calldata ids) external onlyOwner {
    for (uint256 i; i < ids.length; ++i) immuneIds.add(ids[i]);
  }

  /// @notice set dropRates (explore)
  function setDropRates(uint256[] memory ids, uint32[5][] memory stepsById) external onlyOwnerOrController {
    if (ids.length != stepsById.length) revert MismatchingArrayLength();

    for (uint256 i; i < ids.length; ++i) {
      dropRates[i] = stepsById[i];
    }
  }

  /// @notice set dragonRates (fight)
  function setDragonRates(uint256[] memory ids, uint32[2][] memory stepsById) external onlyOwnerOrController {
    if (ids.length != stepsById.length) revert MismatchingArrayLength();

    for (uint256 i; i < ids.length; ++i) {
      dragonRates[i] = stepsById[i];
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                    Awwoooo                                 */
  /* -------------------------------------------------------------------------- */

  receive() external payable {
    //Awoooo
  }
}