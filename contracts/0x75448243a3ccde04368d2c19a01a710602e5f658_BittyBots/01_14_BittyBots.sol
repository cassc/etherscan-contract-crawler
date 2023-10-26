// contracts/BittyBots.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./UIntArrays.sol";

/**
 * 
 * ╔══╦╦══╦══╦═╦╦══╦═╦══╦══╗
 * ║╔╗╠╬╗╔╩╗╔╩╗║║╔╗║║╠╗╔╣══╣
 * ║╔╗║║║║─║║╔╩╗║╔╗║║║║║╠══║
 * ╚══╩╝╚╝─╚╝╚══╩══╩═╝╚╝╚══╝
 *
 * This contract was written by solazy.eth (twitter.com/_solazy). 
 * https://bittybots.io
 * © BittyBots NFT LLC. All rights reserved 
 */

interface IChubbies {
    function ownerOf(uint tokenId) external view returns (address owner);
    function tokensOfOwner(address _owner) external view returns(uint[] memory);
}

interface IJusticeToken {
    function burnFrom(address account, uint256 amount) external;
    function updateLastWithdrawTime(uint _tokenId) external;
}

contract BittyBots is ERC721Enumerable, Ownable  {
    // Generation Related Variables
    struct BittyBot {
        uint helmet;
        uint body;
        uint face;
        uint arms;
        uint engine;
        uint botType;
        uint accessories;
        uint setModifier;
        uint combinedCount;
        uint powerClass;
        uint power;
    }

    mapping(bytes32 => uint) private hashToTokenId;
    mapping(uint => uint) private bittyBots;
    mapping(uint256 => uint256[]) public combinations;

    uint public constant NUM_TRAITS = 7;
    uint public constant NUM_CORE_TRAITS = 6;
    uint public constant NUM_MODELS = 16;
    uint public combinedId = 20000;

    uint public constant TRAIT_INDEX_HELMET = 0;
    uint public constant TRAIT_INDEX_BODY = 1;
    uint public constant TRAIT_INDEX_FACE = 2;
    uint public constant TRAIT_INDEX_ARMS = 3;
    uint public constant TRAIT_INDEX_ENGINE = 4;
    uint public constant TRAIT_INDEX_TYPE = 5;
    uint public constant TRAIT_INDEX_ACCESSORIES = 6;

    uint[NUM_TRAITS] private traitSizes;
    uint[NUM_TRAITS] private traitCounts;
    uint[NUM_TRAITS] private traitRemaining;
    uint public specialBotRemaining;
    
    uint private fallbackModelProbabilities;
    uint private fallbackEngineProbabilities;

    bytes32[NUM_TRAITS] public traitCategories;
    bytes32[][NUM_TRAITS] public traitNames;

    event BittyBotMinted(
        uint indexed tokenId,
        uint[] traits, 
        uint setModifier,
        uint combinedCount,
        uint powerClass,
        uint power
    );

    // ERC721 Sales Related Variables
    uint public constant TOKEN_LIMIT = 20000;
    uint private constant RESERVE_LIMIT = 500;
    uint private constant MAX_CHUBBIES = 10000;
    uint internal constant PRICE = 35000000000000000;

    bool public isSaleActive = false;
    bool public isFreeClaimActive = false;
    bool public isFinalSaleActive = false;

    IChubbies public chubbiesContract;
    IJusticeToken public justiceTokenContract;

    uint public numSold = 0;
    uint public numClaimed = 2;

    string private _baseTokenURI;

    // Withdraw Addresses
    address payable private solazy;
    address payable private kixboy;

    constructor() ERC721("BittyBots","BITTY")  {
        traitSizes = [NUM_MODELS, NUM_MODELS, NUM_MODELS, NUM_MODELS, 10, 4, 7];

        uint[] memory modelDistribution = new uint[](traitSizes[TRAIT_INDEX_HELMET]);
        uint[] memory engineDistribution = new uint[](traitSizes[TRAIT_INDEX_ENGINE]);
        uint[] memory typeDistribution = new uint[](traitSizes[TRAIT_INDEX_TYPE]);
        uint[] memory accessoryDistribution = new uint[](traitSizes[TRAIT_INDEX_ACCESSORIES]);
        uint[] memory specialModelDistribution = new uint[](traitSizes[TRAIT_INDEX_HELMET]);

        traitCounts[TRAIT_INDEX_HELMET] = UIntArrays.packedUintFromArray(modelDistribution);
        traitCounts[TRAIT_INDEX_BODY] = UIntArrays.packedUintFromArray(modelDistribution);
        traitCounts[TRAIT_INDEX_FACE] = UIntArrays.packedUintFromArray(modelDistribution);
        traitCounts[TRAIT_INDEX_ARMS] = UIntArrays.packedUintFromArray(modelDistribution);
        traitCounts[TRAIT_INDEX_ENGINE] = UIntArrays.packedUintFromArray(engineDistribution);
        traitCounts[TRAIT_INDEX_TYPE] = UIntArrays.packedUintFromArray(typeDistribution);
        traitCounts[TRAIT_INDEX_ACCESSORIES] = UIntArrays.packedUintFromArray(accessoryDistribution);

        modelDistribution[0] = 4; 
        for (uint i = 1; i < 13; i++) {
            modelDistribution[i] = 1600; 
        }
        modelDistribution[13] = 360; 
        modelDistribution[14] = 240;
        modelDistribution[15] = 151; 
        for (uint i = 1; i < specialModelDistribution.length; i++) {
            specialModelDistribution[i] = 3; 
        }
        engineDistribution[0] = 4800;
        engineDistribution[1] = 4000;
        engineDistribution[2] = 3200;
        engineDistribution[3] = 2400;
        engineDistribution[4] = 1600;
        engineDistribution[5] = 1600;
        engineDistribution[6] = 1200;
        engineDistribution[7] = 555;
        engineDistribution[8] = 400;
        engineDistribution[9] = 200;
        typeDistribution[0] = 19955;
        typeDistribution[1] = 15;
        typeDistribution[2] = 15;
        typeDistribution[3] = 15;
        accessoryDistribution[0] = 19335;
        accessoryDistribution[1] = 200;
        accessoryDistribution[2] = 200;
        accessoryDistribution[3] = 100;
        accessoryDistribution[4] = 100;
        accessoryDistribution[5] = 10;
        accessoryDistribution[6] = 10;

        traitRemaining[TRAIT_INDEX_HELMET] = UIntArrays.packedUintFromArray(modelDistribution);
        traitRemaining[TRAIT_INDEX_BODY] = UIntArrays.packedUintFromArray(modelDistribution);
        traitRemaining[TRAIT_INDEX_FACE] = UIntArrays.packedUintFromArray(modelDistribution);
        traitRemaining[TRAIT_INDEX_ARMS] = UIntArrays.packedUintFromArray(modelDistribution);
        traitRemaining[TRAIT_INDEX_ENGINE] = UIntArrays.packedUintFromArray(engineDistribution);
        traitRemaining[TRAIT_INDEX_TYPE] = UIntArrays.packedUintFromArray(typeDistribution);
        traitRemaining[TRAIT_INDEX_ACCESSORIES] = UIntArrays.packedUintFromArray(accessoryDistribution);
        specialBotRemaining = UIntArrays.packedUintFromArray(specialModelDistribution);

        fallbackModelProbabilities = UIntArrays.packedUintFromArray(modelDistribution);
        fallbackEngineProbabilities = UIntArrays.packedUintFromArray(engineDistribution);

        traitCategories = [
            bytes32("Helmet"),
            bytes32("Body"),
            bytes32("Face"),
            bytes32("Arms"),
            bytes32("Engine"),
            bytes32("Type"), 
            bytes32("Accessory")
        ];

        bytes32[NUM_MODELS] memory modelNames = [
            bytes32("MXX Torva"),
            bytes32("M01 Ava"),
            bytes32("M02 Shadow King"),
            bytes32("M03 Eni"),
            bytes32("M04 Ultra 7.1"),
            bytes32("M05 Titan"),
            bytes32("M06 Solar Phantom"),
            bytes32("M07 Cyberkat"),
            bytes32("M08 Ziggy"),
            bytes32("M09 Bakken"),
            bytes32("M10 Supaiku"),
            bytes32("M11 Neo"),
            bytes32("M12 Leapor"),
            bytes32("M13 Jupiter"),
            bytes32("M14 Mercury"),
            bytes32("M15 Morpheus")
        ];

        traitNames[TRAIT_INDEX_HELMET] = modelNames;
        traitNames[TRAIT_INDEX_BODY] = modelNames;
        traitNames[TRAIT_INDEX_ARMS] = modelNames;
        traitNames[TRAIT_INDEX_FACE] = modelNames;
        traitNames[TRAIT_INDEX_ENGINE] = [
            bytes32("Love"),
            bytes32("Fire"),
            bytes32("Starshine"),
            bytes32("Luna"),
            bytes32("Solaris"),
            bytes32("Diamond"),
            bytes32("Death"),
            bytes32("Lightning"), // lightning effect
            bytes32("Variable"), // glitch effect
            bytes32("Harmony"), // shiny effect
            bytes32("Error"), // glitchbot
            bytes32("Solid Gold"), // goldbot
            bytes32("Divinity") // godbot
        ];
        traitNames[TRAIT_INDEX_TYPE] = [
            bytes32("Classic"),
            bytes32("Glitch"),
            bytes32("Gold"),
            bytes32("God")
        ];
        traitNames[TRAIT_INDEX_ACCESSORIES] = [
            bytes32("None"),
            bytes32("Bomb"),
            bytes32("Exios Gem"),
            bytes32("Tuera Beam"),
            bytes32("Galactic Visor"),
            bytes32("BB1"),
            bytes32("Hacker Mode")
        ];

        _mintReservedGodBot(msg.sender, 0); // Chubbie #0
        _mintReservedGodBot(msg.sender, 9999); // #Chubbie #9999
        _mintReservedGodBot(msg.sender, 10000);
    }

    // BittyBot helpers

    // Packing optimization to save gas
    function setBittyBot(
        uint _tokenId,
        uint[] memory _traits,
        uint _setModifier,
        uint _combinedCount,
        uint _powerClass,
        uint _power
    ) internal {
        uint bittyBot = _traits[0];
        bittyBot |= _traits[1] << 8;
        bittyBot |= _traits[2] << 16;
        bittyBot |= _traits[3] << 24;
        bittyBot |= _traits[4] << 32;
        bittyBot |= _traits[5] << 40;
        bittyBot |= _traits[6] << 48;
        bittyBot |= _setModifier << 56;
        bittyBot |= _combinedCount << 64;
        bittyBot |= _powerClass << 72;
        bittyBot |= _power << 80;

        bittyBots[_tokenId] = bittyBot; 
    }

    function getBittyBot(uint _tokenId) internal view returns (BittyBot memory _bot) {
        uint bittyBot = bittyBots[_tokenId];
        _bot.helmet = uint256(uint8(bittyBot));
        _bot.body = uint256(uint8(bittyBot >> 8));
        _bot.face = uint256(uint8(bittyBot >> 16));
        _bot.arms = uint256(uint8(bittyBot >> 24));
        _bot.engine = uint256(uint8(bittyBot >> 32));
        _bot.botType = uint256(uint8(bittyBot >> 40));
        _bot.accessories = uint256(uint8(bittyBot >> 48));
        _bot.setModifier = uint256(uint8(bittyBot >> 56));
        _bot.combinedCount = uint256(uint8(bittyBot >> 64));
        _bot.powerClass = uint256(uint8(bittyBot >> 72));
        _bot.power = uint256(uint16(bittyBot >> 80));
    }

    function getTraitRemaining(uint _index) public view returns (uint[] memory) {
        return UIntArrays.arrayFromPackedUint(traitRemaining[_index], traitSizes[_index]);
    }

    function getTraitCounts(uint _index) public view returns (uint[] memory) {
        return UIntArrays.arrayFromPackedUint(traitCounts[_index], traitSizes[_index]);
    }

    // Hash is only determined by core traits and type
    function bittyHash(uint[] memory _traits) public pure returns (bytes32) {
        return UIntArrays.hash(_traits, NUM_CORE_TRAITS);
    }

    function isBotAvailable(uint _claimId) public view returns (bool) {
        return bittyBots[_claimId] == 0;
    }

    function isSpecialBot(uint[] memory _traits) public pure returns (bool) {
        return _traits[TRAIT_INDEX_TYPE] > 0;
    }

    function existTraits(uint[] memory _traits) public view returns (bool) {
        return tokenIdFromTraits(_traits) != 0;
    }

    function tokenIdFromTraits(uint[] memory _traits) public view returns (uint) {
        return hashToTokenId[bittyHash(_traits)];
    }

    function traitsForTokenId(uint _tokenId) public view returns (
        uint[] memory _traits, 
        uint _setModifier, 
        uint _combinedCount,
        uint _powerClass,
        uint _power
    ) {
        (_traits, _setModifier, _combinedCount, _powerClass, _power) = traitsFromBot(getBittyBot(_tokenId));
    }

    function traitsFromBot(BittyBot memory _bot) internal pure returns (
        uint[] memory _traits, 
        uint _setModifier, 
        uint _combinedCount, 
        uint _powerClass, 
        uint _power
    ) {
        _traits = new uint[](NUM_TRAITS);
        _traits[TRAIT_INDEX_HELMET] = _bot.helmet;
        _traits[TRAIT_INDEX_BODY] = _bot.body;
        _traits[TRAIT_INDEX_FACE] = _bot.face;
        _traits[TRAIT_INDEX_ARMS] = _bot.arms;
        _traits[TRAIT_INDEX_ENGINE] = _bot.engine;
        _traits[TRAIT_INDEX_TYPE] = _bot.botType;
        _traits[TRAIT_INDEX_ACCESSORIES] = _bot.accessories;

        _setModifier = _bot.setModifier;
        _combinedCount = _bot.combinedCount;
        _powerClass = _bot.powerClass;
        _power = _bot.power;
    }

    function strConcat(string memory _a, string memory _b) internal pure returns(string memory) {
        return string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function _mintBot(address _sendTo, uint _tokenId) internal {
        // 1. Try to get random traits from remaining
        uint dna = uint(keccak256(abi.encodePacked(msg.sender, _tokenId, block.difficulty, block.timestamp)));
        uint[] memory traits = randomTraits(dna);
        
        // 2. Try reroll with fixed probabillity model if we hit a duplicate (0.0002% of happening)
        if (existTraits(traits)) {
            uint offset = 0;
            do {
                traits = randomFallbackTraits(dna, offset);
                offset += 1;
                require(offset < 5, "Rerolled traits but failed");
            } while (existTraits(traits));
        }
        
        bytes32 hash = bittyHash(traits);
        hashToTokenId[hash] = _tokenId;
        uint setModifier = setModifierForParts(traits);
        uint power = estimatePowerForBot(traits, new uint[](0), setModifier);
        uint powerClass = powerClassForPower(power);
        setBittyBot(
            _tokenId,
            traits,
            setModifier,
            0,
            powerClass,
            power
        );

        // 3. Update info maps with special treatments for special bots
        if (isSpecialBot(traits)) {
            traitRemaining[TRAIT_INDEX_TYPE] = UIntArrays.decrementPackedUint(traitRemaining[TRAIT_INDEX_TYPE], traits[TRAIT_INDEX_TYPE], 1);
            traitCounts[TRAIT_INDEX_TYPE] = UIntArrays.incrementPackedUint(traitCounts[TRAIT_INDEX_TYPE], traits[TRAIT_INDEX_TYPE], 1);
            specialBotRemaining = UIntArrays.decrementPackedUint(specialBotRemaining, traits[TRAIT_INDEX_HELMET], 1);
        } else {
            for (uint i = 0; i < traits.length; i++) {
                traitRemaining[i] = UIntArrays.decrementPackedUint(traitRemaining[i], traits[i], 1);
                traitCounts[i] = UIntArrays.incrementPackedUint(traitCounts[i], traits[i], 1);
            }
            combinations[_tokenId].push(_tokenId);
        }
        
        _safeMint(_sendTo, _tokenId);
        emit BittyBotMinted(_tokenId, traits, setModifier, 0, powerClass, power);
    }

    function _mintReservedGodBot(address _sendTo, uint _tokenId) internal {
        require(_tokenId == 0 || _tokenId == 9999 || _tokenId == 10000, "Reserved god bots are for 0, 9999, and 10000.");
        uint dna = uint(keccak256(abi.encodePacked(msg.sender, _tokenId, block.difficulty, block.timestamp)));
        uint[] memory traits = new uint[](NUM_TRAITS);
        uint specialType = uint(keccak256(abi.encodePacked(dna))) % 3 + 1;
        uint modelIndex = UIntArrays.randomIndexFromWeightedArray(UIntArrays.arrayFromPackedUint(specialBotRemaining, traitSizes[TRAIT_INDEX_HELMET]),  
                                                                      uint(keccak256(abi.encodePacked(dna))));
        traits[TRAIT_INDEX_TYPE] = specialType;
        for (uint i = 0; i < TRAIT_INDEX_TYPE; i++) {
            traits[i] = modelIndex;
        }
        traits[TRAIT_INDEX_ENGINE] = traits[TRAIT_INDEX_TYPE] + 9;
        traits[TRAIT_INDEX_ACCESSORIES] = 0;

        bytes32 hash = bittyHash(traits);
        hashToTokenId[hash] = _tokenId;
        uint setModifier = setModifierForParts(traits);
        uint power = estimatePowerForBot(traits, new uint[](0), setModifier);
        uint powerClass = powerClassForPower(power);

        setBittyBot(
            _tokenId,
            traits,
            setModifier,
            0,
            powerClass,
            power
        );

        traitRemaining[TRAIT_INDEX_TYPE] = UIntArrays.decrementPackedUint(traitRemaining[TRAIT_INDEX_TYPE], traits[TRAIT_INDEX_TYPE], 1);
        traitCounts[TRAIT_INDEX_TYPE] = UIntArrays.incrementPackedUint(traitCounts[TRAIT_INDEX_TYPE], traits[TRAIT_INDEX_TYPE], 1);
        specialBotRemaining = UIntArrays.decrementPackedUint(specialBotRemaining, traits[TRAIT_INDEX_HELMET], 1);

        _safeMint(_sendTo, _tokenId);
        emit BittyBotMinted(_tokenId, traits, setModifier, 0, powerClass, power);
    }

    function randomTraits(uint _dna) internal view returns (uint[] memory) {
        uint[] memory traits = new uint[](NUM_TRAITS);
        for (uint i = 0; i < traitRemaining.length; i++) {
            traits[i] = UIntArrays.randomIndexFromWeightedArray(UIntArrays.arrayFromPackedUint(traitRemaining[i], traitSizes[i]),
                                                                uint(keccak256(abi.encodePacked(_dna, i + 1))));
        }

        // Special Bot Treatment
        if (isSpecialBot(traits)) {
            uint modelIndex = UIntArrays.randomIndexFromWeightedArray(UIntArrays.arrayFromPackedUint(specialBotRemaining, traitSizes[TRAIT_INDEX_HELMET]),  
                                                                      uint(keccak256(abi.encodePacked(_dna))));
            for (uint i = 0; i < TRAIT_INDEX_TYPE; i++) {
                traits[i] = modelIndex;
            }
            traits[TRAIT_INDEX_ENGINE] = traits[TRAIT_INDEX_TYPE] + 9;
            traits[TRAIT_INDEX_ACCESSORIES] = 0;
        }

        return traits;
    }

    function randomFallbackTraits(uint _dna, uint _offset) internal view returns (uint[] memory) {
        uint[] memory traits = new uint[](NUM_TRAITS);

        for (uint i = 0; i < 4; i++) {
            traits[i] = UIntArrays.randomIndexFromWeightedArray(UIntArrays.arrayFromPackedUint(fallbackModelProbabilities, traitSizes[i]), 
                                                                uint(keccak256(abi.encodePacked(_dna, _offset * i))));
        }
        
        traits[TRAIT_INDEX_ENGINE] = UIntArrays.randomIndexFromWeightedArray(UIntArrays.arrayFromPackedUint(fallbackEngineProbabilities, traitSizes[TRAIT_INDEX_ENGINE]), 
                                                                             uint(keccak256(abi.encodePacked(_dna, _offset * TRAIT_INDEX_ENGINE))));
        return traits;
    }

    function metadata(uint _tokenId) public view returns (string memory resultString) {
        if (_exists(_tokenId) == false) {
            return '{}';
        }
        resultString = '{';
        BittyBot memory bot = getBittyBot(_tokenId);
        (
            uint[] memory traits, 
            uint setModifier, 
            uint combinedCount, 
            uint powerClass, 
            uint power
        ) = traitsFromBot(bot);

        for (uint i = 0; i < traits.length; i++) {
            if (i > 0) {
                resultString = strConcat(resultString, ', ');
            }
            resultString = strConcat(resultString, '"');
            resultString = strConcat(resultString, bytes32ToString(traitCategories[i]));
            resultString = strConcat(resultString, '": "');
            resultString = strConcat(resultString, bytes32ToString(traitNames[i][traits[i]]));
            resultString = strConcat(resultString, '"');
        }

        resultString = strConcat(resultString, ', ');

        string[] memory valueCategories = new string[](4);
        valueCategories[0] = 'Full Set';
        valueCategories[1] = 'Combined';
        valueCategories[2] = 'Power Class';
        valueCategories[3] = 'Power';
        uint[] memory values = new uint[](4);
        values[0] = setModifier;
        values[1] = combinedCount;
        values[2] = powerClass;
        values[3] = power;

        for (uint i = 0; i < valueCategories.length; i++) {
            if (i > 0) {
                resultString = strConcat(resultString, ', ');
            }
            resultString = strConcat(resultString, '"');
            resultString = strConcat(resultString, valueCategories[i]);
            resultString = strConcat(resultString, '": ');
            resultString = strConcat(resultString, Strings.toString(values[i]));
        }

        resultString = strConcat(resultString, '}');

        return resultString;
    }

    // COMBINE
    function isSelectedTraitsEligible(uint[] memory _selectedTraits, uint[] memory _selectedBots) public view returns (bool) {
        BittyBot memory bot;
        uint[] memory traits;

        for (uint traitIndex = 0; traitIndex < _selectedTraits.length; traitIndex++) {
            bool traitCheck = false;
            for (uint botIndex = 0; botIndex < _selectedBots.length; botIndex++) {
                bot = getBittyBot(_selectedBots[botIndex]);
                (traits, , , , ) = traitsFromBot(bot);

                if (traits[traitIndex] == _selectedTraits[traitIndex]) {
                    traitCheck = true;
                    break;
                }
            }
            if (traitCheck == false) {
                return false;
            }
        }

        return true;
    }

    function combineFee(uint _combinedCount) public pure returns (uint) {
        if (_combinedCount <= 1) {
            return 0;
        } else {
            return 200 ether * (2 ** (_combinedCount + 1));
        }
    }

    function combine(uint[] memory _selectedTraits, uint[] memory _selectedBots) external {
        // 1. check if bot already exists and not in selected bot
        require(_selectedTraits.length == NUM_TRAITS, "Malformed traits");
        require(_selectedBots.length < 6, "Cannot combine more than 5 bots");

        // 2. check traits is in selected bots
        require(isSelectedTraitsEligible(_selectedTraits, _selectedBots), "Traits not in bots");

        // 3. burn selected bots
        BittyBot memory bot;
        uint[] memory selectedBotTraits;
        uint[] memory traitsToDeduct = new uint[](NUM_TRAITS);
        uint maxCombinedCount = 0;
        uint combinedCount;
        combinations[combinedId].push(combinedId);
        for (uint i = 0; i < _selectedBots.length; i++) {
            require(_exists(_selectedBots[i]), "Selected bot doesn't exist");
            bot = getBittyBot(_selectedBots[i]);
            (selectedBotTraits, , combinedCount, , ) = traitsFromBot(bot);
            require(bot.botType == 0, "Special bots cannot be combined");

            if (combinedCount > maxCombinedCount) {
                maxCombinedCount = combinedCount;
            }

            for (uint j = 0; j < combinations[_selectedBots[i]].length; j++) {
                combinations[combinedId].push(combinations[_selectedBots[i]][j]);
            }

            for (uint j = 0; j < NUM_TRAITS; j++) {
                traitsToDeduct[j] = UIntArrays.incrementPackedUint(traitsToDeduct[j], selectedBotTraits[j], 1);
            }

            // remove hash so that the traits are freed
            delete hashToTokenId[bittyHash(selectedBotTraits)];

            _burn(_selectedBots[i]);
        }
        uint newCombinedCount = maxCombinedCount + 1;
        require(existTraits(_selectedTraits) == false, "Traits already exist");
        require(newCombinedCount < 4, "Cannot combine more than 3 times");

        // Pay fee in Justice Token
        if (newCombinedCount > 1) {
            uint fee = combineFee(newCombinedCount);
            justiceTokenContract.burnFrom(msg.sender, fee);
        }

        justiceTokenContract.updateLastWithdrawTime(combinedId);

        // 4. mint new bot with selected traits
        _safeMint(msg.sender, combinedId);

        bytes32 hash = bittyHash(_selectedTraits);
        hashToTokenId[hash] = combinedId;
        uint setModifier = setModifierForParts(_selectedTraits);
        uint power = estimatePowerForBot(_selectedTraits, _selectedBots, setModifier);
        uint powerClass = powerClassForPower(power);
        setBittyBot(
            combinedId,
            _selectedTraits,
            setModifier,
            newCombinedCount,
            powerClass,
            power
        );

        // Update Trait Count in one sitting to avoid expensive storage hit
        for (uint i = 0; i < NUM_TRAITS; i++) {
            traitsToDeduct[i] = UIntArrays.decrementPackedUint(traitsToDeduct[i], _selectedTraits[i], 1);
            traitCounts[i] -= traitsToDeduct[i];
        }

        emit BittyBotMinted(combinedId, _selectedTraits, setModifier, newCombinedCount, powerClass, power);
        combinedId++;
    }

    // POWER
    function powerForPart(uint _traitCategory, uint _traitIndex) public pure returns (uint) {
        if (_traitCategory == TRAIT_INDEX_HELMET ||
            _traitCategory == TRAIT_INDEX_FACE ||
            _traitCategory == TRAIT_INDEX_ARMS ||
            _traitCategory == TRAIT_INDEX_BODY) {
            if (_traitIndex == 0) {
                return 300;
            } else if (_traitIndex < 13) {
                return 40;
            } else if (_traitIndex < 15) {
                return 80;
            }
            return 150;
        } else if (_traitCategory == TRAIT_INDEX_ENGINE) {
            return 4 * _traitIndex ** 2 + 6 * _traitIndex + 10;
        } else if (_traitCategory == TRAIT_INDEX_ACCESSORIES) {
            if (_traitIndex == 0) {
                return 0;
            } else if (_traitIndex < 3){
                return 100;
            } else if (_traitIndex < 5){
                return 200;
            } else if (_traitIndex < 7){
                return 400;
            }
        }

        return 0;
    }

    function powerForParts(uint[] memory _traits) public pure returns (uint power) {
        for (uint i = 0; i < _traits.length; i++) {
            power += powerForPart(i, _traits[i]);
        }

        return power;
    }

    function setModifierForParts(uint[] memory _traits) public pure returns (uint count) {
        for (uint i = 0; i < 4; i++) {
            uint currentCount = 0;
            for (uint j = 0; j < 4; j++) {
                if (_traits[i] == _traits[j]) {
                    currentCount++;
                }
            }
            if (currentCount > count) {
                count = currentCount;
            }
        }
        return count;
    }

    function powerClassForPower(uint _power) public pure returns (uint) {
        if (_power < 300) {
            return 1;
        } else if (_power < 500) {
            return 2;
        } else if (_power < 800) {
            return 3;
        } else if (_power < 1000) {
            return 4;
        } else if (_power < 1200) {
            return 5;
        } else if (_power < 1400) {
            return 6;
        } else if (_power < 1600) {
            return 7;
        } else if (_power < 1800) {
            return 8;
        } else if (_power < 2000) {
            return 9;
        } else {
            return 10;
        }
    }

    function estimatePowerForBot(uint[] memory _selectedTraits, uint[] memory _selectedBots, uint _setModifier) public view returns (uint power) {
        if (_selectedTraits[TRAIT_INDEX_TYPE] == 1) {
            return 1400;
        } else if (_selectedTraits[TRAIT_INDEX_TYPE] == 2) {
            return 1600;
        } else if (_selectedTraits[TRAIT_INDEX_TYPE] == 3) {
            return 1800;
        }

        // get power of bots
        BittyBot memory bot;
        for (uint i = 0; i < _selectedBots.length; i++) {
            bot = getBittyBot(_selectedBots[i]);
            power += bot.power / 3;
        }

        // get power for parts
        power += powerForParts(_selectedTraits);

        return (_setModifier > 1) ? power * (4 * _setModifier + 4) / 10 : power;
    }

    // Sales related functions
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function tokensOfOwner(address _owner) external view returns(uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory result = new uint[](tokenCount);
        for (uint index = 0; index < tokenCount; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }

    function numEligibleClaims() public view returns (uint) {
        uint[] memory ownedChubbies = chubbiesContract.tokensOfOwner(msg.sender);
        uint numEligible = 0;
        for (uint i = 0; i < ownedChubbies.length; i++) {
            if (isBotAvailable(ownedChubbies[i])) {
                numEligible++;
            }
        }
        return numEligible;
    }

    function claim(uint _claimId) public {
        require(isFreeClaimActive, "Free claim is not active");
        require(_claimId < MAX_CHUBBIES, "Ineligible Claim");
        require(isBotAvailable(_claimId), "BittyBot has already been claimed");

        if (_claimId < MAX_CHUBBIES) {
            require(chubbiesContract.ownerOf(_claimId) == msg.sender, "No Chubbie to claim BittyBot");
        }

        _mintBot(msg.sender, _claimId);
        numClaimed++;
    }

    function claimN(uint _numClaim) public {
        require(isFreeClaimActive, "Free claim is not active");
        uint[] memory ownedChubbies = chubbiesContract.tokensOfOwner(msg.sender);
        uint claimed = 0;
        for (uint i = 0; i < ownedChubbies.length; i++) {
            if (isBotAvailable(ownedChubbies[i])) {
                _mintBot(msg.sender, ownedChubbies[i]);
                claimed++;
            }
            if (claimed == _numClaim) {
                break;
            }
        }

        numClaimed += claimed;
    }

    function buy(uint _numBuy) public payable {
        uint startIndex = MAX_CHUBBIES + RESERVE_LIMIT + numSold;
        require(isSaleActive, "Sale is not active");
        require(startIndex + _numBuy < TOKEN_LIMIT, "Exceeded 20000 limit");
        require(_numBuy < 11, "You can buy maximum 10 bots");
        require(msg.value >= PRICE * _numBuy, "Ether value sent is below the price");

        for (uint i = 0; i < _numBuy; i++) {
            _mintBot(msg.sender, startIndex + i);
        }
        numSold += _numBuy;
    }

    function buyUnclaimed(uint _numBuy) public payable {
        require(isSaleActive && isFinalSaleActive, "Final sale has already ended");
        require(_numBuy < 11, "You can buy maximum 10 bots");
        require(msg.value >= PRICE * _numBuy, "Ether value sent is below the price");

        uint numBought = 0;
        for (uint i = 0; i < MAX_CHUBBIES; i++) {
            if (isBotAvailable(i)) {
                _mintBot(msg.sender, i);
                numBought++;
            }
            if (numBought == _numBuy) {
                return;
            }
        }
    }

    function setContracts(address _chubbiesContract, address _justiceTokenContract) public onlyOwner {
        chubbiesContract = IChubbies(_chubbiesContract);
        justiceTokenContract = IJusticeToken(_justiceTokenContract);
    }

    function setWidthdrawAddresses(address payable _solazy, address payable _kixboy) public onlyOwner {
        solazy = _solazy;
        kixboy = _kixboy;
    }
    
    function startSale() public onlyOwner {
        isSaleActive = true;
    }

    function stopSale() public onlyOwner {
        isSaleActive = false;
    }

    function startClaim() public onlyOwner {
        isFreeClaimActive = true;
    }

    function stopClaim() public onlyOwner {
        isFreeClaimActive = false;
    }

    function startFinalSale() public onlyOwner {
        isFinalSaleActive = true;
        isFreeClaimActive = false;
    }

    function stopFinalSale() public onlyOwner {
        isFinalSaleActive = false;
    }
    
    function withdraw() public payable {
        require(msg.sender == kixboy || msg.sender == solazy || msg.sender == owner(), "Invalid sender");
        uint halfBalance = address(this).balance / 20 * 9;
        kixboy.transfer(halfBalance);
        solazy.transfer(halfBalance);
        payable(owner()).transfer(address(this).balance);
    }

    function reserveMint(address _sendTo, uint _tokenId) public onlyOwner {
        require(_tokenId > MAX_CHUBBIES && _tokenId < MAX_CHUBBIES + RESERVE_LIMIT, "Not a eligible reserve token");
        _mintBot(_sendTo, _tokenId);
    }

    function reserveBulkMint(address _sendTo, uint _numReserve) public onlyOwner {
        uint numReserved = 0;
        for (uint i = MAX_CHUBBIES; i < MAX_CHUBBIES + RESERVE_LIMIT; i++) {
            if (isBotAvailable(i)) {
                _mintBot(_sendTo, i);
                numReserved++;
            }
            if (numReserved == _numReserve) {
                return;
            }
        }
    }
}