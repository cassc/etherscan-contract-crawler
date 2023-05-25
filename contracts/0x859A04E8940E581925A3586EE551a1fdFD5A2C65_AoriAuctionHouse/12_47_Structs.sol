// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;
import "../OpenZeppelin/ERC20.sol";

library Structs {
    struct OpenPositionRequest {
        address account;
        uint256 collateral;
        address orderbook;
        bool isCall;
        uint256 amountOfUnderlying;
        uint256 seatId;
        uint256 endingTime;
    }
    
    struct Vars {
        uint256 optionsMinted;
        uint256 collateralVal;
        uint256 portfolioVal;
        uint256 collateralToLiquidator;
        uint256 profit;
        uint256 profitInUnderlying;
        bool isLiquidatable;
    }
    
    struct settleVars {
        uint256 tokenBalBefore;
        uint256 tokenDiff;
        uint256 optionsSold;
    }
}