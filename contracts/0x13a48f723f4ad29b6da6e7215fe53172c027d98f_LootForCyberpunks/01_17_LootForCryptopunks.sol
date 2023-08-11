/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Base64.sol";

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface SyntheticLootInterface {
    function tokenURI(address walletAddress) external view returns (string memory tokenURI);
}

contract LootForCyberpunks is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    uint256 public constant MAX_SYNTHETIC_ITEMS = 2000;
    Counters.Counter private _syntheticItemsTracker;
    Counters.Counter private _originItemsTracker;

    //Loot Contract
    address public lootAddress;
    LootInterface lootContract;
    
    //Synthetic Loot Contract 
    address public syntheticLootAddress;
    SyntheticLootInterface syntheticLootContract;

    address public multisigAddress;
        
    event CreateLoot(uint256 indexed id);
		
    string[] private weapons = [
        unicode"Dagg̸͔͛e̴r",
        unicode"Shu̶rike̴n",
        unicode"B̷͓͛last̷er",
        unicode"Rif̴le",
        unicode"Gre̵n̵ad̷e",
        unicode"Gau̴ntl̵̚et̵"
    ];
    
    string[] private chestArmor = [
       unicode"H̵̒az̷̧͐m̵at Ś̷̠uit",
       unicode"Bra̷",
       unicode"Wo̴u̶nd̴",
       unicode"Ŕ̷̰ippe̷͘d T-̷S̵̛ͅhi̴r̷t̴"
    ];

    string[] private headArmor = [
        unicode"G̵la̴s̵s̵ Eý̷e",
        unicode"V̵i̵s̷or ̴",
        unicode"Sc̵ar̷̝̽",
        unicode"M̵oha̶w̴k",
        unicode"Pi̴erc̵i̴ng",
        unicode"He̴lm̷et̷̡́"
    ];
    
    string[] private waistArmor = [
       unicode"P̴͠ants",
       unicode"B̷ri̵ef̴s",
       unicode"F̷̐anny-Pack",
       unicode"H̴͂ula-Hoop",
       unicode"Ouro̴boroś̶",
       unicode"S̷h̴eath",
       unicode"Sk̶irt"
    ];
    

    string[] private footArmor = [
       unicode"B̴o̵o̴ts",
       unicode"Ẃ̶͝arts",
       unicode"Tan̵͝k̷͘ T̴r̷eads",
       unicode"Á̴nkle̴t"
    ];

    					

    string[] private handArmor = [
       unicode"B̵̓lõ̵od̵y S̵t̸ump",
       unicode"T̴͌it̵a̵nḯ̵um̵ ̶Fĭ̴ng̴e̶rs",
       unicode"Ni̴nte̴nd̶̽o̵ Põ̷w̵̐e̷rglove",
       unicode"Un̵i̶vë̵́rs̷al Do̷ng̴̚le",
       unicode"P̴͓̽l̶as̵t̶i̴c C̴law̶s",
       unicode"Bl̵ades̵̚"
    ];

			 	

    string[] private necklaces = [
       unicode"Koi̵ Tatt̴̽o̷o"
       unicode"Breat̴̝̽hing Ho̵̅le",
       unicode"C̵͗hŏ̴ker",
       unicode"Ca̸̅rbon St̴̯͠eel C̵͗hŏ̴ker",
       unicode"S̸̿pĩ̴dersilk Scar̴̂f",
       unicode"Babb̴̓le̶̊ F̵ish Imp̵lant"
    ];
    
    			

    string[] private rings = [
      unicode"We̵d̵̏di̵n̴g Ban̶d",
      unicode"Wo̶͝od̵e̶n̶ ̶Ring̵̚",
      unicode"Chr̴̃om̵e Ring",
      unicode"M̴eta̷l̴ Ri̶ng̴",
      unicode"W̷ire ̶Ring"
    ];
    
    string[] private suffixes = [
       unicode"of N̴̐ightc̶i̷̓ty",
       unicode"of̴̎ Redē̴mptio̴͘n",
       unicode"o̶f Dem̶is̷e",
       unicode"of̴ S̵had̶̑ows̵",
       unicode"of L̶̟̽igh̴t",
       unicode"o̵͝f ̵Deligh̵t",
       unicode"of ̴Neo-Tokyo",
       unicode"of Fo̴rt̴u̵̻̽ne",
       unicode"of D̶o̷o̵͠m",
       unicode"o̵f Punish̴̒m̵e̷n̵t",
       unicode"o̵f ̴Cl̵ari̴ty",
       unicode"o̴f Ch̴ao̵s̶",
       unicode"o̴f Ra̶̻͛ge",
       unicode"of̵ Des̵͒i̶r̵e",
       unicode"of ̷De̴spair",
       unicode"of Insan̴ĭ̶̧t̶y",
       unicode"of O̵̼͛pportu̴n̸̼̿ity",
       unicode"of Ma̶lice̷",
       unicode"o̴f Họ̵͠pe",
       unicode"of Generosi̵͇̊ty",
       unicode"o̶̙̍f the Co̵sm̴os",
       unicode"of Te̷rror",
       unicode"of Enli̶gh̷̎tenmen̵t̴",
       unicode"of ̵̓the Si̴th l̶o̴rd̵",
       unicode"o̶͝f Fl̵ȧ̵mes",
       unicode"of̷́ I̵ce",
       unicode"of Mi̴s̴er̶y",
       unicode"of Frien̵d̵s̵͓̽h̵i̷p̵",
       unicode"of Rè̴ͅmorse"
    ];	

    string[] private namePrefixes = [
        unicode"Soil̵e̴d",
        unicode"Stolen̴̎",
        unicode"In̵finit̸̊e",
        unicode"Exo̵̰̎tic",
       unicode"Fr̵oz̴e̴n̷͘",
       unicode"To̴͈͛rn",
       unicode"Stolen̷͚̕",
       unicode"Du̴l̵l",
       unicode"Ho̵l̶͌y",
       unicode"Wa̵r̴ped̶̆",
       unicode"Mo̴l̴ten̶",
       unicode"Deca̴y̷͛ed",
       unicode"Ant̴ique",
       unicode"V̵anis̷hi̵ng",
       unicode"S̴͎̽hattere̷d",
       unicode"Fragm̸ente̶͎͛d",
       unicode"C̴rooke̴d",
       unicode"̴̑Ada̵m̶̾an̵t̵i̶ne",
       unicode"Sili̷cone",
       unicode"C̷arb̴id̸̽e",
       unicode"̷̗͌D̶i̶am̶ond",
       unicode"Lase̶̪̽r",
       unicode"K̴a̴̦̽leid̴oscopi̵̙̽c",
       unicode"Arti̵fi̸̍cial",
       unicode"Hid̴d̸̈en̵",
       unicode"P̴olym̷er̵̔",
       unicode"P̴̃lasti̵c",
       unicode"Au̶t̵h̵̿entic",
       unicode"F̷o̴rbi̵dd̵en̴",
       unicode"Tat̶t̷oo̵̾ed",
       unicode"Swar̴m̴͊ing",
       unicode"Tot̵alled̵",
       unicode"Crum̴͍̚b̴liǹ̶g",
       unicode"Ć̷̣rac̴͌ke̵d̵",
       unicode"Tu̶̔rpid",
       unicode"Disemb̷̮͊o̴͒die̵d̴̍",
       unicode"Jà̶cked",
       unicode"C̵o̶͌nc̵re̵te",
       unicode"W̴ooden",
       unicode"St̶͝eel̴",
        unicode"Pa̵̰̚le",
        unicode"Mirr̴o̴̊red",
        unicode"Le̶athe̵r",
        unicode"Webb̴ed",
        unicode"Ný̴lon̴",
        unicode"N̷͂eon",
        unicode"Br̷oken̴",
        unicode"Unbrea̷̽kable",
        unicode"Cheap̵̗͆",
        unicode"A̵lumi̴͝n̵u̷m",
        unicode"Tran̴s̷p̵a̵re̶n̷t"
    ];
    
    string[] private nameSuffixes = [
        unicode"Pi̶nk",
        unicode"Si̴lv̵e̵r",
        unicode"G̴̀oĺ̵d̵",
        unicode"Vio̴l̶͉̚et",
        unicode"Cy̵an̶",
        unicode"Red̶͇̀",
        unicode"Y̴el̴low",
        unicode"W̶̮͌hite̵",
        unicode"Rainbö̵́w",
        unicode"Bla̵c̴͆k",
        unicode"Gr̵e̴̊y",
        unicode"Ac̴̓i̵͝d Gr̴̊een",
        unicode"Am̵̓b̵e̷r",
        unicode"Aq̵ua",
        unicode"Azu̶re̵",
        unicode"Da̷r̴k ̵̠͝G̷̕rey",
        unicode"B̷̽lu̶e Sap̶p̵h̴i̶re",
        unicode"Bu̶rg̴͂undy",
        unicode"Ca̷d̵͌et Gr̸ey",
        unicode"C̷͂eles̴t̷e",
        unicode"Chå̴rc̷o̴al",
        unicode"Cop̷pe̷̊r",
        unicode"C̶otto̶n C̶and̵y",
        unicode"C̷̏ryst̴al̴",
        unicode"C̷rims̴͐on̴",
        unicode"Opal̶͝",
        unicode"F̷l̸͉͛orescent",
        unicode"G̴las̵̯̊s̷",
        unicode"Sl̷a̴t̷e̴"
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getWeapon(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "WEAPON", weapons);
    }
    
    function getChest(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CHEST", chestArmor);
    }
    
    function getHead(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "HEAD", headArmor);
    }
    
    function getWaist(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "WAIST", waistArmor);
    }

    function getFoot(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FOOT", footArmor);
    }
    
    function getHand(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "HAND", handArmor);
    }
    
    function getNeck(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "NECK", necklaces);
    }
    
    function getRing(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "RING", rings);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId), syntheticLootContract.tokenURI(_msgSender()))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
        }
        if (greatness >= 19) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
            if (greatness == 19) {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output));
            } else {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output, " +1"));
            }
        }
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getWeapon(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getChest(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getHead(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getWaist(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getFoot(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getHand(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getNeck(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getRing(tokenId);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Cyberpunk Bag #', toString(tokenId), '", "description": "Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function _totalSyntheticSupply() internal view returns (uint) {
        return _syntheticItemsTracker.current();
    }
    
    function totalSyntheticSupply() public view returns (uint256) {
        return _totalSyntheticSupply();
    } 
    
    function _totalOriginSupply() internal view returns (uint) {
        return _originItemsTracker.current();
    }
    
    function totalOriginSupply() public view returns (uint256) {
        return _totalOriginSupply();
    } 
    
   function claim(uint256 tokenId) public nonReentrant {
        require(!_exists(tokenId), "This token has already been minted");
        require(tokenId > 0 && tokenId < 10001, "Invalid token id");
        bool isLootOrigin = tokenId > 0 && tokenId < 8001;
        if(isLootOrigin) {
            require(lootContract.ownerOf(tokenId) == _msgSender(), "Not the owner of this loot");
            _originItemsTracker.increment();
        } else {
            uint256 total = _totalSyntheticSupply();
            require(total + 1 <= MAX_SYNTHETIC_ITEMS, "Max limit");
            require(total <= MAX_SYNTHETIC_ITEMS, "Sale end");
            _syntheticItemsTracker.increment();
        }
        _safeMint(_msgSender(), tokenId);
        emit CreateLoot(tokenId);
    }

    function claimTeam() public nonReentrant onlyOwner {
        for (uint256 i = 8888; i < 9038; i++) {
            _syntheticItemsTracker.increment();
            _safeMint(multisigAddress, i);
        }
    } 
    
    
    function mint(uint256 tokenId) public nonReentrant onlyOwner {
        _safeMint(multisigAddress, tokenId);
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    
    constructor(address synthetic, address loot, address multisig) ERC721("Loot (for Cyberpunks)", "CYBERLOOT") {
        syntheticLootAddress = synthetic;
        syntheticLootContract = SyntheticLootInterface(synthetic);
        lootAddress = loot;
        lootContract = LootInterface(loot);
        multisigAddress = multisig;
    }
}