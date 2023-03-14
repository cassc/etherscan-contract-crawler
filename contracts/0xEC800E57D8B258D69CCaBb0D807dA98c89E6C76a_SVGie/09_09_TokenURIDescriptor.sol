// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import { Base64 } from './Base64.sol';

string constant SVGa = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="8 8 32 32" width="300" height="300">'
                            '<radialGradient id="'; // C0 C1
string constant SVGb = '"><stop stop-color="#'; // C0
string constant SVGc = '" offset="0"></stop><stop stop-color="#'; // C1
string constant SVGd = '" offset="1"></stop></radialGradient>'
                        '<rect x="8" y="8" width="100%" height="100%" opacity="1" fill="white"></rect>'
                        '<rect x="8" y="8" width="100%" height="100%" opacity=".5" fill="url(#'; // C0 C1
string constant SVGe = ')"></rect><linearGradient id="'; // C2 C3 C2
string constant SVGf = '"><stop stop-color="#'; // C2
string constant SVGg = '" offset="0"></stop><stop stop-color="#'; // C3
string constant SVGh = '" offset=".5"></stop><stop stop-color="#'; // C2
string constant SVGi = '" offset="1"></stop></linearGradient><linearGradient id="'; // C3 C2 C3
string constant SVGj = '"><stop stop-color="#'; // C3
string constant SVGk = '" offset="0"></stop><stop stop-color="#'; // C2
string constant SVGl = '" offset=".5"></stop><stop stop-color="#'; // C3
string constant SVGm = '" offset="1"></stop></linearGradient><path fill="url(#'; // C2 C3 C2 
string constant SVGn = ')" stroke-width="0.1" stroke="url(#'; // C3 C2 C3
string constant SVGo = ')" d="'; // PATH
string constant SVGp = '"></path></svg>';

library TokenURIDescriptor {

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toHexString(
        address _addr
    )
    internal
    pure
    returns (string memory) {
        bytes memory buffer = new bytes(42);
        uint160 addr = uint160(_addr);
        buffer[0] = "0";
        buffer[1] = "x";
        buffer[41] = _HEX_SYMBOLS[addr & 0xf];
        for (uint256 i = 40; i > 1; i--) {
            addr >>= 4;
            buffer[i] = _HEX_SYMBOLS[addr & 0xf];
        }
        return string(buffer);
    }


    function getColors(
        address _addr
    )
    internal
    pure
    returns(string[4] memory) {
        uint256 kecc = uint(keccak256(abi.encodePacked(_addr)));
        string[4] memory s;
        bytes memory fixedColor = new bytes(8);
        kecc >>= 128;
        uint32 color;
        uint32 opacity;
        color = uint32(kecc & 0xffffffff);
        opacity = (uint32(color & 0xff) * 256) / 1024 + 191;
        fixedColor[7] = _HEX_SYMBOLS[opacity & 0xf];
        opacity >>= 4;
        fixedColor[6] = _HEX_SYMBOLS[opacity & 0xf];
        color >>= 8;
        fixedColor[5] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[4] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[3] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[2] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[1] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[0] = _HEX_SYMBOLS[color & 0xf];
        s[3] = string(fixedColor);
        fixedColor = new bytes(8);
        kecc >>= 32;
        color = uint32(kecc & 0xffffffff);
        opacity = (uint32(color & 0xff) * 256) / 1024 + 191;
        fixedColor[7] = _HEX_SYMBOLS[opacity & 0xf];
        opacity >>= 4;
        fixedColor[6] = _HEX_SYMBOLS[opacity & 0xf];
        color >>= 8;
        fixedColor[5] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[4] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[3] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[2] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[1] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[0] = _HEX_SYMBOLS[color & 0xf];
        s[2] = string(fixedColor);
        fixedColor = new bytes(8);
        kecc >>= 32;
        color = uint32(kecc & 0xffffffff);
        opacity = (uint32(color & 0xff) * 256) / 1024 + 191;
        fixedColor[7] = _HEX_SYMBOLS[opacity & 0xf];
        opacity >>= 4;
        fixedColor[6] = _HEX_SYMBOLS[opacity & 0xf];
        color >>= 8;
        fixedColor[5] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[4] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[3] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[2] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[1] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[0] = _HEX_SYMBOLS[color & 0xf];
        s[1] = string(fixedColor);
        fixedColor = new bytes(8);
        kecc >>= 32;
        color = uint32(kecc & 0xffffffff);
        opacity = (uint32(color & 0xff) * 256) / 1024 + 191;
        fixedColor[7] = _HEX_SYMBOLS[opacity & 0xf];
        opacity >>= 4;
        fixedColor[6] = _HEX_SYMBOLS[opacity & 0xf];
        color >>= 8;
        fixedColor[5] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[4] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[3] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[2] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[1] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[0] = _HEX_SYMBOLS[color & 0xf];
        s[0] = string(fixedColor);
        return s;
    }
    
    function getPath(
        address _addr
    )
    internal
    pure
    returns (string memory) {
        // 40 integers from each hex character of the address (+16 to avoid negatives later)
        uint8[40] memory c;
        uint160 addr = uint160(_addr);
        for (uint8 i = 40; i > 0; i--) {
            c[i-1] = uint8((addr & 0xf) + 16);
            addr >>= 4;
        }
        // An array of strings with the possible values of each integer
        string[49] memory n = [
        '0 ','1 ','2 ','3 ','4 ','5 ','6 ','7 ','8 ','9 ',
        '10 ','11 ','12 ','13 ','14 ','15 ','16 ','17 ','18 ','19 ',
        '20 ','21 ','22 ','23 ','24 ','25 ','26 ','27 ','28 ','29 ',
        '30 ','31 ','32 ','33 ','34 ','35 ','36 ','37 ','38 ','39 ',
        '40 ','41 ','42 ','43 ','44 ','45 ','46 ','47 ','48 '
        ];
        // The Path is created (here lies all the magic)
        string[12] memory o;
        o[0] = string.concat( 'M', n[c[0]], n[c[1]], 'C', n[c[2]], n[c[3]], n[c[4]], n[c[5]] , n[c[6]], n[c[7]] );
        o[1] = string.concat( 'S', n[c[8]], n[c[9]], n[c[10]], n[c[11]], 'S', n[c[12]], n[c[13]] , n[c[14]], n[c[15]] );
        o[2] = string.concat( 'S', n[c[16]], n[c[17]], n[c[18]], n[c[19]], 'S', n[c[20]], n[c[21]], n[c[22]], n[c[23]] );
        o[3] = string.concat( 'S', n[c[24]], n[c[25]], n[c[26]], n[c[27]], 'S', n[c[28]], n[c[29]] , n[c[30]], n[c[31]] );
        o[4] = string.concat( 'S', n[c[32]], n[c[33]], n[c[34]], n[c[35]], 'S', n[c[36]], n[c[37]] , n[c[38]], n[c[39]] );
        o[5] = string.concat( 'Q', n[2*c[38]-c[36]], n[2*c[39]-c[37]], n[c[0]], n[c[1]] );

        o[6] = string.concat( 'M', n[48-c[0]], n[c[1]], 'C', n[48-c[2]], n[c[3]], n[48-c[4]], n[c[5]] , n[48-c[6]], n[c[7]] );
        o[7] = string.concat( 'S', n[48-c[8]], n[c[9]], n[48-c[10]], n[c[11]], 'S', n[48-c[12]], n[c[13]], n[48-c[14]], n[c[15]] );
        o[8] = string.concat( 'S', n[48-c[16]], n[c[17]], n[48-c[18]], n[c[19]], 'S', n[48-c[20]], n[c[21]], n[48-c[22]], n[c[23]] );
        o[9] = string.concat( 'S', n[48-c[24]], n[c[25]], n[48-c[26]], n[c[27]], 'S', n[48-c[28]], n[c[29]] , n[48-c[30]], n[c[31]] );
        o[10] = string.concat( 'S', n[48-c[32]], n[c[33]], n[48-c[34]], n[c[35]], 'S', n[48-c[36]], n[c[37]] , n[48-c[38]], n[c[39]] );
        o[11] = string.concat( 'Q', n[48-(2*c[38]-c[36])], n[2*c[39]-c[37]], n[48-c[0]], n[c[1]], 'z' );

        string memory out = string.concat (o[0], o[1], o[2], o[3], o[4], o[5], o[6]);
        out = string.concat (out, o[7], o[8], o[9], o[10], o[11]);

        return out;
    }

    function getSVG(
        address _addr
    )
    internal
    pure
    returns (string memory) {
        string[4] memory c = getColors(_addr);
        string memory c01 = string.concat(c[0], c[1]);
        string memory c232 = string.concat(c[2], c[3], c[2]);
        string memory c323 = string.concat(c[3], c[2], c[3]);
        string memory path = getPath(_addr);
        string memory o = string.concat(SVGa, c01, SVGb, c[0], SVGc, c[1], SVGd, c01, SVGe);
        o = string.concat(o, c232, SVGf, c[2], SVGg, c[3], SVGh, c[2], SVGi);
        o = string.concat(o, c323, SVGj, c[3], SVGk, c[2], SVGl, c[3], SVGm);
        o = string.concat(o, c232, SVGn, c323, SVGo, path, SVGp);

        return o;
    }

    // function getEncodedSVG(address _addr, string calldata name, string calldata symbol) public pure returns (string memory) {
    function tokenURI(
        address _addr,
        string memory _name,
        string memory _symbol
    )
    internal
    pure
    returns (string memory) {

        string[9] memory json;
        
        json[0] = '{"name":"';
        json[1] = _name;
        json[2] = ' #';
        json[3] = toHexString(_addr);
        json[4] = '","symbol":"';
        json[5] = _symbol;
        json[6] = '","description":"Wallet SVG Representation","image": "data:image/svg+xml;base64,';
        json[7] = Base64.encode(bytes(getSVG(_addr)));
        json[8] = '"}';

        string memory output = string.concat(json[0], json[1], json[2], json[3], json[4], json[5], json[6], json[7], json[8]);

        return string.concat("data:application/json;base64,", Base64.encode(bytes(output)));

    }

}