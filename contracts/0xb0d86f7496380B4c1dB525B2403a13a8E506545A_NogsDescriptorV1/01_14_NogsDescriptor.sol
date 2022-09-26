// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./library/StringUtils.sol";
import "./library/Structs.sol";
import "./library/Base64.sol";
import "./library/NogBuilder.sol";

contract NogsDescriptorV1 is Initializable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for uint160;
    using StringUtils for string;
    using NogBuilder for string;

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                                set state
    ⌐◨—————————————————————————————————————————————————————————————◨ */    
    Structs.NogStyle[] private NogStyles;
    address private _owner;
    string public basePath;
    string public eyesPath;
    string public shadowPath;
    string public shadowAnimate;
    string public nogAnimate;
    string[5] public styleNames;
    string[5] public stylePaths;
    string[7] public shades;
    string[8] public backgroundStyles;
    uint8[5] public frameColorLength;
    string public description;
    string public name;
    bool public floatingNogs;

    function initialize(address owner) public initializer {
        _owner = owner;
        basePath = string(abi.encodePacked('<path class="a" d="M10 50v10h5V50h-5Zm15-5H10v5h15v-5Zm35 0h-5v5h5v-5ZM25 35v30h30V35H25Zm35 0v30h30V35H60Z"/>'));
        eyesPath = string(abi.encodePacked('<path fill="#fff" d="M30 40v20h10V40H30Z"/><path fill="#000" d="M40 40v20h10V40H40Z"/><path fill="#fff" d="M65 40v20h10V40H65Z"/><path fill="#000" d="M75 40v20h10V40H75Z"/>'));
        shadowPath = string(abi.encodePacked('<defs><filter id="sh" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse"><feGaussianBlur stdDeviation="4"/></filter></defs><g filter="url(#sh)" opacity="0.33"><path fill="#000" d="M81 84.875c0 1.035-11.529 1.875-25.75 1.875s-25.75-.84-25.75-1.875C29.5 83.84 41.029 83 55.25 83S81 83.84 81 84.875Z"/></g>'));
        shadowAnimate = string(abi.encodePacked('<defs><filter id="sh" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse"><feGaussianBlur stdDeviation="4"/></filter></defs><g filter="url(#sh)" opacity=".33"><animateTransform attributeName="transform" type="scale" values="1; 0.95; 1; 0.95; 1" dur="8s" repeatCount="indefinite"/><path fill="#000" d="M81 84.875c0 1.035-11.529 1.875-25.75 1.875s-25.75-.84-25.75-1.875C29.5 83.84 41.029 83 55.25 83S81 83.84 81 84.875Z"/></g>'));
        styleNames = [
            string(abi.encodePacked('Standard')),
            string(abi.encodePacked('Multi-color')),
            string(abi.encodePacked('Tri-color')),
            string(abi.encodePacked('Solid-color')),
            string(abi.encodePacked('Hip'))
        ];
        backgroundStyles = [
            string(abi.encodePacked('Standard')),
            string(abi.encodePacked('Standard')), // Cool
            string(abi.encodePacked('Standard')), // Warm
            string(abi.encodePacked('Mono')),
            string(abi.encodePacked('Mesh gradient')),
            string(abi.encodePacked('Radial gradient')),
            string(abi.encodePacked('Linear gradient')),
            string(abi.encodePacked('Light gradient'))
        ];
        
        frameColorLength = [1, 2, 3, 1, 1];
        stylePaths = [
            string(abi.encodePacked(basePath, eyesPath)),
            string(abi.encodePacked(basePath, eyesPath, '<path class="b" d="M25 35v30h30V35H25Zm25 15v10H30V40h20v10Z"/>')),
            string(abi.encodePacked(basePath, '<path fill="#000" d="M10 50v10h5V50h-5Zm15-5H10v5h15v-5Zm35 0h-5v5h5v-5ZM25 35v30h30V35H25Zm35 0v30h30V35H60Z"/><path class="a" fill="#ff0e0e" d="M45 40h-5v5h5v-5Zm35 0h-5v5h5v-5Z"/><path class="b" fill="#0adc4d" d="M35 50h-5v5h5v-5Z"/><path class="c" fill="#1929f4" d="M50 50h-5v5h5v-5Z"/><path class="b" fill="#0adc4d" d="M70 50h-5v5h5v-5Z"/><path class="c" fill="#1929f4" d="M85 50h-5v5h5v-5Z"/>')),
            string(abi.encodePacked(basePath, "<path class='y' d='M45 45v5h5V40h-5zm35-5h5v10h-5z' />")),
            string(abi.encodePacked(basePath, '<path class="a" d="M25 50H10V55H25V50ZM60 50H55V55H60V50Z"/>', eyesPath))
        ];
        nogAnimate = string(abi.encodePacked('<defs><path xmlns="http://www.w3.org/2000/svg" id="nogs" d="M53.5 41.2c-.2.7-.3 1.8 0 1.8s.2-1 0-1.8zm0 0c-.2-.8-.3-1.7 0-1.7s.2 1 0 1.7z"/></defs><animateMotion xmlns="http://www.w3.org/2000/svg" dur="8s" repeatCount="indefinite" calcMode="linear"><mpath xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#nogs"/></animateMotion>'));
        shades = [string(abi.encodePacked('rgba(255,255,255,0.45)')), string(abi.encodePacked('rgba(255,255,255,0.35)')), string(abi.encodePacked('rgba(255,255,255,0.25)')), string(abi.encodePacked('rgba(0,0,0,0.45)')), string(abi.encodePacked('rgba(0,0,0,0.35)')), string(abi.encodePacked('rgba(0,0,0,0.25)')), string(abi.encodePacked('rgba(0,0,0,0.15)'))];
        description = string(abi.encodePacked('nogs.wtf is a celebration of Nouns'));
        floatingNogs = true;

        // Run style setter
        setNogStyles();
    }
    
    function setNogStyles() public {
        require(msg.sender == _owner, 'Rejected: not owner');
        for (uint8 i = 0; i < styleNames.length; i++) {
            Structs.NogStyle memory NogStyle = Structs.NogStyle(styleNames[i], stylePaths[i], frameColorLength[i]); // This declaration shadows an existing declaration.
            NogStyles.push(NogStyle);
        }
    }

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                               get parts
    ⌐◨—————————————————————————————————————————————————————————————◨ */  

    function getColors(address minterAddress) internal pure returns (string[7] memory) {
        string memory addr = uint160(minterAddress).toHexString(20);
        string memory color;
        string[7] memory list;
        for (uint i; i < 7; ++i) {
            if (i == 0) {
                color = addr._substring(6, 2);
            } else if (i == 1) {
                color = addr._substring(6, int(i) * 8);
            } else {
                color = addr._substring(6, int(i) * 6);
            }
            list[i] = color;
        }    
        return list;
    }

    function buildSeed(Structs.Nog memory nog, uint256 tokenId) internal view returns (Structs.Seed memory seed) {
        string memory shadow;
        string memory shadowAnimation;
        string memory nogAnimation;

        if (nog.hasShadow == true) {
            shadow = shadowPath;
        }
        if (nog.hasAnimation == true && floatingNogs == true) {
            shadowAnimation = shadowAnimate;
            nogAnimation = nogAnimate;
        }

        seed = Structs.Seed({
            tokenId: tokenId,
            minterAddress: nog.minterAddress, 
            colorPalette: nog.colorPalette,
            colors: getColors(nog.minterAddress),
            nogStyle: nog.nogStyle,
            nogStyleName: NogStyles[nog.nogStyle].name,
            nogShape: NogStyles[nog.nogStyle].shape,
            frameColorLength: NogStyles[nog.nogStyle].frameColorLength,
            backgroundStyle: nog.backgroundStyle,
            backgroundStyleName: backgroundStyles[nog.backgroundStyle],
            shade: shades[nog.colorPalette[6]],            
            shadow: shadow, 
            shadowAnimation: shadowAnimation,
            hasAnimation: nog.hasAnimation
        });
    }

    function constructTokenURI(Structs.Nog memory nog, uint256 tokenId) external view returns (string memory) {
        Structs.Seed memory seed = buildSeed(nog, tokenId);
        Structs.NogParts memory nogParts = NogBuilder.buildParts(seed);

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Nogs #', abi.encodePacked(string(tokenId.toString())),'",',
                                    '"description": "', abi.encodePacked(string(description)), '",',
                                    '"image": "data:image/svg+xml;base64,', abi.encodePacked(string(nogParts.image)),'", ',
                                    '"attributes": [',
                                        NogBuilder.getAttributesMetadata(seed),
                                    ']',
                                    ', "palette": [',
                                        string(abi.encodePacked(nogParts.colorPalette)),
                                    ']}'
                                )
                            )
                        )
                    )
                )
            );
    }

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                           utility functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  

    function setDescription(string memory _description) external {
        require(msg.sender == _owner, 'Rejected: not owner');

        description = _description;
    }

    function getPseudorandomness(uint tokenId, uint num) external view returns (uint256 pseudorandomness) {        
        return uint256(keccak256(abi.encodePacked(num * tokenId * tokenId + 1, msg.sender, blockhash(block.number - 1))));
    }

    function getStylesCount() external view returns (uint16 stylesCount) {
        stylesCount = uint16(styleNames.length);
    }

    function getBackgroundIndex(uint16 backgroundOdds) external pure returns (uint16 backgroundIndex) {
        backgroundIndex = 0;
        if (backgroundOdds >= 45 && backgroundOdds < 49) { backgroundIndex = 1; }
        if (backgroundOdds >= 50 && backgroundOdds < 54) { backgroundIndex = 2; }
        if (backgroundOdds >= 55 && backgroundOdds < 67) { backgroundIndex = 3; }
        if (backgroundOdds >= 68 && backgroundOdds < 75) { backgroundIndex = 4; }
        if (backgroundOdds >= 75 && backgroundOdds < 82) { backgroundIndex = 5; }
        if (backgroundOdds >= 82 && backgroundOdds < 91) { backgroundIndex = 6; }
        if (backgroundOdds >= 91 && backgroundOdds < 100) { backgroundIndex = 7; }
        
        return backgroundIndex;
    }

    function toggleFloatingNogs() external {
        require(msg.sender == _owner, 'Rejected: not owner');

        floatingNogs = !floatingNogs;
    }
}