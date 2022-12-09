// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './interface/IISBStaticData.sol';

contract ISBStaticData is IISBStaticData, ERC165 {
    using Strings for uint256;
    using Strings for uint16;

    function generationText(Generation gen) public pure override returns (string memory) {
        if (gen == Generation.GEN0) {
            return 'GEN0';
        } else if (gen == Generation.GEN05) {
            return 'GEN0.5';
        } else if (gen == Generation.GEN1) {
            return 'GEN1';
        } else {
            return '';
        }
    }

    function weaponTypeText(WeaponType weaponType) public pure override returns (string memory) {
        if (weaponType == WeaponType.Sword) {
            return 'Sword';
        } else if (weaponType == WeaponType.TwoHand) {
            return 'TwoHand';
        } else if (weaponType == WeaponType.Fists) {
            return 'Fists';
        } else if (weaponType == WeaponType.Bow) {
            return 'Bow';
        } else if (weaponType == WeaponType.Staff) {
            return 'Staff';
        } else {
            return '';
        }
    }

    function armorTypeText(ArmorType armorType) public pure override returns (string memory) {
        if (armorType == ArmorType.HeavyArmor) {
            return 'HeavyArmor';
        } else if (armorType == ArmorType.LightArmor) {
            return 'LightArmor';
        } else if (armorType == ArmorType.Robe) {
            return 'Robe';
        } else if (armorType == ArmorType.Cloak) {
            return 'Cloak';
        } else if (armorType == ArmorType.TribalWear) {
            return 'TribalWear';
        } else {
            return '';
        }
    }

    function sexTypeText(SexType sexType) public pure override returns (string memory) {
        if (sexType == SexType.Male) {
            return 'Male';
        } else if (sexType == SexType.Female) {
            return 'Female';
        } else if (sexType == SexType.Hermaphrodite) {
            return 'Hermaphrodite';
        } else if (sexType == SexType.Unknown) {
            return 'Unknown';
        } else {
            return '';
        }
    }

    function speciesTypeText(SpeciesType speciesType) public pure override returns (string memory) {
        if (speciesType == SpeciesType.Human) {
            return 'Human';
        } else if (speciesType == SpeciesType.Elf) {
            return 'Elf';
        } else if (speciesType == SpeciesType.Dwarf) {
            return 'Dwarf';
        } else if (speciesType == SpeciesType.Demon) {
            return 'Demon';
        } else if (speciesType == SpeciesType.Merfolk) {
            return 'Merfolk';
        } else if (speciesType == SpeciesType.Therianthrope) {
            return 'Therianthrope';
        } else if (speciesType == SpeciesType.Vampire) {
            return 'Vampire';
        } else if (speciesType == SpeciesType.Angel) {
            return 'Angel';
        } else if (speciesType == SpeciesType.Unknown) {
            return 'Unknown';
        } else if (speciesType == SpeciesType.Dragonewt) {
            return 'Dragonewt';
        } else if (speciesType == SpeciesType.Monster) {
            return 'Monster';
        } else {
            return '';
        }
    }

    function heritageTypeText(HeritageType heritageType) public pure override returns (string memory) {
        if (heritageType == HeritageType.LowClass) {
            return 'LowClass';
        } else if (heritageType == HeritageType.MiddleClass) {
            return 'MiddleClass';
        } else if (heritageType == HeritageType.HighClass) {
            return 'HighClass';
        } else if (heritageType == HeritageType.Unknown) {
            return 'Unknown';
        } else {
            return '';
        }
    }

    function personalityTypeText(PersonalityType personalityType) public pure override returns (string memory) {
        if (personalityType == PersonalityType.Cool) {
            return 'Cool';
        } else if (personalityType == PersonalityType.Serious) {
            return 'Serious';
        } else if (personalityType == PersonalityType.Gentle) {
            return 'Gentle';
        } else if (personalityType == PersonalityType.Optimistic) {
            return 'Optimistic';
        } else if (personalityType == PersonalityType.Rough) {
            return 'Rough';
        } else if (personalityType == PersonalityType.Diffident) {
            return 'Diffident';
        } else if (personalityType == PersonalityType.Pessimistic) {
            return 'Pessimistic';
        } else if (personalityType == PersonalityType.Passionate) {
            return 'Passionate';
        } else if (personalityType == PersonalityType.Unknown) {
            return 'Unknown';
        } else if (personalityType == PersonalityType.Frivolous) {
            return 'Frivolous';
        } else if (personalityType == PersonalityType.Confident) {
            return 'Confident';
        } else {
            return '';
        }
    }

    function createMetadata(
        uint256 tokenId,
        Character calldata char,
        Metadata calldata metadata,
        uint16[] calldata status,
        StatusMaster[] calldata statusMaster,
        string calldata image,
        Generation generation
    ) public pure override returns (string memory) {
        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "Name","value": "',
            char.name,
            '"},{"trait_type": "Generation Type","value": "',
            generationText(generation),
            abi.encodePacked(
                '"},{"trait_type": "Weapon","value": "',
                weaponTypeText(char.weapon),
                '"},{"trait_type": "Armor","value": "',
                armorTypeText(char.armor),
                '"},{"trait_type": "Sex","value": "',
                sexTypeText(char.sex),
                '"},{"trait_type": "Species","value": "',
                speciesTypeText(char.species),
                '"},{"trait_type": "Heritage","value": "',
                heritageTypeText(char.heritage),
                '"},{"trait_type": "Personality","value": "',
                personalityTypeText(char.personality)
            ),
            '"},{"trait_type": "Used Seed","value": ',
            metadata.seedHistory.length.toString(),
            '},{"trait_type": "Level","value": ',
            metadata.level.toString(),
            '}',
            statusMaster.length == 0 ? ',' : ''
        );
        for (uint256 i = 0; i < statusMaster.length; i++) {
            if (i == 0) attributes = abi.encodePacked(attributes, ',');
            attributes = abi.encodePacked(
                attributes,
                '{"trait_type": "',
                statusMaster[i].statusText,
                '","value": ',
                status[i].toString(),
                '}',
                i == statusMaster.length - 1 ? '' : ','
            );
        }
        bytes memory dataURI = abi.encodePacked(
            '{"name": "',
            char.name,
            ' #',
            tokenId.toString(),
            '","description": "When the seven Fragments come together,  \\nThe lost power of the gods will be revived and unleashed.  \\n  \\nExplore the Isekai, Turkenista, and defeat your rivals to collect Fragments (NFT)! Combining the Fragments will bring back SINKI blessing you with overflowing SINN(ERC20)!   \\n  \\nYou will need 3 or more characters to play this fully on-chain game on the Ethereum blockchain.  \\n  \\nBattle for NFTs!","image": "',
            image,
            '","attributes": [',
            attributes,
            ']}'
        );

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(dataURI)));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IISBStaticData).interfaceId || super.supportsInterface(interfaceId);
    }
}