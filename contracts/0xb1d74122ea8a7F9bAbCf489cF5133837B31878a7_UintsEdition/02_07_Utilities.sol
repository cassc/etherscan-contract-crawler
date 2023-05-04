/*

░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░                             ░░
░░   ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░   ░░
░░   ░░ ░░ ██ ██ ██ ░░ ░░ ░░   ░░
░░   ░░ ░░ ░░ ░░ ░░ ██ ░░ ░░   ░░
░░   ░░ ░░ ░░ ░░ ██ ░░ ██ ░░   ░░
░░   ░░ ░░ ░░ ██ ░░ ░░ ██ ░░   ░░
░░   ░░ ░░ ██ ░░ ░░ ░░ ██ ░░   ░░
░░   ░░ ██ ░░ ░░ ░░ ░░ ░░ ░░   ░░
░░   ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░   ░░
░░                             ░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library utils {
    function uint2str(
        uint _i
    ) internal pure returns (string memory _uintAsString) {
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
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function uint32ToString(
        uint32 color
    ) internal pure returns (string memory) {
        uint8 r = uint8(color >> 16);
        uint8 g = uint8(color >> 8);
        uint8 b = uint8(color);
        return
            string(
                abi.encodePacked(
                    "RGB(",
                    uint2str(r),
                    ",",
                    uint2str(g),
                    ",",
                    uint2str(b),
                    ")"
                )
            );
    }

    function convertColorsToStyles(
        uint32[64] memory colorArray
    ) internal pure returns (string memory styles) {
        for (uint i = 0; i < 64; i++) {
            styles = string(
                abi.encodePacked(
                    styles,
                    "#p",
                    uint2str(i + 1),
                    "{fill:",
                    uint32ToString(colorArray[i]),
                    "}"
                )
            );
        }
    }

    function renderSvg(
        uint32[64] memory colorArray
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg width="840" height="840" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="14" height="14" fill="#0C0C0C"/><g class="tiles"><rect id="p1" x="3" y="3"/><rect id="p2" x="4" y="3"/><rect id="p3" x="5" y="3"/><rect id="p4" x="6" y="3"/><rect id="p5" x="7" y="3"/><rect id="p6" x="8" y="3"/><rect id="p7" x="9" y="3"/><rect id="p8" x="10" y="3"/><rect id="p9" x="3" y="4"/><rect id="p10" x="4" y="4"/><rect id="p11" x="5" y="4"/><rect id="p12" x="6" y="4"/><rect id="p13" x="7" y="4"/><rect id="p14" x="8" y="4"/><rect id="p15" x="9" y="4"/><rect id="p16" x="10" y="4"/><rect id="p17" x="3" y="5"/><rect id="p18" x="4" y="5"/><rect id="p19" x="5" y="5"/><rect id="p20" x="6" y="5"/><rect id="p21" x="7" y="5"/><rect id="p22" x="8" y="5"/><rect id="p23" x="9" y="5"/><rect id="p24" x="10" y="5"/><rect id="p25" x="3" y="6"/><rect id="p26" x="4" y="6"/><rect id="p27" x="5" y="6"/><rect id="p28" x="6" y="6"/><rect id="p29" x="7" y="6"/><rect id="p30" x="8" y="6"/><rect id="p31" x="9" y="6"/><rect id="p32" x="10" y="6"/><rect id="p33" x="3" y="7"/><rect id="p34" x="4" y="7"/><rect id="p35" x="5" y="7"/><rect id="p36" x="6" y="7"/><rect id="p37" x="7" y="7"/><rect id="p38" x="8" y="7"/><rect id="p39" x="9" y="7"/><rect id="p40" x="10" y="7"/><rect id="p41" x="3" y="8"/><rect id="p42" x="4" y="8"/><rect id="p43" x="5" y="8"/><rect id="p44" x="6" y="8"/><rect id="p45" x="7" y="8"/><rect id="p46" x="8" y="8"/><rect id="p47" x="9" y="8"/><rect id="p48" x="10" y="8"/><rect id="p49" x="3" y="9"/><rect id="p50" x="4" y="9"/><rect id="p51" x="5" y="9"/><rect id="p52" x="6" y="9"/><rect id="p53" x="7" y="9"/><rect id="p54" x="8" y="9"/><rect id="p55" x="9" y="9"/><rect id="p56" x="10" y="9"/><rect id="p57" x="3" y="10"/><rect id="p58" x="4" y="10"/><rect id="p59" x="5" y="10"/><rect id="p60" x="6" y="10"/><rect id="p61" x="7" y="10"/><rect id="p62" x="8" y="10"/><rect id="p63" x="9" y="10"/><rect id="p64" x="10" y="10"/></g><g class="grid"><line x1="1.005" y1="-2.18557e-10" x2="1.005" y2="14"/><line x1="2.005" y1="-2.18557e-10" x2="2.005" y2="14"/><line x1="3.005" y1="-2.18557e-10" x2="3.005" y2="14"/><line x1="4.005" y1="-2.18557e-10" x2="4.005" y2="14"/><line x1="5.005" y1="-2.18557e-10" x2="5.005" y2="14"/><line x1="6.005" y1="-2.18557e-10" x2="6.005" y2="14"/><line x1="7.005" y1="-2.18557e-10" x2="7.005" y2="14"/><line x1="8.005" y1="-2.18557e-10" x2="8.005" y2="14"/><line x1="9.005" y1="-2.18557e-10" x2="9.005" y2="14"/><line x1="10.005" y1="-2.18557e-10" x2="10.005" y2="14"/><line x1="11.005" y1="-2.18557e-10" x2="11.005" y2="14"/><line x1="12.005" y1="-2.18557e-10" x2="12.005" y2="14"/><line x1="13.005" y1="-2.18557e-10" x2="13.005" y2="14"/><line x1="14" y1="1.005" y2="1.005"/><line x1="14" y1="2.005" y2="2.005"/><line x1="14" y1="3.005" y2="3.005"/><line x1="14" y1="4.005" y2="4.005"/><line x1="14" y1="5.005" y2="5.005"/><line x1="14" y1="6.005" y2="6.005"/><line x1="14" y1="7.005" y2="7.005"/><line x1="14" y1="8.005" y2="8.005"/><line x1="14" y1="9.005" y2="9.005"/><line x1="14" y1="10.005" y2="10.005"/><line x1="14" y1="11.005" y2="11.005"/><line x1="14" y1="12.005" y2="12.005"/><line x1="14" y1="13.005" y2="13.005"/></g><style>.tiles rect{width:1px;height:1px;}.grid{stroke:#222;stroke-width:.01;}',
                    convertColorsToStyles(colorArray),
                    "</style></svg>"
                )
            );
    }

    function secondsRemaining(uint end) internal view returns (uint) {
        if (block.timestamp <= end) {
            return end - block.timestamp;
        } else {
            return 0;
        }
    }

    function minutesRemaining(uint end) internal view returns (uint) {
        if (secondsRemaining(end) >= 60) {
            return (end - block.timestamp) / 60;
        } else {
            return 0;
        }
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}