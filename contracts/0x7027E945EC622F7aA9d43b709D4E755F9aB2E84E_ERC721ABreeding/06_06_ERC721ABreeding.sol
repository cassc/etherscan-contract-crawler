// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract ERC721ABreeding is ERC721A, Ownable {

    using Strings for uint256;

    struct Baby {
        uint16 mom;
        uint16 dad;
        uint32 birthday;
    }

    struct Parent {
        uint16 id;
        bool canBreed;
    }

    ERC721A public momContract;
    ERC721A public dadContract;
    uint16 public maxSupply;

    mapping(uint256 => bool) public isMom;
    mapping(uint256 => bool) public isDad;
    mapping(uint256 => Baby) public babies;
    bool public claimIsActive;
    string private baseURI;
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _owner,
        uint16 _maxSupply,
        address _momContract,
        address _dadContract
    ) ERC721A(_name, _symbol) {
        baseURI = _uri;
        maxSupply = _maxSupply;
        momContract = ERC721A(_momContract);
        dadContract = ERC721A(_dadContract);
        transferOwnership(_owner);
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function canBreed(address _owner, uint _type) external view returns (Parent[] memory) {
        ERC721A parentContract = _type == 1 ? dadContract : momContract;
        unchecked {
            uint tokenIdsIdx;
            uint tokenIdsLength = parentContract.balanceOf(_owner);
            Parent[] memory tokenIds = new Parent[](tokenIdsLength);
            for (uint16 i = 0; tokenIdsIdx != tokenIdsLength; i++) {
                if (parentContract.ownerOf(i) == _owner) {
                    tokenIds[tokenIdsIdx].id = i;
                    tokenIds[tokenIdsIdx++].canBreed = !(_type == 1 ? isDad[i] : isMom[i]);
                }
            }
            return tokenIds;
        }
    }

    function setClaimState(bool _claimIsActive) public onlyOwner {
        claimIsActive = _claimIsActive;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function breed(uint16[] memory dadIds, uint16[] memory momIds) public {
        require(claimIsActive, "Claim inactive");
        require(momIds.length == dadIds.length, "Array lengths don't match");
        uint256 _quantity = momIds.length;
        uint256 _currentSupply = totalSupply();
        require(_currentSupply + _quantity <= maxSupply, "Insufficient supply");
        uint256 _currentIdx = _currentSupply;
        for (uint16 i = 0; i < _quantity; i++) {
            if (
                momContract.ownerOf(momIds[i]) == msg.sender &&
                dadContract.ownerOf(dadIds[i]) == msg.sender &&
                !isMom[momIds[i]] &&
                !isDad[dadIds[i]]
            ) { 
                isMom[momIds[i]] = true;
                isDad[dadIds[i]] = true;
                babies[_currentIdx++] = Baby(momIds[i], dadIds[i], uint32(block.timestamp));
            }
        }
        if (_currentIdx > _currentSupply) {
            _safeMint(msg.sender, _currentIdx - _currentSupply);
        }
    }

    function reserve(address _address, uint16 _quantity) public onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Insufficient supply");
        _safeMint(_address, _quantity);
    }
}