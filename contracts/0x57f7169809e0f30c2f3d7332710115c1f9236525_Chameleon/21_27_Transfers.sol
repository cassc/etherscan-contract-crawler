// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ChameleonStorage.sol";
import "./Fees.sol";
import "./Referrals.sol";
import "./BiggestBuyer.sol";

library Transfers {
    using Fees for Fees.Data;
    using Referrals for Referrals.Data;
    using BiggestBuyer for BiggestBuyer.Data;

    struct Data {
        address uniswapV2Router;
        address uniswapV2Pair;
    }

    uint256 private constant FACTOR_MAX = 10000;

    event BuyWithFees(
        address indexed account,
        uint256 amount,
        int256 feeFactor,
        int256 feeTokens
    );

    event SellWithFees(
        address indexed account,
        uint256 amount,
        uint256 feeFactor,
        uint256 feeTokens
    );

    function init(
        Data storage data,
        address uniswapV2Router,
        address uniswapV2Pair)
        public {
        data.uniswapV2Router = uniswapV2Router;
        data.uniswapV2Pair = uniswapV2Pair;
    }

    function transferIsBuy(Data storage data, address from, address to) public view returns (bool) {
        return from == data.uniswapV2Pair && to != data.uniswapV2Router;
    }

    function transferIsSell(Data storage data, address from, address to) public view returns (bool) {
        return from != data.uniswapV2Router && to == data.uniswapV2Pair;
    }


    function handleTransferWithFees(Data storage data, ChameleonStorage.Data storage _storage, address from, address to, uint256 amount, address referrer) public returns(uint256 fees, uint256 buyerMint, uint256 referrerMint) {        
        if(transferIsBuy(data, from, to)) {
            (int256 buyFee,) = _storage.fees.getCurrentFees();

             if(referrer != address(0)) {
                 //lower buy fee by referral bonus, which will either trigger
                 //a lower buy fee, or a larger bonus
                buyFee -= int256(_storage.referrals.referredBonus);
             }

            uint256 tokensBought = amount;

            if(buyFee > 0) {
                fees = Fees.calculateFees(amount, uint256(buyFee));

                tokensBought = amount - fees;

                emit BuyWithFees(to, amount, buyFee, int256(fees));
            }
            else if(buyFee < 0) {
                uint256 extraTokens = amount * uint256(-buyFee) / FACTOR_MAX;

                /*
                    When buy fee is negative, the user gets a bonus
                    via temporarily minted tokens which can be burned
                    from liquidity by anyone in another transaction
                    using the function `burnLiquidityTokens`.

                    It must be done in another transaction because
                    you cannot mess with the liquidity in the pair
                    during a swap.
                */
                buyerMint = extraTokens;

                tokensBought += extraTokens;

                emit BuyWithFees(to, amount, buyFee, -int256(extraTokens));
            }

            if(referrer != address(0)) {
                uint256 referralBonus = tokensBought * _storage.referrals.referralBonus / FACTOR_MAX;

                referrerMint = referralBonus;
            }

            _storage.biggestBuyer.handleBuy(to, amount);
        }
        else if(transferIsSell(data, from, to)) {
            uint256 sellFee = _storage.fees.handleSell(amount);

            fees = Fees.calculateFees(amount, sellFee);

            emit SellWithFees(from, amount, sellFee, fees);

            //Force a claim of dividends when selling
            //so that paperhands are forced to claim unvested divs
            _storage.dividendTracker.claimDividends(
                from,
                _storage.marketingWallet1,
                _storage.marketingWallet2,
                true);
        }
        else {
            fees = Fees.calculateFees(amount, _storage.fees.baseFee);
        }
    }
}