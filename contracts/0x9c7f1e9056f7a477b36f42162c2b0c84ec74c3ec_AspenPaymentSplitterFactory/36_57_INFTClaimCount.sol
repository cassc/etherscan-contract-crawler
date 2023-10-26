// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IRestrictedNFTClaimCountV0 {
    /// @dev Emitted when the wallet claim count for an address is updated.
    event WalletClaimCountUpdated(address indexed wallet, uint256 count);
    /// @dev Emitted when the global max wallet claim count is updated.
    event MaxWalletClaimCountUpdated(uint256 count);

    /// @dev Lets a contract admin set a claim count for a wallet.
    function setWalletClaimCount(address _claimer, uint256 _count) external;

    /// @dev Lets a contract admin set a maximum number of NFTs that can be claimed by any wallet.
    function setMaxWalletClaimCount(uint256 _count) external;
}