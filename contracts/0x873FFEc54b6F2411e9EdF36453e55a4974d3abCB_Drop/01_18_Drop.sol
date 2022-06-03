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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import 'base64-sol/base64.sol';
import "hardhat/console.sol";

contract Drop is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    struct Metadata {
        string[] choosableTraits;
        string[][] choosableValues;
        string[] randomTraits;
        string[][] randomValues;
        uint16[] traitsChance;
        uint16[] dynamicChance;
        uint16[][] valuesChance;
    }

    struct TraitIndex {
        uint16 traitIndex;
        uint16 valueIndex;
    }

    address deployer;
    uint tokenIdCounter = 0;
    uint metadataRandomizedCounter = 0;
    uint tokenPrice;
    uint maxSupply;
    string nftName;
    Metadata metadata;
    mapping (uint => uint[]) chosenTraits;
    mapping (uint => TraitIndex[]) traitIndexes;
    mapping (uint => uint) foundersArts;
    mapping (uint => string) dynamicTraits;
    mapping (address => bool) whitelist;
    bool whitelistEnabled;
    uint randomWord;
    bytes32 merkleRoot;
    mapping (uint => string) nftUris;
    mapping (uint => string) imageUris;
    mapping (uint => string) imageOriginalUris;
    mapping (uint => string) animationUris;
    mapping (uint => string) animationOriginalUris;



    constructor(
        string memory _name,
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
        deployer = msg.sender;
        maxSupply = _maxSupply;
        tokenPrice = _tokenPrice;
        nftName = _name;
        whitelistEnabled = true;
        randomWord = uint(keccak256(
            abi.encodePacked(block.difficulty, block.timestamp, uint(blockhash(block.number-1)), uint(blockhash(block.number-2)))
        ));

        uint16[][] memory valueChances = new uint16[][](chances[2].length);
        for (uint i = 0; i < chances[2].length; i++) {
            uint16 propertySum = 0;
            uint16[] memory propertyChances = new uint16[](chances[2][i].length);
            for (uint j = 0; j < chances[2][i].length; j++) {
                propertySum += chances[2][i][j];
                propertyChances[j] = propertySum;
            }
            valueChances[i] = propertyChances;
        }

        metadata = Metadata({
            choosableTraits: traits[0][0],
            choosableValues: traits[1],
            randomTraits: traits[2][0],
            randomValues: traits[3],
            traitsChance: chances[0][0],
            dynamicChance: chances[1][0],
            valuesChance: valueChances
        });
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function verifyUserInWhitelist(address _address, bytes32[] calldata _merkleProof) public view returns (bool) {
        if (whitelistEnabled) {
            bytes32 leaf = keccak256(abi.encodePacked(_address));
            return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
        } else {
            return true;
        }
    }

    function setWhitelistRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function disableWhitelist() public onlyOwner {
        whitelistEnabled = false;
    }

    function enableWhitelist() public onlyOwner {
        whitelistEnabled = true;
    }

    function setTokenPrice(uint _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function getTokenPrice() public view returns(uint) {
        return tokenPrice;
    }

    function setMaxSupply(uint _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function getMaxSupply() public view returns(uint) {
        return maxSupply;
    }

    function getMetadataRandomizedCounter() public view returns(uint) {
        return metadataRandomizedCounter;
    }

    function randomMetadata(uint tokenId) private {
        foundersArts[tokenId-1] = randomWord % 10;
        for (uint i = 0; i < metadata.traitsChance.length; i++) {
            if (uint(keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, randomWord, i, uint(blockhash(block.number-1))
                ))) % 10000 < metadata.traitsChance[i]) {
                uint randomNumber = uint(keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, randomWord, i, uint(blockhash(block.number-1))
                ))) % metadata.valuesChance[i][metadata.valuesChance[i].length - 1];
                for (uint j = 0; j < metadata.valuesChance[i].length; j++) {
                    if (randomNumber <= metadata.valuesChance[i][j]) {
                        if (j == 0 || randomNumber > metadata.valuesChance[i][j - 1]) {
                            traitIndexes[tokenId].push(TraitIndex(uint16(i), uint16(j)));
                            break;
                        }
                    }
                }
            }
        }
    }

    function randomMonthlyTrait(uint tokenId) private {
        for (uint i = 0; i < metadata.dynamicChance.length; i++) {
            if (uint(keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, randomWord, tokenId, i
                ))) % 10000 < metadata.dynamicChance[i]) {
                dynamicTraits[tokenId] = metadata.randomTraits[i];
                break;
            }
        }
    }

    function randomzieMontlyTraits(uint start, uint end) public onlyOwner {
        for (uint i = start; i < end; i++) {
        randomWord = uint(keccak256(
            abi.encodePacked(block.difficulty, block.timestamp, randomWord, uint(blockhash(block.number-1))
        )));
            randomMonthlyTrait(i);
        }
        metadataRandomizedCounter++;
    }

    function mint(uint16[] calldata traits, bytes32[] calldata _merkleProof, string[] calldata uris) public payable nonReentrant {
        require(tokenIdCounter < maxSupply, "Total supply reached");
        require(verifyUserInWhitelist(msg.sender, _merkleProof), "User not in whitelist");
        require(uris.length == 5, "Please provide 5 uris");
        tokenIdCounter += 1;
        nftUris[tokenIdCounter] = uris[0];
        imageUris[tokenIdCounter] = uris[1];
        imageOriginalUris[tokenIdCounter] = uris[2];
        animationUris[tokenIdCounter] = uris[3];
        animationOriginalUris[tokenIdCounter] = uris[4];
        

        chosenTraits[tokenIdCounter] = traits;
        randomWord = uint(keccak256(
            abi.encodePacked(block.difficulty, block.timestamp, randomWord, uint(blockhash(block.number-1))
        )));
        randomMetadata(tokenIdCounter);
        _mint(_msgSender(), tokenIdCounter);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        string memory encodedMetadata = '';

        for (uint i = 0; i < traitIndexes[tokenId].length; i++) {
            encodedMetadata = string(abi.encodePacked(
                encodedMetadata,
                '{"trait_type":"',
                metadata.randomTraits[traitIndexes[tokenId][i].traitIndex],
                '", "value":"',
                metadata.randomValues[traitIndexes[tokenId][i].traitIndex][traitIndexes[tokenId][i].valueIndex],
                '"}',
                i == traitIndexes[tokenId].length ? '' : ',')
            );
        }

        for (uint i = 0; i < metadata.choosableTraits.length; i++) {
            encodedMetadata = string(abi.encodePacked(
                encodedMetadata,
                '{"trait_type":"',
                metadata.choosableTraits[i],
                '", "value":"',
                metadata.choosableValues[i][chosenTraits[tokenId][i]],
                '"}',
                i == metadata.choosableTraits.length - 1 ? '' : ',')
            );
        }

        if (keccak256(abi.encodePacked((dynamicTraits[tokenId - 1]))) != keccak256(abi.encodePacked(("")))) {
            encodedMetadata = string(abi.encodePacked(
                encodedMetadata,
                ',{"trait_type":"',
                "Dynamic Monthly Trait",
                '", "value":"',
                dynamicTraits[tokenId - 1],
                '"}')
            );
        }

        encodedMetadata = string(abi.encodePacked(
            encodedMetadata,
            ',{"trait_type":"',
            "Founders Art",
            '", "value":"',
            Strings.toString(foundersArts[tokenId-1]),
            '"}')
        );

        string memory encodedUris = string(abi.encodePacked(
            '", "nft_url": "',
            nftUris[tokenId],
            Strings.toString(tokenId),
            '", "image": "',
            imageUris[tokenId],
            '", "image_origional_url": "',
            imageOriginalUris[tokenId],
            '", "animation_url": "',
            animationUris[tokenId],
            '", "animation_origional_url": "',
            animationOriginalUris[tokenId])
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

    function withdraw(address _to, uint amount) public onlyOwner {
        payable(_to).call{value:amount, gas:200000}("");
    }
}