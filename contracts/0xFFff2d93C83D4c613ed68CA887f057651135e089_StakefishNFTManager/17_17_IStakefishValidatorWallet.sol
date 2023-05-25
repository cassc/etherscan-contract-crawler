// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title The interface for StakefishValidatorWallet
/// @notice Factory created contract representing the validator withdrawal address
interface IStakefishValidatorWallet {

    /// @notice receives ether from withdrawals
    receive() external payable;

    /// @notice current nft manager
    function getNFTManager() external returns (address);

    /// @notice allows owner to upgrade their validator contract to gain new features
    function upgradeByNFTOwner(address implementation) external;

    /// @notice migrate orchestrates 1) burn nft 2) mint nft 3) set nft manager
    /// @param newNftManager the new NFT Manager
    function migrate(address newNftManager) external;
}