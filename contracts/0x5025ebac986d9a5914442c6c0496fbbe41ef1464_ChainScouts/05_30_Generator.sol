//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";
import "./Rarities.sol";
import "./Rng.sol";
import "./ChainScoutMetadata.sol";

library Generator {
    using RngLibrary for Rng;

    function getRandom(
        Rng memory rng,
        uint256 raritySum,
        uint16[] memory rarities
    ) internal view returns (uint256) {
        uint256 rn = rng.generate(0, raritySum - 1);

        for (uint256 i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return i;
            }
            rn -= rarities[i];
        }
        revert("rn not selected");
    }

    function makeRandomClass(Rng memory rn)
        internal
        view
        returns (BackAccessory)
    {
        uint256 r = rn.generate(1, 100);

        if (r <= 2) {
            return BackAccessory.NETRUNNER;
        } else if (r <= 15) {
            return BackAccessory.MERCENARY;
        } else if (r <= 23) {
            return BackAccessory.RONIN;
        } else if (r <= 27) {
            return BackAccessory.ENCHANTER;
        } else if (r <= 38) {
            return BackAccessory.VANGUARD;
        } else if (r <= 45) {
            return BackAccessory.MINER;
        } else if (r <= 50) {
            return BackAccessory.PATHFINDER;
        } else {
            return BackAccessory.SCOUT;
        }
    }

    function getAttack(Rng memory rn, BackAccessory sc)
        internal
        view
        returns (uint256)
    {
        if (sc == BackAccessory.SCOUT) {
            return rn.generate(1785, 2415);
        } else if (sc == BackAccessory.VANGUARD) {
            return rn.generate(1105, 1495);
        } else if (sc == BackAccessory.RONIN || sc == BackAccessory.ENCHANTER) {
            return rn.generate(2805, 3795);
        } else if (sc == BackAccessory.MINER) {
            return rn.generate(1615, 2185);
        } else if (sc == BackAccessory.NETRUNNER) {
            return rn.generate(3740, 5060);
        } else {
            return rn.generate(2125, 2875);
        }
    }

    function getDefense(Rng memory rn, BackAccessory sc)
        internal
        view
        returns (uint256)
    {
        if (sc == BackAccessory.SCOUT || sc == BackAccessory.NETRUNNER) {
            return rn.generate(1785, 2415);
        } else if (sc == BackAccessory.VANGUARD) {
            return rn.generate(4250, 5750);
        } else if (sc == BackAccessory.RONIN) {
            return rn.generate(1530, 2070);
        } else if (sc == BackAccessory.MINER) {
            return rn.generate(1615, 2185);
        } else if (sc == BackAccessory.ENCHANTER) {
            return rn.generate(2805, 3795);
        } else if (sc == BackAccessory.NETRUNNER) {
            return rn.generate(3740, 5060);
        } else {
            return rn.generate(2125, 2875);
        }
    }

    function exclude(uint trait, uint idx, uint16[][] memory rarities, uint16[] memory limits) internal pure {
        limits[trait] -= rarities[trait][idx];
        rarities[trait][idx] = 0;
    }

    function getRandomMetadata(Rng memory rng)
        external 
        view
        returns (ChainScoutMetadata memory ret, Rng memory rn)
    {
        uint16[][] memory rarities = new uint16[][](8);
        rarities[0] = Rarities.accessory();
        rarities[1] = Rarities.backaccessory();
        rarities[2] = Rarities.background();
        rarities[3] = Rarities.clothing();
        rarities[4] = Rarities.eyes();
        rarities[5] = Rarities.fur();
        rarities[6] = Rarities.head();
        rarities[7] = Rarities.mouth();

        uint16[] memory limits = new uint16[](rarities.length);
        for (uint i = 0; i < limits.length; ++i) {
            limits[i] = 10000;
        }

        // excluded traits are less likely than advertised because if an excluding trait is selected, the excluded trait's chance drops to 0%
        // one alternative is a while loop that will use wildly varying amounts of gas, which is unacceptable
        // another alternative is to boost the chance of excluded traits proportionally to the chance that they get excluded, but this will cause the excluded traits to be disproportionately likely in the event that they are not excluded
        ret.accessory = Accessory(getRandom(rng, limits[0], rarities[0]));
        if (
            ret.accessory == Accessory.AMULET ||
            ret.accessory == Accessory.CUBAN_LINK_GOLD_CHAIN ||
            ret.accessory == Accessory.FANNY_PACK ||
            ret.accessory == Accessory.GOLDEN_CHAIN
        ) {
            exclude(3, uint(Clothing.FLEET_UNIFORM__BLUE), rarities, limits);
            exclude(3, uint(Clothing.FLEET_UNIFORM__RED), rarities, limits);

            if (ret.accessory == Accessory.CUBAN_LINK_GOLD_CHAIN) {
                exclude(1, uint(BackAccessory.MINER), rarities, limits);
            }
        }
        else if (ret.accessory == Accessory.GOLD_EARRINGS) {
            exclude(6, uint(Head.CYBER_HELMET__BLUE), rarities, limits);
            exclude(6, uint(Head.CYBER_HELMET__RED), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
        }

        ret.backaccessory = BackAccessory(getRandom(rng, limits[1], rarities[1]));
        if (ret.backaccessory == BackAccessory.PATHFINDER) {
            exclude(6, uint(Head.ENERGY_FIELD), rarities, limits);
        }

        ret.background = Background(getRandom(rng, limits[2], rarities[2]));
        if (ret.background == Background.CITY__PURPLE) {
            exclude(3, uint(Clothing.FLEET_UNIFORM__BLUE), rarities, limits);
            exclude(3, uint(Clothing.MARTIAL_SUIT), rarities, limits);
            exclude(3, uint(Clothing.THUNDERDOME_ARMOR), rarities, limits);
            exclude(6, uint(Head.ENERGY_FIELD), rarities, limits);
        }
        else if (ret.background == Background.CITY__RED) {
            exclude(6, uint(Head.ENERGY_FIELD), rarities, limits);
        }

        ret.clothing = Clothing(getRandom(rng, limits[3], rarities[3]));
        if (ret.clothing == Clothing.FLEET_UNIFORM__BLUE || ret.clothing == Clothing.FLEET_UNIFORM__RED) {
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }

        ret.eyes = Eyes(getRandom(rng, limits[4], rarities[4]));
        if (ret.eyes == Eyes.BLUE_LASER || ret.eyes == Eyes.RED_LASER) {
            exclude(6, uint(Head.BANDANA), rarities, limits);
            exclude(6, uint(Head.CYBER_HELMET__BLUE), rarities, limits);
            exclude(6, uint(Head.CYBER_HELMET__RED), rarities, limits);
            exclude(6, uint(Head.DORAG), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.BANANA), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MASK), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.PILOT_OXYGEN_MASK), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }
        else if (ret.eyes == Eyes.BLUE_SHADES || ret.eyes == Eyes.DARK_SUNGLASSES || ret.eyes == Eyes.GOLDEN_SHADES) {
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MASK), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }
        else if (ret.eyes == Eyes.HUD_GLASSES || ret.eyes == Eyes.HIVE_GOGGLES || ret.eyes == Eyes.WHITE_SUNGLASSES) {
            exclude(6, uint(Head.DORAG), rarities, limits);
            exclude(6, uint(Head.HEADBAND), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
        }
        else if (ret.eyes == Eyes.HAPPY) {
            exclude(6, uint(Head.CAP), rarities, limits);
            exclude(6, uint(Head.LEATHER_COWBOY_HAT), rarities, limits);
            exclude(6, uint(Head.PURPLE_COWBOY_HAT), rarities, limits);
        }
        else if (ret.eyes == Eyes.HIPSTER_GLASSES) {
            exclude(6, uint(Head.BANDANA), rarities, limits);
            exclude(6, uint(Head.CYBER_HELMET__BLUE), rarities, limits);
            exclude(6, uint(Head.CYBER_HELMET__RED), rarities, limits);
            exclude(6, uint(Head.DORAG), rarities, limits);
            exclude(6, uint(Head.HEADBAND), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MASK), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }
        else if (ret.eyes == Eyes.MATRIX_GLASSES || ret.eyes == Eyes.NIGHT_VISION_GOGGLES || ret.eyes == Eyes.SUNGLASSES) {
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
        }
        else if (ret.eyes == Eyes.NOUNS_GLASSES) {
            exclude(6, uint(Head.BANDANA), rarities, limits);
            exclude(6, uint(Head.DORAG), rarities, limits);
            exclude(6, uint(Head.HEADBAND), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MASK), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.PILOT_OXYGEN_MASK), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }
        else if (ret.eyes == Eyes.PINCENEZ) {
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.MASK), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
        }
        else if (ret.eyes == Eyes.SPACE_VISOR) {
            exclude(6, uint(Head.DORAG), rarities, limits);
            exclude(6, uint(Head.HEADBAND), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }

        ret.fur = Fur(getRandom(rng, limits[5], rarities[5]));

        ret.head = Head(getRandom(rng, limits[6], rarities[6]));

        if (ret.head == Head.BANDANA || ret.head == Head.DORAG) {
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }
        else if (ret.head == Head.CYBER_HELMET__BLUE || ret.head == Head.CYBER_HELMET__RED || ret.head == Head.SPACESUIT_HELMET) {
            exclude(7, uint(Mouth.BANANA), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.CIGAR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.PILOT_OXYGEN_MASK), rarities, limits);
            exclude(7, uint(Mouth.PIPE), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.VAPE), rarities, limits);
        }
        // not else. spacesuit helmet includes the above
        if (ret.head == Head.SPACESUIT_HELMET) {
            exclude(7, uint(Mouth.MASK), rarities, limits);
        }

        ret.mouth = Mouth(getRandom(rng, limits[7], rarities[7]));

        ret.attack = uint16(getAttack(rng, ret.backaccessory));
        ret.defense = uint16(getDefense(rng, ret.backaccessory));
        ret.luck = uint16(rng.generate(500, 5000));
        ret.speed = uint16(rng.generate(500, 5000));
        ret.strength = uint16(rng.generate(500, 5000));
        ret.intelligence = uint16(rng.generate(500, 5000));
        ret.level = 1;

        rn = rng;
    }
}