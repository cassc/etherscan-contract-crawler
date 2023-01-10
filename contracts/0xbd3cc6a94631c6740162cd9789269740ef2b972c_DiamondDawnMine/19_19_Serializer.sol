// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../objects/Diamond.sol";
import "../objects/Mine.sol";

library Serializer {
    struct NFTMetadata {
        string name;
        string image;
        string animationUrl;
        Attribute[] attributes;
    }

    struct Attribute {
        string traitType;
        string value;
        string maxValue;
        string displayType;
        bool isString;
    }

    function toStrAttribute(string memory traitType, string memory value) public pure returns (Attribute memory) {
        return Attribute({traitType: traitType, value: value, maxValue: "", displayType: "", isString: true});
    }

    function toAttribute(
        string memory traitType,
        string memory value,
        string memory displayType
    ) public pure returns (Attribute memory) {
        return Attribute({traitType: traitType, value: value, maxValue: "", displayType: displayType, isString: false});
    }

    function toMaxValueAttribute(
        string memory traitType,
        string memory value,
        string memory maxValue,
        string memory displayType
    ) public pure returns (Attribute memory) {
        return
            Attribute({
                traitType: traitType,
                value: value,
                maxValue: maxValue,
                displayType: displayType,
                isString: false
            });
    }

    function serialize(NFTMetadata memory metadata) public pure returns (string memory) {
        bytes memory bytes_;
        bytes_ = abi.encodePacked(bytes_, _openObject());
        bytes_ = abi.encodePacked(bytes_, _pushAttr("name", metadata.name, true, false));
        bytes_ = abi.encodePacked(bytes_, _pushAttr("image", metadata.image, true, false));
        bytes_ = abi.encodePacked(bytes_, _pushAttr("animation_url", metadata.animationUrl, true, false));
        bytes_ = abi.encodePacked(bytes_, _pushAttr("attributes", _serializeAttrs(metadata.attributes), false, true));
        bytes_ = abi.encodePacked(bytes_, _closeObject());
        return string(bytes_);
    }

    function _serializeAttrs(Attribute[] memory attributes) public pure returns (string memory) {
        bytes memory bytes_;
        bytes_ = abi.encodePacked(bytes_, _openArray());
        for (uint i = 0; i < attributes.length; i++) {
            Attribute memory attribute = attributes[i];
            bytes_ = abi.encodePacked(bytes_, _pushArray(_serializeAttr(attribute), i == attributes.length - 1));
        }
        bytes_ = abi.encodePacked(bytes_, _closeArray());
        return string(bytes_);
    }

    function _serializeAttr(Attribute memory attribute) public pure returns (string memory) {
        bytes memory bytes_;
        bytes_ = abi.encodePacked(bytes_, _openObject());
        if (bytes(attribute.displayType).length > 0) {
            bytes_ = abi.encodePacked(bytes_, _pushAttr("display_type", attribute.displayType, true, false));
        }
        if (bytes(attribute.maxValue).length > 0) {
            bytes_ = abi.encodePacked(bytes_, _pushAttr("max_value", attribute.maxValue, attribute.isString, false));
        }
        bytes_ = abi.encodePacked(bytes_, _pushAttr("trait_type", attribute.traitType, true, false));
        bytes_ = abi.encodePacked(bytes_, _pushAttr("value", attribute.value, attribute.isString, true));
        bytes_ = abi.encodePacked(bytes_, _closeObject());
        return string(bytes_);
    }

    // Objects
    function _openObject() public pure returns (bytes memory) {
        return abi.encodePacked("{");
    }

    function _closeObject() public pure returns (bytes memory) {
        return abi.encodePacked("}");
    }

    function _pushAttr(
        string memory key,
        string memory value,
        bool isStr,
        bool isLast
    ) public pure returns (bytes memory) {
        if (isStr) value = string.concat('"', value, '"');
        return abi.encodePacked('"', key, '": ', value, isLast ? "" : ",");
    }

    // Arrays
    function _openArray() public pure returns (bytes memory) {
        return abi.encodePacked("[");
    }

    function _closeArray() public pure returns (bytes memory) {
        return abi.encodePacked("]");
    }

    function _pushArray(string memory value, bool isLast) public pure returns (bytes memory) {
        return abi.encodePacked(value, isLast ? "" : ",");
    }

    function toColorStr(Color color, Color toColor) public pure returns (string memory) {
        return
            toColor == Color.NO_COLOR
                ? _toColorStr(color)
                : string.concat(_toColorStr(color), "-", _toColorStr(toColor));
    }

    function toGradeStr(Grade grade) public pure returns (string memory) {
        if (grade == Grade.GOOD) return "Good";
        if (grade == Grade.VERY_GOOD) return "Very Good";
        if (grade == Grade.EXCELLENT) return "Excellent";
        revert();
    }

    function toClarityStr(Clarity clarity) public pure returns (string memory) {
        if (clarity == Clarity.VS2) return "VS2";
        if (clarity == Clarity.VS1) return "VS1";
        if (clarity == Clarity.VVS2) return "VVS2";
        if (clarity == Clarity.VVS1) return "VVS1";
        if (clarity == Clarity.IF) return "IF";
        if (clarity == Clarity.FL) return "FL";
        revert();
    }

    function toFluorescenceStr(Fluorescence fluorescence) public pure returns (string memory) {
        if (fluorescence == Fluorescence.FAINT) return "Faint";
        if (fluorescence == Fluorescence.NONE) return "None";
        revert();
    }

    function toMeasurementsStr(
        bool isRound,
        uint16 length,
        uint16 width,
        uint16 depth
    ) public pure returns (string memory) {
        string memory separator = isRound ? " - " : " x ";
        return string.concat(toDecimalStr(length), separator, toDecimalStr(width), " x ", toDecimalStr(depth));
    }

    function toShapeStr(Shape shape) public pure returns (string memory) {
        if (shape == Shape.PEAR) return "Pear";
        if (shape == Shape.ROUND) return "Round";
        if (shape == Shape.OVAL) return "Oval";
        if (shape == Shape.CUSHION) return "Cushion";
        revert();
    }

    function toRoughShapeStr(RoughShape shape) public pure returns (string memory) {
        if (shape == RoughShape.MAKEABLE_1) return "Makeable 1";
        if (shape == RoughShape.MAKEABLE_2) return "Makeable 2";
        revert();
    }

    function getName(Metadata memory metadata, uint tokenId) public pure returns (string memory) {
        if (metadata.state_ == Stage.KEY) return string.concat("Mine Key #", Strings.toString(tokenId));
        if (metadata.state_ == Stage.MINE) return string.concat("Rough Stone #", Strings.toString(metadata.rough.id));
        if (metadata.state_ == Stage.CUT) return string.concat("Formation #", Strings.toString(metadata.cut.id));
        if (metadata.state_ == Stage.POLISH) return string.concat("Diamond #", Strings.toString(metadata.polished.id));
        if (metadata.state_ == Stage.DAWN) return string.concat("Dawn #", Strings.toString(metadata.reborn.id));
        revert();
    }

    function toDecimalStr(uint percentage) public pure returns (string memory) {
        uint remainder = percentage % 100;
        string memory quotient = Strings.toString(percentage / 100);
        if (remainder < 10) return string.concat(quotient, ".0", Strings.toString(remainder));
        return string.concat(quotient, ".", Strings.toString(remainder));
    }

    function toTypeStr(Stage state_) public pure returns (string memory) {
        if (state_ == Stage.KEY) return "Key";
        if (state_ == Stage.MINE || state_ == Stage.CUT || state_ == Stage.POLISH) return "Diamond";
        if (state_ == Stage.DAWN) return "Certificate";
        revert();
    }

    function toStageStr(Stage state_) public pure returns (string memory) {
        if (state_ == Stage.MINE) return "Rough";
        if (state_ == Stage.CUT) return "Cut";
        if (state_ == Stage.POLISH) return "Polished";
        if (state_ == Stage.DAWN) return "Reborn";
        revert();
    }

    function _toColorStr(Color color) public pure returns (string memory) {
        if (color == Color.K) return "K";
        if (color == Color.L) return "L";
        if (color == Color.M) return "M";
        if (color == Color.N) return "N";
        if (color == Color.O) return "O";
        if (color == Color.P) return "P";
        if (color == Color.Q) return "Q";
        if (color == Color.R) return "R";
        if (color == Color.S) return "S";
        if (color == Color.T) return "T";
        if (color == Color.U) return "U";
        if (color == Color.V) return "V";
        if (color == Color.W) return "W";
        if (color == Color.X) return "X";
        if (color == Color.Y) return "Y";
        if (color == Color.Z) return "Z";
        revert();
    }
}