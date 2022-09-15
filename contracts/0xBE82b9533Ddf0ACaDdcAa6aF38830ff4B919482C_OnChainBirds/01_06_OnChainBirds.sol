// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12 <0.9.0;
import "./ERC721A/ERC721A.sol";
import "./Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OnChainBirds is ERC721A, Ownable {
    /*
     ____       _______        _      ___  _        __  
    / __ \___  / ___/ /  ___ _(_)__  / _ )(_)______/ /__
    / /_/ / _ \/ /__/ _ \/ _ `/ / _ \/ _  / / __/ _  (_-<
    \____/_//_/\___/_//_/\_,_/_/_//_/____/_/_/  \_,_/___/
    */
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public price = 0.006 ether;
    uint256 public constant maxPerTx = 10;
    bool public imageDataLocked;

    bytes32[][16] traitNames;

    // nesting
    mapping(uint256 => uint256) private nestingTotal;
    mapping(uint256 => uint256) private nestingStarted;
    uint256 private nestingTransfer;
    bool public nestingIsOpen;

    // rendering
    uint256 private constant size = 42;
     
    uint256[7][8] private masks; // layer masks
    
    uint256[][][][7] private assets; // stores encoded pixeldata
    uint256[][6][4] private legendarybodies;
    
    mapping (uint256 => uint256) private hashExists;
    mapping (uint256 => DNA) private tokenIdToDNA;
    uint8[2592] private colorPalette;
    uint8[40] private alphaPalette = [0,0,0,77,155,154,134,7,0,0,0,115,0,0,0,26,255,255,255,115,146,235,252,102,135,234,254,38,34,34,34,26,255,255,255,128,0,0,0,38];
    uint256[][] private goldHeadChance = [[4,0,19,0,3,24,0,13,29,14],[0,30,0,23,2,0,0,0,0,0],[11,6,0,26,0,0,0,0,0,0],[21,22,0,36,0,0,0,0,0,0]];
    uint256[25] private rubyHeadChance = [17,20,32,4,0,35,11,2,30,26,14,1,33,23,36,0,19,22,16,15,3,13,0,18,34];
    uint256[][] private goldEWChance = [[0,2,0,12,0,0,0,0,0,0],[0,0,3,0,0,0,0,0,0,0],[0,10,0,0,4,0,0,0,0,0],[0,0,1,8,0,0,0,0,0,0]];
    uint256[85] private roboHeadChance = [21,0,0,0,1,2,3,5,6,7,9,11,12,14,16,17,22,23,24,25,26,27,28,30,32,33,34,35,36,0,0,0,1,2,3,5,6,7,9,11,12,14,16,17,22,23,24,25,26,27,28,30,32,33,34,35,36,0,0,0,1,2,3,5,6,7,9,11,12,14,16,17,22,23,24,25,26,27,28,30,32,33,34,35,36];
    uint256[13] private roboEWChance = [0,0,0,0,0,0,1,9,10,9,10,11,12];
    uint256[11] private skelleEWChance = [0,0,1,3,5,7,9,10,11,12,0];
    uint256[25] private rubyEWChance = [0,0,7,0,10,0,0,0,0,0,0,0,5,0,0,1,0,0,0,9,3,0,0,0,0];

    struct DNA {
        uint16 Background;
        uint16 Beak;
        uint16 Body;
        uint16 Eyes;
        uint16 Eyewear;
        uint16 Feathers;
        uint16 Headwear;
        uint16 Outerwear;
        uint16 EyeColor;
        uint16 BeakColor;
        uint16 LegendaryId;
    }

    struct DecompressionCursor {
        uint256 index;
        uint256 rlength;
        uint256 color;
        uint256 position;
    }

    bool private raffleLocked;
    event FallbackRaffle(
        uint256 tokenId
    );

    constructor() ERC721A("OnChainBirds", "OCBIRD") {}

    function mint(uint256 quantity) external payable {
        unchecked {
            uint256 totalminted = _totalMinted();
            uint256 newSupply = totalminted + quantity;
            require(newSupply <= MAX_SUPPLY, "SoldOut");
            require(quantity <= maxPerTx, "MaxPerTx");
            require(msg.value >= price * quantity);
            _mint(msg.sender, quantity);
            for(; totalminted < newSupply; ++totalminted) {
                createDNA(totalminted);
            }
        }
    }

    function tokenURI(uint256 tokenId) public view override (ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name": "#',
                            _toString(tokenId),
                            '", "image": "data:image/svg+xml;base64,',
                            Base64.encode(
                                bytes(tokenIdToSVG(tokenId))
                            ),
                            '","attributes":',
                            tokenIdToMetadata(tokenId),
                            "}"
                        )
                    )
                )
            );
    }

    function createDNA(uint256 tokenId) private {
        unchecked {
        uint256 randinput =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            tokenId,
                            msg.sender
                        )
                    )
                );
        uint256 newDNA;
        uint256 baseDNA;
        uint256 mask = 0xFFFF;
        uint256 Beak;
        uint256 Eyes;
        uint256 Eyewear;
        uint256 rand = randinput & mask;
        // background
        uint256 backgroundId;
        uint256[7] memory background = [uint256(520),11110,10914,10899,10833,10722,10538];
        uint256 bound;
        uint256 lowerbound;
        for (uint256 j; j < background.length; ++j) {
            bound += background[j];
            if ((rand-lowerbound) < (bound-lowerbound)) backgroundId = j;
            lowerbound = bound; 
        }
        newDNA = backgroundId;
        uint256 bgIsNotZero = ((backgroundId | ((backgroundId^type(uint256).max) + 1)) >> 255) & 1;
        uint256 legendcount = tokenIdToDNA[tokenId-1].LegendaryId+(1>>bgIsNotZero);
        newDNA |= legendcount<<160;
        randinput >>= 16;
        rand = randinput & mask;
        // beak
        uint256[4] memory beak = [uint256(0),27675,27244,10617];
        delete bound;
        delete lowerbound;
        for (uint256 j = 1; j < beak.length; ++j) {
            bound += beak[j];
            if ((rand-lowerbound) < (bound-lowerbound)) Beak = j;
            lowerbound = bound;
        }
        randinput >>= 16;
        rand = randinput & mask; 
        // eyes
        uint256[12] memory eyes = [uint256(0),16202,9708,9013,9006,8699,3332,1989,1936,1930,1877,1844];
        delete bound;
        delete lowerbound;
        for (uint256 j = 1; j < eyes.length; ++j) {
            bound += eyes[j];
            if ((rand-lowerbound) < (bound-lowerbound)) Eyes = j;
            lowerbound = bound; 
        }
        baseDNA |= Eyes<<48;
        randinput >>= 16;
        rand = randinput & mask;
        // eyewear
        uint256[13] memory eyewear = [uint256(53738),1317,1226,1140,1121,1121,1055,931,891,878,826,800,492];
        delete bound;
        delete lowerbound;
        for (uint256 j; j < eyewear.length; ++j) {
            bound += eyewear[j];
            if ((rand-lowerbound) < (bound-lowerbound)) Eyewear = j;
            lowerbound = bound; 
        }
        randinput >>= 16;
        rand = randinput & mask;
        // feathers
        uint256[10] memory feathers = [uint256(0),12345,9691,8301,7625,7507,7238,6072,3549,3208];
        delete bound;
        delete lowerbound;
        for (uint256 j = 1; j < feathers.length; ++j) {
            bound += feathers[j];
            if ((rand-lowerbound) < (bound-lowerbound)) baseDNA |= j<<80;
            lowerbound = bound; 
        }
        randinput >>= 16;
        rand = randinput & mask;
        // head
        uint256 resultHead;
        uint256[38] memory headwear = [uint256(19390),2510,2340,2130,1730,1678,1665,1638,1632,1547,1527,1494,1429,1389,1357,1337,1324,1265,1265,1226,1199,1180,1180,1153,1147,1121,1101,970,950,826,819,786,688,662,603,524,380,374];
        delete bound;
        delete lowerbound;
        uint256 bodybound;
        for (uint256 j; j < headwear.length; ++j) {
            bound += headwear[j];
            if ((rand-lowerbound) < (bound-lowerbound)) {resultHead = j; bodybound=lowerbound;}
            lowerbound = bound; 
        }
        // body
        uint256[11][38] memory body = [[uint256(4230),1752,2349,2204,2322,2270,2224,1182,717,94,48],[uint256(1489),952,0,0,0,0,0,0,0,48,21],[uint256(485),271,362,389,0,283,270,112,67,67,34],[uint256(847),495,698,0,0,0,0,0,0,62,28],[uint256(1051),625,0,0,0,0,0,0,0,0,54],[uint256(570),157,282,249,0,282,0,0,33,66,39],[uint256(401),211,309,348,335,0,0,0,0,27,34],[uint256(314),282,223,249,190,0,242,92,46,0,0],[uint256(1599),0,0,0,0,0,0,0,0,0,33],[uint256(563),387,492,0,0,0,0,0,0,66,39],[uint256(248),144,223,197,184,249,197,85,0,0,0],[uint256(348),212,146,205,0,199,198,0,73,73,40],[uint256(551),328,0,0,465,0,0,0,0,46,39],[uint256(792),597,0,0,0,0,0,0,0,0,0],[uint256(263),258,264,251,297,0,0,0,0,15,9],[uint256(467),277,0,447,0,0,0,0,86,0,60],[uint256(736),408,0,0,0,0,0,0,99,47,34],[uint256(288),140,159,140,126,145,152,60,21,0,34],[uint256(493),317,0,342,0,0,0,0,86,0,27],[uint256(1199),0,0,0,0,0,0,0,0,0,27],[uint256(1183),0,0,0,0,0,0,0,0,0,16],[uint256(277),131,216,229,229,0,0,98,0,0,0],[uint256(290),166,153,192,0,199,0,73,40,27,40],[uint256(223),140,153,107,205,204,0,53,34,0,34],[uint256(506),244,389,0,0,0,0,0,0,0,8],[uint256(210),125,144,229,164,164,0,59,0,0,26],[uint256(166),100,146,171,119,132,86,73,53,47,8],[uint256(373),223,308,0,0,0,0,0,0,59,7],[uint256(897),0,0,0,0,0,0,0,0,33,20],[uint256(826),0,0,0,0,0,0,0,0,0,0],[uint256(93),74,113,133,159,126,0,67,14,0,40],[uint256(786),0,0,0,0,0,0,0,0,0,0],[uint256(93),73,99,73,112,67,73,26,13,33,26],[uint256(98),67,93,73,106,73,67,52,0,0,33],[uint256(83),67,67,93,0,60,80,21,20,66,46],[uint256(105),47,67,86,0,73,0,0,21,73,52],[uint256(60),68,74,54,0,0,0,0,15,74,35],[uint256(45),39,59,66,0,66,46,0,7,0,46]];
        bound = bodybound;
        lowerbound = bodybound;
        for (uint256 j; j < 11; ++j) {
            bound += body[resultHead][j];
            if ((rand-lowerbound) < (bound-lowerbound)) baseDNA |= (j+1)<<32;
            lowerbound = bound; 
        }
        baseDNA |= resultHead<<96;
        randinput >>= 16;
        rand = randinput & mask;
        // outerwear
        uint256[8] memory outerwear = [uint256(54563),2031,1979,1717,1659,1351,1331,905];
        delete bound;
        delete lowerbound;
        for (uint256 j; j < outerwear.length; ++j) {
            bound += outerwear[j];
            if ((rand-lowerbound) < (bound-lowerbound)) baseDNA |= j<<112;
            lowerbound = bound; 
        }
        randinput >>= 16;
        rand = randinput & mask;
        // beakcolor
        newDNA|=(rand & 1)<<144;
        randinput >>= 16;
        rand = randinput & mask;
        // eyecolor
        uint256 eyeIsNotColored = Eyes/6;
        uint256 EyeColor = (rand%7+1)*(1>>eyeIsNotColored)+eyeIsNotColored;
        baseDNA |= EyeColor<<128;
        // store dna
        uint256 found;
        randinput >>= 16;
        uint256 baseHash = baseDNA|bgIsNotZero<<192;
        for(uint256 i; i<5; ++i) {
            uint256 isNotLast = 1>>(i>>2);//1>>(i/4);
            uint256 hashedDNA = baseHash|Beak<<16|Eyewear<<64|(((1>>isNotLast)*tokenId)<<212);
            if(hashExists[hashedDNA]+found == 0) {
                newDNA |= (hashedDNA<<64)>>64;
                assembly {
                    mstore(0, tokenId)
                    mstore(32, tokenIdToDNA.slot)
                    let hash := keccak256(0, 64)
                    sstore(hash, newDNA)
                }
                ++hashExists[hashedDNA];
                ++found;
                }
            Beak = Beak%3+1;
            if(i==0) Eyewear = (Eyewear + randinput%8)%13;
            Eyewear = ++Eyewear%13;
        }
        }
    }
    
    function getDNA(uint256 tokenId) public view returns(DNA memory) {
        DNA memory realDNA = tokenIdToDNA[tokenId];
        // legendary id
        if(realDNA.Background == 0) {
            if(realDNA.LegendaryId>74) {
                realDNA.Background = 1;
                delete realDNA.LegendaryId;
            } else {
                uint256 specialType = realDNA.LegendaryId%3;
                uint256 specialIndex = realDNA.LegendaryId/3;
                if(specialType==0) {
                    //legendary (specialIndex starts at 1)
                    delete realDNA.Beak;
                    delete realDNA.Eyes;
                    delete realDNA.Eyewear;
                    delete realDNA.Headwear;
                    delete realDNA.Outerwear;
                    delete realDNA.EyeColor;
                    delete realDNA.BeakColor;
                    uint256 legendmod = (specialIndex-1)%4;
                    uint256 legenddiv = (specialIndex-1)/4;
                    realDNA.Background = uint16(7 + legendmod);
                    realDNA.Body = uint16(legendmod+1);
                    realDNA.Feathers = uint16(legenddiv+1);
                    return realDNA;
                } else if(specialType==1) {
                    //golden (specialIndex starts at 0)
                    realDNA.Body = 12;
                    uint256 feathermod = specialIndex%5;
                    uint256 featherdiv = specialIndex/5;
                    if(feathermod<2) featherdiv=(featherdiv<<1)+feathermod;
                    if(feathermod==0) ++feathermod;
                    realDNA.Feathers=uint16(feathermod);
                    realDNA.Headwear = uint16(goldHeadChance[--feathermod][featherdiv]);
                    realDNA.Background = uint16((specialIndex%6)+1);
                    realDNA.Eyewear = uint16(goldEWChance[feathermod][featherdiv]);
                } else if(specialType==2) {
                    //ruby (specialIndex starts at 0)
                    realDNA.Body = 13;
                    realDNA.Background = uint16((specialIndex%6)+1);
                    realDNA.Headwear = uint16(rubyHeadChance[specialIndex%25]);
                    realDNA.Eyewear = uint16(rubyEWChance[specialIndex%25]);
                }
            }
        } else {
            delete realDNA.LegendaryId;
        }
        // special bodies except robot -> no outerwear
        if(realDNA.Body > 10) {
            delete realDNA.Outerwear;
        }
        // single color eyes
        if(realDNA.Eyes > 5) {
            realDNA.EyeColor = 1;
        }
        // special bodies
        if(realDNA.Body > 9) {
            delete realDNA.BeakColor;
            delete realDNA.EyeColor;
            // golden body
            if(realDNA.Body == 12) {
                if(realDNA.Eyes == 2 || realDNA.Eyes == 9) {
                    realDNA.Eyes = 1;
                } else if(realDNA.Eyes == 7 || realDNA.Eyes == 6) {
                    realDNA.Eyes = 2;
                } else if(realDNA.Eyes == 5) {
                    realDNA.Eyes = 4;
                } else if(realDNA.Eyes == 8 || realDNA.Eyes > 9) {
                    realDNA.Eyes = 5;
                } else {
                    realDNA.Eyes = 3;
                }
            } else {
                realDNA.Feathers = 1;
                // shuffle hash
                uint256 dist = uint256(keccak256(abi.encodePacked(tokenId,realDNA.Eyes)));
                uint256 mask = 0xFFFFFFFFFFFFFFFF;
                if(realDNA.Body == 10) {
                    // robot body
                    realDNA.Outerwear = uint16((dist&mask)%3);
                    realDNA.Eyewear = uint16(roboEWChance[((dist>>64)&mask)%11]);
                    realDNA.Headwear = uint16(roboHeadChance[((dist>>128)&mask)%85]);
                    realDNA.Eyes = uint16((dist>>192)%2+1);
                } else if(realDNA.Body == 11) {
                    // skelleton body
                        realDNA.Eyes = uint16((dist&mask)%6+1);
                        realDNA.Eyewear = uint16(skelleEWChance[(dist>>64)%11]);
                } else {
                    // ruby skelleton
                    realDNA.Beak = 1;
                    if(realDNA.Eyes > 5 && realDNA.Eyes < 9) {
                        realDNA.Eyes = 1;
                    } else if(realDNA.Eyes == 3 || realDNA.Eyes > 8) {
                        realDNA.Eyes = 2;
                    } else if(realDNA.Eyes == 5 || realDNA.Eyes == 1) {
                        realDNA.Eyes = 3;
                    } else {
                        realDNA.Eyes = 4;
                    }
                }
                    
            }
        }
        // hoodie -> raincloud, crescent, no eyewear
        if(realDNA.Outerwear == 3) {
            realDNA.Body = 1;
            delete realDNA.Eyewear;
            if(realDNA.Headwear < 26) {
                delete realDNA.Headwear;
            } else {
                realDNA.Headwear = 5;
            }
        }
        // heros cap -> heros outerwear, no eyewear 
        if(realDNA.Headwear == 31) {
            realDNA.Outerwear = 8;
            delete realDNA.Eyewear;
        }
        // space helmet -> no outerwear
        if(realDNA.Headwear == 6) {
            delete realDNA.Outerwear;
            if(realDNA.Eyewear == 8) {
                delete realDNA.Eyewear;
            }
        }
        // headphones
        if(realDNA.Headwear == 21) {
            // -> job glasses or none
            if(realDNA.Eyewear != 2) delete realDNA.Eyewear;
            // -> diamond necklace or none
            if(realDNA.Outerwear != 6) delete realDNA.Outerwear;
        }
        // aviators cap -> no eyewear, no bomber, jeans and hoodie down outerwear
        if(realDNA.Headwear == 13) {
            delete realDNA.Eyewear;
            if(realDNA.Outerwear % 2 == 1 && realDNA.Outerwear != 3) delete realDNA.Outerwear;
        }
        // beanie -> no sunglasses, rose-colored glasses, aviators, monocle, 3d glasses
        if(realDNA.Headwear == 8) {
            if((realDNA.Eyewear%2 == 1 && realDNA.Eyewear != 1) || realDNA.Eyewear == 8)
                delete realDNA.Eyewear;
        }
        // eyewear -> no eyes except if eyepatch, monocle, half-moon, big tech
        if(realDNA.Eyewear > 1) {
            // monocle -> no side-eyes
            if(realDNA.Eyewear == 8) {
                // no bucket hat combo
                if(realDNA.Headwear == 28) {
                    delete realDNA.Eyewear;
                } else if(realDNA.Eyes == 5 && realDNA.Body != 11)
                    realDNA.Eyes = 1;
            }
            // half-moon spectacles -> open, adorable, fire eyes
            else if(realDNA.Eyewear == 12) {
                if(realDNA.Body == 10) {
                    realDNA.Eyes = 2;
                } else if(realDNA.Body == 11) {
                    if(realDNA.Eyes != 4 && realDNA.Eyes != 5) realDNA.Eyes = 1;
                } else if(realDNA.Body == 12) {
                    realDNA.Eyes = 3;
                } else if(realDNA.Body == 13) {
                    if(realDNA.Eyes != 3) realDNA.Eyes = 1;
                } else if(realDNA.Eyes != 6 && realDNA.Eyes != 9) {
                    realDNA.Eyes = 1;
                }
            }
            // big tech -> open eyes
            else if(realDNA.Eyewear == 10) {
                if(realDNA.Body == 10) {
                    realDNA.Eyes = 2;
                } else if(realDNA.Body == 11) {
                    realDNA.Eyes = 5;
                } else if(realDNA.Body > 11) {
                    realDNA.Eyes = 3;
                } else {
                    realDNA.Eyes = 1;
                }
            } else {
                delete realDNA.Eyes;
                delete realDNA.EyeColor;
            }
        }
        return realDNA;
    }

    function decodeLength(uint256[] memory imgdata, uint256 index) private pure returns (uint256) {
        uint256 bucket = index >> 4;
        uint256 offset = (index & 0xf) << 4;
        uint256 data = imgdata[bucket] >> (250-offset);
        uint256 mask = 0x3F;
        return data & mask;
    }

    function decodeColorIndex(uint256[] memory imgdata, uint256 index) private pure returns (uint256) {
        uint256 bucket = index >> 4;
        uint256 offset = (index & 0xf) << 4;
        uint256 data = imgdata[bucket] >> (240-offset);
        uint256 mask = 0x3FF;
        return data & mask;
    }

    function tokenIdToSVG(uint256 tokenId) private view returns (string memory) {
        // load data
        DNA memory birdDNA = getDNA(tokenId);
        bool trueLegend = birdDNA.Background>6;
        uint256 colorPaletteLength = colorPalette.length/3;
        uint256 lastcolor;
        uint256 lastwidth = 1;
        bool[] memory usedcolors = new bool[](875);
        bytes memory svgString;
        // load pixeldata
        uint256[][7] memory compressedData;
        compressedData[0] = assets[0][birdDNA.Background-1][0];
        // legendary bodies
        if(trueLegend){
            compressedData[1] = legendarybodies[birdDNA.Body-1][birdDNA.Feathers-1];
        } else {
            compressedData[1] = assets[2][birdDNA.Body-1][birdDNA.Feathers-1];
        }
        if(birdDNA.Beak!=0){
            // special bodies -> special beaks
            if(birdDNA.Body>9){
                compressedData[2] = assets[1][birdDNA.Body-7][birdDNA.Beak-1];
            } else {
                compressedData[2] = assets[1][birdDNA.Beak-1][birdDNA.BeakColor];
            }
        } 
        if(birdDNA.Eyes!=0) {
            // special bodies -> special eyes
            if(birdDNA.Body>9){
                compressedData[3] = assets[3][birdDNA.Body+1][birdDNA.Eyes-1];
            } else {
                compressedData[3] = assets[3][birdDNA.Eyes-1][birdDNA.EyeColor-1];
            }
        }
        if(birdDNA.Eyewear!=0) compressedData[4] = assets[4][birdDNA.Eyewear-1][0];
        if(birdDNA.Headwear!=0) compressedData[5] = assets[5][birdDNA.Headwear-1][0];
        if(birdDNA.Outerwear!=0) compressedData[6] = assets[6][birdDNA.Outerwear-1][0];

        DecompressionCursor[7] memory cursors;
        for(uint256 i = 1; i<7; ++i) {
            if(compressedData[i].length != 0) {
            cursors[i]=DecompressionCursor(0,decodeLength(compressedData[i],0),decodeColorIndex(compressedData[i],0),0);
            }
        }
        // masks
        uint256[7][7] memory bitmasks;
        for(uint256 i; i<7; ++i) {
            if(i==1 && trueLegend) {
                bitmasks[i] = masks[7];
            } else {
                bitmasks[i] = masks[i];
            }
        }
        // create SVG
        bytes14 preRect = "<rect class='c";
        for(uint256 y; y < size;++y){
            bytes memory svgBlendString;
            for(uint256 x; x < size;++x){
                bool blendMode;
                uint256 coloridx;
                uint256 index = y*size+x;
                uint256 bucket = index >> 8;
                uint256 mask = 0x8000000000000000000000000000000000000000000000000000000000000000 >> (index & 0xff);
                // pixeldata decoding
                for(uint256 i = 6; i!=0; i--) {
                    if(compressedData[i].length != 0) {
                    if (bitmasks[i][bucket] & mask != 0) {
                        cursors[i].index++;
                        if(cursors[i].color != 0) {
                            if(coloridx == 0) {
                                coloridx = cursors[i].color;
                                if(cursors[i].color>colorPaletteLength) {
                                    blendMode=true;
                                }
                            } else if(blendMode) {
                                svgBlendString = abi.encodePacked(
                                    preRect,
                                    _toString(cursors[i].color),
                                    "' x='",
                                    _toString(x),
                                    "' y='",
                                    _toString(y),
                                    "' width='1'/>",
                                    svgBlendString
                                );
                                if(cursors[i].color<=colorPaletteLength) {
                                    blendMode=false;
                                }
                                usedcolors[cursors[i].color] = true;
                            }
                        }
                        if(cursors[i].index==cursors[i].rlength) {
                            cursors[i].index=0;
                            cursors[i].position++;
                            if(cursors[i].position<compressedData[i].length*16){
                                cursors[i].rlength=decodeLength(compressedData[i],cursors[i].position);
                                cursors[i].color=decodeColorIndex(compressedData[i],cursors[i].position);
                            }
                            
                        }
                    }   
                    }
                }
                // finalize pixel color
                if(coloridx==0 || blendMode) {
                    uint256 bgcolor;
                    if(birdDNA.Background > 6 && birdDNA.Background != 9){
                        bgcolor = decodeColorIndex(compressedData[0],y);
                    } else {
                        bgcolor = decodeColorIndex(compressedData[0],0);
                    }
                    if(coloridx==0) {
                        coloridx=bgcolor;
                    }
                    else if(blendMode){
                        svgBlendString = abi.encodePacked(
                                    preRect,
                                    _toString(bgcolor),
                                    "' x='",
                                    _toString(x),
                                    "' y='",
                                    _toString(y),
                                    "' width='1'/>",
                                    svgBlendString
                                );
                        usedcolors[bgcolor] = true;
                    }
                }
                usedcolors[coloridx] = true;
                if(x == 0) {
                    lastwidth = 1;
                } else if(lastcolor == coloridx) {
                    lastwidth++;
                } else {
                    svgString = abi.encodePacked( 
                        svgString,
                        svgBlendString,
                        preRect,
                        _toString(lastcolor),
                        "' x='",
                        _toString(x-lastwidth),
                        "' y='",
                        _toString(y),
                        "' width='",
                        _toString(lastwidth),
                        "'/>"
                    );
                    svgBlendString = ""; 
                    lastwidth = 1;
                }
                lastcolor = coloridx;
            }
            svgString = abi.encodePacked( 
                        svgString,
                        svgBlendString,
                        preRect,
                        _toString(lastcolor),
                        "' x='",
                        _toString(42-lastwidth),
                        "' y='",
                        _toString(y),
                        "' width='",
                        _toString(lastwidth),
                        "'/>"
                    );
            svgBlendString = "";
        }
        // generate stylesheet
        bytes memory stylesheet;
        for(uint256 i; i<usedcolors.length; ++i) {
           if(usedcolors[i]) {
            bytes memory colorCSS;
            uint256 paletteIdx = (i-1)*3;
            if(paletteIdx>=colorPalette.length) {
                uint256 fixedColorIdx = (i-1)-colorPalette.length/3;
                paletteIdx = fixedColorIdx<<2;
                uint256 dec = uint256(alphaPalette[paletteIdx+3])*100/255;
                colorCSS = abi.encodePacked("rgba(", _toString(uint256(alphaPalette[paletteIdx])), ",", _toString(uint256(alphaPalette[paletteIdx+1])), ",", _toString(uint256(alphaPalette[paletteIdx+2])), ",0.", _toString(dec), ")");
            } else {
                colorCSS = abi.encodePacked("rgb(", _toString(uint256(colorPalette[paletteIdx])), ",", _toString(uint256(colorPalette[paletteIdx+1])), ",", _toString(uint256(colorPalette[paletteIdx+2])), ")");
            }
            stylesheet = abi.encodePacked(stylesheet, ".c", _toString(i), "{fill:", colorCSS, "}");
            }
        }
        // combine full SVG
        svgString =
            abi.encodePacked(
                '<svg id="bird-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 42 42"> ',
                svgString,
                "<style>rect{height:1px;} #bird-svg{shape-rendering: crispedges;} ",
                stylesheet,
                "</style></svg>"
            );

        return string(svgString);
    }
    
    function tokenIdToMetadata(uint256 tokenId) private view returns (string memory) {
        unchecked {
        DNA memory tokenDNA = getDNA(tokenId);
        string memory metadataString;
        for (uint256 i; i < 8; ++i) {
            uint256 traitId;
            uint idx1;
            uint idx2;
            if(i==0) {
                traitId = tokenDNA.Background;
            } else if(i==1) {
                traitId = tokenDNA.Beak;
            } else if(i==2) {
                traitId = tokenDNA.Body;
                if(tokenDNA.Background > 6) {
                    idx1 = 8;
                    idx2 = traitId-1;
                }
            } else if(i==3) {
                traitId = tokenDNA.Eyes;
                if(tokenDNA.Body > 9) {
                    idx1 = tokenDNA.Body;
                    idx2 = traitId-1;
                }
            } else if(i==4) {
                traitId = tokenDNA.Eyewear;
            } else if(i==5) {
                traitId = tokenDNA.Feathers;
                if(tokenDNA.LegendaryId != 0 && tokenDNA.Body != 13) {
                    idx1 = 9;
                    idx2 = traitId-1;
                } else if(tokenDNA.Body > 9) {
                    idx1 = 14;
                    idx2 = tokenDNA.Body-10;
                }
            } else if(i==6) {
                traitId = tokenDNA.Headwear;
            } else if(i==7) {
                traitId = tokenDNA.Outerwear;
            }
            if(traitId == 0) continue;
            string memory traitName;
            if(idx1 == 0) {
                idx1 = i;
                idx2 = traitId-1;
            }
            traitName = bytes32ToString(traitNames[idx1][idx2]);
            
            string memory startline;
            if(i!=0) startline = ",";

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    startline,
                    '{"trait_type":"',
                    bytes32ToString(traitNames[15][i]),
                    '","value":"',
                    traitName,
                    '"}'
                ));
        }
        return string.concat("[", metadataString, "]");
        }
    }
    
    /**
        Nesting Functions
     */
    
    function nestingPeriod(uint256 tokenId) external view returns (bool nesting, uint256 current, uint256 total) {
        uint256 start = nestingStarted[tokenId];
        if (start != 0) {
            nesting = true;
            current = block.timestamp - start;
        }
        total = current + nestingTotal[tokenId];
    }

    function transferWhileNesting(address from, address to, uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender);
        nestingTransfer = 1;
        transferFrom(from, to, tokenId);
        delete nestingTransfer;
    }

    function _beforeTokenTransfers(address, address, uint256 startTokenId, uint256 quantity) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(nestingStarted[tokenId] == 0 || nestingTransfer != 0, "Nesting");
        }
    }

    function toggleNesting(uint256[] calldata tokenIds) external {
        bool nestOpen = nestingIsOpen;
        for (uint256 i; i < tokenIds.length; ++i) {
            require(ownerOf(tokenIds[i]) == msg.sender);
            uint256 start = nestingStarted[tokenIds[i]];
            if (start == 0) {
                require(nestOpen);
                nestingStarted[tokenIds[i]] = block.timestamp;
            } else {
                nestingTotal[tokenIds[i]] += block.timestamp - start;
                nestingStarted[tokenIds[i]] = 0;
            }
        }
    }

    /**
        Admin Functions
     */

    // fallback raffle in case the random generation does result in a few missing special/legendary birds
    function raffleUnmintedSpecials() external onlyOwner {
        uint256 supply = _totalMinted();
        require(!raffleLocked && supply>=MAX_SUPPLY);
        uint256 specialsMinted = tokenIdToDNA[supply-1].LegendaryId;
        while(specialsMinted < 74) {
            uint256 randomId = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, specialsMinted))) % supply;
            while(tokenIdToDNA[randomId].Background == 0) {
                randomId = (++randomId)%supply;
            }
            tokenIdToDNA[randomId].LegendaryId = uint16(++specialsMinted);
            delete tokenIdToDNA[randomId].Background;
            emit FallbackRaffle(randomId);
        }
        raffleLocked = true;
    }

    // fallback reroll to prevent clones, is fairly rare, called as fast as possible after mint if detected
    function rerollClone(uint256 tokenId1, uint256 tokenId2) external onlyOwner {
        DNA memory bird = getDNA(tokenId1);
        DNA memory clone = getDNA(tokenId2);
        delete bird.Background;
        delete bird.BeakColor;
        delete clone.Background;
        delete clone.BeakColor;
        require(keccak256(abi.encode(bird)) == keccak256(abi.encode(clone)));
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        tokenIdToDNA[tokenId1].Eyes = uint16((randomHash&0xFFFFFFFF)%11+1);
        randomHash>>=32;
        tokenIdToDNA[tokenId1].Beak = uint16((randomHash&0xFFFFFFFF)%3+1);
        randomHash>>=32;
        tokenIdToDNA[tokenId1].Outerwear = uint16(randomHash%8);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert();
    }

    function expelFromNest(uint256 tokenId) external onlyOwner {
        require(nestingStarted[tokenId] != 0);
        nestingTotal[tokenId] += block.timestamp - nestingStarted[tokenId];
        delete nestingStarted[tokenId];
    }

    function setNestingOpen() external onlyOwner {
        nestingIsOpen = !nestingIsOpen;
    }

    function uploadImages1(uint256[][][][7] calldata defaultdata) external onlyOwner {
        if(imageDataLocked) revert();
        assets = defaultdata;
    }
    function uploadImages2(uint256[][][] calldata bodydata) external onlyOwner {
        if(imageDataLocked) revert();
        assets[2] = bodydata;
    }
    function uploadImages3(uint256[][][4] calldata specialbodydata, uint256[][6][4] calldata legenbodydata, uint8[2592] calldata cpalette, uint256[7][8] calldata _masks, bytes32[][16] calldata _traitnames) external onlyOwner {
        if(imageDataLocked) revert();
        assets[2].push(specialbodydata[0]);
        assets[2].push(specialbodydata[1]);
        assets[2].push(specialbodydata[2]);
        assets[2].push(specialbodydata[3]);
        colorPalette = cpalette;
        masks = _masks;
        traitNames = _traitnames;
        legendarybodies = legenbodydata;
        imageDataLocked=true;
    }

    /**
        Utility Functions
     */

    function bytes32ToString(bytes32 _bytes32) private pure returns (string memory) {
        uint256 i;
        while(_bytes32[i] != 0 && i < 32) {
            ++i;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < bytesArray.length; ++i) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    // tokensOfOwner function: MIT License
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i; tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    } 
}