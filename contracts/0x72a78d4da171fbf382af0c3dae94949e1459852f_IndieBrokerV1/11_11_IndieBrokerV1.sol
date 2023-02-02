// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/utils/cryptography/EIP712.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "./IUSDC.sol";

/**
 * @title IndieBrokerV1
 * @author IndieDAO
 * @notice The Indie Protocol contract
 */
contract IndieBrokerV1 is EIP712, Ownable, Pausable, ReentrancyGuard {
    struct Project {
        uint256 projectId;
        address leadAddress;
        address clientAddress;
        address salesAddress;
    }

    struct SprintPayments {
        uint256 totalAmount;
        uint256 totalTreasuryAmount;
        uint256 totalCashVestingAmount;
        uint256 totalLeadAmount;
        uint256 totalSalesAmount;
        uint256[] payeeAmounts;
        uint256[] treasuryAmounts;
        uint256[] leadAmounts;
        uint256[] salesAmounts;
        uint256[] cashVestingAmounts;
    }

    error ExceededMaxFees();
    error ZeroAddress();
    error InvalidFee();
    error FeeTooLow();
    error FeeTooHigh();
    error NotAuthorized();
    error PayeeAmountMismatch();
    error SprintAlreadyCompleted();
    error InvalidClientSignature();
    error ProjectAlreadyExists();
    error ProjectNotFound();
    error InvalidProjectId();
    error InvalidSprintId();
    error LeadNotOnAllowList();
    error InsufficientBalance();

    event StartProject(
        uint256 indexed projectId, address indexed leadAddress, address indexed clientAddress, address salesAddress
    );

    event CompleteProjectSprint(uint256 indexed projectId, uint256 indexed sprintId, uint256 totalAmount);

    event SendDeposit(uint256 indexed projectId, address indexed sender, uint256 amount);

    event DistributePayment(
        address indexed payee,
        uint256 indexed projectId,
        uint256 totalAmount,
        uint256 payeeAmount,
        uint256 treasuryAmount,
        uint256 leadAmount,
        uint256 salesAmount,
        uint256 cashVestingAmount
    );

    event SetFee(Fees indexed f, uint256 fee);

    event SetFeeRecipient(Fees indexed f, address recipient);

    event ReassignProjectLead(uint256 indexed projectId, address newLeadAddress);

    event ReassignProjectSales(uint256 indexed projectId, address newSalesAddress);

    event ReassignProjectClient(uint256 indexed projectId, address newClientAddress);

    event SetIndividualTreasuryFee(address indexed addr, uint256 fee);

    event SetMinMaxIndividualTreasuryFees(uint256 minFee, uint256 maxFee);

    event SetAllowedLead(address indexed addr, bool allowed);

    event WithdrawFromProject(uint256 indexed projectId, uint256 amount, address indexed recipient);

    enum Fees {
        Treasury,
        Sales,
        Lead,
        CashVesting
    }

    /**
     * @notice Mapping of project IDs to project structs
     */
    mapping(uint256 => Project) public projects;

    /**
     * @notice Mapping of project IDs to project balances
     * @dev projectId => USDC balance
     */
    mapping(uint256 => uint256) public projectBalances;

    /**
     * @notice Mapping of project/sprint tuples to project sprint completion status
     * @dev projectId => sprintId => completed
     */
    mapping(uint256 => mapping(uint256 => bool)) public completedSprints;

    /**
     * @notice Mapping of fee types to fee percentages
     * @dev Fees => fee percentage
     */
    mapping(Fees => uint256) public fees;

    /**
     * @notice Mapping of fee types to fee recipients
     * @dev Fees => fee recipient address
     */
    mapping(Fees => address) public feeRecipients;

    /**
     * @notice Mapping of individual treasury fees
     * @dev address => fee percentage
     */
    mapping(address => uint256) public individualTreasuryFees;

    /**
     * @notice Mapping of allowed leads
     * @dev address => allowed
     */
    mapping(address => bool) public allowedLeads;

    /**
     * @notice Reference to the USDC contract
     */
    IUSDC public usdc;

    /**
     * @notice The minimum possible individual treasury fee
     */
    uint256 public minIndividualTreasuryFee = 20_00; // 20%

    /**
     * @notice The maximum possible individual treasury fee
     */
    uint256 public maxIndividualTreasuryFee = 20_00; // 20%

    uint256 internal constant MAX_FEES = 100_00; // The sum of fees cannot exceed 100%
    uint256 internal constant FEE_DENOMINATOR = 100_00;

    /**
     * @notice Constructor
     * @param usdc_ The USDC contract address
     * @param treasuryAddress_ The treasury address
     * @param cashVestingAddress_ The cash vesting address
     */
    constructor(IUSDC usdc_, address treasuryAddress_, address cashVestingAddress_) EIP712("IndieBroker", "1") {
        usdc = usdc_;
        feeRecipients[Fees.Treasury] = treasuryAddress_;
        feeRecipients[Fees.CashVesting] = cashVestingAddress_;

        fees[Fees.Treasury] = 20_00; // 20%
        fees[Fees.Lead] = 10_00; // 10%
        fees[Fees.Sales] = 10_00; // 10%
        fees[Fees.CashVesting] = 5_00; // 5%
    }

    /**
     * @notice Starts a project
     * @param projectId The reference project identifier from the off-chain Indie Protocol database
     * @param leadAddress The project lead address
     * @param clientAddress The project client address
     * @param salesAddress The project sales referrer address
     */
    function startProject(uint256 projectId, address leadAddress, address clientAddress, address salesAddress)
        external
        whenNotPaused
        nonReentrant
    {
        if (projectId == 0) {
            revert InvalidProjectId();
        }

        if (leadAddress == address(0)) {
            revert ZeroAddress();
        }

        if (clientAddress == address(0)) {
            revert ZeroAddress();
        }

        if (salesAddress == address(0)) {
            revert ZeroAddress();
        }

        if (msg.sender != leadAddress) {
            revert NotAuthorized();
        }

        if (!allowedLeads[leadAddress]) {
            revert LeadNotOnAllowList();
        }

        if (projects[projectId].projectId != 0) {
            revert ProjectAlreadyExists();
        }

        projects[projectId] = Project(projectId, leadAddress, clientAddress, salesAddress);
        emit StartProject(projectId, leadAddress, clientAddress, salesAddress);
    }

    /**
     * @notice Sends a deposit to the Indie Protocol contract for a specific project
     * @dev See USDC contract `receiveWithAuthorization` function for more details
     * @param projectId The reference project identifier from the off-chain Indie Protocol database
     * @param from The address to transfer the USDC from
     * @param amount The amount of USDC to transfer
     * @param validAfter The time after which this is valid (unix time)
     * @param validBefore The time before which this is valid (unix time)
     * @param nonce A unique nonce
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function sendDepositWithAuthorization(
        uint256 projectId,
        address from,
        uint256 amount,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused nonReentrant {
        _sendDeposit(projectId, from, amount);

        usdc.receiveWithAuthorization(from, address(this), amount, validAfter, validBefore, nonce, v, r, s);
    }

    /**
     * @notice Sends a deposit to the Indie Protocol contract for a specific project
     * @dev See USDC contract `transferFrom` function for more details
     * @param projectId The reference project identifier from the off-chain Indie Protocol database
     * @param from The address to transfer the USDC from
     * @param amount The amount of USDC to transfer
     */
    function sendDeposit(uint256 projectId, address from, uint256 amount) external whenNotPaused nonReentrant {
        _sendDeposit(projectId, from, amount);

        usdc.transferFrom(from, address(this), amount);
    }

    /**
     * @notice Calculates payment amounts given a set of payees and amounts
     * @param payees The addresses of the payees
     * @param amounts The amounts of USDC expected to be distributed for each payee
     * @return sprintPayments The calculated sprint payments (see `SprintPayments` struct)
     */
    function calculateSprintPayments(address[] calldata payees, uint256[] calldata amounts)
        public
        view
        returns (SprintPayments memory sprintPayments)
    {
        sprintPayments = SprintPayments(
            0, // totalAmount
            0, // totalTreasuryAmount
            0, // totalCashVestingAmount
            0, // totalLeadAmount
            0, // totalSalesAmount
            new uint256[](payees.length), // payeeAmounts
            new uint256[](payees.length), // treasuryAmounts
            new uint256[](payees.length), // leadAmounts
            new uint256[](payees.length), // salesAmounts
            new uint256[](payees.length) // cashVestingAmounts
        );

        uint256 payeeAmount;
        uint256 treasuryAmount;
        uint256 leadAmount;
        uint256 salesAmount;
        uint256 cashVestingAmount;

        for (uint256 i = 0; i < payees.length;) {
            sprintPayments.totalAmount += amounts[i];

            (payeeAmount, treasuryAmount, leadAmount, salesAmount, cashVestingAmount) =
                calculatePayment(payees[i], amounts[i]);

            sprintPayments.totalTreasuryAmount += treasuryAmount;
            sprintPayments.totalLeadAmount += leadAmount;
            sprintPayments.totalSalesAmount += salesAmount;
            sprintPayments.totalCashVestingAmount += cashVestingAmount;

            sprintPayments.payeeAmounts[i] = payeeAmount;
            sprintPayments.treasuryAmounts[i] = treasuryAmount;
            sprintPayments.leadAmounts[i] = leadAmount;
            sprintPayments.salesAmounts[i] = salesAmount;
            sprintPayments.cashVestingAmounts[i] = cashVestingAmount;

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Calculates payment distributions given a payee and amount
     * @param payee The address of the payee
     * @param amount The amount of USDC expected to be distributed
     * @return payeeAmount The amount of USDC expected to be distributed to the payee after rewards are deducted
     * @return treasuryAmount The amount of USDC expected to be distributed to the treasury
     * @return leadAmount The amount of USDC expected to be distributed to the project lead (only includes the lead reward)
     * @return salesAmount The amount of USDC expected to be distributed to the project sales referrer
     * @return cashVestingAmount The amount of USDC expected to be distributed to the cash vesting address
     */
    function calculatePayment(address payee, uint256 amount)
        public
        view
        returns (
            uint256 payeeAmount,
            uint256 treasuryAmount,
            uint256 leadAmount,
            uint256 salesAmount,
            uint256 cashVestingAmount
        )
    {
        uint256 treasuryFee = _getTreasuryFeeForIndividual(payee);
        treasuryAmount = (amount * treasuryFee) / FEE_DENOMINATOR;
        leadAmount = (amount * fees[Fees.Lead]) / FEE_DENOMINATOR;
        salesAmount = (amount * fees[Fees.Sales]) / FEE_DENOMINATOR;
        cashVestingAmount = (amount * fees[Fees.CashVesting]) / FEE_DENOMINATOR;
        payeeAmount = amount - treasuryAmount - leadAmount - salesAmount - cashVestingAmount;
    }

    /**
     * @notice Completes a sprint and distributes the funds to the payees and reward recipients
     * @param projectId The reference project identifier from the off-chain Indie Protocol database
     * @param sprintId The reference sprint identifier from the off-chain Indie Protocol database
     * @param payees The addresses of the payees
     * @param amounts The amounts of USDC expected to be distributed for each payee
     * @param v The recovery byte of the client's acceptance signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function completeSprint(
        uint256 projectId,
        uint256 sprintId,
        address[] calldata payees,
        uint256[] calldata amounts,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused nonReentrant {
        if (sprintId == 0) {
            revert InvalidSprintId();
        }

        if (payees.length != amounts.length) {
            revert PayeeAmountMismatch();
        }

        if (completedSprints[projectId][sprintId]) {
            revert SprintAlreadyCompleted();
        }

        Project memory project = projects[projectId];
        if (msg.sender != project.leadAddress) {
            revert NotAuthorized();
        }

        SprintPayments memory sprintPayments = calculateSprintPayments(payees, amounts);

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("CompleteSprint(uint256 projectId,uint256 sprintId,uint256 totalAmount)"),
                projectId,
                sprintId,
                sprintPayments.totalAmount
            )
        );

        bytes32 digest = _hashTypedDataV4(structHash);

        if (!_verifySignature(digest, v, r, s, project.clientAddress)) {
            revert InvalidClientSignature();
        }

        for (uint256 i = 0; i < sprintPayments.payeeAmounts.length;) {
            if (payees[i] == address(0)) {
                revert ZeroAddress();
            }

            emit DistributePayment(
                payees[i],
                projectId,
                amounts[i],
                sprintPayments.payeeAmounts[i],
                sprintPayments.treasuryAmounts[i],
                sprintPayments.leadAmounts[i],
                sprintPayments.salesAmounts[i],
                sprintPayments.cashVestingAmounts[i]
                );

            if (sprintPayments.payeeAmounts[i] > 0) {
                usdc.transfer(payees[i], sprintPayments.payeeAmounts[i]);
            }

            unchecked {
                i++;
            }
        }

        if (sprintPayments.totalTreasuryAmount > 0) {
            usdc.transfer(feeRecipients[Fees.Treasury], sprintPayments.totalTreasuryAmount);
        }

        if (sprintPayments.totalCashVestingAmount > 0) {
            usdc.transfer(feeRecipients[Fees.CashVesting], sprintPayments.totalCashVestingAmount);
        }

        if (sprintPayments.totalLeadAmount > 0) {
            usdc.transfer(project.leadAddress, sprintPayments.totalLeadAmount);
        }

        if (sprintPayments.totalSalesAmount > 0) {
            usdc.transfer(project.salesAddress, sprintPayments.totalSalesAmount);
        }

        projectBalances[projectId] -= sprintPayments.totalAmount;
        completedSprints[projectId][sprintId] = true;

        emit CompleteProjectSprint(projectId, sprintId, sprintPayments.totalAmount);
    }

    /**
     * @notice Sets the fee for an individual payee address
     * @param addr The address of the payee
     * @param fee The fee to be set where the value has a denominator of 10000 (e.g. `500` yields a 5% fee). See `minIndividualTreasuryFee` and `maxIndividualTreasuryFee` for limits.
     */
    function setIndividualTreasuryFee(address addr, uint256 fee) external {
        if (addr != msg.sender) {
            revert NotAuthorized();
        }
        if (fee < minIndividualTreasuryFee) {
            revert FeeTooLow();
        }
        if (fee > maxIndividualTreasuryFee) {
            revert FeeTooHigh();
        }

        individualTreasuryFees[addr] = fee;

        emit SetIndividualTreasuryFee(addr, fee);
    }

    /**
     * @notice Sets the fee for a given fee type
     * @param f The fee type to be set
     * @param fee The fee to be set where the value has a denominator of 10000 (e.g. `500` yields a 5% fee)
     */
    function setFee(Fees f, uint256 fee) external onlyOwner {
        fees[f] = fee;

        // Ensure the sum of all possible fees does not exceed the max possible
        // Must account for the possibility of an individual maxing out their invididual treasury fee
        uint256 maxTreasuryFee = Math.max(fees[Fees.Treasury], maxIndividualTreasuryFee);

        if (maxTreasuryFee + fees[Fees.Lead] + fees[Fees.Sales] + fees[Fees.CashVesting] > MAX_FEES) {
            revert ExceededMaxFees();
        }

        emit SetFee(f, fee);
    }

    /**
     * @notice Sets the fee recipient for a given fee type
     * @param f The fee type to be set must be Treasury or CashVesting
     * @param recipient The address of the recipient
     */
    function setFeeRecipient(Fees f, address recipient) external onlyOwner {
        if (recipient == address(0)) {
            revert ZeroAddress();
        }
        if (f != Fees.Treasury && f != Fees.CashVesting) {
            revert InvalidFee();
        }

        feeRecipients[f] = recipient;
        emit SetFeeRecipient(f, recipient);
    }

    /**
     * @notice Sets the minimum and maximum individual treasury fees
     * @param minFee The minimum fee to be set where the value has a denominator of 10000 (e.g. `500` yields a 5% fee)
     * @param maxFee The maximum fee to be set where the value has a denominator of 10000 (e.g. `500` yields a 5% fee)
     */
    function setMinMaxIndividualTreasuryFees(uint256 minFee, uint256 maxFee) external onlyOwner {
        if (minFee < 0) {
            revert FeeTooLow();
        }
        if (minFee > maxFee) {
            revert FeeTooHigh();
        }

        // Max individual fee plus all other (non-treasury) fees cannot exceed max fees
        if (maxFee + fees[Fees.Lead] + fees[Fees.Sales] + fees[Fees.CashVesting] > MAX_FEES) {
            revert ExceededMaxFees();
        }

        minIndividualTreasuryFee = minFee;
        maxIndividualTreasuryFee = maxFee;

        emit SetMinMaxIndividualTreasuryFees(minFee, maxFee);
    }

    /**
     * @notice Reassigns the project lead for a project. Can only be called by the current project lead or the contract owner.
     * @param projectId The reference project identifier from the off-chain Indie Protocol database
     * @param newLeadAddress The address of the new project lead
     */
    function reassignProjectLead(uint256 projectId, address newLeadAddress) external {
        if (newLeadAddress == address(0)) {
            revert ZeroAddress();
        }

        if (!allowedLeads[newLeadAddress]) {
            revert LeadNotOnAllowList();
        }

        Project memory project = projects[projectId];

        if (project.projectId == 0) {
            revert ProjectNotFound();
        }

        if (msg.sender != project.leadAddress && msg.sender != owner()) {
            revert NotAuthorized();
        }

        projects[projectId].leadAddress = newLeadAddress;
        emit ReassignProjectLead(projectId, newLeadAddress);
    }

    /**
     * @notice Reassigns the project sales referrer for a project. Can only be called by the current project sales referrer or the contract owner.
     * @param projectId The reference project identifier from the off-chain Indie Protocol database
     * @param newSalesAddress The address of the new project sales referrer
     */
    function reassignProjectSales(uint256 projectId, address newSalesAddress) external {
        if (newSalesAddress == address(0)) {
            revert ZeroAddress();
        }

        Project memory project = projects[projectId];

        if (project.projectId == 0) {
            revert ProjectNotFound();
        }

        if (msg.sender != project.salesAddress && msg.sender != owner()) {
            revert NotAuthorized();
        }

        projects[projectId].salesAddress = newSalesAddress;
        emit ReassignProjectSales(projectId, newSalesAddress);
    }

    /**
     * @notice Reassigns the project client for a project. Can only be called by the current project lead, client or the contract owner.
     * @param projectId The reference project identifier from the off-chain Indie Protocol database
     * @param newClientAddress The address of the new project client
     */
    function reassignProjectClient(uint256 projectId, address newClientAddress) external {
        if (newClientAddress == address(0)) {
            revert ZeroAddress();
        }

        Project memory project = projects[projectId];

        if (project.projectId == 0) {
            revert ProjectNotFound();
        }

        if (msg.sender != project.clientAddress && msg.sender != project.leadAddress && msg.sender != owner()) {
            revert NotAuthorized();
        }

        projects[projectId].clientAddress = newClientAddress;
        emit ReassignProjectClient(projectId, newClientAddress);
    }

    /**
     * @notice Enables/disables an address from being a project lead and being able to create projects
     * @param addr The address of the individual
     * @param allowed Whether or not the address is allowed to be a project lead
     */
    function setAllowedLead(address addr, bool allowed) external onlyOwner {
        if (addr == address(0)) {
            revert ZeroAddress();
        }

        allowedLeads[addr] = allowed;
        emit SetAllowedLead(addr, allowed);
    }

    /**
     * @notice Withdraws funds from a project's balance
     * @param projectId The reference project identifier from the off-chain Indie Protocol database
     * @param amount The amount to withdraw
     * @param recipient The address to send the funds to
     */
    function withdrawFromProject(uint256 projectId, uint256 amount, address recipient)
        external
        onlyOwner
        nonReentrant
    {
        if (recipient == address(0)) {
            revert ZeroAddress();
        }

        if (projectBalances[projectId] < amount) {
            revert InsufficientBalance();
        }

        projectBalances[projectId] -= amount;
        usdc.transfer(recipient, amount);

        emit WithdrawFromProject(projectId, amount, recipient);
    }

    /**
     * @notice Pauses the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function _verifySignature(bytes32 digest, uint8 v, bytes32 r, bytes32 s, address signerAddress)
        internal
        pure
        returns (bool)
    {
        (address signedHashAddress, ECDSA.RecoverError error) = ECDSA.tryRecover(digest, v, r, s);

        return error == ECDSA.RecoverError.NoError && signedHashAddress == signerAddress;
    }

    function _getTreasuryFeeForIndividual(address addr) internal view returns (uint256) {
        return individualTreasuryFees[addr] == 0 ? fees[Fees.Treasury] : individualTreasuryFees[addr];
    }

    function _sendDeposit(uint256 projectId, address from, uint256 amount) internal {
        if (projects[projectId].projectId == 0) {
            revert ProjectNotFound();
        }
        projectBalances[projectId] += amount;

        emit SendDeposit(projectId, from, amount);
    }
}