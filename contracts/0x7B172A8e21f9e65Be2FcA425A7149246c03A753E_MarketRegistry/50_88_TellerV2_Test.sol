// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Testable } from "./Testable.sol";

import { TellerV2 } from "../TellerV2.sol";
import { MarketRegistry } from "../MarketRegistry.sol";
import { ReputationManager } from "../ReputationManager.sol";

import "../TellerV2Storage.sol";

import "../interfaces/IMarketRegistry.sol";
import "../interfaces/IReputationManager.sol";

import "../EAS/TellerAS.sol";

import "../mock/WethMock.sol";
import "../interfaces/IWETH.sol";

contract TellerV2_Test is Testable, TellerV2 {
    User private marketOwner;
    User private borrower;
    User private lender;

    WethMock wethMock;

    constructor() TellerV2(address(address(0))) {}

    function setup_beforeAll() public {
        wethMock = new WethMock();

        marketOwner = new User(this, wethMock);
        borrower = new User(this, wethMock);
        lender = new User(this, wethMock);

        lenderCommitmentForwarder = address(0);
        marketRegistry = IMarketRegistry(new MarketRegistry());
        reputationManager = IReputationManager(new ReputationManager());
    }
}

contract User {
    TellerV2 public immutable tellerV2;
    WethMock public immutable wethMock;

    constructor(TellerV2 _tellerV2, WethMock _wethMock) {
        tellerV2 = _tellerV2;
        wethMock = _wethMock;
    }

    function depositToWeth(uint256 amount) public {
        wethMock.deposit{ value: amount }();
    }
}