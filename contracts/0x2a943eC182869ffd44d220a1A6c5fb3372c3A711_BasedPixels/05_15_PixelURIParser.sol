// SPDX-License-Identifier: Unlicense
// Creator: 0xBasedPixel; Based Pixel Labs/Yeety Labs; 1 yeet = 1 yeet
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./HexChars.sol";

library PixelURIParser {
    string private constant startStr = "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='100%25' height='100%25' viewBox='0 0 16 16'>";
    string private constant endStr = "</svg>";
    uint256 private constant rectStart = 27340891238026048097263813569089141950244693325490254729102276207101788291072;
    uint256 private constant heightNum = 14658463167467038245011812029062285656083636211927847345906851957315119087616;
    uint256 private constant inner1 = 57183955277861053027410940421065042940111934717952;
    uint256 private constant inner2 = 793586231870635386738538214064128;

    function getPixelURI(uint256[12] memory slices, uint256 tokenId) public pure returns (string memory) {
        bytes32[] memory rectComponents = new bytes32[](512);

        uint256 uniqueColors = 0;
        uint256[16] memory colorTracker = [uint256(0), uint256(0),uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)];
        uint256 rTotal = 0;
        uint256 gTotal = 0;
        uint256 bTotal = 0;
        uint256 brightnessSum = 0;

        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 64; j++) {
                uint256 hcR = slices[i*3];
                hcR = (hcR>>(j*4))%16;
                uint256 hcG = slices[i*3+1];
                hcG = (hcG>>(j*4))%16;
                uint256 hcB = slices[i*3+2];
                hcB = (hcB>>(j*4))%16;

                uint256 strNum1 = rectStart+((48 + ((((i*64 + j)%16) - (((i*64 + j)%16)%10))/10))<<176)+((48 + (((i*64 + j)%16)%10))<<168)+inner1;
                strNum1 = strNum1+((48 + ((((i*64 + j)>>4) - (((i*64 + j)>>4)%10))/10))<<120)+((48 + (((i*64 + j)>>4)%10))<<112)+inner2;
                uint256 strNum2 = heightNum+((HexChars.getHex(hcR))<<80);
                strNum2 = strNum2+((HexChars.getHex(hcG))<<72);
                strNum2 = strNum2+((HexChars.getHex(hcB))<<64)+2823543661105512448; //+(39<<56)+(47<<48)+(62<<40)
                rectComponents[(i*64 + j)*2] = bytes32(strNum1);
                rectComponents[(i*64 + j)*2 + 1] = bytes32(strNum2);

                if (((colorTracker[hcR])>>(hcG*16+hcB))%2 == 0) {
                    uniqueColors += 1;
                    colorTracker[hcR] += (uint256(1)<<(hcG*16+hcB));
                }
                rTotal += hcR;
                gTotal += hcG;
                bTotal += hcB;
                brightnessSum += (2126*hcR + 7152*hcG + 722*hcB);
            }
        }

        if ((rTotal+gTotal+bTotal) == 0) {
            rTotal = 1;
            gTotal = 1;
            bTotal = 1;
        }
        uint256 rDom = (rTotal*10000)/(rTotal+gTotal+bTotal);
        uint256 gDom = (gTotal*10000)/(rTotal+gTotal+bTotal);
        uint256 bDom = (bTotal*10000)/(rTotal+gTotal+bTotal);

        string memory brightnessStr;
        if ((brightnessSum/4096) == 10000) {
            brightnessStr = "1";
        }
        else if ((brightnessSum/4096) >= 1000) {
            brightnessStr = string(abi.encodePacked("0.",Strings.toString(brightnessSum/4096)));
        }
        else if ((brightnessSum/4096) >= 100) {
            brightnessStr = string(abi.encodePacked("0.0",Strings.toString(brightnessSum/4096)));
        }
        else if ((brightnessSum/4096) >= 10) {
            brightnessStr = string(abi.encodePacked("0.00",Strings.toString(brightnessSum/4096)));
        }
        else if ((brightnessSum/4096) >= 1) {
            brightnessStr = string(abi.encodePacked("0.000",Strings.toString(brightnessSum/4096)));
        }
        else {
            brightnessStr = "0";
        }

        return string(
            abi.encodePacked(
                "data:application/json;utf8,","{\"name\":\"Token: ",
                Strings.toString(tokenId),"\",\"description\":\"Based Pixels #",
                Strings.toString(tokenId),"\",\"image\":\"data:image/svg+xml;utf8,",
                startStr,rectComponents,endStr,"\",\"attributes\":",
                "[{\"trait_type\":\"Unique Colors\",\"value\":",
                Strings.toString(uniqueColors),"},{\"trait_type\":\"Red Dominance\",",
                "\"value\":0.",Strings.toString(rDom),"},",
                "{\"trait_type\":\"Green Dominance\",\"value\":0.",
                Strings.toString(gDom),"},{\"trait_type\":",
                "\"Blue Dominance\",\"value\":0.",Strings.toString(bDom),"},",
                "{\"trait_type\":\"Average Brightness\",\"value\":",brightnessStr,"}]}"));
    }
}