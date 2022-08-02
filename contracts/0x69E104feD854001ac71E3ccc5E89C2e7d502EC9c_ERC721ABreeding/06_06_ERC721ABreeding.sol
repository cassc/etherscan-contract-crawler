// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

abstract contract ParentContract {
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address);
    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256);
}

contract ERC721ABreeding is ERC721A, Ownable {

    using Strings for uint256;

    struct Baby {
        uint16 mom;
        uint16 dad;
    }

    struct Parent {
        uint16 id;
        bool canBreed;
    }

    ParentContract public momContract;
    ParentContract public dadContract;
    uint16 public maxSupply;

    mapping(uint256 => bool) public isMom;
    mapping(uint256 => bool) public isDad;
    mapping(uint256 => Baby) public babies;
    mapping(uint256 => uint256) public birthdays;
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
        momContract = ParentContract(_momContract);
        dadContract = ParentContract(_dadContract);
        transferOwnership(_owner);
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function canBreed(address _owner, uint _type) external view returns (Parent[] memory) {
        ParentContract parentContract = _type == 1 ? dadContract : momContract;
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
        for (uint16 i = 0; i < _quantity; i++) {
            require(momContract.ownerOf(momIds[i]) == msg.sender, "Not owner of mom");
            require(dadContract.ownerOf(dadIds[i]) == msg.sender, "Not owner of dad");
            require(!isMom[momIds[i]], "Already a mom");
            require(!isDad[dadIds[i]], "Already a dad");
        }
        uint256 _currentIndex = _currentSupply;
        for (uint16 i = 0; i < _quantity; i++) {
            isMom[momIds[i]] = true;
            isDad[dadIds[i]] = true;
            babies[_currentIndex].mom = momIds[i];
            babies[_currentIndex].dad = dadIds[i];
            birthdays[_currentIndex++] = block.timestamp;
        }
        _safeMint(msg.sender, _quantity);
    }

    function reserve(address _address, uint16 _quantity) public onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Insufficient supply");
        _safeMint(_address, _quantity);
    }
}