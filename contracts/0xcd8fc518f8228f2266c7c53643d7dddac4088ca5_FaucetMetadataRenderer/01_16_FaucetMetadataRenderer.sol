// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IPublicSharedMetadata} from "@zoralabs/nft-editions-contracts/contracts/IPublicSharedMetadata.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IFaucet} from "../IFaucet.sol";
import "./external/PTMonoFont.sol";
import "./IFaucetMetadataRenderer.sol";
import './SVG.sol';
import {ColorLib} from './ColorLib.sol';

interface IZorbRenderer {
    function zorbForAddress(address user) external view returns (string memory);
}

contract FaucetMetadataRenderer is IFaucetMetadataRenderer {
    using Strings for uint256;
    IZorbRenderer private immutable zorbRenderer;
    PtMonoFont private immutable font;
    IPublicSharedMetadata private immutable sharedMetadata;

    /// @param _sharedMetadata Link to metadata renderer contract
    /// @param _zorbRenderer zorb project svg renderer
    /// @param _font link to the font style
    constructor(
        IPublicSharedMetadata _sharedMetadata,
        address _zorbRenderer,
        PtMonoFont _font
    ) {
        sharedMetadata = _sharedMetadata;
        zorbRenderer = IZorbRenderer(_zorbRenderer);
        font = _font;
    }

    function getPolylinePoints(address faucetAddress, uint256 _tokenId, IFaucet.FaucetDetails memory fd) internal view returns (bytes memory) {
        bytes memory points;
        uint256 stepFidelity = 100;
        uint256 rangeStep = (((fd.faucetExpiry - fd.faucetStart) * 100) / stepFidelity) / 100;

        for (uint256 i = 0; i <= stepFidelity; i++) {
            uint256 x = fd.faucetStart + (i*rangeStep);
            uint256 y = IFaucet(faucetAddress).claimableAmountForFaucet(_tokenId, x);
            uint256 normalizedY = y * 100 / fd.totalAmount;

            bytes memory point = abi.encodePacked(Strings.toString(i), ",-", Strings.toString(normalizedY));
            points = abi.encodePacked(points, point, " ");
        }

        return points;
    }

    function getLinearGradient(address faucetAddress) internal pure returns (bytes memory) {
        bytes[5] memory colors = ColorLib.gradientForAddress(faucetAddress);
        return abi.encodePacked(
            '<linearGradient id="gradient" x1="0%" y1="0%" x2="0%" y2="100%">',
            '<stop offset="15.62%" stop-color="',
            colors[0],
            '" /><stop offset="39.58%" stop-color="',
            colors[1],
            '" /><stop offset="72.92%" stop-color="',
            colors[2],
            '" /><stop offset="90.63%" stop-color="',
            colors[3],
            '" /><stop offset="100%" stop-color="',
            colors[4],
            '" /></linearGradient>'
        );
    }

    function getRadialGradient(address faucetAddress) internal pure returns (bytes memory) {
        bytes[5] memory colors = ColorLib.gradientForAddress(faucetAddress);
        return abi.encodePacked(
            '<radialGradient id="gzr" gradientTransform="translate(66.4578 24.3575) scale(75.2908)" gradientUnits="userSpaceOnUse" r="1" cx="0" cy="0%">'
                // '<radialGradient fx="66.46%" fy="24.36%" id="grad">'
                '<stop offset="15.62%" stop-color="',
                colors[0],
                '" /><stop offset="39.58%" stop-color="',
                colors[1],
                '" /><stop offset="72.92%" stop-color="',
                colors[2],
                '" /><stop offset="90.63%" stop-color="',
                colors[3],
                '" /><stop offset="100%" stop-color="',
                colors[4],
                '" /></radialGradient>'
        );
    }

    function renderSVG(address _faucetAddress, uint256 _tokenId, IFaucet.FaucetDetails memory _fd) public view returns (bytes memory) {
        string memory header = string(abi.encodePacked(
            '<svg width="500" height="900" viewBox="0 0 500 900" fill="none" xmlns="http://www.w3.org/2000/svg"><defs><style>'
            "svg {background:#000; margin: 0 auto;} @font-face { font-family: CourierFont; src: url('",
            font.font(),
            "') format('opentype');} text { font-family: CourierFont; fill: white; white-space: pre; letter-spacing: 0.05em; font-size: 10px; } text.eyebrow { fill-opacity: 0.4; }"
            '</style>',
            getLinearGradient(_faucetAddress),
            getRadialGradient(_faucetAddress),
            '</defs>'
            '<rect x="39" y="41" width="422" height="65" rx="1" fill="black" />'
            '<rect x="39.5" y="41.5" width="421" height="64" rx="0.5" stroke="white" stroke-opacity="0.08" />'
            '<rect x="39" y="105" width="422" height="35" rx="1" fill="black" />'
            '<rect x="39.5" y="105.5" width="421" height="34" rx="0.5" stroke="white" stroke-opacity="0.08" />'
            '<path transform="translate(57, 57)" fill-rule="evenodd" clip-rule="evenodd" d="M2.07683 0V6.21526H28.2708L5.44618 14.2935C3.98665 14.8571 2.82212 15.6869 1.96814 16.7828C1.11416 17.8787 0.539658 19.0842 0.244645 20.3836C-0.0503676 21.6986 -0.0814215 23.0294 0.16701 24.3914C0.415442 25.7534 0.896778 26.9902 1.64207 28.1174C2.37184 29.229 3.36557 30.1526 4.5922 30.8571C5.83436 31.5616 7.29389 31.9217 8.98633 31.9217H50.8626L50.8703 31.8988C51.1535 31.914 51.4386 31.9217 51.7255 31.9217C60.4671 31.9217 67.5474 24.7828 67.5474 15.9687C67.5474 12.3143 66.333 8.94525 64.2882 6.25304L89.4471 6.2935C90.5651 6.2935 91.388 6.60661 91.9159 7.23284C92.4594 7.85906 92.7078 8.54791 92.6767 9.29937C92.6457 10.0508 92.3351 10.7397 91.7606 11.3659C91.1706 11.9921 90.3322 12.3052 89.2142 12.3052L67.7534 12.3563V12.7123L98.8254 31.9742V31.9061H105.036L104.912 9.04895C104.912 8.45404 105.036 7.93741 105.285 7.46774C105.533 7.01373 105.875 6.65365 106.309 6.43447C106.744 6.21529 107.257 6.13701 107.816 6.19964C108.375 6.26226 108.98 6.5284 109.617 6.98241L143.947 32V24.3444L113.467 2.12919C111.992 1.0333 110.377 0.391416 108.67 0.172238C106.962 -0.0469397 105.362 0.125272 103.887 0.673217C102.412 1.22116 101.186 2.12919 100.223 3.41294C99.2447 4.6967 98.7633 6.29357 98.7633 8.2192V24.7626L87.2423 18.1135L90.0682 18.0665C92.0091 18.0508 93.6084 17.5812 94.8971 16.6888C96.1858 15.7808 97.133 14.6692 97.7385 13.3385C98.3441 11.9921 98.608 10.5518 98.5459 8.98626C98.4838 7.43636 98.0801 5.98039 97.3193 4.66532C96.5585 3.35025 95.4716 2.23871 94.0431 1.36199C92.6146 0.485282 90.829 0.0469261 88.6863 0.0469261H59.4304L52.8915 0.041576C52.5116 0.0140175 52.1279 0 51.741 0C51.3629 0 50.9878 0.0133864 50.6163 0.0397145L2.07683 0ZM37.7103 8.5589L7.86839 20.227C7.23178 20.4932 6.79703 20.9315 6.56412 21.5264C6.33122 22.1213 6.28464 22.7319 6.43991 23.3425C6.59518 23.953 6.93677 24.501 7.43364 24.9706C7.9305 25.4403 8.59816 25.6751 9.42109 25.6751L39.1905 25.7073C37.1293 23.0135 35.9035 19.6361 35.9035 15.9687C35.9035 13.2949 36.5565 10.7739 37.7103 8.5589ZM61.3522 15.9687C61.3522 10.6145 57.0357 6.26223 51.741 6.26223C46.4308 6.26223 42.1143 10.6145 42.1298 15.9687C42.1298 21.3072 46.4308 25.6595 51.741 25.6595C57.0357 25.6595 61.3522 21.3229 61.3522 15.9687Z" fill="white" />'
            '<g transform="translate(393,50.25) scale(0.45 0.45)"><path d="M100 50C100 22.3858 77.6142 0 50 0C22.3858 0 0 22.3858 0 50C0 77.6142 22.3858 100 50 100C77.6142 100 100 77.6142 100 50Z" fill="url(#gzr)" /><path stroke="rgba(0,0,0,0.075)" fill="transparent" stroke-width="1" d="M50,0.5c27.3,0,49.5,22.2,49.5,49.5S77.3,99.5,50,99.5S0.5,77.3,0.5,50S22.7,0.5,50,0.5z" /></g>' // ZORB
            '<text><tspan x="57" y="125.076">',
            IERC721Metadata(_faucetAddress).name(),
            '</tspan></text>'
        ));
        string memory graph = string(abi.encodePacked(
            '<polyline fill="none" stroke="url(#gradient)" stroke-width="1" transform="translate(50,600) scale(4 4)" stroke-linejoin="round" points="',
            getPolylinePoints(_faucetAddress, _tokenId, _fd),
            '"/>'
        ));
        string memory footer = string(abi.encodePacked(
            // Supplier
            '<rect x="38" y="683" width="422" height="44" rx="1" fill="black" />'
            '<rect x="38.5" y="683.5" width="421" height="43" rx="0.5" stroke="white" stroke-opacity="0.08" />'
            '<text class="eyebrow"><tspan x="53" y="708.076">Supplier</tspan></text>'
            '<text text-anchor="end"><tspan x="427" y="708.076">',
            addressToString(_fd.supplier),
            '</tspan></text>'

            // Unclaimed Funds
            '<rect x="38" y="726" width="422" height="44" rx="1" fill="black" />'
            '<rect x="38.5" y="726.5" width="421" height="43" rx="0.5" stroke="white" stroke-opacity="0.08" />'
            '<text class="eyebrow"><tspan x="53" y="752.977">Unclaimed Funds</tspan></text>'
            '<text text-anchor="end"><tspan x="427" y="752.977">',
            parsedAmountString(_fd.totalAmount - _fd.claimedAmount, IFaucet(_faucetAddress).faucetTokenAddress()),
            '</tspan></text>'

            // Fully Vested By
            '<rect x="38" y="769" width="422" height="44" rx="1" fill="black" />'
            '<rect x="38.5" y="769.5" width="421" height="43" rx="0.5" stroke="white" stroke-opacity="0.08" />'
            '<text class="eyebrow"><tspan x="53" y="795.977">Fully Vested By</tspan></text>'
            '<text text-anchor="end"><tspan x="427" y="795.977">',
            timestampToDateTime(_fd.faucetExpiry),
            '</tspan></text>'
            '</svg>'
        ));
        return abi.encodePacked(header, graph, footer);
    }

    function attributeFragment(string memory key, string memory value, bool includeComma) private pure returns (string memory) {
        return string(abi.encodePacked('{"trait_type": "', key, '", "value": "', value, includeComma ? '"},' : '"}'));
    }

    function getTokenURIForFaucet(address _faucetAddress, uint256 _tokenId, IFaucet.FaucetDetails memory _fd) external view returns (string memory) {
        string memory faucetName = IERC721Metadata(_faucetAddress).name();

        return
        // TODO: attributes
        sharedMetadata.encodeMetadataJSON(
            abi.encodePacked(
                '{"name": "',
                faucetName,
                '", "description": "ZORA Faucets are ERC-721 tokens representing ETH or ERC-20 tokens on a vesting strategy", ',
                '"image": "data:image/svg+xml;base64,',
                sharedMetadata.base64Encode(renderSVG(_faucetAddress, _tokenId, _fd)),
                '","attributes": [',
                attributeFragment('Total Amount', _fd.totalAmount.toString(), true),
                attributeFragment('Rescindable', _fd.canBeRescinded ? 'true' : 'false', true),
                attributeFragment('Faucet Strategy', addressToString(_fd.faucetStrategy), true),
                attributeFragment('Faucet Token', addressToString(IFaucet(_faucetAddress).faucetTokenAddress()), true),
                attributeFragment('Supplier', addressToString(_fd.supplier), false),
                ']'
                '}'
            )
        );
    }

    function addressToString(address _addr) private pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(_addr)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(abi.encodePacked('0x', string(s)));
    }

    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function parsedAmountString(uint256 _rawAmt, address _tokenAddress) private view returns (string memory) {
        uint8 decimals = 18;
        string memory symbol = 'ETH';
        if(_tokenAddress != address(0)) {
            IERC20Metadata token = IERC20Metadata(_tokenAddress);
            try token.decimals() returns (uint8 _decimals) {
                decimals = _decimals;
            } catch {
                decimals = 18;
            }
            try token.symbol() returns (string memory _symbol) {
                symbol = _symbol;
            } catch {
                symbol = 'Units';
            }
        }

        uint256 factor = 10**2;
        uint256 quotient = _rawAmt / 10**decimals;
        uint256 remainder = (_rawAmt * factor / 10**decimals) % factor;
        
        return string(abi.encodePacked(quotient.toString(), '.', remainder.toString(), ' ', symbol));
    }

    function timestampToDateTime(uint256 timestamp) private pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / (24*60*60));
        uint256 secs = timestamp % (24*60*60);
        uint256 hour = secs / (60*60);
        secs = secs % (60*60);
        uint256 minute = secs / 60;
        uint256 second = secs % 60;

        return string(abi.encodePacked(
            year.toString(),
            '/',
            month.toString(),
            '/',
            day.toString(),
            ' ',
            hour.toString(),
            ':',
            minute.toString(),
            ':',
            second.toString(),
            ' UTC'
        ));
    }

    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        int __days = int(_days);

        int L = __days + 68569 + 2440588;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }
}