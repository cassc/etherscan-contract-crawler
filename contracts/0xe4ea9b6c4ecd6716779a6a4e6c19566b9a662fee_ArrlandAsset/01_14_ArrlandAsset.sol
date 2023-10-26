// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./utils/ParsingPreAsset.sol";

contract ArrlandAsset is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    mapping(uint256 => string) private BASE_URLS; // base urls per asset type 0 - chest, 1 - island, 2 - ship
    mapping(uint256 => uint256) private ASSET_TYPE_PER_ID;

    uint256 public totalSupply;

    address public imx;

    constructor (address _imx, string memory _baseURI) ERC721("ArrlandAssets", "ARAS") {
        imx = _imx;
        BASE_URLS[0] = _baseURI;
        totalSupply = 0;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = BASE_URLS[ASSET_TYPE_PER_ID[tokenId]];
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _mintAsset(address to, uint256 tokenID, uint256 _assetType) private returns (uint256) {
        ASSET_TYPE_PER_ID[tokenID] = _assetType;
        totalSupply += 1;
        _safeMint(to, tokenID);
        return tokenID;
    }

    function setBaseURI(string memory _baseURI, uint256 _assetType) public onlyOwner {
        BASE_URLS[_assetType] = _baseURI;
    }

    function mintFor(
        address user,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external {
        require(quantity == 1, "Invalid quantity");
        require(msg.sender == imx, "Function can only be called by IMX");
        (uint256 tokenId, uint256 assetType) = ParsingPreAsset.split(mintingBlob);
        _mintAsset(user, tokenId, assetType);
    }

}