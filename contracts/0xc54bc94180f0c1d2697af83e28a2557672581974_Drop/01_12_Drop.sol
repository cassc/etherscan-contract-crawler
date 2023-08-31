// SPDX-License-Identifier: Unlicense

//  .----------------.  .----------------.  .----------------.  .----------------. 
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |   _____      | || |      __      | || |    ______    | || |     ____     | |
// | |  |_   _|     | || |     /  \     | || |  .' ___  |   | || |   .'    `.   | |
// | |    | |       | || |    / /\ \    | || | / .'   \_|   | || |  /  .--.  \  | |
// | |    | |   _   | || |   / ____ \   | || | | |    ____  | || |  | |    | |  | |
// | |   _| |__/ |  | || | _/ /    \ \_ | || | \ `.___]  _| | || |  \  `--'  /  | |
// | |  |________|  | || ||____|  |____|| || |  `._____.'   | || |   `.____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------' 

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "base64-sol/base64.sol";

contract Drop is ERC721, Ownable {
    string public nftName;
    string public description;
    uint256 public tokenIdCounter = 0;
    uint256 public tokenPrice;
    uint256 public maxSupply;
    string public imageUrl;
    string public animationUrl;
    string public nftUrl;
    bool public publicMintEnabled;
    uint256 private randomWord;

    string[] private choosableTraits;
    string[][] private choosableValues;
    string[] private randomTraits;
    string[][] private randomValues;
    uint16[] private traitsChance;
    uint256[] private dynamicChance;
    uint16[][] private valuesChance;
    mapping (uint => uint[]) private chosenTraits;
    mapping (uint => uint16[]) private traitIndexes;
    mapping (uint => uint8) private foundersArts;
    mapping (uint => bool) private hasDynamicTrait;
    mapping (uint => uint8) private dynamicTraits;
    uint256[] private dynamicTraitTokens;

    constructor(
        string memory _name,
        string memory _description,
        string memory _imageUrl,
        string memory _animationUrl,
        string memory _nftUrl,
        string memory _symbol,
        uint _tokenPrice,
        uint _maxSupply,
        string[][][] memory traits,
        uint16[][][] memory chances
    ) ERC721(_name, _symbol) {
        require(traits[0][0].length == traits[1].length &&
                traits[2][0].length == traits[3].length &&
                traits[3].length == chances[0][0].length &&
                traits[3].length == chances[2].length, "Invalid metadata");
        publicMintEnabled = false;
        maxSupply = _maxSupply;
        tokenPrice = _tokenPrice;
        nftName = _name;
        description = _description;
        imageUrl = _imageUrl;
        animationUrl = _animationUrl;
        nftUrl = _nftUrl;
        randomWord = uint(keccak256(
            abi.encodePacked(block.difficulty, block.timestamp, uint(blockhash(block.number-1)), uint(blockhash(block.number-2)))
        ));
        dynamicTraitTokens = new uint256[](0);
        choosableTraits = traits[0][0];
        choosableValues = traits[1];
        randomTraits = traits[2][0];
        randomValues = traits[3];
        traitsChance = chances[0][0];
        dynamicChance = chances[1][0];
        valuesChance = chances[2];
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
        return new uint256[](1);
        } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 resultIndex = 0;

        for (uint256 i = 1; i < tokenIdCounter + 1;) {
            if (ownerOf(i) == _owner) {
                result[resultIndex] = i;
                resultIndex++;
            }
            unchecked { ++i; }
        }
        return result;
        }
    }

    function totalSupply() public view returns (uint) {
        return tokenIdCounter;
    }

    function setName(string memory _name) external onlyOwner {
        nftName = _name;
    }

    function setDescription(string memory _description) external onlyOwner {
        description = _description;
    }

    function setImageUrl(string memory _imageUrl) external onlyOwner {
        imageUrl = _imageUrl;
    }

    function setAnimationUrl(string memory _animationUrl) external onlyOwner {
        animationUrl = _animationUrl;
    }

    function setNftUrl(string memory _nftUrl) external onlyOwner {
        nftUrl = _nftUrl;
    }

    function setTokenPrice(uint _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPublicMintEnabled(bool _publicMintEnabled) external onlyOwner {
        publicMintEnabled = _publicMintEnabled;
    }

    function randomMetadata(uint tokenId) private {
        foundersArts[tokenId] = uint8(randomWord % 10);
        for (uint16 i; i < traitsChance.length;) {
            if (uint(keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, randomWord, i, uint(blockhash(block.number-1))
                ))) % 10000 < traitsChance[i]) {
                if (valuesChance[i].length == 1) {
                    traitIndexes[tokenId].push(i<<8);
                } else {
                    randomWord = uint(keccak256(
                        abi.encodePacked(uint(blockhash(block.number-1)), randomWord, block.difficulty, block.timestamp, i
                    ))) % 10000;
                    for (uint16 j; j < valuesChance[i].length;) {
                        if (randomWord <= valuesChance[i][j]) {
                            uint16 trait = uint16(j);
                            trait |= i<<8;
                            traitIndexes[tokenId].push(trait);
                            break;
                        }
                        unchecked { ++j; }
                    }
                }
                
            }
            unchecked { ++i; }
        }
    }

    function clearMonthlyTraits() public onlyOwner {
        for (uint256 i; i < dynamicTraitTokens.length;) {
            hasDynamicTrait[dynamicTraitTokens[i]] = false;
            unchecked { ++i; }
        }
        dynamicTraitTokens = new uint256[](0);
    }

    function randomizeMonthlyTraits(uint percentNumerator, uint percentDenominator) public onlyOwner {
        for (uint i; i < dynamicChance.length;) {
            uint256 expectation = uint(uint(dynamicChance[i] * tokenIdCounter) / uint(10000));
            expectation = (expectation * percentNumerator) / percentDenominator;
            for (uint j; j < expectation;) {
                uint tokenId = (uint(keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, randomWord, i, j)
                )) % tokenIdCounter) + 1;
                if (!hasDynamicTrait[tokenId]) {
                    hasDynamicTrait[tokenId] = true;
                    dynamicTraits[tokenId] = uint8(i);
                    dynamicTraitTokens.push(tokenId);
                }
                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }

    function publicMint(uint16[] calldata traits) external payable {
        require(publicMintEnabled, "Public minting is disabled");
        require(msg.sender == tx.origin, "Contracts cannot mint");
        require(tokenIdCounter < maxSupply, "Total supply reached");
        require(tokenPrice <= msg.value, "Not enough funds");
        tokenIdCounter += 1;
        chosenTraits[tokenIdCounter] = traits;
        randomMetadata(tokenIdCounter);
        _mint(_msgSender(), tokenIdCounter);
    }

    function ownersMint(uint16[] calldata traits, address _address) external onlyOwner {
        require(tokenIdCounter < maxSupply, "Total supply reached");
        tokenIdCounter += 1;
        chosenTraits[tokenIdCounter] = traits;
        randomMetadata(tokenIdCounter);
        _mint(_address, tokenIdCounter);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        string memory encodedMetadata = '';

        for (uint i; i < traitIndexes[tokenId].length;) {
            encodedMetadata = string(abi.encodePacked(
                encodedMetadata,
                '{"trait_type":"',
                randomTraits[uint8(traitIndexes[tokenId][i]>>8)],
                '", "value":"',
                randomValues[uint8(traitIndexes[tokenId][i]>>8)][uint8(traitIndexes[tokenId][i])],
                '"}',
                i == traitIndexes[tokenId].length ? '' : ',')
            );
            unchecked { ++i; }
        }

        for (uint i; i < choosableTraits.length;) {
            encodedMetadata = string(abi.encodePacked(
                encodedMetadata,
                '{"trait_type":"',
                choosableTraits[i],
                '", "value":"',
                choosableValues[i][chosenTraits[tokenId][i]],
                '"}',
                i == choosableTraits.length - 1 ? '' : ',')
            );
            unchecked { ++i; }
        }

        if (hasDynamicTrait[tokenId]) {
            encodedMetadata = string(abi.encodePacked(
                encodedMetadata,
                ',{"trait_type":"',
                "Dynamic Monthly Trait",
                '", "value":"',
                randomTraits[dynamicTraits[tokenId]],
                '"}')
            );
        }

        encodedMetadata = string(abi.encodePacked(
            encodedMetadata,
            ',{"trait_type":"',
            "Founders Art",
            '", "value":"',
            Strings.toString(foundersArts[tokenId]),
            '"}')
        );

        string memory encodedUris = string(abi.encodePacked(
            '", "nft_url": "',
            nftUrl,
            Strings.toString(tokenId),
            '", "image": "',
            imageUrl,
            '", "animation_url": "',
            animationUrl)
        );

        string memory encoded = string(
            abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(
                bytes(
                abi.encodePacked(
                    '{"name":"',
                    nftName,
                    ' #',
                    Strings.toString(tokenId),
                    encodedUris,
                    '", "attributes": [',
                    encodedMetadata,
                    '] }'
                )
                )
            )
            )
        );

        return encoded;
    }

    function withdraw() public onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }
}