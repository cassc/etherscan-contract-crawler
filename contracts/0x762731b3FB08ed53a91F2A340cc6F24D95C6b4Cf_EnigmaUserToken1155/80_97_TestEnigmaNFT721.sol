// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../ERC721/BaseEnigmaNFT721.sol";

/// @title TestEnigmaNFT721
///
/// @dev This contract extends from BaseEnigmaNFT721 for upgradeablity testing

contract TestEnigmaNFT721 is BaseEnigmaNFT721 {
    event CollectibleCreated(uint256 tokenId);

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     */
    function createCollectible(string memory tokenURI_, uint256 fee_) external returns (uint256) {
        uint256 newItemId = tokenCounter;
        tokenCounter = tokenCounter + 1;
        emit CollectibleCreated(newItemId);
        _safeMint(msg.sender, newItemId, fee_, msg.sender);
        _setTokenURI(newItemId, tokenURI_);
        return newItemId;
    }
}