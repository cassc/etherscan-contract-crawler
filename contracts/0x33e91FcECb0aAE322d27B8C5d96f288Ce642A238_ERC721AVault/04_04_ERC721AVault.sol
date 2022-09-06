// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

abstract contract NFT {
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address owner);
    function totalSupply()
        public
        view
        virtual
        returns (uint256);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;
}


contract ERC721AVault is Ownable, IERC721Receiver {

    struct Token {
        bool claimed;
    }

    bool public claimIsActive = true;
    mapping(uint256 => Token) public tokens;
    uint256 public totalClaimed;
    NFT genesis;
    NFT companion;

    constructor(address _genesisAddress, address _companionAddress) {
        genesis = NFT(_genesisAddress);
        companion = NFT(_companionAddress);
    }

    function setGenesisContract(address _address) public onlyOwner {
        genesis = NFT(_address);
    }

    function setCompanionContract(address _address) public onlyOwner {
        companion = NFT(_address);
    }

    function getClaimable(address _address) public view returns (uint256[] memory) {
        uint256 _currentSupply = genesis.totalSupply();
        uint256 claimable;
        for (uint256 i = 0; i < _currentSupply; i++) {
            if (genesis.ownerOf(i) == _address && !tokens[i].claimed) {
                claimable++;
            }
        }
        uint256 index;
        uint256[] memory tokenIds = new uint256[](claimable);
        for (uint256 i = 0; i < _currentSupply; i++) {
            if (genesis.ownerOf(i) == _address && !tokens[i].claimed) {
                tokenIds[index++] = i;
            }
        }
        return tokenIds;
    }

    function setClaimState(bool _claimIsActive) public onlyOwner {
        claimIsActive = _claimIsActive;
    }

    function claim(uint256[] memory _tokenIds) public {
        require(claimIsActive, "Claim inactive");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(genesis.ownerOf(_tokenIds[i]) == msg.sender, "Not owner");
            require(!tokens[_tokenIds[i]].claimed, "Already claimed");
            tokens[_tokenIds[i]].claimed = true;
            totalClaimed++;
            companion.safeTransferFrom(
                address(this),
                msg.sender,
                _tokenIds[i]
            );
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}