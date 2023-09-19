// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IRestrictedSFTClaimCountV0 {
    /// @dev Emitted when the wallet claim count for a given tokenId and address is updated.
    event WalletClaimCountUpdated(uint256 tokenId, address indexed wallet, uint256 count);
    /// @dev Emitted when the max wallet claim count for a given tokenId is updated.
    event MaxWalletClaimCountUpdated(uint256 tokenId, uint256 count);

    /// @dev Lets a contract admin set a claim count for a wallet.
    function setWalletClaimCount(uint256 _tokenId, address _claimer, uint256 _count) external;

    /// @dev Lets a contract admin set a maximum number of NFTs of a tokenId that can be claimed by any wallet.
    function setMaxWalletClaimCount(uint256 _tokenId, uint256 _count) external;
}