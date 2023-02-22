// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";

library RenderEngine {
    error ValueOutOfRange();

    function _shortenAddr(address addr) private pure returns (string memory) {
        uint256 value = uint160(addr);
        bytes memory allBytes = bytes(Strings.toHexString(value, 20));

        string memory newString = string(allBytes);

        return
            string(
                abi.encodePacked(
                    _substring(newString, 0, 6),
                    unicode"…",
                    _substring(newString, 38, 42)
                )
            );
    }

    function _substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    string constant P1 =
        '<svg width="1244" height="704" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><path d="M2.5 701.5V95.051L97.02 2.5H1241.5v699H2.5z" fill="url(#prefix__p0)" stroke="url(#prefix__p1)" stroke-width="5"/><path d="M1240 10H86.11v2.346H1240V10zM76.727 19.384H1240v2.346H76.727v-2.346zM4 169.529h1236v2.346H4v-2.346zM1240 56.92H39.19v2.346H1240V56.92zM4 207.066h1236v2.346H4v-2.346zM1240 94.457H4v2.346h1236v-2.346zM4 329.059h1236v2.346H4v-2.346zM1240 244.602H4v2.346h1236v-2.346zM4 131.993h1236v2.346H4v-2.346zM1240 282.138H4v2.346h1236v-2.346zM57.959 38.152H1240v2.346H57.959v-2.346zM1240 188.298H4v2.346h1236v-2.346zM20.422 75.689H1240v2.346H20.422v-2.346zM1240 310.291H4v2.346h1236v-2.346zM4 225.834h1236v2.346H4v-2.346zM1240 113.225H4v2.346h1236v-2.346zM4 263.37h1236v2.346H4v-2.346zM1240 150.761H4v2.346h1236v-2.346zM4 300.907h1236v2.346H4v-2.346zM4 160.145h1236v2.346H4v-2.346zM1240 47.536H48.574v2.346H1240v-2.346zM4 197.682h1236v2.346H4v-2.346zM1240 85.073H11.038v2.346H1240v-2.346zM4 319.675h1236v2.346H4v-2.346zM1240 235.218H4v2.346h1236v-2.346zM4 122.609h1236v2.346H4v-2.346zM1240 272.754H4v2.346h1236v-2.346zM67.343 28.768H1240v2.346H67.343v-2.346zM1240 178.913H4v2.347h1236v-2.347zM29.806 66.305H1240v2.345H29.806v-2.346zM1240 216.45H4v2.346h1236v-2.346zM4 103.841h1236v2.346H4v-2.346zM1240 338.443H4v2.346h1236v-2.346zM4 253.986h1236v2.346H4v-2.346zM1240 141.377H4v2.346h1236v-2.346zM4 291.522h1236v2.346H4v-2.346zM4 347.827h1236v2.346H4v-2.346zM1240 357.211H4v2.346h1236v-2.346zM1240 507.356H4v2.346h1236v-2.346zM4 394.747h1236v2.346H4v-2.346zM1240 544.893H4v2.346h1236v-2.346zM4 432.284h1236v2.346H4v-2.346zM1240 666.886H4v2.346h1236v-2.346zM4 582.429h1236v2.346H4v-2.346zM1240 469.82H4v2.346h1236v-2.346zM4 619.965h1236v2.346H4v-2.346zM1240 375.979H4v2.346h1236v-2.346zM4 526.125h1236v2.346H4v-2.346zM1240 413.516H4v2.346h1236v-2.346zM4 648.118h1236v2.346H4v-2.346zM1240 563.661H4v2.346h1236v-2.346zM4 451.052h1236v2.346H4v-2.346zM1240 601.197H4v2.346h1236v-2.346zM4 488.588h1236v2.346H4v-2.346zM1240 638.734H4v2.346h1236v-2.346zM1240 497.972H4v2.346h1236v-2.346zM4 385.363h1236v2.346H4v-2.346zM1240 535.509H4v2.346h1236v-2.346zM4 422.9h1236v2.346H4V422.9zM1240 657.502H4v2.346h1236v-2.346zM4 573.045h1236v2.346H4v-2.346zM1240 460.436H4v2.346h1236v-2.346zM4 610.581h1236v2.346H4v-2.346zM1240 366.595H4v2.346h1236v-2.346zM4 516.74h1236v2.346H4v-2.346zM1240 404.131H4v2.347h1236v-2.347zM4 554.277h1236v2.346H4v-2.346zM1240 441.668H4v2.346h1236v-2.346zM4 676.27h1236v2.346H4v-2.346zM1240 685.654H4V688h1236v-2.346zM4 591.813h1236v2.346H4v-2.346zM1240 479.204H4v2.346h1236v-2.346zM4 629.349h1236v2.346H4v-2.346z" fill="url(#prefix__p2)"/><path d="M1244 12V0H96L0 94v18L102 12h1142z" fill="#F98701"/><text dx="76" dy="605" dominant-baseline="central" text-anchor="left" style="height:100px" font-family="VT323" textLength="1075" font-size="60" fill="#FF8A01">Seed: ';
    string constant P2 =
        '</text><text dx="76" dy="116" dominant-baseline="central" text-anchor="left" font-family="Black Ops One" textLength="300" font-weight="400" font-size="60" fill="#FF8A01">LifeScore</text><text dx="76" dy="230" dominant-baseline="central" text-anchor="left" font-family="Black Ops One" font-weight="400" font-size="120" fill="#FF8A01">';
    string constant P3 =
        '</text><text dx="697" dy="425" dominant-baseline="central" text-anchor="left" font-family="VT323" font-weight="100" font-size="79" fill="#65E250">Re:';
    string constant P4 =
        '</text><text dx="955" dy="425" dominant-baseline="central" text-anchor="left" font-family="VT323" font-weight="400" font-size="78" fill="#65E250">Age:';
    string constant P5 =
        '</text><text dx="382" dy="425" dominant-baseline="central" text-anchor="middle" font-family="VT323" textLength="350" font-weight="400" font-size="78" fill="#FFF">';
    string constant P6 =
        '</text><text dx="975" dy="116" dominant-baseline="central" text-anchor="middle" style="height:100px" font-family="Black Ops One" font-size="56" fill="#FF8A01">DegenReborn</text><text dx="800" dy="230" dominant-baseline="central" text-anchor="right" font-family="VT323" font-weight="400" font-size="96" fill="url(#prefix__p75)">';
    string constant P7 =
        '</text><path fill="#FFD058" d="M1114 204v6h-6v-6z"/><path fill="#E86609" d="M1138 204v6h-6v-6z"/><path fill="#F8C156" d="M1162 204v6h-6v-6z"/><path fill="#fff" d="M1102 204v6h-6v-6z"/><path fill="#E86609" d="M1126 204v6h-6v-6z"/><path fill="#F8C156" d="M1150 204v6h-6v-6z"/><path fill="#000" d="M1174 204v6h-6v-6zM1096 204v6h-6v-6z"/><path fill="#FFD058" d="M1120 204v6h-6v-6z"/><path fill="#C04A07" d="M1144 204v6h-6v-6z"/><path fill="#F29914" d="M1168 204v6h-6v-6z"/><path fill="#FFD058" d="M1108 204v6h-6v-6z"/><path fill="#E86609" d="M1132 204v6h-6v-6z"/><path fill="#F8C156" d="M1156 204v6h-6v-6z"/><path fill="#fff" d="M1114 192v6h-6v-6z"/><path fill="#F8C156" d="M1138 192v6h-6v-6z"/><path fill="#000" d="M1162 192v6h-6v-6z"/><path fill="#FFD058" d="M1126 192v6h-6v-6z"/><path fill="#F29914" d="M1150 192v6h-6v-6z"/><path fill="#fff" d="M1120 192v6h-6v-6z"/><path fill="#F8C156" d="M1144 192v6h-6v-6z"/><path fill="#000" d="M1108 192v6h-6v-6z"/><path fill="#FFD058" d="M1132 192v6h-6v-6z"/><path fill="#F29914" d="M1156 192v6h-6v-6z"/><path fill="#000" d="M1120 180h6v6h-6zM1090 215.999v6h-6v-6z"/><path fill="#FFD058" d="M1114 215.999v6h-6v-6z"/><path fill="#F8C156" d="M1138 215.999v6h-6v-6zM1162 215.999v6h-6v-6z"/><path fill="#FFD058" d="M1102 215.999v6h-6v-6z"/><path fill="#C04A07" d="M1126 215.999v6h-6v-6zM1150 215.999v6h-6v-6z"/><path fill="#F29914" d="M1174 215.999v6h-6v-6z"/><path fill="#fff" d="M1096 215.999v6h-6v-6z"/><path fill="#E86609" d="M1120 215.999v6h-6v-6zM1144 215.999v6h-6v-6z"/><path fill="#F8C156" d="M1168 215.999v6h-6v-6z"/><path fill="#FFD058" d="M1108 215.999v6h-6v-6zM1132 215.999v6h-6v-6z"/><path fill="#F8C156" d="M1156 215.999v6h-6v-6z"/><path fill="#000" d="M1180 215.999v6h-6v-6zM1114 186v6h-6v-6z"/><path fill="#F29914" d="M1138 186v6h-6v-6z"/><path fill="#fff" d="M1126 186v6h-6v-6z"/><path fill="#000" d="M1150 186v6h-6v-6zM1120 186v6h-6v-6z"/><path fill="#F29914" d="M1144 186v6h-6v-6z"/><path fill="#fff" d="M1132 186v6h-6v-6z"/><path fill="#000" d="M1156 186v6h-6v-6z"/><path fill="#FFD058" d="M1114 209.999v6h-6v-6z"/><path fill="#F8C056" d="M1138 209.999v6h-6v-6z"/><path fill="#F8C156" d="M1162 209.999v6h-6v-6z"/><path fill="#fff" d="M1102 209.999v6h-6v-6z"/><path fill="#C04A07" d="M1126 209.999v6h-6v-6zM1150 209.999v6h-6v-6z"/><path fill="#000" d="M1174 209.999v6h-6v-6zM1096 209.999v6h-6v-6z"/><path fill="#E86609" d="M1120 209.999v6h-6v-6zM1144 209.999v6h-6v-6z"/><path fill="#F29914" d="M1168 209.999v6h-6v-6z"/><path fill="#FFD058" d="M1108 209.999v6h-6v-6zM1132 209.999v6h-6v-6z"/><path fill="#F8C156" d="M1156 209.999v6h-6v-6z"/><path fill="#FFD058" d="M1114 198v6h-6v-6z"/><path fill="#F8C156" d="M1138 198v6h-6v-6z"/><path fill="#F29914" d="M1162 198v6h-6v-6z"/><path fill="#000" d="M1102 198v6h-6v-6z"/><path fill="#FFD058" d="M1126 198v6h-6v-6z"/><path fill="#F8C156" d="M1150 198v6h-6v-6z"/><path fill="#FFD058" d="M1120 198v6h-6v-6z"/><path fill="#F8C156" d="M1144 198v6h-6v-6z"/><path fill="#000" d="M1168 198v6h-6v-6z"/><path fill="#fff" d="M1108 198v6h-6v-6z"/><path fill="#FFD058" d="M1132 198v6h-6v-6z"/><path fill="#F8C156" d="M1156 198v6h-6v-6z"/><path fill="#000" d="M1126 180h6v6h-6zM1090 221.999v6h-6v-6z"/><path fill="#FFD058" d="M1114 221.999v6h-6v-6z"/><path fill="#E86609" d="M1138 221.999v6h-6v-6z"/><path fill="#F8C156" d="M1162 221.999v6h-6v-6z"/><path fill="#FFD058" d="M1102 221.999v6h-6v-6z"/><path fill="#E86609" d="M1126 221.999v6h-6v-6z"/><path fill="#F8C156" d="M1150 221.999v6h-6v-6z"/><path fill="#F29914" d="M1174 221.999v6h-6v-6z"/><path fill="#fff" d="M1096 221.999v6h-6v-6z"/><path fill="#E86609" d="M1120 221.999v6h-6v-6z"/><path fill="#C04A07" d="M1144 221.999v6h-6v-6z"/><path fill="#F8C156" d="M1168 221.999v6h-6v-6z"/><path fill="#FFD058" d="M1108 221.999v6h-6v-6z"/><path fill="#E86609" d="M1132 221.999v6h-6v-6z"/><path fill="#F8C156" d="M1156 221.999v6h-6v-6z"/><path fill="#000" d="M1180 221.999v6h-6v-6zM1132 180h6v6h-6zM1090 227.999v6h-6v-6z"/><path fill="#FFD058" d="M1114 227.999v6h-6v-6z"/><path fill="#F8C056" d="M1138 227.999v6h-6v-6z"/><path fill="#F8C156" d="M1162 227.999v6h-6v-6z"/><path fill="#FFD058" d="M1102 227.999v6h-6v-6z"/><path fill="#C04A07" d="M1126 227.999v6h-6v-6zM1150 227.999v6h-6v-6z"/><path fill="#F29914" d="M1174 227.999v6h-6v-6z"/><path fill="#fff" d="M1096 227.999v6h-6v-6z"/><path fill="#E86609" d="M1120 227.999v6h-6v-6zM1144 227.999v6h-6v-6z"/><path fill="#F8C156" d="M1168 227.999v6h-6v-6z"/><path fill="#FFD058" d="M1108 227.999v6h-6v-6zM1132 227.999v6h-6v-6z"/><path fill="#F8C156" d="M1156 227.999v6h-6v-6z"/><path fill="#000" d="M1180 227.999v6h-6v-6z"/><path fill="#FFD058" d="M1114 251.999v6h-6v-6z"/><path fill="#F8C156" d="M1138 251.999v6h-6v-6z"/><path fill="#F29914" d="M1162 251.999v6h-6v-6z"/><path fill="#000" d="M1102 251.999v6h-6v-6z"/><path fill="#FFD058" d="M1126 251.999v6h-6v-6z"/><path fill="#F8C156" d="M1150 251.999v6h-6v-6z"/><path fill="#FFD058" d="M1120 251.999v6h-6v-6z"/><path fill="#F8C156" d="M1144 251.999v6h-6v-6z"/><path fill="#000" d="M1168 251.999v6h-6v-6z"/><path fill="#fff" d="M1108 251.999v6h-6v-6z"/><path fill="#FFD058" d="M1132 251.999v6h-6v-6z"/><path fill="#F8C156" d="M1156 251.999v6h-6v-6z"/><path fill="#FFD058" d="M1114 239.999v6h-6v-6z"/><path fill="#F8C156" d="M1138 239.999v6h-6v-6zM1162 239.999v6h-6v-6z"/><path fill="#fff" d="M1102 239.999v6h-6v-6z"/><path fill="#C04A07" d="M1126 239.999v6h-6v-6z"/><path fill="#E86609" d="M1150 239.999v6h-6v-6z"/><path fill="#000" d="M1174 239.999v6h-6v-6zM1096 239.999v6h-6v-6z"/><path fill="#E86609" d="M1120 239.999v6h-6v-6z"/><path fill="#F8C056" d="M1144 239.999v6h-6v-6z"/><path fill="#F29914" d="M1168 239.999v6h-6v-6z"/><path fill="#FFD058" d="M1108 239.999v6h-6v-6zM1132 239.999v6h-6v-6z"/><path fill="#C04A07" d="M1156 239.999v6h-6v-6z"/><path fill="#000" d="M1114 263.998v6h-6v-6z"/><path fill="#F29914" d="M1138 263.998v6h-6v-6z"/><path fill="#FFE6A6" d="M1126 263.998v6h-6v-6z"/><path fill="#000" d="M1150 263.998v6h-6v-6zM1120 263.998v6h-6v-6z"/><path fill="#F29914" d="M1144 263.998v6h-6v-6z"/><path fill="#FFE6A6" d="M1132 263.998v6h-6v-6z"/><path fill="#000" d="M1156 263.998v6h-6v-6zM1138 180h6v6h-6zM1090 233.999v6h-6v-6z"/><path fill="#FFD058" d="M1114 233.999v6h-6v-6z"/><path fill="#F8C056" d="M1138 233.999v6h-6v-6z"/><path fill="#F8C156" d="M1162 233.999v6h-6v-6z"/><path fill="#FFD058" d="M1102 233.999v6h-6v-6z"/><path fill="#C04A07" d="M1126 233.999v6h-6v-6zM1150 233.999v6h-6v-6z"/><path fill="#F29914" d="M1174 233.999v6h-6v-6z"/><path fill="#fff" d="M1096 233.999v6h-6v-6z"/><path fill="#E86609" d="M1120 233.999v6h-6v-6zM1144 233.999v6h-6v-6z"/><path fill="#F8C156" d="M1168 233.999v6h-6v-6z"/><path fill="#FFD058" d="M1108 233.999v6h-6v-6zM1132 233.999v6h-6v-6z"/><path fill="#F8C156" d="M1156 233.999v6h-6v-6z"/><path fill="#000" d="M1180 233.999v6h-6v-6z"/><path fill="#fff" d="M1114 257.998v6h-6v-6z"/><path fill="#F8C156" d="M1138 257.998v6h-6v-6z"/><path fill="#000" d="M1162 257.998v6h-6v-6z"/><path fill="#FFD058" d="M1126 257.998v6h-6v-6z"/><path fill="#F29914" d="M1150 257.998v6h-6v-6z"/><path fill="#fff" d="M1120 257.998v6h-6v-6z"/><path fill="#F8C156" d="M1144 257.998v6h-6v-6z"/><path fill="#000" d="M1108 257.998v6h-6v-6z"/><path fill="#FFD058" d="M1132 257.998v6h-6v-6z"/><path fill="#F29914" d="M1156 257.998v6h-6v-6z"/><path fill="#FFD058" d="M1114 245.999v6h-6v-6z"/><path fill="#F8C156" d="M1138 245.999v6h-6v-6zM1162 245.999v6h-6v-6z"/><path fill="#fff" d="M1102 245.999v6h-6v-6z"/><path fill="#FFD058" d="M1126 245.999v6h-6v-6z"/><path fill="#F8C056" d="M1150 245.999v6h-6v-6z"/><path fill="#000" d="M1174 245.999v6h-6v-6zM1096 245.999v6h-6v-6z"/><path fill="#FFD058" d="M1120 245.999v6h-6v-6z"/><path fill="#F8C156" d="M1144 245.999v6h-6v-6z"/><path fill="#F29914" d="M1168 245.999v6h-6v-6z"/><path fill="#FFD058" d="M1108 245.999v6h-6v-6zM1132 245.999v6h-6v-6z"/><path fill="#F8C056" d="M1156 245.999v6h-6v-6z"/><path fill="#000" d="M1138 269.998v6h-6v-6zM1126 269.998v6h-6v-6zM1144 269.998v6h-6v-6zM1132 269.998v6h-6v-6z"/><svg xmlns="http://www.w3.org/2000/svg" x="72" y="380"><svg width="120" height="120"><clipPath id="prefix__clipCircle"><circle cx="48" cy="48" r="48"/></clipPath><circle cx="48" cy="48" r="48" fill="#C8145C"/><g clip-path="url(#prefix__clipCircle)"><path fill="#FA6000" d="M29.633 48.617l-86.61-83.057 83.056-86.611 86.611 83.057z"/><path fill="#F5AF00" d="M63.4 142.048l-119.678 8.788-8.788-119.677L54.61 22.37z"/><path fill="#03585E" d="M21.906-1.682l9.833 119.597-119.596 9.832L-97.69 8.151z"/></g></svg></svg><defs><linearGradient id="prefix__p0" x1="622.044" y1="-2.347" x2="622.044" y2="678.332" gradientUnits="userSpaceOnUse"><stop stop-color="#452F16"/><stop offset="1" stop-color="#1B2023"/></linearGradient><linearGradient id="prefix__p1" x1="622.044" y1="-2.347" x2="622.044" y2="668.943" gradientUnits="userSpaceOnUse"><stop stop-color="#FF8A00"/><stop offset="1" stop-color="#52391B"/></linearGradient><linearGradient id="prefix__p2" x1="622.171" y1="-1.73" x2="622.171" y2="347.827" gradientUnits="userSpaceOnUse"><stop stop-color="#F78602" stop-opacity=".35"/><stop offset="1" stop-color="#F78602" stop-opacity="0"/></linearGradient><linearGradient id="prefix__p75" x1="919" y1="180" x2="919" y2="276" gradientUnits="userSpaceOnUse"><stop stop-color="#FFFFDA"/><stop offset=".503" stop-color="#FFE7B6"/><stop offset="1" stop-color="#A87945"/></linearGradient><pattern id="prefix__pattern0" patternContentUnits="objectBoundingBox" width="1" height="1"><use xlink:href="#prefix__image0_539_2800" transform="matrix(.00255 0 0 .00255 -.639 -1.77)"/></pattern></defs><style>@font-face{font-family:&apos;Black Ops One&apos;;font-style:normal;font-weight:400;src:url(data:application/font;base64,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) format(&apos;woff2&apos;);unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}@font-face{font-family:&apos;VT323&apos;;font-style:normal;font-weight:400;src:url(data:application/font;base64,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) format(&apos;woff2&apos;)}</style></svg>';

    function renderSvg(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age,
        address addr,
        uint256 reward
    ) public pure returns (string memory) {
        string memory Part1 = _renderSvgPart1(seed, lifeScore, round, age);
        string memory Part2 = _renderSvgPart2(addr, reward / 10**18);
        return string(abi.encodePacked(Part1, Part2));
    }

    function renderTrait(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age,
        address creator,
        uint256 reward,
        uint256 cost
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _renderTraitPart1(seed, lifeScore, round, age),
                    _renderTraitPart2(creator, reward / 10**18, cost / 10**18)
                )
            );
    }

    function _renderTraitPart1(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '[{"trait_type": "Seed", "value": "',
                    Strings.toHexString(uint256(seed), 32),
                    '"},{"trait_type": "Life Score", "value": ',
                    Strings.toString(lifeScore),
                    '},{"trait_type": "Round", "value": ',
                    Strings.toString(round),
                    '},{"trait_type": "Age", "value": ',
                    Strings.toString(age)
                )
            );
    }

    function _renderTraitPart2(
        address creator,
        uint256 reward,
        uint256 cost
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '},{"trait_type": "Creator", "value": "',
                    Strings.toHexString(uint160(creator), 20),
                    '"},{"trait_type": "Reward", "value": ',
                    Strings.toString(reward),
                    '},{"trait_type": "Cost", "value": ',
                    Strings.toString(cost),
                    "}]"
                )
            );
    }

    function _renderSvgPart1(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    P1,
                    _transformBytes32Seed(seed),
                    P2,
                    _transformUint256(lifeScore),
                    P3,
                    Strings.toString(round),
                    P4,
                    Strings.toString(age)
                )
            );
    }

    function _renderSvgPart2(address addr, uint256 reward)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    P5,
                    _shortenAddr(addr),
                    P6,
                    _transformUint256(reward),
                    P7
                )
            );
    }

    function _transformUint256(uint256 value)
        public
        pure
        returns (string memory str)
    {
        if (value < 10**7) {
            return _recursiveAddComma(value);
        } else if (value < 10**11) {
            return
                string(
                    abi.encodePacked(_recursiveAddComma(value / 10**6), "M")
                );
        } else if (value < 10**14) {
            return
                string(
                    abi.encodePacked(_recursiveAddComma(value / 10**9), "B")
                );
        } else {
            revert ValueOutOfRange();
        }
    }

    function _recursiveAddComma(uint256 value)
        internal
        pure
        returns (string memory str)
    {
        if (value / 1000 == 0) {
            str = string(abi.encodePacked(Strings.toString(value), str));
        } else {
            str = string(
                abi.encodePacked(
                    _recursiveAddComma(value / 1000),
                    ",",
                    Strings.toString(value % 1000),
                    str
                )
            );
        }
    }

    function _transformBytes32Seed(bytes32 b)
        public
        pure
        returns (string memory)
    {
        string memory str = Strings.toHexString(uint256(b), 32);

        return
            string(
                abi.encodePacked(
                    _substring(str, 0, 14),
                    unicode"…",
                    _substring(str, 45, 66)
                )
            );
    }
}