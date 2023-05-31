//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AbiItem is ERC721PresetMinterPauserAutoId, Ownable{
    string private _baseTokenURI;
    bool private _isUriFrozen = false;

    constructor(
        string memory NFTName,
        string memory NFTSymbol,
        string memory _collectibleURI
    ) ERC721PresetMinterPauserAutoId(NFTName, NFTSymbol, _collectibleURI) {
        _baseTokenURI = _collectibleURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _newBaseURI) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC721PresetMinterPauserAutoId: must have admin role to change URI"
        );
        require(!_isUriFrozen, 'Token URI is frozen');
        _baseTokenURI = _newBaseURI;
    }

    function freezeTokenURI() public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC721PresetMinterPauserAutoId: must have admin role to freeze token URI"
        );
        require(!_isUriFrozen, 'Token URI is frozen');
        _isUriFrozen = true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenUri = super.tokenURI(tokenId);
        return bytes(tokenUri).length > 0 ? string(abi.encodePacked(tokenUri, ".json")) : "";
    }

    function mint(address to) public virtual override {
        require(false, "mint() is blocked use mintToken()");
    }

    function mintToken(
        uint256 id,
        address owner
    ) public returns (uint256) {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC721PresetMinterPauserAutoId: must have minter role to mint"
        );

        super._safeMint(owner, id);

        return id;
    }
}