// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseEnigmaNFT721.sol";

/// @title EnigmaUserToken721
///
/// @dev This contract extends from BaseEnigmaNFT721

contract EnigmaUserToken721 is BaseEnigmaNFT721 {
    /// oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line
    constructor() initializer {}

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     */
    function createCollectible(string memory tokenURI_, uint256 fee_) external onlyOwner returns (uint256) {
        return createCollectibleWithCustomRightsHolder(tokenURI_, fee_, owner(), msg.sender);
    }

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     * @param rightsHolder_ account that will receive royalties
     * @param to_ address of the first receiver
     */
    function createCollectibleWithCustomRightsHolder(
        string memory tokenURI_,
        uint256 fee_,
        address rightsHolder_,
        address to_
    ) public onlyOwner returns (uint256) {
        uint256 newItemId = tokenCounter;
        tokenCounter = tokenCounter + 1;
        _safeMint(to_, newItemId, fee_, rightsHolder_);
        _setTokenURI(newItemId, tokenURI_);
        return newItemId;
    }
}