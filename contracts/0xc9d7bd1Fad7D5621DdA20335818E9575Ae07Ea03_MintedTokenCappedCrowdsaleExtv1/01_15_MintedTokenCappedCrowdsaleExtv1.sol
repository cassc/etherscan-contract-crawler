// SPDX-License-Identifier: MIT
/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity 0.7.6;

import "./MintedTokenCappedCrowdsaleExt.sol";


/**
 * ICO crowdsale contract that is capped by amout of tokens.
 *
 * - Tokens are dynamically created during the crowdsale
 *
 *
 */
contract MintedTokenCappedCrowdsaleExtv1 is MintedTokenCappedCrowdsaleExt {

    address[] public investedAmountOfAddresses;
    MintedTokenCappedCrowdsaleExtv1 public mintedTokenCappedCrowdsaleExt;

    constructor(
        string memory _name,
        address _token,
        PricingStrategy _pricingStrategy,
        address _multisigWallet,
        uint _start, uint _end,
        uint _minimumFundingGoal,
        uint _maximumSellableTokens,
        bool _isUpdatable,
        bool _isWhiteListed,
        address _tokenVestingAddress,
        MintedTokenCappedCrowdsaleExtv1 _oldMintedTokenCappedCrowdsaleExtAddress
    )  MintedTokenCappedCrowdsaleExt(_name, _token, _pricingStrategy, _multisigWallet, _start, _end,
    _minimumFundingGoal, _maximumSellableTokens, _isUpdatable, _isWhiteListed, _tokenVestingAddress) {
        
        mintedTokenCappedCrowdsaleExt = _oldMintedTokenCappedCrowdsaleExtAddress;
        tokensSold = mintedTokenCappedCrowdsaleExt.tokensSold();
        //weiRaised = mintedTokenCappedCrowdsaleExt.weiRaised();
        investorCount = mintedTokenCappedCrowdsaleExt.investorCount();        

        //
        //for (uint i = 0; i < mintedTokenCappedCrowdsaleExt.whitelistedParticipantsLength(); i++) {
        //  address whitelistAddress = mintedTokenCappedCrowdsaleExt.whitelistedParticipants(i);
		//
        //  whitelistedParticipants.push(whitelistAddress);
		//
        //  uint256 tokenAmount = mintedTokenCappedCrowdsaleExt.tokenAmountOf(whitelistAddress);
        //  if (tokenAmount != 0){               
        //    tokenAmountOf[whitelistAddress] = tokenAmount;               
        //  }
		//
        //  uint256 investedAmount = mintedTokenCappedCrowdsaleExt.investedAmountOf(whitelistAddress);
        //   if (investedAmount != 0){
        //       investedAmountOf[whitelistAddress] = investedAmount;               
        //   }
		//
        //   setEarlyParticipantWhitelist(whitelistAddress, true, 1000000000000000000, 1000000000000000000000);
        //}
		//
    }
    
}