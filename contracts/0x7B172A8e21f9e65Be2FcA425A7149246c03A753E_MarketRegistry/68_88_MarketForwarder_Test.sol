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

contract MarketForwarder_Test is Testable, TellerV2MarketForwarder {
    MarketForwarderTester private tester;

    MockMarketRegistry mockMarketRegistry;

    uint256 private marketId;
    User private marketOwner;
    User private user1;
    User private user2;

    constructor()
        TellerV2MarketForwarder(
            address(new MarketForwarderTester()),
            address(new MockMarketRegistry(address(0)))
        )
    {}

    function setup_beforeAll() public {
        mockMarketRegistry = MockMarketRegistry(address(getMarketRegistry()));
        tester = MarketForwarderTester(address(getTellerV2()));

        marketOwner = new User(tester);
        user1 = new User(tester);
        user2 = new User(tester);

        tester.__setMarketOwner(marketOwner);

        mockMarketRegistry.setMarketOwner(address(marketOwner));

        delete marketId;
    }

    function setTrustedMarketForwarder_before() public {
        marketOwner.setTrustedMarketForwarder(marketId, address(this));
    }

    function setTrustedMarketForwarder_test() public {
        Test.eq(
            tester.isTrustedMarketForwarder(marketId, address(this)),
            true,
            "Trusted forwarder was not set"
        );
    }

    function approveMarketForwarder_before() public {
        setTrustedMarketForwarder_before();

        user1.approveMarketForwarder(marketId, address(this));
        user2.approveMarketForwarder(marketId, address(this));
    }

    function approveMarketForwarder_test() public {
        Test.eq(
            tester.hasApprovedMarketForwarder(
                marketId,
                address(this),
                address(user1)
            ),
            true,
            "Borrower did not set market forwarder approval"
        );
        Test.eq(
            tester.hasApprovedMarketForwarder(
                marketId,
                address(this),
                address(user2)
            ),
            true,
            "Lender did not set market forwarder approval"
        );
    }

    function forwardUserCall_before() public {
        approveMarketForwarder_before();
    }

    function forwardUserCall_test() public {
        address expectedSender = address(user1);
        address sender = abi.decode(
            _forwardCall(
                abi.encodeWithSelector(
                    MarketForwarderTester.getSenderForMarket.selector,
                    marketId
                ),
                expectedSender
            ),
            (address)
        );
        Test.eq(
            sender,
            expectedSender,
            "Sender address for market does not match expected"
        );

        bytes memory expectedData = abi.encodeWithSelector(
            MarketForwarderTester.getDataForMarket.selector,
            marketId
        );
        bytes memory data = abi.decode(
            _forwardCall(expectedData, expectedSender),
            (bytes)
        );
        Test.eq0(
            data,
            expectedData,
            "Function calldata for market does not match expected"
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

contract MarketForwarderTester is TellerV2Context {
    constructor() TellerV2Context(address(0)) {}

    function __setMarketOwner(User _marketOwner) external {
        marketRegistry = IMarketRegistry(
            address(new MockMarketRegistry(address(_marketOwner)))
        );
    }

    function getSenderForMarket(uint256 _marketId)
        external
        view
        returns (address)
    {
        return _msgSenderForMarket(_marketId);
    }

    function getDataForMarket(uint256 _marketId)
        external
        view
        returns (bytes calldata)
    {
        return _msgDataForMarket(_marketId);
    }
}

contract MockMarketRegistry {
    address private marketOwner;

    constructor(address _marketOwner) {
        marketOwner = _marketOwner;
    }

    function setMarketOwner(address _marketOwner) public {
        marketOwner = _marketOwner;
    }

    function getMarketOwner(uint256) external view returns (address) {
        return address(marketOwner);
    }
}