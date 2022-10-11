//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Helper} from "./helpers.sol";

import {InstaFlashloanAggregatorInterface} from "./interfaces.sol";

contract FlashResolver is Helper {
    function getRoutesInfo()
        public
        view
        returns (uint16[] memory routes_, uint256[] memory fees_)
    {
        routes_ = flashloanAggregator.getRoutes();
        fees_ = new uint256[](routes_.length);
        for (uint256 i = 0; i < routes_.length; i++) {
            fees_[i] = flashloanAggregator.calculateFeeBPS(routes_[i], randomAddr_);
        }
    }

    function getBestRoutes(address[] memory _tokens, uint256[] memory _amounts)
        public
        view
        returns (uint16[] memory, uint256)
    {
        require(_tokens.length == _amounts.length, "array-lengths-not-same");

        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);

        uint16[] memory bRoutes_;
        uint256 feeBPS_;
        uint16[] memory routes_ = flashloanAggregator.getRoutes();
        uint16[] memory routesWithAvailability_ = getRoutesWithAvailability(
            routes_,
            _tokens,
            _amounts
        );
        uint16 j = 0;
        bRoutes_ = new uint16[](routes_.length);
        feeBPS_ = type(uint256).max;
        for (uint256 i = 0; i < routesWithAvailability_.length; i++) {
            if (routesWithAvailability_[i] != 0) {
                uint256 routeFeeBPS_ = flashloanAggregator.calculateFeeBPS(
                    routesWithAvailability_[i],
                    randomAddr_
                );
                if (feeBPS_ > routeFeeBPS_) {
                    feeBPS_ = routeFeeBPS_;
                    bRoutes_[0] = routesWithAvailability_[i];
                    j = 1;
                } else if (feeBPS_ == routeFeeBPS_) {
                    bRoutes_[j] = routesWithAvailability_[i];
                    j++;
                }
            }
        }
        uint16[] memory bestRoutes_ = new uint16[](j);
        for (uint256 i = 0; i < j; i++) {
            bestRoutes_[i] = bRoutes_[i];
        }
        return (bestRoutes_, feeBPS_);
    }

    function getData(address[] memory _tokens, uint256[] memory _amounts)
        public
        view
        returns (
            uint16[] memory routes_,
            uint256[] memory fees_,
            uint16[] memory bestRoutes_,
            uint256 bestFee_
        )
    {
        (routes_, fees_) = getRoutesInfo();
        (bestRoutes_, bestFee_) = getBestRoutes(_tokens, _amounts);
        return (routes_, fees_, bestRoutes_, bestFee_);
    }
}

contract InstaFlashResolver is FlashResolver {
    receive() external payable {}
}