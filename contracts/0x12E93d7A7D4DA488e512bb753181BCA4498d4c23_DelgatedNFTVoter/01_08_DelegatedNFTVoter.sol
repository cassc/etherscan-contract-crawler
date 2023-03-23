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
    address account,
    address hedgeyNFT
  ) public view returns (uint256) {
    address delegatedFrom = accountsDelegated[account][token];
    address delegatedTo = IGovToken(token).delegates(account);
    address voter;
    if (account == delegatedTo) {
      voter = account;
    } else if (delegatedTo == address(0) && delegatedFrom == address(0)) {
      voter = account;
    } else if (delegatedTo == address(0) && delegatedFrom != address(0)) {
      voter = delegatedFrom;
    } else {
      return 0;
    }
    return NFTHelper.getLockedTokenBalance(hedgeyNFT, voter, token);
  }
}