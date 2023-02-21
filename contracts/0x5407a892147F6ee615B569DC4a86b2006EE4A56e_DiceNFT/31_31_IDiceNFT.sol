// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum Material {
    Amber,
    Amethyst,
    Ruby,
    Sapphire,
    Spinel,
    Topaz
}

enum DieType {
    D4,
    D6,
    D8,
    D10,
    D12,
    D20
}

enum ElementalType {
    Dark,
    Space,
    Time,
    Psychic,
    Light
}

library MaterialUtil {
    function toString(Material _material)
        internal
        pure
        returns (string memory)
    {
        if (_material == Material.Amber) {
            return "Amber";
        } else if (_material == Material.Amethyst) {
            return "Amethyst";
        } else if (_material == Material.Ruby) {
            return "Ruby";
        } else if (_material == Material.Sapphire) {
            return "Sapphire";
        } else if (_material == Material.Spinel) {
            return "Spinel";
        } else {
            return "Topaz";
        }
    }
}

library DiceTypeUtil {
    function toString(DieType _type) internal pure returns (string memory) {
        if (_type == DieType.D4) {
            return "D4";
        } else if (_type == DieType.D6) {
            return "D6";
        } else if (_type == DieType.D8) {
            return "D8";
        } else if (_type == DieType.D10) {
            return "D10";
        } else if (_type == DieType.D12) {
            return "D12";
        } else {
            return "D20";
        }
    }
}

library ElementalTypeUtil {
    function toString(ElementalType _el) internal pure returns (string memory) {
        if (_el == ElementalType.Dark) {
            return "Dark";
        } else if (_el == ElementalType.Space) {
            return "Space";
        } else if (_el == ElementalType.Time) {
            return "Time";
        } else if (_el == ElementalType.Psychic) {
            return "Psychic";
        } else {
            return "Light";
        }
    }
}

library DiceBitmapUtil {
    function getDiceType(uint48 bitmap, uint8 diceIdx)
        internal
        pure
        returns (DieType)
    {
        // 3 bits type, then 3 bits material. This is repeated 7 times perDiceIdx
        uint256 shiftAmount = diceIdx * 6;
        // 7 as mask, which is 111, to get three bits
        uint8 typeBit = uint8((bitmap & (7 << shiftAmount)) >> shiftAmount);
        return DieType(typeBit);
    }

    function getDiceMaterial(uint48 bitmap, uint8 diceIdx)
        internal
        pure
        returns (Material)
    {
        uint256 shiftAmount = diceIdx * 6 + 3;
        uint8 typeBit = uint8((bitmap & (7 << shiftAmount)) >> shiftAmount);
        return Material(typeBit);
    }

    function getElementType(uint48 bitmap)
        internal
        pure
        returns (ElementalType)
    {
        uint256 shiftAmount = 7 * 6; // after last/7th dice
        uint8 typeBit = uint8((bitmap & (7 << shiftAmount)) >> shiftAmount);
        return ElementalType(typeBit);
    }
}

interface IDiceNFT {
    struct DiceMetadata {
        uint48 bitmap;
        uint8 amount;
        uint8 power;
    }

    event BoostUpdated(uint256 indexed tokenId, uint256 newBoostCount);

    function setOriginalMetadata(
        DiceMetadata[] calldata originalMetadata,
        uint128 _startIndex,
        uint128 _endIndex
    ) external;

    function resetBoosts(uint256 _newDefaultBoostCount) external;

    function useBoost(uint256 tokenId, uint256 count) external;

    function setBoostCount(uint256 tokenId, uint16 boostCount) external;

    function mint(address _to, uint256 _oldTokenId) external;

    function batchMint(address _to, uint256[] calldata _oldTokenIds) external;

    function getDiceBoosts(uint256 _tokenId) external view returns (uint256);

    function getDiceMaterials(uint256 _tokenId)
        external
        view
        returns (string[] memory);

    function getDiceMetadata(uint256 _tokenId)
        external
        view
        returns (DiceMetadata memory);
}