// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <=0.8.7;
import "prb-math/contracts/PRBMathUD60x18.sol";
import "hardhat/console.sol";

// transaction limit on price collapse
library SellLimit {
    using PRBMathUD60x18 for uint256;

    struct SellLimitData {
        uint256 MaxFallPercent; // the maximum percentage by which can collapse the cours 1e18=1%
        uint256 DefaultMaxFallPercent; // the default value for the maximum collapse per transaction
    }

    // initializing the constrains for the single transaction  
    function Initialize(SellLimitData storage data, uint256 maxFreeFallPercent)
        public
    {
        data.MaxFallPercent = maxFreeFallPercent;
        data.DefaultMaxFallPercent = maxFreeFallPercent;
    }

    // reduces the limit by prohibiting large transactions   
    // doesn't reduce less than 1
    function DecrementLimits(SellLimitData storage data) public returns (bool) {
        uint256 last = data.MaxFallPercent;
        // reducing the limit
        uint256 newMaxFallPercent = PRBMathUD60x18.div(
            data.MaxFallPercent,
            2e18
        );
        //limitation
        if (newMaxFallPercent < 1) return false;
        // setting a new limit
        data.MaxFallPercent = newMaxFallPercent;
        // the results
        return data.MaxFallPercent != last;
    }

   // increases the limit, allowing you to share transactions larger
   // it does not increase more than the default one
    function IncrementLimits(SellLimitData storage data) public returns (bool) {
        uint256 last = data.MaxFallPercent;
        // increasing the limit   
        uint256 newMaxFallPercent = PRBMathUD60x18.mul(
            data.MaxFallPercent,
            2e18
        );
        // if more than the default, then restriction
        if (newMaxFallPercent > data.DefaultMaxFallPercent)
            newMaxFallPercent = data.DefaultMaxFallPercent;
        // setting a new limit
        data.MaxFallPercent = newMaxFallPercent;
        // outputting the result
        return data.MaxFallPercent != last;
    }

    // checks the limiters of a single transaction
    // call only when transferring to the exchanges (selling token)
    // if more than the maximum percentage is burned, such a transaction is cancelled with an error "too large sell transaction"
    function CheckLimit(
        SellLimitData storage data,
        uint256 routerLastEth, // how much was on the router before the ETH transaction
        uint256 routerLastToken, // how much on the router before the transaction
        uint256 ammount // how much are we trying to transfer 
    ) public view {
        //console.log("data.MaxFallPercent", data.MaxFallPercent);
        //console.log("data.MaxBurnPercentage", data.MaxBurnPercentage);
        //console.log("routerLastEth", routerLastEth);
        //console.log("routerLastToken", routerLastToken);
        //console.log("ammount", ammount);
        // calculation of the old price 
        uint256 lastPrice = PRBMathUD60x18.div(routerLastEth, routerLastToken);
        if (lastPrice == 0) return; // if the price was 0, we do nothing
        //console.log("lastPrice", lastPrice);
        // calculation of the new amount of tokens on the router
        uint256 routerNewToken = routerLastToken + ammount;
        //console.log("routerNewToken", routerNewToken);
        // calculation of the new ETH on the exchanger
        //uint256 routerNewEth = routerLastEth -
        //    PRBMathUD60x18.mul(lastPrice, ammount);
        uint256 k = PRBMathUD60x18.mul(routerLastEth, routerLastToken);
        //console.log("k", k);
        uint256 routerNewEth = PRBMathUD60x18.div(k, routerNewToken);
        //console.log("routerNewEth", routerNewEth);
        // calculation of the new price (hypothetical, if you transfer the entire amount)
        //uint256 newPrice = PRBMathUD60x18.div(routerNewEth, routerNewToken);
        //console.log("newPrice", newPrice);
        // get how much ETH is transferred from the pool
        if (routerLastEth <= routerNewEth) return;
        uint256 ethReceived = routerLastEth - routerNewEth;
        //console.log("ethReceived", ethReceived);
        // if the price goes up, there are no limitations
        //if (newPrice > lastPrice) return;
        // the price drop calculation
        uint256 priceImpact = PRBMathUD60x18.div(ethReceived, routerLastEth);
        //console.log("impact", priceImpact);
        //uint256 priceFall = 1e18 - PRBMathUD60x18.div(newPrice, lastPrice);
        //console.log("priceFall", priceFall);
        require(
            priceImpact <= data.MaxFallPercent,
            "The transaction will drop the price more than allowed. Try splitting your transaction into parts, or try to swap a lesser amount."
        );
    }
}