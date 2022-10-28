// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";

contract AnObject is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 private pricePerToken = 0.01 ether;
    uint256 private maxSupply = 100;
    mapping(uint256 => address) public creators;
    mapping(uint256 => TokenData) tokens;
    bool private paused;

    struct TokenData {
        uint8 rotation;
        uint8 width;
        uint8 height;
        uint24 color;
    }

    Counters.Counter private _tokenIds;

    constructor() ERC721("An Object", "OBJ") {
        paused = false;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier onlyCreator(uint256 _id) {
        require(
            creators[_id] == msg.sender,
            "AnObject#creatorOnly: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    function _unpause() public onlyOwner {
        paused = false;
    }

    function _pause() public onlyOwner {
        paused = true;
    }

    function setTokenData(
        uint256 id,
        uint8 rotation,
        uint8 width,
        uint8 height,
        uint24 color
    ) public onlyCreator(id) {
        require(rotation >= 0 && rotation <= 180, "Rotation is out of range.");
        require(width > 0 && width <= 100, "Width is out of range.");
        require(height > 0 && height <= 100, "Height is out of range.");
        tokens[id].rotation = rotation;
        tokens[id].width = width;
        tokens[id].height = height;
        tokens[id].color = color;
    }

    function getTokenData(uint256 id)
        public
        view
        returns (
            address creator,
            uint8 rotation,
            uint8 width,
            uint8 height,
            uint24 color
        )
    {
        require(
            _exists(id),
            "getTokenData: token query for nonexistent token"
        );
        rotation = tokens[id].rotation;
        width = tokens[id].width;
        height = tokens[id].height;
        color = tokens[id].color;
        creator = creators[id];
    }

    function _mintToken(address _to) internal returns (uint256 _tokenId) {
        uint256 tokenId = _tokenIds.current();
        _safeMint(_to, tokenId);
        _tokenIds.increment();
        return tokenId;
    }

    function mint(
        uint8 r,
        uint8 w,
        uint8 h,
        uint24 c
    ) public payable whenNotPaused {
        require(
            totalSupply() < maxSupply,
            "Maximum supply reached."
        );
        require(msg.value >= pricePerToken, "Not enough Ether sent.");
        uint256 tokenId = _mintToken(msg.sender);
        creators[tokenId] = msg.sender;
        setTokenData(tokenId, r, w, h, c);
    }

    function _mint(
        uint8 r,
        uint8 w,
        uint8 h,
        uint24 c
    ) public onlyOwner {
        uint256 tokenId = _mintToken(msg.sender);
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
        uint256 supply = totalSupply();
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
                Strings.toString(totalSupply()),
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

    function image(uint256 _id) private view returns (bytes memory) {

        uint8 w = tokens[_id].width;
        uint8 h = tokens[_id].height;
        uint8 r = tokens[_id].rotation;
        uint8 cx = w/2;
        uint8 cy = h/2;
        return abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"' 
            ' style="background-color:#CCC;'
            ' transform-box: fill-box;'
            ' transform-origin: center;'
            ' transform: rotate(',Strings.toString(r),'deg);">'
                '<rect width="',Strings.toString(w),'"'
                    ' height="',Strings.toString(h),'"'
                    ' x="-',Strings.toString(cx),'"'
                    ' y="-',Strings.toString(cy),'"'
                    ' transform="translate(50,50)"'
                    ' style="fill:',string.concat("#", uint24ToHexStr(tokens[_id].color)),'" />'
            '</svg>'
        );
    }

    function tokenURI(uint256 _id) public view override returns (string memory) {
        require(
            _exists(_id),
            "AnObject: URI query for nonexistent token"
        );
        bytes memory metadata = abi.encodePacked(
            "{"
            '"name":"An Object #',Strings.toString(_id),'",'
            '"description":"This is an object, play with it.",',
            '"image":"data:image/svg+xml;base64,',Base64.encode(image(_id)),'",'
            '"external_url": "http://www.an-object.xyz",', 
            '"animation_url":"data:text/html;base64,',
            Base64.encode(html()),'",',
            '"attributes": ['
                '{'
                    '"trait_type": "Rotation (Deg)",', 
                    '"value": "',Strings.toString(tokens[_id].rotation),'"'
                '},' 
                '{'
                    '"trait_type": "Width (%)",', 
                    '"value": "',Strings.toString(tokens[_id].width),'"'
                '},' 
                '{'
                    '"trait_type": "Height (%)",', 
                    '"value": "',Strings.toString(tokens[_id].height),'"'
                '},' 
                '{'
                    '"trait_type": "Color (Hex)",', 
                    '"value": "',string.concat("#", uint24ToHexStr(tokens[_id].color)),'"'
                '}' 
            ']'
            "}"
        );

        return string(abi.encodePacked("data:application/json,", metadata));
    }

    function withdrawAll() external onlyOwner {
        uint256 amount = address(this).balance;
        require(payable(owner()).send(amount));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        creators[tokenId] = to;
    }
}