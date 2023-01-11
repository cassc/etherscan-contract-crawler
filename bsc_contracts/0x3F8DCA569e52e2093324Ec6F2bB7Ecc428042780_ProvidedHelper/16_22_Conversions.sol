// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "../interfaces/INFTPoolInteractor.sol";
import "./AddressArray.sol";
import "./UintArray.sol";
import "hardhat/console.sol";

struct Conversion {
    Asset desiredERC721;
    address desiredERC20;
    uint256 value;
    address[] underlying;
    uint256[] underlyingValues;
}

library Conversions {
    using AddressArray for address[];
    using UintArray for uint256[];

    function append(
        Conversion[] memory self,
        Conversion memory conversion
    ) internal pure returns (Conversion[] memory) {
        Conversion[] memory newArray = new Conversion[](self.length + 1);
        for (uint256 i = 0; i < self.length; i++) {
            newArray[i] = self[i];
        }
        newArray[self.length] = conversion;
        return newArray;
    }

    function concat(Conversion[] memory self, Conversion[] memory array) internal pure returns (Conversion[] memory) {
        Conversion[] memory newArray = new Conversion[](self.length + array.length);
        for (uint256 i = 0; i < self.length; i++) {
            newArray[i] = self[i];
        }
        for (uint256 i = 0; i < array.length; i++) {
            newArray[i + self.length] = array[i];
        }
        return newArray;
    }

    function getUnderlying(
        Conversion[] memory self
    ) internal pure returns (address[] memory underlying, uint256[] memory underlyingValues) {
        for (uint256 i = 0; i < self.length; i++) {
            for (uint256 j = 0; j < self[i].underlying.length; j++) {
                if (_isBasic(self, self[i].underlying[j])) {
                    underlying = underlying.append(self[i].underlying[j]);
                    underlyingValues = underlyingValues.append(self[i].underlyingValues[j]);
                }
            }
        }
    }

    function findAllBasic(Conversion[] memory self, address toFind) internal pure returns (uint256[] memory) {
        uint256[] memory indices;
        uint256 numMatching;
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].desiredERC20 == toFind && self[i].underlying.length == 0) {
                numMatching += 1;
            }
        }
        if (numMatching == 0) {
            return indices;
        }
        indices = new uint256[](numMatching);
        uint256 numPushed = 0;
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].desiredERC20 == toFind && self[i].underlying.length == 0) {
                indices[numPushed] = i;
                numPushed += 1;
                if (numPushed == numMatching) {
                    return indices;
                }
            }
        }
        return indices;
    }

    function findAllWithUnderlying(
        Conversion[] memory self,
        address underlying
    ) internal pure returns (uint256[] memory) {
        uint256[] memory indices;
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].underlying.exists(underlying)) {
                indices = indices.append(i);
            }
        }
        return indices;
    }

    function findUnderlyingOrFinal(Conversion[] memory self, address token) internal pure returns (uint256[] memory) {
        uint256[] memory indices;
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].underlying.exists(token) || self[i].desiredERC20 == token) {
                indices = indices.append(i);
            }
        }
        return indices;
    }

    function _isBasic(Conversion[] memory conversions, address token) internal pure returns (bool) {
        for (uint256 i = 0; i < conversions.length; i++) {
            if (conversions[i].desiredERC20 == token && conversions[i].underlying[0] != token) return false;
        }
        return true;
    }

    function sumAll(Conversion[] memory conversions, address token) internal pure returns (uint256 sum) {
        for (uint256 i = 0; i < conversions.length; i++) {
            uint256 underlyingIdx = conversions[i].underlying.findFirst(token);
            if (
                underlyingIdx != conversions[i].underlying.length && conversions[i].underlying[underlyingIdx] == token
            ) {
                sum += conversions[i].underlyingValues[underlyingIdx];
            }
        }
    }

    function sumPrior(Conversion[] memory conversions, uint256 idx, address token) internal pure returns (uint256 sum) {
        for (uint256 i = 0; i <= idx; i++) {
            if (conversions[i].desiredERC20 == token) {
                sum += conversions[i].value;
                continue;
            }
            uint256 underlyingIdx = conversions[i].underlying.findFirst(token);
            if (underlyingIdx != conversions[i].underlying.length) {
                sum -= conversions[i].underlyingValues[underlyingIdx];
            }
        }
    }

    function sumAfter(Conversion[] memory conversions, uint256 idx, address token) internal pure returns (uint256 sum) {
        for (uint256 i = idx; i < conversions.length; i++) {
            uint256 underlyingIdx = conversions[i].underlying.findFirst(token);
            if (underlyingIdx != conversions[i].underlying.length) {
                sum += conversions[i].underlyingValues[underlyingIdx];
            }
        }
    }

    function normalizeRatios(Conversion[] memory self) internal pure returns (Conversion[] memory) {
        for (uint256 i = 0; i < self.length; i++) {
            for (uint256 j = 0; j < self[i].underlying.length; j++) {
                if (!_isBasic(self, self[i].underlying[j])) continue;
                uint256 sum = sumAfter(self, i, self[i].underlying[j]);
                self[i].underlyingValues[j] = sum > 0 ? (self[i].underlyingValues[j] * 1e18) / sum : 1e18;
            }
        }
        for (uint256 i = 0; i < self.length; i++) {
            for (uint256 j = 0; j < self[i].underlying.length; j++) {
                if (_isBasic(self, self[i].underlying[j])) continue;
                uint256 sum = sumPrior(self, i, self[i].underlying[j]);
                self[i].underlyingValues[j] = sum > 0 ? (self[i].underlyingValues[j] * 1e18) / sum : 1e18;
            }
        }
        return self;
    }
}