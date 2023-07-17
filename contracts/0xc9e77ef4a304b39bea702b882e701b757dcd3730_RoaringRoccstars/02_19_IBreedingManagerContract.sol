// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBreedingManagerContract {

    function breedOwnLeaders(address ownerAddress, uint256 maleTokenId, uint256 femaleTokenId, bool hasSignature, bool instantCooldown, bytes memory signature) external;

    function breedUsingMarketplace(address ownerAddress, uint256 maleTokenId, uint256 femaleTokenId, bool hasSignature, bool instantCooldown, address renter, bool acceptorIsMaleOwner, uint256 rentalFee, uint256 expiry, bytes memory cooldownSignature, bytes memory listingSignature) external;
}