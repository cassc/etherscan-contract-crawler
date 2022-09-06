// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/INFT.sol';

/// @notice Library to lock tokens and mint an NFT
/// @notice this NFTHelper is used by the HedgeyOTC contract to lock tokens and instruct the Hedgeys contract to mint an NFT
library NFTHelper {
  /// @dev internal function that handles the locking of the tokens in the NFT Futures contract
  /// @param futureContract is the address of the NFT contract that will mint the NFT and lock tokens
  /// @param _holder address here becomes the owner of the newly minted NFT
  /// @param _token address here is the ERC20 contract address of the tokens being locked by the NFT contract
  /// @param _amount is the amount of tokens that will be locked
  /// @param _unlockDate provides the unlock date which is the expiration date for the Future generated
  function lockTokens(
    address futureContract,
    address _holder,
    address _token,
    uint256 _amount,
    uint256 _unlockDate
  ) internal {
    /// @dev ensure that the _unlockDate is in the future compared to the current block timestamp
    require(_unlockDate > block.timestamp, 'NHL01');
    /// @dev similar to checking the balances for the OTC contract when creating a new deal - we check the current and post balance in the NFT contract
    /// @dev to ensure that 100% of the amount of tokens to be locked are in fact locked in the contract address
    uint256 currentBalance = IERC20(_token).balanceOf(futureContract);
    /// @dev increase allowance so that the NFT contract can pull the total funds
    /// @dev this is a safer way to ensure that the entire amount is delivered to the NFT contract
    SafeERC20.safeIncreaseAllowance(IERC20(_token), futureContract, _amount);
    /// @dev this function points to the NFT Futures contract and calls its function to mint an NFT and generate the locked tokens future struct
    INFT(futureContract).createNFT(_holder, _amount, _token, _unlockDate);
    /// @dev check to make sure that _holder is received by the futures contract equals the total amount we have delivered
    /// @dev this prevents functionality with deflationary or tax tokens that have not whitelisted these address
    uint256 postBalance = IERC20(_token).balanceOf(futureContract);
    require(postBalance - currentBalance == _amount, 'NHL02');
  }

  /// @notice function to get the balances for a given wallet
  function getLockedTokenDetails(address futureContract, address holder)
    public
    view
    returns (
      uint256[] memory amounts,
      address[] memory tokens,
      uint256[] memory unlockDates
    )
  {
    uint256 holdersBalance = INFT(futureContract).balanceOf(holder);
    /// @dev for loop going through the holders balance to get each of their token IDs
    for (uint256 i = 0; i < holdersBalance; i++) {
      /// @dev gets the tokenId
      uint256 tokenId = INFT(futureContract).tokenOfOwnerByIndex(holder, i);
      /// @dev now we can use that tokenId to get their time lock details
      (uint256 amount, address token, uint256 unlockDate) = INFT(futureContract).futures(tokenId);
      /// @dev add these to the array
      amounts[i] = amount;
      tokens[i] = token;
      unlockDates[i] = unlockDate;
    }
  }

  function getLockedTokenBalance(address futureContract, address holder, address lockedToken) public view returns (uint256 lockedAmount) {
     uint256 holdersBalance = INFT(futureContract).balanceOf(holder);
    /// @dev for loop going through the holders balance to get each of their token IDs
    for (uint256 i = 0; i < holdersBalance; i++) {
      /// @dev gets the tokenId
      uint256 tokenId = INFT(futureContract).tokenOfOwnerByIndex(holder, i);
      /// @dev now we can use that tokenId to get their time lock details
      (uint256 amount, address token,) = INFT(futureContract).futures(tokenId);
      /// @dev check if the token matches the lockedToken criteria
      if (token == lockedToken) {
        /// @dev if it does - add it to the sum total
        lockedAmount += amount;
      }
    }
  }
}