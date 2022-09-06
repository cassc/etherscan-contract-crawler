// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./CyanWrappedNFTV1.sol";
import "./CyanVaultV1.sol";

contract CyanPaymentPlanV1 is
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using ECDSAUpgradeable for bytes32;

    bytes32 public constant CYAN_ROLE = keccak256("CYAN_ROLE");
    uint256 private _claimableServiceFee;
    address private _cyanSigner;

    event CreatedBNPL(
        address indexed wNFTContract,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 interestRate,
        uint256 serviceFeeRate
    );
    event FundedBNPL(address indexed wNFTContract, uint256 indexed tokenId);
    event ActivatedBNPL(address indexed wNFTContract, uint256 indexed tokenId);
    event ActivatedAdminFundedBNPL(
        address indexed wNFTContract,
        uint256 indexed tokenId
    );
    event RejectedBNPL(address indexed wNFTContract, uint256 indexed tokenId);
    event CreatedPAWN(
        address indexed wNFTContract,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 interestRate,
        uint256 serviceFeeRate
    );
    event LiquidatedPaymentPlan(
        address indexed wNFTContract,
        uint256 indexed tokenId,
        uint256 estimatedPrice,
        uint256 unpaidAmount,
        address lastOwner
    );
    event Paid(
        address indexed wNFTContract,
        uint256 indexed tokenId,
        address indexed from,
        uint256 amount
    );
    event Completed(
        address indexed wNFTContract,
        uint256 indexed tokenId,
        address indexed from,
        uint256 amount,
        address receiver
    );

    enum PaymentPlanStatus {
        BNPL_CREATED,
        BNPL_FUNDED,
        BNPL_ACTIVE,
        BNPL_DEFAULTED,
        PAWN_ACTIVE,
        PAWN_DEFAULTED
    }
    struct PaymentPlan {
        uint256 amount;
        uint256 interestRate;
        uint256 createdDate;
        uint256 term;
        uint256 serviceFeeRate;
        address createdUserAddress;
        uint8 totalNumberOfPayments;
        uint8 counterPaidPayments;
        PaymentPlanStatus status;
    }

    mapping(address => mapping(uint256 => PaymentPlan)) public _paymentPlan;

    function initialize(address cyanSigner, address cyanSuperAdmin)
        external
        initializer
    {
        require(cyanSigner != address(0), "Cyan signer address cannot be zero");
        require(
            cyanSuperAdmin != address(0),
            "Cyan super admin address cannot be zero"
        );

        _claimableServiceFee = 0;
        _cyanSigner = cyanSigner;
        _setupRole(DEFAULT_ADMIN_ROLE, cyanSuperAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Create BNPL payment plan
     * @param wNFTContract Wrapped NFT contract address
     * @param wNFTTokenId Wrapped NFT token ID
     * @param amount Original price of the token
     * @param interestRate Cyan interest rate
     * @param signedBlockNum Signed block number
     * @param term Term of payment plan in seconds
     * @param totalNumberOfPayments Total number of payments required for completion
     * @param signature Signature signed by Cyan signer
     */
    function createBNPLPaymentPlan(
        address wNFTContract,
        uint256 wNFTTokenId,
        uint256 amount,
        uint256 interestRate,
        uint256 signedBlockNum,
        uint256 term,
        uint256 serviceFeeRate,
        uint8 totalNumberOfPayments,
        bytes memory signature
    ) external payable nonReentrant {
        verifySignature(
            wNFTContract,
            wNFTTokenId,
            amount,
            interestRate,
            signedBlockNum,
            term,
            serviceFeeRate,
            totalNumberOfPayments,
            signature
        );
        require(
            signedBlockNum <= block.number,
            "Signed block number must be older"
        );
        require(signedBlockNum + 50 >= block.number, "Signature expired");
        require(
            serviceFeeRate <= 300,
            "Service fee rate must be less than 3 percent"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].totalNumberOfPayments == 0,
            "Payment plan already exists"
        );
        require(amount > 0, "Price of token is non-positive");
        require(interestRate > 0, "Interest rate is non-positive");
        require(msg.value > 0, "Downpayment amount is non-positive");
        require(term > 0, "Term is non-positive");
        require(
            totalNumberOfPayments > 0,
            "Total number of payments is non-positive"
        );

        CyanWrappedNFTV1 _cyanWrappedNFTV1 = CyanWrappedNFTV1(wNFTContract);
        require(
            !_cyanWrappedNFTV1.exists(wNFTTokenId),
            "Token is already wrapped"
        );

        _paymentPlan[wNFTContract][wNFTTokenId] = PaymentPlan(
            amount, // amount
            interestRate, // interestRate
            block.timestamp, // createdDate
            term, // term
            serviceFeeRate, // serviceFeeRate
            msg.sender, // createdUserAddress
            totalNumberOfPayments, // totalNumberOfPayments
            0, // counterPaidPayments
            PaymentPlanStatus.BNPL_CREATED // status
        );

        (, , , uint256 currentPayment, ) = getNextPayment(
            wNFTContract,
            wNFTTokenId
        );
        require(currentPayment == msg.value, "Downpayment amount incorrect");

        _paymentPlan[wNFTContract][wNFTTokenId].counterPaidPayments++;

        emit CreatedBNPL(
            wNFTContract,
            wNFTTokenId,
            amount,
            interestRate,
            serviceFeeRate
        );
    }

    /**
     * @notice Lending ETH from Vault for BNPL payment plan
     * @param wNFTContract Wrapped NFT contract address
     * @param wNFTTokenId Wrapped NFT token ID
     */
    function fundBNPL(address wNFTContract, uint256 wNFTTokenId)
        external
        nonReentrant
        onlyRole(CYAN_ROLE)
    {
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].totalNumberOfPayments != 0,
            "No payment plan found"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].counterPaidPayments == 1,
            "Only downpayment must be paid"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].status ==
                PaymentPlanStatus.BNPL_CREATED,
            "BNPL payment plan must be at CREATED stage"
        );
        CyanWrappedNFTV1 _cyanWrappedNFTV1 = CyanWrappedNFTV1(wNFTContract);
        require(!_cyanWrappedNFTV1.exists(wNFTTokenId), "Wrapped token exist");

        _paymentPlan[wNFTContract][wNFTTokenId].status = PaymentPlanStatus
            .BNPL_FUNDED;

        address _cyanVaultAddress = _cyanWrappedNFTV1.getCyanVaultAddress();
        CyanVaultV1 _cyanVaultV1 = CyanVaultV1(payable(_cyanVaultAddress));
        _cyanVaultV1.lend(
            msg.sender,
            _paymentPlan[wNFTContract][wNFTTokenId].amount
        );

        emit FundedBNPL(wNFTContract, wNFTTokenId);
    }

    /**
     * @notice Activating a BNPL payment plan
     * @param wNFTContract Wrapped NFT contract address
     * @param wNFTTokenId Wrapped NFT token ID
     */
    function activateBNPL(address wNFTContract, uint256 wNFTTokenId)
        external
        nonReentrant
        onlyRole(CYAN_ROLE)
    {
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].totalNumberOfPayments != 0,
            "No payment plan found"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].counterPaidPayments == 1,
            "Only downpayment must be paid"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].status ==
                PaymentPlanStatus.BNPL_FUNDED,
            "BNPL payment plan must be at FUNDED stage"
        );
        CyanWrappedNFTV1 _cyanWrappedNFTV1 = CyanWrappedNFTV1(wNFTContract);
        require(!_cyanWrappedNFTV1.exists(wNFTTokenId), "Wrapped token exist");

        (
            uint256 payAmountForCollateral,
            uint256 payAmountForInterest,
            uint256 payAmountForService,
            ,

        ) = getNextPayment(wNFTContract, wNFTTokenId);

        _paymentPlan[wNFTContract][wNFTTokenId].status = PaymentPlanStatus
            .BNPL_ACTIVE;

        _cyanWrappedNFTV1.wrap(
            msg.sender,
            _paymentPlan[wNFTContract][wNFTTokenId].createdUserAddress,
            wNFTTokenId
        );

        _claimableServiceFee += payAmountForService;

        address _cyanVaultAddress = _cyanWrappedNFTV1.getCyanVaultAddress();
        transferEarnedAmountToCyanVault(
            _cyanVaultAddress,
            payAmountForCollateral,
            payAmountForInterest
        );

        emit ActivatedBNPL(wNFTContract, wNFTTokenId);
    }

    /**
     * @notice Activating a BNPL payment plan that admin funded
     * @param wNFTContract Wrapped NFT contract address
     * @param wNFTTokenId Wrapped NFT token ID
     */
    function activateAdminFundedBNPL(address wNFTContract, uint256 wNFTTokenId)
        external
        nonReentrant
        onlyRole(CYAN_ROLE)
    {
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].totalNumberOfPayments != 0,
            "No payment plan found"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].counterPaidPayments == 1,
            "Only downpayment must be paid"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].status ==
                PaymentPlanStatus.BNPL_CREATED,
            "BNPL payment plan must be at CREATED stage"
        );
        CyanWrappedNFTV1 _cyanWrappedNFTV1 = CyanWrappedNFTV1(wNFTContract);
        require(!_cyanWrappedNFTV1.exists(wNFTTokenId), "Wrapped token exist");

        (
            uint256 payAmountForCollateral,
            uint256 payAmountForInterest,
            uint256 payAmountForService,
            ,

        ) = getNextPayment(wNFTContract, wNFTTokenId);

        _paymentPlan[wNFTContract][wNFTTokenId].status = PaymentPlanStatus
            .BNPL_ACTIVE;

        _cyanWrappedNFTV1.wrap(
            msg.sender,
            _paymentPlan[wNFTContract][wNFTTokenId].createdUserAddress,
            wNFTTokenId
        );

        _claimableServiceFee += payAmountForService;

        address _cyanVaultAddress = _cyanWrappedNFTV1.getCyanVaultAddress();
        CyanVaultV1 _cyanVaultV1 = CyanVaultV1(payable(_cyanVaultAddress));
        // Admin already funded the plan, so Vault is transfering equal amount of ETH to admin.
        _cyanVaultV1.lend(
            msg.sender,
            _paymentPlan[wNFTContract][wNFTTokenId].amount
        );
        _cyanVaultV1.earn{value: payAmountForCollateral + payAmountForInterest}(
            payAmountForCollateral,
            payAmountForInterest
        );

        emit ActivatedAdminFundedBNPL(wNFTContract, wNFTTokenId);
    }

    /**
     * @notice Create PAWN payment plan
     * @param wNFTContract Wrapped NFT contract address
     * @param wNFTTokenId Wrapped NFT token ID
     * @param amount Collateral amount
     * @param interestRate Cyan interest rate
     * @param signedBlockNum Signed block number
     * @param term Term of payment plan in seconds
     * @param totalNumberOfPayments Total number of payments required for completion
     * @param signature Signature signed by Cyan signer
     */
    function createPAWNPaymentPlan(
        address wNFTContract,
        uint256 wNFTTokenId,
        uint256 amount,
        uint256 interestRate,
        uint256 signedBlockNum,
        uint256 term,
        uint256 serviceFeeRate,
        uint8 totalNumberOfPayments,
        bytes memory signature
    ) external nonReentrant {
        verifySignature(
            wNFTContract,
            wNFTTokenId,
            amount,
            interestRate,
            signedBlockNum,
            term,
            serviceFeeRate,
            totalNumberOfPayments,
            signature
        );
        require(
            signedBlockNum <= block.number,
            "Signed block number must be older"
        );
        require(signedBlockNum + 50 >= block.number, "Signature expired");
        require(
            serviceFeeRate <= 300,
            "Service fee rate must be less than 3 percent"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].totalNumberOfPayments == 0,
            "Payment plan already exists"
        );
        require(amount > 0, "Collateral amount is non-positive");
        require(interestRate > 0, "Interest rate is non-positive");
        require(term > 0, "Term is non-positive");
        require(
            totalNumberOfPayments > 0,
            "Total number of payments is non-positive"
        );

        CyanWrappedNFTV1 _cyanWrappedNFTV1 = CyanWrappedNFTV1(wNFTContract);
        require(
            !_cyanWrappedNFTV1.exists(wNFTTokenId),
            "Token is already wrapped"
        );

        _paymentPlan[wNFTContract][wNFTTokenId] = PaymentPlan(
            amount, // amount
            interestRate, // interestRate
            block.timestamp + term, // createdDate
            term, // term
            serviceFeeRate, // serviceFeeRate
            msg.sender, // createdUserAddress
            totalNumberOfPayments, // totalNumberOfPayments
            0, // counterPaidPayments
            PaymentPlanStatus.PAWN_ACTIVE // status
        );

        _cyanWrappedNFTV1.wrap(msg.sender, msg.sender, wNFTTokenId);

        address _cyanVaultAddress = _cyanWrappedNFTV1.getCyanVaultAddress();
        CyanVaultV1 _cyanVaultV1 = CyanVaultV1(payable(_cyanVaultAddress));
        _cyanVaultV1.lend(msg.sender, amount);

        emit CreatedPAWN(
            wNFTContract,
            wNFTTokenId,
            amount,
            interestRate,
            serviceFeeRate
        );
    }

    /**
     * @notice Liquidate defaulted payment plan
     * @param wNFTContract Wrapped NFT contract address
     * @param wNFTTokenId Wrapped NFT token ID
     * @param estimatedTokenValue Estimated value of defaulted NFT
     */
    function liquidate(
        address wNFTContract,
        uint256 wNFTTokenId,
        uint256 estimatedTokenValue
    ) external nonReentrant onlyRole(CYAN_ROLE) {
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].totalNumberOfPayments != 0,
            "No payment plan found"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].totalNumberOfPayments >
                _paymentPlan[wNFTContract][wNFTTokenId].counterPaidPayments,
            "Total payment done"
        );
        (, , , , uint256 dueDate) = getNextPayment(wNFTContract, wNFTTokenId);

        require(dueDate < block.timestamp, "Next payment is still due");

        uint256 unpaidAmount = 0;
        for (
            ;
            // Until the last payment
            _paymentPlan[wNFTContract][wNFTTokenId].counterPaidPayments <
            _paymentPlan[wNFTContract][wNFTTokenId].totalNumberOfPayments;
            _paymentPlan[wNFTContract][wNFTTokenId].counterPaidPayments++
        ) {
            (uint256 payAmountForCollateral, , , , ) = getNextPayment(
                wNFTContract,
                wNFTTokenId
            );
            unpaidAmount += payAmountForCollateral;
        }
        require(unpaidAmount > 0, "Unpaid is non-positive");

        CyanWrappedNFTV1 _cyanWrappedNFTV1 = CyanWrappedNFTV1(wNFTContract);
        require(
            _cyanWrappedNFTV1.exists(wNFTTokenId),
            "Wrapped token does not exist"
        );
        address lastOwner = _cyanWrappedNFTV1.ownerOf(wNFTTokenId);
        _cyanWrappedNFTV1.unwrap(
            wNFTTokenId,
            /* isDefaulted = */
            true
        );
        delete _paymentPlan[wNFTContract][wNFTTokenId];

        address _cyanVaultAddress = _cyanWrappedNFTV1.getCyanVaultAddress();
        require(_cyanVaultAddress != address(0), "Cyan vault has zero address");
        CyanVaultV1 _cyanVaultV1 = CyanVaultV1(payable(_cyanVaultAddress));
        _cyanVaultV1.nftDefaulted(unpaidAmount, estimatedTokenValue);

        emit LiquidatedPaymentPlan(
            wNFTContract,
            wNFTTokenId,
            estimatedTokenValue,
            unpaidAmount,
            lastOwner
        );
    }

    /**
     * @notice Make a payment for the payment plan
     * @param wNFTContract Wrapped NFT contract address
     * @param wNFTTokenId Wrapped NFT token ID
     */
    function pay(address wNFTContract, uint256 wNFTTokenId)
        external
        payable
        nonReentrant
    {
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].totalNumberOfPayments != 0,
            "No payment plan found"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].totalNumberOfPayments >
                _paymentPlan[wNFTContract][wNFTTokenId].counterPaidPayments,
            "Total payment done"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].status ==
                PaymentPlanStatus.BNPL_ACTIVE ||
                _paymentPlan[wNFTContract][wNFTTokenId].status ==
                PaymentPlanStatus.PAWN_ACTIVE,
            "Payment plan must be at ACTIVE stage"
        );

        (
            uint256 payAmountForCollateral,
            uint256 payAmountForInterest,
            uint256 payAmountForService,
            uint256 currentPayment,
            uint256 dueDate
        ) = getNextPayment(wNFTContract, wNFTTokenId);

        require(currentPayment == msg.value, "Wrong payment amount");
        require(dueDate >= block.timestamp, "Payment due date is passed");
        CyanWrappedNFTV1 _cyanWrappedNFTV1 = CyanWrappedNFTV1(wNFTContract);
        require(
            _cyanWrappedNFTV1.exists(wNFTTokenId),
            "Wrapped token does not exist"
        );
        _paymentPlan[wNFTContract][wNFTTokenId].counterPaidPayments++;
        _claimableServiceFee += payAmountForService;

        address _cyanVaultAddress = _cyanWrappedNFTV1.getCyanVaultAddress();
        transferEarnedAmountToCyanVault(
            _cyanVaultAddress,
            payAmountForCollateral,
            payAmountForInterest
        );
        if (
            _paymentPlan[wNFTContract][wNFTTokenId].counterPaidPayments ==
            _paymentPlan[wNFTContract][wNFTTokenId].totalNumberOfPayments
        ) {
            address receiver = _cyanWrappedNFTV1.ownerOf(wNFTTokenId);
            _cyanWrappedNFTV1.unwrap(
                wNFTTokenId,
                /* isDefaulted = */
                false
            );
            delete _paymentPlan[wNFTContract][wNFTTokenId];
            emit Completed(
                wNFTContract,
                wNFTTokenId,
                msg.sender,
                msg.value,
                receiver
            );
        } else {
            emit Paid(wNFTContract, wNFTTokenId, msg.sender, msg.value);
        }
    }

    /**
     * @notice Reject the payment plan
     * @param wNFTContract Wrapped NFT contract address
     * @param wNFTTokenId Wrapped NFT token ID
     */
    function rejectBNPLPaymentPlan(address wNFTContract, uint256 wNFTTokenId)
        external
        nonReentrant
        onlyRole(CYAN_ROLE)
    {
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].totalNumberOfPayments != 0,
            "No payment plan found"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].counterPaidPayments == 1,
            "Payment done other than downpayment for this plan"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].status ==
                PaymentPlanStatus.BNPL_CREATED,
            "BNPL payment plan must be at CREATED stage"
        );
        CyanWrappedNFTV1 _cyanWrappedNFTV1 = CyanWrappedNFTV1(wNFTContract);
        require(!_cyanWrappedNFTV1.exists(wNFTTokenId), "Wrapped token exists");

        (, , , uint256 currentPayment, ) = getNextPayment(
            wNFTContract,
            wNFTTokenId
        );

        // Returning downpayment to created user address
        payable(_paymentPlan[wNFTContract][wNFTTokenId].createdUserAddress)
            .transfer(currentPayment);
        delete _paymentPlan[wNFTContract][wNFTTokenId];

        emit RejectedBNPL(wNFTContract, wNFTTokenId);
    }

    /**
     * @notice Reject the payment plan after FUNDED
     * @param wNFTContract Wrapped NFT contract address
     * @param wNFTTokenId Wrapped NFT token ID
     */
    function rejectBNPLPaymentPlanAfterFunded(
        address wNFTContract,
        uint256 wNFTTokenId
    ) external payable nonReentrant onlyRole(CYAN_ROLE) {
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].totalNumberOfPayments != 0,
            "No payment plan found"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].counterPaidPayments == 1,
            "Payment done other than downpayment for this plan"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].status ==
                PaymentPlanStatus.BNPL_FUNDED,
            "BNPL payment plan must be at FUNDED stage"
        );
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].amount == msg.value,
            "Wrong fund return amount"
        );
        CyanWrappedNFTV1 _cyanWrappedNFTV1 = CyanWrappedNFTV1(wNFTContract);
        require(!_cyanWrappedNFTV1.exists(wNFTTokenId), "Wrapped token exists");

        (, , , uint256 currentPayment, ) = getNextPayment(
            wNFTContract,
            wNFTTokenId
        );

        // Returning downpayment to created user address
        payable(_paymentPlan[wNFTContract][wNFTTokenId].createdUserAddress)
            .transfer(currentPayment);
        delete _paymentPlan[wNFTContract][wNFTTokenId];

        // Returning funded amount back to Vault
        address _cyanVaultAddress = _cyanWrappedNFTV1.getCyanVaultAddress();
        transferEarnedAmountToCyanVault(_cyanVaultAddress, msg.value, 0);

        emit RejectedBNPL(wNFTContract, wNFTTokenId);
    }

    /**
     * @notice Calculate payments for given amount and interest rate
     * @param amount amount of collateral
     * @param interestRate interest rate
     * @param numOfPayment Number of payments
     * @return First payment amount for collateral
     * @return Total payment amount for interest fee
     * @return First payment amount for interest fee
     * @return Total payment amount for service fee
     * @return First payment amount for service fee
     * @return First payment amount
     */
    function calculateIndividualPayments(
        uint256 amount,
        uint256 interestRate,
        uint256 serviceFeeRate,
        uint8 numOfPayment
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // Payment amount for collateral
        uint256 payAmountForCollateral = amount / numOfPayment;

        // Calculating interest fee, Note that interest rate is x100
        uint256 interestFee = (amount * interestRate) / 10000;
        // Payment amount for interest fee payment
        uint256 payAmountForInterest = interestFee / numOfPayment;

        // Calculating service fee, Note that service fee rate is x100
        uint256 serviceFee = (amount * serviceFeeRate) / 10000;
        // Payment amount for service fee payment
        uint256 payAmountForService = serviceFee / numOfPayment;

        // First amount
        uint256 currentPayment = payAmountForCollateral +
            payAmountForInterest +
            payAmountForService;

        return (
            payAmountForCollateral,
            interestFee,
            payAmountForInterest,
            serviceFee,
            payAmountForService,
            currentPayment
        );
    }

    /**
     * @notice Return next payment info
     * @param wNFTContract Wrapped NFT contract address
     * @param wNFTTokenId Wrapped NFT token ID
     * @return Next payment amount for collateral
     * @return Next payment amount for interest fee
     * @return Next payment amount for service fee
     * @return Next payment amount
     * @return Due date
     */
    function getNextPayment(address wNFTContract, uint256 wNFTTokenId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].totalNumberOfPayments != 0,
            "No payment plan found"
        );
        PaymentPlan memory plan = _paymentPlan[wNFTContract][wNFTTokenId];
        (
            uint256 payAmountForCollateral,
            uint256 interestFee,
            uint256 payAmountForInterest,
            uint256 serviceFee,
            uint256 payAmountForService,
            uint256 currentPayment
        ) = calculateIndividualPayments(
                plan.amount,
                plan.interestRate,
                plan.serviceFeeRate,
                plan.totalNumberOfPayments
            );
        if (plan.counterPaidPayments + 1 == plan.totalNumberOfPayments) {
            // Last payment
            payAmountForCollateral =
                plan.amount -
                (payAmountForCollateral * plan.counterPaidPayments);
            payAmountForInterest =
                interestFee -
                (payAmountForInterest * plan.counterPaidPayments);
            payAmountForService =
                serviceFee -
                (payAmountForService * plan.counterPaidPayments);
            currentPayment =
                payAmountForCollateral +
                payAmountForInterest +
                payAmountForService;
        }

        return (
            payAmountForCollateral,
            payAmountForInterest,
            payAmountForService,
            currentPayment,
            plan.createdDate + plan.counterPaidPayments * plan.term
        );
    }

    /**
     * @notice Transfer earned amount to Cyan Vault
     * @param cyanVaultAddress Original price of the token
     * @param paidTokenPayment Paid token payment
     * @param paidInterestFee Paid interest fee
     */
    function transferEarnedAmountToCyanVault(
        address cyanVaultAddress,
        uint256 paidTokenPayment,
        uint256 paidInterestFee
    ) private {
        require(cyanVaultAddress != address(0), "Cyan vault has zero address");
        CyanVaultV1 _cyanVaultV1 = CyanVaultV1(payable(cyanVaultAddress));
        _cyanVaultV1.earn{value: paidTokenPayment + paidInterestFee}(
            paidTokenPayment,
            paidInterestFee
        );
    }

    /**
     * @notice Return expected payment plan for given price and interest rate
     * @param amount Original price of the token
     * @param interestRate Interest rate
     * @param numOfPayment Number of payments
     * @return Original price of the token
     * @return Interest Fee
     * @return Service Fee
     * @return Downpayment amount
     * @return Total payment amount
     */
    function getExpectedPaymentPlan(
        uint256 amount,
        uint256 interestRate,
        uint256 serviceFeeRate,
        uint8 numOfPayment
    )
        external
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            ,
            uint256 interestFee,
            ,
            uint256 serviceFee,
            ,
            uint256 currentPayment
        ) = calculateIndividualPayments(
                amount,
                interestRate,
                serviceFeeRate,
                numOfPayment
            );

        uint256 totalPayment = amount + interestFee + serviceFee;
        return (amount, interestFee, serviceFee, currentPayment, totalPayment);
    }

    /**
     * @notice Check if payment plan is pending
     * @param wNFTContract Wrapped NFT contract address
     * @param wNFTTokenId Wrapped NFT token ID
     * @return PaymentPlanStatus
     */
    function getPaymentPlanStatus(address wNFTContract, uint256 wNFTTokenId)
        external
        view
        returns (PaymentPlanStatus)
    {
        require(
            _paymentPlan[wNFTContract][wNFTTokenId].totalNumberOfPayments != 0,
            "No payment plan found"
        );

        (, , , , uint256 dueDate) = getNextPayment(wNFTContract, wNFTTokenId);
        bool isDefaulted = block.timestamp > dueDate;

        if (isDefaulted) {
            if (
                _paymentPlan[wNFTContract][wNFTTokenId].status ==
                PaymentPlanStatus.PAWN_ACTIVE
            ) {
                return PaymentPlanStatus.PAWN_DEFAULTED;
            }
            return PaymentPlanStatus.BNPL_DEFAULTED;
        }
        return _paymentPlan[wNFTContract][wNFTTokenId].status;
    }

    /**
     * @notice Getting claimable service fee amount
     */
    function getClaimableServiceFee()
        external
        view
        onlyRole(CYAN_ROLE)
        returns (uint256)
    {
        return _claimableServiceFee;
    }

    /**
     * @notice Claiming collected service fee amount
     */
    function claimServiceFee()
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        payable(msg.sender).transfer(_claimableServiceFee);
        _claimableServiceFee = 0;
    }

    function verifySignature(
        address wNFTContract,
        uint256 wNFTTokenId,
        uint256 amount,
        uint256 interestRate,
        uint256 timestamp,
        uint256 term,
        uint256 serviceFeeRate,
        uint8 totalNumberOfPayments,
        bytes memory signature
    ) internal view {
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                wNFTContract,
                wNFTTokenId,
                amount,
                interestRate,
                timestamp,
                term,
                serviceFeeRate,
                totalNumberOfPayments
            )
        );
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)
        );
        require(
            signedHash.recover(signature) == _cyanSigner,
            "Invalid signature"
        );
    }

    function updateCyanSignerAddress(address cyanSigner)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(cyanSigner != address(0), "Zero Cyan Signer address");
        _cyanSigner = cyanSigner;
    }
}