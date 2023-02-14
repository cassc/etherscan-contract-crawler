// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Airdrop
contract Airdrop is Ownable, ERC1155URIStorage {
    constructor()
        ERC1155(
            "https://atlascorp.mypinata.cloud/ipfs/QmNd6c3i4dFRniFuVTTWBhPuDWN5FEvboc1FrbAxhwfoCz"
        )
    {}

    /// @param _wallets is the list of wallets being minted to
    /// @param _tokenId is the collection ID
    /// @param _amount is the amount of tokens being minted
    function mintToWallets(
        address[] memory _wallets,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            _mintSingleNFT(_wallets[i], _tokenId, _amount);
        }
    }

    function _mintSingleNFT(
        address _wallet,
        uint256 _tokenId,
        uint256 _amount
    ) private {
        _mint(_wallet, _tokenId, _amount, "");
    }

    /// @param _tokenId is the collection ID
    /// @param _tokenURI is the new metadata file
    function setURI(uint256 _tokenId, string memory _tokenURI)
        external
        onlyOwner
    {
        _setURI(_tokenId, _tokenURI);
    }
}