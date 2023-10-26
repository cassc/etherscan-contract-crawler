// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev Settings keys.
 */
library LibConstants {
    /// Reserved IDs
    string internal constant EMPTY_IDENTIFIER = "";
    string internal constant SYSTEM_IDENTIFIER = "System";
    string internal constant NDF_IDENTIFIER = "NDF";
    string internal constant STM_IDENTIFIER = "Staking Mechanism";
    string internal constant SSF_IDENTIFIER = "SSF";
    string internal constant NAYM_TOKEN_IDENTIFIER = "NAYM"; //This is the ID in the system as well as the token ID
    string internal constant DIVIDEND_BANK_IDENTIFIER = "Dividend Bank"; //This will hold all the dividends
    string internal constant NAYMS_LTD_IDENTIFIER = "Nayms Ltd";

    /// Roles

    string internal constant ROLE_SYSTEM_ADMIN = "System Admin";
    string internal constant ROLE_SYSTEM_MANAGER = "System Manager";
    string internal constant ROLE_SYSTEM_UNDERWRITER = "System Underwriter";

    string internal constant ROLE_ENTITY_ADMIN = "Entity Admin";
    string internal constant ROLE_ENTITY_MANAGER = "Entity Manager";
    string internal constant ROLE_ENTITY_BROKER = "Broker";
    string internal constant ROLE_ENTITY_INSURED = "Insured";
    string internal constant ROLE_ENTITY_CP = "Capital Provider";
    string internal constant ROLE_ENTITY_CONSULTANT = "Consultant"; // note NEW name for ROLE_SERVICE_PROVIDER

    string internal constant ROLE_ENTITY_COMPTROLLER_COMBINED = "Comptroller Combined";
    string internal constant ROLE_ENTITY_COMPTROLLER_WITHDRAW = "Comptroller Withdraw";
    string internal constant ROLE_ENTITY_COMPTROLLER_CLAIM = "Comptroller Claim";
    string internal constant ROLE_ENTITY_COMPTROLLER_DIVIDEND = "Comptroller Dividend";

    /// old roles
    string internal constant ROLE_SPONSOR = "Sponsor";
    string internal constant ROLE_CAPITAL_PROVIDER = "Capital Provider";
    string internal constant ROLE_INSURED_PARTY = "Insured";
    string internal constant ROLE_BROKER = "Broker";
    string internal constant ROLE_SERVICE_PROVIDER = "Service Provider";

    string internal constant ROLE_UNDERWRITER = "Underwriter";
    string internal constant ROLE_CLAIMS_ADMIN = "Claims Admin";
    string internal constant ROLE_TRADER = "Trader";
    string internal constant ROLE_SEGREGATED_ACCOUNT = "Segregated Account";

    /// Groups

    string internal constant GROUP_SYSTEM_ADMINS = "System Admins";
    string internal constant GROUP_SYSTEM_MANAGERS = "System Managers";
    string internal constant GROUP_SYSTEM_UNDERWRITERS = "System Underwriters";

    string internal constant GROUP_TENANTS = "Tenants";
    string internal constant GROUP_MANAGERS = "Managers"; // a group of roles that can be assigned by both system and entity managers

    string internal constant GROUP_START_TOKEN_SALE = "Start Token Sale";
    string internal constant GROUP_EXECUTE_LIMIT_OFFER = "Execute Limit Offer";
    string internal constant GROUP_CANCEL_OFFER = "Cancel Offer";
    string internal constant GROUP_INTERNAL_TRANSFER_FROM_ENTITY = "Internal Transfer From Entity";
    string internal constant GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY = "External Withdraw From Entity";
    string internal constant GROUP_EXTERNAL_DEPOSIT = "External Deposit";
    string internal constant GROUP_PAY_SIMPLE_CLAIM = "Pay Simple Claim";
    string internal constant GROUP_PAY_SIMPLE_PREMIUM = "Pay Simple Premium";
    string internal constant GROUP_PAY_DIVIDEND_FROM_ENTITY = "Pay Dividend From Entity";

    string internal constant GROUP_POLICY_HANDLERS = "Policy Handlers"; // note replaced with GROUP_PAY_SIMPLE_PREMIUM

    string internal constant GROUP_ENTITY_ADMINS = "Entity Admins";
    string internal constant GROUP_ENTITY_MANAGERS = "Entity Managers";
    string internal constant GROUP_APPROVED_USERS = "Approved Users";
    string internal constant GROUP_BROKERS = "Brokers";
    string internal constant GROUP_INSURED_PARTIES = "Insured Parties";
    string internal constant GROUP_UNDERWRITERS = "Underwriters";
    string internal constant GROUP_CAPITAL_PROVIDERS = "Capital Providers";
    string internal constant GROUP_CLAIMS_ADMINS = "Claims Admins";
    string internal constant GROUP_TRADERS = "Traders";
    string internal constant GROUP_SEGREGATED_ACCOUNTS = "Segregated Accounts";
    string internal constant GROUP_SERVICE_PROVIDERS = "Service Providers";

    /*///////////////////////////////////////////////////////////////////////////
                        Market and Premium Fee Schedules
    ///////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant FEE_TYPE_PREMIUM = 1;
    uint256 internal constant FEE_TYPE_TRADING = 2;
    uint256 internal constant FEE_TYPE_INITIAL_SALE = 3;

    bytes32 internal constant DEFAULT_FEE_SCHEDULE = 0;

    /*///////////////////////////////////////////////////////////////////////////
                        MARKET OFFER STATES
    ///////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant OFFER_STATE_ACTIVE = 1;
    uint256 internal constant OFFER_STATE_CANCELLED = 2;
    uint256 internal constant OFFER_STATE_FULFILLED = 3;

    uint256 internal constant DUST = 1;
    uint256 internal constant BP_FACTOR = 10000;

    /*///////////////////////////////////////////////////////////////////////////
                        SIMPLE POLICY STATES
    ///////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant SIMPLE_POLICY_STATE_CREATED = 0;
    uint256 internal constant SIMPLE_POLICY_STATE_APPROVED = 1;
    uint256 internal constant SIMPLE_POLICY_STATE_ACTIVE = 2;
    uint256 internal constant SIMPLE_POLICY_STATE_MATURED = 3;
    uint256 internal constant SIMPLE_POLICY_STATE_CANCELLED = 4;
    uint256 internal constant STAKING_WEEK = 7 days;
    uint256 internal constant STAKING_MINTIME = 60 days; // 60 days min lock
    uint256 internal constant STAKING_MAXTIME = 4 * 365 days; // 4 years max lock
    uint256 internal constant SCALE = 1e18; //10 ^ 18

    /// _depositFor Types for events
    int128 internal constant STAKING_DEPOSIT_FOR_TYPE = 0;
    int128 internal constant STAKING_CREATE_LOCK_TYPE = 1;
    int128 internal constant STAKING_INCREASE_LOCK_AMOUNT = 2;
    int128 internal constant STAKING_INCREASE_UNLOCK_TIME = 3;

    string internal constant VE_NAYM_NAME = "veNAYM";
    string internal constant VE_NAYM_SYMBOL = "veNAYM";
    uint8 internal constant VE_NAYM_DECIMALS = 18;
    uint8 internal constant INTERNAL_TOKEN_DECIMALS = 18;
    address internal constant DAI_CONSTANT = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
}