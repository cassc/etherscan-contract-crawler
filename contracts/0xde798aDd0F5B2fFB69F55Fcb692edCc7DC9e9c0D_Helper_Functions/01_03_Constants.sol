// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

library Constants {

    // ------- Addresses -------

    // USDT address
    address internal constant usdt_address = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT

    // USDC address
    address internal constant usdc_address = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC

    // Founder Wallets
    address internal constant founder_0 = 0x1FBBdc4b9c8CB458deb9305b0884c64D5DD7DBee; // S
    address internal constant founder_1 = 0xb96ddd73895FF973c85A0dcd882627c994d179C4; // P
    address internal constant founder_2 = 0x3e34a7014751dff1B5fE1aa340c35E8aa00C555E; // A
    address internal constant founder_3 = 0x7D3e5A497a03d294F17650c298F53Fb916421522; // F

    // Company
    address internal constant company_wallet = 0xfe7474462F0d520B3A41bBE3813dd9aE6B5190B8; // Owner

    // Price signing
    address internal constant pricing_authority = 0x83258645a1E202ED1EAA70cAA015DCfaD8557b3b; // Signer

    // ------- Values -------

    // Standard amount of decimals we usually use
    uint128 internal constant decimals = 10 ** 18; // Same as Ethereum

    // Token supply
    uint128 internal constant founder_reward = 50 * 10**9 * decimals; // 4x 50 Billion
    uint128 internal constant company_reward = 200 * 10**9 * decimals; // 200 Billion
    uint128 internal constant max_presale_quantity = 200 * 10**9 * decimals; // 200 Billion
    uint128 internal constant maximum_subsidy = 400 * 10**9 * decimals; // 400 Billion

    // Fees and taxes these are in x100 for some precision
    uint128 internal constant ministerial_fee = 100;
    uint128 internal constant finders_fee = 100;
    uint128 internal constant minimum_tax_rate = 50;
    uint128 internal constant maximum_tax_rate = 500;
    uint128 internal constant tax_rate_range = maximum_tax_rate - minimum_tax_rate;
    uint16 internal constant maximum_royalties = 2500;
    
    // Values for subsidy
    uint128 internal constant subsidy_duration = 946080000; // 30 years
    uint128 internal constant max_subsidy_rate = 3 * maximum_subsidy / subsidy_duration;


}