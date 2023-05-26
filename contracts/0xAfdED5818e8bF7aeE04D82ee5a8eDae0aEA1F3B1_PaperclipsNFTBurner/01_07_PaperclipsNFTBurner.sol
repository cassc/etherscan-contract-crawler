// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract PaperclipsNFTBurner is Ownable {
    using Address for address;
    IERC20 public clipsToken;
    uint256 public burntCount = 0;

    constructor(IERC20 _clipsToken) {
        clipsToken = _clipsToken;
    }

    function burnNFTs(address[] calldata nftAddresses, uint256[] calldata _tokenIds) external payable {
        require(msg.value == 0.01 ether * _tokenIds.length, "Must send 0.01 ETH per NFT");
        require(nftAddresses.length == _tokenIds.length, "NFT Addresses and token IDs count must be the same");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            address nftAddress = nftAddresses[i];
            uint256 _tokenId = _tokenIds[i];
            
            IERC721 musicNFT = IERC721(nftAddress);
            require(musicNFT.ownerOf(_tokenId) == msg.sender, "Must own the NFT");

            (bool successMetadataModule, bytes memory dataMetadataModule) = nftAddress.call(abi.encodeWithSignature("metadataModule()"));
            (bool successSoundRecoveryAddress, bytes memory dataSoundRecoveryAddress) = nftAddress.call(abi.encodeWithSignature("soundRecoveryAddress()"));

            require(
                (successMetadataModule && dataMetadataModule.length > 0) || 
                (successSoundRecoveryAddress && dataSoundRecoveryAddress.length > 0), 
                "NFT contract does not have metadataModule or soundRecoveryAddress function"
            );

            uint256 clipsAmount;
            if (burntCount < 100) {
                clipsAmount = 1000000000 * 10 ** 18;
            } else if (burntCount < 1100) {
                clipsAmount = 100000000 * 10 ** 18;
            } else if (burntCount < 11100) {
                clipsAmount = 10000000 * 10 ** 18;
            } else if (burntCount < 111100) {
                clipsAmount = 1000000 * 10 ** 18;
            } else {
                clipsAmount = 100000 * 10 ** 18;
            }

            // Transfer the NFT to the 0x0 address, burning it
            musicNFT.transferFrom(msg.sender, address(0), _tokenId);

            // Check that there are enough CLIPS tokens to transfer
            require(clipsToken.balanceOf(address(this)) >= clipsAmount, "Not enough tokens left");

            // Transfer CLIPS tokens
            require(clipsToken.transfer(msg.sender, clipsAmount), "Transfer failed");

            burntCount++;
        }
    }
}