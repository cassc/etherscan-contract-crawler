// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "solady/src/utils/Base64.sol";
import "erc721a/contracts/ERC721A.sol";

import "solady/src/utils/DynamicBufferLib.sol";

import "./StringUtilsLib.sol";

interface PunkDataInterface {
    function punkImage(uint16 index) external view returns (bytes memory);
    function punkAttributes(uint16 index) external view returns (string memory);
}

interface AsciiPunksRendererInterface {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function baguette() external view returns (string memory);
}

interface ExtendedPunkDataInterface {
    enum PunkAttributeType {SEX, HAIR, EYES, BEARD, EARS, LIPS, MOUTH,
                                FACE, EMOTION, NECK, NOSE, CHEEKS, TEETH}
    
    enum PunkAttributeValue {NONE, ALIEN, APE, BANDANA, BEANIE, BIG_BEARD, BIG_SHADES, BLACK_LIPSTICK, BLONDE_BOB, BLONDE_SHORT, BLUE_EYE_SHADOW, BUCK_TEETH, CAP, CAP_FORWARD, CHINSTRAP, CHOKER, CIGARETTE, CLASSIC_SHADES, CLOWN_EYES_BLUE, CLOWN_EYES_GREEN, CLOWN_HAIR_GREEN, CLOWN_NOSE, COWBOY_HAT, CRAZY_HAIR, DARK_HAIR, DO_RAG, EARRING, EYE_MASK, EYE_PATCH, FEDORA, FEMALE, FRONT_BEARD, FRONT_BEARD_DARK, FROWN, FRUMPY_HAIR, GOAT, GOLD_CHAIN, GREEN_EYE_SHADOW, HALF_SHAVED, HANDLEBARS, HEADBAND, HOODIE, HORNED_RIM_GLASSES, HOT_LIPSTICK, KNITTED_CAP, LUXURIOUS_BEARD, MALE, MEDICAL_MASK, MESSY_HAIR, MOHAWK, MOHAWK_DARK, MOHAWK_THIN, MOLE, MUSTACHE, MUTTONCHOPS, NERD_GLASSES, NORMAL_BEARD, NORMAL_BEARD_BLACK, ORANGE_SIDE, PEAK_SPIKE, PIGTAILS, PILOT_HELMET, PINK_WITH_HAT, PIPE, POLICE_CAP, PURPLE_EYE_SHADOW, PURPLE_HAIR, PURPLE_LIPSTICK, RED_MOHAWK, REGULAR_SHADES, ROSY_CHEEKS, SHADOW_BEARD, SHAVED_HEAD, SILVER_CHAIN, SMALL_SHADES, SMILE, SPOTS, STRAIGHT_HAIR, STRAIGHT_HAIR_BLONDE, STRAIGHT_HAIR_DARK, STRINGY_HAIR, TASSLE_HAT, THREE_D_GLASSES, TIARA, TOP_HAT, VAMPIRE_HAIR, VAPE, VR, WELDING_GOGGLES, WILD_BLONDE, WILD_HAIR, WILD_WHITE_HAIR, ZOMBIE}
    
    function attrStringToEnumMapping(string memory) external view returns (ExtendedPunkDataInterface.PunkAttributeValue);
    function attrEnumToStringMapping(PunkAttributeValue) external view returns (string memory);
    function attrValueToTypeEnumMapping(PunkAttributeValue) external view returns (ExtendedPunkDataInterface.PunkAttributeType);
}

contract AsciiPunks is Ownable, ERC721A {
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
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;
    
    uint public constant costPerToken = 0.005 ether;
    uint[] public prices = [0 ether, .01 ether, .02 ether, .028 ether,
                    .036 ether, .042 ether, .048 ether, .052 ether, .056 ether,
                    .058 ether, .06 ether];
    
    uint public constant maxSupply = 10_001;
        
    bool public isMintActive;
        
    bool public contractSealed;
    
    bytes constant tokenDescription = "Ascii Punks is a generative homage to the original CryptoPunks. Each Ascii Punk's traits are retrieved on-chain from the CryptoPunksData contract.";

    PunkDataInterface public immutable punkDataContract;
    ExtendedPunkDataInterface public immutable extendedPunkDataContract;
    AsciiPunksRendererInterface public asciiPunksRenderer;
            
    modifier unsealed() {
        require(!contractSealed, "Contract sealed.");
        _;
    }
    
    function seal() external onlyOwner unsealed {
        contractSealed = !contractSealed;
    }
    
    function flipMintState() external onlyOwner {
        isMintActive = !isMintActive;
    }
    
    constructor(address punkDataContractAddress, address extendedPunkDataContractAddress,
                address asciiPunksRendererAddress)
        ERC721A("Ascii Punks", "ASCII") {
        punkDataContract = PunkDataInterface(punkDataContractAddress);
        extendedPunkDataContract = ExtendedPunkDataInterface(extendedPunkDataContractAddress);
        setRenderer(asciiPunksRendererAddress);
        _safeMint(0x41538872240Ef02D6eD9aC45cf4Ff864349D51ED, 10);
        _safeMint(0x1B3FEA07590E63Ce68Cb21951f3C133a35032473, 10);
        _safeMint(0x4FD3F94bb056057737DC835757Ba6714692F8a4d, 1);
        _safeMint(0x477EA7A022e51B6eB0DCb6d802fb5F0cFc3b4A81, 10);
        _safeMint(0x32bd27BF11c971aD9536b34Fd02A19Fc3D93E527, 2);
        _safeMint(0xC2172a6315c1D7f6855768F843c420EbB36eDa97, 1);
        _safeMint(0x3C5fD4ff053b178ca2F157D4c44d24269aDD71C3, 1);
        _safeMint(0xF400700bdDb05fBc38657B871E313Db3de8d07ff, 1);
        _safeMint(0x3c1b27e8f900ce78dCA46C55F413d60794195867, 6);
        _safeMint(0xA2b1DB1D846d368489B7211831BEdb50b94aE83D, 1);
    }
    
    function _internalMint(address toAddress, uint numTokens) private {
        if (msg.sender != YS && msg.sender != WG) {
            require(numTokens < 11, "max tokens per tx 10");
            require(isMintActive, "Mint is not active");
            require(msg.value == prices[numTokens], "Need exact payment");
        }
        require(numTokens + totalSupply() <= maxSupply, "Supply limit reached.");
        require(tx.origin == msg.sender, "no contract minters");
        
        _safeMint(toAddress, numTokens);
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
        if (id == 10_000) {
            return baguette();
        }
        return constructTokenURI(uint16(id));
    }
    
    function constructTokenURI(uint16 tokenId) public view returns (string memory) {        
        bytes memory title = abi.encodePacked("Ascii Punk #", tokenId.toString());
        
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
                                '"image_data":"', asciiPunksRenderer.tokenURI(tokenId), '",'
                                '"attributes": ',
                                    punkAttributesAsJSON(tokenId),
                                '}'
                            )
                        )
                    )
                )
            );
    }
    function baguette() public view returns (string memory) {

        bytes memory title = abi.encodePacked("Ascii Punk #10000 (Baguette)");
        bytes memory desc = abi.encodePacked("Oui Oui");
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', title, '",'
                                '"description":"', desc, '",'
                                '"image_data":"', asciiPunksRenderer.baguette(), '",'
                                '"attributes": [{"trait_type":"1/1","value":"Baguette"}]}'
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
    
    function tokenImage(uint16 punkId) public view returns (string memory) {
        return asciiPunksRenderer.tokenURI(punkId);
    }
    
    address constant YS = 0x32bd27BF11c971aD9536b34Fd02A19Fc3D93E527;
    address constant WG = 0x41538872240Ef02D6eD9aC45cf4Ff864349D51ED;
    
    function withdraw() external {
        require(address(this).balance > 0, "Nothing to withdraw");
        
        uint total = address(this).balance;
        uint half = total / 2;
        
        Address.sendValue(payable(WG), half);
        Address.sendValue(payable(YS), total - half);
    }
    
    function creators() external pure returns (address[2] memory) {
        return [YS, WG];
    }
    
    function walletOfOwner(address _owner)
        external
        view
        returns (uint[] memory, uint)
    {
        uint ownerTokenCount = balanceOf(_owner);
        uint[] memory ownedTokenIds = new uint[](ownerTokenCount);
        uint currentTokenId = 0;
        uint ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId < totalSupply()) {
            address currentTokenOwner = _exists(currentTokenId) ? ownerOf(currentTokenId) : address(0);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return (ownedTokenIds, ownedTokenIndex);
    }
    
    function initializePunk(uint16 punkId) private view returns (Punk memory) {
        Punk memory punk = Punk({
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
        
        punk.id = punkId;
        
        string memory attributes = punkDataContract.punkAttributes(punk.id);

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
    
    function punkAttributeCount(Punk memory punk) public view returns (uint totalCount) {
        PunkAttributeValue[13] memory attrArray = [
            punk.sex,
            punk.hair,
            punk.eyes,
            punk.beard,
            punk.ears,
            punk.lips,
            punk.mouth,
            punk.face,
            punk.emotion,
            punk.neck,
            punk.nose,
            punk.cheeks,
            punk.teeth
        ];
        
        for (uint i = 0; i < 13; ++i) {
            if (attrArray[i] != PunkAttributeValue.NONE) {
                totalCount++;
            }
        }
        
        // Don't count sex as an attribute
        totalCount--;
    }
    
    function punkAttributesAsJSON(uint16 punkId) public view returns (string memory json) {
        Punk memory punk = initializePunk(punkId);
        
        PunkAttributeValue none = PunkAttributeValue.NONE;
        
        DynamicBufferLib.DynamicBuffer memory outputBytes = DynamicBufferLib.DynamicBuffer('[');        
        PunkAttributeValue[13] memory attrArray = [
            punk.sex,
            punk.hair,
            punk.eyes,
            punk.beard,
            punk.ears,
            punk.lips,
            punk.mouth,
            punk.face,
            punk.emotion,
            punk.neck,
            punk.nose,
            punk.cheeks,
            punk.teeth
        ];
        
        uint attrCount = punkAttributeCount(punk);
        uint attrCounter = 0;
        for (uint i = 0; i < 13; ++i) {
            PunkAttributeValue attrVal = attrArray[i];
            
            if (attrVal != none) {
                outputBytes.append(bytes(punkAttributeAsJSON(attrVal)));
                if (attrCounter < attrCount) {
                    outputBytes.append(',');
                    attrCounter += 1;
                } 
            }
        }
        outputBytes.append(bytes(']'));
        return string(outputBytes.data);
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
            string memory WWH = "Wild White Hair";
            if (StringUtils.compareToIgnoreCase(attributeAsString, WWH)) {
                attributeAsString = "Female Hoodie";
            }
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

    function getPrices() external view returns (uint[] memory) {
        return prices;
    }

    function getIsSaleActive() external view returns (bool) {
        return isMintActive;
    }

    event RendererSet(address _new);
    function setRenderer(address newRendererAddress) public onlyOwner unsealed {
        asciiPunksRenderer = AsciiPunksRendererInterface(newRendererAddress);
        emit RendererSet(newRendererAddress);
    }
}