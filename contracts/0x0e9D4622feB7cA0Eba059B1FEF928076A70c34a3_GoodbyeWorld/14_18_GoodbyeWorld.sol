// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

interface IFont {
    function font() external view returns (string memory);
}

contract GoodbyeWorld is
    ERC721,
    ERC2981,
    ReentrancyGuard,
    RevokableDefaultOperatorFilterer,
    Ownable
{
    uint256 private _tokenSupply;
    bool public isActive;
    string private _description;
    string private _baseExternalURI;
    address[] private _allowAddresses;

    IFont private font;

    constructor(address _fontAddress) ERC721("GoodbyeWorld", "GOODBYEWORLD") {
        font = IFont(_fontAddress);
        _setDefaultRoyalty(owner(), 1000);
    }

    function mint() external nonReentrant {
        require(isActive, "INACTIVE");
        require(available(), "NOT AVAILABLE");
        _safeMint(_msgSender(), _tokenSupply);
        _tokenSupply++;
    }

    function available() public view returns (bool) {
        if (_allowAddresses.length == 0) return true;
        for (uint256 i; i < _allowAddresses.length; i++) {
            if (IERC721(_allowAddresses[i]).balanceOf(_msgSender()) > 0) {
                return true;
            }
        }
        return false;
    }

    /* token utility */

    function setIsActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function setDescription(string memory desc) public onlyOwner {
        _description = desc;
    }

    function setBaseExternalURI(string memory URI) external onlyOwner {
        _baseExternalURI = URI;
    }

    function setAllowAddresses(address[] memory _addresses) external onlyOwner {
        _allowAddresses = _addresses;
    }

    function random(uint256 _seed) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_seed)));
    }

    function rowBody(
        uint256 _seed,
        uint256 _index,
        string memory _width
    ) private pure returns (string memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked("GBW", _index, _seed)));
        string memory body;
        {
            for (uint256 i = 0; i < 10; i++) {
                rand = random(rand);
                string memory amount = Strings.toString(1 + (rand % 10));
                rand = random(rand);
                string memory direction = rand % 2 == 0 ? "right" : "left";
                rand = random(rand);
                string memory behavior = rand % 5 == 0 ? "alternate" : "scroll";
                rand = random(rand);
                string memory color = string(
                    abi.encodePacked("hsl(", Strings.toString(rand % 361), ",100%,40%)")
                );
                rand = uint256(keccak256(abi.encodePacked(rand)));
                string memory bg = string(
                    abi.encodePacked("hsl(", Strings.toString(rand % 361), ",100%,50%)")
                );
                body = string(
                    abi.encodePacked(
                        body,
                        "<div class='w'><marquee style='color:",
                        color,
                        ";background-color:",
                        bg,
                        "' scrollamount='",
                        amount,
                        "' direction='",
                        direction,
                        "' behavior='",
                        behavior,
                        "'>GOODBYE WORLD</marquee></div>"
                    )
                );
            }
        }
        return
            string(
                abi.encodePacked(
                    "<div style='height:100%;width:",
                    _width,
                    "%;float:left'>",
                    body,
                    "</div>"
                )
            );
    }

    function tokenHTML(uint256 _tokenId) private view returns (string memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked("GBW", _tokenId)));
        uint256 rows = 1 + (uint256(keccak256(abi.encodePacked("GBWR", _tokenId))) % 4);
        string[4] memory widths = ["100", "50", "33.3", "25"];
        string memory body;
        {
            for (uint256 i = 0; i < rows; i++) {
                body = string(abi.encodePacked(body, rowBody(rand, i, widths[rows - 1])));
            }
        }
        return
            string(
                abi.encodePacked(
                    "<body xmlns='http://www.w3.org/1999/xhtml'><style>",
                    "html,body{width:100%;height:100%;line-height:1;overflow:hidden}",
                    "@font-face {font-family:'GBW';font-display:block;src:url(",
                    font.font(),
                    ") format('woff2');}",
                    "*{padding:0;margin:0;font-size:10vh;font-weight:900;font-family:'GBW',monospace;box-sizing:border-box}.w{height:10%;width:100%;}</style>",
                    body,
                    "</body>"
                )
            );
    }

    function getMetaData(uint256 _tokenId) private view returns (string memory) {
        string memory html = tokenHTML(_tokenId);
        return
            string(
                abi.encodePacked(
                    '{"name":"Goodbye World #',
                    Strings.toString(_tokenId),
                    '","description":"',
                    _description,
                    '","image":"data:image/svg+xml;utf8,',
                    "<svg viewBox='0 0 500 500' xmlns='http://www.w3.org/2000/svg' fill='none'><foreignObject width='500' height='500'>",
                    html,
                    "</foreignObject><style>*{font-size:50px}</style></svg>",
                    '","animation_url":"data:text/html;base64,',
                    Base64.encode(
                        bytes(string(abi.encodePacked("<!DOCTYPE html><html>", html, "</html>")))
                    ),
                    '","external_url":"',
                    _baseExternalURI,
                    Strings.toString(_tokenId),
                    '"}'
                )
            );
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked("data:application/json;utf8,", getMetaData(_tokenId)));
    }

    function totalSupply() external view returns (uint256) {
        return _tokenSupply;
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

    /* OperatorFilter */

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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