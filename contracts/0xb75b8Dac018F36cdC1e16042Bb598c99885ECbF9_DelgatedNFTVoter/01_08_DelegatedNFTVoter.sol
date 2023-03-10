// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import './libraries/NFTHelper.sol';
import './interfaces/IGovToken.sol';

contract DelgatedNFTVoter {
  /// this contract is a view only that will let ppl vote on snapshot with delegated tokens from an NFT

  // maps from the delegate to the token to the account
  mapping(address => mapping(address => address)) public accountsDelegated;

  function delegateLockedTokens(address account, address token) external {
    address delegate = IGovToken(token).delegates(account);
    require(delegate != address(0));
    accountsDelegated[delegate][token] = account;
  }

  function getDelegatedVotesFromNFT(
    address token,
    address delegate,
    address hedgeyNFT
  ) public view returns (uint256 lockedBalance) {
    // get the underlying account that has been assigned from the delegate
    address account = accountsDelegated[delegate][token];
    if (account == address(0)) {
      lockedBalance = NFTHelper.getLockedTokenBalance(hedgeyNFT, delegate, token);
    } else {
      lockedBalance = NFTHelper.getLockedTokenBalance(hedgeyNFT, account, token);
    }
  }
}