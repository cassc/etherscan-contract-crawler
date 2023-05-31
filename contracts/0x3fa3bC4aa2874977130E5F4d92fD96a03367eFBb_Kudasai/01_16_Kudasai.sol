// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Util.sol";

contract Kudasai is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    uint256 private constant maxTokensPerTransaction = 1;
    uint256 private constant maxWalletPerToken = 2;
    uint256 private constant tokenMaxSupply = 500;

    mapping(uint256 => uint256) private _seeds;
    mapping(address => bool) private _isKudasaiList;
    bool private _publicEnable = false;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}
    
    modifier onlyKudasaiList() {
        require(_publicEnable || _isKudasaiList[msg.sender], "You are not on the Kudasai list");
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function getSeed(uint256 tokenId) public view returns (uint256) {
        require(
            tokenId < _tokenIdCounter.current(),
            "call to a non-exisitent token"
        );
        return _seeds[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isKudasaiList(address _account) public view returns (bool) {
        return _isKudasaiList[_account];
    }

    function addKudasaiList(address[] calldata _account) external onlyOwner() {
        for (uint256 i = 0; i < _account.length; i++) {
            _isKudasaiList[_account[i]] = true;
        }
    }

    function startPublic() external onlyOwner() {
        _publicEnable = true;
    }

    function _getColor(uint256 coloer) private pure returns (string memory) {
        string memory code;
        if (coloer == 0) { // purple
            code = string(abi.encodePacked("rgb(186,85,211)"));
        } else if (coloer == 1) { // red
            code = string(abi.encodePacked("rgb(220,20,60)"));
        } else if (coloer == 2) { // pink
            code = string(abi.encodePacked("rgb(250,128,114)"));
        } else if (coloer == 3) { // gold
            code = string(abi.encodePacked("rgb(255,215,0)"));
        } else if (coloer == 4) { // black
            code = string(abi.encodePacked("rgb(10,10,10)"));
        } else if (coloer == 5) { // green
            code = string(abi.encodePacked("rgb(50,205,5)"));
        } else if (coloer == 6) { // aqua
            code = string(abi.encodePacked("rgb(64,224,208)"));
        } else { // original
            code = string(abi.encodePacked("rgb(217,101,38)"));
        }
        return code;
    }

    function _getColorName(uint256 coloer) private pure returns (string memory) {
        string memory name;
        if (coloer == 0) { // purple
            name = string("purple");
        } else if (coloer == 1) { // red
            name = string("red");
        } else if (coloer == 2) { // pink
            name = string("pink");
        } else if (coloer == 3) { // gold
            name = string("gold");
        } else if (coloer == 4) { // black
            name = string("black");
        } else if (coloer == 5) { // green
            name = string("green");
        } else if (coloer == 6) { // aqua
            name = string("aqua");
        } else { // original
            name = string("original");
        }
        return name;
    }

    function _getText(bool agemasu) private pure returns (string memory) {
        string memory text = "KUDASAI";
        if (agemasu) {
            text = "AGEMASU";
        }
        return text;
    }

    function _getKudasai(
        uint256 color,
        bool agemasu
    ) private pure returns (string memory) {
        string memory colorCode = _getColor(color);
        return
            string(
                abi.encodePacked(
                    '<svg fill-rule="evenodd" height="620" width="620" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xml:space="preserve" xmlns:serif="http://www.serif.com/" style="fill-rule:evenodd;clip-rule:evenodd;stroke-miterlimit:10;"><g transform="matrix(1,0,0,1,-320,-65)"><g id="Layer-2" serif:id="Layer 2"><g transform="matrix(1,0,0,1,472.72,638.949)"><path d="M0,-416.989L-115.312,-11.671C-119.165,1.872 -109.063,15.36 -95.068,15.36L387.91,15.36C402.359,15.36 412.515,1.048 407.829,-12.71L269.768,-418.028C266.85,-426.595 258.847,-432.349 249.849,-432.349L20.244,-432.349C10.847,-432.349 2.587,-426.082 0,-416.989Z" style="fill:',
                    colorCode,
                    ';fill-rule:nonzero;"/></g><g transform="matrix(1,0,0,1,484.759,626.452)"><path d="M0,-391.107L113.392,5.766C116.957,18.241 128.359,26.842 141.333,26.842L375.871,26.842C390.32,26.842 400.476,12.623 395.79,-1.045L257.729,-403.721C254.811,-412.232 246.808,-417.949 237.81,-417.949L20.247,-417.949C6.257,-417.949 -3.843,-404.559 0,-391.107Z" style="fill:white;fill-rule:nonzero;stroke:',
                    colorCode,
                    ';stroke-width:4px;"/></g><g transform="matrix(1,0,0,1,626.528,308.553)"><path d="M0,88.958C-5.264,88.958 -9.531,84.69 -9.531,79.427L-9.531,9.531C-9.531,4.267 -5.264,0 0,0C5.264,0 9.531,4.267 9.531,9.531L9.531,79.427C9.531,84.69 5.264,88.958 0,88.958" style="fill:',
                    colorCode,
                    ';fill-rule:nonzero;"/></g><g transform="matrix(1,0,0,1,699.659,308.553)"><path d="M0,88.958C-5.265,88.958 -9.531,84.69 -9.531,79.427L-9.531,9.531C-9.531,4.267 -5.265,0 0,0C5.264,0 9.531,4.267 9.531,9.531L9.531,79.427C9.531,84.69 5.264,88.958 0,88.958" style="fill:',
                    colorCode,
                    ';fill-rule:nonzero;"/></g><g transform="matrix(1,0,0,1,554.286,494.729)"><path d="M0,0L281.432,0" style="fill:none;fill-rule:nonzero;stroke:',
                    colorCode,
                    ';stroke-width:4px;"/></g><g transform="matrix(0,-1,-1,0,719.761,588.077)"><path d="M-8.087,-8.088C-12.554,-8.088 -16.175,-4.467 -16.175,-0C-16.175,4.466 -12.554,8.087 -8.087,8.087C-3.621,8.087 0,4.466 0,-0C0,-4.467 -3.621,-8.088 -8.087,-8.088" style="fill:',
                    colorCode,
                    ';fill-rule:nonzero;"/></g><g transform="matrix(0,-1,-1,0,749.336,588.078)"><path d="M-8.087,-8.088C-12.554,-8.088 -16.175,-4.468 -16.175,-0.001C-16.175,4.466 -12.554,8.087 -8.087,8.087C-3.621,8.087 0,4.466 0,-0.001C0,-4.468 -3.621,-8.088 -8.087,-8.088" style="fill:',
                    colorCode,
                    ';fill-rule:nonzero;"/></g><g transform="matrix(0.436403,-0.899751,-0.899751,-0.436403,657.211,203.65)"><path d="M-41.093,75.547L107.619,75.547C115.783,75.547 118.259,64.463 110.872,60.989L-7.117,5.498L-41.093,75.547Z" style="fill:',
                    colorCode,
                    ';fill-rule:nonzero;"/></g><g transform="matrix(0.278631,-1.03987,1.03987,0.278631,-0.147034,739.635)"><text x="185.551px" y="359.393px" style="font-family:\'Menlo-Regular\', \'Menlo\', monospace;font-size:72px;fill:white;">',
                    _getText(agemasu),
                    '</text></g></g></g></svg>'
                )
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(
            tokenId < _tokenIdCounter.current(),
            "call to a non-exisitent token"
        );

        uint256 seed = _seeds[tokenId];
        uint256 color = seed % 8;
        bool agemasu = false;
        if ((seed /= 1000) % 100 == 0) {
            agemasu = true;
        }

        string memory output = _getKudasai(
            color, agemasu
        );

        string memory attributes = string(
            abi.encodePacked(
                '[{ "trait_type": "Color", "value": "',
                _getColorName(color),
                '"},{ "trait_type": "Type", "value": "',
                _getText(agemasu),
                '"}]'
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "OnChain Kudasai #',
                        Util.toStr(tokenId),
                        '", "description": "\\"Kudasai!\\" you said. After watching the rest of community getting their airdrops. Yes. You didn\'t listen. again.","attributes":',
                        attributes,
                        ', "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function kudasai(uint256 tokensNumber) public onlyKudasaiList {
        require(maxWalletPerToken > balanceOf(msg.sender), "No more Kudasai");
        require(tokensNumber > 0, "the number is too small");
        require(
            tokensNumber <= maxTokensPerTransaction,
            "number of tokens exceeds the range"
        );
        require(
            _tokenIdCounter.current().add(tokensNumber) <= tokenMaxSupply,
            "number of tokens exceeds the range"
        );

        for (uint256 i = 0; i < tokensNumber; i++) {
            uint256 seed = uint256(
                keccak256(
                    abi.encodePacked(
                        uint256(uint160(msg.sender)),
                        uint256(blockhash(block.number - 1)),
                        _tokenIdCounter.current(),
                        "kudasai"
                    )
                )
            );
            _seeds[_tokenIdCounter.current()] = seed;
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}