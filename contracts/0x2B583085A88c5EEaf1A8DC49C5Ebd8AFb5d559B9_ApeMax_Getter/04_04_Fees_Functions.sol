// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./Data_Structures.sol";
import "./Constants.sol";

library Fees_Functions {

    /*
        Returns percentage tax at current time
        Tax ranges from 1% to 5%
        In 100x denomination
    */
    function calculate_tax(
        uint128 total_staked
        )
        internal pure
        returns(uint128)
    {

        if (total_staked >= Constants.maximum_subsidy) {
            return Constants.maximum_tax_rate;
        }

        return
            Constants.minimum_tax_rate +
            Constants.tax_rate_range *
            total_staked /
            Constants.maximum_subsidy;

    }

    /*
        Calculates fees to be shared amongst all parties when a new stake comes in
    */
    function calculate_inbound_fees(
        uint128 amount_staked,
        uint16 royalties,
        uint128 total_staked
        )
        internal pure
        returns(Data_Structures.Split memory)
    {
        Data_Structures.Split memory inbound_fees;
        
        inbound_fees.staker = Constants.finders_fee * amount_staked / 10000;
        inbound_fees.ministerial = Constants.ministerial_fee * amount_staked / 10000;
        inbound_fees.tax = amount_staked * calculate_tax(total_staked) / 10000;
        inbound_fees.creator = amount_staked * royalties / 1000000;
        
        inbound_fees.total =
            inbound_fees.staker +
            inbound_fees.ministerial + 
            inbound_fees.tax +
            inbound_fees.creator;

        return inbound_fees;
    }

}