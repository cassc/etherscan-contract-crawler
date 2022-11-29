// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

library Variables {
    // Baisc contract variable declaration
    string public constant _name = "ThunderEV";
    string public constant _symbol = "THEV";
    uint8 public constant _decimals = 18;
    uint256 public constant _initial_total_supply = 2000000000 * 10**_decimals;

    struct wallet_details {
        uint256 balance;
        uint256 joining_date;
        uint256 locked_on;

        // General allowance variable
        uint256 last_sent_time;
        uint256 max_sending_allowed_in_timeperiod;
        uint256 total_sent_in_timeperiod;

        // condition specific variables
        uint256 total_lock_amount;
        uint256 total_release_amount;
        uint256 next_release_time;
        uint256 current_release_iteration;
        uint256 current_release_amount;
        bool is_investor;
        bool is_director;
    }

    // investor variables
    uint16 public constant _investor_lock_days = 180;
    uint16 public constant _investor_release_percentage = 25;
    uint16 public constant _investor_total_release_iteration = 4;
    uint16 public constant _investor_release_every_days_after_locking = 30;

    // director variables
    uint16 public constant _director_lock_days = 730;
    uint16 public constant _director_release_percentage = 10;
    uint16 public constant _director_total_release_iteration = 10;
    uint16 public constant _director_release_every_days_after_locking = 365;

    // Burning Variables
    uint16 public constant _fees_percentage = 2;
    uint16 public constant _burning_from_fees_percentage = 10;
    uint16 public constant _development_sharing_percentage_from_fees_percentage = 35;
    uint16 public constant _marketing_sharing_percentage_from_fees_percentage = 35;
    uint16 public constant _redistribution_from_fees_percentage = 20;

    // All Token Holders Variable
    uint16 public constant _others_24_hours_transfer_limit = 25;

    // Fees Variables
    // Now To All Holders, if _Fees_distribution_eligibility > 0 then only distributed to holders holding greater amount
    uint256 public constant _fees_distribution_participation_eligibility = 1000;
    uint256 public constant _fees_distribution_after = 700 * 10**_decimals;

    // Pre Defined Wallet
    address public constant _development_wallet = 0xEa18f98cc0c1745515e912d2A69721e37FCc57C7;
    address public constant _marketing_wallet = 0x42B0d316E79b0D85A5F87142a60d15D9dc6291D2;

}
