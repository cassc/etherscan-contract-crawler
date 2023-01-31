// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interface/IPair.sol";

contract RC is Ownable {
    using SafeERC20 for IERC20;

    struct Subscription {
        bool active;
        uint256 validityPeriod;
        uint256 priceInQuoteToken;
        address paymentToken;
        address exchangePair;
        uint256 recoveryTokenLimit;
        uint256 penaltyBP; //penalty for late payment (without an insured event)
        uint256 erc20FeeBP; // commission from all erc20 balances for late payment (insured event)
        uint256 erc20PenaltyBP; // penalty from all erc20 balances in case of an insured event (not exist if there is a commission above)
    }

    struct Insurance {
        bool autopayment;
        uint256 subscriptionID;
        uint256 expirationTime;
        uint256 voteQuorum;
        uint256 rcCount;
        address backupWallet;
        address[] validators;
    }

    struct NFTinfo {
        address nftAddress;
        uint256[] ids;
    }

    struct Propose {
        bool executed;
        address newBackupWallet;
        uint256 deadline;
        uint256 executionTime;
        uint256 votersBits;
    }

    enum ProposalState {
        Unknown,
        Failed,
        Executed,
        Active,
        Succeeded,
        ExecutionWaiting
    }

    uint256 public constant EXECUTION_LOCK_PERIOD = 1 days;
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant BASE_POINT = 10000;
    uint256 public constant MAX_ERC20_PENALTY_BP = 2000; // 20%
    uint256 public constant MAX_ERC20_FEE_BP = 1000; // 10%
    uint256 public constant MAX_FEE_PENALTY_BP = 10000; // +100%
    uint256 public constant MAX_VALIDATORS = 30;
    uint256 public constant TRIAL_ID = 0;
    uint256 public constant FREEMIUM_ID = 1;
    address public immutable quoteTokenAddress;
    address public feeAddress;
    address public paymentAdmin;

    //   insurance creator => Insurance
    mapping(address => Insurance) public insurances;

    //   insurance creator => Propose
    mapping(address => Propose) public proposals;

    Subscription[] public subscriptions;

    modifier validSubscriptionID(uint256 _sid) {
        require(
            _sid < subscriptions.length && subscriptions[_sid].active,
            "subscription is not valid"
        );
        _;
    }

    event AutopaymentChanged(address user, bool active);
    event BackupWalletChanged(address user, address newBackupWallet);
    event SubscriptionsAdded(Subscription _subscription);
    event SubscriptionStateChanged(uint256 subscriptionID, bool active);
    event ValidatorsChanged(
        address user,
        uint256 newVoteQuorum,
        address[] newValidators
    );

    event CreateInsurance(
        address creator,
        uint256 priceInPaymentToken,
        Insurance userInsurance
    );
    event UpgradeInsurancePlan(
        address user,
        uint256 newSubscriptionID,
        uint256 expirationTime,
        uint256 priceInPaymentToken
    );
    event BillPayment(
        address payer,
        address insuranceOwner,
        uint256 amountInPaymentToken,
        uint256 newexpirationTime,
        bool withPenalty
    );
    event InsuranceEvent(
        address insuranceOwner,
        address backupWallet,
        uint256 recoveryTokensCount
    );
    event ProposalCreated(
        address insuranceOwner,
        address newBackupWallet,
        address proposer
    );
    event Vote(
        address insuranceOwner,
        address newBackupWallet,
        address validator
    );
    event ProposalConfirmed(address insuranceOwner, address newBackupWallet);
    event ProposalExecuted(address insuranceOwner, address newBackupWallet);

    constructor(
        address _feeAddress,
        address _paymentAdmin,
        address _quoteTokenAddress
    ) {
        // TRIAL
        subscriptions.push(
            Subscription(
                true,
                30 days,
                0,
                address(0),
                address(0),
                0, //recoveryTokenLimit
                0, // penaltyBP +100%
                0, //erc20FeeBP 0%
                0 // erc20PenaltyBP 20%
            )
        );
        
        // FREEMIUM
        subscriptions.push(
            Subscription(
                true,
                300000 days,
                0,
                address(0),
                address(0),
                1, //recoveryTokenLimit
                0, // penaltyBP +100%
                200, //erc20FeeBP 2%
                0 // erc20PenaltyBP 20%
            )
        );

        feeAddress = _feeAddress;
        paymentAdmin = _paymentAdmin;
        quoteTokenAddress = _quoteTokenAddress;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    /**
     * @param _paymentAdmin: address of the auto payment bot
     */
    function setPaymentAdminAddress(address _paymentAdmin) external onlyOwner {
        paymentAdmin = _paymentAdmin;
    }

    /**
     * @notice add new payment plan
     */
    function addSubscription(
        Subscription calldata _subscription
    ) external onlyOwner {
        require(
            _subscription.paymentToken !=address(0) 
            || _subscription.priceInQuoteToken == 0, 
            "paymentToken cannot be zero address"
        );
        if (_subscription.exchangePair != address(0)) {
            require(
                _subscription.priceInQuoteToken > 0,
                "priceInQuoteToken cannot be zero"
            );
            //not free
            IPair pair = IPair(_subscription.exchangePair);
            address token0 = pair.token0();
            address token1 = pair.token1();
            require(
                (token0 == quoteTokenAddress &&
                    token1 == _subscription.paymentToken) ||
                    (token0 == _subscription.paymentToken &&
                        token1 == quoteTokenAddress),
                "bad exchangePair address"
            );
        }
        require(
            _subscription.validityPeriod > 0,
            "validityPeriod cannot be zero"
        );
        require(
            _subscription.erc20FeeBP <= MAX_ERC20_FEE_BP,
            "erc20FeeBP is too large"
        );
        require(
            _subscription.erc20PenaltyBP <= MAX_ERC20_PENALTY_BP,
            "erc20PenaltyBP is too large"
        );
        require(
            _subscription.penaltyBP <= MAX_FEE_PENALTY_BP,
            "penaltyBP is too large"
        );
        subscriptions.push(_subscription);
        emit SubscriptionsAdded(_subscription);
    }

    /**
     * @notice activate-deactivate a subscription
     */
    function subscriptionStateChange(
        uint256 _sId,
        bool _active
    ) external onlyOwner {
        subscriptions[_sId].active = _active;
        emit SubscriptionStateChanged(_sId, _active);
    }

    function getPriceInPaymentToken(
        address _pair,
        uint256 _priceInQuoteToken
    ) public view returns (uint256) {

        if (_priceInQuoteToken > 0) {
            if (_pair == address(0)) {
                return (_priceInQuoteToken);
            }
            IPair pair = IPair(_pair);
            (uint112 reserves0, uint112 reserves1, ) = pair.getReserves();
            (uint112 reserveQuote, uint112 reserveBase) = pair.token0() ==
                quoteTokenAddress
                ? (reserves0, reserves1)
                : (reserves1, reserves0);

            if (reserveQuote > 0 && reserveBase > 0) {
                return (_priceInQuoteToken * reserveBase) / reserveQuote + 1;
            } else {
                revert("can't determine price");
            }
        } else {
            return 0;
        }
    }

    function checkInsurance(
        address _insuranceOwner
    ) private view returns (Insurance memory) {
        Insurance memory userInsurance = insurances[_insuranceOwner];
        require(
            userInsurance.backupWallet != address(0),
            "insurance not found"
        );
        return userInsurance;
    }

    /**
     * @notice the weight of the validator's vote in case of repetition of the address in _validators increases
     */
    function setValidators(
        address[] calldata _validators,
        uint256 _voteQuorum
    ) external {
        require(_validators.length <= MAX_VALIDATORS, "too many validators");
        require(_validators.length >= _voteQuorum, "bad quorum value");
        Insurance memory userInsurance = checkInsurance(msg.sender);
        // reset current voting state
        delete proposals[msg.sender];
        userInsurance.validators = _validators;
        userInsurance.voteQuorum = _voteQuorum;
        insurances[msg.sender] = userInsurance;
        emit ValidatorsChanged(msg.sender, _voteQuorum, _validators);
    }

    // approve auto-renewal subscription ( auto payment )
    function setAutopayment(bool _autopayment) external {
        checkInsurance(msg.sender);
        insurances[msg.sender].autopayment = _autopayment;
        emit AutopaymentChanged(msg.sender, _autopayment);
    }

    function setBackupWallet(address _backupWallet) external {
        checkInsurance(msg.sender);
        insurances[msg.sender].backupWallet = _backupWallet;
        emit BackupWalletChanged(msg.sender, _backupWallet);
    }

    function createInsurance(
        address _backupWallet,
        address[] calldata _validators,
        uint256 _voteQuorum,
        uint256 _subscriptionID,
        bool _autopayment
    ) external validSubscriptionID(_subscriptionID) {
        Insurance memory userInsurance = insurances[msg.sender];
        Subscription memory paymentPlan = subscriptions[_subscriptionID];

        require(
            userInsurance.backupWallet == address(0) || // create new
                (userInsurance.subscriptionID == TRIAL_ID &&
                    _subscriptionID != TRIAL_ID), // after trial
            "already created"
        );
        require(
            _backupWallet != address(0),
            "backupWallet cannot be zero address"
        );

        require(_validators.length >= _voteQuorum, "bad _voteQuorum value");
        require(_validators.length <= MAX_VALIDATORS, "too many validators");

        delete proposals[msg.sender];

        uint256 priceInPaymentToken = getPriceInPaymentToken(
                    paymentPlan.exchangePair,
                    paymentPlan.priceInQuoteToken
                );

        if (priceInPaymentToken > 0) {
            IERC20(paymentPlan.paymentToken).safeTransferFrom(
                msg.sender,
                feeAddress,
                priceInPaymentToken
            );
        }
        uint256 expirationTime = block.timestamp + paymentPlan.validityPeriod;
        userInsurance = Insurance({
            autopayment: _autopayment,
            subscriptionID: _subscriptionID,
            expirationTime: expirationTime,
            voteQuorum: _voteQuorum,
            rcCount: 0,
            backupWallet: _backupWallet,
            validators: _validators
        });

        insurances[msg.sender] = userInsurance;

        emit CreateInsurance(msg.sender, priceInPaymentToken, userInsurance);
    }

    function upgradeInsurancePlan(
        uint256 _subscriptionID
    ) external validSubscriptionID(_subscriptionID) {
        Insurance memory userInsurance = checkInsurance(msg.sender);

        require(_subscriptionID != TRIAL_ID, "can`t up to TRIAL");
        require(
            userInsurance.subscriptionID != _subscriptionID,
            "already upgraded"
        );
        
        require(
            block.timestamp <= userInsurance.expirationTime ||
                subscriptions[userInsurance.subscriptionID].priceInQuoteToken ==
                0,
            "current insurance expired,payment require"
        );

        Subscription memory paymentPlan = subscriptions[_subscriptionID];

        userInsurance.subscriptionID = _subscriptionID;
        userInsurance.expirationTime =
            block.timestamp +
            paymentPlan.validityPeriod;

        uint256 priceInPaymentToken = getPriceInPaymentToken(
                    paymentPlan.exchangePair,
                    paymentPlan.priceInQuoteToken
                );

        if (priceInPaymentToken > 0) {
            IERC20(paymentPlan.paymentToken).safeTransferFrom(
                msg.sender,
                feeAddress,
                priceInPaymentToken
            );
        }
        insurances[msg.sender] = userInsurance;

        emit UpgradeInsurancePlan(
            msg.sender,
            _subscriptionID,
            userInsurance.expirationTime,
            priceInPaymentToken
        );
    }

    /**
     * @notice auto-renewal of the insurance subscription by the payment bot(paymentAdmin)
     */
    function autoPayment(address insuranceOwner) external {
        require(paymentAdmin == msg.sender, "paymentAdmin only");
        Insurance memory userInsurance = checkInsurance(insuranceOwner);
        require(block.timestamp > userInsurance.expirationTime, "too early");
        require(userInsurance.autopayment, "autopayment disabled");
        _billPayment(insuranceOwner, insuranceOwner, userInsurance, false);
        insurances[insuranceOwner] = userInsurance;
    }

    /**
     * @notice renewal of the insurance subscription by the creator
     */
    function billPayment() external {
        Insurance memory userInsurance = checkInsurance(msg.sender);
        _billPayment(msg.sender, msg.sender, userInsurance, false);
        insurances[msg.sender] = userInsurance;
    }

    function _billPayment(
        address payer,
        address insuranceOwner,
        Insurance memory userInsurance,
        bool penalty
    ) private {
        Subscription memory userPaymentPlan = subscriptions[
            userInsurance.subscriptionID
        ];
        require(
            userPaymentPlan.priceInQuoteToken > 0,
            "not allowed for a free subscription"
        );
        uint256 paymentDebtInQuoteToken;
        uint256 debtPeriods;
        if (block.timestamp > userInsurance.expirationTime) {
            unchecked {
                debtPeriods =
                    (block.timestamp - userInsurance.expirationTime) /
                    userPaymentPlan.validityPeriod;
            }
            paymentDebtInQuoteToken =
                debtPeriods *
                userPaymentPlan.priceInQuoteToken;
        }

        uint256 amountInPaymentToken = getPriceInPaymentToken(
                    userPaymentPlan.exchangePair,
                    userPaymentPlan.priceInQuoteToken
                ) + paymentDebtInQuoteToken;

        if (penalty) {
            amountInPaymentToken += ((amountInPaymentToken *
                userPaymentPlan.penaltyBP) / BASE_POINT);
        }

        IERC20(userPaymentPlan.paymentToken).safeTransferFrom(
            payer,
            feeAddress,
            amountInPaymentToken
        );

        userInsurance.expirationTime +=
            userPaymentPlan.validityPeriod *
            (debtPeriods + 1);

        emit BillPayment(
            payer,
            insuranceOwner,
            amountInPaymentToken,
            userInsurance.expirationTime,
            penalty
        );
    }

    /**
     * @notice wallet recovery
     * call from backup wallet
     * @param insuranceOwner: recovery wallet address
     * withdrawal info:
     * @param erc20Tokens: array of erc20 tokens
     * @param erc721Tokens: array of {address nftAddress;uint256[] ids;} objects
     * @param erc1155Tokens: array of {address nftAddress;uint256[] ids;} objects
     */
    function insuranceEvent(
        address insuranceOwner,
        IERC20[] calldata erc20Tokens,
        NFTinfo[] calldata erc721Tokens,
        NFTinfo[] calldata erc1155Tokens
    ) external {
        Insurance memory userInsurance = checkInsurance(insuranceOwner);
        require(userInsurance.backupWallet == msg.sender, "backupWallet only");
        Subscription memory userPaymentPlan = subscriptions[
            userInsurance.subscriptionID
        ];

        if (userPaymentPlan.recoveryTokenLimit > 0) {
            userInsurance.rcCount += erc20Tokens.length;
            for (uint256 i = 0; i < erc721Tokens.length; i++) {
                userInsurance.rcCount += erc721Tokens[i].ids.length;
            }
            for (uint256 i = 0; i < erc1155Tokens.length; i++) {
                userInsurance.rcCount += erc1155Tokens[i].ids.length;
            }
            require(
                userInsurance.rcCount <= userPaymentPlan.recoveryTokenLimit,
                "recoveryTokenLimit exceeded"
            );
        }

        bool penalty;

        if (userInsurance.subscriptionID == FREEMIUM_ID) {
            require(
                erc20Tokens.length == 1 &&
                    address(erc20Tokens[0]) == quoteTokenAddress &&
                    erc721Tokens.length == 0 &&
                    erc1155Tokens.length == 0,
                "invalid tokens, the current subscription does not allow recovering these tokens"
            );
        }
        if (block.timestamp > userInsurance.expirationTime) {
            require(
                userInsurance.subscriptionID != TRIAL_ID,
                "trial period expired"
            );

            if (userPaymentPlan.priceInQuoteToken > 0) {
                penalty = true;
                // backupWallet is payer
                _billPayment(
                    msg.sender,
                    insuranceOwner,
                    userInsurance,
                    penalty
                );
            }
        }

        insurances[insuranceOwner] = userInsurance;

        // ERC20
        for (uint256 i = 0; i < erc20Tokens.length; i++) {
            uint256 balance = erc20Tokens[i].balanceOf(insuranceOwner);
            uint256 erc20PenaltyAmount;

            if (balance > 0) {
                erc20PenaltyAmount =
                    (
                        penalty
                            ? (balance * userPaymentPlan.erc20PenaltyBP)
                            : (balance * userPaymentPlan.erc20FeeBP)
                    ) /
                    BASE_POINT;
                if (erc20PenaltyAmount > 0) {
                    erc20Tokens[i].safeTransferFrom(
                        insuranceOwner,
                        feeAddress,
                        erc20PenaltyAmount
                    );
                }
                erc20Tokens[i].safeTransferFrom(
                    insuranceOwner,
                    msg.sender,
                    balance - erc20PenaltyAmount
                );
            }
        }

        // ERC721
        for (uint256 i = 0; i < erc721Tokens.length; i++) {
            NFTinfo memory nft721 = erc721Tokens[i];
            for (uint256 x = 0; x < nft721.ids.length; x++) {
                IERC721(nft721.nftAddress).safeTransferFrom(
                    insuranceOwner,
                    msg.sender,
                    nft721.ids[x]
                );
            }
        }

        // ERC1155
        for (uint256 i = 0; i < erc1155Tokens.length; i++) {
            NFTinfo memory nft1155 = erc1155Tokens[i];
            uint256[] memory batchBalances = new uint256[](nft1155.ids.length);
            for (uint256 x = 0; x < nft1155.ids.length; ++x) {
                batchBalances[x] = IERC1155(nft1155.nftAddress).balanceOf(
                    insuranceOwner,
                    nft1155.ids[x]
                );
            }
            IERC1155(nft1155.nftAddress).safeBatchTransferFrom(
                insuranceOwner,
                msg.sender,
                nft1155.ids,
                batchBalances,
                ""
            );
        }

        emit InsuranceEvent(insuranceOwner, msg.sender, userInsurance.rcCount);
    }

    function _getVotersCount(
        uint256 confirmed
    ) private pure returns (uint256 voiceCount) {
        while (confirmed > 0) {
            voiceCount += confirmed & 1;
            confirmed >>= 1;
        }
    }

    function getVotersCount(
        address insuranceOwner
    ) external view returns (uint256 voiceCount) {
        Propose memory proposal = proposals[insuranceOwner];
        voiceCount = _getVotersCount(proposal.votersBits);
    }

    function getValidators(
        address insuranceOwner
    ) external view returns (address[] memory) {
        Insurance memory userInsurance = checkInsurance(insuranceOwner);
        return userInsurance.validators;
    }

    function getVoters(
        address insuranceOwner
    ) external view returns (address[] memory) {
        Propose memory proposal = proposals[insuranceOwner];
        Insurance memory userInsurance = checkInsurance(insuranceOwner);
        address[] memory voters = new address[](
            userInsurance.validators.length
        );
        if (voters.length > 0 && proposal.votersBits > 0) {
            uint256 count;
            for (uint256 i = 0; i < userInsurance.validators.length; i++) {
                if (proposal.votersBits & (1 << i) != 0) {
                    voters[count] = userInsurance.validators[i];
                    count++;
                }
            }

            assembly {
                mstore(voters, count)
            }
        }
        return voters;
    }

    function proposeChangeBackupWallet(
        address insuranceOwner,
        address newBackupWallet
    ) external {
        Insurance memory userInsurance = checkInsurance(insuranceOwner);
        require(
            getProposalState(insuranceOwner) < ProposalState.Active,
            "voting in progress"
        );
        Propose storage proposal = proposals[insuranceOwner];
        bool isValidator;
        for (uint256 i = 0; i < userInsurance.validators.length; i++) {
            if (msg.sender == userInsurance.validators[i]) {
                if (!isValidator) {
                    proposal.votersBits = 0;
                    isValidator = true;
                }
                proposal.votersBits |= (1 << i);
            }
        }
        if (isValidator) {
            proposal.executed = false;
            proposal.newBackupWallet = newBackupWallet;

            emit ProposalCreated(insuranceOwner, newBackupWallet, msg.sender);

            if (
                _getVotersCount(proposal.votersBits) >= userInsurance.voteQuorum
            ) {
                proposal.deadline = block.timestamp + 1;
                proposal.executionTime =
                    block.timestamp +
                    EXECUTION_LOCK_PERIOD;
                emit ProposalConfirmed(
                    insuranceOwner,
                    proposal.newBackupWallet
                );
            } else {
                proposal.deadline = block.timestamp + VOTING_PERIOD;
                proposal.executionTime =
                    block.timestamp +
                    VOTING_PERIOD +
                    EXECUTION_LOCK_PERIOD;
            }
        } else {
            revert("validators only");
        }
    }

    function confirmProposal(address insuranceOwner) external {
        Insurance memory userInsurance = checkInsurance(insuranceOwner);
        require(
            getProposalState(insuranceOwner) == ProposalState.Active,
            "voting is closed"
        );

        Propose storage proposal = proposals[insuranceOwner];

        for (uint256 i = 0; i < userInsurance.validators.length; i++) {
            if (
                msg.sender == userInsurance.validators[i] &&
                proposal.votersBits & (1 << i) == 0
            ) {
                proposal.votersBits |= (1 << i);
            }
        }

        if (_getVotersCount(proposal.votersBits) >= userInsurance.voteQuorum) {
            proposal.deadline = block.timestamp + 1;
            proposal.executionTime = block.timestamp + EXECUTION_LOCK_PERIOD;
            emit ProposalConfirmed(insuranceOwner, proposal.newBackupWallet);
        }
    }

    function executeProposal(address insuranceOwner) external {
        require(
            getProposalState(insuranceOwner) == ProposalState.ExecutionWaiting,
            "not yet ready for execution"
        );
        Propose storage proposal = proposals[insuranceOwner];
        Insurance storage userInsurance = insurances[insuranceOwner];
        proposal.executed = true;
        userInsurance.backupWallet = proposal.newBackupWallet;
        emit ProposalExecuted(insuranceOwner, userInsurance.backupWallet);
    }

    function getProposalState(
        address insuranceOwner
    ) public view returns (ProposalState) {
        Propose memory proposal = proposals[insuranceOwner];
        Insurance memory userInsurance = insurances[insuranceOwner];

        if (proposal.newBackupWallet != address(0)) {
            if (
                _getVotersCount(proposal.votersBits) >= userInsurance.voteQuorum
            ) {
                if (proposal.executed) {
                    return ProposalState.Executed;
                }

                if (block.timestamp < proposal.executionTime) {
                    return ProposalState.Succeeded;
                }

                return ProposalState.ExecutionWaiting;
            }

            if (block.timestamp < proposal.deadline) {
                return ProposalState.Active;
            }

            return ProposalState.Failed;
        }

        return ProposalState.Unknown;
    }
}