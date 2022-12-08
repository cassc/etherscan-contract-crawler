// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Whitelistable.sol";
import "../libraries/structs.sol";

abstract contract Exchangeable is Whitelistable {
    PriceStrategy pricestrategy;

    // Tier pricing rules
    mapping(uint256 => PriceRule) tierRules;
    uint256[] private tierTracker;

    // Determines what methods of payment are acceptable
    address[] public acceptedTokens;
    mapping(address => bool) public isPaymentToken;

    // Simplified price - default price per unit
    mapping(address => uint256) public simplifiedTokenPrices;

    function getAcceptedTokens() external view returns (address[] memory) {
        return acceptedTokens;
    }

    function getPricingStrategy() external view returns (uint256) {
        return uint256(pricestrategy);
    }

    function getPricingRules() external view returns (PriceRule[] memory) {
        PriceRule[] memory rules = new PriceRule[](tierTracker.length);

        for (uint256 x = 0; x < tierTracker.length; x++) {
            rules[x] = tierRules[tierTracker[x]];
        }

        return rules;
    }

    function updatePricingStrategy(PriceStrategy _strategy) external onlyAdmin {
        pricestrategy = _strategy;
    }

    // Related to strategy
    function _addPricingRule(
        uint256 _id,
        string calldata _name,
        uint256 _minMint,
        address[] calldata _tokens,
        uint256[] calldata _prices
    ) internal {
        tierRules[_id] = PriceRule(_id, _name, _minMint, _tokens, _prices);
        tierTracker.push(_id);
    }

    function resetSimplifiedPricing(
        address[] calldata _acceptedTokens,
        uint256[] calldata _acceptedPrices
    ) external onlyAdmin {
        if (_acceptedTokens.length != _acceptedPrices.length)
            revert InvalidAction("Tokens and prices arrays not matching");

        // First loop resets values in mapping
        for (uint256 i = 0; i < acceptedTokens.length; i++) {
            isPaymentToken[acceptedTokens[i]] = false;
            delete simplifiedTokenPrices[acceptedTokens[i]];
        }

        acceptedTokens = _acceptedTokens;

        // Second loop updates to new acceptedTokens
        for (uint256 i = 0; i < _acceptedTokens.length; i++) {
            isPaymentToken[acceptedTokens[i]] = true;
            simplifiedTokenPrices[acceptedTokens[i]] = _acceptedPrices[i];
        }
    }

    function resetPricingRules(PriceRule[] calldata _pricingRules)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < tierTracker.length; i++) {
            delete tierRules[i];
        }

        delete tierTracker;

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
}