// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@mangrovedao/hardhat-test-solidity/test.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { Testable } from "./Testable.sol";
import { TellerV2Context } from "../TellerV2Context.sol";
import { IMarketRegistry } from "../interfaces/IMarketRegistry.sol";
import { TellerV2MarketForwarder } from "../TellerV2MarketForwarder.sol";
import { LenderCommitmentForwarder } from "../LenderCommitmentForwarder.sol";

contract TellerV2Context_Test is Testable, TellerV2Context {
    uint256 private marketId;
    /*User private marketOwner;
    User private user1;
    User private user2;*/
    User private marketOwner;
    User private user1;

    constructor() TellerV2Context(address(0)) {}

    function setup_beforeAll() public {
        marketOwner = new User(TellerV2Context(this));

        marketRegistry = IMarketRegistry(
            address(new MockMarketRegistry(marketOwner))
        );

        Test.eq(
            marketRegistry.getMarketOwner(5),
            address(marketOwner),
            "should have set marketOwner"
        );
    }

    function isTrustedMarketForwarder_test() public returns (bool) {
        Test.eq(
            super.isTrustedMarketForwarder(89, lenderCommitmentForwarder),
            true,
            "lenderCommitmentForwarder should be a trusted forwarder for all markets"
        );
        //Test.eq(super.isTrustedMarketForwarder(1,  address(0)) , false, "by default address(0) should not be a trusted forwarder");

        address stubbedMarketForwarder = address(
            0xB11ca87E32075817C82Cc471994943a4290f4a14
        );
        Test.eq(
            super.isTrustedMarketForwarder(7, stubbedMarketForwarder),
            false,
            "by default an address should not be a trusted forwarder"
        );

        marketOwner.setTrustedMarketForwarder(7, stubbedMarketForwarder);

        Test.eq(
            super.isTrustedMarketForwarder(7, stubbedMarketForwarder),
            true,
            " address should  be a trusted forwarder after setting "
        );
    }
}

contract User {
    TellerV2Context public immutable context;

    constructor(TellerV2Context _context) {
        context = _context;
    }

    function setTrustedMarketForwarder(uint256 _marketId, address _forwarder)
        external
    {
        context.setTrustedMarketForwarder(_marketId, _forwarder);
    }

    function approveMarketForwarder(uint256 _marketId, address _forwarder)
        external
    {
        context.approveMarketForwarder(_marketId, _forwarder);
    }
}

contract MockMarketRegistry {
    User private immutable marketOwner;

    constructor(User _marketOwner) {
        marketOwner = _marketOwner;
    }

    function getMarketOwner(uint256) external view returns (address) {
        return address(marketOwner);
    }
}