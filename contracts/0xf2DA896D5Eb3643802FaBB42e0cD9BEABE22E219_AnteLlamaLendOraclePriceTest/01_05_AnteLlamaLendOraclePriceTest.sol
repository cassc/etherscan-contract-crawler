// SPDX-License-Identifier: GPL-3.0-only

// NOTE: As of Dec 2022, a challenger checking this test can potentially be
// front-run (e.g. by setting a different message state to check, preventing
// test failure). To avoid this, a potential challenger could deploy a wrapper
// contract and use it to challenge and check the Ante Pool.

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface ILendingPool {
    function oracle() external view returns (address);
}

/// @title Checks that the LlamaLend oracle used by TubbyLoan never
///        returns a Tubby Cats floor price greater than 0.3 ETH.
/// @author 0x1A2B73207C883Ce8E51653d6A9cC8a022740cCA4 (abitwhaleish.eth)
/// @notice Ante Test to check the LlamaLend oracle used by the TubbyLoan
///         pool never returns a Tubby Cats price greater than 0.3 ETH
contract AnteLlamaLendOraclePriceTest is AnteTest("LlamaLend oracle never returns Tubby Cats price > 0.3 ETH") {
    struct Message {
        bytes32 hash;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // https://etherscan.io/address/0x34d0A4B1265619F3cAa97608B621a17531c5626f
    ILendingPool public constant LLAMALEND_TUBBYLOAN_POOL = ILendingPool(0x34d0A4B1265619F3cAa97608B621a17531c5626f);

    // https://etherscan.io/address/0xCa7cA7BcC765F77339bE2d648BA53ce9c8a262bD
    address public constant TUBBY_CATS = 0xCa7cA7BcC765F77339bE2d648BA53ce9c8a262bD;

    // The price that we don't think the oracle should return above
    uint256 public constant FAILURE_PRICE = 3e17; // 0.3 ETH

    // Message storage variable
    Message public message;

    constructor() {
        protocolName = "LlamaLend";
        testedContracts = [address(LLAMALEND_TUBBYLOAN_POOL), LLAMALEND_TUBBYLOAN_POOL.oracle()];
    }

    /// @notice Checks if a valid message with a Tubby Cats price higher than
    ///         the failure threshold has been signed by the oracle. Requires
    ///         message parameters to be set using setMessageToCheck prior to
    ///         calling checkTestPasses.
    /// @return true if the message state set matches a valid message signed
    ///         by the oracle
    function checkTestPasses() public view override returns (bool) {
        // Check the oracle address -- if 0x0, exit without failing the test
        address oracle = LLAMALEND_TUBBYLOAN_POOL.oracle();
        if (oracle == address(0)) return true;

        // Determine the address of the signed message contents set. We don't
        // use ECDSA.recover() because that will revert on error
        (address signer, ECDSA.RecoverError error) = ECDSA.tryRecover(message.hash, message.v, message.r, message.s);
        // If unsuccessful recovery, don't revert, just exit
        if (error != ECDSA.RecoverError.NoError) return true;

        // If signer == oracle, then a valid message with price higher than
        // the threshold has been signed by the oracle and the test fails
        return signer != oracle;
    }

    /*****************************************************
     * ================ USER INTERFACE ================= *
     *****************************************************/

    /// @notice Sets the message parameters to check for a valid signature. As
    ///         of 2022-12-07, the following API endpoint can be used to get
    ///         the latest signed message from the Tubby Cats price oracle:
    ///         https://oracle.llamalend.com/quote/1/0xca7ca7bcc765f77339be2d648ba53ce9c8a262bd
    /// @param price floor price of collection
    /// @param deadline deadline of floor price validity
    /// @param v part of the message signature
    /// @param r part of the message signature
    /// @param s part of the message signature
    function setMessageToCheck(
        uint216 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // We only care if the price we're checking is above the failure level
        // of the test. Also, no need to check _deadline as we just care if the
        // oracle has ever returned a price too high, but we need to collect it
        // so we can generate the correct message body to match
        require(price > FAILURE_PRICE, "Price not above failing level!");

        // Store the hashed message body and signature to check
        message = Message(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n111", price, deadline, block.chainid, TUBBY_CATS)
            ),
            v,
            r,
            s
        );
    }
}