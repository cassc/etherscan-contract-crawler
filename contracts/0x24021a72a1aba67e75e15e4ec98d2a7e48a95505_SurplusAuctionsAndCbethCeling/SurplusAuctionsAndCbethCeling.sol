/**
 *Submitted for verification at Etherscan.io on 2023-06-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

abstract contract Setter {
    function modifyParameters(bytes32, uint) public virtual;

    function modifyParameters(bytes32, bytes32, uint) public virtual;

    function removeAuthorization(address) public virtual;
}

contract SurplusAuctionsAndCbethCeling {
    Setter public constant GEB_SAFE_ENGINE =
        Setter(0x3AD2F30266B35F775D58Aecde3fbB7ea8b83bF2b);
    Setter public constant GEB_ACCOUNTING_ENGINE =
        Setter(0xDAf29A8bD397a4177C895C02F415Ad9e4774C7B1);

    function run() external {
        // set surplus auction settings
        GEB_ACCOUNTING_ENGINE.modifyParameters(
            "debtAuctionBidSize",
            70000 * 10 ** 45
        ); // rad
        GEB_ACCOUNTING_ENGINE.modifyParameters(
            "initialDebtAuctionMintedTokens",
            35000 * 10 ** 18
        ); // wad

        // set CBETH collaterals debt ceiling to 2mm
        GEB_SAFE_ENGINE.modifyParameters(
            "CBETH-A",
            "debtCeiling",
            2000000 * 10 ** 45
        ); // rad
        GEB_SAFE_ENGINE.modifyParameters(
            "CBETH-B",
            "debtCeiling",
            2000000 * 10 ** 45
        ); // rad
    }
}