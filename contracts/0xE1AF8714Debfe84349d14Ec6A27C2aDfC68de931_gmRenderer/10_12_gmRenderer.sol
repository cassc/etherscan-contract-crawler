// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IgmRenderer.sol";
import "hardhat/console.sol";

contract gmRenderer is IgmRenderer, Ownable, AccessControl {
    /* Constants */
    bytes32 private constant CAN_STYLE = keccak256("CAN_STYLE");

    string private constant tokenUriStart = "{ \"name\": \"say gm #";
    string private constant tokenUriSeparator = " , ";
    string private constant tokenUriImage = "\"image\": ";
    string private constant tokenUriEnd = "}";
    string private constant description = "\"description\":\"Saying GM to ETH one address at a time. By Scooprinder.\"";
    
    string private constant tokenStart = "<svg width=\"512\" height=\"";
    string private constant tokenHeightEnd = "\" xmlns=\"http://www.w3.org/2000/svg\"><style>";
    string private constant styleEnd = "</style><path id=\"path\"><animate attributeName=\"d\" from=\"m0,40 h0\" to=\"m0,40 h800\" fill=\"freeze\" dur=\"3s\" /></path>";
    string private constant bgAndTilde = "<g class=\"box\"><rect width=\"100%\" height=\"100%\" class=\"bg\"/></g><text x=\"20\" y=\"40\" class=\"text\"><tspan class=\"three\"> ~ </tspan><tspan class=\"five\">$ </tspan></text><text x=\"90\" y=\"40\" class=\"text\"><textPath href=\"#path\"><tspan>./sayGM.sh --token </tspan><tspan>";
    string private constant tildeEnd = "</tspan></textPath></text>";
    string private constant svgEnd = "</svg>";

    struct Theme {
        uint256 colours;
        string name;
    }    

    /* Variables */
    mapping(uint16 => address[]) public addresses;
    mapping(uint16 => Theme) public tokenMeta;
    mapping(uint16 => Theme) public styles;

    /* Errors */
    error IncorrectPermissions();

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, owner());
        initStyles();
    }

    function initStyles() internal {
        styles[0] = Theme(785032280514239843345403986361234975989988, "3024.Dark");
        styles[1] = Theme(21601113074724041509299788054747602248376548, "3024.Light");
        styles[2] = Theme(2450080602231916301109411517425644615931335, "Ashes.Dark");
        styles[3] = Theme(21251640488257556404332348807687975117690311, "Ashes.Light");
        styles[4] = Theme(1836532932293261474947541093197059158164207, "Chalk.Dark");
        styles[5] = Theme(21426205144243543352603650819884654439416559, "Chalk.Light");
        styles[6] = Theme(3063968387711154413797538277562850736622969, "Codeschool.Dark");
        styles[7] = Theme(15841151954126252132335802530650147934195065, "Codeschool.Light");
        styles[8] = Theme(3935426488509762671892753047397560498952652, "eighties.Dark");
        styles[9] = Theme(21163155083579423400054192616014747844123084, "eighties.Light");
        styles[10] = Theme(1922956443369488271547589485961065159022466, "Embers.Dark");
        styles[11] = Theme(19150689203312247356020497198042459178620802, "Embers.Light");
        styles[12] = Theme(5784804030466693623925746515944033786112, "Greenscreen.Dark");
        styles[13] = Theme(86772005288844268355738519842085236939008, "Greenscreen.Light");
        styles[14] = Theme(1084233046149285124766650863596889855, "Isotope.Dark");
        styles[15] = Theme(22300744369717921920193691046784006883403519, "Isotope.Light");
        styles[16] = Theme(2795082791690382213632460520052185973095585, "Marrakesh.Dark");
        styles[17] = Theme(21859959068736174936823471140295558566476961, "Marrakesh.Light");
        styles[18] = Theme(5156693241509711486190552088476313935590325, "Mocha.Dark");
        styles[19] = Theme(21423810146085430223419735651964402086359989, "Mocha.Light");
        styles[20] = Theme(3411036932506252666815918801810340780104175, "Monokai.Dark");
        styles[21] = Theme(21775675265366654877166405750759315017751023, "Monokai.Light");
        styles[22] = Theme(3762241274062658723578064965903336480940467, "Ocean.Dark");
        styles[23] = Theme(20902170461022904022793058095753059258835379, "Ocean.Light");
        styles[24] = Theme(4104547903849528960754850712654414816392943, "Paraiso.Dark");
        styles[25] = Theme(20202515354196458816962624266815773350475503, "Paraiso.Light");
        styles[26] = Theme(14704686635302771731306147606592303303634, "Solarized.Dark");
        styles[27] = Theme(22123419996915462889364537219902724096035794, "Solarized.Light");
        styles[28] = Theme(2536849936874170634349935813617216894640830, "Tomorrow.Dark");
        styles[29] = Theme(22300744156080783666526710536704242948874942, "Tomorrow.Light");
    }

    function unpackStyle(uint16 id) internal view returns (string memory) {
        uint256 a = tokenMeta[id].colours;
        bytes memory result = abi.encodePacked(
            ".bg{fill:#",
            unpackHexCode(a, 120),
            ";}.text{fill:#",
            unpackHexCode(a, 96),
            ";font:30px courier;}.two{fill:#",
            unpackHexCode(a, 72)
        );

        result = abi.encodePacked(
            result,
            ";}.three{fill:#",
            unpackHexCode(a, 48),
            ";}.four{fill:#",
            unpackHexCode(a, 24),
            ";}.five{fill:#",
            unpackHexCode(a, 0),
            ";}"
        );

        return string(result);
    }

    function unpackHexCode(uint256 raw, uint8 offset) internal pure returns (string memory) {
        return string(abi.encodePacked(
            substring(Strings.toHexString( uint8(raw >> (16+offset)) ), 2, 4),
            substring(Strings.toHexString( uint8(raw >> (8+offset)) ), 2, 4),
            substring(Strings.toHexString( uint8(raw >> (offset)) ), 2, 4)
        ));
    }

    function addAddress(uint16 tokenId, address newAddress) external {
        addresses[tokenId].push(newAddress);
    }

    function addStyler(address account) external onlyOwner {
        grantRole(CAN_STYLE, account);
    }

    function removeStyler(address account) external onlyOwner {
        revokeRole(CAN_STYLE, account);
    }

    function applyStyle(uint16 id) external {
        if (!hasRole(CAN_STYLE, msg.sender)) {
            revert IncorrectPermissions();
        }
        uint256 r = kindaRandom(id);
        tokenMeta[id] = styles[uint16(r)];
    }

    function kindaRandom(uint16 tokenId) private view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), tokenId))
        ) % 30;
    }

    function generateImage(uint16 id) internal view returns (bytes memory) {        
        return abi.encodePacked(
            tokenStart,
            getHeight(id),
            tokenHeightEnd,
            unpackStyle(id),
            styleEnd,
            generateAddressAnimations(id),
            bgAndTilde,
            Strings.toString(id),
            tildeEnd,
            generateAddressText(id),
            svgEnd
        );
    }

    function tokenUri(uint16 id) external view returns (string memory) {
        bytes memory rawImage = generateImage(id);

        string memory attributeStr = string(abi.encodePacked(
            "\"attributes\" : [",
            buildAttribute("theme", tokenMeta[id].name),
            tokenUriSeparator,
            buildAttribute("address count", Strings.toString(addresses[id].length)),
            "]"
        ));

        bytes memory dataURI = abi.encodePacked(
            tokenUriStart, 
            Strings.toString(id), 
            "\" , ",
            tokenUriImage,
            "\"data:image/svg+xml;base64,", 
            Base64.encode(rawImage),
            "\"",
            tokenUriSeparator,
            description,
            tokenUriSeparator,
            attributeStr,
            tokenUriEnd   
        );

        return string(abi.encodePacked(
            "data:application/json,",
            dataURI
        ));
    }

    function getHeight(uint16 id) internal view returns (string memory) {
        return Strings.toString((addresses[id].length * 40) + 80);
    }

    function buildAttribute(string memory attributeType, string memory attributeValue) internal pure returns (string memory) {
        return string(abi.encodePacked("{ \"trait_type\" : \"", attributeType, "\", \"value\" : \"", attributeValue, "\" }"));
    }

    function generateAddressText(uint16 tokenId) private view returns (string memory) {
        address[] memory addressArr = addresses[tokenId];
        uint16 heightOffset = 80;
        string memory start = "<text x=\"20\" y=\"";
        string memory heightEnd = "\" class=\"text\"><textPath href=\"#path";
        string memory gmStart = "\"><tspan class=\"";
        string memory gmEnd = "\">gm</tspan> <tspan>";
        string memory end = "</tspan></textPath></text>";

        bytes memory result = "";
        

        for (uint16 i = 0; i < addressArr.length; i++) {
            string memory addressAtIndex = substring(Strings.toHexString(addressArr[i]), 0, 10);

            result = abi.encodePacked(
                result,
                start,
                Strings.toString(heightOffset + (i * 40)),
                heightEnd,
                Strings.toString(i),
                gmStart,
                getGmClass(substring(addressAtIndex,2,8)),
                gmEnd,
                addressAtIndex,
                end
            );
        }
        
        return string(result);
    }

    function getGmClass(string memory hexNum) private pure returns (string memory) {
        uint256 idx = convertString(hexNum) % 4;        
        if (idx == 0) {
            return "two";
        } else if (idx == 1) {
            return "three";
        } else if (idx == 2) {
            return "four";
        } else {
            return "five";
        }
    }

    function generateAddressAnimations(uint16 tokenId) private view returns (string memory) {
        address[] memory addressArr = addresses[tokenId];

        uint16 startingHeightOffset = 80; // increments of 40
        uint16 startingAnimationOffset = 2; // increments
        string memory pathStart = "<path id=\"path";
        string memory start = "\"><animate attributeName=\"d\" from=\"m0,";
        string memory middle = " h0\" to=\"m0,";
        string memory end = " h800\" fill=\"freeze\" dur=\"3s\" begin=\"";
        string memory realEnd = "s\"/></path>";

        bytes memory result = "";

        for (uint16 i = 0; i < addressArr.length; i++) {
            result = abi.encodePacked(
                result,
                pathStart,
                Strings.toString(i),
                start,
                Strings.toString(startingHeightOffset + (i * 40)),
                middle
            );

            result = abi.encodePacked(
                result,
                Strings.toString(startingHeightOffset + (i * 40)),
                end,
                Strings.toString(startingAnimationOffset + i),
                realEnd
            );
        }

        return string(result);
    }

    function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory ) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function numberFromAscII(bytes1 b) private pure returns (uint8 res) {
        if (b>="0" && b<="9") {
            return uint8(b) - uint8(bytes1("0"));
        } else if (b>="A" && b<="F") {
            return 10 + uint8(b) - uint8(bytes1("A"));
        } else if (b>="a" && b<="f") {
            return 10 + uint8(b) - uint8(bytes1("a"));
        }
        return uint8(b); 
    }

    function convertString(string memory str) public pure returns (uint256 value) {
        
        bytes memory b = bytes(str);
        uint256 number = 0;
        for(uint i=0;i<b.length;i++){
            number = number << 4; 
            number |= numberFromAscII(b[i]); 
        }
        return number; 
    }
}