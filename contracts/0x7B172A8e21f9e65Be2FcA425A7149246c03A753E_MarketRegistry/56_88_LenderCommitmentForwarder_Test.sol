// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@mangrovedao/hardhat-test-solidity/test.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../TellerV2MarketForwarder.sol";
import { Testable } from "./Testable.sol";
import { LenderCommitmentForwarder } from "../LenderCommitmentForwarder.sol";

contract LenderCommitmentForwarder_Test is Testable, LenderCommitmentForwarder {
    LenderCommitmentTester private tester;
    MockMarketRegistry mockMarketRegistry;

    User private marketOwner;
    User private lender;
    User private borrower;

    address tokenAddress;
    uint256 marketId;
    uint256 maxAmount;
    uint32 maxLoanDuration;
    uint16 minInterestRate;
    uint32 expiration;

    bool acceptBidWasCalled;
    bool submitBidWasCalled;

    constructor()
        LenderCommitmentForwarder(
            address(new LenderCommitmentTester()),
            address(new MockMarketRegistry(address(0)))
        )
    {}

    function setup_beforeAll() public {
        tester = LenderCommitmentTester(address(getTellerV2()));
        mockMarketRegistry = MockMarketRegistry(address(getMarketRegistry()));

        marketOwner = new User(tester, (this));
        borrower = new User(tester, (this));
        lender = new User(tester, (this));
        tester.__setMarketOwner(marketOwner);

        mockMarketRegistry.setMarketOwner(address(marketOwner));

        tokenAddress = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
        marketId = 2;
        maxAmount = 100000000000000000000;
        maxLoanDuration = 2480000;
        minInterestRate = 3000;
        expiration = uint32(block.timestamp) + uint32(64000);

        marketOwner.setTrustedMarketForwarder(marketId, address(this));
        lender.approveMarketForwarder(marketId, address(this));

        delete acceptBidWasCalled;
        delete submitBidWasCalled;
    }

    function updateCommitment_before() public {
        super.updateCommitment(
            marketId,
            tokenAddress,
            maxAmount,
            maxLoanDuration,
            minInterestRate,
            expiration
        );
    }

    function updateCommitment_test() public {
        Commitment memory existingCommitment = lenderMarketCommitments[
            address(this)
        ][marketId][tokenAddress];

        //make sure the commitment exists
        //        Test.eq(existingCommitment.amount, maxAmount, "Commitment not recorded!" );
    }

    function deleteCommitment_test() public {
        //make sure the commitment exists
        //Test.eq( ,  ,"" );
        //        super.deleteCommitment(tokenAddress, marketId);
        //        Commitment memory existingCommitment = lenderMarketCommitments[address(this)][marketId][tokenAddress];
        //make sure the commitment has been removed
        //Test.eq( ,  ,"" );
    }

    function acceptCommitment_before() public {
        lender._updateCommitment(
            marketId,
            tokenAddress,
            maxAmount,
            maxLoanDuration,
            minInterestRate,
            expiration
        );
    }

    function acceptCommitment_test() public {
        Commitment storage commitment = lenderMarketCommitments[
            address(lender)
        ][marketId][tokenAddress];

        Test.eq(
            acceptBidWasCalled,
            false,
            "Expect accept bid not called before exercise"
        );

        uint256 bidId = marketOwner._acceptCommitment(
            marketId,
            address(lender),
            tokenAddress,
            maxAmount - 100,
            maxLoanDuration,
            minInterestRate
        );

        Test.eq(
            acceptBidWasCalled,
            true,
            "Expect accept bid called after exercise"
        );

        Test.eq(
            commitment.maxPrincipal == 100,
            true,
            "commitment not accepted"
        );

        bidId = marketOwner._acceptCommitment(
            marketId,
            address(lender),
            tokenAddress,
            100,
            maxLoanDuration,
            minInterestRate
        );

        Test.eq(commitment.maxPrincipal == 0, true, "commitment not accepted");
    }

    /*
        Overrider methods for exercise 
    */

    function _submitBid(CreateLoanArgs memory, address)
        internal
        override
        returns (uint256 bidId)
    {
        submitBidWasCalled = true;
        return 1;
    }

    function _acceptBid(uint256, address) internal override returns (bool) {
        acceptBidWasCalled = true;

        Test.eq(
            submitBidWasCalled,
            true,
            "Submit bid must be called before accept bid"
        );

        return true;
    }
}

contract User {
    TellerV2Context public immutable context;
    LenderCommitmentForwarder public immutable commitmentForwarder;

    constructor(
        TellerV2Context _context,
        LenderCommitmentForwarder _commitmentForwarder
    ) {
        context = _context;
        commitmentForwarder = _commitmentForwarder;
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

    function _updateCommitment(
        uint256 marketId,
        address tokenAddress,
        uint256 principal,
        uint32 loanDuration,
        uint16 interestRate,
        uint32 expiration
    ) public {
        commitmentForwarder.updateCommitment(
            marketId,
            tokenAddress,
            principal,
            loanDuration,
            interestRate,
            expiration
        );
    }

    function _acceptCommitment(
        uint256 marketId,
        address lender,
        address tokenAddress,
        uint256 principal,
        uint32 loanDuration,
        uint16 interestRate
    ) public returns (uint256) {
        return
            commitmentForwarder.acceptCommitment(
                marketId,
                lender,
                tokenAddress,
                principal,
                loanDuration,
                interestRate
            );
    }
}

contract LenderCommitmentTester is TellerV2Context {
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