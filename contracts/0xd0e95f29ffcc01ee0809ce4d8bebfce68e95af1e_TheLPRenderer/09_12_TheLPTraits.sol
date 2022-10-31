// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "ERC721A/ERC721A.sol";
import "solmate/utils/SSTORE2.sol";
import "solmate/auth/Owned.sol";
import "solmate/utils/LibString.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/utils/Address.sol";
import "prb-math/PRBMathUD60x18.sol";
import "./Base64.sol";

contract TheLPTraits {
    struct TraitInfo {
        mapping(uint256 => string) map;
    }

    TraitInfo back;
    TraitInfo pants;
    TraitInfo shirt;
    TraitInfo logo;
    TraitInfo clothingItem;
    TraitInfo gloves;
    TraitInfo hat;
    TraitInfo item;
    TraitInfo special;

    string[5] public colors = [
        "#f8f8f8",
        "#E5FBEF",
        "#F5FCDD",
        "#FDEEE8",
        "#E5F1F6"
    ];

    function getBack(uint256 i) public view returns (string memory) {
        return back.map[i];
    }

    function getPants(uint256 i) public view returns (string memory) {
        return pants.map[i];
    }

    function getShirt(uint256 i) public view returns (string memory) {
        return shirt.map[i];
    }

    function getLogo(uint256 i) public view returns (string memory) {
        return logo.map[i];
    }

    function getClothingItem(uint256 i) public view returns (string memory) {
        return clothingItem.map[i];
    }

    function getGloves(uint256 i) public view returns (string memory) {
        return gloves.map[i];
    }

    function getHat(uint256 i) public view returns (string memory) {
        return hat.map[i];
    }

    function getItem(uint256 i) public view returns (string memory) {
        return item.map[i];
    }

    function getSpecial(uint256 i) public view returns (string memory) {
        return special.map[i];
    }

    constructor() {
        back.map[1] = "Fairy Wings";
        back.map[2] = "Jetpack";

        pants.map[59] = "Orange Pants";
        pants.map[60] = "Blue Jeans";
        pants.map[61] = "Black Pants";
        pants.map[62] = "Fun Jeans";
        pants.map[72] = "Blue Shorts";
        pants.map[73] = "Orange Shorts";
        pants.map[74] = "Black Shorts";
        pants.map[75] = "White Shorts";

        shirt.map[76] = "Orange";
        shirt.map[77] = "Yellow";
        shirt.map[78] = "Black";
        shirt.map[79] = "Blue";
        shirt.map[80] = "Green";
        shirt.map[81] = "Red";
        shirt.map[82] = "White";
        shirt.map[83] = "Peanut";

        logo.map[50] = "Bear";
        logo.map[51] = "Chicken";
        logo.map[52] = "Computer";
        logo.map[53] = "Dino";
        logo.map[54] = "Eth";
        logo.map[55] = "LP";
        logo.map[56] = "Metal";
        logo.map[57] = "Rainbow";
        logo.map[58] = "Smile";

        clothingItem.map[3] = "Fanny pack";
        clothingItem.map[4] = "Hawaiian";
        clothingItem.map[5] = "Karate";
        clothingItem.map[6] = "Puffer white";
        clothingItem.map[7] = "Puffer peanut";
        clothingItem.map[8] = "Puffer red";
        clothingItem.map[9] = "LP Puffer";
        clothingItem.map[10] = "Puffer blue";
        clothingItem.map[11] = "Puffer orange";
        clothingItem.map[12] = "Puffer yellow";
        clothingItem.map[13] = "Suit jacket";
        clothingItem.map[14] = "Body suit blue";
        clothingItem.map[15] = "Body suit red";

        gloves.map[16] = "Motorcycle";
        gloves.map[17] = "Wrist guards";

        hat.map[18] = "Aquarium";
        hat.map[19] = "Army";
        hat.map[20] = "Baseball";
        hat.map[21] = "Bear";
        hat.map[22] = "Black hood";
        hat.map[23] = "Bucket helmet";
        hat.map[24] = "Bucket hat";
        hat.map[25] = "Bull";
        hat.map[26] = "Captain";
        hat.map[27] = "Cowboy";
        hat.map[28] = "Dino";
        hat.map[29] = "M";
        hat.map[30] = "Ninja";
        hat.map[31] = "Pirate";
        hat.map[32] = "Safari";
        hat.map[33] = "Santa";
        hat.map[34] = "Shower cap";
        hat.map[35] = "Sombrero";
        hat.map[36] = "Bad guy";
        hat.map[37] = "Viking";
        hat.map[38] = "Builder";
        hat.map[39] = "Hero";

        item.map[63] = "Cellphone";
        item.map[64] = "Briefcase";
        item.map[65] = "Gecko";
        item.map[66] = "Saber";
        item.map[67] = "Lobster";
        item.map[68] = "Lolli";
        item.map[69] = "Shroom";
        item.map[70] = "Ray gun";
        item.map[71] = "Hero Sword";

        special.map[1] = "Unicorn floaty";
        special.map[2] = "Astronaut";
        special.map[3] = "Explorer";
        special.map[4] = "Twilight Knight";
    }
}