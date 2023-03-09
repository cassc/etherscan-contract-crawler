// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract GeoMetric is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public maxSupply = 999;
    uint256 public cost = 0.01 ether;

    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  
    struct Art { 
        string name;
        string description;
        string bgHue;
        string circleHue;
        string tokenValue;
    }
  
    mapping (uint256 => Art) public art;
    mapping (uint256 => bool) public tokenClaimed;
  
    constructor() ERC721("GeoMetric", "GEOMTC") {}

    // public
    function mint(uint256 _tokenId) public payable {
        //uint256 supply = totalSupply();
        require(_tokenId > 0 && _tokenId <= maxSupply, "Token not exist");
        require(!tokenClaimed[_tokenId], "No QTs here, try your own ID");
        require(msg.value >= cost, "Price is 0.01 Ether");
    
        Art memory newArt = Art(
            string(abi.encodePacked('GEO-METRIC #', uint256(_tokenId).toString())),
            string(abi.encodePacked("Generated on chain art. This particular artwork was generated at position: #", uint256(totalSupply() + 1).toString())),
            randomNum(361, block.basefee, _tokenId).toString(),
            randomNum(361, block.timestamp, _tokenId).toString(),
            string(uint256(_tokenId).toString()));
    
        art[_tokenId] = newArt;
        tokenClaimed[_tokenId] = true;
        _safeMint(msg.sender, _tokenId);
    }

    function randomNum(uint256 _mod, uint256 _seed, uint _salt) public view returns(uint256) {
        uint256 num = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt))) % _mod;
        return num;
    }
  
    function buildImage(uint256 _tokenId) public view returns(string memory) {
        Art memory currentArt = art[_tokenId];
        return Base64.encode(bytes(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500">',
                '<rect xmlns="http://www.w3.org/2000/svg" height="500" width="500" fill="hsl(',currentArt.bgHue,', 100%, 90%)"/>',
                '<rect style="fill: hsl(',currentArt.tokenValue,', 40%, 60%);" x="40%" y="50%" width="200" height="200" transform="translate(-100, -100)" rx="30"/>',
                '<circle style="fill: hsl(',currentArt.circleHue,', 80%, 25%);" cx="55%" cy="50%" r="100"/>',
                '<text font-family="Raleway" font-size="88" font-style="normal" font-weight="900" style="fill: hsl(',currentArt.tokenValue,', 50%, 40%);" x="55%" y="52%" text-anchor="middle" dominant-baseline="middle">',currentArt.tokenValue,'</text>',
                '</svg>'
            )
        ));
    }
  
    function buildMetadata(uint256 _tokenId) public view returns(string memory) {
        Art memory currentArt = art[_tokenId];
        return string(abi.encodePacked(
                'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                            '{"name":"', 
                            currentArt.name,
                            '", "description":"', 
                            currentArt.description,
                            '", "image": "', 
                            'data:image/svg+xml;base64,', 
                            buildImage(_tokenId),
                            '"}')))));
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        return buildMetadata(_tokenId);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}