// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface INFTStaking {
    /// @notice let user lock NFT, access: ANY
    /// @param _nftId is the NFT id which locked
    function lockNFT(uint256 _nftId) external;

    /// @notice let user unlcok NFT if enabled, access: ANY
    /// @param _nftId is the NFT id which unlocked
    function unlockNFT(uint256 _nftId) external;

    /// @notice get user reduction multiplier for policy premium, access: PolicyBook
    /// @param _user is the user who locked NFT
    /// @return reduction multiplier of locked NFT by user
    function getUserReductionMultiplier(address _user) external view returns (uint256);

    /// @notice return enabledlockingNFTs state, access: ANY
    /// if true user can't unlock NFT and vice versa
    function enabledlockingNFTs() external view returns (bool);

    /// @notice To enable/disable locking of the NFTs
    /// @param _enabledlockingNFTs is a state for enable/disbale locking of the NFT
    function enableLockingNFTs(bool _enabledlockingNFTs) external;
}