// SPDX-License-Identifier: MIT
// TOKEN 365

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Base64.sol";

contract Signature is ERC721, Ownable {
    address private _artist;
    mapping (address => bool) private _creators;
    string private _externalLib;
    mapping (uint => uint) private _idToSeed;
    string private _imageExtension;
    string private _imageBaseUrl;
    uint private _tokensCreated = 0;
    bool private _paused = true;
    uint private _platformFee;
    uint private _tokenPrice = 3650000000000000;
    
    uint private constant TOKEN_LIMIT = 365;
    string private constant SCRIPT = "let slice = []; for (let i = 2; i < 66; i+=4) { slice.push(hashString.slice(i, i+4)); } let decRows = slice.map(x => parseInt(x, 16)); const border = 32; const max = 256 + border * 2; let canvas, scaling, lineLength, lineY; let r, g, b; let colors = true; function setup() { scaling = Math.min(window.innerWidth/max, window.innerHeight/max); canvas = max * scaling; createCanvas(canvas, canvas); r = shifted(0, 1); g = shifted(2, 5); b = shifted(4, 3); lineY = (230 + border) * scaling; } function draw() { background(255); if (colors) { background(r, g, b, 120); strokeWeight(1); fill(0); stroke(0); drawingContext.setLineDash([scaling * 6, scaling * 3]); line(border * scaling, lineY, (max - border) * scaling, lineY); drawingContext.setLineDash([]); noStroke(); let fontSize = 12 * scaling; textFont('Times New Roman', fontSize); text('Signature', (border + 10) * scaling, lineY + fontSize / 2 + 10 * scaling); bgAlpha = shifted(6, 7) / 2; stroke(r, g, b, bgAlpha < 80 ? bgAlpha : 0); let points = floor(shifted(3, 2) / 3) + 1; let pointsWidth = (256 * scaling) / points; strokeWeight(pointsWidth); for (var v = 0; v < points; v++) { for (var h = 0; h < points; h++) { point(pointsWidth * h + (border * scaling) + pointsWidth / 2, pointsWidth * v + (border * scaling) + pointsWidth / 2); } } } signature(); noLoop(); } function signature() { noFill(); let sw; for(var i = colors ? 0 : 3; i <= 3; i++) { if (i == 3) { if (colors) { stroke(255 - r , 255 - g , 255 - b, 215); } else { stroke(0); } } else { stroke(i * 40); } let weight = shifted(8, 4) / 160; sw = (i * (0.3 + weight) + 0.5) * scaling; strokeWeight(sw); beginShape(); curveVertex(border * scaling, lineY); curveVertex((border + 20) * scaling + sw, (lineY + sw) - 20 * scaling); for (var row = 0; row < decRows.length; row++) { curveVertex(pos(row, 0) + sw, pos(row, 8) + sw); } endShape(); } } function pos(row, i) { return (shifted(row, i) + border) * scaling; } function shifted(row, i) {  return ((decRows[row] >> i) & 0xFF); } function keyTyped() { if (key === 's') { saveCanvas('signature', 'png'); } if (key === 'c') { colors = !colors; redraw(); } }";

    constructor(address artist, uint fee) ERC721("Signature", "Signature") {
        _artist = artist;
        _platformFee = fee;
        _imageBaseUrl = 'https://signature.token365.art/';
        _imageExtension = '.svg';
        _externalLib = 'https://ipfs.io/ipfs/Qmej2aMjKpsH2gGmR1bDnGT7FYWPuuqedgrb3i9NKDjDVw/p5-150.min.js';
    }
    
    function animationPage(uint tokenId) public view returns (string memory) {
        string memory _script = script(tokenId);
        if (bytes(_script).length > 0) {
            return string(abi.encodePacked("data:text/html;base64,", Base64.encode(abi.encodePacked('<html><head><title>Signature by Ruud Ghielen</title><script src="', _externalLib, '"></script><script>', _script, '</script></head><body style="margin:0;"><main></main></body></html>'))));
        }
        return "";
    }

    function canCreate() public view returns (bool) {
        return _tokensCreated < totalSupply() && !_paused;
    }
    
    function create() external payable returns (uint) {
        require(this.canCreate());
        require(msg.value >= this.price());
        uint _id = _create(msg.sender);
        if (msg.value > 0) {
            uint value = (msg.value / 100) * _platformFee;
            if (value > 0) {
                payable(owner()).transfer(value);
            }
            payable(_artist).transfer(msg.value - value);
        }
        return _id;
    }

    function createForAddress(address receiver) public onlyOwner returns (uint) {
        require(_tokensCreated < totalSupply());
        uint _id = _create(receiver);
        return _id;
    }

    function _create(address _creator) internal returns (uint) {
        require(_creator != address(0));
        require(!_creators[_creator]);
        _creators[_creator] = true;
        _tokensCreated = _tokensCreated + 1;
        uint _id = _tokensCreated;
        uint _seed = hash(_creator);
        _idToSeed[_id] = _seed;
        _safeMint(_creator, _id);
        return _id;
    }

    function getHash(uint tokenId) public view returns (string memory) {
        return Strings.toHexString(_idToSeed[tokenId]);
    }

    function hash(address creator) private pure returns (uint) {
        return uint(keccak256(abi.encodePacked(creator)));
    }

    function price() public view returns (uint) {
        return _tokenPrice;
    }

    function script(uint tokenId) public view returns (string memory) {
        uint _seed = _idToSeed[tokenId];
        if (_seed > 0) {
            return string(abi.encodePacked("let hashString = '", Strings.toHexString(_seed), "'; ", SCRIPT));
        }
        return "";
    }

    function setPaused(bool paused) public onlyOwner {
        _paused = paused;
    }

    function setTokenPrice(uint tokenPrice) public onlyOwner {
        _tokenPrice = tokenPrice;
    }

    function setImageUrl(string memory imageBaseUrl, string memory imageExtension) public onlyOwner {
        _imageBaseUrl = imageBaseUrl;
        _imageExtension = imageExtension;
    }

    function setExternalLib(string memory url) public onlyOwner {
        _externalLib = url;
    }

    function tokensCreated() public view returns (uint) {
        return _tokensCreated;
    }

    function totalSupply() public pure returns (uint) {
        return TOKEN_LIMIT;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (tokenId > 0 && tokenId <= _tokensCreated) {
            return string(abi.encodePacked('data:application/json,{"name":"Signature ', Strings.toString(tokenId), '","description":"The Signature is a visual representation of the wallet address that created this token. No worries, the script and hash are both stored immutably inside this blockchain contract to generate the image.","image":"', _imageBaseUrl, Strings.toString(tokenId), _imageExtension, '","external_url":"https://www.token365.art/","animation_url":"', animationPage(tokenId), '","interaction":"Press C to switch between colored and outline Signature, Press S to save the image"}'));
        } else {
            return "";
        }
    }
    
    function withdraw() public onlyOwner {
        require(address(this).balance > 0);
        payable(owner()).transfer(address(this).balance);
    }
}
