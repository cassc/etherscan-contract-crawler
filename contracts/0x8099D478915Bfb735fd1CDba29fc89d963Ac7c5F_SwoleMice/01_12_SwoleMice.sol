// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./TinyERC721.sol";

//  _________             .__            _____  .__              
// /   _____/_  _  ______ |  |   ____   /     \ |__| ____  ____  
// \_____  \\ \/ \/ /  _ \|  | _/ __ \ /  \ /  \|  |/ ___\/ __ \ 
// /        \\     (  <_> )  |_\  ___//    Y    \  \  \__\  ___/ 
///_______  / \/\_/ \____/|____/\___  >____|__  /__|\___  >___  >
//        \/                        \/        \/        \/    \/ 
//
// Made by @nft_ved

contract SwoleMice is TinyERC721, Ownable {

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public maxPer = 6;
    bool public isPublicActive = false;

    mapping(address => uint256) private _minted;

    constructor() TinyERC721("SwoleMice", "SWOLEM", 3) {
        _safeMint(_msgSender(), 1);
    }

    // View
    function _calculateAux(
        address from,
        address to,
        uint256 tokenId,
        bytes12 current
    ) internal view virtual override returns (bytes12) {
        return
            from == address(0)
                ? bytes12(
                    keccak256(
                        abi.encodePacked(
                            tokenId,
                            to,
                            block.difficulty,
                            block.timestamp
                        )
                    )
                )
                : current;
    }

    function colorHash(uint256 tokenId) public view returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, _tokenData(tokenId).aux));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        return(
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(
                                abi.encodePacked(
                                    '{"name": "SwoleMouse #',
                                    Strings.toString(tokenId),
                                    '", "description": "SwoleMice are a 100% on-chain swole collection. Arm days only.", "image": "data:image/svg+xml;base64,',
                                    Base64.encode(bytes(hashToSVG(bytes32ToLiteralString(colorHash(tokenId))))),
                                    '"}'
                                )
                    ))
                )
            )
        );
    }

    // External
    function mint(uint256 quantity) external {
        require(isPublicActive, "Minting is not open");
        require(quantity <= maxPer, "Too many mints per tx");
        require(_minted[msg.sender] + quantity <= maxPer, "Too many mints per wallet");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough mints left"
        );
        _safeMint(msg.sender, quantity);
        _minted[msg.sender] += quantity;
    }

    // Owner
    function setMaxPer(uint256 _maxPer) external onlyOwner {
        maxPer = _maxPer;
    }

    function setIsPublicActive(bool _isPublicActive) external onlyOwner{
        isPublicActive = _isPublicActive;
    }

    // Internal 

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function bytes32ToLiteralString(bytes32 data)
        internal
        pure
        returns (string memory result)
    {
        bytes memory temp = new bytes(65);
        uint256 count;

        for (uint256 i = 0; i < 32; i++) {
            bytes1 currentByte = bytes1(data << (i * 8));

            uint8 c1 = uint8(bytes1((currentByte << 4) >> 4));

            uint8 c2 = uint8(bytes1((currentByte >> 4)));

            if (c2 >= 0 && c2 <= 9) temp[++count] = bytes1(c2 + 48);
            else temp[++count] = bytes1(c2 + 87);

            if (c1 >= 0 && c1 <= 9) temp[++count] = bytes1(c1 + 48);
            else temp[++count] = bytes1(c1 + 87);
        }

        result = string(temp);
    }

        function hashToSVG(string memory _hash)
        internal
        pure
        returns (string memory)
    {
        string memory svgString;

        string memory backgroundColor = string.concat(string.concat('.c11{fill:#', substring(_hash, 1, 7)),'}');
        string memory topColor = string.concat(string.concat('.c10{fill:#', substring(_hash, 7, 13)),'}');
        string memory leftEye = string.concat(string.concat('.c06{fill:#', substring(_hash, 13, 19)),'}');
        string memory rightEye = string.concat(string.concat('.c07{fill:#', substring(_hash, 19, 25)),'}');
        string memory eyes = string.concat(leftEye, rightEye);
        string memory backs = string.concat(topColor, backgroundColor);
        string memory styleString = string.concat(string.concat(string.concat(string.concat('<style>#swol-mouse-svg{shape-rendering: crispedges;} .c00{fill:#8B93AF}.c01{fill:#DAE0EA}.c02{fill:#B3B9D1}.c03{fill:#F5A097}.c04{fill:#403353}.c05{fill:#6D758D}',eyes),'.c08{fill:#000000}.c09{fill:#4B1E0B}'),backs),'</style>');

        string memory svgBody = '<svg id="swol-mouse-svg" version="1.1" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"> <rect class="c11" width="100%" height="100%" /> <rect class="c00" x="8" y="9" width="1" height="1"/> <rect class="c01" x="9" y="9" width="1" height="1"/> <rect class="c00" x="13" y="9" width="1" height="1"/> <rect class="c01" x="14" y="9" width="1" height="1"/> <rect class="c02" x="8" y="10" width="1" height="1"/> <rect class="c03" x="9" y="10" width="1" height="1"/> <rect class="c01" x="10" y="10" width="1" height="1"/> <rect class="c01" x="11" y="10" width="1" height="1"/> <rect class="c02" x="12" y="10" width="1" height="1"/> <rect class="c01" x="13" y="10" width="1" height="1"/> <rect class="c01" x="14" y="10" width="1" height="1"/> <rect class="c02" x="9" y="11" width="1" height="1"/> <rect class="c01" x="10" y="11" width="1" height="1"/> <rect class="c01" x="11" y="11" width="1" height="1"/> <rect class="c01" x="12" y="11" width="1" height="1"/> <rect class="c01" x="13" y="11" width="1" height="1"/> <rect class="c04" x="8" y="12" width="1" height="1" /> <rect class="c05" x="9" y="12" width="1" height="1" /> <rect class="c05" x="10" y="12" width="1" height="1" /> <rect class="c06" x="11" y="12" width="1" height="1" /> <rect class="c05" x="12" y="12" width="1" height="1" /> <rect class="c07" x="13" y="12" width="1" height="1" /> <rect class="c04" x="15" y="12" width="1" height="1" /> <rect class="c04" x="9" y="13" width="1" height="1" /> <rect class="c01" x="10" y="13" width="1" height="1"/> <rect class="c01" x="11" y="13" width="1" height="1"/> <rect class="c08" x="12" y="13" width="1" height="1" /> <rect class="c01" x="13" y="13" width="1" height="1"/> <rect class="c04" x="14" y="13" width="1" height="1" /> <rect class="c02" x="9" y="14" width="1" height="1"/> <rect class="c04" x="10" y="14" width="1" height="1" /> <rect class="c01" x="11" y="14" width="1" height="1"/> <rect class="c01" x="12" y="14" width="1" height="1"/> <rect class="c01" x="13" y="14" width="1" height="1"/> <rect class="c01" x="16" y="14" width="1" height="1"/> <rect class="c01" x="17" y="14" width="1" height="1"/> <rect x="9" y="15" width="1" height="1" /> <rect class="c02" x="10" y="15" width="1" height="1"/> <rect class="c01" x="11" y="15" width="1" height="1"/> <rect class="c01" x="12" y="15" width="1" height="1"/> <rect class="c02" x="13" y="15" width="1" height="1"/> <rect x="14" y="15" width="1" height="1" /> <rect class="c02" x="16" y="15" width="1" height="1"/> <rect class="c01" x="17" y="15" width="1" height="1"/> <rect x="8" y="16" width="1" height="1" /> <rect class="c02" x="10" y="16" width="1" height="1"/> <rect class="c01" x="11" y="16" width="1" height="1"/> <rect x="15" y="16" width="1" height="1" /> <rect class="c01" x="17" y="16" width="1" height="1"/> <rect class="c02" x="8" y="17" width="1" height="1"/> <rect class="c10" x="9" y="17" width="1" height="1" /> <rect class="c02" x="10" y="17" width="1" height="1"/> <rect class="c01" x="11" y="17" width="1" height="1"/> <rect class="c10" x="12" y="17" width="1" height="1" /> <rect class="c02" x="14" y="17" width="1" height="1"/> <rect class="c01" x="15" y="17" width="1" height="1"/> <rect class="c01" x="17" y="17" width="1" height="1"/> <rect class="c02" x="7" y="18" width="1" height="1"/> <rect class="c01" x="8" y="18" width="1" height="1"/> <rect class="c10" x="9" y="18" width="1" height="1" /> <rect class="c02" x="10" y="18" width="1" height="1"/> <rect class="c01" x="11" y="18" width="1" height="1"/> <rect class="c10" x="12" y="18" width="1" height="1" /> <rect class="c01" x="13" y="18" width="1" height="1"/> <rect class="c01" x="14" y="18" width="1" height="1"/> <rect class="c01" x="15" y="18" width="1" height="1"/> <rect class="c01" x="16" y="18" width="1" height="1"/> <rect class="c01" x="17" y="18" width="1" height="1"/> <rect class="c02" x="7" y="19" width="1" height="1"/> <rect class="c01" x="8" y="19" width="1" height="1"/> <rect class="c10" x="9" y="19" width="1" height="1" /> <rect class="c10" x="10" y="19" width="1" height="1" /> <rect class="c10" x="11" y="19" width="1" height="1" /> <rect class="c10" x="12" y="19" width="1" height="1" /> <rect class="c02" x="13" y="19" width="1" height="1"/> <rect class="c02" x="14" y="19" width="1" height="1"/> <rect class="c02" x="15" y="19" width="1" height="1"/> <rect class="c02" x="16" y="19" width="1" height="1"/> <rect class="c01" x="7" y="20" width="1" height="1"/> <rect class="c02" x="8" y="20" width="1" height="1"/> <rect class="c10" x="9" y="20" width="1" height="1" /> <rect class="c10" x="10" y="20" width="1" height="1" /> <rect class="c10" x="11" y="20" width="1" height="1" /> <rect class="c10" x="12" y="20" width="1" height="1" /> <rect class="c01" x="7" y="21" width="1" height="1"/> <rect class="c02" x="8" y="21" width="1" height="1"/> <rect class="c10" x="9" y="21" width="1" height="1" /> <rect class="c10" x="10" y="21" width="1" height="1" /> <rect class="c10" x="11" y="21" width="1" height="1" /> <rect class="c10" x="12" y="21" width="1" height="1" /> <rect class="c01" x="7" y="22" width="1" height="1"/> <rect class="c02" x="8" y="22" width="1" height="1"/> <rect class="c10" x="9" y="22" width="1" height="1" /> <rect class="c10" x="10" y="22" width="1" height="1" /> <rect class="c10" x="11" y="22" width="1" height="1" /> <rect class="c10" x="12" y="22" width="1" height="1" /> <rect class="c01" x="7" y="23" width="1" height="1"/> <rect class="c02" x="8" y="23" width="1" height="1"/> <rect class="c10" x="9" y="23" width="1" height="1" /> <rect class="c10" x="10" y="23" width="1" height="1" /> <rect class="c10" x="11" y="23" width="1" height="1" /> <rect class="c10" x="12" y="23" width="1" height="1" />';

        svgString = string(
            abi.encodePacked(
                svgBody,
                styleString,
                '</svg>'
            )
        );

        return svgString;
    }
}