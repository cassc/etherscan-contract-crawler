// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';

contract EvilWizNFT is Ownable, ERC721AQueryable, ERC721ABurnable {
    event EvilWizMinted(address owner, uint256 wzrdType, uint256 evilWzrdId);

    string private baseMetadataUri;
    mapping(address => bool) private altarOfSacrifice;
    mapping(uint256 => uint256) private tokenToTypeMap;
    mapping(uint256 => uint256) private tokenToIndexMap;
    mapping(uint256 => uint256) private counterPerType;

    constructor() ERC721A('EvilWizNFT', 'EVLWZNFT') {}

    function claimFromSkull(address a, uint256 skullId, uint quantity) public onlyAltars {
        uint256 currIndex = _currentIndex;
        _safeMint(a, quantity);
        for (uint i = 0 ; i < quantity ; i++ ) {
            emit EvilWizMinted(a, skullId, currIndex+i);
            tokenToTypeMap[currIndex+i] = skullId;
            tokenToIndexMap[currIndex+i] = counterPerType[skullId];
            counterPerType[skullId] = counterPerType[skullId] + 1;
        }
    }

    function burnFromAltar(uint256 tokenId) public onlyAltars {
        require(_exists(tokenId), 'Token does not exist');
        _burn(tokenId);
    }

    function getSkullTypeOfToken(uint256 tokenId) public view returns (uint256) {
        return tokenToTypeMap[tokenId];
    }

    function getSkullIndexOfToken(uint256 tokenId) public view returns (uint256) {
        return tokenToIndexMap[tokenId];
    }

    function setBaseMetadataUri(string memory a) public onlyOwner {
        baseMetadataUri = a;
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        if (altarOfSacrifice[operator]) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseMetadataUri;
    }

    function addAltar(address a) public onlyOwner {
        altarOfSacrifice[a] = true;
    }

    function removeAltar(address a) public onlyOwner {
        altarOfSacrifice[a] = false;
    }

    modifier onlyAltars() {
        require(altarOfSacrifice[_msgSender()], 'Not an altar of sacrifice');
        _;
    }
}