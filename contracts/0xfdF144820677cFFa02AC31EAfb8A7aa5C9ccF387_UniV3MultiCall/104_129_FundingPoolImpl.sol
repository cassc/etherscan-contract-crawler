// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Constants} from "../Constants.sol";
import {DataTypesPeerToPool} from "./DataTypesPeerToPool.sol";
import {Errors} from "../Errors.sol";
import {IFactory} from "./interfaces/IFactory.sol";
import {IFundingPoolImpl} from "./interfaces/IFundingPoolImpl.sol";
import {ILoanProposalImpl} from "./interfaces/ILoanProposalImpl.sol";
import {IMysoTokenManager} from "../interfaces/IMysoTokenManager.sol";

contract FundingPoolImpl is Initializable, ReentrancyGuard, IFundingPoolImpl {
    using SafeERC20 for IERC20Metadata;

    address public factory;
    address public depositToken;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public depositUnlockTime;
    mapping(address => uint256) public totalSubscriptions;
    mapping(address => mapping(address => uint256)) public subscriptionAmountOf;
    // note: earliest unsubscribe time is to prevent griefing loans through atomic flashborrow,
    // deposit, subscribe, lock, unsubscribe, and withdraw
    mapping(address => mapping(address => uint256))
        internal _earliestUnsubscribe;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _factory,
        address _depositToken
    ) external initializer {
        if (_factory == address(0) || _depositToken == address(0)) {
            revert Errors.InvalidAddress();
        }
        factory = _factory;
        depositToken = _depositToken;
    }

    function deposit(
        uint256 amount,
        uint256 transferFee,
        uint256 depositLockupDuration
    ) external nonReentrant {
        if (amount == 0) {
            revert Errors.InvalidSendAmount();
        }
        if (depositLockupDuration > 0) {
            uint256 _depositUnlockTime = depositUnlockTime[msg.sender];
            if (_depositUnlockTime < block.timestamp + depositLockupDuration) {
                depositUnlockTime[msg.sender] =
                    block.timestamp +
                    depositLockupDuration;
            }
        }
        address mysoTokenManager = IFactory(factory).mysoTokenManager();
        if (mysoTokenManager != address(0)) {
            IMysoTokenManager(mysoTokenManager).processP2PoolDeposit(
                address(this),
                msg.sender,
                amount,
                depositLockupDuration,
                transferFee
            );
        }
        address _depositToken = depositToken;
        uint256 preBal = IERC20Metadata(_depositToken).balanceOf(address(this));
        IERC20Metadata(_depositToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount + transferFee
        );
        uint256 postBal = IERC20Metadata(_depositToken).balanceOf(
            address(this)
        );
        if (postBal != preBal + amount) {
            revert Errors.InvalidSendAmount();
        }
        balanceOf[msg.sender] += amount;
        emit Deposited(msg.sender, amount, depositLockupDuration);
    }

    function withdraw(uint256 amount) external {
        uint256 _balanceOf = balanceOf[msg.sender];
        if (amount == 0 || amount > _balanceOf) {
            revert Errors.InvalidWithdrawAmount();
        }
        if (block.timestamp < depositUnlockTime[msg.sender]) {
            revert Errors.DepositLockActive();
        }
        unchecked {
            balanceOf[msg.sender] = _balanceOf - amount;
        }
        IERC20Metadata(depositToken).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function subscribe(
        address loanProposal,
        uint256 minSubscriptionAmount,
        uint256 maxSubscriptionAmount,
        uint256 subscriptionLockupDuration
    ) external nonReentrant {
        if (
            maxSubscriptionAmount == 0 ||
            minSubscriptionAmount > maxSubscriptionAmount
        ) {
            revert Errors.InvalidAmount();
        }
        address _factory = factory;
        if (!IFactory(_factory).isLoanProposal(loanProposal)) {
            revert Errors.UnregisteredLoanProposal();
        }
        if (!ILoanProposalImpl(loanProposal).canSubscribe()) {
            revert Errors.NotInSubscriptionPhase();
        }
        (, , , , address whitelistAuthority, , , ) = ILoanProposalImpl(
            loanProposal
        ).staticData();
        if (
            whitelistAuthority != address(0) &&
            !IFactory(_factory).isWhitelistedLender(
                whitelistAuthority,
                msg.sender
            )
        ) {
            revert Errors.InvalidLender();
        }
        uint256 _balanceOf = balanceOf[msg.sender];
        if (maxSubscriptionAmount > _balanceOf) {
            revert Errors.InsufficientBalance();
        }
        DataTypesPeerToPool.LoanTerms memory loanTerms = ILoanProposalImpl(
            loanProposal
        ).loanTerms();
        if (subscriptionLockupDuration > 0) {
            (
                ,
                ,
                ,
                ,
                ,
                ,
                DataTypesPeerToPool.LoanStatus status,

            ) = ILoanProposalImpl(loanProposal).dynamicData();
            if (status != DataTypesPeerToPool.LoanStatus.LOAN_TERMS_LOCKED) {
                revert Errors.DisallowedSubscriptionLockup();
            }
        }
        uint256 _totalSubscriptions = totalSubscriptions[loanProposal];
        uint256 _freeSubscriptionSpace = loanTerms.maxTotalSubscriptions -
            _totalSubscriptions;
        if (_freeSubscriptionSpace < minSubscriptionAmount) {
            revert Errors.InsufficientFreeSubscriptionSpace();
        }
        uint256 effectiveSubscriptionAmount = maxSubscriptionAmount <
            _freeSubscriptionSpace
            ? maxSubscriptionAmount
            : _freeSubscriptionSpace;
        address mysoTokenManager = IFactory(factory).mysoTokenManager();
        if (mysoTokenManager != address(0)) {
            IMysoTokenManager(mysoTokenManager).processP2PoolSubscribe(
                address(this),
                msg.sender,
                loanProposal,
                effectiveSubscriptionAmount,
                subscriptionLockupDuration,
                _totalSubscriptions,
                loanTerms
            );
        }
        unchecked {
            // @dev: can't underflow due to previous `maxSubscriptionAmount > _balanceOf` check
            balanceOf[msg.sender] = _balanceOf - effectiveSubscriptionAmount;
        }
        totalSubscriptions[loanProposal] =
            _totalSubscriptions +
            effectiveSubscriptionAmount;
        subscriptionAmountOf[loanProposal][
            msg.sender
        ] += effectiveSubscriptionAmount;
        _earliestUnsubscribe[loanProposal][msg.sender] =
            block.timestamp +
            (
                subscriptionLockupDuration <
                    Constants.MIN_WAIT_UNTIL_EARLIEST_UNSUBSCRIBE
                    ? Constants.MIN_WAIT_UNTIL_EARLIEST_UNSUBSCRIBE
                    : subscriptionLockupDuration
            );
        emit Subscribed(
            msg.sender,
            loanProposal,
            effectiveSubscriptionAmount,
            subscriptionLockupDuration
        );
    }

    function unsubscribe(address loanProposal, uint256 amount) external {
        if (amount == 0) {
            revert Errors.InvalidAmount();
        }
        if (!IFactory(factory).isLoanProposal(loanProposal)) {
            revert Errors.UnregisteredLoanProposal();
        }
        if (!ILoanProposalImpl(loanProposal).canUnsubscribe()) {
            revert Errors.NotInUnsubscriptionPhase();
        }
        mapping(address => uint256)
            storage subscriptionAmountPerLender = subscriptionAmountOf[
                loanProposal
            ];
        if (amount > subscriptionAmountPerLender[msg.sender]) {
            revert Errors.UnsubscriptionAmountTooLarge();
        }
        mapping(address => uint256)
            storage earliestUnsubscribePerLender = _earliestUnsubscribe[
                loanProposal
            ];
        (
            ,
            ,
            ,
            ,
            ,
            ,
            DataTypesPeerToPool.LoanStatus status,

        ) = ILoanProposalImpl(loanProposal).dynamicData();
        if (
            status != DataTypesPeerToPool.LoanStatus.ROLLBACK &&
            block.timestamp < earliestUnsubscribePerLender[msg.sender]
        ) {
            revert Errors.BeforeEarliestUnsubscribe();
        }
        balanceOf[msg.sender] += amount;
        totalSubscriptions[loanProposal] -= amount;
        subscriptionAmountPerLender[msg.sender] -= amount;
        earliestUnsubscribePerLender[msg.sender] = 0;

        emit Unsubscribed(msg.sender, loanProposal, amount);
    }

    function executeLoanProposal(address loanProposal) external {
        address _factory = factory;
        if (!IFactory(_factory).isLoanProposal(loanProposal)) {
            revert Errors.UnregisteredLoanProposal();
        }

        (
            uint256 arrangerFee,
            uint256 grossLoanAmount,
            ,
            ,
            ,
            ,
            ,
            uint256 protocolFee
        ) = ILoanProposalImpl(loanProposal).dynamicData();
        DataTypesPeerToPool.LoanTerms memory loanTerms = ILoanProposalImpl(
            loanProposal
        ).loanTerms();
        if (
            block.timestamp + Constants.MIN_TIME_UNTIL_FIRST_DUE_DATE >
            loanTerms.repaymentSchedule[0].dueTimestamp
        ) {
            revert Errors.FirstDueDateTooCloseOrPassed();
        }
        ILoanProposalImpl(loanProposal).checkAndUpdateStatus();
        if (grossLoanAmount != totalSubscriptions[loanProposal]) {
            revert Errors.IncorrectLoanAmount();
        }
        IERC20Metadata(depositToken).safeTransfer(
            loanTerms.borrower,
            grossLoanAmount - arrangerFee - protocolFee
        );
        (, , , address arranger, , , , ) = ILoanProposalImpl(loanProposal)
            .staticData();

        address _depositToken = depositToken;
        if (arrangerFee > 0) {
            IERC20Metadata(_depositToken).safeTransfer(arranger, arrangerFee);
        }
        if (protocolFee > 0) {
            IERC20Metadata(_depositToken).safeTransfer(
                IFactory(factory).owner(),
                protocolFee
            );
        }

        emit LoanProposalExecuted(
            loanProposal,
            loanTerms.borrower,
            grossLoanAmount,
            arrangerFee,
            protocolFee
        );
    }
}