// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library CollateralPoolLibrary {
    // ================ Structs ================
    // Needed to lower stack size
    struct MintFF_Params {
        uint256 bankx_price_usd; 
        uint256 col_price_usd;
        uint256 bankx_amount;
        uint256 collateral_amount;
        uint256 col_ratio;
    }

    struct BuybackBankX_Params {
        uint256 excess_collateral_dollar_value_d18;
        uint256 bankx_price_usd;
        uint256 col_price_usd;
        uint256 BankX_amount;
    }

    struct BuybackXSD_Params {
        uint256 excess_collateral_dollar_value_d18;
        uint256 xsd_price_usd;
        uint256 col_price_usd;
        uint256 XSD_amount;
    }



    // ================ Functions ================
// xsd is at the price of one gram of silver.
    function calcMint1t1XSD(uint256 col_price, uint256 silver_price, uint256 collateral_amount_d18) public pure returns (uint256) {
        uint256 gram_price = (silver_price*(1e4))/(311035);
        return (collateral_amount_d18*(col_price))/(gram_price); 
    }
// xsd is at the price of one gram of silver
    function calcMintAlgorithmicXSD(uint256 bankx_price_usd, uint256 silver_price, uint256 bankx_amount_d18) public pure returns (uint256) {
        uint256 gram_price = (silver_price*(1e4))/(311035);
        return (bankx_amount_d18*bankx_price_usd)/(gram_price);
    }

    function calcMintInterest(uint256 XSD_amount,uint256 silver_price,uint256 rate, uint256 accum_interest, uint256 interest_rate, uint256 time, uint256 amount) internal view returns(uint256, uint256, uint256, uint256) {
        uint256 gram_price = (silver_price*(1e4))/(311035);
        if(time == 0){
        interest_rate = rate;
        amount = XSD_amount;
        time = block.timestamp;
        }
        else{
        uint delta_t = block.timestamp - time;
        delta_t = delta_t/(86400); 
        accum_interest = accum_interest+((amount*gram_price*interest_rate*delta_t)/(365*(1e12)));
    
        interest_rate = (amount*interest_rate) + (XSD_amount*rate);
        amount = amount+XSD_amount;
        interest_rate = interest_rate/amount;
        time = block.timestamp;
        }
        return (
            accum_interest,
            interest_rate,
            time, 
            amount
        );
    }

    function calcRedemptionInterest(uint256 XSD_amount,uint256 silver_price, uint256 accum_interest, uint256 interest_rate, uint256 time, uint256 amount) internal view returns(uint256, uint256, uint256, uint256){
        uint256 gram_price = (silver_price*(1e4))/(311035);
        uint delta_t = block.timestamp - time;
        delta_t = delta_t/(86400);
        accum_interest = accum_interest+((amount*gram_price*interest_rate*delta_t)/(365*(1e12)));
        amount = amount - XSD_amount;
        time = block.timestamp;
        return (
            accum_interest,
            interest_rate,
            time, 
            amount
        );
    }
    
    // Must be internal because of the struct
    // xsd must be the dollar value of one price of silver
    function calcMintFractionalXSD(MintFF_Params memory params) internal pure returns (uint256, uint256) {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint XSD. We do this by seeing the minimum mintable XSD based on each amount 
        uint256 bankx_dollar_value_d18;
        uint256 c_dollar_value_d18;
        
        // Scoping for stack concerns
        {    
            // USD amounts of the collateral and the BankX
            bankx_dollar_value_d18 = params.bankx_amount*(params.bankx_price_usd)/(1e6);
            c_dollar_value_d18 = params.collateral_amount*(params.col_price_usd)/(1e6);

        }
        uint calculated_bankx_dollar_value_d18 = 
                    (c_dollar_value_d18*(1e6)/(params.col_ratio))
                    -(c_dollar_value_d18);

        uint calculated_bankx_needed = calculated_bankx_dollar_value_d18*(1e6)/(params.bankx_price_usd);

        return (
            (c_dollar_value_d18+calculated_bankx_dollar_value_d18),
            calculated_bankx_needed
        );
    }

    function calcRedeem1t1XSD(uint256 col_price_usd,uint256 silver_price, uint256 XSD_amount) public pure returns (uint256,uint256) {
        uint256 gram_price = (silver_price*(1e4))/(311035);
        return ((XSD_amount*gram_price/1e6),((XSD_amount*gram_price)/col_price_usd));
    }

    // Must be internal because of the struct
    function calcBuyBackBankX(BuybackBankX_Params memory params) internal pure returns (uint256) {
        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible BankX with the desired collateral
        require(params.excess_collateral_dollar_value_d18 > 0, "No excess collateral to buy back!");

        // Make sure not to take more than is available
        uint256 bankx_dollar_value_d18 = (params.BankX_amount*params.bankx_price_usd);
        require((bankx_dollar_value_d18/1e6) <= params.excess_collateral_dollar_value_d18, "You are trying to buy back more than the excess!");

        // Get the equivalent amount of collateral based on the market value of BankX provided 
        uint256 collateral_equivalent_d18 = (bankx_dollar_value_d18)/(params.col_price_usd);
        //collateral_equivalent_d18 = collateral_equivalent_d18-((collateral_equivalent_d18*(params.buyback_fee))/(1e6));

        return (
            collateral_equivalent_d18
        );

    }

    function calcBuyBackXSD(BuybackXSD_Params memory params) internal pure returns (uint256) {
        require(params.excess_collateral_dollar_value_d18 > 0, "No excess collateral to buy back!");

        uint256 xsd_dollar_value_d18 = params.XSD_amount*(params.xsd_price_usd);
        require((xsd_dollar_value_d18/1e6) <= params.excess_collateral_dollar_value_d18, "You are trying to buy more than the excess!");

        uint256 collateral_equivalent_d18 = (xsd_dollar_value_d18)/(params.col_price_usd);

        return (
            collateral_equivalent_d18
        );
    }

}