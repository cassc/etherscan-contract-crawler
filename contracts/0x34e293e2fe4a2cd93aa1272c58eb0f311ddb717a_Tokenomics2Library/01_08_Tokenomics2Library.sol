// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.14;

import "../interfaces/IDarwinSwapLister.sol";
import "../interfaces/IDarwinSwapPair.sol";
import "../libraries/DarwinSwapLibrary.sol";

library Tokenomics2Library {

    bytes4 private constant _TRANSFER = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant _TRANSFERFROM = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    // TODO: Make sure this actually does correct and enough calculations
    // Taxes the sender with Tokenomics 1.0 on the sold token, both from the sold token and the bought token. Returns the taxed amount.
    function handleToks1Sell(
        address sellToken,
        address from,
        uint256 value,
        address buyToken,
        address factory
    ) public returns(uint sellTaxAmount) {
        IDarwinSwapLister.TokenInfo memory sellTokenInfo = IDarwinSwapLister(IDarwinSwapFactory(factory).lister()).tokenInfo(sellToken);
        IDarwinSwapLister.TokenInfo memory buyTokenInfo = IDarwinSwapLister(IDarwinSwapFactory(factory).lister()).tokenInfo(buyToken);

        if (sellTokenInfo.valid && buyTokenInfo.official) {
            // SELLTOKEN tokenomics1.0 sell tax value applied to itself
            uint sellTokenA1 = (value * sellTokenInfo.addedToks.tokenA1TaxOnSell) / 10000;

            if (sellTokenA1 > 0) {
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFERFROM, from, sellTokenInfo.feeReceiver, sellTokenA1));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_SELL_A1");
            }

            sellTaxAmount += sellTokenA1;
        }

        if (buyTokenInfo.valid && sellTokenInfo.official) {
            // If BUYTOKEN's liqInj is active, send the tokenomics1.0 buy tax value applied to SELLTOKEN to the pair's liqInj guard
            //? liqInj ONLY WORKS ON [2]PATH SWAPS
            address pair = IDarwinSwapFactory(factory).getPair(sellToken, buyToken);
            if (buyTokenInfo.addedToks.tokenB1BuyToLI > 0 && pair != address(0)) {
                uint refill = handleLIRefill(sellToken, buyToken, factory, value, buyTokenInfo.addedToks.tokenB1BuyToLI);
                address liqInj = IDarwinSwapPair(pair).liquidityInjector();
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFERFROM, from, liqInj, refill));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: ANTIDUMP_FAILED_BUY_B1");
            }

            // BUYTOKEN tokenomics1.0 buy tax value applied to SELLTOKEN
            uint buyTokenB1 = (value * buyTokenInfo.addedToks.tokenB1TaxOnBuy) / 10000;

            if (buyTokenB1 > 0) {
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFERFROM, from, buyTokenInfo.feeReceiver, buyTokenB1));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_BUY_B1");
            }

            sellTaxAmount += buyTokenB1;
        }
    }

    // TODO: Make sure this actually does correct and enough calculations
    // Taxes the receiver (well, actually sends LESS tokens to the receiver) with Tokenomics 1.0 on the bought token, both from the sold token and the bought token. Returns the taxed amount.
    function handleToks1Buy(
        address buyToken,
        uint value,
        address sellToken,
        address factory
    ) public returns(uint buyTaxAmount) {
        IDarwinSwapLister.TokenInfo memory buyTokenInfo = IDarwinSwapLister(IDarwinSwapFactory(factory).lister()).tokenInfo(buyToken);
        IDarwinSwapLister.TokenInfo memory sellTokenInfo = IDarwinSwapLister(IDarwinSwapFactory(factory).lister()).tokenInfo(sellToken);

        if (buyTokenInfo.valid && sellTokenInfo.official) {
            // BUYTOKEN tokenomics1.0 buy tax value applied to itself
            uint buyTokenA1 = (value * buyTokenInfo.addedToks.tokenA1TaxOnBuy) / 10000;

            if (buyTokenA1 > 0) {
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, buyTokenInfo.feeReceiver, buyTokenA1));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_BUY_A1");
            }

            buyTaxAmount += buyTokenA1;
        }

        if (sellTokenInfo.valid && buyTokenInfo.official) {
            // If SELLTOKEN's liqInj is active, send the tokenomics1.0 sell tax value applied to BUYTOKEN to the pair's liqInj guard
            //? liqInj ONLY WORKS ON [2]PATH SWAPS
            address pair = IDarwinSwapFactory(factory).getPair(sellToken, buyToken);
            if (sellTokenInfo.addedToks.tokenB1SellToLI > 0 && pair != address(0)) {
                uint refill = handleLIRefill(buyToken, sellToken, factory, value, sellTokenInfo.addedToks.tokenB1SellToLI);
                address liqInj = IDarwinSwapPair(pair).liquidityInjector();
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, liqInj, refill));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: ANTIDUMP_FAILED_SELL_B1");
            }

            // SELLTOKEN tokenomics1.0 sell tax value applied to BUYTOKEN
            uint sellTokenB1 = (value * sellTokenInfo.addedToks.tokenB1TaxOnSell) / 10000;

            if (sellTokenB1 > 0) {
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, sellTokenInfo.feeReceiver, sellTokenB1));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_SELL_B1");
            }

            buyTaxAmount += sellTokenB1;
        }
    }

    // TODO: Make sure this actually does correct and enough calculations
    // Taxes the LP with Tokenomics 2.0 on the sold token, both from the sold token and the bought token.
    function handleToks2Sell(
        address sellToken,
        uint value,
        address buyToken,
        address factory
    ) public {
        IDarwinSwapLister lister = IDarwinSwapLister(IDarwinSwapFactory(factory).lister());
        IDarwinSwapLister.TokenInfo memory sellTokenInfo = lister.tokenInfo(sellToken);
        IDarwinSwapLister.TokenInfo memory buyTokenInfo = lister.tokenInfo(buyToken);

        if (sellTokenInfo.valid && buyTokenInfo.official) {
            // Calculates eventual tokenomics1.0 refund and makes it
            if (sellTokenInfo.addedToks.refundOnSell > 0) {
                uint refundA1WithA2 = (value * sellTokenInfo.addedToks.refundOnSell) / 10000;

                // TODO: SHOULD AVOID USING TX.ORIGIN
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFER, tx.origin, refundA1WithA2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: REFUND_FAILED_SELL_A2");
            }

            // If SELLTOKEN's liqInj is active, send the tokenomics2.0 sell tax value applied to BUYTOKEN to the pair's liqInj guard
            //? liqInj ONLY WORKS ON [2]PATH SWAPS
            address pair = IDarwinSwapFactory(factory).getPair(sellToken, buyToken);
            if (sellTokenInfo.addedToks.tokenB2SellToLI > 0 && pair != address(0)) {
                uint refill = handleLIRefill(buyToken, sellToken, factory, value, sellTokenInfo.addedToks.tokenB2SellToLI);
                address liqInj = IDarwinSwapPair(pair).liquidityInjector();
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, liqInj, refill));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: ANTIDUMP_FAILED_SELL_B2");
            }

            // SELLTOKEN tokenomics2.0 sell tax value applied to itself
            uint sellTokenA2 = (value * sellTokenInfo.addedToks.tokenA2TaxOnSell) / 10000;

            if (sellTokenA2 > 0) {
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFER, sellTokenInfo.feeReceiver, sellTokenA2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_SELL_A2");
            }
        }

        if (buyTokenInfo.valid && sellTokenInfo.official) {
            // BUYTOKEN tokenomics2.0 buy tax value applied to SELLTOKEN
            uint buyTokenB2 = (value * buyTokenInfo.addedToks.tokenB2TaxOnBuy) / 10000;

            if (buyTokenB2 > 0) {
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFER, buyTokenInfo.feeReceiver, buyTokenB2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_BUY_B2");
            }
        }
    }

    // TODO: Make sure this actually does correct and enough calculations
    // Taxes the LP with Tokenomics 2.0 on the bought token, both from the bought token and the sold token.
    function handleToks2Buy(
        address buyToken,
        uint value,
        address sellToken,
        address to,
        address factory
    ) public {
        IDarwinSwapLister lister = IDarwinSwapLister(IDarwinSwapFactory(factory).lister());
        IDarwinSwapLister.TokenInfo memory buyTokenInfo = lister.tokenInfo(buyToken);
        IDarwinSwapLister.TokenInfo memory sellTokenInfo = lister.tokenInfo(sellToken);

        if (buyTokenInfo.valid && sellTokenInfo.official) {
            // Calculates eventual tokenomics1.0 refund
            if (buyTokenInfo.addedToks.refundOnBuy > 0) {
                uint refundA1WithA2 = (value * buyTokenInfo.addedToks.refundOnBuy) / 10000;

                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, to, refundA1WithA2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: REFUND_FAILED_BUY_A2");
            }

            // If BUYTOKEN's liqInj is active, send the tokenomics2.0 buy tax value applied to SELLTOKEN to the pair's liqInj guard
            //? liqInj ONLY WORKS ON [2]PATH SWAPS
            address pair = IDarwinSwapFactory(factory).getPair(sellToken, buyToken);
            if (buyTokenInfo.addedToks.tokenB2BuyToLI > 0 && pair != address(0)) {
                uint refill = handleLIRefill(sellToken, buyToken, factory, value, buyTokenInfo.addedToks.tokenB2BuyToLI);
                address liqInj = IDarwinSwapPair(pair).liquidityInjector();
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFER, liqInj, refill));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: ANTIDUMP_FAILED_BUY_B2");
            }

            // BUYTOKEN tokenomics2.0 buy tax value applied to itself
            uint buyTokenA2 = (value * buyTokenInfo.addedToks.tokenA2TaxOnBuy) / 10000;

            if (buyTokenA2 > 0) {
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, buyTokenInfo.feeReceiver, buyTokenA2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_BUY_A2");
            }
        }

        if (sellTokenInfo.valid && buyTokenInfo.official) {
            // SELLTOKEN tokenomics2.0 sell tax value applied to BUYTOKEN
            uint sellTokenB2 = (value * sellTokenInfo.addedToks.tokenB2TaxOnSell) / 10000;

            if (sellTokenB2 > 0) {
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, sellTokenInfo.feeReceiver, sellTokenB2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_SELL_B2");
            }
        }
    }

    function handleLIRefill(address antiDumpToken, address otherToken, address factory, uint value, uint otherTokenB2OtherToLI) public view returns(uint refill) {
        (uint antiDumpReserve, uint otherReserve) = DarwinSwapLibrary.getReserves(factory, antiDumpToken, otherToken);
        refill = (DarwinSwapLibrary.getAmountOut(value, otherReserve, antiDumpReserve) * otherTokenB2OtherToLI) / 10000;
    }

    // Ensures that the limitations we've set for taxes are respected
    function ensureTokenomics(IDarwinSwapLister.TokenInfo memory tokInfo, uint maxTok1Tax, uint maxTok2Tax, uint maxTotalTax) public pure returns(bool valid) {
        IDarwinSwapLister.TokenomicsInfo memory toks = tokInfo.addedToks;
        IDarwinSwapLister.OwnTokenomicsInfo memory ownToks = tokInfo.ownToks;

        uint tax1OnSell =   toks.tokenA1TaxOnSell + toks.tokenB1TaxOnSell + toks.tokenB1SellToLI;
        uint tax1OnBuy =    toks.tokenA1TaxOnBuy +  toks.tokenB1TaxOnBuy +  toks.tokenB1BuyToLI;
        uint tax2OnSell =   toks.tokenA2TaxOnSell + toks.tokenB2TaxOnSell + toks.refundOnSell +     toks.tokenB2SellToLI;
        uint tax2OnBuy =    toks.tokenA2TaxOnBuy +  toks.tokenB2TaxOnBuy +  toks.refundOnBuy +      toks.tokenB2BuyToLI;

        valid = tax1OnSell <= maxTok1Tax && tax1OnBuy <= maxTok1Tax && tax2OnSell <= maxTok2Tax && tax2OnBuy <= maxTok2Tax &&
                (toks.refundOnSell <= (ownToks.tokenTaxOnSell / 2)) && (toks.refundOnBuy <= (ownToks.tokenTaxOnBuy / 2)) &&
                (tax1OnBuy + tax1OnSell + tax2OnBuy + tax2OnSell <= maxTotalTax);
    }

    // Removes 5% from added tokenomics, to leave it for LP providers.
    function adjustTokenomics(IDarwinSwapLister.TokenomicsInfo calldata addedToks) public pure returns(IDarwinSwapLister.TokenomicsInfo memory returnToks) {
        returnToks.tokenA1TaxOnBuy = addedToks.tokenA1TaxOnBuy - (addedToks.tokenA1TaxOnBuy * 5) / 100;
        returnToks.tokenA1TaxOnSell = addedToks.tokenA1TaxOnSell - (addedToks.tokenA1TaxOnSell * 5) / 100;
        returnToks.tokenA2TaxOnBuy = addedToks.tokenA2TaxOnBuy - (addedToks.tokenA2TaxOnBuy * 5) / 100;
        returnToks.tokenA2TaxOnSell = addedToks.tokenA2TaxOnSell - (addedToks.tokenA2TaxOnSell * 5) / 100;
        returnToks.tokenB1TaxOnBuy = addedToks.tokenB1TaxOnBuy - (addedToks.tokenB1TaxOnBuy * 5) / 100;
        returnToks.tokenB1TaxOnSell = addedToks.tokenB1TaxOnSell - (addedToks.tokenB1TaxOnSell * 5) / 100;
        returnToks.tokenB2TaxOnBuy = addedToks.tokenB2TaxOnBuy - (addedToks.tokenB2TaxOnBuy * 5) / 100;
        returnToks.tokenB2TaxOnSell = addedToks.tokenB2TaxOnSell - (addedToks.tokenB2TaxOnSell * 5) / 100;
        returnToks.refundOnBuy = addedToks.refundOnBuy - (addedToks.refundOnBuy * 5) / 100;
        returnToks.refundOnSell = addedToks.refundOnSell - (addedToks.refundOnSell * 5) / 100;
        returnToks.tokenB1SellToLI = addedToks.tokenB1SellToLI - (addedToks.tokenB1SellToLI * 5) / 100;
        returnToks.tokenB1BuyToLI = addedToks.tokenB1BuyToLI - (addedToks.tokenB1BuyToLI * 5) / 100;
        returnToks.tokenB2SellToLI = addedToks.tokenB2SellToLI - (addedToks.tokenB2SellToLI * 5) / 100;
        returnToks.tokenB2BuyToLI = addedToks.tokenB2BuyToLI - (addedToks.tokenB2BuyToLI * 5) / 100;
    }
}