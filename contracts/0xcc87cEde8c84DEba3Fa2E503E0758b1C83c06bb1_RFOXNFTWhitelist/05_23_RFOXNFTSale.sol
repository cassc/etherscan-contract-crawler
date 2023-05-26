// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./base/BaseRFOXNFT.sol";

contract RFOXNFTSale is BaseRFOXNFT {
  /**
   * @dev Public sale.
   *
   * @param tokensNumber How many NFTs for buying this round
   */
  function buyNFTsPublic(uint256 tokensNumber)
      public
      payable
      whenNotPaused
      callerIsUser
      maxPurchasePerTx(tokensNumber)
      authorizePublicSale
  {
      _buyNFTs(tokensNumber);
  }
}