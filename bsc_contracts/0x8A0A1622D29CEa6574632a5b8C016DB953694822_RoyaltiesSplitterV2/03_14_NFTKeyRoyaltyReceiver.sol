// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/INFTKEYMarketplaceRoyalty.sol";
import "./ViewablePaymentSplitter.sol";

contract NFTKeyRoyaltyReceiver is Ownable {

    /**
     * @dev Set Royalty settings for NFTKey marketplace (only recipient can change so we need this here)
     */
    function setRoyalty(
        address nftkeyMarketplaceAddress,
        address erc721Address,
        address recipient,
        uint256 feeFraction
    ) external onlyOwner {
        INFTKEYMarketplaceRoyalty(nftkeyMarketplaceAddress).setRoyalty(erc721Address, recipient, feeFraction);
    }
}