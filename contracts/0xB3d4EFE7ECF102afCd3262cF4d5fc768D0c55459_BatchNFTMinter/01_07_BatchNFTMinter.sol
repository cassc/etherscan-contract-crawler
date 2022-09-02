// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;


import '../libraries/TransferHelper.sol';
import '../interfaces/INFT.sol';

/// @notice basic smart contract to allow minting of Hedgeys NFTs in batches
contract BatchNFTMinter {
  function batchMint(
    address nftContract,
    address[] memory holders,
    address token,
    uint256[] memory amounts,
    uint256[] memory unlockDates
  ) public {
    require(holders.length == amounts.length && amounts.length == unlockDates.length, 'array size wrong');
    require(token != address(0));
    uint256 totalAmount;
    for (uint256 i; i < amounts.length; i++) {
      require(amounts[i] > 0, 'cant mint with 0');
      require(unlockDates[i] > block.timestamp, 'must be in the future');
      totalAmount += amounts[i];
    }
    /// @dev pull the tokens into this contract first sufficient to mint everything
    TransferHelper.transferTokens(token, msg.sender, address(this), totalAmount);
    /// @dev approve NFT contract to pull our tokens
    SafeERC20.safeIncreaseAllowance(IERC20(token), nftContract, totalAmount);
    for (uint256 i; i < amounts.length; i++) {
      /// @dev mint each NFT to each holder, this will pull the funds from this address to the NFT contract
      INFT(nftContract).createNFT(holders[i], amounts[i], token, unlockDates[i]);
    }
  }
}