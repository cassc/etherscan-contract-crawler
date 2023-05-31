// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "base64-sol/base64.sol";
import "erc721a/contracts/ERC721A.sol";

import "./sstore2/SSTORE2.sol";
import "./utils/DynamicBuffer.sol";

import "./StringUtilsLib.sol";

import "hardhat/console.sol";

interface PunkDataInterface {
    function punkImage(uint16 index) external view returns (bytes memory);
    function punkAttributes(uint16 index) external view returns (string memory);
}

interface ExtendedPunkDataInterface {
    enum PunkAttributeType {SEX, HAIR, EYES, BEARD, EARS, LIPS, MOUTH,
                                FACE, EMOTION, NECK, NOSE, CHEEKS, TEETH}
    
    enum PunkAttributeValue {NONE, ALIEN, APE, BANDANA, BEANIE, BIG_BEARD, BIG_SHADES, BLACK_LIPSTICK, BLONDE_BOB, BLONDE_SHORT, BLUE_EYE_SHADOW, BUCK_TEETH, CAP, CAP_FORWARD, CHINSTRAP, CHOKER, CIGARETTE, CLASSIC_SHADES, CLOWN_EYES_BLUE, CLOWN_EYES_GREEN, CLOWN_HAIR_GREEN, CLOWN_NOSE, COWBOY_HAT, CRAZY_HAIR, DARK_HAIR, DO_RAG, EARRING, EYE_MASK, EYE_PATCH, FEDORA, FEMALE, FRONT_BEARD, FRONT_BEARD_DARK, FROWN, FRUMPY_HAIR, GOAT, GOLD_CHAIN, GREEN_EYE_SHADOW, HALF_SHAVED, HANDLEBARS, HEADBAND, HOODIE, HORNED_RIM_GLASSES, HOT_LIPSTICK, KNITTED_CAP, LUXURIOUS_BEARD, MALE, MEDICAL_MASK, MESSY_HAIR, MOHAWK, MOHAWK_DARK, MOHAWK_THIN, MOLE, MUSTACHE, MUTTONCHOPS, NERD_GLASSES, NORMAL_BEARD, NORMAL_BEARD_BLACK, ORANGE_SIDE, PEAK_SPIKE, PIGTAILS, PILOT_HELMET, PINK_WITH_HAT, PIPE, POLICE_CAP, PURPLE_EYE_SHADOW, PURPLE_HAIR, PURPLE_LIPSTICK, RED_MOHAWK, REGULAR_SHADES, ROSY_CHEEKS, SHADOW_BEARD, SHAVED_HEAD, SILVER_CHAIN, SMALL_SHADES, SMILE, SPOTS, STRAIGHT_HAIR, STRAIGHT_HAIR_BLONDE, STRAIGHT_HAIR_DARK, STRINGY_HAIR, TASSLE_HAT, THREE_D_GLASSES, TIARA, TOP_HAT, VAMPIRE_HAIR, VAPE, VR, WELDING_GOGGLES, WILD_BLONDE, WILD_HAIR, WILD_WHITE_HAIR, ZOMBIE}
    
    function attrStringToEnumMapping(string memory) external view returns (ExtendedPunkDataInterface.PunkAttributeValue);
    function attrEnumToStringMapping(PunkAttributeValue) external view returns (string memory);
    function attrValueToTypeEnumMapping(PunkAttributeValue) external view returns (ExtendedPunkDataInterface.PunkAttributeType);
}

contract CyberPhunks is Ownable, ERC721A {
    enum PunkAttributeType {SEX, HAIR, EYES, BEARD, EARS, LIPS, MOUTH,
                                FACE, EMOTION, NECK, NOSE, CHEEKS, TEETH}
    
    enum PunkAttributeValue {NONE, ALIEN, APE, BANDANA, BEANIE, BIG_BEARD, BIG_SHADES, BLACK_LIPSTICK, BLONDE_BOB, BLONDE_SHORT, BLUE_EYE_SHADOW, BUCK_TEETH, CAP, CAP_FORWARD, CHINSTRAP, CHOKER, CIGARETTE, CLASSIC_SHADES, CLOWN_EYES_BLUE, CLOWN_EYES_GREEN, CLOWN_HAIR_GREEN, CLOWN_NOSE, COWBOY_HAT, CRAZY_HAIR, DARK_HAIR, DO_RAG, EARRING, EYE_MASK, EYE_PATCH, FEDORA, FEMALE, FRONT_BEARD, FRONT_BEARD_DARK, FROWN, FRUMPY_HAIR, GOAT, GOLD_CHAIN, GREEN_EYE_SHADOW, HALF_SHAVED, HANDLEBARS, HEADBAND, HOODIE, HORNED_RIM_GLASSES, HOT_LIPSTICK, KNITTED_CAP, LUXURIOUS_BEARD, MALE, MEDICAL_MASK, MESSY_HAIR, MOHAWK, MOHAWK_DARK, MOHAWK_THIN, MOLE, MUSTACHE, MUTTONCHOPS, NERD_GLASSES, NORMAL_BEARD, NORMAL_BEARD_BLACK, ORANGE_SIDE, PEAK_SPIKE, PIGTAILS, PILOT_HELMET, PINK_WITH_HAT, PIPE, POLICE_CAP, PURPLE_EYE_SHADOW, PURPLE_HAIR, PURPLE_LIPSTICK, RED_MOHAWK, REGULAR_SHADES, ROSY_CHEEKS, SHADOW_BEARD, SHAVED_HEAD, SILVER_CHAIN, SMALL_SHADES, SMILE, SPOTS, STRAIGHT_HAIR, STRAIGHT_HAIR_BLONDE, STRAIGHT_HAIR_DARK, STRINGY_HAIR, TASSLE_HAT, THREE_D_GLASSES, TIARA, TOP_HAT, VAMPIRE_HAIR, VAPE, VR, WELDING_GOGGLES, WILD_BLONDE, WILD_HAIR, WILD_WHITE_HAIR, ZOMBIE}
    
    struct CyberPhunk {
        uint16 id;
        PunkAttributeValue sex;
        PunkAttributeValue hair;
        PunkAttributeValue eyes;
        PunkAttributeValue beard;
        PunkAttributeValue ears;
        PunkAttributeValue lips;
        PunkAttributeValue mouth;
        PunkAttributeValue face;
        PunkAttributeValue emotion;
        PunkAttributeValue neck;
        PunkAttributeValue nose;
        PunkAttributeValue cheeks;
        PunkAttributeValue teeth;
    }
    
    using StringUtils for string;
    using Address for address;
    using DynamicBuffer for bytes;
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;
    
    uint public constant costPerToken = 0.005 ether;
    
    uint public constant maxSupply = 10_000;
    
    uint public constant mintBatchSize = 30;
    
    bool public isMintActive;
    
    bytes public constant externalLink = "https://capsule21.com/collections/cyberphunks";
    
    bool public contractSealed;
    
    bytes constant tokenDescription = "One of 10,000 tokens in the CYBERPHUNK collection, an on-chain transformation of the original CryptoPunks.";
    
    PunkDataInterface public immutable punkDataContract;
    ExtendedPunkDataInterface public immutable extendedPunkDataContract;
    
    address private phunkRarities;
    
    mapping (string => string) public colorMapping;
    
    function setColorMapping(string[][] memory _colorMapping) public onlyOwner unsealed {
        for (uint i = 0; i < _colorMapping.length; i++) {
            colorMapping[_colorMapping[i][0]] = _colorMapping[i][1];
        }
    }
    
    mapping(PunkAttributeValue => bool) public attributeIsLit;
    
    function setColorIsLit(PunkAttributeValue[] memory litColors) public onlyOwner unsealed {
        for (uint i = 0; i < litColors.length; i++) {
            attributeIsLit[litColors[i]] = true;
        }
    }
    
    address public phunkColorCounts;
    
    function setPhunkColorCounts(bytes memory counts) public onlyOwner unsealed {
        phunkColorCounts = SSTORE2.write(counts);
    }
    
    function getPhunkColorCount(uint16 punkId) public view returns (uint8) {
        bytes memory allCounts = SSTORE2.read(phunkColorCounts);
        return (uint8(allCounts[punkId]) - 1); // Don't count background
    }
    
    address public phunkRarityRanks;
    
    function setPhunkRarityRanks(bytes memory ranks) public onlyOwner unsealed {
        phunkRarityRanks = SSTORE2.write(ranks);
    }
    
    function getPhunkRarityRank(uint16 punkId) public view returns (uint16) {
        bytes memory allRanks = SSTORE2.read(phunkRarityRanks);
        
        uint big = uint16(uint8(allRanks[punkId * 2]) * 2 ** 8);
        uint small = uint8(allRanks[punkId * 2 + 1]);
        
        return uint16(big + small + 1); // + 1 to account for 0th index
    }
    
    modifier unsealed() {
        require(!contractSealed, "Contract sealed.");
        _;
    }
    
    function sealContract() external onlyOwner unsealed {
        contractSealed = true;
    }
    
    function flipMintState() external onlyOwner {
        isMintActive = !isMintActive;
    }
    
    constructor(address punkDataContractAddress, address extendedPunkDataContractAddress)
        ERC721A("CyberPhunks", "CYBERPHUNK") {
        punkDataContract = PunkDataInterface(punkDataContractAddress);
        extendedPunkDataContract = ExtendedPunkDataInterface(extendedPunkDataContractAddress);
    }
    
    function _internalMint(address toAddress, uint numTokens) private {
        require(msg.value == totalMintCost(numTokens), "Need exact payment");
        require(msg.sender == tx.origin, "Contracts cannot mint");
        require(numTokens + totalSupply() <= maxSupply, "Supply limit reached.");
        require(isMintActive, "Mint is not active");
        require(numTokens > 0, "Mint at least one");
        
        uint batchCount = numTokens / mintBatchSize;
        uint remainder = numTokens % mintBatchSize;
        
        for (uint i; i < batchCount; i++) {
            _mint(toAddress, mintBatchSize);
        }
        
        if (remainder > 0) {
            _mint(toAddress, remainder);
        }
    }
    
    function airdrop(address toAddress, uint numTokens) external payable {
        _internalMint(toAddress, numTokens);
    }
    
    function mint(uint numTokens) external payable {
        _internalMint(msg.sender, numTokens);
    }
    
    function exists(uint tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
    
    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Token does not exist");

        return constructTokenURI(uint16(id));
    }
    
    function constructTokenURI(uint16 tokenId) private view returns (string memory) {
        bytes memory svg = bytes(tokenImage(tokenId));
        
        bytes memory title = abi.encodePacked("CyberPhunk #", tokenId.toString());
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', title, '",'
                                '"description":"', tokenDescription, '",'
                                '"image_data":"data:image/svg+xml;base64,', Base64.encode(svg), '",'
                                '"external_url":"', externalLink, '",'
                                '"attributes": ',
                                    punkAttributesAsJSON(tokenId),
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    function stringCompare(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
    
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    
    function tokenImage(uint16 tokenId) public view returns (string memory) {
        CyberPhunk memory phunk = initializePunk(tokenId);
        
        bytes memory pixels = punkDataContract.punkImage(uint16(tokenId));
        
        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
        
        svgBytes.appendSafe('<svg width="1200" height="1200" shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24"><style>rect{width:1px;height:1px}</style><rect x="0" y="0" style="width:100%;height:100%" fill="#3c2a3c" />');
        
        bytes memory buffer = new bytes(8);
        for (uint256 y = 0; y < 24; y++) {
            for (uint256 x = 0; x < 24; x++) {
                uint256 p = (y * 24 + x) * 4;
                if (uint8(pixels[p + 3]) > 0) {
                    for (uint256 i = 0; i < 4; i++) {
                        uint8 value = uint8(pixels[p + i]);
                        
                        buffer[i * 2 + 1] = _HEX_SYMBOLS[value & 0xf];
                        value >>= 4;
                        buffer[i * 2] = _HEX_SYMBOLS[value & 0xf];
                    }
                    
                    uint flippedX = 23 - x;
                    
                    string memory oldColor = string(buffer);
                    string memory newColor;
                    
                    uint row = flippedX;
                    uint col = y;
                    
                    if (
                            ((row == 8 && col == 12) || (row == 13 && col == 12)) &&
                            stringCompare(oldColor, "9be0e0ff")
                        ) {
                        newColor = "9be0e0ff";
                    } else if (
                        ((row == 10 && col == 18) || (row == 12 && col == 18)) &&
                        stringCompare(oldColor, "dacdbbff")
                        ) {
                        newColor = "ffffffff";
                    } else if (
                        ((row == 14 && col == 7) || (row == 15 && col == 8) || (row == 14 && col == 9)) &&
                        changeWhite(phunk) &&
                        stringCompare(oldColor, "ffffffff")
                    ) {
                        newColor = "664259ff";
                    } else {
                        newColor = colorMapping[oldColor];
                    }
                    
                    svgBytes.appendSafe(
                        abi.encodePacked(
                            '<rect x="',
                            flippedX.toString(),
                            '" y="',
                            y.toString(),
                            '" fill="#',
                            newColor,
                            '"/>'
                        )
                    );
                }
            }
        }
        
        svgBytes.appendSafe('</svg>');
        return string(svgBytes);
    }
    
    address constant doveAddress = 0x5FD2E3ba05C862E62a34B9F63c45C0DF622Ac112;
    address constant middleAddress = 0xC2172a6315c1D7f6855768F843c420EbB36eDa97;
    
    function withdraw() external {
        require(address(this).balance > 0, "Nothing to withdraw");
        
        uint total = address(this).balance;
        uint half = total / 2;
        
        Address.sendValue(payable(middleAddress), half);
        Address.sendValue(payable(doveAddress), total - half);
    }
    
    function creators() public pure returns (address[2] memory) {
        return [doveAddress, middleAddress];
    }
    
    function totalMintCost(uint numTokens) public pure returns (uint) {
        return numTokens * costPerToken;
    }
    
    function changeWhite(CyberPhunk memory phunk) public pure returns (bool) {
        if (phunk.hair != PunkAttributeValue.WILD_WHITE_HAIR &&
            phunk.hair != PunkAttributeValue.HEADBAND &&
            phunk.hair != PunkAttributeValue.POLICE_CAP) {
                return true;
            }
            
        return false;
    }
    
    function walletOfOwner(address _owner)
        external
        view
        returns (uint[] memory)
    {
        uint ownerTokenCount = balanceOf(_owner);
        uint[] memory ownedTokenIds = new uint[](ownerTokenCount);
        uint currentTokenId = 0;
        uint ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId < maxSupply) {
            address currentTokenOwner = _exists(currentTokenId) ? ownerOf(currentTokenId) : address(0);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }
    
    function initializePunk(uint16 punkId) private view returns (CyberPhunk memory) {
        CyberPhunk memory phunk = CyberPhunk({
            id: punkId,
            sex: PunkAttributeValue.NONE,
            hair: PunkAttributeValue.NONE,
            eyes: PunkAttributeValue.NONE,
            beard: PunkAttributeValue.NONE,
            ears: PunkAttributeValue.NONE,
            lips: PunkAttributeValue.NONE,
            mouth: PunkAttributeValue.NONE,
            face: PunkAttributeValue.NONE,
            emotion: PunkAttributeValue.NONE,
            neck: PunkAttributeValue.NONE,
            nose: PunkAttributeValue.NONE,
            cheeks: PunkAttributeValue.NONE,
            teeth: PunkAttributeValue.NONE
        });
        
        phunk.id = punkId;
        
        string memory attributes = punkDataContract.punkAttributes(phunk.id);

        string[] memory attributeArray = attributes.split(",");
        
        for (uint i = 0; i < attributeArray.length; i++) {
            string memory untrimmedAttribute = attributeArray[i];
            string memory trimmedAttribute;
            
            if (i < 1) {
                trimmedAttribute = untrimmedAttribute.split(' ')[0];
            } else {
                trimmedAttribute = untrimmedAttribute._substring(int(bytes(untrimmedAttribute).length - 1), 1);
            }
            
            PunkAttributeValue attrValue = PunkAttributeValue(uint(extendedPunkDataContract.attrStringToEnumMapping(trimmedAttribute)));
            PunkAttributeType attrType = PunkAttributeType(uint(extendedPunkDataContract.attrValueToTypeEnumMapping(ExtendedPunkDataInterface.PunkAttributeValue(uint(attrValue)))));
            
            if (attrType == PunkAttributeType.SEX) {
                phunk.sex = attrValue;
            } else if (attrType == PunkAttributeType.HAIR) {
                phunk.hair = attrValue;
            } else if (attrType == PunkAttributeType.EYES) {
                phunk.eyes = attrValue;
            } else if (attrType == PunkAttributeType.BEARD) {
                phunk.beard = attrValue;
            } else if (attrType == PunkAttributeType.EARS) {
                phunk.ears = attrValue;
            } else if (attrType == PunkAttributeType.LIPS) {
                phunk.lips = attrValue;
            } else if (attrType == PunkAttributeType.MOUTH) {
                phunk.mouth = attrValue;
            } else if (attrType == PunkAttributeType.FACE) {
                phunk.face = attrValue;
            } else if (attrType == PunkAttributeType.EMOTION) {
                phunk.emotion = attrValue;
            } else if (attrType == PunkAttributeType.NECK) {
                phunk.neck = attrValue;
            } else if (attrType == PunkAttributeType.NOSE) {
                phunk.nose = attrValue;
            } else if (attrType == PunkAttributeType.CHEEKS) {
                phunk.cheeks = attrValue;
            } else if (attrType == PunkAttributeType.TEETH) {
                phunk.teeth = attrValue;
            }
        }
        
        return phunk;
    }
    
    function punkAttributeCount(CyberPhunk memory phunk) public view returns (uint totalCount, uint litCount) {
        PunkAttributeValue[13] memory attrArray = [
            phunk.sex,
            phunk.hair,
            phunk.eyes,
            phunk.beard,
            phunk.ears,
            phunk.lips,
            phunk.mouth,
            phunk.face,
            phunk.emotion,
            phunk.neck,
            phunk.nose,
            phunk.cheeks,
            phunk.teeth
        ];
        
        for (uint i = 0; i < 13; ++i) {
            if (attrArray[i] != PunkAttributeValue.NONE) {
                totalCount++;
                
                if (attributeIsLit[attrArray[i]]) {
                    litCount++;
                }
            }
        }
        
        // Don't count sex as an attribute
        totalCount--;
    }
    
    function punkAttributesAsJSON(uint16 punkId) public view returns (string memory json) {
        CyberPhunk memory phunk = initializePunk(punkId);
        
        PunkAttributeValue none = PunkAttributeValue.NONE;
        
        bytes memory outputBytes = DynamicBuffer.allocate(1024 * 64);
        outputBytes.appendSafe("[");
        
        PunkAttributeValue[13] memory attrArray = [
            phunk.sex,
            phunk.hair,
            phunk.eyes,
            phunk.beard,
            phunk.ears,
            phunk.lips,
            phunk.mouth,
            phunk.face,
            phunk.emotion,
            phunk.neck,
            phunk.nose,
            phunk.cheeks,
            phunk.teeth
        ];
        
        (uint attrCount, uint litAttrCount) = punkAttributeCount(phunk);
        
        for (uint i = 0; i < 13; ++i) {
            PunkAttributeValue attrVal = attrArray[i];
            
            if (attrVal != none) {
                outputBytes.appendSafe(bytes(punkAttributeAsJSON(attrVal)));
                
                outputBytes.appendSafe(",");
            }
        }
        
        outputBytes.appendSafe(abi.encodePacked(
            '{"trait_type":"Color Count", "display_type": "number", "max_value": 14, "value":', getPhunkColorCount(phunk.id).toString(), '},'
        ));
        
        outputBytes.appendSafe(abi.encodePacked(
            '{"trait_type":"Trait Count", "display_type": "number", "max_value": 7, "value":', attrCount.toString(), '},'
        ));
        
        outputBytes.appendSafe(abi.encodePacked(
            '{"trait_type":"Glowing Trait Count", "display_type": "number", "max_value": 5, "value":', litAttrCount.toString(), '},'
        ));
        
        outputBytes.appendSafe(abi.encodePacked(
            '{"trait_type":"Rarity Rank", "display_type": "number", "max_value": 10000, "value":', getPhunkRarityRank(phunk.id).toString(), '}'
        ));
        
        return string(abi.encodePacked(outputBytes, "]"));
    }
    
    function punkAttributeAsJSON(PunkAttributeValue attribute) internal view returns (string memory json) {
        require(attribute != PunkAttributeValue.NONE);
        
        string memory attributeAsString = extendedPunkDataContract.attrEnumToStringMapping(ExtendedPunkDataInterface.PunkAttributeValue(uint(attribute)));
        string memory attributeTypeAsString;
        
        PunkAttributeType attrType = PunkAttributeType(
            uint(
                extendedPunkDataContract.attrValueToTypeEnumMapping(
                    ExtendedPunkDataInterface.PunkAttributeValue(
                        uint(
                            attribute
                        )))));

        
        if (attrType == PunkAttributeType.SEX) {
            attributeTypeAsString = "Sex";
        } else if (attrType == PunkAttributeType.HAIR) {
            attributeTypeAsString = "Hair";
        } else if (attrType == PunkAttributeType.EYES) {
            attributeTypeAsString = "Eyes";
        } else if (attrType == PunkAttributeType.BEARD) {
            attributeTypeAsString = "Beard";
        } else if (attrType == PunkAttributeType.EARS) {
            attributeTypeAsString = "Ears";
        } else if (attrType == PunkAttributeType.LIPS) {
            attributeTypeAsString = "Lips";
        } else if (attrType == PunkAttributeType.MOUTH) {
            attributeTypeAsString = "Mouth";
        } else if (attrType == PunkAttributeType.FACE) {
            attributeTypeAsString = "Face";
        } else if (attrType == PunkAttributeType.EMOTION) {
            attributeTypeAsString = "Emotion";
        } else if (attrType == PunkAttributeType.NECK) {
            attributeTypeAsString = "Neck";
        } else if (attrType == PunkAttributeType.NOSE) {
            attributeTypeAsString = "Nose";
        } else if (attrType == PunkAttributeType.CHEEKS) {
            attributeTypeAsString = "Cheeks";
        } else if (attrType == PunkAttributeType.TEETH) {
            attributeTypeAsString = "Teeth";
        }
        
        return string(abi.encodePacked('{"trait_type":"', attributeTypeAsString, '", "value":"', attributeAsString, '"}'));
    }
}