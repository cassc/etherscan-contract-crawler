// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../inactive_contracts/lib/ERC721r.sol";
import "solady/src/utils/DynamicBufferLib.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "solady/src/utils/Base64.sol";
import "solady/src/utils/SSTORE2.sol";
import "./utils/DynamicBuffer.sol";


import "hardhat/console.sol";

interface PunkDataInterface {
    function punkImage(uint16 index) external view returns (bytes memory);
}

interface ExtendedPunkDataInterface {
    enum PunkAttributeType {SEX, HAIR, EYES, BEARD, EARS, LIPS, MOUTH,
                                FACE, EMOTION, NECK, NOSE, CHEEKS, TEETH}
    
    enum PunkAttributeValue {NONE, ALIEN, APE, BANDANA, BEANIE, BIG_BEARD, BIG_SHADES, BLACK_LIPSTICK, BLONDE_BOB, BLONDE_SHORT, BLUE_EYE_SHADOW, BUCK_TEETH, CAP, CAP_FORWARD, CHINSTRAP, CHOKER, CIGARETTE, CLASSIC_SHADES, CLOWN_EYES_BLUE, CLOWN_EYES_GREEN, CLOWN_HAIR_GREEN, CLOWN_NOSE, COWBOY_HAT, CRAZY_HAIR, DARK_HAIR, DO_RAG, EARRING, EYE_MASK, EYE_PATCH, FEDORA, FEMALE, FRONT_BEARD, FRONT_BEARD_DARK, FROWN, FRUMPY_HAIR, GOAT, GOLD_CHAIN, GREEN_EYE_SHADOW, HALF_SHAVED, HANDLEBARS, HEADBAND, HOODIE, HORNED_RIM_GLASSES, HOT_LIPSTICK, KNITTED_CAP, LUXURIOUS_BEARD, MALE, MEDICAL_MASK, MESSY_HAIR, MOHAWK, MOHAWK_DARK, MOHAWK_THIN, MOLE, MUSTACHE, MUTTONCHOPS, NERD_GLASSES, NORMAL_BEARD, NORMAL_BEARD_BLACK, ORANGE_SIDE, PEAK_SPIKE, PIGTAILS, PILOT_HELMET, PINK_WITH_HAT, PIPE, POLICE_CAP, PURPLE_EYE_SHADOW, PURPLE_HAIR, PURPLE_LIPSTICK, RED_MOHAWK, REGULAR_SHADES, ROSY_CHEEKS, SHADOW_BEARD, SHAVED_HEAD, SILVER_CHAIN, SMALL_SHADES, SMILE, SPOTS, STRAIGHT_HAIR, STRAIGHT_HAIR_BLONDE, STRAIGHT_HAIR_DARK, STRINGY_HAIR, TASSLE_HAT, THREE_D_GLASSES, TIARA, TOP_HAT, VAMPIRE_HAIR, VAPE, VR, WELDING_GOGGLES, WILD_BLONDE, WILD_HAIR, WILD_WHITE_HAIR, ZOMBIE}
    
    function attrStringToEnumMapping(string memory) external view returns (ExtendedPunkDataInterface.PunkAttributeValue);
    function attrEnumToStringMapping(PunkAttributeValue) external view returns (string memory);
    function attrValueToTypeEnumMapping(PunkAttributeValue) external view returns (ExtendedPunkDataInterface.PunkAttributeType);
}

contract DefaultPunks is Ownable, ERC721r {
    using LibString for *;
    using SafeTransferLib for *;
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;
    using DynamicBuffer for bytes;
    
    enum PunkAttributeType {SEX, HAIR, EYES, BEARD, EARS, LIPS, MOUTH,
                                FACE, EMOTION, NECK, NOSE, CHEEKS, TEETH}
    
    enum PunkAttributeValue {NONE, ALIEN, APE, BANDANA, BEANIE, BIG_BEARD, BIG_SHADES, BLACK_LIPSTICK, BLONDE_BOB, BLONDE_SHORT, BLUE_EYE_SHADOW, BUCK_TEETH, CAP, CAP_FORWARD, CHINSTRAP, CHOKER, CIGARETTE, CLASSIC_SHADES, CLOWN_EYES_BLUE, CLOWN_EYES_GREEN, CLOWN_HAIR_GREEN, CLOWN_NOSE, COWBOY_HAT, CRAZY_HAIR, DARK_HAIR, DO_RAG, EARRING, EYE_MASK, EYE_PATCH, FEDORA, FEMALE, FRONT_BEARD, FRONT_BEARD_DARK, FROWN, FRUMPY_HAIR, GOAT, GOLD_CHAIN, GREEN_EYE_SHADOW, HALF_SHAVED, HANDLEBARS, HEADBAND, HOODIE, HORNED_RIM_GLASSES, HOT_LIPSTICK, KNITTED_CAP, LUXURIOUS_BEARD, MALE, MEDICAL_MASK, MESSY_HAIR, MOHAWK, MOHAWK_DARK, MOHAWK_THIN, MOLE, MUSTACHE, MUTTONCHOPS, NERD_GLASSES, NORMAL_BEARD, NORMAL_BEARD_BLACK, ORANGE_SIDE, PEAK_SPIKE, PIGTAILS, PILOT_HELMET, PINK_WITH_HAT, PIPE, POLICE_CAP, PURPLE_EYE_SHADOW, PURPLE_HAIR, PURPLE_LIPSTICK, RED_MOHAWK, REGULAR_SHADES, ROSY_CHEEKS, SHADOW_BEARD, SHAVED_HEAD, SILVER_CHAIN, SMALL_SHADES, SMILE, SPOTS, STRAIGHT_HAIR, STRAIGHT_HAIR_BLONDE, STRAIGHT_HAIR_DARK, STRINGY_HAIR, TASSLE_HAT, THREE_D_GLASSES, TIARA, TOP_HAT, VAMPIRE_HAIR, VAPE, VR, WELDING_GOGGLES, WILD_BLONDE, WILD_HAIR, WILD_WHITE_HAIR, ZOMBIE}
    
    struct DefaultPunk {
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
    
    struct ContractConfig {
        bool isMintActive;
        bool contractSealed;
        string name;
        string nameSingular;
        string symbol;
        string externalLink;
        string tokenDescription;
        string baseImageUri;
        uint costPerToken;
        uint64 maxSupply;
    }
    
    ContractConfig public config;
    
    PunkDataInterface public immutable punkDataContract;
    ExtendedPunkDataInterface public immutable extendedPunkDataContract;
    
    function name() public view virtual override returns (string memory) {
        return config.name;
    }

    function symbol() public view virtual override returns (string memory) {
        return config.symbol;
    }
    
    function setContractConfig(ContractConfig calldata _config) external onlyOwner unsealed {
        config = _config;
    }
    
    uint16[954] private defaultPunks;
    
    function setDefaultPunks(uint16[954] calldata _defaultPunks) external onlyOwner unsealed {
        defaultPunks = _defaultPunks;
    }
    
    uint16[954] private defaultPunkCounts;
    
    function setDefaultPunkCounts(uint16[954] calldata _defaultPunkCounts) external onlyOwner unsealed {
        defaultPunkCounts = _defaultPunkCounts;
    }
    
    address private defaultPunkAttributesBytes;
    
    function setDefaultPunkAttributesBytes(bytes calldata _defaultPunkAttributesBytes) external onlyOwner unsealed {
        defaultPunkAttributesBytes = SSTORE2.write(_defaultPunkAttributesBytes);
    }
    
    function defaultAttributesForPunkId(uint16 punkId) public view returns (PunkAttributeValue[] memory) {
        bytes memory arrayAsBytes = SSTORE2.read(defaultPunkAttributesBytes);
        uint maxNumberAttributes = 7;
        uint bytesPerAttribute = 1;
        
        uint startingByteIndex = punkId * maxNumberAttributes * bytesPerAttribute;
        
        PunkAttributeValue[] memory attributes = new PunkAttributeValue[](maxNumberAttributes);
        
        for (uint i; i < maxNumberAttributes; ++i) {
            uint8 attributeValue = uint8(arrayAsBytes[startingByteIndex + i]);
            
            attributes[i] = PunkAttributeValue(attributeValue);
        }
        
        return attributes;
    }
    
    modifier unsealed() {
        require(!config.contractSealed, "Contract sealed.");
        _;
    }
    
    function setTokenDescription(string calldata _tokenDescription) external onlyOwner unsealed {
        config.tokenDescription = _tokenDescription;
    }
    
    function sealContract() external onlyOwner unsealed {
        config.contractSealed = true;
    }
    
    function flipMintState() external onlyOwner {
        config.isMintActive = !config.isMintActive;
    }
    
    constructor(address punkDataContractAddress, address extendedPunkDataContractAddress, ContractConfig memory _config)
        ERC721r("", "", _config.maxSupply) {
        config = _config;
        punkDataContract = PunkDataInterface(punkDataContractAddress);
        extendedPunkDataContract = ExtendedPunkDataInterface(extendedPunkDataContractAddress);
    }
    
    function _internalMint(address toAddress, uint numTokens) private {
        require(msg.value == totalMintCost(numTokens), "Need exact payment");
        require(config.isMintActive, "Mint is not active");
        
        _mintRandom(toAddress, numTokens);
    }
    
    function airdrop(address toAddress, uint numTokens) external payable {
        _internalMint(toAddress, numTokens);
    }
    
    function mintPublic(uint numTokens) external payable {
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
        bytes memory title = abi.encodePacked(config.nameSingular, " #", tokenId.toString());
        string memory html = tokenHTMLPage(tokenId);
        string memory b64Html = Base64.encode(bytes(html));

        bytes memory imageUri = abi.encodePacked(config.baseImageUri, tokenId.toString(), ".png");

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', title, '",'
                                '"description":"', config.tokenDescription.escapeJSON(), '",'
                                '"image":"', imageUri,'",'
                                '"external_url":"', config.externalLink, '",'
                                '"html":"data:text/html;charset=utf-8;base64,', b64Html, '",'
                                '"attributes": ',
                                    punkAttributesAsJSON(tokenId),
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    
    function tokenImage(uint16 tokenId) public view returns (string memory) {
        uint16 punkId = defaultPunks[tokenId];
        bytes memory pixels = punkDataContract.punkImage(punkId);
        DynamicBufferLib.DynamicBuffer memory svgBytes;
        
        svgBytes.append('<svg width="1200" height="1200" shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24"><style>rect{width:1px;height:1px}</style>');
        
        svgBytes.append('<g><rect x="0" y="0" style="width:100%;height:100%" fill="#d6dde4" />');
        
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
                    
                    string memory oldColor = string(buffer);
                    string memory newColor;
                    
                    if (oldColor.endsWith("00")) {
                        newColor = "d6dde4";
                    } else {
                        newColor = "788a97";
                    }
                    
                    svgBytes.append(
                        abi.encodePacked(
                            '<rect x="',
                            x.toString(),
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
        
        svgBytes.append('</g>');
        svgBytes.append('</svg>');
        return string(svgBytes.data);
    }
    
    function tokenHTMLPage(uint16 tokenId) public view returns (string memory) {
        bytes memory HTMLBytes = DynamicBuffer.allocate(1024 * 128);
    
        string memory image = tokenImage(tokenId);
        
        HTMLBytes.appendSafe('<!DOCTYPE html><html lang="en">');
        HTMLBytes.appendSafe(abi.encodePacked('<body><style>*{box-sizing:border-box;margin:0;padding:0;border:0;transform-origin: center} svg{background:#638596;left: 50%;top: 50%;transform: translate(-50%, -50%);position: fixed;aspect-ratio: 1 / 1;max-width: 100vmin;max-height: 100vmin;width: 100%; height: 100%;}</style>'));
        
        HTMLBytes.appendSafe(bytes(image));
        
        HTMLBytes.appendSafe('</body></html>');

        return string(HTMLBytes);
    }
    
    address constant pivAddress = 0xf98537696e2Cf486F8F32604B2Ca2CDa120DBBa8;
    address constant middleAddress = 0xC2172a6315c1D7f6855768F843c420EbB36eDa97;
    
    function withdraw() external {
        require(address(this).balance > 0, "Nothing to withdraw");
        
        uint total = address(this).balance;
        uint half = total / 2;
        
        Address.sendValue(payable(middleAddress), half);
        Address.sendValue(payable(pivAddress), total - half);
    }
    
    function totalMintCost(uint numTokens) public view returns (uint) {
        return numTokens * config.costPerToken;
    }
    
    function initializePunkWithPunkAttributeValueArray(uint16 tokenId) private view returns (DefaultPunk memory) {
        PunkAttributeValue[] memory punkAttributes = defaultAttributesForPunkId(tokenId);
        DefaultPunk memory punk = DefaultPunk({
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
        
        for (uint i = 0; i < punkAttributes.length; i++) {
            PunkAttributeValue attrValue = punkAttributes[i];
            PunkAttributeType attrType = PunkAttributeType(uint(extendedPunkDataContract.attrValueToTypeEnumMapping(ExtendedPunkDataInterface.PunkAttributeValue(uint(attrValue)))));
            
            if (attrValue == PunkAttributeValue.NONE) {
                continue;
            }
            
            if (attrType == PunkAttributeType.SEX) {
                punk.sex = attrValue;
            } else if (attrType == PunkAttributeType.HAIR) {
                punk.hair = attrValue;
            } else if (attrType == PunkAttributeType.EYES) {
                punk.eyes = attrValue;
            } else if (attrType == PunkAttributeType.BEARD) {
                punk.beard = attrValue;
            } else if (attrType == PunkAttributeType.EARS) {
                punk.ears = attrValue;
            } else if (attrType == PunkAttributeType.LIPS) {
                punk.lips = attrValue;
            } else if (attrType == PunkAttributeType.MOUTH) {
                punk.mouth = attrValue;
            } else if (attrType == PunkAttributeType.FACE) {
                punk.face = attrValue;
            } else if (attrType == PunkAttributeType.EMOTION) {
                punk.emotion = attrValue;
            } else if (attrType == PunkAttributeType.NECK) {
                punk.neck = attrValue;
            } else if (attrType == PunkAttributeType.NOSE) {
                punk.nose = attrValue;
            } else if (attrType == PunkAttributeType.CHEEKS) {
                punk.cheeks = attrValue;
            } else if (attrType == PunkAttributeType.TEETH) {
                punk.teeth = attrValue;
            }
        }
        
        return punk;
    }
    
    function punkAttributeCount(DefaultPunk memory phunk) internal pure returns (uint totalCount) {
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
            }
        }
    }
    
    function punkAttributesAsJSON(uint16 tokenId) public view returns (string memory json) {
        DefaultPunk memory phunk = initializePunkWithPunkAttributeValueArray(tokenId);
        
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
        
        uint attrCount = punkAttributeCount(phunk);
        uint attrsCounted;
        
        outputBytes.appendSafe(abi.encodePacked(
            '{"trait_type":"CryptoPunks With Matching Silhouette", "display_type": "number", "max_value": 496, "value":', defaultPunkCounts[tokenId].toString(), '},'
        ));
        
        if (defaultPunkCounts[tokenId] == 1) {
            outputBytes.appendSafe(abi.encodePacked(
                '{"trait_type":"Unique Silhouette", "value": "Yes"},'
            ));
        }
        
        for (uint i; i < 13; ++i) {
            PunkAttributeValue attrVal = attrArray[i];
            
            if (attrVal != none) {
                attrsCounted++;
                outputBytes.appendSafe(bytes(punkAttributeAsJSON(attrVal)));
                
                if (attrsCounted < attrCount) {
                    outputBytes.appendSafe(",");
                }
            }
        }
        
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
    
    function walletOfOwner(address _owner)
        external
        view
        returns (uint16[] memory)
    {
        uint ownerTokenCount = balanceOf(_owner);
        uint16[] memory ownedTokenIds = new uint16[](ownerTokenCount);
        uint currentTokenId = 0;
        uint ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId < maxSupply()) {
            address currentTokenOwner = _exists(currentTokenId) ? ownerOf(currentTokenId) : address(0);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = uint16(currentTokenId);

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }
}