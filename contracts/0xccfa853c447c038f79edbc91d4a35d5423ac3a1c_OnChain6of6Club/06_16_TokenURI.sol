// SPDX-License-Identifier: MIT
// TokenURI Contracts v0.0.1
// Creator: RockArt 🪨 AI

pragma solidity ^0.8.20;

import { Strings } from "openzeppelin/utils/Strings.sol";
import { Base64 } from "openzeppelin/utils/Base64.sol";

interface ITokenURI {
    function setToken(
        address from,
        uint256 tokenId
    ) external;

    function tokenURI(
        uint256 tokenId
    ) external view returns (string memory);
}

contract TokenURI is ITokenURI {
    using Strings for uint256;

    address public nft;
    address public owner;

    string private _description = string(abi.encodePacked(
        unicode'[ BUY = +1 of 6 ] ⇢ [ lost 🔴 | 🟢 win ] ⇢ [ SELL = +1 of 6 ]',
        unicode' ❗️ Attention ❗️ to add cartridge you need',
        unicode' ⚪️ 👉 Sell for native token (ETH)',
        unicode' ⚪️ 👉 Buy one token in one transaction (1 token in cart)',
        unicode' ⚪️ 👉 Use only marketplace Opensea'
    ));

    address[] private _markets;

    uint256 public memberId;
    mapping(uint256 => uint256) public memberToken;
    mapping(uint256 => uint256) public tokenMember;
    mapping(uint256 => uint256) public drum;
    mapping(uint256 => uint256) public color;

    string[16] private _mascot = [
        unicode"🐶", unicode"🐱", unicode"🐭", unicode"🐹",
        unicode"🐰", unicode"🦊", unicode"🐻", unicode"🐼",
        unicode"🐻‍❄️", unicode"🐨", unicode"🐯", unicode"🦁",
        unicode"🐮", unicode"🐷", unicode"🐸", unicode"🐵"
    ];

    string[6] private _cx = ["71.6", "71.6", "50", "28.5", "28.5", "50"];
    string[6] private _cy = ["37.5", "62.6", "75", "62.6", "37.5", "25"];
    string[3] private _r = ["9", "6", "5"];
    string[3] private _red = ["cc0000", "bb0000", "dd0000"];

    modifier onlyNft {
        require(msg.sender == nft, "Only NFT contract");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only Owner user");
        _;
    }

    constructor(address nft_) {
        nft = nft_;
        owner = msg.sender;
    }

    function setToken(
        address from,
        uint256 tokenId
    ) external onlyNft {
        if (from == address(0) || _isSale()) {
            if (color[tokenId] <= 0) {
                uint256 r = uint256(keccak256(abi.encodePacked(
                    block.number,
                    block.prevrandao,
                    tokenId
                )));
                color[tokenId] = r > type(uint128).max
                    ? r
                    : r + type(uint128).max;
            } else {
                (uint256 c, uint256 r) = _parse(tokenId);
                if (r == 0 || (c < 5 && c < r)) {
                    c += 1;
                    r = (uint256(keccak256(abi.encodePacked(
                        block.number,
                        block.prevrandao,
                        tokenId
                    )))) % 6 + 1;
                    drum[tokenId] = (c * 10) + r;
                    if (c == 5 && r == 6) {
                        memberId += 1;
                        memberToken[memberId] = tokenId;
                        tokenMember[tokenId] = memberId;
                    }
                }
            }
        }
    }

    function setDescription(string memory description_) public onlyOwner {
        _description = description_;
    }

    function addMarket(address[] memory markets_) public onlyOwner {
        for (uint256 i = 0; i < markets_.length; i++) {
            _markets.push(markets_[i]);
        }
    }

    function delMarket(address[] memory markets_) public onlyOwner {
        for (uint256 i = 0; i < _markets.length; i++) {
            for (uint256 j = 0; j < markets_.length; j++) {
                address market = markets_[j];
                if (market == _markets[i]) {
                    _markets[i] = _markets[_markets.length-1];
                    _markets.pop();
                    break;
                }
            }
        }
    }

    function _isSale() private view returns (bool sale) {
        for (uint256 i = 0; i < _markets.length; i++) {
            if (address(_markets[i]).balance > 0) {
                sale = true;
                break;
            }
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual returns (string memory) {
        return string(abi.encodePacked(
            'data:application/json;utf8,',
            abi.encodePacked(
                '{',
                    '"name":"', _name(tokenId),
                    '","description":"', _description,
                    '","external_url":"https://6of6club.eth.limo',
                    '","background_color":"', backgroundColor(tokenId),
                    '","attributes":', _attributes(tokenId),
                    ',"image":"', _image(tokenId),
                '"}'
            )
        ));
    }

    function _parse(
        uint256 tokenId
    ) private view returns (uint256 c, uint256 r) {
        c = uint256(drum[tokenId]) / uint256(10);
        r = uint256(drum[tokenId]) % uint256(10);
    }

    function _name(
        uint256 tokenId
    ) private view returns (string memory) {
        (uint256 c, uint256 r) = _parse(tokenId);

        return string(abi.encodePacked(
            (r == 6 && c == 5 ? 6 : c).toString(),
            'of6 Club #',
            tokenId.toString()
        ));
    }

    function _image(
        uint256 tokenId
    ) private view returns (string memory) {
        (uint256 c, uint256 r) = _parse(tokenId);

        uint256 cartridgeRed = (color[tokenId] % 10**3) % 86 + 1;
        uint256 cartridgeGreen = ((color[tokenId] / 10**3) % 10**3) % 221 + 1;
        uint256 cartridgeBlue = ((color[tokenId] / 10**6) % 10**3) % 221 + 1;

        string[3] memory fill = [
            _rgbToHex(
                cartridgeRed + 17,
                cartridgeGreen + 17,
                cartridgeBlue + 17
            ),
            _rgbToHex(
                cartridgeRed,
                cartridgeGreen,
                cartridgeBlue
            ),
            _rgbToHex(
                cartridgeRed + 34,
                cartridgeGreen + 34,
                cartridgeBlue + 34
            )
        ];

        return string(abi.encodePacked(
            'data:image/svg+xml;base64,',
            Base64.encode(abi.encodePacked(
                '<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><defs>',
                _radialGradient(tokenId),
                _style(tokenId),
                '</defs>',
                (c > 0 ? _cartridges(c, fill) : bytes('')),
                (r > 0 ? _cartridge(r, c < r ? fill : _red) : bytes('')),
                '<path d="m88.408 38.831c-1.823-6.278-5.14-11.916-9.545-16.508-3.834 0.265-7.785-0.568-11.363-2.634-3.583-2.069-6.283-5.079-7.97-8.537-3.055-0.747-6.245-1.152-9.53-1.152s-6.475 0.405-9.53 1.152c-1.687 3.459-4.387 6.469-7.97 8.537-3.578 2.066-7.529 2.899-11.363 2.634-4.405 4.592-7.722 10.23-9.545 16.508 2.151 3.189 3.408 7.032 3.408 11.169s-1.257 7.98-3.408 11.169c1.823 6.278 5.14 11.916 9.545 16.508 3.834-0.265 7.785 0.568 11.363 2.634 3.583 2.069 6.283 5.079 7.97 8.538 3.055 0.746 6.245 1.151 9.53 1.151s6.475-0.405 9.53-1.152c1.687-3.459 4.387-6.469 7.97-8.538 3.578-2.066 7.529-2.899 11.363-2.634 4.405-4.592 7.722-10.23 9.545-16.508-2.151-3.188-3.408-7.031-3.408-11.168s1.257-7.98 3.408-11.169zm-25.417-6.331c2.761-4.783 8.877-6.421 13.659-3.66 4.783 2.761 6.421 8.877 3.66 13.659-2.761 4.783-8.877 6.421-13.659 3.66-4.783-2.761-6.421-8.877-3.66-13.659zm-25.984 35c-2.761 4.783-8.877 6.421-13.659 3.66-4.783-2.761-6.421-8.877-3.66-13.659 2.761-4.783 8.877-6.421 13.659-3.66 4.783 2.761 6.422 8.876 3.66 13.659zm-8.659-20.001c-5.522 0-9.999-4.477-9.999-9.999s4.477-9.999 9.999-9.999 9.999 4.477 9.999 9.999-4.477 9.999-9.999 9.999zm26.651 36.161c-4.783 2.762-10.898 1.123-13.659-3.66s-1.123-10.898 3.66-13.659 10.898-1.123 13.659 3.66 1.122 10.898-3.66 13.659zm-9.999-33.66c0-2.761 2.239-5 5-5s5 2.239 5 5-2.239 5-5 5-5-2.239-5-5zm9.999-16.341c-4.783 2.761-10.898 1.123-13.659-3.66-2.762-4.783-1.123-10.898 3.66-13.659s10.898-1.123 13.659 3.66c2.761 4.782 1.122 10.897-3.66 13.659zm16.652 38.841c-5.522 0-9.999-4.477-9.999-9.999s4.477-9.999 9.999-9.999 9.999 4.477 9.999 9.999-4.477 9.999-9.999 9.999z" fill="url(#a)"></path>',
                (r == 6 && c == 5 ? _mascotFor(tokenId) : bytes('')),
                '</svg>'
            ))
        ));
    }

    function _radialGradient(
        uint256 tokenId
    ) private view returns (bytes memory) {
        (string memory start, string memory stop) = gradientColor(tokenId);

        return abi.encodePacked(
            '<radialGradient id="a"><stop stop-color="#',
            start,
            '" offset="0"/><stop stop-color="#',
            stop,
            '" offset="1"/></radialGradient>'
        );
    }

    function _style(
        uint256 tokenId
    ) private view returns (bytes memory) {
        (uint256 c, uint256 r) = _parse(tokenId);

        return abi.encodePacked(
            '<style><![CDATA[svg{overflow:hidden;background:#',
            backgroundColor(tokenId),
            ';animation:5s ease-in-out 1s forwards r}@keyframes r{0%{transform:rotateZ(0)}100%{transform:rotateZ(',
            (1800 - 60 * r).toString(),
            'deg)}}circle:nth-of-type(-n+3){opacity:0;animation:1s ease-in-out forwards f}circle:nth-last-of-type(-n+3){opacity:0;', 
            (r <= c || c == 5 ? 'animation:1s ease-in-out 6s forwards f' : ''),
            '}text{opacity:0;', 
            (r == 6 && c == 5 ? 'animation:1s ease-in-out 6s forwards f' : ''), 
            '}@keyframes f{0%{opacity:0}100%{opacity:1}}]]></style>'
        );
    }

    function _mascotFor(
        uint256 tokenId
    ) private view returns (bytes memory) {
        (, uint256 r) = _parse(tokenId);

        return abi.encodePacked(
            '<text x="50%" y="50%" dominant-baseline="central" text-anchor="middle" style="font-size: 20px;" transform="rotate(',
            (60 * r).toString(),
            ', 50, 50)">',
            _mascot[uint256(color[tokenId] % 16)],
            '</text>'
        );
    }

    function _cartridges(
        uint256 max,
        string[3] memory fill
    ) private view returns (bytes memory) {
        bytes memory result;
        for (uint256 i = max; i >= 1; i--) {
            result = abi.encodePacked(
                result,
                _cartridge(i, fill)
            );
        }
        return result;
    }

    function _cartridge(
        uint256 position,
        string[3] memory fill
    ) private view returns (bytes memory) {
        return abi.encodePacked(
            _circle(_cx[position - 1], _cy[position - 1], _r[0], fill[0]),
            _circle(_cx[position - 1], _cy[position - 1], _r[1], fill[1]),
            _circle(_cx[position - 1], _cy[position - 1], _r[2], fill[2])
        );
    }

    function _circle(
        string memory cx,
        string memory cy,
        string memory r,
        string memory fill
    ) private pure returns (bytes memory) {
        return abi.encodePacked(
            '<circle cx="', cx,
            '" cy="', cy,
            '" r="', r,
            '" fill="#', fill,
            '"></circle>'
        );
    }

    function _attributes(
        uint256 tokenId
    ) private view returns (bytes memory) {
        return abi.encodePacked(
            '[{"trait_type": "CARTRIDGES", "value": "',
            _typeCartridges(tokenId), '"},',
            '{"trait_type": "MASCOT", "value": "',
            _typeMascot(tokenId), '"},',
            '{"trait_type": "MEMBER ID", "value": "', 
            _typeMemberId(tokenId), '"}]'
        );
    }

    function _typeCartridges(
        uint256 tokenId
    ) private view returns (bytes memory cs) {
        (uint256 c, uint256 r) = _parse(tokenId);

        bool q;
        for (uint256 i = 1; i <= 6; i++) {
            if (i <= c) {
                if (i == c && r <= c) {
                    cs = abi.encodePacked(cs, unicode"🔴");
                    q = true;
                } else {
                    cs = abi.encodePacked(cs, unicode"🟢");
                }
            } else {
                if (q) {
                    cs = abi.encodePacked(cs, unicode"⚪️");
                } else {
                    if (c == 5 && r == 6) {
                        cs = abi.encodePacked(cs, unicode"🟢");
                    } else {
                        cs = abi.encodePacked(cs, unicode"❔");
                        q = true;
                    }
                }
            }
        }
    }

    function _typeMascot(
        uint256 tokenId
    ) private view returns (string memory) {
        (uint256 c, uint256 r) = _parse(tokenId);

        return c > 0 && c >= r
            ? unicode"🔴"
            : r == 6 && c == 5
                ? _mascot[uint256(color[tokenId] % 16)]
                : unicode"❔";
    }

    function _typeMemberId(
        uint256 tokenId
    ) private view returns (string memory) {
        (uint256 c, uint256 r) = _parse(tokenId);

        return r == 6 && c == 5
            ? (tokenMember[tokenId]).toString() 
            : "Non-member";
    }

    function clubMember(
        uint64 id
    ) public view returns (string memory) {
        require(memberToken[id] > 0);
        return tokenURI(memberToken[id]);
    }

    function _rgbToHex(
        uint256 r,
        uint256 g,
        uint256 b
    ) private pure returns (string memory) {
        uint256 decimalValue = (r << 16) | (g << 8) | b;
        uint256 remainder;
        bytes memory hexResult = "";
        string[16] memory hexDictionary = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];

        while (decimalValue > 0) {
            remainder = decimalValue % 16;
            string memory hexValue = hexDictionary[remainder];
            hexResult = abi.encodePacked(hexValue, hexResult);
            decimalValue = decimalValue / 16;
        }
        
        uint len = hexResult.length;

        if (len == 5) {
            hexResult = abi.encodePacked("0", hexResult);
        } else if (len == 4) {
            hexResult = abi.encodePacked("00", hexResult);
        } else if (len == 3) {
            hexResult = abi.encodePacked("000", hexResult);
        } else if (len == 4) {
            hexResult = abi.encodePacked("0000", hexResult);
        }

        return string(hexResult);
    }

    function backgroundColor(
        uint256 tokenId
    ) public view returns (string memory) {
        return _rgbToHex(
            ((color[tokenId] / 10**9) % 10**3) % 100 + 1,
            ((color[tokenId] / 10**12) % 10**3) % 100 + 1,
            ((color[tokenId] / 10**15) % 10**3) % 100 + 1
        );
    }

    function gradientColor(
        uint256 tokenId
    ) public view returns (string memory, string memory) {
        uint256 cartridgeRed = (color[tokenId] % 10**3) % 86 + 1;
        uint256 cartridgeGreen = ((color[tokenId] / 10**3) % 10**3) % 221 + 1;
        uint256 cartridgeBlue = ((color[tokenId] / 10**6) % 10**3) % 221 + 1;

        return (
            _rgbToHex(
                cartridgeRed + cartridgeRed % 34,
                cartridgeGreen + cartridgeGreen % 34,
                cartridgeBlue + cartridgeBlue % 34
            ),
            _rgbToHex(
                ((color[tokenId] / 10**18) % 10**3) % 155 + 100,
                ((color[tokenId] / 10**21) % 10**3) % 155 + 100,
                ((color[tokenId] / 10**24) % 10**3) % 155 + 100
            )
        );
    }
}