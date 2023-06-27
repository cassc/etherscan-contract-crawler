// SPDX-License-Identifier: MIT

/*
    B L I T B L 0 x
    L \           L \
    I   B L I T B L 0 x
    T   L         T   L
    B   I    <3   B   I
    L   T         L   T
    0   B         0   B
    B L L T B L 0 x   L
      \ 0           \ 0
        B L I T B L 0 x
    
    Blitblox
    by sayangel.eth
    Derivative project for Blitmap and Flipmap.
    Experimenting with 3D glTF on chain.
*/
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./IBlitmap.sol";
import "./IFlipmap.sol";

contract Blitblox is ERC721, Ownable, ReentrancyGuard {
    struct glTFCursor {
        uint8 x;
        uint8 y;
        uint256 color1;
        uint256 color2;
        uint256 color3;
        uint256 color4;
    }

    uint256 private constant PRECISION_MULTIPLIER = 1000;

    uint256 private _mintPrice = 0.02 ether;
    
    string private _proxyUri;

    mapping(uint256 => bytes1) private _tokenStyles;

    mapping(address => uint256) private _creators;

    IFlipmap flipmap;
    IBlitmap blitmap;

    modifier onlyCreators() {
        require(isCreator(msg.sender));
        _;
    }

    constructor(address _blitAddress, address _flipAddress) ERC721("Blitblox", "BX") Ownable() {
        blitmap = IBlitmap(_blitAddress);
        flipmap = IFlipmap(_flipAddress);
    }

    function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
        //wrap the original SVG in an anaglyph style filter
        string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 32 32"><filter id="i1" width="150%" height="150%"><feOffset result="offOut" in="SourceGraphic" dx="1" dy="0"/><feOffset result="off2Out" in="SourceGraphic" dx="-1" dy="0"/><feColorMatrix result="matrixOut" in="offOut" type="matrix" values="0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0.4 0"/><feColorMatrix result="matrix2Out" in="off2Out" type="matrix" values="1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.4 0"/><feBlend result="blend1" in="matrix2Out" in2="SourceGraphic" mode="normal"/><feBlend in="matrixOut" in2="blend1" mode="normal"/></filter><g filter="url(#i1)"><image width="100%" height="100%" href="data:image/svg+xml;base64,';
        
        if(tokenId < 1700)
            svg = string(abi.encodePacked(svg, Base64.encode(bytes(blitmap.tokenSvgDataOf(tokenId)))));
        else
            svg = string(abi.encodePacked(svg, Base64.encode(bytes(flipmap.tokenSvgDataOf(tokenId)))));
        
        svg = string(abi.encodePacked(svg, '"/></g></svg>'));
        svg = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(svg))));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Blitblox #', Strings.toString(tokenId), '", "description": "Blitblox is a derivative project of Blitmap and Flipmap. It generates a three dimensional voxel version of the corresponding map. All 3D data is generated and stored on chain as a glTF.", "image":"', svg, '","animation_url":"', _proxyUri, Strings.toString(tokenId),'.glb"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    /*  
    *   As of Jan 2022 OS and other platforms with glTF support expect a glb via HTTP response.
    *   hack around this by returning the contract response via an HTTP proxy that 
    *   calls tokenGltfDataOf() and returns response.
    */
    function setProxyUri(string memory proxyUri) public onlyOwner {
        _proxyUri = proxyUri;
    }

    function mint(uint256 tokenId, bytes1 style) external payable nonReentrant {
        require(_mintPrice == msg.value);

        if(tokenId < 1700)
            require(blitmap.ownerOf(tokenId) == msg.sender);
        else
            require(flipmap.ownerOf(tokenId) == msg.sender);

        address creatorA = owner();
        address creatorB = owner();

        //artist gets full royalties on original
        if(tokenId < 100) { 
            creatorA = blitmap.tokenCreatorOf(tokenId);
            creatorB = blitmap.tokenCreatorOf(tokenId);
        }

        //siblings and flipmaps divide royalties between composition and pallette artist
        if(tokenId > 99) { 
            uint256 tokenIdA;
            uint256 tokenIdB;
            if(tokenId < 1700 ){
                (tokenIdA, tokenIdB) = blitmap.tokenParentsOf(tokenId);
            }
            else 
                (tokenIdA, tokenIdB) = flipmap.tokenParentsOf(tokenId);

            creatorA = blitmap.tokenCreatorOf(tokenIdA);
            creatorB = blitmap.tokenCreatorOf(tokenIdB);
        }

        _tokenStyles[tokenId] = style;
        _safeMint(msg.sender, tokenId);

        // 25% royalty to original artists. 
        // of that, 75% to composition artist and 25% to palette artist.
        _creators[creatorA]     +=  0.00375 ether;
        _creators[creatorB]     += 0.00125 ether;
        _creators[owner()]      += 0.015 ether;
    }

    function isCreator(address _address) public view returns (bool) {
        return _creators[_address] > 0;
    }

    function availableBalanceForCreator(address creatorAddress) public view returns (uint256) {
        return _creators[creatorAddress];
    }

    function withdrawAvailableBalance() public nonReentrant onlyCreators {
        uint256 withdrawAmount = _creators[msg.sender];
        _creators[msg.sender] = 0;
        payable(msg.sender).transfer(withdrawAmount);
    }

    function voxel4(string[32] memory lookup, glTFCursor memory pos) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '{"mesh":', Strings.toString(pos.color1), ',"translation": [', lookup[pos.x], ', 0.0,', lookup[31 - pos.y],']},',
            '{"mesh":', Strings.toString(pos.color2), ',"translation": [', lookup[pos.x + 1], ', 0.0,', lookup[31 - pos.y],']},',

            string(abi.encodePacked(
                '{"mesh":', Strings.toString(pos.color3), ',"translation": [', lookup[pos.x + 2], ', 0.0,', lookup[31 - pos.y],']},',
                '{"mesh":', Strings.toString(pos.color4), ',"translation": [', lookup[pos.x + 3], ', 0.0,', lookup[31- pos.y],']}'
            ))
        )) ;
    }

    function bitTest(bytes1 aByte, uint8 index) internal pure returns (bool) {
        return uint8(aByte) >> index & 1 == 1;
    }

    function colorIndex(bytes1 aByte, uint8 index1, uint8 index2) internal pure returns (uint) {
        if (bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 3;
        } else if (bitTest(aByte, index2) && !bitTest(aByte, index1)) {
            return 2;
        } else if (!bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 1;
        }
        return 0;
    }

    function styleByteToInts(bytes1 style) internal pure returns (uint8, uint8) {
        /* 
        *   decode the style of a given token.
        *    first 4 bits  represent the voxel style:
        *        0 - normal
        *        1 - normal with transparency
        *        2 - exploded
        *        3 - exploded with transparency
        *    last 4 bits represent the color index to apply transparency to. Value between 0-3.
        */

        return (uint8(style >> 4), uint8(style & hex"0F"));
    }

    /*function setTokenStyle(uint256 tokenId, bytes1 style) public {
        require(ownerOf(tokenId) == msg.sender, "This wallet does not own this Blitblox."); 
        _tokenStyles[tokenId] = style;
    }

    function getTokenStyle (uint256 tokenId) public view returns (uint8, uint8) {
        return styleByteToInts(_tokenStyles[tokenId]);
    }*/

    //returns an approximation of the original RGB value in sRGB color space. 
    function intRGBValTosRGBVal(uint256 val) internal pure returns (string memory result) {
        uint256 res = (val * PRECISION_MULTIPLIER) * (PRECISION_MULTIPLIER * PRECISION_MULTIPLIER) / (255 * PRECISION_MULTIPLIER);
        res = (res ** 2)/( PRECISION_MULTIPLIER * PRECISION_MULTIPLIER);
        string memory sRGBString = string( abi.encodePacked(bytes(Strings.toString(uint(res/( PRECISION_MULTIPLIER * PRECISION_MULTIPLIER)))), bytes(".")));   
        sRGBString = string(abi.encodePacked(sRGBString, bytes( Strings.toString( res % ( PRECISION_MULTIPLIER * PRECISION_MULTIPLIER) / 100000 ) ) ) );
        sRGBString = string(abi.encodePacked(sRGBString, bytes( Strings.toString( res % ( PRECISION_MULTIPLIER * PRECISION_MULTIPLIER / 10) / 10000 ) ) ) );
        sRGBString = string(abi.encodePacked(sRGBString, bytes( Strings.toString( res % ( PRECISION_MULTIPLIER * PRECISION_MULTIPLIER / 100) / 1000 ) ) ) );
        return sRGBString;
    }

    function tokenGltfDataOf(uint256 tokenId) public view returns (string memory) {
        bytes memory data;
        if(tokenId < 1700 ) {
            data = blitmap.tokenDataOf(tokenId);
        }
        else {
            data = flipmap.tokenDataOf(tokenId);
        }
        return tokenGltfData(data, _tokenStyles[tokenId]);
    }

    /*
    *   glTF data built from blitmap/flipmap token data. Just like original SVGs data is built in chunks of 4 voxels at a time.
    *   The output is a 32 x 32 grid of voxels. Each voxel is a node in the scene that references 1 of 4 meshes depending on its color. 
    *   There are 4 mesh primitives with the only difference being material index. There is only one mesh buffer: a voxel/cube. 
    *   Voxel spacing and material transparency are affected by the tokens saved style.
    */
    function tokenGltfData(bytes memory data, bytes1 style) public pure returns (string memory) {
        (uint8 voxelStyle, uint8 transparencyIndex) = styleByteToInts(style);

        string[32] memory lookup = [
        "0", "1", "2", "3", "4", "5", "6", "7",
        "8", "9", "10", "11", "12", "13", "14", "15",
        "16", "17", "18", "19", "20", "21", "22", "23",
        "24", "25", "26", "27", "28", "29", "30", "31"
        ];

        glTFCursor memory pos;

        uint256[3][4] memory colors = [
        [byteToUint(data[0]), byteToUint(data[1]), byteToUint(data[2])],
        [byteToUint(data[3]), byteToUint(data[4]), byteToUint(data[5])],
        [byteToUint(data[6]), byteToUint(data[7]), byteToUint(data[8])],
        [byteToUint(data[9]), byteToUint(data[10]), byteToUint(data[11])]
        ];

        string[8] memory p;

        string memory gltfAccumulator = '{"asset": {"generator": "Blitblox.sol","version": "2.0"},"scene": 0,"scenes": [{"nodes": [0]}],';
        gltfAccumulator = strConcat(gltfAccumulator, '"nodes": [{"children": [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,303,304,305,306,307,308,309,310,311,312,313,314,315,316,317,318,319,320,321,322,323,324,325,326,327,328,329,330,331,332,333,334,335,336,337,338,339,340,341,342,343,344,345,346,347,348,349,350,351,352,353,354,355,356,357,358,359,360,361,362,363,364,365,366,367,368,369,370,371,372,373,374,375,376,377,378,379,380,381,382,383,384,385,386,387,388,389,390,391,392,393,394,395,396,397,398,399,400,401,402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,417,418,419,420,421,422,423,424,425,426,427,428,429,430,431,432,433,434,435,436,437,438,439,440,441,442,443,444,445,446,447,448,449,450,451,452,453,454,455,456,457,458,459,460,461,462,463,464,465,466,467,468,469,470,471,472,473,474,475,476,477,478,479,480,481,482,483,484,485,486,487,488,489,490,491,492,493,494,495,496,497,498,499,500,501,502,503,504,505,506,507,508,509,510,511,512,513,514,515,516,517,518,519,520,521,522,523,524,525,526,527,528,529,530,531,532,533,534,535,536,537,538,539,540,541,542,543,544,545,546,547,548,549,550,551,552,553,554,555,556,557,558,559,560,561,562,563,564,565,566,567,568,569,570,571,572,573,574,575,576,577,578,579,580,581,582,583,584,585,586,587,588,589,590,591,592,593,594,595,596,597,598,599,600,601,602,603,604,605,606,607,608,609,610,611,612,613,614,615,616,617,618,619,620,621,622,623,624,625,626,627,628,629,630,631,632,633,634,635,636,637,638,639,640,641,642,643,644,645,646,647,648,649,650,651,652,653,654,655,656,657,658,659,660,661,662,663,664,665,666,667,668,669,670,671,672,673,674,675,676,677,678,679,680,681,682,683,684,685,686,687,688,689,690,691,692,693,694,695,696,697,698,699,700,701,702,703,704,705,706,707,708,709,710,711,712,713,714,715,716,717,718,719,720,721,722,723,724,725,726,727,728,729,730,731,732,733,734,735,736,737,738,739,740,741,742,743,744,745,746,747,748,749,750,751,752,753,754,755,756,757,758,759,760,761,762,763,764,765,766,767,768,769,770,771,772,773,774,775,776,777,778,779,780,781,782,783,784,785,786,787,788,789,790,791,792,793,794,795,796,797,798,799,800,801,802,803,804,805,806,807,808,809,810,811,812,813,814,815,816,817,818,819,820,821,822,823,824,825,826,827,828,829,830,831,832,833,834,835,836,837,838,839,840,841,842,843,844,845,846,847,848,849,850,851,852,853,854,855,856,857,858,859,860,861,862,863,864,865,866,867,868,869,870,871,872,873,874,875,876,877,878,879,880,881,882,883,884,885,886,887,888,889,890,891,892,893,894,895,896,897,898,899,900,901,902,903,904,905,906,907,908,909,910,911,912,913,914,915,916,917,918,919,920,921,922,923,924,925,926,927,928,929,930,931,932,933,934,935,936,937,938,939,940,941,942,943,944,945,946,947,948,949,950,951,952,953,954,955,956,957,958,959,960,961,962,963,964,965,966,967,968,969,970,971,972,973,974,975,976,977,978,979,980,981,982,983,984,985,986,987,988,989,990,991,992,993,994,995,996,997,998,999,1000,1001,1002,1003,1004,1005,1006,1007,1008,1009,1010,1011,1012,1013,1014,1015,1016,1017,1018,1019,1020,1021,1022,1023,1024],');
        gltfAccumulator = strConcat(gltfAccumulator, '"matrix": [1.0,0.0,0.0,0.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,0.0,1.0]},');
        for (uint i = 12; i < 268; i += 8) {
            pos.color1 =  colorIndex(data[i], 6, 7);
            pos.color2 =  colorIndex(data[i], 4, 5);
            pos.color3 =  colorIndex(data[i], 2, 3);
            pos.color4 =  colorIndex(data[i], 0, 1);
            p[0] = voxel4(lookup, pos);
            p[0] = strConcat(p[0], ',');
            pos.x += 4;
            
            pos.color1 =  colorIndex(data[i + 1], 6, 7);
            pos.color2 =  colorIndex(data[i + 1], 4, 5);
            pos.color3 =  colorIndex(data[i + 1], 2, 3);
            pos.color4 =  colorIndex(data[i + 1], 0, 1);
            p[1] = voxel4(lookup, pos);
            p[1] = strConcat(p[1], ',');
            pos.x += 4;
            
            pos.color1 =  colorIndex(data[i + 2], 6, 7);
            pos.color2 =  colorIndex(data[i + 2], 4, 5);
            pos.color3 =  colorIndex(data[i + 2], 2, 3);
            pos.color4 =  colorIndex(data[i + 2], 0, 1);
            p[2] = voxel4(lookup, pos);
            p[2] = strConcat(p[2], ',');
            pos.x += 4;
            
            pos.color1 =  colorIndex(data[i + 3], 6, 7);
            pos.color2 =  colorIndex(data[i + 3], 4, 5);
            pos.color3 =  colorIndex(data[i + 3], 2, 3);
            pos.color4 =  colorIndex(data[i + 3], 0, 1);
            p[3] = voxel4(lookup, pos);
            p[3] = strConcat(p[3], ',');
            pos.x += 4;
            
            pos.color1 =  colorIndex(data[i + 4], 6, 7);
            pos.color2 =  colorIndex(data[i + 4], 4, 5);
            pos.color3 =  colorIndex(data[i + 4], 2, 3);
            pos.color4 =  colorIndex(data[i + 4], 0, 1);
            p[4] = voxel4(lookup, pos);
            p[4] = strConcat(p[4], ',');
            pos.x += 4;
            
            pos.color1 =  colorIndex(data[i + 5], 6, 7);
            pos.color2 =  colorIndex(data[i + 5], 4, 5);
            pos.color3 =  colorIndex(data[i + 5], 2, 3);
            pos.color4 =  colorIndex(data[i + 5], 0, 1);
            p[5] = voxel4(lookup, pos);
            p[5] = strConcat(p[5], ',');
            pos.x += 4;
            
            pos.color1 =  colorIndex(data[i + 6], 6, 7);
            pos.color2 =  colorIndex(data[i + 6], 4, 5);
            pos.color3 =  colorIndex(data[i + 6], 2, 3);
            pos.color4 =  colorIndex(data[i + 6], 0, 1);
            p[6] = voxel4(lookup, pos);
            p[6] = strConcat(p[6], ',');
            pos.x += 4;
            
            pos.color1 =  colorIndex(data[i + 7], 6, 7);
            pos.color2 =  colorIndex(data[i + 7], 4, 5);
            pos.color3 =  colorIndex(data[i + 7], 2, 3);
            pos.color4 =  colorIndex(data[i + 7], 0, 1);
            p[7] = voxel4(lookup, pos);
            if(i + 9 < 268){
                p[7] = strConcat(p[7], ',');
            }
            pos.x += 4;
            
            gltfAccumulator = string(abi.encodePacked(gltfAccumulator, p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]));
            
            if (pos.x >= 32) {
                pos.x = 0;
                pos.y += 1;
            }
        }
        gltfAccumulator = strConcat(gltfAccumulator, '],');
        gltfAccumulator = strConcat(gltfAccumulator, '"materials": [');
        for(uint i=0; i < colors.length; i++){
            gltfAccumulator = strConcat(gltfAccumulator,'{"pbrMetallicRoughness": {"baseColorFactor": [');
            gltfAccumulator = string( abi.encodePacked(bytes(gltfAccumulator), bytes(intRGBValTosRGBVal(colors[i][0])), bytes(",") ));
            gltfAccumulator = string( abi.encodePacked(bytes(gltfAccumulator), bytes(intRGBValTosRGBVal(colors[i][1])), bytes(",") ));
            gltfAccumulator = string( abi.encodePacked(bytes(gltfAccumulator), bytes(intRGBValTosRGBVal(colors[i][2])), bytes(",") ));
            if(voxelStyle % 2 == 1 && i == transparencyIndex) {
                gltfAccumulator = string( abi.encodePacked(bytes(gltfAccumulator), bytes("0.5")));
            }
            else {
                gltfAccumulator = string( abi.encodePacked(bytes(gltfAccumulator), bytes("1.0")));
            }
            gltfAccumulator = strConcat(gltfAccumulator,'],"metallicFactor": 0.0},');
            if(voxelStyle % 2 == 1 && i == transparencyIndex) {
                gltfAccumulator = strConcat(gltfAccumulator, '"alphaMode": "BLEND",');
            }
            gltfAccumulator = strConcat(gltfAccumulator, '"name": "material"}');
            if(i + 1 < colors.length ){
                gltfAccumulator = strConcat(gltfAccumulator, ',');
            }
        }
        gltfAccumulator = strConcat(gltfAccumulator,'],');
        gltfAccumulator = strConcat(gltfAccumulator, '"meshes": [');
        for(uint i=0; i < colors.length; i++){
            gltfAccumulator = strConcat(gltfAccumulator,'{"primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1},"indices": 2,"material": ');
            gltfAccumulator = strConcat(gltfAccumulator, Strings.toString(i));
            gltfAccumulator = strConcat(gltfAccumulator,'}],"name": "Mesh');
            gltfAccumulator = strConcat(gltfAccumulator, Strings.toString(i));
            gltfAccumulator = strConcat(gltfAccumulator,'"}');
            if(i + 1 < colors.length ){
                gltfAccumulator = strConcat(gltfAccumulator, ',');
            }
        }

        gltfAccumulator = strConcat(gltfAccumulator,'],');
        gltfAccumulator = strConcat(gltfAccumulator, '"accessors": [');
        gltfAccumulator = strConcat(gltfAccumulator, '{"bufferView" : 0,"componentType" : 5126,"count" : 24,"max" : [0.5,0.5,0.5],"min" : [-0.5,-0.5,-0.5],"type" : "VEC3"},');
        gltfAccumulator = strConcat(gltfAccumulator, '{"bufferView" : 1,"componentType" : 5126,"count" : 24,"type" : "VEC3"},');
        gltfAccumulator = strConcat(gltfAccumulator, '{"bufferView" : 2,"componentType" : 5123,"count" : 36,"type" : "SCALAR"}');
        gltfAccumulator = strConcat(gltfAccumulator, '],');
        gltfAccumulator = strConcat(gltfAccumulator, '"bufferViews": [');
        gltfAccumulator = strConcat(gltfAccumulator, '{"buffer" : 0,"byteLength" : 288,"byteOffset" : 0},');
        gltfAccumulator = strConcat(gltfAccumulator, '{"buffer" : 0,"byteLength" : 288,"byteOffset" : 288},');
        gltfAccumulator = strConcat(gltfAccumulator, '{"buffer" : 0,"byteLength" : 72,"byteOffset" : 576}');
        gltfAccumulator = strConcat(gltfAccumulator, '],');
        gltfAccumulator = strConcat(gltfAccumulator, '"buffers": [{"byteLength": 648,"uri": "data:application/octet-stream;base64,');

        //the strings below are the buffers for a voxel's vertex data.
        //every node refers to a mesh described by this same buffer.
        //initially I had a single buffer and applied a scale transform to every node depdnding on style
        //but this was inefficient and caused a 4x bigger payload and longer execution time.
        //when the "exploded" style is chosen the buffer is modified to be a smaller voxel.
        //index and normal buffers are the same regardless of style.
        if(voxelStyle < 2){
            gltfAccumulator = strConcat(gltfAccumulator, 'AAAAvwAAAL8AAAA/AAAAPwAAAL8AAAA/AAAAvwAAAD8AAAA/AAAAPwAAAD8AAAA/AAAAPwAAAL8AAAA/AAAAvwAAAL8AAAA/AAAAPwAAAL8AAAC/AAAAvwAAAL8AAAC/AAAAPwAAAD8AAAA/AAAAPwAAAL8AAAA/AAAAPwAAAD8AAAC/AAAAPwAAAL8AAAC/AAAAvwAAAD8AAAA/AAAAPwAAAD8AAAA/AAAAvwAAAD8AAAC/AAAAPwAAAD8AAAC/AAAAvwAAAL8AAAA/AAAAvwAAAD8AAAA/AAAAvwAAAL8AAAC/AAAAvwAAAD8AAAC/AAAAvwAAAL8AAAC/AAAAvwAAAD8AAAC/AAAAPwAAAL8AAAC/AAAAPwAAAD8AAAC/');
        } else {
            gltfAccumulator = strConcat(gltfAccumulator, 'AADAvgAAwL4AAMA+AADAPgAAwL4AAMA+AADAvgAAwD4AAMA+AADAPgAAwD4AAMA+AADAPgAAwL4AAMA+AADAvgAAwL4AAMA+AADAPgAAwL4AAMC+AADAvgAAwL4AAMC+AADAPgAAwD4AAMA+AADAPgAAwL4AAMA+AADAPgAAwD4AAMC+AADAPgAAwL4AAMC+AADAvgAAwD4AAMA+AADAPgAAwD4AAMA+AADAvgAAwD4AAMC+AADAPgAAwD4AAMC+AADAvgAAwL4AAMA+AADAvgAAwD4AAMA+AADAvgAAwL4AAMC+AADAvgAAwD4AAMC+AADAvgAAwL4AAMC+AADAvgAAwD4AAMC+AADAPgAAwL4AAMC+AADAPgAAwD4AAMC+');
        }
        gltfAccumulator = strConcat(gltfAccumulator, 'AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAgL8AAACAAAAAAAAAgL8AAACAAAAAAAAAgL8AAACAAAAAAAAAgL8AAACAAACAPwAAAAAAAACAAACAPwAAAAAAAACAAACAPwAAAAAAAACAAACAPwAAAAAAAACAAAAAAAAAgD8AAACAAAAAAAAAgD8AAACAAAAAAAAAgD8AAACAAAAAAAAAgD8AAACAAACAvwAAAAAAAACAAACAvwAAAAAAAACAAACAvwAAAAAAAACAAACAvwAAAAAAAACAAAAAAAAAAAAAAIC/AAAAAAAAAAAAAIC/AAAAAAAAAAAAAIC/AAAAAAAAAAAAAIC/AAABAAIAAwACAAEABAAFAAYABwAGAAUACAAJAAoACwAKAAkADAANAA4ADwAOAA0AEAARABIAEwASABEAFAAVABYAFwAWABUA"}]');
        gltfAccumulator = strConcat(gltfAccumulator, '}');
        return gltfAccumulator;
    }

    function byteToUint(bytes1 b) internal pure returns (uint256) {
        return uint256(uint8(b));
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory result) {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
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