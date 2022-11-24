// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./OcfiStorage.sol";
import "./OcfiFees.sol";
import "./OcfiReferrals.sol";
import "./OcfiStorage.sol";

library OcfiTransfers {
    using OcfiFees for OcfiFees.Data;
    using OcfiReferrals for OcfiReferrals.Data;
    using OcfiStorage for OcfiStorage.Data;

    struct Data {
        address uniswapV2Router;
        address uniswapV2Pair;
    }

    uint256 private constant FACTOR_MAX = 10000;

    event BuyWithFees(
        address indexed account,
        uint256 amount,
        uint256 feeFactor,
        uint256 feeTokens
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


    function handleTransferWithFees(Data storage data, OcfiStorage.Data storage _storage, address from, address to, uint256 amount, address referrer) public returns(uint256 fees, uint256 referrerReward) {
        if(transferIsBuy(data, from, to)) {
            uint256[] memory currentFees = _storage.fees.getCurrentFees(_storage);
            uint256 buyFee = currentFees[0];

             if(referrer != address(0)) {
                 //lower buy fee by referral bonus
                if(_storage.referrals.referredBonus >= buyFee) {
                    buyFee = 0;
                }
                else {
                    buyFee -= _storage.referrals.referredBonus;
                }
             }

            uint256 tokensBought = amount;

            if(buyFee > 0) {
                fees = OcfiFees.calculateFees(amount, uint256(buyFee));

                tokensBought = amount - fees;

                emit BuyWithFees(to, amount, buyFee, fees);
            }

            if(referrer != address(0)) {
                referrerReward = amount * _storage.referrals.referralBonus / FACTOR_MAX;
            }
        }
        else if(transferIsSell(data, from, to)) {
            uint256 sellFee = _storage.fees.handleSell(_storage, amount);

            fees = OcfiFees.calculateFees(amount, sellFee);

            emit SellWithFees(from, amount, sellFee, fees);
        }
        else {
            fees = OcfiFees.calculateFees(amount, _storage.fees.baseFee);
        }
    }
}