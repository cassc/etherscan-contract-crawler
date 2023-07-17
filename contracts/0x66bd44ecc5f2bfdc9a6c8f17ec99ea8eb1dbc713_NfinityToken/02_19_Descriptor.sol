// SPDX-License-Identifier: GPL-3.0

/*
             ░┴W░
             ▒m▓░
           ╔▄   "╕
         ╓▓╣██,   '
       ,▄█▄▒▓██▄    >
      é╣▒▒▀███▓██▄
     ▓▒▒▒▒▒▒███▓███         ███╗   ██╗███████╗████████╗    ██╗███╗   ██╗███████╗██╗███╗   ██╗██╗████████╗██╗   ██╗
  ,╢▓▀███▒▒▒██▓██████       ████╗  ██║██╔════╝╚══██╔══╝    ██║████╗  ██║██╔════╝██║████╗  ██║██║╚══██╔══╝╚██╗ ██╔╝
 @╢╢Ñ▒╢▒▀▀▓▓▓▓▓██▓████▄     ██╔██╗ ██║█████╗     ██║       ██║██╔██╗ ██║█████╗  ██║██╔██╗ ██║██║   ██║    ╚████╔╝
╙▓╢╢╢╢╣Ñ▒▒▒▒██▓███████▀▀    ██║╚██╗██║██╔══╝     ██║       ██║██║╚██╗██║██╔══╝  ██║██║╚██╗██║██║   ██║     ╚██╔╝
   "╩▓╢╢╢╣╣▒███████▀▀       ██║ ╚████║██║        ██║       ██║██║ ╚████║██║     ██║██║ ╚████║██║   ██║      ██║
      `╨▓╢╢╢████▀           ╚═╝  ╚═══╝╚═╝        ╚═╝       ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝      ╚═╝
          ╙▓█▀

*/


pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import "./IDescriptor.sol";
import {Tools} from "./Tools.sol";

contract Descriptor is Ownable {
    string[] rarityNames = ["Common", "Uncommon", "Rare", "Epic", "Legendary"];


    uint8[2][] nodesOfLevel = [
    [3, 4],
    [3, 5],
    [4, 6],
    [5, 7],
    [6, 11]
    ];

    uint8[2][5] bgColorIndexOfRarity = [
    [6, 7],
    [3, 5],
    [1, 1],
    [2, 2],
    [0, 0]
    ];

    uint16[4][] team1Regions = [
    [229, 305, 572, 377], // front court
    [222, 359, 581, 428], //
    [218, 424, 582, 514], // midfield
    [213, 513, 586, 586], //
    [202, 573, 599, 655], // backfield
    [333, 636, 467, 690], // freethrow lane
    [364, 710, 437, 710]  // door
    ];

    uint16[4][] team2Regions = [
    [202, 573, 599, 655], // front court
    [213, 513, 586, 586], //
    [218, 424, 582, 514], // midfield
    [222, 359, 581, 428], //
    [229, 305, 572, 377], // backfield
    [344, 281, 458, 327], // freethrow lane
    [365, 250, 436, 250]  // door
    ];

    uint16[2][11][2][] teamFormations = [
    [
    [[358, 653], [248, 532], [313, 523], [396, 532], [499, 578], [577, 527], [315, 491], [401, 429], [562, 427], [298, 383], [480, 404]],
    [[397, 294], [285, 360], [456, 336], [369, 381], [551, 410], [273, 464], [574, 470], [231, 540], [524, 583], [281, 576], [419, 596]]],
    [[[360, 672], [221, 518], [339, 533], [416, 570], [565, 532], [225, 496], [436, 443], [535, 426], [228, 394], [454, 412], [565, 387]],
    [[439, 308], [301, 343], [455, 325], [376, 372], [520, 361], [305, 434], [504, 492], [229, 562], [404, 569], [370, 595], [409, 609]]],
    [[[383, 647], [259, 522], [336, 514], [398, 532], [464, 524], [518, 520], [218, 441], [374, 442], [472, 507], [306, 361], [521, 415]],
    [[406, 317], [253, 376], [375, 335], [455, 359], [535, 327], [379, 439], [525, 482], [346, 540], [441, 529], [205, 618], [563, 610]]],
    [[[412, 689], [214, 617], [308, 594], [417, 643], [563, 653], [229, 447], [515, 489], [352, 369], [482, 421], [322, 342], [508, 354]],
    [[361, 313], [233, 382], [357, 394], [387, 360], [488, 383], [519, 422], [282, 460], [350, 456], [543, 445], [263, 582], [506, 583]]],
    [[[351, 666], [238, 605], [302, 600], [485, 576], [592, 605], [228, 450], [398, 476], [486, 469], [267, 310], [365, 315], [550, 311]],
    [[452, 321], [376, 350], [485, 352], [241, 371], [354, 419], [483, 400], [250, 463], [561, 435], [273, 585], [535, 516], [377, 586]]],
    [[[401, 675], [249, 578], [330, 625], [492, 608], [507, 621], [223, 483], [516, 510], [308, 365], [567, 361], [359, 317], [494, 362]],
    [[389, 302], [284, 319], [563, 345], [236, 399], [356, 359], [528, 362], [267, 473], [511, 473], [318, 547], [433, 538], [598, 602]]],
    [[[372, 660], [278, 544], [338, 572], [443, 527], [513, 570], [371, 430], [470, 485], [300, 404], [267, 363], [368, 333], [512, 315]],
    [[433, 311], [233, 336], [361, 319], [440, 352], [526, 358], [261, 510], [414, 430], [556, 450], [293, 616], [407, 651], [468, 619]]],
    [[[338, 689], [268, 615], [419, 621], [323, 515], [456, 521], [579, 536], [227, 490], [360, 469], [484, 436], [288, 424], [579, 370]],
    [[429, 285], [294, 370], [567, 326], [277, 425], [441, 396], [529, 389], [294, 493], [407, 485], [474, 497], [249, 549], [557, 585]]],
    [[[434, 640], [220, 603], [382, 625], [415, 647], [555, 636], [255, 430], [579, 502], [389, 378], [565, 398], [322, 342], [431, 334]],
    [[352, 325], [227, 408], [398, 379], [444, 388], [495, 369], [240, 513], [431, 506], [561, 435], [288, 538], [454, 517], [520, 525]]],
    [[[445, 642], [245, 515], [320, 557], [403, 562], [537, 532], [304, 453], [428, 493], [493, 485], [293, 424], [416, 368], [461, 396]],
    [[433, 313], [260, 346], [380, 319], [410, 367], [565, 357], [336, 433], [415, 495], [502, 431], [264, 583], [365, 596], [597, 638]]],
    [[[397, 650], [286, 589], [381, 600], [467, 642], [565, 595], [331, 504], [508, 501], [363, 400], [476, 376], [305, 340], [567, 364]],
    [[435, 310], [300, 342], [378, 333], [431, 315], [499, 335], [222, 462], [444, 487], [397, 538], [583, 513], [382, 651], [416, 602]]],
    [[[352, 677], [290, 587], [417, 625], [398, 577], [469, 576], [290, 470], [570, 494], [330, 394], [366, 347], [433, 319], [313, 307]],
    [[394, 295], [249, 357], [524, 362], [223, 425], [458, 366], [556, 389], [324, 441], [387, 433], [531, 476], [382, 550], [421, 527]]],
    [[[455, 682], [382, 575], [418, 581], [325, 553], [342, 527], [550, 551], [269, 453], [518, 424], [342, 406], [562, 424], [313, 307]],
    [[430, 317], [306, 379], [346, 410], [434, 395], [496, 415], [340, 468], [508, 507], [582, 515], [249, 642], [447, 573], [486, 642]]],
    [[[420, 666], [260, 548], [308, 551], [412, 523], [525, 533], [251, 455], [418, 482], [339, 373], [248, 362], [362, 342], [466, 337]],
    [[427, 312], [296, 328], [321, 355], [434, 326], [529, 334], [326, 458], [353, 424], [517, 503], [267, 582], [352, 595], [555, 615]]],
    [[[343, 665], [355, 642], [530, 624], [304, 581], [521, 552], [246, 442], [438, 436], [445, 402], [270, 372], [541, 350], [516, 325]],
    [[454, 320], [392, 364], [520, 372], [272, 412], [552, 405], [264, 474], [418, 435], [540, 488], [566, 517], [312, 614], [426, 585]]],
    [[[347, 656], [297, 537], [376, 584], [447, 513], [551, 551], [367, 469], [534, 497], [387, 364], [246, 350], [379, 320], [516, 325]],
    [[404, 315], [390, 368], [424, 349], [352, 411], [548, 419], [218, 428], [419, 432], [448, 525], [270, 623], [551, 645], [426, 585]]],
    [[[462, 649], [282, 618], [405, 624], [299, 532], [381, 551], [506, 584], [253, 513], [363, 499], [535, 454], [250, 365], [538, 387]],
    [[448, 318], [347, 336], [537, 376], [302, 395], [522, 363], [330, 500], [551, 441], [502, 515], [236, 640], [515, 589], [426, 585]]],
    [[[430, 656], [260, 583], [447, 577], [554, 530], [261, 481], [339, 511], [466, 510], [541, 462], [338, 396], [419, 408], [490, 400]],
    [[392, 306], [395, 335], [546, 352], [325, 410], [401, 423], [315, 510], [539, 500], [517, 583], [268, 609], [440, 637], [426, 585]]],
    [[[385, 665], [357, 644], [551, 597], [333, 515], [507, 585], [357, 503], [412, 498], [310, 383], [394, 329], [481, 305], [520, 362]],
    [[384, 312], [303, 369], [367, 340], [440, 376], [490, 330], [367, 437], [496, 462], [369, 525], [486, 528], [234, 616], [444, 624]]],
    [[[376, 668], [296, 514], [341, 534], [474, 549], [554, 513], [231, 442], [426, 437], [561, 477], [321, 411], [355, 371], [520, 362]],
    [[454, 293], [289, 353], [459, 353], [282, 367], [346, 424], [522, 398], [345, 439], [575, 455], [304, 552], [567, 522], [371, 617]]]];

    string[] footballColors = [
    '#e4001e',
    '#1d9cfe',
    '#ff9504',
    '#00a143'
    ];

    mapping(uint256 => mapping(uint256 => string)) elementGroups;

    constructor() Ownable(){
    }

    function setElement(uint256 groupIndex, uint256[] calldata index, string[] calldata content) external onlyOwner {
        for (uint i = 0; i < index.length; i ++) {
            elementGroups[groupIndex][index[i]] = content[i];
        }
    }

    function renderBg(uint256 groupBg, uint256 groupColor, uint256 colorIndex) internal view returns (string memory s) {
        s = "";
        if (colorIndex == 0) {
            s = string(abi.encodePacked(s, elementGroups[groupBg][0]));
        } else {
            s = string(abi.encodePacked(s, elementGroups[groupBg][1], elementGroups[groupColor][colorIndex - 1], elementGroups[groupBg][2]));
        }
    }

    function renderElement(uint256 group, uint256 index) internal view returns (string memory){
        return elementGroups[group][index];
    }

    function renderWrapText(uint256 group, uint256 index, string memory text) internal view returns (string memory){
        return string(
            abi.encodePacked(
                elementGroups[group][index * 2],
                text,
                elementGroups[group][index * 2 + 1]
            )
        );
    }

    function renderStars(uint256 value) internal view returns (string memory){
        string memory s = "";
        for (uint256 i = 0; i <= value; i ++) {
            s = string(abi.encodePacked(
                    s,
                    '<use xlink:href="#star" transform="translate(',
                    Strings.toString(104 + i * 36),
                    ',983)" id="stm',
                    Strings.toString(i),
                    '" />\n'
                ));
        }
        return s;
    }

    function renderScoreBar(uint256 v, uint256 y, uint256 id) internal pure returns (string memory){
        uint256 x = 553 + v * 114 / 125;
        uint256 w = (10000 - v * 10000 / 125) * 114 / 10000;
        return string(abi.encodePacked(
                "<rect x=\"", Strings.toString(x),
                "\" y=\"", Strings.toString(y),
                "\" width=\"", Strings.toString(w),
                "\" height=\"4\" id=\"", Strings.toString(id),
                "\" />\n"
            ));
    }

    function renderTeam1Member(uint256 index, uint256 x, uint256 y) internal pure returns (string memory){
        return string(abi.encodePacked(
                '<use xlink:href="#team1member" transform="translate(',
                Strings.toString(x), ",", Strings.toString(y),
                ')" />\n'
            ));
    }

    function renderTeam2Member(uint256 index, uint256 x, uint256 y) internal pure returns (string memory){
        return string(abi.encodePacked(
                '<use xlink:href="#team2member" transform="translate(',
                Strings.toString(x), ",", Strings.toString(y),
                ')" />\n'
            ));
    }

    function renderTeam(IDescriptor.CardInfo calldata card) internal view returns (string memory){
        //        console.log(101);

        uint256 dir = Tools.Random8Bits(card.seed, 8, 0, 1);
        uint256 startType = Tools.Random8Bits(card.seed, 9, 1, 2) * 2 - 1;
        uint256 goalType = Tools.Random8Bits(card.seed, 10, card.rarity < 2 ? 1 : 0, startType == 0 ? 2 : 3);


        // may be one
        uint256 team1FormationIndex = Tools.Random8Bits(card.seed, 13, 0, uint8(teamFormations.length - 1));
        uint256 team2FormationIndex = Tools.Random8Bits(card.seed, 14, 0, uint8(teamFormations.length - 1));
        string memory data = "";

        // goalKeeper1
        uint256[2] memory gk1;
        {
            uint256 sx = teamFormations[team1FormationIndex][0][0][0];
            uint256 sy = teamFormations[team2FormationIndex][0][0][1];
            gk1 = [sx, sy];
            data = string(abi.encodePacked(data, renderTeam1Member(1, sx, sy)));
        }
        // goalKeeper2
        uint256[2] memory gk2;
        {
            uint256 sx = teamFormations[team2FormationIndex][0][0][0];
            uint256 sy = teamFormations[team2FormationIndex][0][0][1];
            gk2 = [sx, sy];
            data = string(abi.encodePacked(data, renderTeam2Member(1, sx, sy)));
        }
        uint256[2][] memory points = new uint256[2][](12);
        uint256 pointCounter = 0;

        if (startType == 0) {
            uint256 side = Tools.Random8Bits(card.seed, 15, 0, 1);
            uint256 sx = side == 0 ? Tools.Random16Bits(card.seed, 18, 146, 164) : Tools.Random16Bits(card.seed, 16, 624, 658);
            uint256 sy = Tools.Random16Bits(card.seed, 17, 296, 678);
            points[pointCounter++] = [sx, sy];
            data = string(abi.encodePacked(data, dir == 0 ? renderTeam1Member(1, sx, sy) : renderTeam2Member(1, sx, sy)));} else if (startType == 1) {
        } else if (startType == 1) {
            // pass
        }
        else if (startType == 2) {
            uint256 side = Tools.Random8Bits(card.seed, 15, 0, 1);
            uint256 sx;
            uint256 sy;
            if (dir == 0) {
                if (side == 0) {
                    sx = 227;
                    sy = 281;
                } else {
                    sx = 578;
                    sy = 281;
                }
            } else {
                if (side == 0) {
                    sx = 176;
                    sy = 696;
                } else {
                    sx = 624;
                    sy = 696;
                }
            }
            points[pointCounter++] = [sx, sy];
            data = string(abi.encodePacked(data, dir == 0 ? renderTeam1Member(1, sx, sy) : renderTeam2Member(1, sx, sy)));
        } else if (startType == 3) {
            points[pointCounter++] = dir == 0 ? gk1 : gk2;
        }

        int16 dy1 = int16(uint16(Tools.Random8Bits(card.seed, 18, 0, 31))) - 15;
        uint16 inPath = uint16(0xFFFF & (card.seed >> (19 * 8)));
        // 19 & 20

        {
            uint256 team1max = Tools.Random8Bits(card.seed, 11, nodesOfLevel[card.rarity][0], nodesOfLevel[card.rarity][1]);
            for (uint j = 0; j < 10; j ++) {
                if (startType == 0 || startType == 2) {
                    if (dir == 0 && j == 0) {
                        continue;
                    }
                }
                uint256 sx = teamFormations[team1FormationIndex][0][j + 1][0];
                uint256 sy = uint256(uint16(int16(teamFormations[team1FormationIndex][0][j + 1][1]) + dy1));
                gk1 = [sx, sy];
                data = string(abi.encodePacked(data, renderTeam1Member(1, sx, sy)));
                if (dir == 0) {
                    if (pointCounter < 2) {
                        points[pointCounter++] = gk1;
                    } else if (pointCounter < team1max) {
                        if (((inPath >> j) & 0x1) == 1) {
                            points[pointCounter++] = gk1;
                        }
                    }
                }
            }
        }
        {
            uint256 team2max = Tools.Random8Bits(card.seed, 12, nodesOfLevel[card.rarity][0], nodesOfLevel[card.rarity][1]);
            for (uint j = 0; j < 10; j ++) {
                if (startType == 0 || startType == 2) {
                    if (dir == 1 && j == 0) {
                        continue;
                    }
                }

                uint256 sx = teamFormations[team2FormationIndex][1][j + 1][0];
                uint256 sy = uint256(uint16(int16(teamFormations[team1FormationIndex][1][j + 1][1]) + dy1));
                gk2 = [sx, sy];
                data = string(abi.encodePacked(data, renderTeam2Member(1, sx, sy)));
                if (dir == 1) {
                    if (pointCounter < 2) {
                        points[pointCounter++] = gk2;
                    } else if (pointCounter < team2max) {
                        if (((inPath >> j) & 0x1) == 1) {
                            points[pointCounter++] = gk2;
                        }
                    }
                }
            }
        }
        string memory z = "";
        {
            if (goalType == 0) {
                uint256 sx = Tools.Random16Bits(card.seed, 21, dir == 0 ? team2Regions[6][0] : team1Regions[6][0], dir == 0 ? team2Regions[6][2] : team1Regions[6][2]);
                uint256 sy = dir == 0 ? team2Regions[6][1] : team1Regions[6][1];
                points[pointCounter++] = [sx, sy];
            } else if (goalType == 1) {
                uint256 side = Tools.Random8Bits(card.seed, 22, 0, 1);
                uint256 sx = side == 0 ? 164 : 648;
                uint256 sy = Tools.Random16Bits(card.seed, 23, 284, 700);
                points[pointCounter++] = [sx, sy];
            } else if (goalType == 2) {
                uint256 side = Tools.Random8Bits(card.seed, 22, 0, 1);
                uint256 sx = side == 0 ? Tools.Random16Bits(card.seed, 23, 222, 357) : Tools.Random16Bits(card.seed, 23, 445, 578);
                uint256 sy = dir == 0 ? 236 : 740;
                points[pointCounter++] = [sx, sy];
            } else if (goalType == 3) {
                z = "z";
            }
        }

        string memory pData = genPathData(points, pointCounter, z);
        data = string(abi.encodePacked(genPath(pData), data));


        uint8 dur = Tools.Random8Bits(card.seed, 25, 12, uint8(10 + pointCounter * 6));
        uint8 ballColor = Tools.Random8Bits(card.seed, 26, 0, 3);
        data = string(abi.encodePacked(data, genFootball(points[0][0], points[0][1], pData, dur, ballColor)));

        return data;
    }

    function genPathData(uint256[2][] memory points, uint256 pointCounter, string memory z) internal view returns (string memory path){
        path = "";
        if (pointCounter > 1) {
            path = "M";
            for (uint i = 0; i < pointCounter; i ++) {
                path = string(abi.encodePacked(path, " ", Strings.toString(points[i][0]), ",", Strings.toString(points[i][1])));
            }
            path = string(abi.encodePacked(path, z));
        }
    }

    function genPath(string memory path) internal view returns (string memory pathData){
        return string(abi.encodePacked(
                "<path style=\"opacity:0.97506925;fill:none;fill-opacity:0.416413;stroke-width:3;stroke-dasharray:11.564, 23.128;stroke:#f5f500;stroke-opacity:1\" d=\"",
                path,
                "\" id=\"path",
                "R42",
                "\" />\n"
            ));
    }

    function genFootball(uint256 x, uint256 y, string memory pathData, uint8 dur, uint8 ballColor) internal view returns (string memory path){
        return string(abi.encodePacked(
                "<g id=\"g1449\" transform=\"translate(-286.58244,-526.37697)\"> <path class=\"cls-6\" d=\"m 286.6417,510.61358 a 26,26 0 0 1 7.91,1.21 22,22 0 0 1 6.49,3.32 16.4,16.4 0 0 1 4.42,5 12.42,12.42 0 0 1 0.12,12.23 16.07,16.07 0 0 1 -4.36,5 21.85,21.85 0 0 1 -6.54,3.42 26.51,26.51 0 0 1 -16.09,0 21.85,21.85 0 0 1 -6.54,-3.42 16.24,16.24 0 0 1 -4.37,-5 12.38,12.38 0 0 1 0.13,-12.23 16.4,16.4 0 0 1 4.42,-5 22,22 0 0 1 6.49,-3.32 26,26 0 0 1 7.92,-1.21 z\" id=\"path1292\" style=\"fill:#ffffff\" /> <path class=\"cls-17\" d=\"m 298.4717,517.19358 a 15.05,15.05 0 0 1 2,1.92 13.2,13.2 0 0 1 1.55,2.16 11.16,11.16 0 0 1 1,2.38 10,10 0 0 1 -0.93,7.54 13.27,13.27 0 0 1 -3.59,4.11 17.67,17.67 0 0 1 -5.35,2.8 21,21 0 0 1 -6.55,1 c -0.45,0 -0.89,0 -1.34,0 -0.45,0 -0.87,-0.06 -1.31,-0.12 -0.44,-0.06 -0.85,-0.12 -1.28,-0.2 -0.43,-0.08 -0.83,-0.16 -1.24,-0.26 h -0.14 -0.15 a 19.67,19.67 0 0 1 -2.32,-0.76 16.71,16.71 0 0 1 -2.13,-1 16.12,16.12 0 0 1 -1.91,-1.25 14.64,14.64 0 0 1 -1.65,-1.47 l -0.09,-0.11 a 13.6,13.6 0 0 1 -1.37,-1.7 11.22,11.22 0 0 1 -1,-1.86 9.92,9.92 0 0 1 -0.63,-2 9.68,9.68 0 0 1 -0.2,-2.09 c 0,-0.21 0,-0.42 0,-0.63 0,-0.21 0,-0.41 0.07,-0.62 0.07,-0.21 0.06,-0.41 0.1,-0.61 0.04,-0.2 0.09,-0.41 0.15,-0.61 v -0.09 a 10.78,10.78 0 0 1 0.65,-1.77 13.48,13.48 0 0 1 1,-1.67 13.23,13.23 0 0 1 1.27,-1.55 15.79,15.79 0 0 1 1.53,-1.4 h 0.08 0.09 0.08 0.09 a 17.35,17.35 0 0 1 2.47,-1.52 19.33,19.33 0 0 1 2.8,-1.15 21.74,21.74 0 0 1 3.09,-0.72 22.28,22.28 0 0 1 3.3,-0.25 21.81,21.81 0 0 1 3.37,0.26 21,21 0 0 1 3.13,0.75 19.61,19.61 0 0 1 2.85,1.19 17.48,17.48 0 0 1 2.51,1.3 z m -3.21,14.63 3.55,0.69 a 11,11 0 0 0 1.06,-1.43 9.33,9.33 0 0 0 0.79,-1.54 8.59,8.59 0 0 0 0.49,-1.64 8.16,8.16 0 0 0 0.15,-1.72 c 0,-0.13 0,-0.27 0,-0.4 v -0.41 c 0,-0.13 0,-0.26 0,-0.4 0,-0.14 0,-0.26 -0.07,-0.39 h -3 a 1.36,1.36 0 0 1 -0.29,0 1.14,1.14 0 0 1 -0.26,-0.09 1.07,1.07 0 0 1 -0.22,-0.15 1.2,1.2 0 0 1 -0.17,-0.21 l -0.53,-0.8 -4.12,1.89 -1.74,4.73 2.59,2.64 1,-0.57 a 0.39,0.39 0 0 1 0.19,-0.1 h 0.22 0.23 0.2 m -15.41,0.74 2.44,-2.48 -1.85,-5 -3.91,-1.79 -0.58,0.89 a 0.61,0.61 0 0 1 -0.12,0.16 0.83,0.83 0 0 1 -0.18,0.13 l -0.25,0.08 a 1.36,1.36 0 0 1 -0.29,0 h -3 c 0,0.13 0,0.26 -0.07,0.39 -0.07,0.13 0,0.27 0,0.4 v 0.41 c 0,0.13 0,0.27 0,0.4 a 8.88,8.88 0 0 0 0.15,1.72 9.39,9.39 0 0 0 1.28,3.18 11,11 0 0 0 1.06,1.43 l 3.56,-0.69 h 0.41 0.16 l 0.14,0.06 0.13,0.09 1,0.57 m 1.9,-16.91 c -0.48,0.13 -0.94,0.28 -1.4,0.45 -0.46,0.17 -0.89,0.35 -1.32,0.55 -0.43,0.2 -0.84,0.41 -1.23,0.64 -0.39,0.23 -0.78,0.48 -1.15,0.74 l 1.41,2.23 a 0.64,0.64 0 0 1 0.06,0.18 0.82,0.82 0 0 1 0,0.36 l -0.06,0.18 -0.57,0.87 3.92,1.8 4.17,-1.92 v -3.54 h -1 -0.24 l -0.22,-0.07 -0.21,-0.1 -0.18,-0.12 -2,-2.22 m 5.92,2.54 v 3.63 l 4.08,1.88 4,-1.84 -0.64,-1 a 0.64,0.64 0 0 1 -0.06,-0.18 0.82,0.82 0 0 1 0,-0.36 1.21,1.21 0 0 1 0,-0.18 l 1.41,-2.23 c -0.35,-0.24 -0.72,-0.48 -1.1,-0.7 -0.38,-0.22 -0.78,-0.42 -1.19,-0.62 -0.41,-0.2 -0.84,-0.36 -1.27,-0.52 -0.43,-0.16 -0.88,-0.31 -1.34,-0.44 l -2,2.2 -0.23,0.12 -0.24,0.1 -0.23,0.07 h -0.24 -1 m 2.54,16.22 1.51,-0.88 -2.46,-2.51 h -5.26 l -2.46,2.51 1.51,0.88 a 1.74,1.74 0 0 1 0.2,0.13 1.83,1.83 0 0 1 0.13,0.16 1.34,1.34 0 0 1 0.07,0.18 1.1,1.1 0 0 1 0,0.18 v 2.17 l 0.77,0.11 c 0.26,0 0.52,0.06 0.79,0.09 h 0.8 0.8 0.81 0.8 l 0.78,-0.09 0.78,-0.11 v -2.17 a 1.1,1.1 0 0 1 0,-0.18 1.34,1.34 0 0 1 0.07,-0.18 1,1 0 0 1 0.14,-0.16 l 0.19,-0.13\" id=\"path1294\" style=\"fill:",
                footballColors[ballColor],
                ';fill-opacity:1" /><animateMotion path="',
                pathData,
                '"\n dur="',
                Strings.toString(dur / 10),
                ".",
                Strings.toString(dur % 10),
                's" begin="0s" repeatCount="indefinite" rotate="none" /></g>\n'
            ));
    }

    function renderImage(IDescriptor.CardInfo calldata card, uint256 tokenId) internal view returns (bytes memory){
        bytes memory image =
        abi.encodePacked(
            renderBg(1, 6, Tools.Random8Bits(card.seed, 1, bgColorIndexOfRarity[card.rarity][0], bgColorIndexOfRarity[card.rarity][1])), // background
            renderElement(2, card.nation), // flag
            renderWrapText(0, 0, Strings.toString(tokenId)), // tokenId Text
            renderWrapText(0, 1, rarityNames[card.rarity]), // Rarity name
            renderStars(card.rarity), // tokenId Text
            renderScoreBar(card.attack, 903, 101), renderWrapText(4, 0, Strings.toString(card.attack)),
            renderScoreBar(card.defensive, 953, 102), renderWrapText(4, 1, Strings.toString(card.defensive)),
            renderScoreBar(card.physical, 1003, 103), renderWrapText(4, 2, Strings.toString(card.physical)),
            renderScoreBar(card.tactical, 1053, 104), renderWrapText(4, 3, Strings.toString(card.tactical)),
            renderScoreBar(card.luck, 1103, 105), renderWrapText(4, 4, Strings.toString(card.luck)),
            renderElement(5, Tools.Random8Bits(card.seed, 7, 0, 7)),
            renderTeam(card),
            "</svg>"
        );
        return image;
    }

    function renderMeta(IDescriptor.CardInfo calldata card, uint256 tokenId) external view returns (string memory){
        bytes memory data;
        if (card.seed == 0) {
            string memory image = Base64.encode(abi.encodePacked(elementGroups[1][3]));
            data = bytes(
                abi.encodePacked(
                    '{"name":"', 'Nfinity #', Strings.toString(tokenId), '", ',
                    '"image": "', 'data:image/svg+xml;base64,', image,
                    '"}')
            );
        } else {
            string memory image = Base64.encode(renderImage(card, tokenId));
            string memory attributes = '[';
            attributes = string.concat(attributes, '{"trait_type": "Rank", "value": "', rarityNames[card.rarity], '"},');
            attributes = string.concat(attributes, '{"trait_type": "Nation", "value": "', elementGroups[7][card.nation], '"},');
            attributes = string.concat(attributes, '{"trait_type": "Attack", "value": ', Strings.toString(card.attack), '},');
            attributes = string.concat(attributes, '{"trait_type": "Defensive", "value": ', Strings.toString(card.defensive), '},');
            attributes = string.concat(attributes, '{"trait_type": "Physical", "value": ', Strings.toString(card.physical), '},');
            attributes = string.concat(attributes, '{"trait_type": "Tactical", "value": ', Strings.toString(card.tactical), '},');
            attributes = string.concat(attributes, '{"trait_type": "Luck", "value": ', Strings.toString(card.luck), '}');
            attributes = string.concat(attributes, ']');
            data = bytes(
                abi.encodePacked(
                    '{"name":"', 'Nfinity #', Strings.toString(tokenId), '", ',
                    '"attributes":', attributes, ', ',
                    '"image": "', 'data:image/svg+xml;base64,', image,
                    '"}')
            );

        }

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    data
                )));
    }
}