// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Testable } from "./Testable.sol";

import { TellerV2Autopay } from "../TellerV2Autopay.sol";
import { MarketRegistry } from "../MarketRegistry.sol";
import { ReputationManager } from "../ReputationManager.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../TellerV2Storage.sol";

import "../interfaces/IMarketRegistry.sol";
import "../interfaces/IReputationManager.sol";

import "../EAS/TellerAS.sol";

import "../mock/WethMock.sol";

import "../mock/TellerV2SolMock.sol";
import "../mock/MarketRegistryMock.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/ITellerV2Autopay.sol";

import "@mangrovedao/hardhat-test-solidity/test.sol";
import "hardhat/console.sol";

contract TellerV2Autopay_Test is Testable, TellerV2Autopay {
    User private marketOwner;
    User private borrower;
    User private lender;

    WethMock wethMock;

    address marketRegistry;

    constructor() TellerV2Autopay(address(new TellerV2SolMock())) {
        marketRegistry = address(new MarketRegistryMock());
        TellerV2SolMock(address(tellerV2)).setMarketRegistry(marketRegistry);
    }

    function setup_beforeAll() public {
        wethMock = new WethMock();

        marketOwner = new User(
            address(this),
            address(tellerV2),
            address(wethMock)
        );
        borrower = new User(
            address(this),
            address(tellerV2),
            address(wethMock)
        );
        lender = new User(address(this), address(tellerV2), address(wethMock));
    }

    function setAutoPayEnabled_before() public {
        uint256 marketplaceId = 1;
        marketOwner.createMarketWithinRegistry(
            address(marketRegistry),
            8000,
            7000,
            5000,
            500,
            false,
            false,
            V2Calculations.PaymentType.EMI,
            "uri://"
        );

        uint256 bidId = borrower.submitBid(
            address(wethMock),
            marketplaceId,
            100,
            4000,
            300,
            "ipfs://",
            address(borrower)
        );
    }

    function setAutoPayEnabled_test() public {
        uint256 bidId = 0;

        borrower.enableAutoPay(bidId, true);

        Test.eq(
            loanAutoPayEnabled[bidId],
            true,
            "Autopay not enabled after setAutoPayEnabled"
        );
    }

    function autoPayLoanMinimum_before() public {
        uint256 marketplaceId = 1;

        uint256 lenderNewBalance = 50000;

        payable(address(lender)).transfer(lenderNewBalance);

        //lender approves for acceptBid
        lender.depositToWeth(lenderNewBalance);
        lender.approveWeth(address(tellerV2), lenderNewBalance);

        uint256 bidId = borrower.submitBid(
            address(wethMock),
            marketplaceId,
            100,
            4000,
            300,
            "ipfs://",
            address(borrower)
        );

        borrower.enableAutoPay(bidId, true);

        uint256 lenderBalance = ERC20(address(wethMock)).balanceOf(
            address(lender)
        );

        lender.acceptBid(bidId);

        uint256 borrowerNewBalance = 50000;

        payable(address(borrower)).transfer(borrowerNewBalance);

        //borrower approve to do repay
        borrower.depositToWeth(borrowerNewBalance);
        borrower.approveWeth(address(this), borrowerNewBalance);
    }

    function autoPayLoanMinimum_test() public {
        uint256 bidId = 0;

        uint256 lenderBalanceBefore = ERC20(address(wethMock)).balanceOf(
            address(lender)
        );
        uint256 borrowerBalanceBefore = ERC20(address(wethMock)).balanceOf(
            address(borrower)
        );

        lender.autoPayLoanMinimum(bidId);

        uint256 lenderBalanceAfter = ERC20(address(wethMock)).balanceOf(
            address(lender)
        );
        uint256 borrowerBalanceAfter = ERC20(address(wethMock)).balanceOf(
            address(borrower)
        );

        uint256 lenderBalanceDelta = lenderBalanceBefore - lenderBalanceAfter;

        Test.eq(lenderBalanceDelta, 0, "lender balance changed");

        uint256 borrowerBalanceDelta = borrowerBalanceBefore -
            borrowerBalanceAfter;

        Test.eq(borrowerBalanceDelta, 400, "borrower did not autopay");
    }

    function getEstimatedMinimumPayment(uint256 _bidId)
        public
        override
        returns (uint256 _amount)
    {
        return 400; //stub this for this test since there is not a good way to fast forward timestamp
    }
}

contract User {
    address public immutable tellerV2;
    address public immutable wethMock;
    address public immutable tellerV2Autopay;

    constructor(
        address _tellerV2Autopay,
        address _tellerV2,
        address _wethMock
    ) {
        tellerV2Autopay = _tellerV2Autopay;
        tellerV2 = _tellerV2;
        wethMock = _wethMock;
    }

    function enableAutoPay(uint256 bidId, bool enabled) public {
        ITellerV2Autopay(tellerV2Autopay).setAutoPayEnabled(bidId, enabled);
    }

    function createMarketWithinRegistry(
        address marketRegistry,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        V2Calculations.PaymentType _paymentType,
        string calldata _uri
    ) public {
        IMarketRegistry(marketRegistry).createMarket(
            address(this),
            _paymentCycleDuration,
            _paymentDefaultDuration,
            _bidExpirationTime,
            _feePercent,
            _requireLenderAttestation,
            _requireBorrowerAttestation,
            _paymentType,
            _uri
        );
    }

    function autoPayLoanMinimum(uint256 bidId) public {
        ITellerV2Autopay(tellerV2Autopay).autoPayLoanMinimum(bidId);
    }

    function submitBid(
        address _lendingToken,
        uint256 _marketplaceId,
        uint256 _principal,
        uint32 _duration,
        uint16 _APR,
        string calldata _metadataURI,
        address _receiver
    ) public returns (uint256) {
        return
            ITellerV2(tellerV2).submitBid(
                _lendingToken,
                _marketplaceId,
                _principal,
                _duration,
                _APR,
                _metadataURI,
                _receiver
            );
    }

    function acceptBid(uint256 _bidId) public {
        ITellerV2(tellerV2).lenderAcceptBid(_bidId);
    }

    function depositToWeth(uint256 amount) public {
        IWETH(wethMock).deposit{ value: amount }();
    }

    function approveWeth(address to, uint256 amount) public {
        ERC20(wethMock).approve(to, amount);
    }

    receive() external payable {}
}