// contracts/InterleaveSuperNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
  _____       _            _                     
  \_   \_ __ | |_ ___ _ __| | ___  __ ___   _____ 
   / /\/ '_ \| __/ _ \ '__| |/ _ \/ _` \ \ / / _ \
/\/ /_ | | | | ||  __/ |  | |  __/ (_| |\ V /  __/
\____/ |_| |_|\__\___|_|  |_|\___|\__,_| \_/ \___|

*/

/// @title The SuperNFT contract for Interleave
/// @notice Contract represents a ERC1155 which is only mintable for a certain period of time under specific conditions
contract InterleaveSuperNFT is ERC1155, ERC1155Burnable, Ownable {
    string public baseURI;

    uint256 public MINTING_PERIOD_END;

    uint256 public immutable REQUIRED_BURN_AMOUNT = 6;

    ERC721Burnable public interleaveNFT;

    mapping(uint256 => bool) public validSuperNFTs;

    event SetBaseURI(string indexed _baseURI);

    constructor(
        address _interleaveNFT,
        uint256 _mintingPeriodLengthInSeconds,
        string memory _baseURI
    ) ERC1155(_baseURI) {
        baseURI = _baseURI;
        MINTING_PERIOD_END = block.timestamp + _mintingPeriodLengthInSeconds;
        interleaveNFT = ERC721Burnable(_interleaveNFT);
        validSuperNFTs[0] = true;
        emit SetBaseURI(baseURI);
    }

    function mintSuperNFT(uint256[] memory _idsToBurn) public {
        require(block.timestamp < MINTING_PERIOD_END, "Minting period closed");
        require(_idsToBurn.length == REQUIRED_BURN_AMOUNT, "Minimum 6 NFTs required");
        for (uint256 i = 0; i < _idsToBurn.length; i++) {
            require(interleaveNFT.ownerOf(_idsToBurn[i]) == msg.sender, "User is not the owner of all token ids");
            interleaveNFT.burn(_idsToBurn[i]);
        }
        _mint(msg.sender, 0, 1, "");
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        require(validSuperNFTs[typeId], "URI requested for invalid super NFT type");
        return baseURI;
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }

    function setMintingPeriodEnd(uint256 _timeInSeconds) public onlyOwner {
        MINTING_PERIOD_END = block.timestamp + _timeInSeconds;
    }
}