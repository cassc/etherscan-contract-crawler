// SPDX-License-Identifier: GPL-3.0
import '../base/IZombieMetadata.sol';
import '../base/ISurvivorFactory.sol';
import '../base/IMetadataBuilder.sol';
import '../base/IMetadataFactory.sol';
import "../base/IVRF.sol";
import '../base/Strings.sol';
import "../main/ProxyTarget.sol";

pragma solidity ^0.8.0;

/// @title MetadataFactory
/// @notice Provides metadata utility functions for creation
contract MetadataFactory is IMetadataFactory, ProxyTarget {

	bool public initialized;
    IZombieMetadata zombieMetadata;
    ISurvivorFactory survivorFactory;
    IMetadataBuilder metadataBuilder;
    IVRF public randomNumberGenerator;

    uint _nonce;

    function initialize(address _zombieMetadata, address _survivorFactory, address _metadataBuilder, address _randomNumberGenerator) external {
        require(msg.sender == _getAddress(ADMIN_SLOT), "not admin");
        require(!initialized);
        initialized = true;

        zombieMetadata = IZombieMetadata(_zombieMetadata);
        survivorFactory = ISurvivorFactory(_survivorFactory);
        metadataBuilder = IMetadataBuilder(_metadataBuilder);
        randomNumberGenerator = IVRF(_randomNumberGenerator);
    }

    function setRandomNumberGenerator(address _randomEngineAddress) external {
        require(msg.sender == _getAddress(ADMIN_SLOT), "not admin");
        randomNumberGenerator = IVRF(_randomEngineAddress);
    }

    function constructNft(uint8 nftType, uint8[] memory traits, uint8 level) public pure override returns(nftMetadata memory) {
        nftMetadata memory nft;
        nft.nftType = nftType;
        nft.traits = traits;
        nft.level = level;
        return nft;
    }

    function buildMetadata(nftMetadata memory nft, bool survivor,uint id) public view override returns(string memory) {
        return metadataBuilder.buildMetadata(nft, survivor, id);
    }

    function levelUpMetadata(nftMetadata memory nft) public override returns (nftMetadata memory) {
        
        if(nft.nftType == 0) {
            return createRandomMetadata(nft.level + 1, nft.nftType);
        } else {
            //So basically the rule is that if an item availability ends at a set level it persists. If the availability continues it re-rolls for non base traits
            return levelUpSurvivor(nft);
        }
    }

    function levelUpSurvivor(nftMetadata memory nft) public returns (nftMetadata memory) {
        
        //increment level here
        nft.level++;
        uint8[] memory traits = new uint8[](12);

        { //Base traits remain consistent through leveling up
            traits[0] = nft.traits[0];
            traits[1] = nft.traits[1];
            traits[2] = nft.traits[2];
            traits[3] = nft.traits[3];
            traits[4] = nft.traits[4];
            traits[5] = nft.traits[5];
            traits[6] = nft.traits[6];
        }

        {
            //re roll this
            uint8 chestArmorTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorChestArmorTraitCount(nft.level),_nonce++));
            traits[7] = chestArmorTrait;
            //re roll this
            uint8 shoulderArmorTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorShoulderArmorTraitCount(nft.level),_nonce++)); 
            traits[8] = shoulderArmorTrait;
            
            //persist - if it's already set
            if(nft.traits[9] == 0) {
                uint8 legArmorTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorLegArmorTraitCount(nft.level),_nonce++)); 
                traits[9] = legArmorTrait > 0 ? legArmorTrait : nft.traits[9];
            } else traits[9] = nft.traits[9];
    
            //persist - if level is > 2
            if(nft.level <= 2) {
                uint8 rightWeaponTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorRightWeaponTraitCount(nft.level),_nonce++));
                traits[10] = rightWeaponTrait;
            } else traits[10] = nft.traits[10];

            //re roll this
            uint8 leftWeaponTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorLeftWeaponTraitCount(nft.level),_nonce++));
            traits[11] = leftWeaponTrait;
        }
        
        return constructNft(nft.nftType, traits, nft.level);
    }

    function createRandomMetadata(uint8 level, uint8 tokenType) public override returns(nftMetadata memory) {

        uint8[] memory traits;
        // bool canClaim;
        // uint stakedTime;
        // uint lastClaimTime;
        //uint8 nftType = 0;//implement random here between 0 and 1

        if(tokenType == 0) {
            (traits, level) = createRandomZombie(level);
        } else {
            (traits, level) = createRandomSurvivor(level);
        }

        return constructNft(tokenType, traits, level);
    }

    function createRandomZombie(uint8 level) public override returns(uint8[] memory, uint8) {
        return (
            randomZombieTraits(level),
            level
        );
    }

    function randomZombieTraits(uint8 level) public returns(uint8[] memory) {
        uint8[] memory traits = new uint8[](5);

        uint8 torsoTrait = uint8(randomNumberGenerator.getRange(1, zombieMetadata.zombieTorsoTraitCount(level),_nonce++));
        traits[0] = torsoTrait;
        uint8 leftArmTrait = uint8(randomNumberGenerator.getRange(1, zombieMetadata.zombieLeftArmTraitCount(level),_nonce++)); 
        traits[1] = leftArmTrait;
        uint8 rightArmTrait = uint8(randomNumberGenerator.getRange(1, zombieMetadata.zombieRightArmTraitCount(level),_nonce++));
        traits[2] = rightArmTrait;
        uint8 legsTrait = uint8(randomNumberGenerator.getRange(1, zombieMetadata.zombieLegsTraitCount(level),_nonce++)); 
        traits[3] = legsTrait;
        uint8 headTrait = uint8(randomNumberGenerator.getRange(1, zombieMetadata.zombieHeadTraitCount(level),_nonce++)); 
        traits[4] = headTrait;

        return traits;
    }

    function createRandomSurvivor(uint8 level) public override returns(uint8[] memory, uint8) {
        return (
            randomSurvivorTraits(level),
            level
        );
    }

    function randomSurvivorTraits(uint8 level) public returns(uint8[] memory) {
        uint8[] memory traits = new uint8[](12);

            {
                uint8 shoesTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorShoesTraitCount(),_nonce++)); 
                traits[0] = shoesTrait;
                uint8 pantsTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorPantsTraitCount(),_nonce++));
                traits[1] = pantsTrait;
                uint8 bodyTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorBodyTraitCount(),_nonce++)); 
                traits[2] = bodyTrait;
                uint8 beardTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorBeardTraitCount(),_nonce++)); 
                traits[3] = beardTrait;
                uint8 hairTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorHairTraitCount(),_nonce++)); 
                traits[4] = hairTrait;
                uint8 headTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorHeadTraitCount(),_nonce++)); 
                traits[5] = headTrait;
                uint8 shirtTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorShirtTraitCount(),_nonce++)); 
                traits[6] = shirtTrait;
            }

            {
                uint8 chestArmorTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorChestArmorTraitCount(level),_nonce++));
                traits[7] = chestArmorTrait;
                uint8 shoulderArmorTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorShoulderArmorTraitCount(level),_nonce++)); 
                traits[8] = shoulderArmorTrait;
                uint8 legArmorTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorLegArmorTraitCount(level),_nonce++)); 
                traits[9] = legArmorTrait;
                uint8 rightWeaponTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorRightWeaponTraitCount(level),_nonce++));
                traits[10] = rightWeaponTrait;
                uint8 leftWeaponTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorLeftWeaponTraitCount(level),_nonce++));
                traits[11] = leftWeaponTrait;
            }
            return traits;
    }


    function survivorMetadataBytes(nftMetadata memory survivor,uint id) public view returns(bytes memory) {
        return metadataBuilder.survivorMetadataBytes(survivor, id);
    }

    function survivorTraitsMetadata(nftMetadata memory survivor) public view returns(string memory) {

        string memory traits1;
        string memory traits2;

        {
            traits1 = string(abi.encodePacked(
                '", "shoes":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Shoes, survivor.level, survivor.traits[0]),
                '", "pants":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Pants, survivor.level, survivor.traits[1]),
                '", "body":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Body, survivor.level, survivor.traits[2]),
                '", "beard":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Beard, survivor.level, survivor.traits[3]),
                '", "hair":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Hair, survivor.level, survivor.traits[4]),
                '", "head":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Head, survivor.level, survivor.traits[5])
            ));
        }

        {
            traits2 = string(abi.encodePacked(
                '", "shirt":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Shirt, survivor.level, survivor.traits[6]),
                '", "chest armor":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.ChestArmor, survivor.level, survivor.traits[7]),
                '", "shoulder armor":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.ShoulderArmor, survivor.level, survivor.traits[8]),
                '", "leg armor":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.LegArmor, survivor.level, survivor.traits[9]),
                '", "right weapon":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.RightWeapon, survivor.level, survivor.traits[10]),
                '", "left weapon":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.LeftWeapon, survivor.level, survivor.traits[11])
            ));
        }

        return string(abi.encodePacked(traits1, traits2));
    }

    function zombieMetadataBytes(nftMetadata memory zombie,uint id) public view returns(bytes memory) {
        return metadataBuilder.zombieMetadataBytes(zombie, id);
    }
    
}