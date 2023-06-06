// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OnChainSeasides is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    uint private constant maxTokensPerTransaction = 30;
    uint256 private tokenPrice = 30000000000000000; //0.03 ETH
    uint256 private constant nftsNumber = 3333;
    uint256 private constant nftsPublicNumber = 3300;
    
    constructor() ERC721("OnChain Seasides", "SEA") {
        _tokenIdCounter.increment();
    }
    

     function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function toHashCode(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "000000";
        }
        uint256 i;

        bytes memory buffer = "000000";
        for(i=6;i>0;i--) {
            if (value % 16 < 10)
                buffer[i-1] = bytes1(uint8(48 + uint256(value % 16)));
            else
                buffer[i-1] = bytes1(uint8(55 + uint256(value % 16)));

            value /= 16;
        }
        return string(buffer);
    }
    
    function getGrass(uint256 value, uint256 is_mirror) public pure returns (string memory) {
        uint256 i;
        uint256 prt;
        int256 sym;
        uint256 pos;
        uint256 seed;
        uint256 ps;
        uint256 psx;

        uint256 finale=1;

        bytes memory buffer = new bytes(250);

        uint256[6] memory gtypes;

        gtypes[0] = 563891157643448204000202434637890680663763947839870365052682593692495482209;
        gtypes[1] = 1002862760941180669446230775124823108274825368678245159754096610961814;
        gtypes[2] = 563871000271014004664722370698789260236686074535032282236861359775136052288;
        gtypes[3] = 1003329826285104973259814183739832352502149867278345049274004408492605;
        gtypes[4] = 564017709498396033660054424834310877655732749413952956046917965314005819035;
        gtypes[5] = 1002137238139483205643623885946750710585681910777426838629649942020236;


        finale = 0;
        seed = gtypes[value*2-2];

    
        for(psx=ps=pos=i=0;i<70;i++) {
            prt = seed / (750 ** ps++);
            sym = int256(prt % 750);
            if (sym == 749) {
                if (finale == 1)
                    break;
                    
                finale = 1;
                seed = gtypes[value*2-1];
                ps=0;
                continue;
            }
            
            if (psx%2==0) {
                
                if (is_mirror==1)
                    sym = 400 - sym;
                else
                    sym += 550;
                  
                if (i>0)
                    buffer[pos++] = ' ';
            } else {
                if (i>0)
                    buffer[pos++] = ',';
                sym += 500;
    
            }
            
            if (sym<0) {
                sym=-sym;
                buffer[pos++] = bytes1(uint8(45));
    
            }
                
            if (sym<10)
                buffer[pos++] = bytes1(uint8(48 + uint256(sym % 10)));
            else if (sym<100) {
                buffer[pos++] = bytes1(uint8(48 + uint256(sym / 10)));
                buffer[pos++] = bytes1(uint8(48 + uint256(sym % 10)));
            } else if (sym<1000) {
                buffer[pos++] = bytes1(uint8(48 + uint256(sym / 100)));
                buffer[pos++] = bytes1(uint8(48 + uint256((sym / 10)%10)));
                buffer[pos++] = bytes1(uint8(48 + uint256(sym % 10)));  
            } else {
                buffer[pos++] = bytes1(uint8(48 + uint256(sym / 1000)));
                buffer[pos++] = bytes1(uint8(48 + uint256((sym / 100)%10)));
                buffer[pos++] = bytes1(uint8(48 + uint256((sym / 10)%10)));
                buffer[pos++] = bytes1(uint8(48 + uint256(sym % 10)));  
            }
            psx++;
    
        }
        
        bytes memory buffer2 = new bytes(pos);
        for(i=0;i<pos;i++)
            buffer2[i] = buffer[i];

        return string(buffer2);
    }
    
    function getShip(uint256 value, uint dir, uint is_mirror) internal pure returns (string memory) {
        uint256 i;
        uint256 prt;
        uint256 sym;
        uint256 pos;
        uint256 seed;
        uint256 ps;

        uint256 finale=1;

        bytes memory buffer = new bytes(300);

        uint256[10] memory stypes;

        stypes[0] = 4039953958419306012627391607069051694356360220713754655043968660016;
        stypes[1] = 63106266081136485859406661386793985037851232673778661;
        stypes[2] = 161568093605294050650559196328221936718722000674656809180508552713619040;
        stypes[3] = 63096482884095845761084638724950672236119832596577537;
        stypes[4] = 6461049781969783938359086369026346968766711308334899858451023002616666897676;
        stypes[5] = 63120086296825990194702960480301658791387552688699008;
        stypes[6] = 161512793322334258241850556133413063336821761930288295517787616106338882;
        stypes[7] = 986070141659197590531764122903072004020;
        stypes[8] = 161390119281273703232398765386984498139365471992159755174679367096177400;
        stypes[9] = 100972004999646208506838990436000093602246360157725215130052251;
        if (value < 7) {
            seed = stypes[value-1];
        } else {
            finale = 0;
            seed = stypes[value==7?6:8];
        }

        uint256 shift_y = is_mirror==1 ? 560 : 460;
        for(ps=pos=i=0;i<70;i++) {
            prt = seed / (200 ** ps++);
            sym = prt % 200;
            if (sym == 150) {
                if (finale == 1)
                    break;
                    
                finale = 1;
                seed = stypes[value==7?7:9];
                ps=0;
                continue;
            }
            
    
                
            
            
            if (ps%2==0) {
                if (is_mirror==1)
                    sym = 1000 - (sym + 320);
                else
                    sym = sym + shift_y;
                    
                if (i>0)
                    buffer[pos++] = ',';
            } else {
    
                if (dir == 1)
                    sym += 100;
                else
                    sym = 1000 - (sym + 100);
                    
                if (i>0)
                    buffer[pos++] = ' ';
            }
                
            if (sym<10)
                buffer[pos++] = bytes1(uint8(48 + uint256(sym % 10)));
            else if (sym<100) {
                buffer[pos++] = bytes1(uint8(48 + uint256(sym / 10)));
                buffer[pos++] = bytes1(uint8(48 + uint256(sym % 10)));
            } else {
                buffer[pos++] = bytes1(uint8(48 + uint256(sym / 100)));
                buffer[pos++] = bytes1(uint8(48 + uint256((sym / 10)%10)));
                buffer[pos++] = bytes1(uint8(48 + uint256(sym % 10)));  
            }
    
        }

        bytes memory buffer2 = new bytes(pos);
        for(i=0;i<pos;i++)
            buffer2[i] = buffer[i];

        return string(buffer2);
        }

    
    function getPalm(uint256 num) internal pure returns (string memory) {
        string[4] memory palm;
        palm[0]='M-137,104C-32,27,573,28,762,263 C582,95,180,57,23,87c105-7,598,17,757,244 c-60-74-241-182-524-212c241,55,435,181,475,265 C587,207,260,141,220,133c18,4,375,100,461,262 C504,164,19,125-4,123c141,15,524,86,641,281 C493,229,162,170,122,163c141,51,245,127,273,197 C340,270,68,139-39,146c139,51,242,127,269,196 C117,195-84,150-84,150L-758,97L-137,104z';
        palm[1]='M-144,304c9-106,334-319,580-175 C236,41-2,150-67,232c52-44,331-195,555-47 c-77-45-241-78-410-5c162-35,344,8,417,70 C307,140,92,197,65,204c12-2,263-42,407,72 c-236-144-520-8-534-1C24,239,273,167,455,301 C270,193,57,257,31,265c107-3,209,27,267,80 C214,284-11,263-65,308c106-3,207,28,264,80 C48,296-87,326-87,326L-533,433L-144,304z';
        palm[2]='M173,299c80-78,288-143,525-156c123-6,235,2,323,22 c11,1,21,2,32,4c-87-30-205-48-339-49c-210-0-400,43-495,107 c84-74,293-128,528-127c217,0,395,47,466,114l435,66 c0,0-500-18-509-26c-175,21-328,81-402,151c56-69,193-132,358-163 c-15-2-30-4-47-5c-22,1-46,2-70,5C796,262,636,324,560,396 c56-70,195-133,362-164c-44,0-91,3-139,8 c-213,23-400,87-490,161c76-82,282-158,521-184 c92-10,179-11,255-5c-0-0-0-0-0-0c-89-14-204-14-330,1 C524,241,338,309,250,384c75-83,280-163,519-193 c21-2,42-4,63-6c-45,1-92,5-141,11c-213,27-400,95-488,170 c75-83,280-163,519-193c26-3,53-6,78-8c-42-1-87-1-133,0 C454,175,265,230,173,299z';
        palm[3]='M1086,14C982-63,415-11,256,269C412,64,785-11,934,9 c-99,0-559,70-690,339c50-88,212-225,474-283 c-221,82-393,240-424,339C415,191,716,89,753,77 c-16,6-344,144-412,334C490,136,941,50,963,47 C832,76,478,189,384,418c120-210,426-305,463-316 c-128,69-220,164-241,245c44-106,289-276,391-277 c-126,69-217,163-237,243c94-175,279-243,279-243l438-99L1086,14z';
        return palm[num-1];
    }
    
    function getGround(uint256 num) internal pure returns (string memory) {
        string[7] memory ground;
        ground[0] = '-30,898,-1357,1016,1298,1016';
        ground[1] = '-11,927,431,952,663,921,845,945,1043,934,1043,1011,-8,1011';
        ground[2] = '-11,927,156,912,222,941,284,931,1043,934,1043,1011,-8,1011';
        ground[3] = '-11,927,425,969,875,952,1046,880,1043,934,1043,1011,-8,1011';
        ground[4] = '-12,962,136,940,239,960,648,966,951,931,1041,938,1043,1011,-8,1011';
        ground[5] = '894,933,722,948,666,900,666,900,664,890,646,890,645,900,482,900,481,890,462,890,461,900,461,900,364,967,247,961,102,946,-9,912,-12,1007,1039,1007,1043,930';
        ground[6] = '800,951,1014,927,1039,1007,-12,1007,-10,940,81,941,175,962,647,927';
        return ground[num-1];
    }
    
    function getSun(uint256 num) internal pure returns (string memory) {
        uint256 suns;

        suns = 712316151692331099684323100692331075717224135713226117576244139582262105;
        if (num > 0)
            suns = suns / (1000 ** (num*3));
        string memory output = string(abi.encodePacked('cx="',toString((suns/1000000)%1000),'" cy="',toString((suns/1000)%1000),  '" r="',toString(suns%1000),'"'));
        
        return output;
    }
    
     function tokenURI(uint256 tokenId) pure public override(ERC721)  returns (string memory) {
        uint256[16] memory xtypes;
        string[4] memory colors;
        string[17] memory parts;
        string[8] memory mount1;
        string[8] memory mount2;
        uint256[8] memory params;
        uint256 pos;

        uint256 rand = random(string(abi.encodePacked('Seasides',toString(tokenId))));

        params[0] = 1 + ((rand/10) % 8);// ship
        params[1] = 1 + (rand/100) % 2; // dir
        params[2] = 1 + ((rand/10000) % 37); // pallette
        params[3] = 1 + ((rand/1000000) % 8); // mounts
        params[4] = 1 + ((rand/100000000) % 6); // grass
        params[5] = 1 + ((rand/1000000000) % 4); // palm
        params[6] = 1 + ((rand/10000000000) % 7); // ground
        params[7] = 1 + ((rand/100000000000) % 4); // sun
        
        mount1[0] = '78,444 -494,478 651,478';
        mount1[1] = '999,392 865,417 806,420 743,451 529,478 1468,478';
        mount1[2] = '463,449 403,457 351,431 177,478 681,478';
        mount1[3] = '1004,457 848,464 760,450 608,455 419,433 320,454 135,409 -8,424 -8,478 1004,478';
        mount1[4] = '226,422 177,414 83,344 -8,367 -12,478 328,478';
        mount1[5] = '999,392 865,417 806,420 743,451 529,478 1468,478';
        mount1[6] = '564,443 463,457 375,478 793,478 721,467 612,414';
        mount1[7] = '1013,420 853,410 732,441 637,431 608,446 390,466 240,457 186,430 94,447 -16,420 -87,478 1016,478';
        
        mount2[0] = '162,392 -307,478 632,478';
        mount2[1] = '';
        mount2[2] = '';
        mount2[3] = '';
        mount2[4] = '991,410 826,454 611,478 1262,478';
        mount2[5] = '';
        mount2[6] = '156,438 47,478 321,478 214,461';
        mount2[7] = '';

        
        xtypes[0] = 5165462586977505248984271025794477445148782908573069521325498340212639;
        xtypes[1] = 490024044101034400102396419179934085738779419751960710510484619019681904;
        xtypes[2] = 4043991994607814950473362577238312297018937036519365143342896853810329;
        xtypes[3] = 1379064599573736476104814799994272434465744258265921437097553789059202;
        xtypes[4] = 6056088629583070600596400423476580059718415009582353316298341503465113;
        xtypes[5] = 138040297937156288773826099078203347749133755730926697092887565253488215;
        xtypes[6] = 1763486549546207954426324916291393168705773800679768336312337964145309337;
        xtypes[7] = 948653233183009513098268805292360185252612190882203913941189109236825;
        xtypes[8] = 1765596160030049122294337924707755907300568572202546387173451426705702110;
        xtypes[9] = 571213962168160818623884462797953331024439701527741670201332697661529;
        xtypes[10] = 1759945423641250114310949500884067660757318022344968985317724270290468863;
        xtypes[11] = 634962523324887909409742165431514640856016078396772822011217464449368064;
        xtypes[12] = 1318233657466206738337996551415773989873200879281323137549919882303230302;
        xtypes[13] = 20786449684869734852663949139680728584860474635680334261919687729872949;
        xtypes[14] = 321076936879265745525548114627410433723373509773187045336;
    
        pos = (params[2]-1) * 4;
        colors[0] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
    
        pos = (params[2]-1) * 4 + 1;
        colors[1] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        
        pos = (params[2]-1) * 4 + 2;
        colors[2] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        
        pos = (params[2]-1) * 4 + 3;
        colors[3] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        


parts[0] = '<svg width="1000px" height="1000px" viewBox="0 0 1000 1000" version="1.1" xmlns="http://www.w3.org/2000/svg"> <linearGradient id="SkyGradient" gradientUnits="userSpaceOnUse" x1="500.001" y1="999.8105" x2="500.0009" y2="4.882813e-004"> <stop offset="0.5604" style="stop-color:#'; // 2
parts[1] = '"/> <stop offset="1" style="stop-color:#'; // 3
parts[2] = '"/> </linearGradient> <rect x="0.001" fill="url(#SkyGradient)" width="1000" height="999.811"/> <polygon opacity="0.15" fill="#'; // 3
parts[3] = string(abi.encodePacked('" points="',mount2[params[3]-1],'"/> <polygon opacity="0.1" fill="#')); // 3
parts[4] = string(abi.encodePacked('" points="',mount1[params[3]-1],'"/> <rect x="0" y="478" opacity="0.2" fill="#')); // 3
parts[5] = '" width="1000" height="734.531"/> <rect x="0" y="563.156" opacity="0.3" fill="#'; // 3
parts[6] = '" width="1000" height="649.315"/> <g> <path xmlns="http://www.w3.org/2000/svg" opacity="0.55" fill="#'; // 3
parts[7] = '" d="M8087,687c-158,0-320-3.15-469-3 c-293,0-616,10-701,10c-261,0-600-17-809-17 c-118,0-246,11-376,11c-158,0-320-10-469-10 c-293,0-379,10-574,10c-195,0-331-11-540-11 c-118,0-246,11-376,11c-158,0-320-10-469-10 c-293,0-616,17-701,17c-261,0-600-12-809-12 c-118,0-246,12-376,12c-103,0-263-9-469-9 c-92,0-181,2-260,2c-171,0-304,0-362,0c-261,0-330-0-330-0 v525l9053-6V688C9039,688,8217,687,8087,687z"/> <animateMotion path="M 0 0 L -8050 20 Z" dur="70s" repeatCount="indefinite" /> </g> <g> <path xmlns="http://www.w3.org/2000/svg" fill="#'; // 3
parts[8] = '" d="M8097,846c-158,0-319-7-470-7c-285,0-443,20-651,20 c-172,0-353-5-449-9c-101-4-247-20-413-20c-116,0-243,26-373,26 c-158,0-320-31-471-31c-285,0-352,36-560,36c-172,0-390-31-556-31 c-116,0-243,26-373,26c-158,0-320-31-471-31c-285,0-442,35-650,35 c-172,0-353-5-449-9c-101-4-247-20-413-20c-116,0-245,25-375,25 c-158,0-322-13-474-13c-107,0-197,2-277,3c-133,1-243,0-372,0 c-172,0-308-0-308-0v364h9053V846C9038,846,8227,846,8097,846z"/> <animateMotion path="M 0 0 L -8050 40 Z" dur="70s" repeatCount="indefinite" /> </g> <g> <polygon fill="#'; // 3
parts[9] =  string(abi.encodePacked('" points="',getShip(params[0],params[1],0), '"/> <polygon opacity="0.2" fill="#')); // 3
parts[10] = string(abi.encodePacked('" points="',getShip(params[0],params[1],1),'"/> <animateMotion path="m 0 0 h ',(params[1]==1 ? '':'-'),'5000" dur="1500s" repeatCount="indefinite" /> </g> <radialGradient id="SunGradient" ',getSun(params[7]*2-2),' gradientUnits="userSpaceOnUse"> <stop offset="0.7604" style="stop-color:#')); // 1
parts[11] = '"/> <stop offset="0.9812" style="stop-color:#'; // 2
parts[12] = '"/> </radialGradient> <circle opacity="0.1" fill="#'; // 2
parts[13] = string(abi.encodePacked('" ',getSun(params[7]*2-1),'/> <circle fill="url(#SunGradient)" ',getSun(params[7]*2-2),'/> <g> <polygon fill="#')); // 4
parts[14] = string(abi.encodePacked('" points="',getGrass(params[4]/3+1, params[4]%2),'"/> <animateMotion path="M 0 0 H 10 Z" dur="4s" repeatCount="indefinite" /> </g> <g> <path fill="#',colors[3],'" d="',getPalm(params[5]),'"/> <animateMotion path="M 0 0 H 15 Z" dur="5s" repeatCount="indefinite"/> </g> <polygon fill="#')); // 4
parts[15] = '" points="';
parts[16] = '"/></svg> ';



        string memory output = string(abi.encodePacked(parts[0],colors[1],parts[1],colors[2]));
         output = string(abi.encodePacked(output,parts[2],colors[2],parts[3] ));
         output = string(abi.encodePacked(output,colors[2],parts[4],colors[2] ));
         output = string(abi.encodePacked(output,parts[5],colors[2],parts[6] ));
         output = string(abi.encodePacked(output,colors[2],parts[7],colors[2] ));
         output = string(abi.encodePacked(output,parts[8],colors[2],parts[9] ));
         output = string(abi.encodePacked(output,colors[2],parts[10],colors[0] ));
         output = string(abi.encodePacked(output,parts[11],colors[1],parts[12] ));
         output = string(abi.encodePacked(output,colors[1],parts[13],colors[3] ));
         output = string(abi.encodePacked(output,parts[14],colors[3],parts[15]));
         output = string(abi.encodePacked(output,getGround(params[6]), parts[16]));

        string[11] memory aparts;
        aparts[0] = '[{ "trait_type": "Ship", "value": "';
        aparts[1] = toString(params[0]);
        aparts[2] = '" }, { "trait_type": "Palette", "value": "';
        aparts[3] = toString(params[2]);
        aparts[4] = '" }, { "trait_type": "Hills", "value": "';
        aparts[5] = toString(params[3]);
        aparts[6] = '" }, { "trait_type": "Sun", "value": "';
        aparts[7] = toString(params[7]);
        aparts[8] = '" }, { "trait_type": "Coast", "value": "';
        aparts[9] = toString(params[6]);
        aparts[10] = '" }]';
        
        string memory strparams = string(abi.encodePacked(aparts[0], aparts[1], aparts[2], aparts[3], aparts[4], aparts[5]));
        strparams = string(abi.encodePacked(strparams, aparts[6], aparts[7], aparts[8], aparts[9], aparts[10]));



        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "OnChain Seaside", "description": "Beautiful views, completely generated OnChain","attributes":', strparams, ', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
    function claim() public  {
        require(_tokenIdCounter.current() <= 333, "Tokens number to mint exceeds number of public tokens");
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();

    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function buySunsets(uint tokensNumber) public payable {
        require(tokensNumber > 0, "Wrong amount");
        require(tokensNumber <= maxTokensPerTransaction, "Max tokens per transaction number exceeded");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "Tokens number to mint exceeds number of public tokens");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Ether value sent is too low");

        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    
}




/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}