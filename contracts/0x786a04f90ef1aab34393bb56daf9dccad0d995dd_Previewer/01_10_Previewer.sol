//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "base64-sol/base64.sol";
import "./IArtData.sol";
import "./IColors.sol";
import "./IRenderer.sol";
import "./Structs.sol";

contract Previewer is IRenderer, ReentrancyGuard, Ownable
{
    using Strings for uint256;

    address public colorsAddr;
    uint8 spacingY = 40;
    uint8 spacingX = 100;

    function setColorsAddr(address addr) external virtual onlyOwner {
        colorsAddr = addr;
    }

    function setSpacing(uint8 spacingX_, uint8 spacingY_) external virtual onlyOwner {
        spacingX = spacingX_;
        spacingY = spacingY_;
    }

    function render(
        string calldata,
        uint256,
        BaseAttributes calldata art,
        bool,
        IArtData.ArtProps memory artProps
    )
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(address(colorsAddr) != address(0), "colors address does not exist");
        IColors colors = IColors(colorsAddr);

        string[] memory skyVals = colors.getSkyPalette(art.skyCol);
        string[] memory trailVals = colors.getPalette(art.palette);

        string memory svgStr = string(abi.encodePacked(
                svgStartStr,
                '<defs>',
                plane_def,
                sky_def[0],
                skyVals[0],
                sky_def[1],
                skyVals[1],
                sky_def[2],
                smoke_def,
                '</defs>',
                sky_draw
        ));

        for (uint256 i; i < art.planeAttributes.length; i++) {
            uint x = i / 5;
            uint y = i % 5;

            PlaneAttributes calldata plane = art.planeAttributes[i];
            uint256 angle_deg = 180 + 360 * plane.angle / art.extraParams[uint(EP.NumAngles)];
            svgStr = string.concat( svgStr,
                    plane_draw[0],
                    (x* spacingX).toString(),
                    ' ',
                    (y* spacingY).toString(),
                    plane_draw[1],
                    trailVals[plane.trailCol % trailVals.length],
                    plane_draw[2],
                    angle_deg.toString(),
                    plane_draw[3]
            );
        }

        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(abi.encodePacked( svgStr, svgEndStr)))));
    }

    string public svgStartStr = '<svg width="100%" height="100%" viewBox="0 0 200 200" \n\
version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xml:space="preserve" \n\
style="fill-rule:evenodd;clip-rule:evenodd;stroke-linejoin:round;stroke-miterlimit:2;"> \n\
';
    string public svgEndStr = '</svg>';

    string public plane_def = '\n\
<path id="plane" \n\
d="M37,58l39,0l0,-32.5c0,0 0.417,-11.417 12.5,-11.5c12.083,-0.083 12.481,11.489 12.5,11.5c0.019,0.011 0,32.5 0,32.5l39,0c0,0 17.667,1.167 17.5,19c-0.167,17.833 -17.5,19 -17.5,19l-39,0l0,44c0,0 12.75,-0.25 12.5,12.5c-0.25,12.75 -11.5,12.5 -11.5,12.5l-27,0c0,0 -11.333,0.167 -11.5,-12.5c-0.167,-12.667 12.5,-12.5 12.5,-12.5l0,-44l-39,0c0,0 -17.667,-0.25 -17.5,-19c0.167,-18.75 17.5,-19 17.5,-19Z" \n\
style="fill:#fff;"/>';

    string[] public sky_def = [
'<linearGradient id="sky" gradientTransform="rotate(90)"> \n\
<stop offset="5%" stop-color="#',
//'B2FBFF',
'"/> <stop offset="95%" stop-color="#',
//'4FA9F2',
'"/> </linearGradient>'];

    string public smoke_def = '<line id="smoke" x1="10" y1="18" x2="40" y2="18" stroke-width="5%"/>';

    string public sky_draw = '<rect x="0" y="0" width="100%" height="100%" fill="url(#sky)"/>';

    string[] public plane_draw = [
'<g transform="translate(',
//0 ',
//'0',
')"> <use xlink:href="#smoke" stroke="#',
//'c8823c',
'" /> <use xlink:href="#plane" fill="none" stroke="black" transform="translate(50 0) scale(0.2 0.2) rotate(',
//'30
' 88 89)"/> </g>'];

}