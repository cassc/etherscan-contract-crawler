// SPDX-License-Identifier: MIT
/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity 0.7.6;

import "./CrowdsaleExt.sol";
import "./MintableTokenExt.sol";
import "./SafeMathLibExt.sol";


/**
 * ICO crowdsale contract that is capped by amout of tokens.
 *
 * - Tokens are dynamically created during the crowdsale
 *
 *
 */
contract MintedTokenCappedCrowdsaleExt is CrowdsaleExt {
    using SafeMathLibExt for uint;
    /* Maximum amount of tokens this crowdsale can sell. */
    uint public maximumSellableTokens;

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
        address _tokenVestingAddress
    )  CrowdsaleExt(_name, _token, _pricingStrategy, _multisigWallet, _start, _end,
    _minimumFundingGoal, _isUpdatable, _isWhiteListed, _tokenVestingAddress) {
        maximumSellableTokens = _maximumSellableTokens;
    }

    // Crowdsale maximumSellableTokens has been changed
    event MaximumSellableTokensChanged(uint newMaximumSellableTokens);

    /**
    * Called from invest() to confirm if the curret investment does not break our cap rule.
    */
    function isBreakingCap(uint tokensSoldTotal) public view override returns (bool limitBroken) {
        return tokensSoldTotal > maximumSellableTokens;
    }

    function isBreakingInvestorCap(address addr, uint weiAmount) public view override returns (bool limitBroken) {
        assert(isWhiteListed);
        uint maxCap = earlyParticipantWhitelist[addr].maxCap;
        return (investedAmountOf[addr].plus(weiAmount)) > maxCap;
    }

    function isCrowdsaleFull() public view override returns (bool) {
        return tokensSold >= maximumSellableTokens;
    }

    function setMaximumSellableTokens(uint tokens) public onlyOwner {
        assert(!finalized);
        assert(isUpdatable);
        assert(block.timestamp <= startsAt);

        CrowdsaleExt lastTierCntrct = CrowdsaleExt(payable(getLastTier()));
        assert(!lastTierCntrct.finalized());

        maximumSellableTokens = tokens;
        emit MaximumSellableTokensChanged(maximumSellableTokens);
    }

    function updateRate(uint oneTokenInCents) public onlyOwner {
        assert(!finalized);
        assert(isUpdatable);
        assert(block.timestamp <= startsAt);

        CrowdsaleExt lastTierCntrct = CrowdsaleExt(payable(getLastTier()));
        assert(!lastTierCntrct.finalized());

        pricingStrategy.updateRate(oneTokenInCents);
    }

    /**
    * Dynamically create tokens and assign them to the investor.
    */
    function assignTokens(address receiver, uint tokenAmount) internal override {
        MintableTokenExt mintableToken = MintableTokenExt(address(token));
        mintableToken.mint(receiver, tokenAmount);
    }    
}