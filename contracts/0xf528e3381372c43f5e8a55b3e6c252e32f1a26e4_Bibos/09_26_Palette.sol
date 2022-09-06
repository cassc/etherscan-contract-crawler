// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;
import {Traits} from "libraries/Traits.sol";
import {Data} from "libraries/Data.sol";

enum DensityType {
    HIGH,
    LOW
}

enum PolarityType {
    POSITIVE,
    NEGATIVE
}

library Palette {
    uint256 constant length = 64;
    uint256 constant opacityLength = 5;

    /*//////////////////////////////////////////////////////////////
                                  FILL
    //////////////////////////////////////////////////////////////*/

    function bodyFill(
        bytes32 _seed,
        uint256 _i,
        uint256 _tokenId
    ) internal pure returns (string memory) {
        uint256 bodyFillValue = uint256(keccak256(abi.encodePacked(_seed, "bodyFill", _i)));

        if (Traits.densityType(_seed, _tokenId) == DensityType.HIGH) {
            if (Traits.polarityType(_seed, _tokenId) == PolarityType.POSITIVE) return _light(bodyFillValue);
            else return _invertedLight(bodyFillValue);
        } else {
            if (Traits.polarityType(_seed, _tokenId) == PolarityType.POSITIVE) return _lightest(bodyFillValue);
            else return _invertedLightest(bodyFillValue);
        }
    }

    function backgroundFill(bytes32 _seed, uint256 _tokenId) internal pure returns (string memory) {
        uint256 backgroundFillValue = uint256(keccak256(abi.encodePacked(_seed, "backgroundFill")));

        if (Traits.densityType(_seed, _tokenId) == DensityType.HIGH) {
            if (Traits.polarityType(_seed, _tokenId) == PolarityType.POSITIVE) return _darkest(backgroundFillValue);
            else return _invertedDarkest(backgroundFillValue);
        } else {
            if (Traits.polarityType(_seed, _tokenId) == PolarityType.POSITIVE) return _darkest(backgroundFillValue);
            else return _invertedDarkest(backgroundFillValue);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 OPACITY
    //////////////////////////////////////////////////////////////*/

    function opacity(
        uint256 _glintSeed,
        bytes32 _seed,
        uint256 _tokenId
    ) internal pure returns (string memory) {
        return
            (
                Traits.densityType(_seed, _tokenId) == DensityType.HIGH
                    ? ["0.3", "0.4", "0.5", "0.6", "0.7"]
                    : ["0.6", "0.7", "0.8", "0.9", "1.0"]
            )[_glintSeed % opacityLength];
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _lightest(uint256 _i) internal pure returns (string memory) {
        return Data.lightestPalette(_i % length);
    }

    function _light(uint256 _i) internal pure returns (string memory) {
        return Data.lightPalette(_i % length);
    }

    function _darkest(uint256 _i) internal pure returns (string memory) {
        return Data.darkestPalette(_i % length);
    }

    function _invertedLightest(uint256 _value) internal pure returns (string memory) {
        return Data.invertedLightestPalette(_value);
    }

    function _invertedLight(uint256 _value) internal pure returns (string memory) {
        return Data.invertedLightPalette(_value);
    }

    function _invertedDarkest(uint256 _value) internal pure returns (string memory) {
        return Data.invertedDarkestPalette(_value);
    }
}