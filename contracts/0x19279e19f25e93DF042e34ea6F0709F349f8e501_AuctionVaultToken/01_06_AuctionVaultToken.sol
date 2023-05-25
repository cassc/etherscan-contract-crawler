// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'erc721a/contracts/ERC721A.sol';
import './library/errors/Errors.sol';
import './interfaces/ITokenMetadata.sol';
import 'solmate/src/auth/Owned.sol';

contract AuctionVaultToken is Owned, ERC721A {
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    mapping(address => bool) private _tokenManagers;
    ITokenMetadata public _tokenMetadata;
    string public _baseTokenURI;
    string public contractURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI,
        string memory _contractURI)
        Owned(msg.sender)
        ERC721A(name_, symbol_) {
            _baseTokenURI = baseTokenURI;
            contractURI = _contractURI;
    }

    function toggleTokenManager(address wallet, bool permission) onlyOwner public {
        _tokenManagers[ wallet ] = permission;
    }

    function tokenManager(address wallet) public view returns(bool) {
        return _tokenManagers[ wallet ];
    }

    modifier onlyTokenManagers() {
        if (false == _tokenManagers[ msg.sender ]) {
            revert Errors.UserPermissions();
        }

        _;
    }

    function mint(address dest, uint256 qty) onlyTokenManagers public {
        _mint(dest, qty);
    }

    function burn(uint256 tokenId) onlyTokenManagers public {
        _burn(tokenId);
    }

    function updateBaseURI(string memory uri) onlyOwner public {
        _baseTokenURI = uri;
        _tokenMetadata = ITokenMetadata(address(0));
    }

    function setMetadataContract(address tokenMetadata) onlyOwner public {
        _tokenMetadata = ITokenMetadata(tokenMetadata);
    }

    function _baseURI() internal override view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public override view returns(string memory) {
        if (address(_tokenMetadata) != address(0)) {
            return _tokenMetadata.tokenURI(tokenId);
        }

		return ERC721A.tokenURI(tokenId);
    }


    function updateMetadata(uint256 id) public onlyOwner {
        emit MetadataUpdate(id);
    }

    function updateAllMetadata() public onlyOwner {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }
}