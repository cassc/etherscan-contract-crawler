// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "./Base64.sol";

contract NumberQuest is ERC721A, ERC721AQueryable, Ownable {
    uint256 public maxSupply = 20000;
    uint256 public maxMintsPerWallet = 100;
    uint256 public price = 0.006 ether;

    // Phase 1 - minting phase
    // Phase 2 - merging phase
    // Phase 3 - questing phase
    // Phase 4 - ?
    uint64 public phase = 1;

    bool public isPaused = false;
    string public baseURI = ''; // For the permanent image.
    string public dynamicImageURI = "https://number-quest.vercel.app/"; // For the dynamic image generation.

    struct TokenData {
        // Type of token. If false, it's a number
        bool isModifier;
        // The value of the number/modifier
        uint64 value;
        uint64 generation;
    }

    // Mapping from token ID to TokenData
    mapping(uint256 => TokenData) private _tokenData;

    struct QuestData {
        // 0-100 percentage chance to trigger
        uint64 triggerChance;
        // 1 Merge any type
        // 2 Merge number and number
        // 3 Merge number and multiplier
        // 4 Merge multiplier and multiplier
        // 5 Result ending with a number x
        // 6 result is number x
        // 7 result ending with number greater than x
        // 8 Result ending with number less than x
        // 9 Result divisible by x
        uint64 questType;
        uint64 questTypeParam;
        // 1 mint chance
        // 2 Increase result by fixed amount x
        // 3 Increase result by percentage amount x
        // 4 One card wont get burned (lower card)
        uint64 rewardType;
        uint64 rewardTypeParam;
    }

    // Instructs how the quest reward should be handled.
    struct QuestRewardResult {
        // 0 = do nothing more
        // 1 = mint a new token
        // 2 = apply the new token data to the new token created during merge
        // 3 = don't burn one card
        uint256 action;
        TokenData tokenData;
    }

    mapping(uint256 => QuestData) private _questData;
    uint256 _numQuests = 0;

    constructor() ERC721A("Number Quest", "NUMQUEST") {}

    function mint(uint256 quantity) external payable {
        require(!isPaused, "Contract paused");
        require(phase == 1, "Minting is during phase 1 only");
        require(_totalMinted() + quantity <= maxSupply, "Not enough tokens left");

        require(quantity + _numberMinted(msg.sender) <= maxMintsPerWallet, "Exceeded wallet limit");
        require(msg.value >= quantity * price, "Ether value sent is not sufficient");

        // Create the random token.
        uint256 startingTokenId = _nextTokenId();
        for(uint256 _tokenId=startingTokenId; _tokenId<startingTokenId + quantity; _tokenId++){
            _tokenData[_tokenId] = createRandomToken(_tokenId);
        }

        _safeMint(msg.sender, quantity);

        // If enough mints have taken place, move to next phase.
        if ( _totalMinted() >= maxSupply ) {
            setPhase(phase + 1, '');
        }
    }

    function combine(uint256 _tokenId1, uint256 _tokenId2) external payable {
        require(!isPaused, "Contract paused");
        require(phase == 2 || phase == 3, "Combining is only phase 2 and phase 3");
        require(_exists(_tokenId1) && _exists(_tokenId2), "Invalid Token");
        require(ownerOf(_tokenId1) == msg.sender && ownerOf(_tokenId2) == msg.sender, "Invalid Owner");
        require(_tokenId1 != _tokenId2, "Must be different tokens");

        TokenData memory newTokenData = combineTokens(_tokenId1, _tokenId2);

        // If phase 3 questing phase, do quests.
        bool questResult = false;
        uint256 _rewardTokenId = 0;
        QuestRewardResult memory questReward;
        if ( phase == 3 ) {
            QuestData memory quest = getCurrentQuest( block.timestamp );
            questResult = doQuest(_tokenId1, _tokenId2, newTokenData, quest );

            // Do quest rewards if successful
            if ( questResult ) {
                questReward = getQuestReward( newTokenData, quest );

                // Quest reward 2 means we adjust the resulting token with new values.
                if ( questReward.action == 2 ) {
                    newTokenData.value = questReward.tokenData.value;
                }
    
                // Quest reward 1 means we mint a new token.
                if ( questReward.action == 1 ) {
                    uint256 rewardTokenId = _nextTokenId();
                    _rewardTokenId = rewardTokenId;
                    _tokenData[rewardTokenId] = createRandomToken(rewardTokenId);
                    _safeMint(msg.sender, 1);
                }
            }
        }

        // Burns the tokens, takes into account phase 3 questing rewards.
        burnTokensAfterCombine( _tokenId1, _tokenId2, questResult, questReward );
        
        uint256 _newTokenId = _nextTokenId();
        _tokenData[_newTokenId] = newTokenData;

        _safeMint(msg.sender, 1);

        emit TokenCombined(_tokenId1, _tokenId2, _newTokenId, questResult, _rewardTokenId);
    }

    // Sets the current phase and optionally set an argument too
    function setPhase(uint64 _phase, string memory _value) public onlyOwner {
        phase = _phase;
        // For phase 4, allow also setting the baseURI to make things permanent.
        if ( _phase == 4 ) {
            baseURI = _value;
        }
    }

    function burn(uint256[] memory tokenIds) external onlyOwner {
        for(uint i=0; i<tokenIds.length; i++){
            _burn(tokenIds[i]);
        }
	}

    function burnTokensAfterCombine(uint256 _tokenId1, uint256 _tokenId2, bool questResult, QuestRewardResult memory questReward) private {
        bool burnToken1 = true;
        bool burnToken2 = true;

        if ( phase == 3 && questResult) {
            // We need to skip burning on the lower values token.
            // Burn the multiplier, or the higher value.
            if ( questReward.action == 3 ) {
                if ( _tokenData[_tokenId1].isModifier && ! _tokenData[_tokenId2].isModifier ) {
                    burnToken2 = false;
                } else if ( ! _tokenData[_tokenId1].isModifier && _tokenData[_tokenId2].isModifier ) {
                    burnToken1 = false;
                } else if ( _tokenData[_tokenId1].value < _tokenData[_tokenId2].value ) {
                    burnToken1 = false;
                } else {
                    burnToken2 = false;
                }
            }
        }

        if ( burnToken1 ) {
            _burn(_tokenId1);
            delete _tokenData[_tokenId1];
        }
        if ( burnToken2 ) {
            _burn(_tokenId2);
            delete _tokenData[_tokenId2];
        }
    }

    event TokenCombined(uint256 tokenId1, uint256 tokenId2, uint256 newTokenId, bool questResult, uint256 newTokenIdMinted);

    function createRandomToken(uint256 _tokenId) private view returns (TokenData memory) {
        uint64 value;
        uint r = random(1000, _tokenId);
        bool isModifier = r > 955;

        if ( r <= 90 ) {
            value = 1;
        } else if ( r <= 175 ) {
            value = 2;
        } else if ( r <= 255 ) {
            value = 3;
        } else if ( r <= 355 ) {
            value = 4;
        } else if ( r <= 405 ) {
            value = 5;
        } else if ( r <= 475 ) {
            value = 6;
        } else if ( r <= 545 ) {
            value = 7;
        } else if ( r <= 605 ) {
            value = 8;
        } else if ( r <= 665 ) {
            value = 9;
        } else if ( r <= 715 ) {
            value = 10;
        } else if ( r <= 765 ) {
            value = 11;
        } else if ( r <= 805 ) {
            value = 12;
        } else if ( r <= 845 ) {
            value = 13;
        } else if ( r <= 875 ) {
            value = 14;
        } else if ( r <= 905 ) {
            value = 15;
        } else if ( r <= 955 ) {
            value = 2;
        } else if ( r <= 980 ) {
            value = 3;
        } else if ( r <= 986 ) {
            value = 4;
        } else {
            value = 5;
        }

        return TokenData(
            isModifier,
            value,
            1
        );
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "Invalid Token");

        // If at phase 4, return the static JSON URI.
        if ( phase == 4 ) {
            if ( bytes(baseURI).length != 0 ) {
                return string(abi.encodePacked(baseURI, _toString(_tokenId)));
            }
        }

        bool isModifier = _tokenData[_tokenId].isModifier;
        uint64 value = _tokenData[_tokenId].value;
        string memory tokenIdStr = _toString(_tokenId);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "NUMQUEST ', tokenIdStr, '",',
                    '"description": "Embark on an epic journey of numeric discovery.",',
                    '"image":"', dynamicImageURI ,'?token=', tokenIdStr ,'&value=', isModifier ? 'x' : '', _toString( value ) ,'",'
                    '"attributes":[',
                    formTokenAttributes(_tokenId, isModifier, value),
                    ']}'
                )
            ))
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function formTokenAttributes(uint256 _tokenId, bool isModifier, uint64 value) private view returns (string memory) {
        uint64 generation = _tokenData[_tokenId].generation;

        return string(
            abi.encodePacked(
                '{"trait_type":"Type","value":"', isModifier ? 'Multiplier' : 'Number', '"},',
                '{"trait_type":"', (isModifier ? 'Multiplier' : 'Number'), '","value":', getLabel( isModifier, value ), '},',
                '{"trait_type":"Rarity","value":"', getRarity( value, isModifier ), '"},',
                '{"trait_type":"Generation","value":', _toString( generation ), '}'
            )
        );
    }

    function getData(uint256 _tokenId) public view returns (TokenData memory) {
        require(_exists(_tokenId), "URI does not exist!");
        return _tokenData[_tokenId];
    }

    function setData(uint256 _tokenId, bool isModifier, uint64 value, uint64 generation) external onlyOwner {
        require(_exists(_tokenId), "URI does not exist!");
        _tokenData[_tokenId].isModifier = isModifier;
        _tokenData[_tokenId].value = value;
        _tokenData[_tokenId].generation = generation;
    }

    function combineTokens(uint256 _tokenId1, uint256 _tokenId2) public view returns (TokenData memory) {
        require(_exists(_tokenId1), "Invalid Token");
        require(_exists(_tokenId2), "Invalid Token");

        TokenData memory _token1Data = _tokenData[_tokenId1];
        TokenData memory _token2Data = _tokenData[_tokenId2];

        bool isModifier = false;
        uint64 value;
        uint64 generation = _token1Data.generation > _token2Data.generation ? _token1Data.generation + 1 : _token2Data.generation + 1;

        if ( ! _token1Data.isModifier && ! _token2Data.isModifier ) {
            value = _token1Data.value + _token2Data.value;
        } else if ( _token1Data.isModifier && _token2Data.isModifier ) {
            isModifier = true;
            value = _token1Data.value * _token2Data.value;
        } else {
            value = _token1Data.value * _token2Data.value;
        }

        // Limits
        if ( ! isModifier && value > 18446744073709551615){
            value = 18446744073709551615;
        } else if ( isModifier && value > 999 ) {
            value = 999;
        }

        return TokenData(
            isModifier,
            value,
            generation
        );
    }

    function getRarity(uint64 num, bool isModifier) private pure returns (string memory) {
        if ( ! isModifier ) {
            if ( num <= 5 ) {
                return "Common";
            } else if ( num <= 20 ) {
                return "Uncommon";
            } else if ( num <= 120 ) {
                return "Rare";
            } else if ( num <= 260 ) {
                return "Superior";
            } else if ( num <= 900000 ) {
                return "Epic";
            } else if ( num <= 1000000 ) {
                return "Legendary";
            } else {
                return "Mythical";
            }
        }

        if ( num <= 5 ) {
            return "Rare";
        } else if ( num <= 100 ) {
            return "Epic";
        } else if ( num <= 500 ) {
            return "Legendary";
        }
        return "Mythical";
    }

    function getLabel(bool isModifier, uint64 value) private pure returns (string memory) {
        return _toString(value);
    }

    function random(uint max, uint256 seed) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _toString(seed)))) % max + 1;
    }

    function checkIfLastCharIs(string memory needle, string memory haystack) public pure returns (bool) {
        bytes memory stringBytes = bytes(haystack);
        return stringBytes[stringBytes.length - 1] == bytes(needle)[0];
    }

    function doQuest(uint256 _tokenId1, uint256 _tokenId2, TokenData memory newTokenData, QuestData memory quest) public view returns (bool) {
        // Is quest type a match?
        bool questTypeMatch = false;
        if ( quest.questType == 1 ) { // Merge any type
            questTypeMatch = true; 
        } else if ( quest.questType == 2 ) { // Merge number and number
            if ( ! _tokenData[_tokenId1].isModifier && ! _tokenData[_tokenId2].isModifier ) {
                questTypeMatch = true;
            }
        } else if ( quest.questType == 3 ) { // Merge number and multiplier
            if ( ( ! _tokenData[_tokenId1].isModifier && _tokenData[_tokenId2].isModifier ) || ( _tokenData[_tokenId1].isModifier && ! _tokenData[_tokenId2].isModifier ) ) {
                questTypeMatch = true;
            }
        } else if ( quest.questType == 4 ) { // Merge multiplier and multiplier
            if ( _tokenData[_tokenId1].isModifier && _tokenData[_tokenId2].isModifier ) {
                questTypeMatch = true;
            }
        } else if ( quest.questType == 5 ) { // Result ending with a specified number
            if ( checkIfLastCharIs( _toString( quest.questTypeParam ), _toString( newTokenData.value ) ) ) {
                questTypeMatch = true;
            }
        } else if ( quest.questType == 6 ) { // result is a specified number
            if ( newTokenData.value == quest.questTypeParam ) {
                questTypeMatch = true;
            }
        } else if ( quest.questType == 7 ) { // result ending with number greater than x
            if ( newTokenData.value >= quest.questTypeParam ) {
                questTypeMatch = true;
            }
        } else if ( quest.questType == 8 ) { // Result ending with number less than x
            if ( newTokenData.value <= quest.questTypeParam ) {
                questTypeMatch = true;
            }
        } else if ( quest.questType == 9 ) { // Result divisible by x
            uint result = newTokenData.value * 10 / quest.questTypeParam;
            if ( checkIfLastCharIs( '0', _toString( result ) ) ) {
                questTypeMatch = true;
            }
        }

        if ( ! questTypeMatch ) {
            return false;
        }

        // Check if RNG gods allow.
        uint rand = random(100, _tokenId1);
        return rand <= quest.triggerChance;
    }

    // Performs the quest reward. Returns a QuestRewardResult with instrcutions on what to do to apply the reward.
    function getQuestReward(TokenData memory newTokenData, QuestData memory quest) public pure returns (QuestRewardResult memory) {
        // Get the reward
        if ( quest.rewardType == 1 ) { // mint chance
            return QuestRewardResult( 1, newTokenData );
        } else if ( quest.rewardType == 2 ) { // Increase result by fixed amount
            newTokenData.value = newTokenData.value + quest.rewardTypeParam;
            return QuestRewardResult( 2, newTokenData );
        } else if ( quest.rewardType == 3 ) { // Increase result by percentage amount
            newTokenData.value = newTokenData.value * ( quest.rewardTypeParam + 100 ) / 100;
            return QuestRewardResult( 2, newTokenData );
        } else if ( quest.rewardType == 4 ) { // One card wont get burned (lowest card)
            return QuestRewardResult( 3, newTokenData );
        }
        return QuestRewardResult( 0, newTokenData );
    }

    function getCurrentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getCurrentQuest(uint256 timestamp) public view returns (QuestData memory) {
        require(_numQuests > 0, "No quests available");
        uint256 i = getCurrentQuestIndex(timestamp);
        return _questData[i];
    }

    function getCurrentQuestIndex(uint256 timestamp) private view returns (uint256) {
        return timestamp / 86400 % _numQuests;
    }

    function setQuests(uint64[] memory triggerChances, uint64[] memory questTypes, uint64[] memory questTypeParams, uint64[] memory rewardTypes, uint64[] memory rewardTypeParams) public onlyOwner {
        for(uint i=0; i<triggerChances.length; i++){
            _questData[i] = QuestData(
                triggerChances[i],
                questTypes[i],
                questTypeParams[i],
                rewardTypes[i],
                rewardTypeParams[i]
            );
        }
        _numQuests = triggerChances.length;
    }

    function setPause(bool value) external onlyOwner {
		isPaused = value;
	}

    function withdraw() external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, 'Nothing to Withdraw');
        payable(owner()).transfer(balance);
    }

    function withdrawTo(address to) external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, 'Nothing to Withdraw');
        payable(to).transfer(balance);
    }

    function setDynamicImageURI(string memory _dynamicImageURI) public onlyOwner {
        dynamicImageURI = _dynamicImageURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        maxSupply = _supply;
    }

    function setMaxMintPerWallet(uint256 _mint) public onlyOwner {
        maxMintsPerWallet = _mint;
    }

	function ownerMint(address to, uint quantity) external onlyOwner {
        uint256 startingTokenId = _nextTokenId();
        for(uint256 _tokenId=startingTokenId; _tokenId<startingTokenId + quantity; _tokenId++){
            _tokenData[_tokenId] = createRandomToken(_tokenId);
        }

        _safeMint(to, quantity);
	}

    function ownerAirdropToMulti(address[] memory airdrops, uint[] memory quantity) external onlyOwner {
        for(uint i=0; i<airdrops.length; i++){
            require(
                _totalMinted() + quantity[i] <= maxSupply,
                'Exceeded the limit'
            );

            uint256 startingTokenId = _nextTokenId();
            for(uint256 _tokenId=startingTokenId; _tokenId<startingTokenId + quantity[i]; _tokenId++){
                _tokenData[_tokenId] = createRandomToken(_tokenId);
            }

            _safeMint(airdrops[i], quantity[i]);
        }
    }
}