// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DensityType, PolarityType} from "./Palette.sol";
import {MoteType} from "./Motes.sol";
import {EyeType} from "./Eyes.sol";
import {CheekType} from "./Cheeks.sol";
import {MouthType} from "./Mouth.sol";
import {Glints} from "./Glints.sol";
import {Util} from "./Util.sol";

library Traits {
    /*//////////////////////////////////////////////////////////////
                                 TRAITS
    //////////////////////////////////////////////////////////////*/

    function attributes(bytes32 _seed, uint256 _tokenId) internal pure returns (string memory) {
        string memory result = "[";
        result = string.concat(result, _attribute("Density", densityTrait(_seed, _tokenId)));
        result = string.concat(result, ",", _attribute("Polarity", polarityTrait(_seed, _tokenId)));
        result = string.concat(result, ",", _attribute("Glints", glintTrait(_seed)));
        result = string.concat(result, ",", _attribute("Motes", moteTrait(_seed)));
        result = string.concat(result, ",", _attribute("Eyes", eyeTrait(_seed)));
        result = string.concat(result, ",", _attribute("Mouth", mouthTrait(_seed)));
        result = string.concat(result, ",", _attribute("Cheeks", cheekTrait(_seed)));
        result = string.concat(result, ",", _attribute("Virtue", virtueTrait(_seed)));
        return string.concat(result, "]");
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _attribute(string memory _traitType, string memory _value) internal pure returns (string memory) {
        return string.concat("{", Util.keyValue("trait_type", _traitType), ",", Util.keyValue("value", _value), "}");
    }

    function _rarity(bytes32 _seed, string memory _salt) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_seed, _salt))) % 100;
    }

    /*//////////////////////////////////////////////////////////////
                                 DENSITY
    //////////////////////////////////////////////////////////////*/

    function densityTrait(bytes32 _seed, uint256 _tokenId) internal pure returns (string memory) {
        DensityType type_ = densityType(_seed, _tokenId);
        return type_ == DensityType.HIGH ? "High" : "Low";
    }

    function densityType(bytes32 _seed, uint256 _tokenId) internal pure returns (DensityType) {
        uint256 densityRarity = _rarity(_seed, "density");

        if (_tokenId == 0) return DensityType.HIGH;
        if (densityRarity < 80) return DensityType.HIGH;
        return DensityType.LOW;
    }

    /*//////////////////////////////////////////////////////////////
                                POLARITY
    //////////////////////////////////////////////////////////////*/

    function polarityTrait(bytes32 _seed, uint256 _tokenId) internal pure returns (string memory) {
        PolarityType type_ = polarityType(_seed, _tokenId);
        return type_ == PolarityType.POSITIVE ? "Positive" : "Negative";
    }

    function polarityType(bytes32 _seed, uint256 _tokenId) internal pure returns (PolarityType) {
        uint256 polarityRarity = _rarity(_seed, "polarity");

        if (_tokenId == 0) return PolarityType.POSITIVE;
        if (polarityRarity < 80) return PolarityType.POSITIVE;
        return PolarityType.NEGATIVE;
    }

    /*//////////////////////////////////////////////////////////////
                                  MOTE
    //////////////////////////////////////////////////////////////*/

    function moteTrait(bytes32 _seed) internal pure returns (string memory) {
        MoteType type_ = moteType(_seed);

        if (type_ == MoteType.FLOATING) return "Floating";
        if (type_ == MoteType.RISING) return "Rising";
        if (type_ == MoteType.FALLING) return "Falling";
        if (type_ == MoteType.GLISTENING) return "Glistening";
        return "None";
    }

    function moteType(bytes32 _seed) internal pure returns (MoteType) {
        uint256 moteRarity = _rarity(_seed, "mote");

        if (moteRarity < 20) return MoteType.FLOATING;
        if (moteRarity < 35) return MoteType.RISING;
        if (moteRarity < 50) return MoteType.FALLING;
        if (moteRarity < 59) return MoteType.GLISTENING;
        return MoteType.NONE;
    }

    /*//////////////////////////////////////////////////////////////
                                   EYE
    //////////////////////////////////////////////////////////////*/

    function eyeTrait(bytes32 _seed) internal pure returns (string memory) {
        EyeType type_ = eyeType(_seed);

        if (type_ == EyeType.OVAL) return "Oval";
        if (type_ == EyeType.SMILEY) return "Smiley";
        if (type_ == EyeType.WINK) return "Wink";
        if (type_ == EyeType.ROUND) return "Round";
        if (type_ == EyeType.SLEEPY) return "Sleepy";
        if (type_ == EyeType.CLOVER) return "Clover";
        if (type_ == EyeType.STAR) return "Star";
        if (type_ == EyeType.DIZZY) return "Dizzy";
        if (type_ == EyeType.HEART) return "Heart";
        if (type_ == EyeType.HAHA) return "Haha";
        if (type_ == EyeType.CYCLOPS) return "Cyclops";
        return "Opaline";
    }

    function eyeType(bytes32 _seed) internal pure returns (EyeType) {
        uint256 eyeRarity = _rarity(_seed, "eye");

        if (eyeRarity < 20) return EyeType.OVAL;
        if (eyeRarity < 40) return EyeType.ROUND;
        if (eyeRarity < 50) return EyeType.SMILEY;
        if (eyeRarity < 60) return EyeType.SLEEPY;
        if (eyeRarity < 70) return EyeType.WINK;
        if (eyeRarity < 80) return EyeType.HAHA;
        if (eyeRarity < 84) return EyeType.CLOVER;
        if (eyeRarity < 88) return EyeType.STAR;
        if (eyeRarity < 92) return EyeType.DIZZY;
        if (eyeRarity < 96) return EyeType.HEART;
        if (eyeRarity < 99) return EyeType.CYCLOPS;
        return EyeType.OPALINE;
    }

    /*//////////////////////////////////////////////////////////////
                                  MOUTH
    //////////////////////////////////////////////////////////////*/

    function mouthTrait(bytes32 _seed) internal pure returns (string memory) {
        MouthType type_ = mouthType(_seed);
        if (type_ == MouthType.SMILE) return "Smile";
        if (type_ == MouthType.SMIRK) return "Smirk";
        if (type_ == MouthType.GRATIFIED) return "Gratified";
        if (type_ == MouthType.POLITE) return "Polite";
        if (type_ == MouthType.HMM) return "Hmm";
        if (type_ == MouthType.OOO) return "Ooo";
        if (type_ == MouthType.TOOTHY) return "Toothy";
        if (type_ == MouthType.VEE) return "Vee";
        if (type_ == MouthType.GRIN) return "Grin";
        if (type_ == MouthType.BLEP) return "Blep";
        if (type_ == MouthType.SMOOCH) return "Smooch";
        return "Cat";
    }

    function mouthType(bytes32 _seed) internal pure returns (MouthType) {
        uint256 mouthRarity = _rarity(_seed, "mouth");

        if (mouthRarity < 20) return MouthType.SMILE;
        if (mouthRarity < 40) return MouthType.GRATIFIED;
        if (mouthRarity < 60) return MouthType.POLITE;
        if (mouthRarity < 70) return MouthType.GRIN;
        if (mouthRarity < 80) return MouthType.SMIRK;
        if (mouthRarity < 89) return MouthType.VEE;
        if (mouthRarity < 92) return MouthType.OOO;
        if (mouthRarity < 94) return MouthType.HMM;
        if (mouthRarity < 95) return MouthType.TOOTHY;
        if (mouthRarity < 97) return MouthType.BLEP;
        if (mouthRarity < 98) return MouthType.SMOOCH;
        return MouthType.CAT;
    }

    /*//////////////////////////////////////////////////////////////
                                 CHEEKS
    //////////////////////////////////////////////////////////////*/

    function cheekTrait(bytes32 _seed) internal pure returns (string memory) {
        CheekType type_ = cheekType(_seed);
        if (type_ == CheekType.NONE) return "None";
        if (type_ == CheekType.CIRCULAR) return "Circular";
        if (type_ == CheekType.BIG) return "Big";
        return "Freckles";
    }

    function cheekType(bytes32 _seed) internal pure returns (CheekType) {
        uint256 cheekRarity = _rarity(_seed, "cheeks");

        if (cheekRarity < 50) return CheekType.NONE;
        if (cheekRarity < 75) return CheekType.CIRCULAR;
        if (cheekRarity < 85) return CheekType.BIG;
        return CheekType.FRECKLES;
    }

    /*//////////////////////////////////////////////////////////////
                                  GLINT
    //////////////////////////////////////////////////////////////*/

    function glintTrait(bytes32 _seed) internal pure returns (string memory) {
        uint256 count = glintCount(_seed);
        return Util.uint256ToString(count);
    }

    function glintCount(bytes32 _seed) internal pure returns (uint256) {
        uint256 glintRarity = _rarity(_seed, "glint");

        if (glintRarity < 1) return 3;
        if (glintRarity < 5) return 2;
        if (glintRarity < 35) return 1;
        return 0;
    }

    /*//////////////////////////////////////////////////////////////
                                  VIRTUE
    //////////////////////////////////////////////////////////////*/

    function virtueTrait(bytes32 _seed) internal pure returns (string memory) {
        return virtueType(_seed);
    }

    function virtueType(bytes32 _seed) internal pure returns (string memory) {
        uint256 virtueRarity = _rarity(_seed, "virtue");

        if (virtueRarity < 15) return "Gentleness";
        if (virtueRarity < 30) return "Bravery";
        if (virtueRarity < 45) return "Modesty";
        if (virtueRarity < 60) return "Temperance";
        if (virtueRarity < 70) return "Rightous Indignation";
        if (virtueRarity < 80) return "Justice";
        if (virtueRarity < 85) return "Sincerity";
        if (virtueRarity < 88) return "Friendliness";
        if (virtueRarity < 92) return "Dignity";
        if (virtueRarity < 94) return "Endurance";
        if (virtueRarity < 96) return "Greatness of Spirit";
        if (virtueRarity < 98) return "Magnificence";
        if (virtueRarity < 99) return "Wisdom";
        return "Extreme Tardiness";
    }
}