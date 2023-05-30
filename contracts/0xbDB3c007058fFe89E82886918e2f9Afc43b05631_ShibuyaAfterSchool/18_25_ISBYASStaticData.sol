// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ISBYASStaticData {
    enum Hair {
        Bob,
        Braid,
        Bun,
        Curly,
        Lob,
        Long,
        Medium,
        Messy,
        Osage,
        Pigtail,
        Ponytail,
        Short,
        SideBangs,
        Twintail
    }
    enum HairColor {
        Beige,
        Black,
        Blue,
        Brown,
        Charcoal,
        Green,
        Grey,
        LightBlue,
        Magenta,
        Navy,
        Orange,
        Pink,
        Red,
        RedBrown,
        Silver,
        Turquoise,
        Violet,
        Yellow
    }
    enum EyeColor {
        Grey,
        Iris,
        Lime,
        LiteBlue,
        Mint,
        Orange,
        Pink,
        Purple,
        Rose,
        Ruby,
        Sakura,
        Salmon,
        Yellow
    }
    enum SchoolUniform {
        Crow,
        Hayabusa,
        Swallow,
        Swan
    }
    enum Accessory {
        None,
        FoxMask,
        Glasses
    }
    enum Phase {
        BeforeMint,
        WLMint,
        PublicMint,
        MintByTokens
    }

    struct Character {
        Hair hair;
        HairColor hairColor;
        EyeColor eyeColor;
        SchoolUniform schoolUniform;
        Accessory accessory;
        string name;
        uint256 imageId;
    }

    function hairText(Hair hair) external pure returns (string memory);

    function hairColorText(HairColor hairColor) external pure returns (string memory);

    function eyeColorText(EyeColor eyeColor) external pure returns (string memory);

    function schoolUniformText(SchoolUniform schoolUniform) external pure returns (string memory);

    function accessoryText(Accessory accessory) external pure returns (string memory);

    function createMetadata(Character calldata char, string calldata image) external pure returns (string memory);
}