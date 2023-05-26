// SPDX-License-Identifier: Anonymice License, Version 1.0

/*
Copyright 2021 Anonymice

Licensed under the Anonymice License, Version 1.0 (the “License”); you may not use this code except in compliance with the License.
You may obtain a copy of the License at https://doz7mjeufimufl7fa576j6kq5aijrwezk7tvdgvzrfr3d6njqwea.arweave.net/G7P2JJQqGUKv5Qd_5PlQ6BCY2JlX51GauYljsfmphYg

Unless required by applicable law or agreed to in writing, code distributed under the License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ICheeth.sol";
import "./IAnonymice.sol";
import "./AnonymiceLibrary.sol";
import "./IAnonymiceBreedingDescriptor.sol";

contract AnonymiceBreeding is ERC721Enumerable, Ownable {
    /*
           _   _  ____  _   ___     ____  __ _____ _____ ______   ____  _____  ______ ______ _____ _____ _   _  _____ 
     /\   | \ | |/ __ \| \ | \ \   / /  \/  |_   _/ ____|  ____| |  _ \|  __ \|  ____|  ____|  __ \_   _| \ | |/ ____|
    /  \  |  \| | |  | |  \| |\ \_/ /| \  / | | || |    | |__    | |_) | |__) | |__  | |__  | |  | || | |  \| | |  __ 
   / /\ \ | . ` | |  | | . ` | \   / | |\/| | | || |    |  __|   |  _ <|  _  /|  __| |  __| | |  | || | | . ` | | |_ |
  / ____ \| |\  | |__| | |\  |  | |  | |  | |_| || |____| |____  | |_) | | \ \| |____| |____| |__| || |_| |\  | |__| |
 /_/    \_\_| \_|\____/|_| \_|  |_|  |_|  |_|_____\_____|______| |____/|_|  \_\______|______|_____/_____|_| \_|\_____|
                                                                                                                                                                                                                             
*/

    using AnonymiceLibrary for uint8;
    using Counters for Counters.Counter;

    //addresses
    address CHEETH_ADDRESS;
    address ANONYMICE_ADDRESS;
    address ANONYMICE_BREEDING_DESCRIPTOR_ADDRESS;
    address PUZZLE_ADDRESS;

    struct BreedingEvent {
        uint256 breedingEventId;
        uint256 parentId1;
        uint256 parentId2;
        uint256 childId;
        uint256 releaseBlock;
    }

    struct Incubator {
        uint256 parentId1;
        uint256 parentId2;
        uint256 childId;
        uint256 revealBlock;
    }

    mapping(uint256 => bool) public _breedingEventIdToActive;
    mapping(uint256 => uint256) public _breedingEventIdToIndex;

    mapping(address => BreedingEvent[]) public _addressToBreedingEvents;
    mapping(uint256 => bool) public _tokenToRevealed;
    mapping(uint256 => Incubator) public _tokenToIncubator;

    mapping(uint256 => string) internal tokenIdToHash;
    mapping(uint256 => bool) public _tokenIdToLegendary;
    mapping(uint256 => uint8) public _tokenIdToLegendaryNumber;
    mapping(uint256 => address) public _parentTokenIdToOwner;

    uint256 SEED_NONCE = 0;
    uint256 MAX_BABY_SUPPLY = 3550;
    uint256 BASE_CHEETH_COST = 50000000000000000000;
    uint256 CHEETH_COST_PER_BLOCK = 500000000000000;

    uint256 BLOCKS_TILL_REVEAL = 50000;
    uint256 BLOCKS_TILL_RELEASE = 50000;

    bool public BREEDING_LIVE = false;

    uint8 public legendariesMinted = 0;

    Counters.Counter private _currentBreedingEventId;

    //uint arrays
    uint16[][10] TIERS;

    uint16[9] LEGENDARY_TIERS = [100, 100, 100, 200, 200, 200, 300, 300, 300];

    constructor() ERC721("AnonymiceBreeding", "BABYMICE") {
        //Declare all the rarity tiers

        //Hat
        TIERS[0] = [50, 150, 200, 300, 850, 850, 850, 900, 150, 5700];
        //whiskers
        TIERS[1] = [200, 800, 1000, 3000, 5000];
        //Neck
        TIERS[2] = [300, 800, 900, 1000, 7000];
        //Earrings
        TIERS[3] = [50, 200, 300, 300, 9150];
        //Eyes
        TIERS[4] = [50, 100, 400, 450, 500, 700, 1800, 2000, 2000, 2000];
        //Mouth
        TIERS[5] = [1428, 1428, 1428, 1429, 1429, 1429, 1429];
        //Nose
        TIERS[6] = [2000, 2000, 2000, 2000, 2000];
        //Character
        TIERS[7] = [20, 70, 721, 1000, 1155, 1200, 1300, 1434, 1541, 1559];

        //Character traits adjusted for OG owners
        TIERS[8] = [30, 80, 721, 1000, 1155, 1200, 1300, 1434, 1541, 1539];
        TIERS[9] = [40, 90, 721, 1000, 1155, 1200, 1300, 1434, 1541, 1519];
    }

    function flipBreedingSwitch() public {
        //Only puzzle wallet may start breeding
        require(msg.sender == PUZZLE_ADDRESS, "This is not the puzzle address.");

        BREEDING_LIVE = true;
    }

    function initiateBreeding(uint256 _parentId1, uint256 _parentId2) public {
        require(BREEDING_LIVE == true, "Breeding is not live.");
        require(totalSupply() < MAX_BABY_SUPPLY, "Max supply reached!");

        //Require they are the owners of both parents.
        require(
            IAnonymice(ANONYMICE_ADDRESS).ownerOf(_parentId1) == msg.sender &&
                IAnonymice(ANONYMICE_ADDRESS).ownerOf(_parentId2) == msg.sender
        , "You do not own both Anonymice.");

        //Burn cheeth
        ICheeth(CHEETH_ADDRESS).burnFrom(msg.sender, BASE_CHEETH_COST);

        //Transfer parent 1
        IAnonymice(ANONYMICE_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            _parentId1
        );

        //Tranfer parent 2
        IAnonymice(ANONYMICE_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            _parentId2
        );

        //Set this babies tokenId to the total supply
        uint256 _tokenId = totalSupply();

        _currentBreedingEventId.increment();

        uint256 _thisBreedingEventId = _currentBreedingEventId.current();

        //Add this breeding event to their mapping.
        _addressToBreedingEvents[msg.sender].push(
            BreedingEvent(
                _thisBreedingEventId,
                _parentId1,
                _parentId2,
                _tokenId,
                block.number + BLOCKS_TILL_RELEASE
            )
        );

        _breedingEventIdToActive[_thisBreedingEventId] = true;
        _breedingEventIdToIndex[_thisBreedingEventId] = _addressToBreedingEvents[msg.sender].length - 1;

        //Set this token to this breeding event.
        _tokenToIncubator[_tokenId] = Incubator(
            _parentId1,
            _parentId2,
            _tokenId,
            block.number + BLOCKS_TILL_REVEAL
        );

        //Map this tokenId as unrevealed
        _tokenToRevealed[_tokenId] = false;

        //Set the owner of these tokens
        _parentTokenIdToOwner[_parentId1] = msg.sender;
        _parentTokenIdToOwner[_parentId2] = msg.sender;

        //Mint them their unrevealed baby
        _mint(msg.sender, _tokenId);
    }

    function speedUpParentRelease(
        uint256 _breedingEventId,
        uint256 _cheethAmount
    ) public {
        require(_breedingEventIdToActive[_breedingEventId], "Breeding event not active.");
        uint256 thisBreedingEventIndex = _breedingEventIdToIndex[_breedingEventId];

        //Pull this breeding event
        BreedingEvent memory thisBreedingEvent = _addressToBreedingEvents[
            msg.sender
        ][thisBreedingEventIndex];

        
        require(thisBreedingEvent.breedingEventId == _breedingEventId, "Breeding event in mapping not equal to breeding event sent.");

        //Must be before the release time.
        require(block.number < thisBreedingEvent.releaseBlock, "Block number is greater than reveal block.");

        uint256 blocksToRemove = _cheethAmount / CHEETH_COST_PER_BLOCK;
        uint256 newReleaseBlock;

        if (blocksToRemove > thisBreedingEvent.releaseBlock) {
            newReleaseBlock = block.number;
        } else {
            newReleaseBlock = thisBreedingEvent.releaseBlock - blocksToRemove;
        }

        //Set the new release time.
        _addressToBreedingEvents[msg.sender][thisBreedingEventIndex]
            .releaseBlock = newReleaseBlock;

        //Burn cheeth
        ICheeth(CHEETH_ADDRESS).burnFrom(msg.sender, _cheethAmount);
    }

    function speedUpChildReveal(uint256 _tokenId, uint256 _cheethAmount)
        public
    {
        //Require it to be unrevealed
        require(_tokenToRevealed[_tokenId] == false, "This is already revealed");

        //Require that they own it
        require(ownerOf(_tokenId) == msg.sender, "You do not own this baby.");

        //Must be before the reveal time.
        require(block.number < _tokenToIncubator[_tokenId].revealBlock, "Block number is greater than reveal block.");

        uint256 blocksToRemove = _cheethAmount / CHEETH_COST_PER_BLOCK;
        uint256 newRevealBlock;

        if (blocksToRemove > _tokenToIncubator[_tokenId].revealBlock) {
            newRevealBlock = block.number;
        } else {
            newRevealBlock =
                _tokenToIncubator[_tokenId].revealBlock -
                blocksToRemove;
        }

        //Set the new reveal time.
        _tokenToIncubator[_tokenId].revealBlock = newRevealBlock;

        //Burn cheeth
        ICheeth(CHEETH_ADDRESS).burnFrom(msg.sender, _cheethAmount);
    }

    function _removeBreedingEvent(uint256 _breedingEventIndex) internal {
        uint256 _maxIndex = _addressToBreedingEvents[msg.sender].length - 1;


        uint256 idForItemToMove = _addressToBreedingEvents[msg.sender][_maxIndex].breedingEventId;
        uint256 idForItemToRemove = _addressToBreedingEvents[msg.sender][_breedingEventIndex].breedingEventId;

        
        if(_breedingEventIndex == _maxIndex){
            //Remove the final element
            _addressToBreedingEvents[msg.sender].pop();
            
            //Set the new index for the item that got removed;
            _breedingEventIdToIndex[idForItemToRemove] = 0;

            //Set this breeding event to finished.
            _breedingEventIdToActive[idForItemToRemove] = false;
            return;
        }
        
        //Replace this breeding event with the final one.
        _addressToBreedingEvents[msg.sender][_breedingEventIndex] = _addressToBreedingEvents[msg.sender][_maxIndex];

        //Set the new index for the final item that got moved
        _breedingEventIdToIndex[idForItemToMove] = _breedingEventIndex;
        
        //Remove the final element
        _addressToBreedingEvents[msg.sender].pop();

        //Set the new index for the item that got removed;
        _breedingEventIdToIndex[idForItemToRemove] = 0;

        //Set this breeding event to finished.
        _breedingEventIdToActive[idForItemToRemove] = false;

    }

    function pullParentsByBreedingEventId(uint256 _breedingEventId) public {
        require(_breedingEventIdToActive[_breedingEventId], "Breeding event no longer active.");

        uint256 thisBreedingEventIndex = _breedingEventIdToIndex[_breedingEventId];

        require(_addressToBreedingEvents[msg.sender][thisBreedingEventIndex].breedingEventId == _breedingEventId, "Breeding event ID does not match Breeding event ID found in mapping.");

        pullParentsByBreedingEventIndex(thisBreedingEventIndex);
    }

    function pullParentsByBreedingEventIndex(uint256 _breedingEventIndex)
        public
    {
        //Pull this breeding event
        BreedingEvent memory thisBreedingEvent = _addressToBreedingEvents[
            msg.sender
        ][_breedingEventIndex];

        //Must be beyond the time to pull parents.
        require(block.number >= thisBreedingEvent.releaseBlock, "Block number is less than release block.");

        //Transfer parent 1
        IAnonymice(ANONYMICE_ADDRESS).transferFrom(
            address(this),
            msg.sender,
            thisBreedingEvent.parentId1
        );

        //Tranfer parent 2
        IAnonymice(ANONYMICE_ADDRESS).transferFrom(
            address(this),
            msg.sender,
            thisBreedingEvent.parentId2
        );

        //Set the owner to the zero address
        _parentTokenIdToOwner[thisBreedingEvent.parentId1] = address(0x0);
        _parentTokenIdToOwner[thisBreedingEvent.parentId2] = address(0x0);

        _removeBreedingEvent(_breedingEventIndex);
    }

    /**
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - 10000 to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        internal
        view
        returns (string memory)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i.toString();
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert("Rarity gen failed");
    }

    function generateRandomNumber(uint256 _tokenId, uint256 limit)
        internal
        returns (uint256)
    {
        SEED_NONCE++;

        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        _tokenId,
                        msg.sender,
                        SEED_NONCE
                    )
                )
            ) % limit;
    }

    function generateChildHash(
        uint256 _tokenId,
        string memory _parentHash1,
        string memory _parentHash2,
        uint8 _OGParentCount
    ) internal returns (string memory) {
        //Genetic traits - 1,4,5,6,7
        //Accessory traits - 0,2,3
        bytes memory childHashBytes;
        _OGParentCount;

        for (uint8 i = 0; i < 9; i++) {
            uint256 geneticDecider = generateRandomNumber(_tokenId, 100);
            string memory appendString;

            if (i == 0) {
                //Burned
                appendString = "0";
                childHashBytes = abi.encodePacked(childHashBytes, appendString);
                continue;
            }

            if (i == 1 || i == 5) {
                //Hat
                //Eyes
                if (geneticDecider >= 0 && geneticDecider < 5)
                    appendString = AnonymiceLibrary.substring(
                        _parentHash1,
                        i,
                        i + 1
                    );
                if (geneticDecider >= 5 && geneticDecider < 10)
                    appendString = AnonymiceLibrary.substring(
                        _parentHash2,
                        i,
                        i + 1
                    );
                if (geneticDecider >= 10 && geneticDecider <= 99)
                    appendString = rarityGen(
                        generateRandomNumber(_tokenId, 10000),
                        i - 1
                    );
                childHashBytes = abi.encodePacked(childHashBytes, appendString);
                continue;
            }

            if (i == 2 || i == 6 || i == 7) {
                //Whiskers
                //Mouth
                //Nose
                if (geneticDecider >= 0 && geneticDecider < 40)
                    appendString = AnonymiceLibrary.substring(
                        _parentHash1,
                        i,
                        i + 1
                    );
                if (geneticDecider >= 40 && geneticDecider < 80)
                    appendString = AnonymiceLibrary.substring(
                        _parentHash2,
                        i,
                        i + 1
                    );
                if (geneticDecider >= 80 && geneticDecider <= 100)
                    appendString = rarityGen(
                        generateRandomNumber(_tokenId, 10000),
                        i - 1
                    );
                childHashBytes = abi.encodePacked(childHashBytes, appendString);
                continue;
            }

            if (i == 3 || i == 4) {
                //Neck
                //Earrings
                if (geneticDecider >= 0 && geneticDecider < 15)
                    appendString = AnonymiceLibrary.substring(
                        _parentHash1,
                        i,
                        i + 1
                    );

                if (geneticDecider >= 15 && geneticDecider < 30)
                    appendString = AnonymiceLibrary.substring(
                        _parentHash2,
                        i,
                        i + 1
                    );

                if (geneticDecider >= 30 && geneticDecider <= 100)
                    appendString = rarityGen(
                        generateRandomNumber(_tokenId, 10000),
                        i - 1
                    );
                childHashBytes = abi.encodePacked(childHashBytes, appendString);
                continue;
            }

            if (i == 8) {
                //Character
                string memory parent1Character = AnonymiceLibrary.substring(
                    _parentHash1,
                    i,
                    i + 1
                );

                string memory parent2Character = AnonymiceLibrary.substring(
                    _parentHash2,
                    i,
                    i + 1
                );

                uint8 parent1Chance;
                uint8 parent2Chance;

                //If parent 1 character is glitched or irradiated, give child a 5% chance
                keccak256(abi.encodePacked(parent1Character)) ==
                    keccak256("0") ||
                    keccak256(abi.encodePacked(parent1Character)) ==
                    keccak256("1")
                    ? parent1Chance = 5
                    : parent1Chance = 40;

                //If parent 2 character is glitched or irradiated, give child a 5% chance
                keccak256(abi.encodePacked(parent2Character)) ==
                    keccak256("0") ||
                    keccak256(abi.encodePacked(parent2Character)) ==
                    keccak256("1")
                    ? parent2Chance = 5
                    : parent2Chance = 40;

                if (geneticDecider >= 0 && geneticDecider < parent1Chance)
                    appendString = AnonymiceLibrary.substring(
                        _parentHash1,
                        i,
                        i + 1
                    );

                if (
                    geneticDecider >= parent1Chance &&
                    geneticDecider < parent1Chance + parent2Chance
                )
                    appendString = AnonymiceLibrary.substring(
                        _parentHash2,
                        i,
                        i + 1
                    );

                if (
                    geneticDecider >= parent1Chance + parent2Chance &&
                    geneticDecider <= 100
                ) {
                    if (_OGParentCount == 0)
                        appendString = rarityGen(
                            generateRandomNumber(_tokenId, 10000),
                            i - 1
                        );
                    if (_OGParentCount == 1)
                        appendString = rarityGen(
                            generateRandomNumber(_tokenId, 10000),
                            i
                        );
                    if (_OGParentCount == 2)
                        appendString = rarityGen(
                            generateRandomNumber(_tokenId, 10000),
                            i + 1
                        );
                }

                childHashBytes = abi.encodePacked(childHashBytes, appendString);
                continue;
            }
        }

        return string(childHashBytes);

        //Hat - a
        //whiskers - g
        //Neck - a
        //Earrings - a
        //Eyes - g
        //Mouth - g
        //Nose - g
        //Character - g
    }

    function revealBaby(uint256 _tokenId) public {
        //Require this to not be a contract
        require(msg.sender == tx.origin, "Contracts not allowed to reveal");

        //Require that they own it
        require(ownerOf(_tokenId) == msg.sender, "You do not own this baby.");

        //It must be revealable right now
        require(block.number >= _tokenToIncubator[_tokenId].revealBlock, "Block number is less than the reveal block.");

        //It must be unrevealed
        require(_tokenToRevealed[_tokenId] == false, "Token is already revealed");

        if (legendariesMinted < 9) {
            uint256 legendaryDecider = generateRandomNumber(
                _tokenId,
                LEGENDARY_TIERS[legendariesMinted]
            );

            if (legendaryDecider == 0) {
                //This is a legendary
                _tokenIdToLegendary[_tokenId] = true;

                legendariesMinted++;

                //It will assign this legendary
                _tokenIdToLegendaryNumber[_tokenId] = legendariesMinted;

                //Make it view as revealed
                _tokenToRevealed[_tokenId] = true;
                return;
            }
        }

        uint8 _OGParentCount;

        if (_tokenToIncubator[_tokenId].parentId1 < 2000) _OGParentCount++;
        if (_tokenToIncubator[_tokenId].parentId2 < 2000) _OGParentCount++;

        //This will not be a legendary
        _tokenIdToLegendary[_tokenId] = false;

        //Set its hash as to what is generated
        tokenIdToHash[_tokenId] = generateChildHash(
            _tokenId,
            IAnonymice(ANONYMICE_ADDRESS)._tokenIdToHash(
                _tokenToIncubator[_tokenId].parentId1
            ),
            IAnonymice(ANONYMICE_ADDRESS)._tokenIdToHash(
                _tokenToIncubator[_tokenId].parentId2
            ),
            _OGParentCount
        );

        //Make it view as revealed
        _tokenToRevealed[_tokenId] = true;
    }

    function setAddresses(
        address _descriptorAddress,
        address _anonymiceAddress,
        address _cheethAddress,
        address _puzzleAddress
    ) public onlyOwner {
        ANONYMICE_BREEDING_DESCRIPTOR_ADDRESS = _descriptorAddress;
        CHEETH_ADDRESS = _cheethAddress;
        ANONYMICE_ADDRESS = _anonymiceAddress;
        PUZZLE_ADDRESS = _puzzleAddress;
    }

    function getBreedingEventsLengthByAddress(address breeder)
        public
        view
        returns (uint256)
    {
        return _addressToBreedingEvents[breeder].length;
    }

    /**
     * @dev Returns a hash for a given tokenId
     * @param _tokenId The tokenId to return the hash for.
     */
    function _tokenIdToHash(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory tokenHash = tokenIdToHash[_tokenId];
        //If this is a burned token, override the previous hash
        if (ownerOf(_tokenId) == 0x000000000000000000000000000000000000dEaD) {
            tokenHash = string(
                abi.encodePacked(
                    "1",
                    AnonymiceLibrary.substring(tokenHash, 1, 9)
                )
            );
        }

        return tokenHash;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            IAnonymiceBreedingDescriptor(ANONYMICE_BREEDING_DESCRIPTOR_ADDRESS)
                .tokenURI(_tokenId);
    }
}