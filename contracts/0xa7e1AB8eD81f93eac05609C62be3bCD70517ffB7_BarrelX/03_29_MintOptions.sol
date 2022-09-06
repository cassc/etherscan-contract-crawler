// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JupiterNFT.sol';

/**
 * @dev defines available options for the user to choose at mint time.
 * and keeps track of the minted options
 */
abstract contract MintOptions is JupiterNFT {
    /**
     * @dev Struct that defines a single mint option
     * @param price is the cost in wei for this option
     * @param remaining how many slots are available for this option
     * @param enabled allows a single option to be disabled or not.
     */
    struct Option {
        uint256 price;
        uint256 remaining;
        bool enabled;
    }

    // maps all available options by number with their configuration
    mapping(uint256 => Option) public options;

    constructor (){
        // option 1 - 6 month barrel
        // option 2 - 1.5 year barrel
        // option 3 - 2 year barrel
        // option 4 - 3 year barrel
        // option 5 - 4 year barrel

        // mashbills are 
        // 1 64C/24R/12M
        // 2 64C/24W/12M
        // 3 70C/21R/09M
        // 4 75C/21R/04M

        // e.g option 34 means a 2 year old barrel with mashbill 75C/21R/04M

        options[11] = Option(10000000000000000, 1250, true);
        options[12] = Option(10000000000000000, 0, false);
        options[13] = Option(10000000000000000, 0, false);
        options[14] = Option(10000000000000000, 0, false);

        // option 2 - 1 year old all mashbills
        options[21] = Option(20000000000000000, 0, false);
        options[22] = Option(20000000000000000, 0, false);
        options[23] = Option(20000000000000000, 0, false);
        options[24] = Option(20000000000000000, 1000, true);


        // option 3 - 2 years old
        options[31] = Option(30000000000000000, 0, false);
        options[32] = Option(30000000000000000, 2000, true);
        options[33] = Option(30000000000000000, 0, false);
        options[34] = Option(30000000000000000, 0, false);

        // option 4 - 3 years old
        options[41] = Option(40000000000000000, 0, false);
        options[42] = Option(40000000000000000, 0, false);
        options[43] = Option(40000000000000000, 500, true);
        options[44] = Option(40000000000000000, 0, false);

        // option 4 - 4 years old
        options[51] = Option(50000000000000000, 0, false);
        options[52] = Option(50000000000000000, 0, false);
        options[53] = Option(50000000000000000, 250, true);
        options[54] = Option(50000000000000000, 0, false);
    }

    /**
     * @dev allows an operator to define or change all parameters of an option
     * @param _optionNumber the number of the option, if exists it modifies.
     * @param _newPrice price in wei for this option
     * @param _newRemaining how many unit are available for this option
     * @param _enabled the flag for this option to be enabled
     */
    function setOption(uint256 _optionNumber, uint256 _newPrice, uint256 _newRemaining, bool _enabled) public {
        require(operators[msg.sender], "only operators");
        options[_optionNumber] = Option(_newPrice, _newRemaining, _enabled);
    }
}