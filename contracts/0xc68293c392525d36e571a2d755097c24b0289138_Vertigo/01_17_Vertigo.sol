// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "base64-sol/base64.sol";
import "./ERC721r.sol";
import "erc721a/contracts/ERC721A.sol";

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

contract Vertigo is Ownable, ERC721r {
    enum PunkAttributeType {SEX, HAIR, EYES, BEARD, EARS, LIPS, MOUTH,
                                FACE, EMOTION, NECK, NOSE, CHEEKS, TEETH}
    
    enum PunkAttributeValue {NONE, ALIEN, APE, BANDANA, BEANIE, BIG_BEARD, BIG_SHADES, BLACK_LIPSTICK, BLONDE_BOB, BLONDE_SHORT, BLUE_EYE_SHADOW, BUCK_TEETH, CAP, CAP_FORWARD, CHINSTRAP, CHOKER, CIGARETTE, CLASSIC_SHADES, CLOWN_EYES_BLUE, CLOWN_EYES_GREEN, CLOWN_HAIR_GREEN, CLOWN_NOSE, COWBOY_HAT, CRAZY_HAIR, DARK_HAIR, DO_RAG, EARRING, EYE_MASK, EYE_PATCH, FEDORA, FEMALE, FRONT_BEARD, FRONT_BEARD_DARK, FROWN, FRUMPY_HAIR, GOAT, GOLD_CHAIN, GREEN_EYE_SHADOW, HALF_SHAVED, HANDLEBARS, HEADBAND, HOODIE, HORNED_RIM_GLASSES, HOT_LIPSTICK, KNITTED_CAP, LUXURIOUS_BEARD, MALE, MEDICAL_MASK, MESSY_HAIR, MOHAWK, MOHAWK_DARK, MOHAWK_THIN, MOLE, MUSTACHE, MUTTONCHOPS, NERD_GLASSES, NORMAL_BEARD, NORMAL_BEARD_BLACK, ORANGE_SIDE, PEAK_SPIKE, PIGTAILS, PILOT_HELMET, PINK_WITH_HAT, PIPE, POLICE_CAP, PURPLE_EYE_SHADOW, PURPLE_HAIR, PURPLE_LIPSTICK, RED_MOHAWK, REGULAR_SHADES, ROSY_CHEEKS, SHADOW_BEARD, SHAVED_HEAD, SILVER_CHAIN, SMALL_SHADES, SMILE, SPOTS, STRAIGHT_HAIR, STRAIGHT_HAIR_BLONDE, STRAIGHT_HAIR_DARK, STRINGY_HAIR, TASSLE_HAT, THREE_D_GLASSES, TIARA, TOP_HAT, VAMPIRE_HAIR, VAPE, VR, WELDING_GOGGLES, WILD_BLONDE, WILD_HAIR, WILD_WHITE_HAIR, ZOMBIE}
    
    struct Punk {
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
    using Strings for *;
    
    struct ContractConfig {
        bool isMintActive;
        bool contractSealed;
        string name;
        string nameSingular;
        string symbol;
        string externalLink;
        string tokenDescriptionAsJSON;
        string baseImageUri;
        uint costPerToken;
        uint64 maxSupply;
    }
    
    ContractConfig public config;
    
    PunkDataInterface public immutable punkDataContract;
    ExtendedPunkDataInterface public immutable extendedPunkDataContract;
    
    modifier unsealed() {
        require(!config.contractSealed, "Contract sealed.");
        _;
    }
    
    function name() public view virtual override returns (string memory) {
        return config.name;
    }

    function symbol() public view virtual override returns (string memory) {
        return config.symbol;
    }
    
    function setContractConfig(ContractConfig calldata _config) external onlyOwner unsealed {
        config = _config;
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
                                '"description":', config.tokenDescriptionAsJSON, ','
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
    
    function punkRects(uint tokenId) public view returns (bytes memory) {
        bytes memory pixels = punkDataContract.punkImage(uint16(tokenId));
        
        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 24);
        
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
                    
                    bytes memory rectStart = abi.encodePacked(
                        '<rect x="',
                        x.toString(),
                        '" y="',
                        y.toString()
                    );
                    
                    svgBytes.appendSafe(
                        abi.encodePacked(
                            rectStart,
                            '" fill="#',
                            string(buffer),
                            '"/>'
                        )
                    );
                }
            }
        }
        
        return svgBytes;
    }
    
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    
    function tokenHTMLPage(uint tokenId) public view returns (string memory) {
        bytes memory HTMLBytes = DynamicBuffer.allocate(1024 * 128);
    
        string memory image = tokenImage(tokenId);
        
        HTMLBytes.appendSafe('<!DOCTYPE html><html lang="en">');
        HTMLBytes.appendSafe(abi.encodePacked('<body><style>*{box-sizing:border-box;margin:0;padding:0;border:0;transform-origin: center} svg{background:#638596;left: 50%;top: 50%;transform: translate(-50%, -50%);position: fixed;aspect-ratio: 1 / 1;max-width: 100vmin;max-height: 100vmin;width: 100%; height: 100%;}</style>'));
        
        HTMLBytes.appendSafe(bytes(image));
        
        HTMLBytes.appendSafe('<script>var svgEl=document.querySelector("svg"),rects=Array.from(document.querySelectorAll("#r rect")),svgBox=svgEl.getBoundingClientRect(),svgCenter=[svgBox.left+svgBox.width/2,svgBox.top+svgBox.height/2],distanceMemo={},distanceFromRectToSVGCenter=function(t){var e=t.getBoundingClientRect(),r=JSON.stringify(e);if(distanceMemo[r])return distanceMemo[r];var o=[e.left,e.top],s=[e.left,e.top+e.height],n=[e.left+e.height,e.top],a=[e.left+e.width,e.top+e.height],c=Math.max(...[o,s,n,a].map((t=>Math.sqrt(Math.pow(t[0]-svgCenter[0],2)+Math.pow(t[1]-svgCenter[1],2)))));return distanceMemo[r]=c,c},sorted=rects.sort(((t,e)=>distanceFromRectToSVGCenter(e)-distanceFromRectToSVGCenter(t))),farthest=sorted[0],farDistance=distanceFromRectToSVGCenter(sorted[0]),factor=svgBox.width/2/farDistance;document.querySelector("#a").style.transform="scale("+factor+")",svgEl.classList.add("init");</script></body></html>');

        return string(HTMLBytes);
    }
    
    function tokenImage(uint tokenId) public view returns (string memory) {
        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
        
        uint numRepetitions = 360;
        uint angleIncrements = 360 / numRepetitions;
        
        svgBytes.appendSafe(abi.encodePacked('<svg width="1200" height="1200" shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24"><style>rect{width:1px;height:1px}</style><defs><g opacity="0.05" id="r">'));
        
        svgBytes.appendSafe(punkRects(tokenId));
        svgBytes.appendSafe('</g></defs>');
        svgBytes.appendSafe('<circle cx="12" cy="12" r="1.025" fill="#000000"/><g id="a">');
        
        for (uint i = 0; i < numRepetitions; i++) {
            svgBytes.appendSafe(abi.encodePacked('<use href="#r" transform="rotate(', (angleIncrements * i).toString(), ')" />'));
        }
        
        svgBytes.appendSafe('</g></svg>');
        return string(svgBytes);
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
    
    function initializePunk(uint16 punkId) private view returns (Punk memory) {
        Punk memory phunk = Punk({
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
    
    function punkAttributeCount(Punk memory phunk) public pure returns (uint totalCount) {
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
    
    function punkAttributesAsJSON(uint16 punkId) public view returns (string memory json) {
        Punk memory phunk = initializePunk(punkId);
        
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

        while (ownedTokenIndex < ownerTokenCount && currentTokenId < config.maxSupply) {
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