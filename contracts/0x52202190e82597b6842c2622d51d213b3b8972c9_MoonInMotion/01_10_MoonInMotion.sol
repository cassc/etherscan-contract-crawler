// SPDX-License-Identifier: CC-BY-4.0

pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonInMotion is ERC1155, Ownable {
    struct Date {
        int day;
        int month;
        int year;
    }

    uint256 public constant MOON = 1;
    uint256 public constant BLOOD = 2;
    uint256 public constant HONEY = 3;
    uint256 public constant ORANGE = 4;
    uint256 public constant BLUE = 5;
    uint256 public constant NEON = 6;

    uint constant COMMON_COUNT = 29;
    uint constant UNCOMMON_COUNT = 14;
    uint constant RARE_COUNT = 7;
    uint constant SUPERRARE_COUNT = 3;
    uint constant UNIQUE_COUNT = 1;

    string svg1 = "<svg width='600' height='600' viewBox='0 0 600 600' fill='none' xmlns='http://www.w3.org/2000/svg'><g clip-path='url(#c0)'><rect width='600' height='600' fill='url(#p0)'/><g filter='url(#f0)'><circle cx='300' cy='300' r='191' fill='#FCFBEF'/></g><g filter='url(#f1)'><circle cx='300' cy='300' r='191' fill='#FCFBEF'/></g><mask id='m0' mask-type='alpha' maskUnits='userSpaceOnUse' x='109' y='109' width='382' height='382'><circle cx='300' cy='300' r='191' fill='#FCFBEF'/></mask><g mask='url(#m0)'><g filter='url(#f2)'>";
    string svg2 = "</g></g><defs><filter id='f0' x='-15' y='-15' width='630' height='630' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feFlood flood-opacity='0' result='BackgroundImageFix'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset/><feGaussianBlur stdDeviation='62'/><feComposite in2='hardAlpha' operator='out'/><feColorMatrix type='matrix' values='0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0.25 0'/><feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow'/><feBlend mode='normal' in='SourceGraphic' in2='effect1_dropShadow' result='shape'/></filter><filter id='f1' x='39' y='39' width='522' height='522' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feFlood flood-opacity='0' result='BackgroundImageFix'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset/><feGaussianBlur stdDeviation='35'/><feComposite in2='hardAlpha' operator='out'/><feColorMatrix type='matrix' values='0 0 0 0 0.0862745 0 0 0 0 0.0823529 0 0 0 0 0.25098 0 0 0 0.24 0'/><feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow'/><feBlend mode='normal' in='SourceGraphic' in2='effect1_dropShadow' result='shape'/></filter><filter id='f2' x='105' y='109' width='390' height='390' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feFlood flood-opacity='0' result='BackgroundImageFix'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset dy='4'/><feGaussianBlur stdDeviation='2'/><feComposite in2='hardAlpha' operator='out'/><feColorMatrix type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0'/><feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow'/><feBlend mode='normal' in='SourceGraphic' in2='effect1_dropShadow' result='shape'/></filter><radialGradient id='p0' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(126 116) rotate(45.1872) scale(865.503)'><stop offset='0.255208' stop-color='#160340'/><stop offset='1' stop-color='#356C4B'/></radialGradient><clipPath id='c0'><rect width='600' height='600' fill='white'/></clipPath></defs></svg>";
    
    string svgNeon1 = "<svg width='600' height='600' viewBox='0 0 600 600' fill='none' xmlns='http://www.w3.org/2000/svg'><rect width='600' height='600' fill='#0B1124'/><g filter='url(#f0i)'><circle cx='300' cy='300' r='191' fill='#04050B'/><circle cx='300' cy='300' r='188' stroke='#BD00FF' stroke-width='6'/></g><mask id='m0' mask-type='alpha' maskUnits='userSpaceOnUse' x='109' y='109' width='382' height='382'><circle cx='300' cy='300' r='191' fill='#FCFBEF'/></mask><g mask='url(#m0)'><g filter='url(#f1i)'><circle cx='300' cy='300' r='191' fill='#0B1124'/></g>";
    string svgNeon2 = "<circle cx='300' cy='300' r='188' stroke='#BD00FF' stroke-width='6'/></g><defs><filter id='f0i' x='75' y='75' width='450' height='450' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feFlood flood-opacity='0' result='BackgroundImageFix'/><feColorMatrix in='SourceAlpha' type='matrix' values ='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset/><feGaussianBlur stdDeviation='17'/><feComposite in2='hardAlpha' operator='out'/><feColorMatrix type='matrix' values='0 0 0 0 0.741176 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0'/><feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow'/><feBlend mode='normal' in='SourceGraphic' in2='effect1_dropShadow' result='shape'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset dy='4'/><feGaussianBlur stdDeviation='16.5'/><feComposite in2='hardAlpha' operator='arithmetic' k2='-1' k3='1'/><feColorMatrix type='matrix' values='0 0 0 0 0.729412 0 0 0 0 0 0 0 0 0 0.984314 0 0 0 1 0'/><feBlend mode='normal' in2='shape' result='effect2_is'/></filter><filter id='f1i' x='75' y='75' width='450' height='450' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feFlood flood-opacity='0' result='BackgroundImageFix'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset/><feGaussianBlur stdDeviation='17'/><feComposite in2='hardAlpha' operator='out'/><feColorMatrix type='matrix' values='0 0 0 0 0.741176 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0'/><feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow'/><feBlend mode='normal' in='SourceGraphic' in2='effect1_dropShadow' result='shape'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset dy='4'/><feGaussianBlur stdDeviation='16.5'/><feComposite in2='hardAlpha' operator='arithmetic' k2='-1' k3='1'/><feColorMatrix type='matrix' values='0 0 0 0 0.729412 0 0 0 0 0 0 0 0 0 0.984314 0 0 0 1 0'/><feBlend mode='normal' in2='shape' result='effect2_is'/></filter><filter id='f2' x='86' y='69' width='462' height='462' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feFlood flood-opacity='0' result='BackgroundImageFix'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset/><feGaussianBlur stdDeviation='17'/><feComposite in2='hardAlpha' operator='out'/><feColorMatrix type='matrix' values='0 0 0 0 0 0 0 0 0 1 0 0 0 0 0.878431 0 0 0 1 0'/><feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow'/><feBlend mode='normal' in='SourceGraphic' in2='effect1_dropShadow' result='shape'/></filter><filter id='is' x='86' y='69' width='462' height='462' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feGaussianBlur in='SourceAlpha' stdDeviation='17'></feGaussianBlur><feOffset dy='2' dx='3'></feOffset><feComposite in2='SourceAlpha' operator='arithmetic' k2='-1' k3='1' result='shadowDiff'></feComposite><feFlood flood-color='#00FFE0' flood-opacity='0.75'></feFlood><feComposite in2='shadowDiff' operator='in'></feComposite><feComposite in2='SourceGraphic' operator='over' result='firstfilter'></feComposite><feGaussianBlur in='firstfilter' stdDeviation='3' result='blur2'></feGaussianBlur><feOffset dy='-2' dx='-3'></feOffset><feComposite in2='firstfilter' operator='arithmetic' k2='-1' k3='1' result='shadowDiff'></feComposite><feFlood flood-color='#00FFE0' flood-opacity='0.75'></feFlood><feComposite in2='shadowDiff' operator='in'></feComposite><feComposite in2='firstfilter' operator='over'></feComposite></filter></defs></svg>";
    
    string maskOuterPhases1 = "<g filter='url(#is)'><svg width='191' height='382' x='";
    string maskOuterPhases2 = "' y='109'><circle cx='";
    string maskOuterPhases3 = "' cy='191' r='191' fill='#0E1C4B'/><circle cx='";
    string maskOuterPhases4 = "' cy='191' r='194' stroke='#00FFE0' stroke-width='6'/></svg></g><g filter='url(#f2)'><svg width='382' height='382' x='109' y='109'><ellipse cx='191' cy='191' rx='";
    string maskOuterPhases5 = "' ry='191' fill='#0B1124'/><ellipse cx='191' cy='191' rx='";
    string maskOuterPhases6 = "' ry='194' stroke='#00FFE0' stroke-width='6'/></svg></g><rect x='";
    string maskOuterPhases7 = "' y='109' width='191' height='382' fill='#0B1124'/>";
    
    string maskInnerPhases1 = "<g filter='url(#is)'><svg width='382' height='382' x='109' y='109'><ellipse cx='191' cy='191' rx='";
    string maskInnerPhases2 = "' ry='191' fill='#0E1C4B'/><ellipse cx='191' cy='191' rx='";
    string maskInnerPhases3 = "' ry='194' stroke='#00FFE0' stroke-width='6'/></svg><svg width='191' height='382' x='";
    string maskInnerPhases4 = "' y='109'><circle cx='";
    string maskInnerPhases5 = "' cy='191' r='191' fill='#0E1C4B'/><circle cx='";
    string maskInnerPhases6 = "' cy='191' r='194' stroke='#00FFE0' stroke-width='6'/></svg></g>";
    string[] descriptions = [
            'The Moon is our closest celestial body. During its cycle, we can admire a different look every night.',
            "When the Moon moves into the Earth's shadow, we can all enjoy the spectacle of the Blood Moon. Visible only during full Moon.",
            'When the Sun is high and the Moon is low on the horizon, we can see the Honey Moon.',
            'Once a year in Autumn, at harvesting time, the dust from the crops will filter the moonlight, letting us enjoy the Orange Moon.',
            'The Blue Moon has appeared only a few times in history, thanks to the hashes of erupting volcanoes.',
            'A wise man once said: \\"Transcend your mind and the Neon Moon will rise.\\"'
    ];
    string[] names = ["Moon", "Blood Moon", "Honey Moon", "Orange Moon", "Blue Moon", "Neon Moon"];
    string[] colors = ["#fcfbef", "#ff7474", "#f6ed9e", "#ffa95e", "#9bd1e0"];
    string commonDescription = "\\n\\nThis NFT follows the current lunar phase, shifting it every day, without using any external resource (it's 100% on chain). What you see reflects the visibility of the Moon on ";
    string attributes1 = '"attributes":[{"trait_type":"Frequency","value":"';
    string attributes2 = '"},{"trait_type":"Editions","value":"';
    string attributes3 = '"}]'; 
    constructor () ERC1155 ("mooninmotion") {
        _mint(msg.sender, MOON, COMMON_COUNT, "");
        _mint(msg.sender, HONEY, UNCOMMON_COUNT, "");
        _mint(msg.sender, ORANGE, UNCOMMON_COUNT, "");
        _mint(msg.sender, BLOOD, RARE_COUNT, "");
        _mint(msg.sender, BLUE, SUPERRARE_COUNT, "");
        _mint(msg.sender, NEON, UNIQUE_COUNT, "");
    }


    function calculateRadius(int day) public pure returns (uint radius) {
        int dmod = day % 14;
        int max = 20000;
        int r = (max - (max / 7 * dmod)) / 100;
        
        return uint(r > 0 ? r : r * -1);
    }

    function currentMoonDay(int day, int month, int year) public pure returns (int _day) {
        if(month == 1 || month == 2) {
            month = month + 12;
            year = year - 1;
        }
        
        int fa = 10000;

        int a = year / 100 * fa;
        int b = a / 4 / fa * fa;
        int c = 2 * fa - a + b;
        int e = 3652500 * (year + 4716);
        int f = 306001 * (month + 1);
        int jd = c+ day*fa + e + f - 15245000;
        int daysSinceNew = (jd - 24515495000) / fa;

        int cycle = 2953;
        int newMoonsInt = daysSinceNew * 100000 / cycle;
        int newMoonsDec = newMoonsInt - (newMoonsInt / 1000) * 1000;

        return newMoonsDec * cycle / 100000;
    }

    function timestampToDate(uint timestamp) internal pure returns (Date memory _date) {
        int z = int(timestamp) / 86400 + 719468;
        int era = (z >= 0 ? z : z - 146096) / 146097;
        int doe = z - era * 146097;
        int yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
        int doy = doe - (365 * yoe + yoe/4 - yoe/100);
        int y = yoe + era * 400;
        int mp = (5 * doy + 2) / 153;
        int m = mp + (mp < 10 ? int(3) : -9);
        int d = doy - (153 * mp + 2)/5 + 1;

        return Date({
            day: d, 
            month: m, 
            year: y}
        );
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function generateMoon(int day, string memory color) public view returns (string memory) {
        uint r = calculateRadius(day);
        string memory color1 = (day < 8 || day > 21) ? color : "#231336";
        string memory color2 = (day < 8 || day > 21) ? "#231336" : color;
        
        string memory rectPosition = day < 8 || (day >= 15 && day < 22) ? "109" : "300";

        bytes memory _img = abi.encodePacked(svg1, 
            "<circle cx='300' cy='300' r='191' fill='", 
            color1, 
            "'/></g><ellipse cx='300' cy='300' rx='", 
            uint2str(r), 
            "' ry='200' fill='", 
            color2, 
            "'/><rect x='", 
            rectPosition, 
            "' y='109' width='191' height='382' fill='", color2, "'/>", svg2);

        return(string(abi.encodePacked(_img)));
        
    }

    function generateNeonMoon(int day) public view returns (string memory) {
        uint r = calculateRadius(day);

        bytes memory mask;
        if(day < 8) {
            mask = abi.encodePacked(
                maskOuterPhases1,
                "300",
                maskOuterPhases2,
                "0",
                maskOuterPhases3,
                "0",
                maskOuterPhases4,
                uint2str(r),
                maskOuterPhases5,
                uint2str(r + 4),
                maskOuterPhases6,
                "109",
                maskOuterPhases7
            );
        }
        else if (day < 15) {
            mask = abi.encodePacked(
                maskInnerPhases1,
                uint2str(r),
                maskInnerPhases2,
                uint2str(r + 4),
                maskInnerPhases3,
                "300",
                maskInnerPhases4,
                "0",
                maskInnerPhases5,
                "0",
                maskInnerPhases6
            );
        }
        else if(day < 22) {
            mask = abi.encodePacked(
                maskInnerPhases1,
                uint2str(r),
                maskInnerPhases2,
                uint2str(r + 4),
                maskInnerPhases3,
                "109",
                maskInnerPhases4,
                "191",
                maskInnerPhases5,
                "191",
                maskInnerPhases6
            );
        }
        else {
            mask = abi.encodePacked(
                maskOuterPhases1,
                "109",
                maskOuterPhases2,
                "191",
                maskOuterPhases3,
                "191",
                maskOuterPhases4,
                uint2str(r),
                maskOuterPhases5,
                uint2str(r + 4),
                maskOuterPhases6,
                "300",
                maskOuterPhases7
            );
        }
        
        bytes memory _img = abi.encodePacked(
            svgNeon1, 
            mask,
            svgNeon2);

        return(string(abi.encodePacked(_img)));
        
    }

    function getImage(uint tokenId, int moonDay) public view returns (string memory _image) {
        string memory image;
        if(tokenId != NEON) {
            if (tokenId == BLOOD && moonDay != 14) {
                image = generateMoon(moonDay, colors[MOON - 1]);
            }
            else {
                image = generateMoon(moonDay, colors[tokenId - 1]);
            }
        }
        else {
            image = generateNeonMoon(moonDay);
        }

        return image;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        uint timestamp = block.timestamp;
        Date memory date = timestampToDate(timestamp);
        int moonDay = currentMoonDay(date.day, date.month, date.year);

        string memory image = getImage(tokenId, moonDay);
        
        string memory name = names[tokenId - 1];
        string memory description = descriptions[tokenId - 1];
        string memory wholeDescription = string(abi.encodePacked(
            commonDescription, 
            uint2str(uint(date.day)), 
            "/", 
            uint2str(uint(date.month)), 
            "/", 
            uint2str(uint(date.year)), 
            "."));

        string memory attributes;
        if(tokenId == MOON) {
            attributes = string(abi.encodePacked(attributes1,"Common", attributes2, "29", attributes3));
        }
        else if(tokenId == ORANGE || tokenId == HONEY) {
            attributes = string(abi.encodePacked(attributes1,"Uncommon", attributes2, "14", attributes3));
        }
        else if(tokenId == BLOOD) {
            attributes = string(abi.encodePacked(attributes1,"Rare", attributes2, "7", attributes3));
        }
        else if(tokenId == BLUE) {
            attributes = string(abi.encodePacked(attributes1,"Super Rare", attributes2, "3", attributes3));
        }
        else {
            attributes = string(abi.encodePacked(attributes1,"N/A", attributes2, "1", attributes3));
        }

        bytes memory json = abi.encodePacked('{"name":"', name, '", "description":"', description, wholeDescription, '",', attributes, ', "created_by":"Inner Space", "image":"', image,'"}');

        return string(abi.encodePacked('data:text/plain,',json));
        
    }
}