// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
/**
 * @title GS Dynamic Price 
 * @author www.geeks.solutions
 * @dev These functions helps to build a dynamic price based on a set of arbitrary conditions
 * It assumes the price rules list is sorted by ascending trigger values and provides a function
 * to check for the validity of a price rules list:
 *  - Makes sure the list is NOT empty
 *  - Makes sure the list sorted by ascending trigger values
 *  - Makes sure each entry contains a price that is >= 0
 * It also provides a function to extract the total price to charge based on an ordered list of price rules, a value and an amount
 * of tokens to mint to pull the right triggers
 */
library GsDynamicPrice {
    error InvalidRule();
    
    struct PriceRule {
        uint128 trigger;
        uint128 priceInWei;
    }

    /**
     * @dev Extracts the price from the list of price rules, if no rule is triggered, it returns the default price
     * It also returns a boolean indicating if a rule has been triggered
     * 
     * @param ordered_rules a list of price rules that is sorted by ascending trigger values
     * @param value the value that should be over the rule trigger value to execute the rule
     * @param defaultPrice the default price value to return in wei if no rule is triggered
     * @param amount the amount of tokens to be minted
     * @return triggered
     * @return price
     */
    function extractPrice(PriceRule[] storage ordered_rules, uint value, uint defaultPrice, uint amount) internal view 
    returns (bool triggered, uint price){
        uint length = ordered_rules.length;
        if (length == 0) { 
            // we have no rules to apply
            return (false, amount * defaultPrice);
        }
        bool value_found;
        bool value_before_first_rule;
        price = 0;
        PriceRule storage rule = ordered_rules[0];
        if (value < rule.trigger + 1) {
            value_before_first_rule = value_found = true;
            if (value + amount < rule.trigger + 1) {
                return (false, amount * defaultPrice);
            } else {
                unchecked {
                    price += (rule.trigger - value) * defaultPrice;
                }
            }
        }
        
        uint32 value_index = 0;
        for (uint32 i = 0; i < length; i++) {
            rule = ordered_rules[i];
            if (!value_found) {
                // Last rule in the list, we trigger if the value is >= to trigger in this case only as no rule exists above
                if (i == length - 1 && rule.trigger <= value) {
                    // The value triggers this rule and no rule after
                    return (true, amount * rule.priceInWei);
                } else if (rule.trigger < value && i < length - 1 &&  ordered_rules[i + 1].trigger > value) {
                    // the value triggers this rule and not the one above
                    value_found = true;
                    value_index = i; 
                } else if (rule.trigger < value && i < length - 1 &&  ordered_rules[i + 1].trigger < value) {
                    // the value is next
                    continue;
                }  
            }

            if (rule.trigger < value + amount  && 
                (i == length - 1 || (i < length - 1 && ordered_rules[i + 1].trigger + 1 > value + amount))) {
                // the total triggers this index and no rule after
                if (value_index == i && !value_before_first_rule) {
                    unchecked {
                        price += amount * rule.priceInWei;
                    }
                } else {
                    unchecked {
                        price += (value + amount - rule.trigger) * rule.priceInWei;
                    }
                }
                // we found the total in the current rule we return
                return (true, price);
            } else if (rule.trigger < value + amount && i < length - 1 && ordered_rules[i + 1].trigger < value + amount) {
                if (value_index == i && !value_before_first_rule) {
                    unchecked {
                        price += (ordered_rules[i + 1].trigger - value) * rule.priceInWei;
                    }
                } else {
                    unchecked {
                        price += (ordered_rules[i + 1].trigger - rule.trigger) * rule.priceInWei;
                    }
                }
                continue;
            } else if (value + amount < rule.trigger) {
                unchecked {
                    price += (value + amount - ordered_rules[i - 1].trigger) * ordered_rules[i - 1].priceInWei;
                }
                return (true, price);
            }
        }
    }

    /**
     * @dev This function is to be invoked by the contract before storing the rules list to guarantee the rules list will be compatible
     * with the `extractPrice` function
     * 
     * @param ordered_rules a list of price rules to check for validity
     */
    function checkValidRulesList(PriceRule[] calldata ordered_rules) internal pure returns(bool) {
        uint length = ordered_rules.length;
        if (length == 0) {return false;}

        uint trigger = 0;
        for (uint i = 0; i < length; i++) {
            if (trigger < ordered_rules[i].trigger && ordered_rules[i].priceInWei >= 0) { trigger = ordered_rules[i].trigger; }
            else { return false; }
        }
        return true;
    }
}