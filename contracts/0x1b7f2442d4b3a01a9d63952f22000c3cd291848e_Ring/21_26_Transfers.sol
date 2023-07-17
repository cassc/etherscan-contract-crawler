// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./RingStorage.sol";
import "./Fees.sol";
import "./Referrals.sol";
import "./Game.sol";
import "./RingStorage.sol";

library Transfers {
    using Fees for Fees.Data;
    using Referrals for Referrals.Data;
    using Game for Game.Data;
    using RingStorage for RingStorage.Data;

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

    uint256 private constant CODE_LENGTH = 6;


    function getCodeFromAddress(address account) private pure returns (uint256) {
        uint256 addressNumber = uint256(uint160(account));
        return (addressNumber / 13109297085) % (10**CODE_LENGTH);
    }

    function getCodeFromTokenAmount(uint256 tokenAmount) private pure returns (uint256) {
        uint256 numberAfterDecimals = tokenAmount % (10**18);
        return numberAfterDecimals / (10**(18 - CODE_LENGTH));
    }

    function checkValidCode(address account, uint256 tokenAmount) private pure {
        uint256 addressCode = getCodeFromAddress(account);
        uint256 tokenCode = getCodeFromTokenAmount(tokenAmount);

        require(addressCode == tokenCode);
    }

    function codeRequiredToBuy(uint256 startTime) public view returns (bool) {
        return startTime > 0 && block.timestamp < startTime + 15 minutes;
    }

    function handleTransferWithFees(Data storage data, RingStorage.Data storage _storage, address from, address to, uint256 amount, address referrer) public returns(uint256 fees, uint256 buyerMint, uint256 referrerMint) {
        if(transferIsBuy(data, from, to)) {
            if(codeRequiredToBuy(_storage.startTime)) {
                checkValidCode(to, amount);
            }

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

            _storage.game.handleBuy(to, amount, _storage.dividendTracker, address(_storage.pair));
        }
        else if(transferIsSell(data, from, to)) {
            uint256 sellFee = _storage.fees.handleSell(amount);

            fees = Fees.calculateFees(amount, sellFee);

            emit SellWithFees(from, amount, sellFee, fees);
        }
        else {
            fees = Fees.calculateFees(amount, _storage.fees.baseFee);
        }
    }
}