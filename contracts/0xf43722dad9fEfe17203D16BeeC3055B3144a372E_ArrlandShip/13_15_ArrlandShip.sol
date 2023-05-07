// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./utils/ParsingPreAsset.sol";

contract ArrlandShip is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    string public BASE_URL;
    uint256 public totalSupply;
    address public imx;

    constructor (address _imx, string memory _baseURI) ERC721("ArrlandIsland", "ArrI") {
        imx = _imx;
        BASE_URL = _baseURI;
        totalSupply = 0;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = BASE_URL;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _mintAsset(address to, uint256 tokenID) private returns (uint256) {
        totalSupply += 1;
        _safeMint(to, tokenID);
        return tokenID;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        BASE_URL = _baseURI;
    }

    function mintFor(
        address user,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external {
        require(quantity == 1, "Invalid quantity");
        require(msg.sender == imx, "Function can only be called by IMX");
        (uint256 tokenId, ) = ParsingPreAsset.split(mintingBlob);
        _mintAsset(user, tokenId);
    }

}