// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";

contract AnObject is ERC1155Supply, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    string public name = "An Object";
    string public symbol = "OBJ";

    uint256 public constant AnObjectToken = 0;
    uint256 private pricePerToken = 0.01 ether;
    uint256 private maxSupply = 100;

    mapping(uint256 => address) public creators;
    mapping(uint256 => TokenData) tokens;

    struct TokenData {
        uint8 rotation;
        uint8 width;
        uint8 height;
        uint24 color;
    }

    Counters.Counter private _tokenIds;

    constructor(string memory baseURI) ERC1155(baseURI) {}

    modifier onlyCreator(uint256 _id) {
        require(
            creators[_id] == msg.sender,
            "ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    function setTokenData(
        uint256 _id,
        uint8 angle,
        uint8 width,
        uint8 height,
        uint24 color
    ) public onlyCreator(_id) {
        require(angle >= 0 && angle <= 360, "Rotation is out of range.");
        require(width > 0 && width <= 100, "Width is out of range.");
        require(height > 0 && height <= 100, "Height is out of range.");
        tokens[_id].rotation = angle;
        tokens[_id].width = width;
        tokens[_id].height = height;
        tokens[_id].color = color;
    }

    function getTokenData(uint256 _id)
        public
        view
        returns (
            address creator,
            uint8 angle,
            uint8 width,
            uint8 height,
            uint24 color
        )
    {
        require(
            _exists(_id),
            "getTokenData: token query for nonexistent token"
        );
        angle = tokens[_id].rotation;
        width = tokens[_id].width;
        height = tokens[_id].height;
        color = tokens[_id].color;
        creator = creators[_id];
    }

    function totalSupply() public view virtual returns (uint256) {
        return maxSupply;
    }

    function _mintToken(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) internal returns (uint256 _tokenId) {
        _mint(_to, _id, _quantity, _data);
        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
        return tokenId;
    }

    function mint(
        uint8 r,
        uint8 w,
        uint8 h,
        uint24 c
    ) public payable {
        require(
            totalSupply(AnObjectToken) < maxSupply,
            "Maximum supply reached."
        );
        require(msg.value >= pricePerToken, "Not enough Ether sent.");

        uint256 tokenId = _mintToken(msg.sender, AnObjectToken, 1, "Object");
        creators[tokenId] = msg.sender;
        setTokenData(tokenId, r, w, h, c);
    }

    function _mint(
        uint8 r,
        uint8 w,
        uint8 h,
        uint24 c
    ) public onlyOwner {
        uint256 tokenId = _mintToken(msg.sender, AnObjectToken, 1, "Object");
        creators[tokenId] = msg.sender;
        setTokenData(tokenId, r, w, h, c);
    }

    // from https://stackoverflow.com/questions/69328780/convert-uint24-to-hex-string-in-solidity/69328880#69328880
    function uint8tohexchar(uint8 i) public pure returns (uint8) {
        return
            (i > 9)
                ? (i + 87) // ascii a-f
                : (i + 48); // ascii 0-9
    }

    function uint24ToHexStr(uint24 i) public pure returns (string memory) {
        bytes memory o = new bytes(6);
        uint24 mask = 0x00000f; // hex 15
        uint256 k = 6;
        do {
            k--;
            o[k] = bytes1(uint8tohexchar(uint8(i & mask)));
            i >>= 4;
        } while (k > 0);
        return string(o);
    }

    function tokenToCSS(
        uint256 percent,
        uint8 r,
        uint8 w,
        uint8 h,
        uint24 color
    ) private view returns (string memory) {
        string memory cssAnim = "";
        cssAnim = string.concat(cssAnim, Strings.toString(percent));
        cssAnim = string.concat(cssAnim, "%");
        cssAnim = string.concat(cssAnim, " {transform: rotate(");
        cssAnim = string.concat(cssAnim, Strings.toString(r));
        cssAnim = string.concat(cssAnim, "deg); width:");
        cssAnim = string.concat(cssAnim, Strings.toString(w));
        cssAnim = string.concat(cssAnim, "%; height:");
        cssAnim = string.concat(cssAnim, Strings.toString(h));
        cssAnim = string.concat(cssAnim, "%; background-color:#");
        cssAnim = string.concat(cssAnim, uint24ToHexStr(color));
        cssAnim = string.concat(cssAnim, ";}");
        return cssAnim;
    }

    function css() private view returns (bytes memory) {
        uint256 supply = totalSupply(AnObjectToken);
        string memory cssAnim = "@keyframes colors {";
        uint256 step = 100 / supply;
        for (uint256 i = 0; i < supply; ++i) {
            cssAnim = string.concat(
                cssAnim,
                tokenToCSS(
                    i * step,
                    tokens[i].rotation,
                    tokens[i].width,
                    tokens[i].height,
                    tokens[i].color
                )
            );
        }

        cssAnim = string.concat(
            cssAnim,
            tokenToCSS(maxSupply, 0, 50, 50, 0x0000FF)
        );
        return abi.encodePacked(string.concat(cssAnim, "}"));
    }

    function html() private view returns (bytes memory) {
        return
            abi.encodePacked(
                "<!DOCTYPE html>"
                "<html>"
                "<head>"
                "<title>",
                "An Object.",
                "</title>"
                '<meta name="description" content="An Object" />'
                '<style type="text/css">'
                "body { background:#CCC;margin:0;padding:0;overflow:hidden; }"
                ".container { aspect-ratio:1/1; margin:0; padding:0; position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%);"
                "display: flex;   justify-content: center; align-items: center; height: 100vmin; max-width:100vmin; }",
                css(),
                ".box {"
                "background: #0000FF;"
                "width: 50%;"
                "height:50%;"
                "transform-origin: center center;"
                "animation-name: colors;"
                "animation-duration:",
                Strings.toString(totalSupply(AnObjectToken)),
                "s;"
                "animation-delay:1s;"
                "animation-iteration-count:infinite;"
                "}"
                "</style>"
                "</head>"
                "<body>"
                '<div class="container">'
                '<div class="box"></div>'
                "</div>"
                "</body>"
                "</html>"
            );
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(
            _exists(_id),
            "ERC1155Metadata: URI query for nonexistent token"
        );
        bytes memory metadata = abi.encodePacked(
            "{"
            '"name":"An Object",'
            '"description":"This is an object, play with it.",',
            '"animation_url":"data:text/html;base64,',
            Base64.encode(html()),
            '"'
            "}"
        );

        return string(abi.encodePacked("data:application/json,", metadata));
    }

    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    function withdrawAll() external onlyOwner {
        uint256 amount = address(this).balance;
        require(payable(owner()).send(amount));
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        
        for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                creators[id] = to;
        }
    }
}