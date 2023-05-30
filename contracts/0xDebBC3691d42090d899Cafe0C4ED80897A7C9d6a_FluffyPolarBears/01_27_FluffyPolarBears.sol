// SPDX-License-Identifier: MIT
//  ______ _        __  __         _____      _              ____
// |  ____| |      / _|/ _|       |  __ \    | |            |  _ \
// | |__  | |_   _| |_| |_ _   _  | |__) |__ | | __ _ _ __  | |_) | ___  __ _ _ __ ___
// |  __| | | | | |  _|  _| | | | |  ___/ _ \| |/ _` | '__| |  _ < / _ \/ _` | '__/ __|
// | |    | | |_| | | | | | |_| | | |  | (_) | | (_| | |    | |_) |  __/ (_| | |  \__ \
// |_|    |_|\__,_|_| |_|  \__, | |_|   \___/|_|\__,_|_|    |____/ \___|\__,_|_|  |___/
//                          __/ |
//                         |___/
//
// Fluffy Polar Bears ERC-1155 Contract
// “Ice to meet you, this contract is smart and fluffy.”
/// @creator:     FluffyPolarBears
/// @author:      kodbilen.eth - twitter.com/kodbilenadam
/// @contributor: peker.eth – twitter.com/MehmetAliCode

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./FluffyCore.sol";
import "./Library.sol";

contract FluffyPolarBears is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, FluffyCore, IERC721Receiver {

    using Counters for Counters.Counter;

    address public constant CONTRACT_DEVELOPER_ADDRESS = 0x16eFE37c0c557D4B1D8EB76d11E13616d2b52eAF;
    address public constant ARTIST_ADDRESS = 0xAD4dcA5A70b4b2467301879B83484dFB550698c6;
    address public constant POOL_ADDRESS = 0x084C29a614e0F40a01dD028E1eE2Fb5046585316;
    address public constant WEB_DEVELOPER_ADDRESS = 0x09D5b72677F42caa0Caa68519CdFC679cc6c24C0;
    address public constant COMMUNITY_MANAGER_ADDRESS = 0xc1b17d7Cb355FE015E29C3575B12DF722D764959;
    address public constant SHAREHOLDER_ADDRESS = 0x9E650ef13d0893A8729B3685285Fbc918b4850C6;
    address public constant CHARITY_ADDRESS = 0x336353B2BfeFeB6d4241bC3E2009eC4D18cBdD74;

    uint public CONTRACT_DEVELOPER_FEE = 3;
    uint public ARTIST_FEE = 25;
    uint public POOL_FEE = 12;
    uint public WEB_DEVELOPER_FEE = 7;
    uint public COMMUNITY_MANAGER_FEE = 24;
    uint public SHAREHOLDER_FEE = 24;
    uint public CHARITY_FEE = 5;
    
    uint constant SHARE_SUM = 100;
    uint constant TOTAL_SUPPLY = 9999;

    uint256 public REROLL_PRICE = 0.033 ether;

    address private _ERC1155BURNADDRESS;

    bool public isMintingActive = false;
    bool public isRerollActive = false;

    string IMAGE_URL;
    string[][100] attributeIdsToNames;
    string[] attributeCategoryIdToName = ["Background", "Costume", "Eye", "Head", "Nose"];
    string[] legendaryIdToName = ["Vanilla Bear", "Golden Bear", "Puzzled Bear", "3D Bear", "Polar Lisa", "The Scream", "Vincent Polar Gogh", "Great Wave", "Bearida Kahlo", "Pablo Polarsco", "Bearet Mondriaan", "Salvador Fluffy", "Gm Bear", "Shakespeare", "Amabearus Mozart", "Crossword Fluffy", "Frankicetein", "Crazy Wizard", "Count Bearacula", "Fluffy Witch", "Zombear", "Evil Fluffy Robot", "Mummy Bear", "Cave Bear", "Fluffy Unicorn", "Fluffy Cowboy", "Astronaut Bear", "Desert Bear", "Bipolar", "Super Fluffy", "Fluffy Punk", "Purple Punk", "Ninja Bear", "Fluffy Pilot", "Pirate Captain", "Exhausted Bear", "Fluffy Painter", "Left Looking Bear", "Pink Bear", "Fluffy Bandit", "Ducky", "Chick", "Office Bear", "Fluffy Warrior", "Mcbear's", "Ethbeary", "Hodl Bear", "Frozen Fluffy", "Beauty Bear", "Intern Viking", "Shiny", "Tattooed Bear", "Silhouette Bear", "Ski Bear", "Fluffy Neo", "Robear Hood", "Bearlie Chaplin", "Obear Wan", "Bearlock Holmes", "Sad Sailor", "Fluffy Captain", "Miss Fluffy Sunshine", "Chief Redbird", "Diver Bear", "Rainbow Bear", "Albear Icetein", "Galileo Fluffio", "Iceac Newton", "Niclaw Tesla", "Fluffy Marie Curie", "Fluffy Santa", "Fluffy Holiday", "Stormy", "Narcissist Bear", "Seally Bear", "Fluffy Knight", "Princess Aurora", "Karate Bear", "Fluffy Lighthouse", "Party Bear", "Rainy", "Igloo Bear", "Fluffy Panda", "Fluffy Fall", "Pizza Chef", "Stoned Bear", "Sharky", "The Goat", "Fluffy Pharaoh", "Art Bear", "Manga Bear", "Fluffy Hipster", "Lucky", "Bearly Bear", "The Ice King", "Yeti", "Coder Bear", "Fluffy Arctic Wolf", "Baby Bear"];

    string public metadataProvenance;

    constructor(address SketchAddress) ERC721("Fluffy Polar Bears", "FPB") {
        _ERC1155BURNADDRESS = SketchAddress;

        attributeIdsToNames[0] = ["Pink", "Orange", "Blue", "Purple", "Yellow", "Fuchsia", "Green", "Rose", "Electric Pink", "Light Green"];
        attributeIdsToNames[1] = ["Yellow T-shirt", "Casual T-shirt", "Red Shirt", "Purple Polo", "Party Dress", "Purple Hoodie", "Purple Waistcoat", "Blue Scarf", "Pirate", "Blue Shirt&Tie", "White Shirt&Tie", "Suit", "Yellow Puffer", "Pink Scarf", "Pink Dress", "Caveman", "Karate", "Rock T-shirt", "Punk Jacket", "Explorer", "Trenchcoat", "Hawaiian Shirt", "Fur Coat", "Viking", "Yellow Sweater", "Red Sweater", "Warrior", "Wizard", "Sailor", "Cowboy", "Pilot", "Pink Blouse", "Painter", "Princess", "Craftsman", "Chef", "Aristocrat", "King", "Clown", "Pharaoh", "Red Hoodie", "Hodl Hoodie", "Captain", "Aviator", "Admiral", "Blue Bathrobe", "Pink Towel", "Denim Jacket", "Black Suit", "Plaid Shirt", "Poncho", "Prisoner", "Bikini", "Yellow Raincoat", "Hawaaian", "ETH Sweater", "ETH Hoodie", "Gold Chain", "Straitjacket", "FPB Chain", "Ski Coat", "Snow", "FPB T-shirt", "Santa", "Life Jacket", "Knight", "Legionnaire", "Roman", "Gold Medal", "Robin", "Tribal", "Gardener", "Vampire", "Super Bear", "Astronaut", "Hipster", "Tattoo", "Xmas Lights", "Jersey", "Snow Sweatshirt", "Jedi", "Detective", "Polka Dot Bikini", "Witch"];
        attributeIdsToNames[2] = ["Straight", "Left", "Calm", "Thinker", "Angry", "Wobbly", "Embarassed", "Sad", "Tired", "Innocent", "Heart Glasses", "Cool", "Dizzy", "Sunglasses", "Blue Glasses", "Retro Glasses", "Pirate", "In Love", "3D", "Sneaky", "Triple", "Confused", "Winky", "Cunning", "Flower Glasses", "Crossed", "Crying", "Punk", "Starry", "Thug Life", "Ski Goggles", "Condescending", "Super Hero", "Cute", "Furious", "Cucumber", "Purple Glasses", "Manga Eyes", "Steampunk", "Red Glasses", "Hipster Glasses", "Green Laser", "Red Laser", "Dreamer", "Fragile", "Lol", "Shiny", "Masquerade"];
        attributeIdsToNames[3] = ["Santa", "Fish", "Purple Beanie", "Frog Beanie", "Wizard", "Crab", "Pirate", "Viking", "Pink Hat", "Fedora Hat", "Punk", "Purple Hair", "Blue Cap", "Navy Cap", "Admiral", "Paper Boat", "Bandana", "Party Hat", "Lighthouse", "Reverse Cap", "Graduated", "Top Hat", "Emo", "Blonde", "Karate Bandana", "Punk Cap", "Explorer", "Rice Hat", "Sailor", "Seagull", "Cowboy", "Devil", "Frog", "Motorbike Helmet", "Pilot", "Mushroom", "Manga Hair", "Painter", "Princess", "Safety Helmet", "Chef", "Wig", "Gold Crown", "Clown", "Polar Bear Beanie", "Red Bow", "Pharaoh", "Igloo", "Captain", "Aviator", "Towel", "Duck", "Hodl Cap", "Ice Crown", "Caveman", "Sombrero", "Prisoner", "Ice-Cream", "Unicorn", "Coffee", "Straw Hat", "Rain Hat", "Bowler Hat", "Flowers", "Toilet Paper", "Funnel", "FPB Cap", "Pompom", "Propeller Hat", "Knight", "Legionnaire", "Civic Crown", "Cooking Pot", "Shark", "Robin", "Feather Headband", "Vampire", "Hero", "Hipster", "Basketball", "Chicken", "Traffic Cone", "Curly", "Witch", "Detective", "Pony Tail", "McBear", "Headphones"];
        attributeIdsToNames[4] = ["Neutral", "Smiling", "Laughing", "Sweet", "Sad", "Tongue Out", "Teeth", "Crooked Teeth", "Smirky", "Playful", "Doubt", "Cool", "Fickle", "Bucktoothed", "Two Teeth", "Mmm", "Puzzled", "Lipstick", "Exhausted", "Whistling", "Goofy", "Frozen", "Romantic", "Vampire", "Content", "Manga Mouth", "Disco", "Moustache", "Runny Nose", "Crazy", "Satisfied", "Hodl"];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function safeMint() public onlyOwner {
        uint256 current = _tokenIdCounter.current();
        require(current < TOTAL_SUPPLY, "Purchase would exceed max tokens");

        _safeMint(msg.sender, current);
        super.setMetadata(current);
        tokenIds.push(current);
        _tokenIdCounter.increment();
    }

    function updateERC1155BurnAddress(address erc1155BurnAddress) external onlyOwner {
        _ERC1155BURNADDRESS = erc1155BurnAddress;
    }

    /**
     * @dev Start the minting process
     */
    function startMintingProcess() public onlyOwner {
        isMintingActive = true;
    }

    /**
     * @dev Pause the public sale
     */
    function pauseMintingProcess() public onlyOwner {
        isMintingActive = false;
    }

    /**
     * @dev Start the reroll
     */
    function startRerollProcess() public onlyOwner {
        isRerollActive = true;
    }

    /**
     * @dev Pause the reroll
     */
    function pauseRerollProcess() public onlyOwner {
        isRerollActive = false;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function reroll(uint256 tokenId) external payable {
        require(isRerollActive, "Reroll not active");
        require(msg.sender == ownerOf(tokenId), "Only owner can reroll.");

        require(REROLL_PRICE <= msg.value, "Ether value sent is not correct");
        super.setMetadata(tokenId);
    }


    function setImageUrl(string memory _imageUrl) onlyOwner public {
        IMAGE_URL = _imageUrl;
    }


    function generateMetadata(uint256 _tokenId) public view returns (string memory) {
        string memory metadataString;

        Token memory token = tokens[_tokenId];

        if (token.isLegendary) {
            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"Legendary","value":"',
                    legendaryIdToName[token.legendaryId],
                    '"}'
                )
            );
        } else {
            uint8[5] memory attributes = [token.bg, token.costume, token.eyes, token.head, token.nose];

            for (uint8 i = 0; i < attributes.length; i++) {
                uint256 value = attributes[i];

                metadataString = string(
                    abi.encodePacked(
                        metadataString,
                        '{"trait_type":"',
                        attributeCategoryIdToName[i],
                        '","value":"',
                        attributeIdsToNames[i][value - 1],
                        '"}'
                    )
                );

                if (i != attributes.length - 1) metadataString = string(abi.encodePacked(metadataString, ","));
            }
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(tokens[_tokenId].isExists);

        return
        string(
            abi.encodePacked(
                "data:application/json;base64,",
                Library.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Fluffy Polar Bears #',
                                Library.toString(_tokenId),
                                '", "description": "After a very harsh ice age, polar bears were the only species that survived. Now, they need to explore the world, create inventions and a world of polar bears - cold, funky and definitely interesting! Fluffy Polar Bears are a collection of 9,999 randomly and fully On-Chain generated NFTs that exist on the Ethereum Blockchain.", "image": "',
                                IMAGE_URL,
                                Library.toString(_tokenId),
                                '","external_url":"https://polarbearsnft.com/token/',
                                Library.toString(_tokenId),
                                '","attributes":',
                                generateMetadata(_tokenId),
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(address, address from, uint256 id, bytes calldata data) public virtual override returns (bytes4) {
        require(msg.sender == _ERC1155BURNADDRESS && id == 1, "Invalid NFT");
        require(isMintingActive, "Minting is not active yet.");


        uint256 current = _tokenIdCounter.current();
        require(current + 1 <= TOTAL_SUPPLY, "Purchase would exceed max tokens");


        // Burn it
        try ERC1155Burnable(msg.sender).burn(address(this), id, 1) {
        } catch Error(string memory reason) {
            emit ErrorHandled(reason);
            revert("Burn failure");
        } catch (bytes memory lowLevelData) {
            emit ErrorNotHandled(lowLevelData);
            revert("Burn failure");
        }


        for (uint i = 0; i < 1; i++) {
            uint256 current = _tokenIdCounter.current();
            require(current < TOTAL_SUPPLY, "Purchase would exceed max tokens");

            _safeMint(from, current);
            super.setMetadata(current);
            tokenIds.push(current);
            _tokenIdCounter.increment();
        }

        return this.onERC721Received.selector;
    }


    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns(bytes4) {
        _onERC1155Received(from, id, value, data);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns(bytes4) {
        require(ids.length == values.length, "Invalid input");
        for (uint i = 0; i < ids.length; i++) {
            _onERC1155Received(from, ids[i], values[i], data);
        }
        return this.onERC1155BatchReceived.selector;
    }

    event ErrorHandled(string reason);
    event ErrorNotHandled(bytes reason);

    function _onERC1155Received(address from, uint256 id, uint256 value, bytes calldata data) private {
        require(msg.sender == _ERC1155BURNADDRESS && id == 1, "Invalid NFT");
        require(isMintingActive, "Minting is not active yet.");

        uint256 current = _tokenIdCounter.current();
        require(current + value <= TOTAL_SUPPLY, "Purchase would exceed max tokens");


        // Burn it
        try ERC1155Burnable(msg.sender).burn(address(this), id, value) {
        } catch Error(string memory reason) {
            emit ErrorHandled(reason);
            revert("Burn failure");
        } catch (bytes memory lowLevelData) {
            emit ErrorNotHandled(lowLevelData);
            revert("Burn failure");
        }


        for (uint i = 0; i < value; i++) {
            uint256 current = _tokenIdCounter.current();
            require(current < TOTAL_SUPPLY, "Purchase would exceed max tokens");

            _safeMint(from, current);
            super.setMetadata(current);
            tokenIds.push(current);
            _tokenIdCounter.increment();
        }
    }

    mapping (address => bool) isBlacklisted;
    
    function addToBlacklist(address[] memory _addresses, bool _value) onlyOwner public {
        for (uint i = 0; i < _addresses.length; i++) {
            isBlacklisted[_addresses[i]] = _value;
        }
    }

    function setTokenAsLegendary (uint256 tokenId, uint8 id, uint16[] memory tokenIdMap, uint16 tokenCount) private {
        // Convert cleanedTokenId to actual token id
        tokenId = tokenIdMap[tokenId];
        
        if (tokens[tokenId].isLegendary) {
            uint256 random = uint256(keccak256(abi.encode(tokenId, randomResult))) % tokenCount;
            setTokenAsLegendary(random, id, tokenIdMap, tokenCount);
        } else {
            Token memory _token = tokens[tokenId];
            _token.isLegendary = true;
            _token.legendaryId = id;
            tokens[tokenId] = _token;

            emit TokenInfoChanged(_token);
        }
    }


    function _setLegendaries(uint256[] memory _legendaries, uint16[] memory tokenIdMap, uint16 tokenCount) private {
        uint256 len = _legendaries.length;

        for (uint8 i = 0; i < len; i++) {
            uint256 token = _legendaries[i];

            setTokenAsLegendary(token, i, tokenIdMap, tokenCount);
        }
    }
    
    
    function setLegendaries() public onlyOwner {
        uint currentSupply = _tokenIdCounter.current(); // 9999
        
        uint16 cleanedTokenIdCounter = 0;
        
        uint16[] memory cleanedTokensToActualTokenIds = new uint16[](currentSupply);

        
        for (uint16 tokenId = 0; tokenId < currentSupply; tokenId++) {
            address owner = this.ownerOf(tokenId);
            
            if(isBlacklisted[owner] != true) {
                cleanedTokensToActualTokenIds[cleanedTokenIdCounter] = tokenId;
                cleanedTokenIdCounter += 1;
            }
        }
        
        uint256[] memory luckyTokens = expand(randomResult, 99, cleanedTokenIdCounter);
        _setLegendaries(luckyTokens, cleanedTokensToActualTokenIds, cleanedTokenIdCounter);
    }
    
    function expand(uint256 randomValue, uint256 n, uint256 tokenCount) private pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i))) % tokenCount;
        }
        return expandedValues;
    }


    function setMetadataProvenance(string memory _hash) onlyOwner public {
        metadataProvenance = _hash;
    }

    /**
    * @dev Withdraw and distribute the ether.
     */
    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;

        uint toContractDeveloper = (balance * CONTRACT_DEVELOPER_FEE) / SHARE_SUM;
        uint toArtist = (balance * ARTIST_FEE) / SHARE_SUM;
        uint toWebDeveloper = (balance * WEB_DEVELOPER_FEE) / SHARE_SUM;
        uint toCommmunityManager = (balance * COMMUNITY_MANAGER_FEE) / SHARE_SUM;
        uint toShareholder = (balance * SHAREHOLDER_FEE) / SHARE_SUM;
        uint toCharity = (balance * CHARITY_FEE) / SHARE_SUM;
        uint toPool = (balance * POOL_FEE) / SHARE_SUM;


        payable(CONTRACT_DEVELOPER_ADDRESS).transfer(toContractDeveloper);
        payable(ARTIST_ADDRESS).transfer(toArtist);
        payable(WEB_DEVELOPER_ADDRESS).transfer(toWebDeveloper);
        payable(COMMUNITY_MANAGER_ADDRESS).transfer(toCommmunityManager);
        payable(SHAREHOLDER_ADDRESS).transfer(toShareholder);
        payable(CHARITY_ADDRESS).transfer(toCharity);
        payable(POOL_ADDRESS).transfer(toPool);


        uint toOwner = balance - (toContractDeveloper + toArtist + toWebDeveloper + toCommmunityManager + toShareholder + toCharity + toPool);
        payable(msg.sender).transfer(toOwner);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}