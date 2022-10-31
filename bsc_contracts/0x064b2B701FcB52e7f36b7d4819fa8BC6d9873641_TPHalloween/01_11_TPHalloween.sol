// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TPHalloween is ERC721, Ownable {

    using Strings for uint256;

    uint256 public totalSupply;
    uint256 public  circulationSupply;
    mapping(address => bool) public minted;
    //tokenId => style
    mapping(uint256 => uint256) private _token_style;
    string public baseURI;

    event Mint(address indexed owner, uint256 indexed tokenId, uint256 indexed style);

    constructor(string memory uri) ERC721("TokenPocket Halloween", "TP Halloween") {
        baseURI = uri;
    }

    function updateBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "TPHalloween: URI query for nonexistent token");

        uint256 style = _token_style[tokenId];
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, style.toString(), ".json")) : "";
    }

    function mint(address[] memory accounts, uint style) public onlyOwner returns (uint256 tokenId) {
        for (uint256 i; i < accounts.length; i++) {
            tokenId = circulationSupply + 1;
            _safeMint(accounts[i], tokenId);
            circulationSupply = tokenId;
            _token_style[tokenId] = style;
            emit Mint(accounts[i], tokenId, style);
            totalSupply++;
        }
    }
}