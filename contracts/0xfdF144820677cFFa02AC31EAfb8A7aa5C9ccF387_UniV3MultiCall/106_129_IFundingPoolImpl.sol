// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IFundingPoolImpl {
    event Deposited(
        address user,
        uint256 amount,
        uint256 depositLockupDuration
    );
    event Withdrawn(address user, uint256 amount);
    event Subscribed(
        address indexed user,
        address indexed loanProposalAddr,
        uint256 amount,
        uint256 subscriptionLockupDuration
    );
    event Unsubscribed(
        address indexed user,
        address indexed loanProposalAddr,
        uint256 amount
    );
    event LoanProposalExecuted(
        address indexed loanProposal,
        address indexed borrower,
        uint256 grossLoanAmount,
        uint256 arrangerFee,
        uint256 protocolFee
    );

    /**
     * @notice Initializes funding pool
     * @param _factory Address of the factory contract spawning the given funding pool
     * @param _depositToken Address of the deposit token for the given funding pool
     */
    function initialize(address _factory, address _depositToken) external;

    /**
     * @notice function allows users to deposit into funding pool
     * @param amount amount to deposit
     * @param transferFee this accounts for any transfer fee token may have (e.g. paxg token)
     * @param depositLockupDuration the duration for which the deposit shall be locked (optional for tokenomics)
     */
    function deposit(
        uint256 amount,
        uint256 transferFee,
        uint256 depositLockupDuration
    ) external;

    /**
     * @notice function allows users to withdraw from funding pool
     * @param amount amount to withdraw
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice function allows users from funding pool to subscribe as lenders to a proposal
     * @param loanProposal address of the proposal to which user wants to subscribe
     * @param minAmount the desired minimum subscription amount
     * @param maxAmount the desired maximum subscription amount
     * @param subscriptionLockupDuration the duration for which the subscription shall be locked (optional for tokenomics)
     */
    function subscribe(
        address loanProposal,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 subscriptionLockupDuration
    ) external;

    /**
     * @notice function allows subscribed lenders to unsubscribe from a proposal
     * @dev there is a cooldown period after subscribing to mitigate possible griefing attacks
     * of subscription followed by quick unsubscription
     * @param loanProposal address of the proposal to which user wants to unsubscribe
     * @param amount amount of subscription removed
     */
    function unsubscribe(address loanProposal, uint256 amount) external;

    /**
     * @notice function allows execution of a proposal
     * @param loanProposal address of the proposal executed
     */
    function executeLoanProposal(address loanProposal) external;

    /**
     * @notice function returns factory address
     */
    function factory() external view returns (address);

    /**
     * @notice function returns address of deposit token for pool
     */
    function depositToken() external view returns (address);

    /**
     * @notice function returns balance deposited into pool
     * note: balance is tracked only through using deposit function
     * direct transfers into pool are not credited
     */
    function balanceOf(address) external view returns (uint256);

    /**
     * @notice function tracks total subscription amount for a given proposal address
     */
    function totalSubscriptions(address) external view returns (uint256);

    /**
     * @notice function tracks subscription amounts for a given proposal address and subsciber address
     */
    function subscriptionAmountOf(
        address,
        address
    ) external view returns (uint256);
}