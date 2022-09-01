//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

interface IPixelPuppers {
    function ownerOf(uint256 tokenId) external view returns (address);

    function totalSupply() external view returns (uint16);
}

contract GoldenBone is ERC721A, Ownable {
    using Strings for uint256;
    string public baseUri;
    IPixelPuppers pixelPuppersContract;
    address public pixelPuppersAddress;
    bool public isActive = false;

    mapping(uint256 => bool) public isClaimed;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by contract");
        _;
    }

    constructor(address _pixelPuppersAddress) ERC721A("GoldenBone", "GBN") {
        pixelPuppersAddress = _pixelPuppersAddress;
        pixelPuppersContract = IPixelPuppers(
            _pixelPuppersAddress
        );
    }

    function claimBone(uint16[] calldata _pupperTokenIds) public callerIsUser {
        require(isActive, "Golden Bone claming is not active yet");
        // Require that _pupperTokenIds is length 4
        require(
            _pupperTokenIds.length >= 4,
            "Must provide at least four pupper token ids"
        );
        require(
            _pupperTokenIds.length % 4 == 0,
            "Must provide a multiple of 4 pupper token ids"
        );
        // Require that none of the _pupperTokenIds have been claimed and that the msg.sender is the owner of them
        for (uint256 i = 0; i < _pupperTokenIds.length; i++) {
            require(
                !isClaimed[_pupperTokenIds[i]],
                "Cannot claim a bone using puppers that have already claimed a bone"
            );
            require(
                pixelPuppersContract.ownerOf(_pupperTokenIds[i]) == msg.sender,
                "Cannot claim a bone using puppers you do not own"
            );
            // Set the isClaimed mapping to true for each _pupperTokenIds
            isClaimed[_pupperTokenIds[i]] = true;
        }

        _safeMint(msg.sender, _pupperTokenIds.length / 4);
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setIsActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

        return string(abi.encodePacked(baseUri));
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}