// SPDX-License-Identifier: GPL-3.0
import '../base/Base64.sol';
import '../base/IZombieMetadata.sol';
import '../base/ISurvivorFactory.sol';
import "../base/IMetadataFactory.sol";
import '../base/Strings.sol';
import "../main/ProxyTarget.sol";

pragma solidity ^0.8.0;

/// @title MetadataBuilder
/// @notice Provides metadata builder utility functions for MetadataFactory
contract MetadataBuilder is ProxyTarget {

	bool public initialized;
    IZombieMetadata zombieMetadata;
    ISurvivorFactory survivorFactory;
    
    IMetadataFactory metadataFactory;

    function initialize(address _metaFactory, address _zombieMetadata, address _survivorFactory) external {
        require(msg.sender == _getAddress(ADMIN_SLOT), "not admin");
        require(!initialized);
        initialized = true;

        metadataFactory = IMetadataFactory(_metaFactory);
        zombieMetadata = IZombieMetadata(_zombieMetadata);
        survivorFactory = ISurvivorFactory(_survivorFactory);
    }

    function buildMetadata(IMetadataFactory.nftMetadata memory nft, bool survivor,uint id) public view returns(string memory) {

        if(survivor) {
            return string(abi.encodePacked(
                    'data:application/json;base64,', Base64.encode(survivorMetadataBytes(nft,id))));
        } else {
            return string(abi.encodePacked(
                    'data:application/json;base64,', Base64.encode(zombieMetadataBytes(nft,id))));
        }
    }

    function survivorMetadataBytes(IMetadataFactory.nftMetadata memory survivor,uint id) public view returns(bytes memory) {
        string memory firstHalf = string(abi.encodePacked(
                '{"name":"',
                'Survivor #',
                Strings.toString(id),
                '", "description":"',
                'Hunger Brainz is a 100% on-chain wargame of Zombies vs. Survivors with high risk and even higher rewards',
                '", "image":"',
                'data:image/svg+xml;base64,',
                Base64.encode(survivorFactory.survivorSVG(survivor.level, survivor.traits)),
                '", "attributes":[',
                '{"trait_type":"Character Type","value":"Survivor"},',
                '{"trait_type":"Level","value":',
                    Strings.toString(survivor.level),
                '},',
                '{"trait_type":"Shoes","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Shoes, survivor.level, survivor.traits[0]),
                '},',
                '{"trait_type":"Pants","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Pants,  survivor.level, survivor.traits[1]),
                '},',
                '{"trait_type":"Body","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Body,  survivor.level, survivor.traits[2]),
                '},',
                '{"trait_type":"Beard","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Beard,  survivor.level, survivor.traits[3]),
                '},',
                '{"trait_type":"Hair","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Hair,  survivor.level, survivor.traits[4]),
                '},',
                '{"trait_type":"Head","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Head,  survivor.level, survivor.traits[5]),
                '},'
                
                ));

        string memory secondHalf = string(abi.encodePacked(
            '{"trait_type":"Shirt","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Shirt, survivor.level, survivor.traits[6]),
                '},',
            '{"trait_type":"Chest Armor","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.ChestArmor, survivor.level, survivor.traits[7]),
                '},',
                '{"trait_type":"Shoulder Armor","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.ShoulderArmor, survivor.level, survivor.traits[8]),
                '},',
                '{"trait_type":"Leg Armor","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.LegArmor, survivor.level, survivor.traits[9]),
                '},',
                '{"trait_type":"Right Weapon","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.RightWeapon, survivor.level, survivor.traits[10]),
                '},',
                '{"trait_type":"Left Weapon","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.LeftWeapon, survivor.level, survivor.traits[11]),
                '}',
                ']',
                '}'
        ));
        return bytes(abi.encodePacked(firstHalf,secondHalf));
    }

    function zombieMetadataBytes(IMetadataFactory.nftMetadata memory zombie,uint id) public view returns(bytes memory) {
        // string memory id = "1";
        return bytes(
            abi.encodePacked(
                '{"name":"',
                'Zombie #',
                Strings.toString(id),
                '", "description":"',
                'Hunger Brainz is a 100% on-chain wargame of Zombies vs. Survivors with high risk and even higher rewards',
                '", "image":"',
                'data:image/svg+xml;base64,',
                Base64.encode(zombieMetadata.zombieSVG(zombie.level, zombie.traits)),
                '", "attributes":[',
                '{"trait_type":"Character Type","value":"Zombie"},',
                '{"trait_type":"Level","value":',
                    Strings.toString(zombie.level),
                '},',
                '{"trait_type":"Torso","value":',
                    zombieMetadata.zombieTrait(IZombieMetadata.ZombieTrait.Torso, zombie.level, zombie.traits[0]),
                '},',
                '{"trait_type":"Left Arm","value":',
                    zombieMetadata.zombieTrait(IZombieMetadata.ZombieTrait.LeftArm, zombie.level, zombie.traits[1]),
                '},',
                '{"trait_type":"Right Arm","value":',
                    zombieMetadata.zombieTrait(IZombieMetadata.ZombieTrait.RightArm, zombie.level, zombie.traits[2]),
                '},',
                '{"trait_type":"Legs","value":',
                    zombieMetadata.zombieTrait(IZombieMetadata.ZombieTrait.Legs, zombie.level, zombie.traits[3]),
                '},',
                '{"trait_type":"Head","value":',
                    zombieMetadata.zombieTrait(IZombieMetadata.ZombieTrait.Head, zombie.level, zombie.traits[4]),
                '}',
                ']',
                '}'
            )
        );
    }
    
}