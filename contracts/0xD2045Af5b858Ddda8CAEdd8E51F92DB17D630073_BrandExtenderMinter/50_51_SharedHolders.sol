// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract SharedHolders {

    address[] sharedTokenHolders;

    event SharedTokenHoldersUpdated(address[] newAddresses);

    function _authorizeSetSharedHolder(address[] calldata newAddresses) internal virtual;

    // SharedTokenHolder - some STL address, which holds popular NFTs, 
    // contract allowed to mint derived NFTs for NFTs, owned by this token
    function setSharedTokenHolders(address[] calldata newAddresses) external {
        _authorizeSetSharedHolder(newAddresses);

        emit SharedTokenHoldersUpdated(newAddresses);
        sharedTokenHolders = newAddresses;
    }

    function _isSharedHolderTokenOwner(address _contract, uint256 tokenId) internal view returns (bool) {
        ERC721 t = ERC721(_contract);
        address nftOwner = t.ownerOf(tokenId);
        uint length = sharedTokenHolders.length;
        for (uint i=0; i<length; i++){
            if (sharedTokenHolders[i] == nftOwner){
                return true;
            }
        }
        return false;
    }

    function hasSharedTokenHolders() internal view returns (bool){
        return sharedTokenHolders.length > 0;
    }

}