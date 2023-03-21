pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { SyndicateFactory } from "../../../contracts/syndicate/SyndicateFactory.sol";
import { IFactoryDependencyInjector } from "../interfaces/IFactoryDependencyInjector.sol";
import { SyndicateMock } from "./SyndicateMock.sol";

contract SyndicateFactoryMock is IFactoryDependencyInjector, SyndicateFactory {
    /// @dev Mock Stakehouse dependencies that will be injected into the LSDN networks
    address public override accountMan;
    address public override txRouter;
    address public override uni;
    address public override slot;
    address public override dETH;
    address public override saveETHRegistry;

    constructor(
        address _accountMan,
        address _txRouter,
        address _uni,
        address _slot
    ) {
        _init(address(new SyndicateMock()), msg.sender);

        // Create mock Stakehouse contract dependencies that can later be injected
        accountMan = _accountMan;
        txRouter = _txRouter;
        uni = _uni;
        slot = _slot;
    }

    function deployMockSyndicate(
        address _contractOwner,
        uint256 _priorityStakingEndBlock,
        address[] calldata _priorityStakers,
        bytes[] calldata _blsPubKeysForSyndicateKnots
    ) public returns (address) {
        // Syndicate deployed with factory as owner first for dependency injection
        address syn = deploySyndicate(
            address(this),
            _priorityStakingEndBlock,
            _priorityStakers,
            _blsPubKeysForSyndicateKnots
        );

        // then ownership given to address requested by test
        SyndicateMock(payable(syn)).transferOwnership(_contractOwner);

        // Address of syndicate now returned
        return syn;
    }
}