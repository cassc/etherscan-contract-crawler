// SPDX-License-Identifier: MIT

//  ___             __  __  __   
//   |  /\ |\/| /\ / _ /  \/ _ | 
//   | /--\|  |/--\\__)\__/\__)| 
// 
//  Tamagogi is a fully onchain tamagotchi dapp.
//  https://tamagogi.xyz 

pragma solidity ^0.8.7;

import "https://github.com/RollaProject/solidity-datetime/blob/master/contracts/DateTimeContract.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "base64-sol/base64.sol";
import "./tamagogi_drawer.sol";


contract Tamagogi is Ownable, ERC721A, ReentrancyGuard, TamagogiDrawer {
    struct TMGG {
        string name;
        uint lastFeed;
        uint lastPlay;
        uint lastHit;
        uint birthhash;
    }

    struct PetMdata {
        uint tokenId;
        uint seed;
        uint hunger;
        uint bored;
        uint unhappiness;
        bool isMaster;
    }

    struct Config {
        uint price;
        uint propMaxSupply;
        uint petMaxSupply;
        uint[3] hungerRate;
        uint[3] boredRate;
        uint[3] hitRate;
        uint[3] hitRasing;
        uint[5] reactionRate;
        bool revealProp;
        bool revealPet;
        MintStage mintStage;
    }

    //@@@ enum
    enum MintStage {
        PAUSED,
        PROPS,
        PETS_MERKLE,
        PETS
    }

    //@@@ event
    event EPlay(
       uint tokenId,
       address sender
    );
    event EHit(
       uint tokenId,
       address sender
    );
    event EFeed(
       uint tokenId,
       address sender
    );

    constructor() ERC721A("Tamagogi", "TMGG") {
        config.price = 0;
        config.propMaxSupply = 2000;
        config.petMaxSupply = 1825;
        config.mintStage = MintStage.PAUSED;
        config.hungerRate = [8,40,120];
        config.boredRate = [6,30,90];
        config.hitRate = [4,20,60];
        config.hitRasing = [9,3,1];
        config.reactionRate = [0,10,20,30,40];
        config.revealProp = false;
        config.revealPet = false;
    }
    
    DateTimeContract private dateTimeContract = new DateTimeContract();
    bytes32 public rootHash = 0x0;

    Config public config;

    mapping(uint => uint) private seeds;
    mapping(uint => TMGG) public TMGGs;
    mapping(uint => bool) public rerollTable;
    mapping(string => bool) public nameTable;
    mapping(address => bool) public propMinted;
    mapping(address => bool) public petMinted;

    uint private bornTimestamp = 1640995201;
    uint private bornIdx = 0;

    //@@@ modifier
    modifier validToken(uint tokenId) {
        require(tokenId >= _startTokenId() && tokenId <= _totalMinted(), "Not valid id");
        _;
    }

    modifier validOwner(uint tokenId) {
        require(ownerOf(tokenId) == msg.sender, "You are not token's owner");
        _;
    }

    modifier revealPetOnly() {
        require(config.revealPet, "Not reveal");
        _;
    }

    modifier petOnly(uint tokenId) {
        require(tokenId > config.propMaxSupply && tokenId <= config.petMaxSupply, "Not valid pet id");
        _;
    }

    //@@@ mint
    function getProp() external payable {
        require(config.mintStage == MintStage.PROPS, "Not in stage to buy prop");
        require(_totalMinted() < config.propMaxSupply, "No props left");
        require(!propMinted[msg.sender], "Max to 1");

        uint propId = _startTokenId() + _totalMinted();
        uint seed = _getRandom(propId);
        seeds[propId] = seed;

        _safeMint(msg.sender, 1);
        propMinted[msg.sender] = true;
    }

    function hatchEgg() external payable {
        require(config.mintStage == MintStage.PETS, "Not in stage to mint TMGG");
        require(_totalMinted() < config.petMaxSupply, "No pet left");
        require(!petMinted[msg.sender], "Max to 1");
        require(1 * config.price <= msg.value,"No enough eth.");
        _hatchEgg();
    }

    function allowlistHatchEgg(bytes32[] calldata _proof) external payable {
        require(config.mintStage == MintStage.PETS_MERKLE, "Not in stage to mint merkle TMGG");
        require(_totalMinted() < config.petMaxSupply, "No pet left");
        require(!petMinted[msg.sender], "Max to 1");
        require(1 * config.price <= msg.value,"No enough eth.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, rootHash, leaf), "invalid proof");
        _hatchEgg();
    }

    function _hatchEgg() private {
        uint mintId = _startTokenId() + _totalMinted();
        if (bornIdx == 5) {
            bornIdx = 0;
            bornTimestamp = dateTimeContract.addDays(bornTimestamp, 1);
        }

        TMGG memory preBornTMGG = TMGG('', block.timestamp, block.timestamp, 0, bornTimestamp);
        TMGGs[mintId] = preBornTMGG;
        bornIdx++;
        
        uint seed = _getRandom(mintId);
        seeds[mintId] = seed;

        _safeMint(msg.sender, 1);
        petMinted[msg.sender] = true;
    }
    
    //@@@ pet function

    function setName(uint tokenId, string calldata name) external validOwner(tokenId) revealPetOnly() petOnly(tokenId) {
        require(nameTable[name] == false, "Name exist");

        uint nameLength = utfStringLength(name);

        require(nameLength > 1 && nameLength < 18, "Not valid name");
        TMGGs[tokenId].name = name;
        nameTable[name] = true;
    }

    // everyone can call these function to feed, hit or play with any pet
    function play(uint tokenId) external revealPetOnly() petOnly(tokenId) {
        TMGGs[tokenId].lastPlay = block.timestamp;
        emit EPlay(tokenId, msg.sender);
    }

    function feed(uint tokenId) external revealPetOnly() petOnly(tokenId) {
        TMGGs[tokenId].lastFeed = block.timestamp;
        emit EFeed(tokenId, msg.sender);
    }

    function hit(uint tokenId) external revealPetOnly() petOnly(tokenId) {
        TMGGs[tokenId].lastHit = block.timestamp;
        emit EHit(tokenId, msg.sender);
    }

    function reroll(uint tokenId) external validOwner(tokenId) revealPetOnly() petOnly(tokenId) {
        require(!rerollTable[tokenId], "Not available");
        seeds[tokenId] = _getRandom(tokenId);
        rerollTable[tokenId] = true;
    }
    
    function isBirthdate(uint tokenId) public view petOnly(tokenId) returns (bool) {
        TMGG memory tmgg = TMGGs[tokenId];
        uint _now = block.timestamp;
        
        uint seed = seeds[tokenId];
        uint offset = seed % 31536000;

        return dateTimeContract.getDay(_now) == dateTimeContract.getDay(tmgg.birthhash + offset) && dateTimeContract.getMonth(_now) == dateTimeContract.getMonth(tmgg.birthhash + offset);
    }

    function getBirthdate(uint tokenId) public view petOnly(tokenId) returns (uint month, uint day) {
        TMGG memory tmgg = TMGGs[tokenId];

        uint seed = seeds[tokenId];
        uint offset = seed % 31536000;

        uint _month = dateTimeContract.getMonth(tmgg.birthhash + offset);
        uint _day = dateTimeContract.getDay(tmgg.birthhash + offset);

        return (_month, _day);
    }

    function getPetUnhappinessAndProp(uint tokenId) public view revealPetOnly() petOnly(tokenId) returns(uint, bool, bool ,bool) {
        uint _now = block.timestamp;
        TMGG memory tmgg = TMGGs[tokenId];
        uint hunger = dateTimeContract.diffHours(tmgg.lastFeed, _now);
        uint bored = dateTimeContract.diffHours(tmgg.lastPlay, _now);
        uint _baseHit = tmgg.lastHit == 0 ? 0 : (_now - tmgg.lastHit) / 60;

        uint hitVal = 0;
        if (_baseHit <= config.hitRate[0]) {
            hitVal = _baseHit * config.hitRasing[0];
        } else if (_baseHit < config.hitRate[1]) {
            hitVal = _baseHit * config.hitRasing[1];
        } else if (_baseHit < config.hitRate[2]) {
            hitVal = _baseHit * config.hitRasing[2];
        } else {
            hitVal = _baseHit * 0;
        }

        uint[] memory ownerTokens = tokensOfOwner(ownerOf(tokenId));
        bool ownFood = false;
        bool ownToy = false;
        bool ownShield = false;

        for(uint i = 0; i < ownerTokens.length; i++) {
            uint id = ownerTokens[i];

            if (id <= config.propMaxSupply) {
                uint seed = seeds[id];
                uint propNumber = propOdds[seed % propOdds.length];

                if (propNumber == 0) { // own food
                    hunger = 0;
                    ownFood = true;
                } else if (propNumber == 1) { // own toy
                    bored = 0;
                    ownToy = true;
                } else if (propNumber == 2) { // own shiled
                    hitVal = 0;
                    ownShield = true;
                }
            }
        }

        uint _unhappiness = hunger + bored + hitVal;

        return (_unhappiness, ownFood, ownToy, ownShield);
    }

    function getPetHungerAndBored(uint tokenId) public view revealPetOnly() petOnly(tokenId) returns(uint, uint) {
        uint _now = block.timestamp;
        TMGG memory tmgg = TMGGs[tokenId];
        uint hunger = dateTimeContract.diffHours(tmgg.lastFeed, _now);
        uint bored = dateTimeContract.diffHours(tmgg.lastPlay, _now);

        uint[] memory ownerTokens = tokensOfOwner(ownerOf(tokenId));
        for(uint i = 0; i < ownerTokens.length; i++) {
            uint id = ownerTokens[i];

            if (id <= config.propMaxSupply) {
                uint seed = seeds[id];
                uint propNumber = propOdds[seed % propOdds.length];

                if (propNumber == 0) { // own food
                    hunger = 0;
                } else if (propNumber == 1) { // own toy
                    bored = 0;
                }
            }
        }

        return (hunger, bored);
    }

    function _getReactionTraitIndex(uint _unhappiness) private view returns (uint) {
        if (_unhappiness <= config.reactionRate[0]) {
            return reaction[3];
        } else if (_unhappiness < config.reactionRate[1]) {
            return reaction[0];
        } else if (_unhappiness < config.reactionRate[2]) {
            return reaction[1];
        } else if (_unhappiness < config.reactionRate[3]) {
            return reaction[2];
        } else {
            return reaction[4];
        }
    }

    function _getPetTraits(PetMdata memory petMeta) private pure returns (string memory) {
        string memory attr = string(abi.encodePacked(
            '{ "trait_type": "hunger", "display_type": "number", "value": ',Strings.toString(petMeta.hunger),'},',
            '{ "trait_type": "bored", "display_type": "number", "value": ',Strings.toString(petMeta.bored),'},'
        ));

        return attr;
    }

    function _getPetStyleTraits(PetMdata memory petMeta) private view returns (string memory) {
        string memory masterLabel = petMeta.isMaster ? "yes" : "no";
        string memory attr = string(abi.encodePacked(
            '{ "trait_type": "type", "value": "pets"},',
            '{ "trait_type": "master", "value": "',masterLabel,'"},',
            '{ "trait_type": "unhappiness", "display_type": "number", "value": ',Strings.toString(petMeta.unhappiness),'},',
            _getPetReactionTraits(petMeta),
            _getPetEarTraits(petMeta),
            _getPetHeadTraits(petMeta),
            _getPetBodyTraits(petMeta)
        ));

        return attr;
    }
    
    function _getPetReactionTraits(PetMdata memory petMeta) private view returns (string memory) {
        string memory attr = string(abi.encodePacked(
            '{ "trait_type": "reaction", "value": "',reactionTraits[_getReactionTraitIndex(petMeta.unhappiness)],'"},'
        ));

        return attr;
    }

    function _getPetEarTraits(PetMdata memory petMeta) private view returns (string memory) {
        string memory attr = string(abi.encodePacked(
            '{ "trait_type": "ear", "value": "',earTraits[ear[(petMeta.seed / 2) % ear.length]],'"},'
        ));

        return attr;
    }

    function _getPetHeadTraits(PetMdata memory petMeta) private view returns (string memory) {
        string memory attr = string(abi.encodePacked(
            '{ "trait_type": "head", "value": "',headTraits[head[(petMeta.seed / 3) % head.length]],'"},'
        ));

        return attr;
    }

    function _getPetBodyTraits(PetMdata memory petMeta) private view returns (string memory) {
        string memory attr = string(abi.encodePacked(
            '{ "trait_type": "body", "value": "',bodyTraits[body[(petMeta.seed / 4) % body.length]],'"},'
        ));

        return attr;
    }

    function _getPetsName(PetMdata memory petMeta) private view returns (string memory) {
        (uint month, uint day) = getBirthdate(petMeta.tokenId);
        TMGG memory tmgg = TMGGs[petMeta.tokenId];
        string memory name = utfStringLength(tmgg.name) > 1 ? string(abi.encodePacked(tmgg.name, " / ")) : "";

        return string(abi.encodePacked(
            '{"name": "',name,'#',Strings.toString(petMeta.tokenId),' Tamagogi (',Strings.toString(month),'/',Strings.toString(day),')','",'
        ));
    }

    function _getPetsBirthTrait(PetMdata memory petMeta) private view returns (string memory) {
        (uint month, uint day) = getBirthdate(petMeta.tokenId);

        return string(abi.encodePacked(
            '{ "trait_type": "birthdate", "value": "',Strings.toString(month),'/',Strings.toString(day),'"}'
        ));
    }

    function _getPetsMetadata(uint tokenId) private view returns (string memory) {
        (uint unhappiness, bool ownFood, bool ownToy, bool ownShield) = getPetUnhappinessAndProp(tokenId);
        (uint hunger, uint bored) = getPetHungerAndBored(tokenId);
        bool hbd = isBirthdate(tokenId);
        bool isMaster = ownFood && ownToy && ownShield || hbd ? true : false;
        uint reactionId = _getReactionTraitIndex(unhappiness);
        PetMdata memory petMeta = PetMdata(tokenId, seeds[tokenId], hunger, bored, unhappiness, isMaster);
        string memory _svgString = drawReveal(seeds[tokenId], reactionId, isMaster);

        string memory json = 
                string(
                    abi.encodePacked(
                        _getPetsName(petMeta),
                        '"description": "Tamagogi is a Tamagotchi Dapp and fully generated on-chain. The contract interaction and time will affect the status and reaction of the pet. If you collect other items, the pet will show love!",', 
                        '"attributes": [',
                            _getPetTraits(petMeta),
                            _getPetStyleTraits(petMeta),
                            _getPetsBirthTrait(petMeta),
                        '],'
                        '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(drawSVG(_svgString))), '"}' 
                        )
                    );

        return Base64.encode(
            bytes(
                string(json)
                )
            );
    }

    function _getPetsUnrevealMetadata(uint tokenId) private view returns (string memory) {
        (uint month, uint day) = getBirthdate(tokenId);
        uint _seed = seeds[tokenId];

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "#',Strings.toString(tokenId),' Tamagogi Egg (',Strings.toString(month),'/',Strings.toString(day),')','", "description": "Unbroken Tamagogi eggs...",',
                        '"attributes": [',
                            '{ "trait_type": "type", "value": "pets"},',
                            '{ "trait_type": "birthdate", "value": "',Strings.toString(month),'/',Strings.toString(day),'"}',
                        '],',
                        '"image": "ipfs://QmW1tccYqBmSLQFTfN8rWw8JHXxx7hZS4MiiwWWDN5tvG8/',Strings.toString(eggs[_seed % eggs.length]),'.gif"}' 
                        )
                    )
                )
            );

        return json;
    }

    function _getPropsMetadata(uint tokenId) private view returns (string memory) {
        uint _seed = seeds[tokenId];
        uint _propIndex = propOdds[_seed % propOdds.length];
        string memory _desc = propDesc[_propIndex];
        string memory _traitName = propTraits[_propIndex];

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "#',Strings.toString(tokenId),' Tamagogi (',_traitName,')", "description": "',_desc,'",',
                        '"attributes": [',
                            '{ "trait_type": "type", "value": "props"},',
                            '{ "trait_type": "usage", "value": "',_traitName,'"}'
                        '],',
                        '"image": "ipfs://QmVxCDfmwgY2psAh7wti8aLCykkj99snygGQ89p2zkfAtf/',_traitName,'.gif"}' 
                    )
                )
            )
        );

        return json;
    }

    function _getPropsUnrevealMetadata(uint tokenId) private pure returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "#',Strings.toString(tokenId),' Tamagogi (Unreveal Props)", "description": "Unreveal Props",',
                        '"attributes": [',
                            '{ "trait_type": "type", "value": "props"}',
                        '],',
                        '"image": "ipfs://QmTbB6DD2w8t36zLPvBEdoWo62RFMyJi9EXcj99ZixPrxC"}' 
                    )
                )
            )
        );

        return json;
    }

    //@@@ override
    function _tokenURI(uint256 tokenId) private view validToken(tokenId) returns (string memory) {
        string memory json = tokenId <= config.propMaxSupply ? config.revealProp ? _getPropsMetadata(tokenId) : _getPropsUnrevealMetadata(tokenId) : config.revealPet ? _getPetsMetadata(tokenId) : _getPetsUnrevealMetadata(tokenId);

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function tokenURI(uint256 tokenId) override (ERC721A) public view returns (string memory) {
        return _tokenURI(tokenId);
    }

    function _startTokenId() override internal pure virtual returns (uint256) {
        return 1;
    }

    //@@@ admin

    function setMintStage(uint _stage) external onlyOwner {
        config.mintStage = MintStage(_stage);
    }
    function setHungerRate(uint[3] calldata _rate) external onlyOwner {
        config.hungerRate = _rate;
    }
    function setBoredRate(uint[3] calldata _rate) external onlyOwner {
        config.boredRate = _rate;
    }
    function setHitRate(uint[3] calldata _rate) external onlyOwner {
        config.hitRate = _rate;
    }
    function setReactionRate(uint[5] calldata _rate) external onlyOwner {
        config.reactionRate = _rate;
    }
    function setHitRasing(uint[3] calldata _rate) external onlyOwner {
        config.hitRasing = _rate;
    }
    function setRevealPet() external onlyOwner {
        config.revealPet = true;
    }
    function setRevealProp() external onlyOwner {
        config.revealProp = true;
    }
    function setPrice(uint _price) external onlyOwner {
        config.price = _price;
    }
    function setMerkle(bytes32 _hash) external onlyOwner {
        rootHash = _hash;
    }

    //@@@ others

    // ERC721AQueryable.sol
    function tokensOfOwner(address owner) public view virtual returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    // https://ethereum.stackexchange.com/questions/13862/is-it-possible-to-check-string-variables-length-inside-the-contract
    function utfStringLength(string memory str) pure internal returns (uint length) {
        uint i=0;
        bytes memory string_rep = bytes(str);

        while (i<string_rep.length)
        {
            if (string_rep[i]>>7==0)
                i+=1;
            else if (string_rep[i]>>5==bytes1(uint8(0x6)))
                i+=2;
            else if (string_rep[i]>>4==bytes1(uint8(0xE)))
                i+=3;
            else if (string_rep[i]>>3==bytes1(uint8(0x1E)))
                i+=4;
            else
                //For safety
                i+=1;

            length++;
        }
    }
    
    function _getRandom(uint tokenId) private view returns (uint) {
        uint randomlize = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, msg.sender)));
        return randomlize;
    }
}