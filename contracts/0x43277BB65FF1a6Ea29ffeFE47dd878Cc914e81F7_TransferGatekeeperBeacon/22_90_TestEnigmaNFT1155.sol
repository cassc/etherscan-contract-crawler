// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../ERC1155/EnigmaNFT1155.sol";

/// @title TestEnigmaNFT1155
///
/// @dev This contract extends from BaseEnigmaNFT1155 for upgradeablity testing

contract TestEnigmaNFT1155 is EnigmaNFT1155 {
    event CollectibleCreated(uint256 tokenId);

    /**
     * @notice public function to mint a new token.
     * @param uri_ string memory URI of the token to be minted.
     * @param supply_ tokens amount to be minted
     * @param fee_ uint256 royalty of the token to be minted.
     */
    function mint(
        string memory uri_,
        uint256 supply_,
        uint256 fee_
    ) external {
        uint256 tokenId = _mintNew(msg.sender, _increaseNextId(), supply_, uri_, fee_);
        creators[tokenId] = msg.sender;
        emit CollectibleCreated(tokenId);
    }
}