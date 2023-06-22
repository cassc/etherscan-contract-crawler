//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @creator: mhxalt.eth
/// @author: seesharp.eth

import "./contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface ITerraformer {
    function mint(uint256 tokenID1, uint256 tokenID2, uint256 tokenID3, address to_mint) external returns (uint32);
    function burn(uint256 tokenID) external returns (uint32[3] memory);
    function setHOMETokensFinished() external;
}

contract Homesick is ERC721A, DefaultOperatorFilterer, Ownable {
    using Address for address;

    event HomeTokenFound(uint256 indexed tokenId, address indexed addr);
    event ScoreAccumulationStarted(address indexed addr, uint256 tokenID1, uint256 tokenID2, uint256 tokenID3);

    address public terraformerAddr;

    string public baseURI;
    string public homeBaseURI;
    string public specimenExtension = ".png";
    string public homeExtension = ".png";
    string public homeAnimationExtension = ".mp4";
    uint256 constant public maxSupply = 999; // HOME tokens are not in this, they will be minted by burning one token so supply will remain static
    uint256 public mintedSupply = 0;
    uint256 public remainingAirDropSupply = 78;

    uint256 constant public mintPrice = 40e15;

    uint256 public mintPublicActiveTs = 0;

    struct Metadata {
        uint8 specimen_type;
        uint8 is_locked;
        uint16 potentia;

        uint16 original_token_index;
        
        int32 creation_date;
        uint32 seed;
    }
    struct HomeMetadata {
        uint16 original_token_index;
        uint16 token_order;
        
        uint32 creation_date;
        uint32 exoshellSeed;
        uint32 sonicSeed;
        uint32 self_creation_time;
    }
    mapping(uint256 => Metadata) public tokenMetadata; // tokenID => Metadata
    mapping(uint256 => HomeMetadata) public homeTokenMetadata; // tokenID => Metadata
    mapping(uint256 => uint8) public isHomeToken; // tokenID => 1 if home, 0 otherwise

    uint256 public scoreAccumulationStartTs = 0;
    struct WalletInfo {
        uint32 accumulation_start_ts;
        uint32 terraformerID;

        uint64 total_potentia;

        uint32 score_change_ts;
        uint64 score_change_tm_accumulated_score;
    }
    mapping(address => WalletInfo) public walletInfo;
    uint64 constant public homeMintScoreRequirement = /* getPlayerScoreForPotentia(30) */ 100 * 60 * 60 * 24 * 30; // NOTE: getPlayerScoreForPotentia(30) must be 100!!
    uint256 public remainingHomeTokens = 91;
    uint256 public homeTokenEndTs = 0;
    uint256 private currentHomeTokenIndex = 0;

    uint32 constant private specimenTypeCount = 23;
    // NOTE: min is inclusive and max (minPotentiaPerType + potentiaDiff) is NOT inclusive!!
    uint8[specimenTypeCount] private minPotentiaPerType = [20,30,60,20,70,30,10,40,10,20,30,50,70,70,50,40,80,60,40,80,70,10,30];
    uint8 private potentiaDiff = 10;
    int32[specimenTypeCount] private specimenCreationDatePerType = [int32(-1567953989),int32(-1258123589),int32(997258411),int32(-1097426789),int32(21798811),int32(947056411),int32(332662411),int32(-848843647),int32(755075611),int32(1045466011),int32(2079983611),int32(567288607),int32(35817394),int32(1781409545),int32(1835903611),int32(171321211),int32(379113211),int32(1654460011),int32(1541448031),int32(641934031),int32(899825400),int32(197582431),int32(804672811)];
    uint16[specimenTypeCount] private specimenSeedStarts = [1055,3847,3944,1289,1939,3135,2305,3868,1944,3466,2044,2104,3566,965,3861,841,3433,744,3771,1376,2108,1874,1506];
    // NOTE: biggest value of this array should be (specimenTypeCount - 1)
    uint8[maxSupply] private typeOfIndex = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 12, 12, 12, 12, 12, 12, 12, 12, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22];
    string[specimenTypeCount] private specimenTypeNames = [unicode"ÆC", unicode"ISÙ", unicode"ŮRY", unicode"IT§I", unicode"ŤIBA", unicode"CØA", unicode"ØSIA", unicode"ŮNA", unicode"SØA", unicode"XØN", unicode"NAĐ", unicode"GŁEA", unicode"ØRIA", unicode"ŮDIA", unicode"XφM", unicode"ØTRI", unicode"ZA∀", unicode"MÆ", unicode"ZÆ", unicode"LØM", unicode"HXM", unicode"ICª", unicode"EŁI"];

    constructor() ERC721A("Homesick", "H.H") {}

    bytes16 private constant __SYMBOLS = "0123456789abcdef";
    function toStringDecimal(uint256 value, uint256 decimal_point_pos) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits = 1;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            if (digits == decimal_point_pos) {
                buffer[digits] = '.';
                digits -= 1;
            }
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function toString(uint256 value, uint256 length) internal pure returns (string memory) {
        unchecked {
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                length--;
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), __SYMBOLS))
                }
                value /= 10;
                if (length == 0) break;
            }
            require(value == 0, "Strings: length insufficient");
            return buffer;
        }
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (isHomeToken[tokenId] == 0) {
            uint8 sign = 32; // ' '
            uint32 creation_date;
            if (tokenMetadata[tokenId].creation_date < 0) {
                sign = 45; // '-'
                creation_date = uint32(int32(-1) * tokenMetadata[tokenId].creation_date);
            } else {
                creation_date = uint32(tokenMetadata[tokenId].creation_date);
            }

            if (tokenMetadata[tokenId].is_locked == 1 && remainingHomeTokens != 0) {
                bytes memory metadata;
                {
                    metadata = abi.encodePacked(
                        '{"description":"With the use of 3D and AI mediums, HOXID has carefully curated 999 unique pieces from the latent space, creating a beautiful collection of specimens.","image":"',
                        baseURI,
                        Strings.toString(tokenMetadata[tokenId].original_token_index),
                        specimenExtension,
                        '","name":"Specimen #',
                        toString(tokenId, 4),
                        '","attributes":[{"trait_type":"Type Name","value":"',
                        specimenTypeNames[tokenMetadata[tokenId].specimen_type],
                        '"},{"trait_type":"Seed","value":"'
                    );
                }
                {
                    metadata = abi.encodePacked(
                        metadata,
                        Strings.toHexString(tokenMetadata[tokenId].seed, 4),
                        '"},{"trait_type":"Locked","value":"',
                        'Locked',
                        '"},{"trait_type":"Potentia","value":',
                        toStringDecimal(tokenMetadata[tokenId].potentia, 1),
                        '},{"display_type":"date","trait_type":"Creation Date","value":',
                        sign,
                        Strings.toString(creation_date),
                        '}]}'
                    );
                }
                return string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(metadata)
                    )    
                );
            } else {
                bytes memory metadata;
                {
                    metadata = abi.encodePacked(
                        '{"description":"With the use of 3D and AI mediums, HOXID has carefully curated 999 unique pieces from the latent space, creating a beautiful collection of specimens.","image":"',
                        baseURI,
                        Strings.toString(tokenMetadata[tokenId].original_token_index),
                        specimenExtension,
                        '","name":"Specimen #',
                        toString(tokenId, 4),
                        '","attributes":[{"trait_type":"Type Name","value":"',
                        specimenTypeNames[tokenMetadata[tokenId].specimen_type],
                        '"},{"trait_type":"Seed","value":"'
                    );
                }
                {
                    metadata = abi.encodePacked(
                        metadata,
                        Strings.toHexString(tokenMetadata[tokenId].seed, 4),
                        '"},{"trait_type":"Potentia","value":',
                        toStringDecimal(tokenMetadata[tokenId].potentia, 1),
                        '},{"display_type":"date","trait_type":"Creation Date","value":',
                        sign,
                        Strings.toString(creation_date),
                        '}]}'
                    );
                }
                return string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(metadata)
                    )    
                );
            }
        } else {
            bytes memory metadata;
            {
                bytes memory URI = abi.encodePacked(homeBaseURI, Strings.toString(homeTokenMetadata[tokenId].original_token_index));
                metadata = abi.encodePacked(
                    '{"description":"Home  \\n*The place where you live or feel you belong.*  \\n  \\nThis 1/1 special piece is part of the HOMESICK collection, with its unique generative sound design.","image":"',
                    URI,
                    homeExtension,
                    '","animation_url":"',
                    URI,
                    homeAnimationExtension
                );
            }
            {
                metadata = abi.encodePacked(
                    metadata,
                    '","name":"HOME #',
                    toString(homeTokenMetadata[tokenId].token_order, 2),
                    '","attributes":[{"trait_type":"Exoshell Seed","value":"',
                    Strings.toHexString(homeTokenMetadata[tokenId].exoshellSeed, 4),
                    '"},{"trait_type":"Sonic Seed","value":"'
                );
            }
            {
                metadata = abi.encodePacked(
                    metadata,
                    Strings.toHexString(homeTokenMetadata[tokenId].sonicSeed, 4),
                    '"},{"trait_type":"Type Name","value":"HOME"},{"trait_type":"Self Creation Time (Hours)","value":',
                    Strings.toString(homeTokenMetadata[tokenId].self_creation_time / 60 / 60),
                    '},{"display_type":"date","trait_type":"Creation Date","value":',
                    Strings.toString(homeTokenMetadata[tokenId].creation_date),
                    '}]}'
                );
            }
            return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(metadata)
                )    
            );
        }
    }

    mapping(uint => uint) private _availableTokens;
    // Implements https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle. Modified from ERC721R
    function getRandomUnusedTokenIndex(uint256 randomIndex, uint256 remainingTokenCount)
        internal
        returns (uint256)
    {
        uint256 valAtIndex = _availableTokens[randomIndex];
        uint256 result;
        if (valAtIndex == 0) {
            // This means the index itself is still an available token
            result = randomIndex;
        } else {
            // This means the index itself is not an available token, but the val at that index is.
            result = valAtIndex;
        }

        uint256 lastIndex = remainingTokenCount - 1;
        uint256 lastValInArray = _availableTokens[lastIndex];
        
        if (randomIndex != lastIndex) {
            // Replace the value at indexToUse, now that it's been used.
            // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
            if (lastValInArray == 0) {
                // This means the index itself is still an available token
                _availableTokens[randomIndex] = lastIndex;
            } else {
                // This means the index itself is not an available token, but the val at that index is.
                _availableTokens[randomIndex] = lastValInArray;
            }
        }
        if (lastValInArray != 0) {
            // Gas refund courtsey of @dievardump
            delete _availableTokens[lastIndex];
        }
        
        return result;
    }
    function getTypeOfIndex(uint256 randomIndex)
        internal view
        returns (uint8)
    {
        return typeOfIndex[randomIndex];
    }

    mapping(uint => uint) private _availableHomeTokens;
    // Implements https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle. Modified from ERC721R
    function getRandomUnusedHomeTokenIndex(uint256 randomIndex, uint256 remainingTokenCount)
        internal
        returns (uint256)
    {
        uint256 valAtIndex = _availableHomeTokens[randomIndex];
        uint256 result;
        if (valAtIndex == 0) {
            // This means the index itself is still an available token
            result = randomIndex;
        } else {
            // This means the index itself is not an available token, but the val at that index is.
            result = valAtIndex;
        }

        uint256 lastIndex = remainingTokenCount - 1;
        uint256 lastValInArray = _availableHomeTokens[lastIndex];
        
        if (randomIndex != lastIndex) {
            // Replace the value at indexToUse, now that it's been used.
            // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
            if (lastValInArray == 0) {
                // This means the index itself is still an available token
                _availableHomeTokens[randomIndex] = lastIndex;
            } else {
                // This means the index itself is not an available token, but the val at that index is.
                _availableHomeTokens[randomIndex] = lastValInArray;
            }
        }
        if (lastValInArray != 0) {
            // Gas refund courtsey of @dievardump
            delete _availableHomeTokens[lastIndex];
        }
        
        return result;
    }
    function mint(uint256 _mintAmount) public payable {
        require(!msg.sender.isContract(), "Should not be called from a contract!!");

        require(mintPublicActiveTs != 0, "public mint date is not set");
        require(block.timestamp >= mintPublicActiveTs, "wait for public mint time");

        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_mintAmount < 11, "max mint per tx is 10 NFTs");
        require((mintedSupply + remainingAirDropSupply + _mintAmount) <= maxSupply, "max NFT limit exceeded");

        require(msg.value >= _mintAmount * mintPrice, "insufficient funds");

        uint64 total_potentia = 0;
        uint256 end = mintedSupply + _mintAmount;
        for (uint256 i = mintedSupply; i < end; i++) {
            uint256 remainingTokenCount = maxSupply - i;

            uint256 random_seed = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, i)));
            uint32 _random_index = uint32((random_seed & 0xFFFF) % remainingTokenCount);
            uint256 random_unused_index = getRandomUnusedTokenIndex(_random_index, remainingTokenCount);
            uint8 specimen_type = getTypeOfIndex(random_unused_index);
            
            uint16 potentia = uint16(((random_seed >> 16) & 0xFFFF) % (potentiaDiff));
            potentia += uint16(minPotentiaPerType[specimen_type]);

            int32 creation_date = specimenCreationDatePerType[specimen_type] + int32(int256(uint256((random_seed >> 32) & (0xFFFFFFFF)) % 86400) - int256(43200));
            uint32 seed = uint32(((random_seed >> 64) & 0xFFFFF) | (uint32(specimenSeedStarts[specimen_type]) << 20));

            Metadata memory _localMetadata = Metadata(specimen_type, 0, potentia, uint16(random_unused_index), creation_date, seed);
            tokenMetadata[i] = _localMetadata;
            total_potentia += potentia;
        }
        mintedSupply += _mintAmount;

        WalletInfo memory localWalletTo = walletInfo[msg.sender];
        if (localWalletTo.accumulation_start_ts != 0) {
            uint64 toCurrentScore = getPlayerAccumulatedScore(localWalletTo);
            localWalletTo.score_change_ts = uint32(block.timestamp);
            localWalletTo.score_change_tm_accumulated_score = toCurrentScore;
        }
        localWalletTo.total_potentia += total_potentia;
        walletInfo[msg.sender] = localWalletTo;

        _safeMint(msg.sender, _mintAmount);
    }

    /**
    * SCORE RELATED FUNCTIONS
    */
    function startScoreAccumulation() external onlyOwner {
        scoreAccumulationStartTs = uint32(block.timestamp);
    }
    function startScoreAccumulation(uint256 tokenID1, uint256 tokenID2, uint256 tokenID3) public {
        require(scoreAccumulationStartTs != 0, "Score accumulation hasn't started yet");

        require(tokenID1 != tokenID2, "All tokens must be unique");
        require(tokenID2 != tokenID3, "All tokens must be unique");
        require(tokenID1 != tokenID3, "All tokens must be unique");

        require(ownerOf(tokenID1) == msg.sender, "Not the owner of locked tokens");
        require(ownerOf(tokenID2) == msg.sender, "Not the owner of locked tokens");
        require(ownerOf(tokenID3) == msg.sender, "Not the owner of locked tokens");

        // HOME tokens cannot be locked
        require(isHomeToken[tokenID1] == 0, "Cannot lock HOME tokens");
        require(isHomeToken[tokenID2] == 0, "Cannot lock HOME tokens");
        require(isHomeToken[tokenID3] == 0, "Cannot lock HOME tokens");

        WalletInfo memory localWalletInfo = walletInfo[msg.sender];
        require(localWalletInfo.accumulation_start_ts == 0, "Already started");
        // We don't need to check if the tokens have already been locked since a wallet cannot have multiple terraformers

        uint32 terraformerID = ITerraformer(terraformerAddr).mint(tokenID1, tokenID2, tokenID3, msg.sender);

        localWalletInfo.accumulation_start_ts = uint32(block.timestamp);
        localWalletInfo.terraformerID = terraformerID;
        walletInfo[msg.sender] = localWalletInfo;

        tokenMetadata[tokenID1].is_locked = 1;
        tokenMetadata[tokenID2].is_locked = 1;
        tokenMetadata[tokenID3].is_locked = 1;

        emit ScoreAccumulationStarted(msg.sender, tokenID1, tokenID2, tokenID3);
    }
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    function getPlayerScoreForPotentia(uint256 total_potentia) public pure returns (uint64) {
        total_potentia -= 20;
        total_potentia *= 1000000000000000; // 15 0es (one 0 less because potentia is fixed point with one decimal)
        return uint64(sqrt(sqrt(sqrt(total_potentia))));
    }
    function getPlayerAccumulatedScore(WalletInfo memory info) internal view returns (uint64) {
        if (scoreAccumulationStartTs == 0) { return 0; }
        if (info.accumulation_start_ts == 0) { return 0; } // user hasn't started to accumulate points
        
        uint256 check_ts = block.timestamp;
        if (remainingHomeTokens == 0) { 
            check_ts = homeTokenEndTs;
        }
        
        if (info.score_change_ts != 0) {
            return uint64(check_ts - info.score_change_ts) * getPlayerScoreForPotentia(info.total_potentia) + info.score_change_tm_accumulated_score;
        } else {
            return uint64(check_ts - info.accumulation_start_ts) * getPlayerScoreForPotentia(info.total_potentia);
        }
    }
    function getPlayerAccumulatedScore(address _addr) public view returns (uint64) {
        if (scoreAccumulationStartTs == 0) { return 0; }
        if (walletInfo[_addr].accumulation_start_ts == 0) { return 0; } // user hasn't started to accumulate points
        
        uint256 check_ts = block.timestamp;
        if (remainingHomeTokens == 0) { 
            check_ts = homeTokenEndTs;
        }
        
        if (walletInfo[_addr].score_change_ts != 0) {
            return uint64(check_ts - walletInfo[_addr].score_change_ts) * getPlayerScoreForPotentia(walletInfo[_addr].total_potentia) + walletInfo[_addr].score_change_tm_accumulated_score;
        } else {
            return uint64(check_ts - walletInfo[_addr].accumulation_start_ts) * getPlayerScoreForPotentia(walletInfo[_addr].total_potentia);
        }
    }
    function updateWalletInfoRemoveToken(address from, uint256 tokenID) internal {
        WalletInfo memory localWalletFrom = walletInfo[from];
        Metadata memory localMetadata = tokenMetadata[tokenID];

        if (localMetadata.is_locked == 1) { // transfer of locked token, burn ticket and remove score
            uint32 terraformerID = localWalletFrom.terraformerID;
            uint32[3] memory tokenIDs = ITerraformer(terraformerAddr).burn(terraformerID);

            tokenMetadata[tokenIDs[0]].is_locked = 0;
            tokenMetadata[tokenIDs[1]].is_locked = 0;
            tokenMetadata[tokenIDs[2]].is_locked = 0;

            localWalletFrom.accumulation_start_ts = 0;
            localWalletFrom.terraformerID = 0;
            localWalletFrom.score_change_ts = 0;
            localWalletFrom.score_change_tm_accumulated_score = 0;
            localWalletFrom.total_potentia -= localMetadata.potentia;
        } else {
            if (localWalletFrom.accumulation_start_ts != 0) {
                uint64 fromCurrentScore = getPlayerAccumulatedScore(localWalletFrom);
                localWalletFrom.score_change_ts = uint32(block.timestamp);
                localWalletFrom.score_change_tm_accumulated_score = fromCurrentScore;
            }
            localWalletFrom.total_potentia -= localMetadata.potentia;
        }
        walletInfo[from] = localWalletFrom;
    }
    function _afterTokenTransfers(
        address from, // this is 0x0 only when this is mint
        address to,
        uint256 startTokenId,
        uint256 // this is always 1 if its not a mint
    ) internal virtual override {
        if (from == address(0x0)) return; // mint calculates this itself
        if (remainingHomeTokens == 0) return; // HOME minting ended

        // HOME tokens does not affect anything
        if (isHomeToken[startTokenId] != 0) return;
        
        updateWalletInfoRemoveToken(from, startTokenId);
        Metadata memory localMetadata = tokenMetadata[startTokenId];

        if (to != address(0x0)) {
            WalletInfo memory localWalletTo = walletInfo[to];
            if (localWalletTo.accumulation_start_ts != 0) {
                uint64 toCurrentScore = getPlayerAccumulatedScore(localWalletTo);
                localWalletTo.score_change_ts = uint32(block.timestamp);
                localWalletTo.score_change_tm_accumulated_score = toCurrentScore;
            }
            localWalletTo.total_potentia += localMetadata.potentia;
            walletInfo[to] = localWalletTo;
        }
    }


    function mintHOMEToken(uint256 _tokenID) public {
        require(msg.sender == ownerOf(_tokenID), "Not your token!");
        require(remainingHomeTokens > 0, "All ultimate planets have been found");
        uint64 accumulatedScore = getPlayerAccumulatedScore(msg.sender);
        require(accumulatedScore > homeMintScoreRequirement, "Not enough accumulated score");

        require(isHomeToken[_tokenID] == 0, "Cannot burn HOME tokens");
        require(tokenMetadata[_tokenID].is_locked == 1, "Need to supply locked token to mint HOME token");

        uint256 random_seed = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, mintedSupply + currentHomeTokenIndex)));
        uint32 _random_index = uint32((random_seed & 0xFFFF) % remainingHomeTokens);
        uint256 random_unused_index = getRandomUnusedHomeTokenIndex(_random_index, remainingHomeTokens);
        uint32 exoshell_seed = uint32(((random_seed >> 32) & 0xFFFFFFFF));
        uint32 sonic_seed = uint32(((random_seed >> 64) & 0xFFFFFFFF));
        
        HomeMetadata memory _localMetadata = HomeMetadata(uint16(random_unused_index), 
                uint16(currentHomeTokenIndex),
                uint32(block.timestamp), exoshell_seed, sonic_seed, 
                uint32(block.timestamp - walletInfo[msg.sender].accumulation_start_ts));
        homeTokenMetadata[_tokenID] = _localMetadata;
        isHomeToken[_tokenID] = 1;

        // this will automatically reset counters, reduce total score and burn terraformer token
        updateWalletInfoRemoveToken(msg.sender, _tokenID);
        delete tokenMetadata[_tokenID];

        remainingHomeTokens -= 1;
        currentHomeTokenIndex += 1;

        if (remainingHomeTokens == 0) {
            ITerraformer(terraformerAddr).setHOMETokensFinished();
            homeTokenEndTs = block.timestamp;
        }

        emit HomeTokenFound(_tokenID, msg.sender);
    }



    /**
    * ADMIN FUNCTIONS
    */
    function airDrop(address[] memory _targets, uint256[] memory _mintAmounts) external onlyOwner {
        require((_targets.length) == (_mintAmounts.length), "array lengths should match");

        uint256 txMintedAmount = 0;
        uint256 currentIndex = mintedSupply;
        for (uint256 i = 0; i < _targets.length; i++) {
            uint64 total_potentia = 0;

            for (uint256 j = 0; j < _mintAmounts[i]; j++) {
                uint256 remainingTokenCount = maxSupply - (currentIndex);

                uint256 random_seed = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, currentIndex)));
                uint32 _random_index = uint32((random_seed & 0xFFFF) % remainingTokenCount);
                uint256 random_unused_index = getRandomUnusedTokenIndex(_random_index, remainingTokenCount);
                uint8 specimen_type = getTypeOfIndex(random_unused_index);
                
                uint16 potentia = uint16(((random_seed >> 16) & 0xFFFF) % (potentiaDiff));
                potentia += uint16(minPotentiaPerType[specimen_type]);

                int32 creation_date = specimenCreationDatePerType[specimen_type] + int32(int256(uint256((random_seed >> 32) & (0xFFFFFFFF)) % 86400) - int256(43200));
                uint32 seed = uint32(((random_seed >> 64) & 0xFFFFF) | (uint32(specimenSeedStarts[specimen_type]) << 20));

                Metadata memory _localMetadata = Metadata(specimen_type, 0, potentia, uint16(random_unused_index), creation_date, seed);
                tokenMetadata[currentIndex] = _localMetadata;
                total_potentia += potentia;

                currentIndex++;
            }

            txMintedAmount += _mintAmounts[i];
            _safeMint(_targets[i], _mintAmounts[i]);

            WalletInfo memory localWalletTo = walletInfo[_targets[i]];
            if (localWalletTo.accumulation_start_ts != 0) {
                uint64 toCurrentScore = getPlayerAccumulatedScore(localWalletTo);
                localWalletTo.score_change_ts = uint32(block.timestamp);
                localWalletTo.score_change_tm_accumulated_score = toCurrentScore;
            }
            localWalletTo.total_potentia += total_potentia;
            walletInfo[_targets[i]] = localWalletTo;
        }

        require(txMintedAmount <= remainingAirDropSupply, "max NFT limit exceeded");

        remainingAirDropSupply -= txMintedAmount;
        mintedSupply += txMintedAmount;
    }

    function activatePublicMint(uint256 _mintPublicActiveTs) external onlyOwner {
        require(mintPublicActiveTs == 0, "Already activated");
        mintPublicActiveTs = _mintPublicActiveTs;
    }
    function deactivatePublicMint() external onlyOwner {
        mintPublicActiveTs = 0;
    }

    function setTerraformerAddr(address _newterraformerAddr) external onlyOwner {
        terraformerAddr = _newterraformerAddr;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setHomeBaseURI(string memory _newHomeBaseURI) external onlyOwner {
        homeBaseURI = _newHomeBaseURI;
    }

    function setSpecimenExtension(string memory _newSpecimenExtension) external onlyOwner {
        specimenExtension = _newSpecimenExtension;
    }
    function setHomeExtension(string memory _newHomeExtension) external onlyOwner {
        homeExtension = _newHomeExtension;
    }
    function setHomeAnimationExtension(string memory _newHomeAnimationExtension) external onlyOwner {
        homeAnimationExtension = _newHomeAnimationExtension;
    }


    /**
     * ROYALTY FUNCTIONS
     */
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;

    function withdraw() external onlyOwner {
        require(_royaltyRecipient != address(0x0), "Must set royalty recipient");

        (bool os, ) = _royaltyRecipient.call{value: address(this).balance}("");
        require(os);
    }

    function withdrawERC20(address erc20_addr) external onlyOwner {
        require(_royaltyRecipient != address(0x0), "Must set royalty recipient");

        IERC20 erc20_int = IERC20(erc20_addr);
        uint256 balance = erc20_int.balanceOf(address(this));

        bool os = erc20_int.transfer(_royaltyRecipient, balance);
        require(os);
    }
    
    function updateRoyalties(address payable recipient, uint256 bps) external onlyOwner {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    bytes4 constant private _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 constant private _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 constant private _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE
            || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }
    
    receive() external payable {
    }


    /**
     * OPENSEA FILTER STUFF
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}