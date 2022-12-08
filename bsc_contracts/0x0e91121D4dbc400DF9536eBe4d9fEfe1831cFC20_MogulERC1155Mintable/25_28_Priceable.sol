// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Exchangeable.sol";

abstract contract Priceable is Exchangeable {
    bool initialConfigSet = false;

    function _getPrice(
        uint256 _tokenId,
        uint256 _mintAmount,
        address _tokenAddress // address(0) is Native currency
    ) internal view returns (uint256 price) {
        price = simplifiedTokenPrices[_tokenAddress];

        // If tier based strategy
        if (
            pricestrategy == PriceStrategy.TIERS &&
            tierRules[_tokenId].minMint > 0
        ) {
            for (uint256 x = 0; x < tierRules[_tokenId].tokens.length; x++) {
                if (
                    tierRules[_tokenId].tokens[x] == _tokenAddress &&
                    _mintAmount >= tierRules[_tokenId].minMint
                ) {
                    price = tierRules[_tokenId].prices[x];
                }
            }
        }
    }

    function setInitialPricingConfig(
        PriceStrategy _strategy,
        address[] calldata _acceptedTokens,
        uint256[] calldata _acceptedPrices,
        PriceRule[] calldata _pricingRules
    ) external {
        if (initialConfigSet) revert InvalidAction("Already initialized");
        if (_acceptedTokens.length != _acceptedPrices.length)
            revert InvalidAction("Tokens and prices arrays not matching");
        initialConfigSet = true;
        pricestrategy = _strategy;
        acceptedTokens = _acceptedTokens;

        for (uint256 i = 0; i < _acceptedTokens.length; i++) {
            isPaymentToken[acceptedTokens[i]] = true;
            simplifiedTokenPrices[acceptedTokens[i]] = _acceptedPrices[i];
        }

        for (uint256 j = 0; j < _pricingRules.length; j++) {
            _addPricingRule(
                _pricingRules[j].id,
                _pricingRules[j].name,
                _pricingRules[j].minMint,
                _pricingRules[j].tokens,
                _pricingRules[j].prices
            );
        }
    }

    function getPrice(
        uint256 _tokenId,
        uint256 _mintAmount,
        address _tokenAddress // address(0) is Native currency
    ) external view returns (uint256) {
        return _getPrice(_tokenId, _mintAmount, _tokenAddress);
    }
}