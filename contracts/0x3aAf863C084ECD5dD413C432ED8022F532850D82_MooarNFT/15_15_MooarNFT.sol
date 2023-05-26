// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC173.sol";

contract MooarNFT is ERC721Enumerable, Ownable {
    string private _baseTokenURI;
    address private _mooar;
    string private _tokenSuffix;

    uint256 public maxSupply;
    
    mapping(address => bool) private _priorityMinterRecords;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        string memory tokenSuffix,
        uint256 maxSupply_)
        ERC721(name, symbol)
    {
        _baseTokenURI = baseURI;
        _mooar = _msgSender();
        _tokenSuffix = tokenSuffix;
        maxSupply = maxSupply_;
    }

    modifier onlyMooar() {
        require(_msgSender() == _mooar, "Only for mooar contract");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC173).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory uri = super.tokenURI(tokenId);
        return bytes(_tokenSuffix).length > 0 ? string(abi.encodePacked(uri, _tokenSuffix)) : uri;
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return _baseTokenURI;
    }

    function mooarMint(address to, uint256 tokenId) onlyMooar external {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) external virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Burn caller is not owner nor approved"
        );
        _burn(tokenId);
    }

}