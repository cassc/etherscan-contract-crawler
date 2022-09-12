// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// artist: 0xhaiku

interface IFont {
    function font() external view returns (string memory);
}

interface IComposer {
    function getHaiku(uint256) external view returns (string[][] memory);
}

contract HumanReadable is ERC721, ERC2981, ReentrancyGuard, Ownable {
    uint256 public constant MAX_SUPPLY = 200;
    uint256 public constant OWNER_ALLOTMENT = 100;
    uint256 public constant SUPPLY = MAX_SUPPLY - OWNER_ALLOTMENT;
    uint256 private _tokenSupply;
    uint256 private _tokenPublicSupply;
    uint256 private _tokenOwnerSupply;
    uint256 public price = 0.08 ether;
    bool public isActive;
    string public description;
    string private _baseExternalURI;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;

    IFont private font;
    IComposer private composer;

    constructor(
        address _fontAddress,
        address _composerAddress,
        string memory _description
    ) ERC721("human-readable", "HR") {
        font = IFont(_fontAddress);
        composer = IComposer(_composerAddress);
        description = _description;
        _setDefaultRoyalty(owner(), 1000);
    }

    function _mint(bytes32 _hash, address _to) private {
        require(_tokenSupply < MAX_SUPPLY, "All tokens minted");
        require(hashToTokenId[_hash] == 0, "Already minted");
        _tokenSupply++;
        tokenIdToHash[_tokenSupply] = _hash;
        hashToTokenId[_hash] = _tokenSupply;
        _safeMint(_to, _tokenSupply);
    }

    function mint(bytes32 _hash, bool iamhuman) external payable nonReentrant {
        require(iamhuman, "only human");
        require(isActive, "INACTIVE");
        require(_tokenPublicSupply < SUPPLY, "All tokens minted");
        require(msg.value >= price, "Not enough ETH sent; check price!");
        _tokenPublicSupply++;
        _mint(_hash, _msgSender());
    }

    function ownerMint(bytes32 _hash, address _to) external onlyOwner {
        require(_tokenOwnerSupply < OWNER_ALLOTMENT, "All tokens minted");
        _tokenOwnerSupply++;
        _mint(_hash, _to);
    }

    function setIsActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setDescription(string memory desc) external onlyOwner {
        description = desc;
    }

    function setBaseExternalURI(string memory URI) external onlyOwner {
        _baseExternalURI = URI;
    }

    function setFont(address _fontAddress) external onlyOwner {
        font = IFont(_fontAddress);
    }

    function captcha(uint256 _now)
        external
        view
        returns (
            bytes32 _hash,
            string[][] memory _words,
            string memory _svg
        )
    {
        _hash = keccak256(
            abi.encodePacked(block.number, blockhash(block.number - 1), _now, msg.sender)
        );
        _words = composer.getHaiku(uint256(_hash));
        _svg = tokenSVG(_hash, _words);
    }

    function t(
        string memory _x,
        string memory _y,
        string memory _c,
        string memory _form,
        string memory _t
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<text x='",
                    _x,
                    "' y='",
                    _y,
                    "' class='",
                    _c,
                    "' ",
                    _form,
                    ">",
                    _t,
                    "</text>"
                )
            );
    }

    function feTurbulence(string memory _seed) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<feTurbulence type='fractalNoise' baseFrequency='0.01 0.008' numOctaves='3' result='noise' seed='",
                    _seed,
                    "'/>"
                )
            );
    }

    function feDisplacementMap(string memory _scale) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<feDisplacementMap in2='noise' in='SourceGraphic' scale='",
                    _scale,
                    "' xChannelSelector='R' yChannelSelector='G'/>"
                )
            );
    }

    function svgStyle(bytes32 _hash) private view returns (string memory) {
        uint256 crand = uint256(keccak256(abi.encodePacked("color", _hash)));
        uint256 key = crand % 361;
        string memory color = string(
            abi.encodePacked(
                "hsl(",
                Strings.toString(key),
                ",100%,",
                Strings.toString(40 + (crand % 9)),
                "%)"
            )
        );
        string memory bg = string(abi.encodePacked("hsl(", Strings.toString(key), ",100%,95%)"));
        uint256 prand = uint256(keccak256(abi.encodePacked("pallete", _hash))) % 8;
        bool gradBg = uint256(keccak256(abi.encodePacked("gbg", _hash))) % 2 == 0;
        if (prand % 33 == 0) {
            color = "#ffffff";
            bg = "#000000";
        } else if (prand <= 2) {
            color = "#000000";
            bg = "#ffffff";
        } else if (prand <= 4) {
            bg = "#ffffff";
        } else if (prand == 5) {
            bg = string(
                abi.encodePacked(
                    "hsl(",
                    Strings.toString(uint256(keccak256(abi.encodePacked("cbg", _hash))) % 361),
                    ",",
                    Strings.toString(
                        30 + (uint256(keccak256(abi.encodePacked("cbgb", _hash))) % 20)
                    ),
                    "%,50%)"
                )
            );
        } else if (prand == 6) {
            bg = string(
                abi.encodePacked(
                    "hsl(",
                    Strings.toString((key + 180) % 360),
                    ",100%,",
                    Strings.toString(40 + (crand % 9)),
                    "%)"
                )
            );
        }
        return
            string(
                abi.encodePacked(
                    "<style>",
                    "@font-face {font-family:'HAIKU';font-display:fallback;src:url(",
                    font.font(),
                    ") format('woff2');}",
                    "*{font-family:'HAIKU',monospace;will-change:filter}text{font-size:26px;dominant-baseline:hanging;}.w{x:0;y:0;width:100%;height:100%}text,line{fill:",
                    color,
                    ";stroke:",
                    color,
                    "}.bg{fill:",
                    bg,
                    "}.fn{fill:none}",
                    gradBg ? "" : ".g{fill:none}",
                    "</style>"
                )
            );
    }

    function dash(
        uint256 _top,
        uint256 _x_d1,
        uint256 _length
    ) private pure returns (string memory) {
        string memory lines;
        {
            uint256 rand = uint256(keccak256(abi.encodePacked(_top, _x_d1, _length)));
            string memory _ts = Strings.toString(_top + 15);
            uint256 rotate = rand % 31;
            lines = string(
                abi.encodePacked(
                    lines,
                    "<line filter='url(#f3)' x1='",
                    decimalString(_x_d1, 1),
                    "' y1='",
                    _ts,
                    "' x2='",
                    decimalString(_x_d1 + _length, 1),
                    "' y2='",
                    _ts,
                    "' stroke-width='2' transform='rotate(",
                    zeroCenteredString(rotate, 15),
                    " ",
                    decimalString(_x_d1 + _length / 2, 1),
                    " ",
                    _ts,
                    ")' />"
                )
            );
        }
        return lines;
    }

    function word(
        string memory _word,
        uint256 _top,
        uint256 _x_d1,
        uint256 _chaosLV
    ) private pure returns (string memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked(_word, _top, _x_d1)));

        uint256 y = _chaosLV < 2 ? 0 : rand % 21;
        uint256 length = bytes(_word).length * 130;
        string memory _topStr = Strings.toString(_top);

        string memory rect;
        {
            rect = string(
                abi.encodePacked(
                    "<g filter='url(#f0)'><rect filter='url(#f2)' height='26' width='",
                    decimalString(length, 1),
                    "' x='",
                    decimalString(_x_d1, 1),
                    "' y='",
                    _topStr,
                    "' style='opacity:0.5'/></g>"
                )
            );
        }

        string memory text;
        {
            text = t(
                decimalString(_x_d1, 1),
                _topStr,
                uint256(keccak256(abi.encodePacked("fn", rand))) % 5 == 0 ? "fn" : "",
                string(
                    abi.encodePacked(
                        _chaosLV < 3
                            ? ""
                            : uint256(keccak256(abi.encodePacked("tf", rand))) % 4 == 0
                            ? "filter='url(#f1)'"
                            : "filter='url(#f0)'",
                        " stroke-width='",
                        Strings.toString(
                            1 + (uint256(keccak256(abi.encodePacked("ssw", rand))) % 2)
                        ),
                        "'"
                    )
                ),
                _word
            );
        }

        return
            string(
                abi.encodePacked(
                    "<g transform='translate(0 ",
                    zeroCenteredString(y, 10),
                    ")'>",
                    text,
                    1 < _chaosLV && uint256(keccak256(abi.encodePacked("db", rand))) % 6 == 0
                        ? string(abi.encodePacked("<g transform='translate(0 3.5)'>", text, "</g>"))
                        : "",
                    2 < _chaosLV && uint256(keccak256(abi.encodePacked("td", rand))) % 4 == 0
                        ? dash(_top, _x_d1, length)
                        : "",
                    2 < _chaosLV && uint256(keccak256(abi.encodePacked("r", rand))) % 7 == 0
                        ? rect
                        : "",
                    "</g>"
                )
            );
    }

    // e.g. (10, 5) => "5", (2, 5) => "-3"
    function zeroCenteredString(uint256 _value, uint256 _max) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _value < _max ? "-" : "",
                    Strings.toString(_value < _max ? _max - _value : _value - _max)
                )
            );
    }

    // e.g. (123, 1) => "12.3"
    function decimalString(uint256 _value, uint8 _decimals) private pure returns (string memory) {
        uint256 divider = 10**_decimals;
        uint256 ap = _value % divider;
        string memory zeros;
        if (ap != 0) {
            for (uint256 i = 1; i < _decimals; i++) {
                if (ap / 10**i == 0) {
                    zeros = string(abi.encodePacked(zeros, "0"));
                }
            }
        }
        return
            string(
                abi.encodePacked(
                    Strings.toString(_value / divider),
                    ap != 0 ? "." : "",
                    zeros,
                    ap != 0 ? Strings.toString(ap) : ""
                )
            );
    }

    function line(
        string[] memory words,
        uint256 _top,
        uint256[] memory textX,
        uint256 total,
        uint256 chaosLV
    ) private pure returns (string memory) {
        string memory res;
        uint256 groupX = (7000 - total) / 2;

        for (uint256 i = 0; i < words.length; i++) {
            res = string(abi.encodePacked(res, word(words[i], _top, groupX + textX[i], chaosLV)));
        }

        return res;
    }

    function tokenSVG(bytes32 _hash, string[][] memory words) private view returns (string memory) {
        uint256[][] memory allTextX = new uint256[][](words.length);
        uint256[] memory allTotal = new uint256[](words.length);
        uint256 max;

        for (uint256 i = 0; i < words.length; i++) {
            uint256[] memory textX = new uint256[](words[i].length);
            uint256 total;

            for (uint256 ii = 0; ii < words[i].length; ii++) {
                textX[ii] = total;
                total += bytes(words[i][ii]).length * 130 + (ii == words[i].length - 1 ? 0 : 130);
            }

            allTextX[i] = textX;
            allTotal[i] = total;
            max = total > max ? total : max;
        }
        uint256 scaleD2 = (600 * 10**3) / max;
        string memory filters;
        {
            uint256 seed = uint256(keccak256(abi.encodePacked(_hash))) % 10000;
            filters = string(
                abi.encodePacked(
                    "<filter id='f0' width='150%' height='150%' x='-25%' y='-25%' filterUnits='userSpaceOnUse'>",
                    feTurbulence(Strings.toString(seed)),
                    feDisplacementMap("40"),
                    "</filter>",
                    "<filter id='f1' width='150%' height='150%' x='-25%' y='-25%' filterUnits='userSpaceOnUse'>",
                    feTurbulence(Strings.toString(seed + 1)),
                    feDisplacementMap("10"),
                    "</filter>",
                    "<filter id='f2'>",
                    "<feTurbulence type='fractalNoise' baseFrequency='0.8' result='noise' />",
                    "<feBlend in='SourceGraphic' in2='noise' mode='multiply' />",
                    "</filter>",
                    "<filter id='f3' width='150%' height='150%' x='-25%' y='-25%' filterUnits='userSpaceOnUse'>",
                    feTurbulence(Strings.toString(seed + 2)),
                    feDisplacementMap("20"),
                    "</filter>",
                    "<linearGradient id='g' x1='0' x2='1' y1='0' y2='0'>",
                    "<stop offset='0%' stop-color='lightgray'/>",
                    "<stop offset='100%' stop-color='white'/>",
                    "</linearGradient>"
                )
            );
        }
        uint256 chaosLV = uint256(keccak256(abi.encodePacked("ch", _hash))) % 7;
        return
            string(
                abi.encodePacked(
                    "<svg viewBox='0 0 700 500' width='700' height='500' fill='none' preserveAspectRatio='xMidYMid meet' version='2' xmlns='http://www.w3.org/2000/svg'>",
                    svgStyle(_hash),
                    filters,
                    "<rect class='bg w'/>",
                    "<rect fill='url(#g)' class='g w' style='mix-blend-mode:multiply'/>",
                    "<g ",
                    chaosLV <= 3 ? "filter='url(#f0)' " : "",
                    "transform='scale(",
                    decimalString(scaleD2, 2),
                    " 2)' transform-origin='center'>",
                    line(words[0], 190, allTextX[0], allTotal[0], chaosLV),
                    line(words[1], 240, allTextX[1], allTotal[1], chaosLV),
                    line(words[2], 290, allTextX[2], allTotal[2], chaosLV),
                    "</g>",
                    "</svg>"
                )
            );
    }

    function getMetaData(uint256 _tokenId) private view returns (string memory) {
        bytes32 _hash = tokenIdToHash[_tokenId];
        string[][] memory words = composer.getHaiku(uint256(_hash));
        string memory haiku;
        for (uint256 i = 0; i < words.length; i++) {
            for (uint256 ii = 0; ii < words[i].length; ii++) {
                haiku = string(
                    abi.encodePacked(haiku, words[i][ii], ii < words[i].length - 1 ? " " : "")
                );
            }
            haiku = string(abi.encodePacked(haiku, i < words.length - 1 ? " " : ""));
        }
        return
            string(
                abi.encodePacked(
                    '{"name":"human-readable #',
                    Strings.toString(_tokenId),
                    '","description":"',
                    haiku,
                    "\\n\\n",
                    description,
                    '","image":"data:image/svg+xml;utf8,',
                    tokenSVG(_hash, words),
                    '","external_url":"',
                    _baseExternalURI,
                    Strings.toString(_tokenId),
                    '"}'
                )
            );
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked("data:application/json;utf8,", getMetaData(_tokenId)));
    }

    function totalSupply() external view returns (uint256) {
        return _tokenSupply;
    }

    function withdrawBalance() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    function setRoyaltyInfo(address receiver_, uint96 royaltyBps_) external onlyOwner {
        _setDefaultRoyalty(receiver_, royaltyBps_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}