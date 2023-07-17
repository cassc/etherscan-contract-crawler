// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ICheckson.sol";

struct Indexes{
    uint256 i;
    uint256 colorIndex;
    uint8 pairTracker;
}

library ChecksonsArt {

    function getPreviewImage(
        string memory backgroundColor, 
        string memory jacketColor
    )
    external
    pure
    returns(bytes memory)
    {
        bytes memory SVG_START = "<svg version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' x='0px' y='0px' viewBox='0 0 500 500' style='enable-background:new 0 0 500 500;' xml:space='preserve'><style type='text/css'>";
        bytes memory SVG_END = ".whiteTransparent{opacity:0.18;fill:#FFFFFF;}.black{fill:#000000;}.creame{fill:#DDA894;} .pattern{fill:url(#chekesPattenr);} .silver{fill:#e3e3e3;} </style> <defs> <path id='check' d='M19.76,8.91c-0.3-0.94-0.94-1.6-1.79-2.07C17.9,6.8,17.87,6.77,17.9,6.69c0.18-0.57,0.23-1.16,0.13-1.75 c-0.18-1.08-0.75-1.9-1.72-2.41c-0.88-0.46-1.81-0.49-2.76-0.21c-0.09,0.03-0.12,0.01-0.17-0.07c-0.24-0.45-0.55-0.85-0.95-1.17 c-1-0.8-2.12-1.01-3.32-0.55C8.25,0.85,7.65,1.47,7.22,2.26C7.18,2.33,7.15,2.35,7.07,2.32C6.69,2.21,6.31,2.15,5.87,2.15 c-0.16,0-0.36,0.01-0.56,0.04C4.21,2.39,3.38,2.96,2.88,3.97C2.44,4.85,2.43,5.76,2.7,6.68C2.73,6.77,2.71,6.8,2.64,6.84 C2.2,7.08,1.81,7.38,1.49,7.76C0.71,8.7,0.45,9.77,0.84,10.95c0.3,0.94,0.95,1.59,1.8,2.06c0.08,0.04,0.09,0.08,0.06,0.16 c-0.17,0.55-0.23,1.12-0.14,1.7c0.21,1.26,0.89,2.15,2.09,2.61c0.79,0.3,1.59,0.29,2.4,0.05c0.08-0.02,0.12-0.02,0.16,0.06 c0.23,0.44,0.54,0.83,0.93,1.15c0.92,0.76,1.97,1.01,3.12,0.66c0.97-0.29,1.65-0.94,2.13-1.81c0.04-0.07,0.07-0.09,0.15-0.07 c0.57,0.17,1.14,0.23,1.73,0.13c1.1-0.18,1.93-0.74,2.44-1.74c0.45-0.88,0.48-1.81,0.2-2.75c-0.02-0.08-0.02-0.12,0.06-0.16 c0.44-0.23,0.83-0.54,1.15-0.92C19.89,11.14,20.14,10.08,19.76,8.91z M14.69,7.58c-0.61,0.67-1.23,1.34-1.84,2.01 c-1.28,1.39-2.55,2.79-3.83,4.18c-0.07,0.08-0.11,0.09-0.19,0.01c-1.11-1.12-2.22-2.23-3.34-3.34c-0.07-0.07-0.07-0.1,0-0.17 c0.4-0.39,0.79-0.79,1.18-1.19c0.05-0.06,0.08-0.05,0.14,0c0.66,0.66,1.32,1.32,1.97,1.98c0.07,0.07,0.1,0.06,0.16,0 c1.45-1.59,2.91-3.17,4.37-4.76c0.05-0.05,0.08-0.07,0.14-0.01c0.41,0.39,0.83,0.77,1.24,1.15c0.02,0.02,0.04,0.04,0.07,0.06 C14.72,7.54,14.71,7.56,14.69,7.58z'/> </defs> <pattern width='20.85' height='20.85' patternUnits='userSpaceOnUse' id='checks' viewBox='0 0 20.85 20.85' style='overflow:visible;' > <g> <use href='#check' class='whiteTransparent'></use> </g> </pattern> <!-- Background --> <circle class='background' cx='250.38' cy='249.91' r='249.62'/> <pattern id='chekesPattenr' xlink:href='#checks'> </pattern> <circle class='pattern' cx='250.38' cy='249.91' r='249.62'/> <!-- Checkson --> <g transform='translate(0, -20.85)'> <use href='#check' class='black' y='83.4' x='166.8'></use> <use href='#check' class='black' y='83.4' x='187.65'></use> <use href='#check' class='black' y='104.25' x='145.95'></use> <use href='#check' class='black' y='104.25' x='166.8'></use> <use href='#check' class='black' y='104.25' x='187.65'></use> <use href='#check' class='black' y='104.25' x='208.5'></use> <use href='#check' class='creame' y='125.37' x='166.8'></use> <use href='#check' class='creame' y='125.37' x='187.65'></use> <use href='#check' class='creame' y='125.37' x='62.55'></use> <use href='#check' class='creame' y='125.37' x='83.4'></use> <!-- Jacket starts --> <use href='#check' class='black' y='146.22' x='104.25'></use> <use href='#check' class='jacket' y='146.22' x='125.1'></use> <use href='#check' class='jacket' y='146.22' x='145.95'></use> <use href='#check' class='black' y='146.22' x='166.8'></use> <use href='#check' class='black' y='146.22' x='187.65'></use> <use href='#check' class='jacket' y='146.22' x='208.5'></use> <use href='#check' class='black' y='167.07' x='104.25'></use> <use href='#check' class='jacket' y='167.07' x='125.1'></use> <use href='#check' class='jacket' y='167.07' x='145.95'></use> <use href='#check' class='black' y='167.07' x='166.8'></use> <use href='#check' class='black' y='167.07' x='187.65'></use> <use href='#check' class='jacket' y='167.07' x='208.5'></use> <use href='#check' class='jacket' y='167.07' x='229.35'></use> <use href='#check' class='jacket' y='187.92' x='145.95'></use> <use href='#check' class='black' y='187.92' x='166.8'></use> <use href='#check' class='black' y='187.92' x='187.65'></use> <use href='#check' class='black' y='187.92' x='208.5'></use> <use href='#check' class='jacket' y='187.92' x='229.35'></use> <use href='#check' class='jacket' y='187.92' x='250.2'></use> <use href='#check' class='jacket' y='208.77' x='145.95'></use> <use href='#check' class='black' y='208.77' x='166.8'></use> <use href='#check' class='black' y='208.77' x='187.65'></use> <use href='#check' class='black' y='208.77' x='208.5'></use> <use href='#check' class='jacket' y='208.77' x='229.35'></use> <use href='#check' class='jacket' y='208.77' x='250.2'></use> <use href='#check' class='jacket' y='229.62' x='145.95'></use> <use href='#check' class='black' y='229.62' x='166.8'></use> <use href='#check' class='black' y='229.62' x='187.65'></use> <use href='#check' class='jacket' y='229.62' x='208.5'></use> <use href='#check' class='jacket' y='229.62' x='229.35'></use> <use href='#check' class='jacket' y='229.62' x='250.2'></use> <use href='#check' class='black' y='250.47' x='166.8'></use> <use href='#check' class='black' y='250.47' x='187.65'></use> <use href='#check' class='jacket' y='250.47' x='208.5'></use> <use href='#check' class='creame' y='250.47' x='229.35'></use> <use href='#check' class='jacket' y='250.47' x='250.2'></use> <!-- Jacket ends --> <use href='#check' class='black' y='271.32' x='187.65'></use> <use href='#check' class='black' y='271.32' x='208.5'></use> <use href='#check' class='creame' y='271.32' x='229.35'></use> <use href='#check' class='black' y='271.32' x='250.2'></use> <use href='#check' class='black' y='292.17' x='187.65'></use> <use href='#check' class='black' y='292.17' x='208.5'></use> <use href='#check' class='black' y='292.17' x='229.35'></use><use href='#check' class='black' y='292.17' x='250.2'></use><use href='#check' class='black' y='313.02' x='166.8'></use><use href='#check' class='black' y='313.02' x='187.65'></use> <use href='#check' class='black' y='313.02' x='250.2'></use><use href='#check' class='black' y='333.87' x='166.8'></use><use href='#check' class='black' y='333.87' x='187.65'></use> <use href='#check' class='black' y='333.87' x='250.2'></use><use href='#check' class='black' y='333.87' x='271.02'></use><use href='#check' class='black' y='354.72' x='166.8'></use><use href='#check' class='black' y='354.72' x='271.02'></use><use href='#check' class='black' y='375.57' x='145.95'></use> <use href='#check' class='black' y='375.57' x='166.8'></use><use href='#check' class='black' y='375.57' x='271.02'></use><use href='#check' class='black' y='375.57' x='291.87'></use><use href='#check' class='black' y='396.42' x='145.95'></use><use href='#check' class='black' y='396.42' x='271.02'></use> <use href='#check' class='black' y='396.42' x='291.87'></use><use href='#check' class='silver' y='417.27' x='145.95'></use><use href='#check' class='silver' y='417.27' x='291.87'></use><use href='#check' class='black' y='438.12' x='145.95'></use><use href='#check' class='black' y='438.12' x='291.87'></use><use href='#check' class='black' y='438.12' x='145.95'></use><use href='#check' class='black' y='458.97' x='125.1'></use><use href='#check' class='black' y='458.97' x='145.95'></use></g></svg>";
        bytes memory uniqueStyle = abi.encodePacked('.background{fill:#',backgroundColor,';}.jacket{fill:#',jacketColor,';}');
        return abi.encodePacked(SVG_START,uniqueStyle,SVG_END);
    }


 function getHtmlAnimation(
       IChecksons.HTMLAnimationAssets memory HTMLassets
    )
    external
    pure
    returns(bytes memory)
    {
        uint256 checksCount = HTMLassets.colors.length;
        string memory HTML_A = '<!DOCTYPE html><html lang="en"><head><meta name="viewport" content="width=device-width, initial-scale=1.0"></head><body><style>'; 
        string memory HTML_B = '#container{height:500px;width:500px;max-width: 95vw;max-height: 95vw;margin-top:calc((100vh - 500px) /2);margin-left:calc((100vw - 500px) /2);position:relative;}.color{ border-radius:50%;';
        string memory HTML_C = 'div,img{position:absolute;top:0;left:0;height:100%;width:100%;}audio{position:absolute;z-index:9;width:100px;bottom:0;}@media screen and (max-width: 640px){ #container{ margin: 50px auto; }}@media screen and (max-height: 550px){#container{margin:0px auto;}}</style><div id="container"><div class="color"></div><div class="background"></div>';
        bytes memory assets = abi.encodePacked('<img src="',HTMLassets._baseAssetURI, HTMLassets.animationHash,'" alt="check" class="check"/></div><audio loop controls ><source src="',HTMLassets._baseAssetURI, HTMLassets.audioHash, '" type="audio/mpeg"></audio></body></html>');
        bytes memory backgroundStyle = abi.encodePacked('.background{background:url(',HTMLassets._baseAssetURI,'QmZMcqVAFsXVerEdBkC94VWMPtqPrEkvvzF6vuKECJ3NSJ);background-size:contain;opacity:0.6;border-radius:50%;}');
        bytes memory add_animation = abi.encodePacked('background: #',HTMLassets.colors[0],';');
        if(checksCount > 1) add_animation = abi.encodePacked(add_animation, 'animation: backgroundChange ', uint2str(checksCount) ,'s infinite;');
        add_animation = abi.encodePacked(add_animation,'}');
    
        bytes memory animation = '';

        if(checksCount > 1){
            animation = abi.encodePacked('@keyframes backgroundChange{0%{background:#', HTMLassets.colors[0], ';}');
            Indexes memory indexes = Indexes(0, 0, 1);
             for(indexes.i=0 ;indexes.i < HTMLassets.sqcItems.length;indexes.i++){
                    animation = abi.encodePacked(animation, HTMLassets.sqcItems[indexes.i],'%{background:#', HTMLassets.colors[indexes.colorIndex], ';}');
                    indexes.pairTracker++;
                    if(indexes.pairTracker == 2){
                        indexes.pairTracker = 0;
                        indexes.colorIndex++;
                    }
             }
             animation = abi.encodePacked(animation,'}');
        }
        return bytes(abi.encodePacked(HTML_A,animation,HTML_B,add_animation,backgroundStyle,HTML_C,assets));
    }

    function uint2str(uint256 _i) 
    public 
    pure 
    returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            ++len;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}