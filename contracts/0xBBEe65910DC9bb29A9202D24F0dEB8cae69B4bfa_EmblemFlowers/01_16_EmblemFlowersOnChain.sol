// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract EmblemFlowers is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bool public paused = true;
    uint256 public price = 10000000000000000; // 0.01
    uint256 public maxSupply = 999;
  
    mapping (uint256 => uint256) private tokensPosition;
    mapping (uint256 => uint256) private tokensDifficulty;
  
    constructor() ERC721("Emblem Flowers", "EFOC") {}

    function blossom(uint256 _tokenId) public payable {
        require(!paused, "Not open yet");
        require(msg.value >= price, "Wrong value");
        require(_tokenId > 0 && _tokenId <= maxSupply, "Token Id out of range");

        uint256 position = totalSupply() + 1;

        tokensPosition[_tokenId] = position;
        tokensDifficulty[_tokenId] = block.difficulty;
        _safeMint(msg.sender, _tokenId);
    }

    function randomNum(uint256 _mod, uint256 _seed, uint _salt) public view returns(uint256) {
        uint256 num = uint(keccak256(abi.encodePacked(block.timestamp, _seed, _salt))) % _mod;
        return num;
    }
  
    function buildImage(uint256 _tokenId) public view returns(string memory) {
        bytes memory output;

        uint256 sum = _tokenId + tokensPosition[_tokenId];

        string memory bgHue = randomNum(361, tokensDifficulty[_tokenId], _tokenId).toString();
        string memory centerHue = randomNum(361, block.timestamp, sum).toString();
        string memory petalsHue = randomNum(361, tokensDifficulty[_tokenId], tokensPosition[_tokenId]).toString();

        string[21] memory imageParts = [
            '<svg xmlns="http://www.w3.org/2000/svg" style="background-color:hsl(',
            bgHue,
            ', 100%, 90%)" viewBox="0 0 500 500"><circle style="fill: hsl(',
            petalsHue,
            ', 80%, 25%);" cx="30%" cy="50%" r="100"/><circle style="fill: hsl(',
            petalsHue,
            ', 80%, 25%);" cx="70%" cy="50%" r="100"/><circle style="fill: hsl(',
            petalsHue,
            ', 80%, 25%);" cx="50%" cy="30%" r="100"/><circle style="fill: hsl(',
            petalsHue,
            ', 80%, 25%);" cx="50%" cy="70%" r="100"/><circle style="fill: hsl(',
            centerHue,
            ', 40%, 60%);" cx="50%" cy="50%" r="100"/><text font-family="Raleway" font-size="30" font-style="normal" font-weight="900" style="fill: hsl(',
            centerHue,
            ', 50%, 40%);" x="10%" y="95%" text-anchor="middle" dominant-baseline="middle">',
            uint256(_tokenId).toString(),
            '</text><text font-family="Raleway" font-size="30" font-style="normal" font-weight="900" style="fill: hsl(',
            centerHue,
            ', 50%, 40%);" x="90%" y="95%" text-anchor="middle" dominant-baseline="middle">#',
            uint256(tokensPosition[_tokenId]).toString(),
            '</text></svg>'
        ];

        for (uint256 i = 0; i < imageParts.length; i++) {
            output = abi.encodePacked(output, imageParts[i]);
        }

        return Base64.encode(bytes(output));
    }
  
    function buildMetadata(uint256 _tokenId) public view returns(string memory) {
        return string(abi.encodePacked(
                'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                            '{"name":"Flower #', 
                            uint256(_tokenId).toString(),
                            '", "description":"Flowers generated on chain. This flower was generated at position: #',
                            uint256(tokensPosition[_tokenId]).toString(),
                            '", "image": "', 
                            'data:image/svg+xml;base64,', 
                            buildImage(_tokenId),
                            '"}')))));
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
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