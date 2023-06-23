// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../Math/SafeMath.sol";



library XUSDPoolLibrary {
    using SafeMath for uint256;

    // ================ Functions ================

    function calcMint1t1XUSD(uint256 col_price, uint256 mint_fee, uint256 collateral_amount_d18) public pure returns (uint256, uint256) {
        uint256 col_price_usd = col_price;
        uint256 c_dollar_value_d18 = (collateral_amount_d18.mul(col_price_usd)).div(1e6);
        uint256 fee = (c_dollar_value_d18.mul(mint_fee)).div(1e6);
        uint256 out = c_dollar_value_d18.sub(fee);
        return (out, fee);
    }

    function calcMintAlgorithmicXUSD(uint256 mint_fee, uint256 xus_price_usd, uint256 xus_amount_d18) public pure returns (uint256, uint256) {
        uint256 xus_dollar_value_d18 = xus_amount_d18.mul(xus_price_usd).div(1e6);
        uint256 fee = (xus_dollar_value_d18.mul(mint_fee)).div(1e6);
        uint256 out = xus_dollar_value_d18.sub(fee);
        return (out, fee);
    }
    
    // Must be internal because of the struct
    function calcMintFractionalXUSD(uint256 collat_amount, uint256 collat_price, uint256 xus_price, uint256 col_ratio, uint256 mint_fee) internal pure returns (uint256, uint256, uint256) {
        uint256 c_dollar_value_d18 = collat_amount.mul(collat_price).div(1e6);
        
        uint calculated_xus_dollar_value_d18 = 
                    (c_dollar_value_d18.mul(1e6).div(col_ratio))
                    .sub(c_dollar_value_d18);

        uint calculated_xus_needed = calculated_xus_dollar_value_d18.mul(1e6).div(xus_price);
        uint fee = ((c_dollar_value_d18.add(calculated_xus_dollar_value_d18)).mul(mint_fee)).div(1e6);
        uint out = (c_dollar_value_d18.add(calculated_xus_dollar_value_d18)).sub(fee);
        return (
            out,
            calculated_xus_needed,
            fee
        );
    }

    function calcRedeem1t1XUSD(uint256 col_price_usd, uint256 XUSD_amount, uint256 redemption_fee) public pure returns (uint256, uint256) {
        uint256 fee = XUSD_amount.mul(redemption_fee).div(1e6);
        uint256 left = XUSD_amount.sub(fee);
        uint256 collateral_needed_d18 = left.mul(1e6).div(col_price_usd);
        return (collateral_needed_d18, fee);
    }

    // Must be internal because of the struct
    function calcBuyBackXUS(uint256 XUS_amount, uint256 xus_price, uint256 excess_dv, uint256 col_price) internal pure returns (uint256) {
        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible XUS with the desired collateral
        require(excess_dv > 0, "no excess collateral");

        // Make sure not to take more than is available
        uint256 xus_dollar_value_d18 = XUS_amount.mul(xus_price).div(1e6);
        require(xus_dollar_value_d18 <= excess_dv, "excess collateral not enough");

        // Get the equivalent amount of collateral based on the market value of XUS provided 
        uint256 collateral_equivalent_d18 = xus_dollar_value_d18.mul(1e6).div(col_price);
        //collateral_equivalent_d18 = collateral_equivalent_d18.sub((collateral_equivalent_d18.mul(params.buyback_fee)).div(1e6));

        return (
            collateral_equivalent_d18
        );

    }

    // Returns value of collateral that must increase to reach recollateralization target (if 0 means no recollateralization)
    function recollateralizeAmount(uint256 total_supply, uint256 global_collateral_ratio, uint256 global_collat_value) public pure returns (uint256) {
        uint256 target_collat_value = total_supply.mul(global_collateral_ratio).div(1e6); // We want 18 decimals of precision so divide by 1e6; total_supply is 1e18 and global_collateral_ratio is 1e6
        // Subtract the current value of collateral from the target value needed, if higher than 0 then system needs to recollateralize
        uint256 recollateralization_left = target_collat_value.sub(global_collat_value); // If recollateralization is not needed, throws a subtraction underflow
        return(recollateralization_left);
    }

    function calcRecollateralizeXUSDInner(
        uint256 collateral_amount, 
        uint256 col_price,
        uint256 global_collat_value,
        uint256 xusd_total_supply,
        uint256 global_collateral_ratio
    ) public pure returns (uint256, uint256) {
        uint256 collat_value_attempted = collateral_amount.mul(col_price).div(1e6);
        uint256 effective_collateral_ratio = global_collat_value.mul(1e6).div(xusd_total_supply); //returns it in 1e6
        uint256 recollat_possible = (global_collateral_ratio.mul(xusd_total_supply).sub(xusd_total_supply.mul(effective_collateral_ratio))).div(1e6);

        uint256 amount_to_recollat;
        if(collat_value_attempted <= recollat_possible){
            amount_to_recollat = collat_value_attempted;
        } else {
            amount_to_recollat = recollat_possible;
        }

        return (amount_to_recollat.mul(1e6).div(col_price), amount_to_recollat);
    }
}