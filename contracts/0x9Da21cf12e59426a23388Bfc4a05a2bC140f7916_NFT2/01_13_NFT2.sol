// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract NFT2 is Ownable, ERC721, IERC721Enumerable {
    bytes32 public whitelist;
    uint public nextId = 51;
    uint256[] private _allTokens;
    mapping(address => bool) private _whitelistClaimed;
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    mapping(uint256 => uint256) private _allTokensIndex;


    constructor() ERC721('Estate Trader Activity Building Card', 'ETA') {
        address owner = 0x33dB393656941F4EE093aB4a9df2EdaaF2BACf78;
        transferOwnership(owner);
        for (uint i = 1; i < nextId; i++) {
            _safeMint(owner, i);
        }
    }

    function updateWhitelist(bytes32 _whitelist) public onlyOwner {
        whitelist = _whitelist;
    }

    function mintTo(address to) public onlyOwner {
        require(to.code.length==0,'invalid to address.');
        _safeMint(to, nextId);
        nextId += 1;
    }

    function burn(uint256 tokenId) public {
        require(_exists(tokenId), "Operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        require(owner == msg.sender, "Burn caller is not owner");
        super._burn(tokenId);
    }

    function whitelistMint(bytes32[] memory proof) public {
        require(!_whitelistClaimed[_msgSender()], 'Address already claimed!');
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(proof, whitelist, leaf), 'Invalid proof!');
        _whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), nextId);
        nextId += 1;
    }

    function mintable(bytes32[] memory proof) view public returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        return !_whitelistClaimed[_msgSender()] && MerkleProof.verify(proof, whitelist, leaf);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; 
            _ownedTokensIndex[lastTokenId] = tokenIndex; 
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex; 

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    function _baseURI() internal pure override returns (string memory) {
        return 'https://estatetrader.io/nft.metadata/buildingcard/';
    }
}