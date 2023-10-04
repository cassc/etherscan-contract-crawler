// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IFactory {
    event LoanProposalCreated(
        address indexed loanProposalAddr,
        address indexed fundingPool,
        address indexed sender,
        address collToken,
        uint256 arrangerFee,
        uint256 unsubscribeGracePeriod,
        uint256 numLoanProposals
    );
    event FundingPoolCreated(
        address indexed newFundingPool,
        address indexed depositToken,
        uint256 numFundingPools
    );
    event ProtocolFeeUpdated(uint256 oldProtocolFee, uint256 newProtocolFee);
    event LenderWhitelistStatusClaimed(
        address indexed whitelistAuthority,
        address indexed lender,
        uint256 whitelistedUntil
    );
    event LenderWhitelistUpdated(
        address indexed whitelistAuthority,
        address[] indexed lender,
        uint256 whitelistedUntil
    );
    event MysoTokenManagerUpdated(
        address oldTokenManager,
        address newTokenManager
    );

    /**
     * @notice Creates a new loan proposal
     * @param _fundingPool The address of the funding pool from which lenders are allowed to subscribe, and -if loan proposal is successful- from where loan amount is sourced
     * @param _collToken The address of collateral token to be provided by borrower
     * @param _whitelistAuthority The address of the whitelist authority that can manage the lender whitelist (optional)
     * @param _arrangerFee The relative arranger fee (where 100% = BASE)
     * @param _unsubscribeGracePeriod The unsubscribe grace period, i.e., after a loan gets accepted by the borrower lenders can still unsubscribe for this time period before being locked-in
     * @param _conversionGracePeriod The grace period during which lenders can convert
     * @param _repaymentGracePeriod The grace period during which borrowers can repay
     */
    function createLoanProposal(
        address _fundingPool,
        address _collToken,
        address _whitelistAuthority,
        uint256 _arrangerFee,
        uint256 _unsubscribeGracePeriod,
        uint256 _conversionGracePeriod,
        uint256 _repaymentGracePeriod
    ) external;

    /**
     * @notice Creates a new funding pool
     * @param _depositToken The address of the deposit token to be accepted by the given funding pool
     */
    function createFundingPool(address _depositToken) external;

    /**
     * @notice Sets the protocol fee
     * @dev Can only be called by the loan proposal factory owner
     * @param _newProtocolFee The given protocol fee; note that this amount must be smaller than Constants.MAX_P2POOL_PROTOCOL_FEE (<5%)
     */
    function setProtocolFee(uint256 _newProtocolFee) external;

    /**
     * @notice Allows user to claim whitelisted status
     * @param whitelistAuthority Address of whitelist authorithy
     * @param whitelistedUntil Timestamp until when user is whitelisted
     * @param compactSig Compact signature from whitelist authority
     * @param salt Salt to make signature unique
     */
    function claimLenderWhitelistStatus(
        address whitelistAuthority,
        uint256 whitelistedUntil,
        bytes calldata compactSig,
        bytes32 salt
    ) external;

    /**
     * @notice Allows a whitelist authority to set the whitelistedUntil state for a given lender
     * @dev Anyone can create their own whitelist, and borrowers can decide if and which whitelist they want to use
     * @param lenders Array of lender addresses
     * @param whitelistedUntil Timestamp until which lenders shall be whitelisted under given whitelist authority
     */
    function updateLenderWhitelist(
        address[] calldata lenders,
        uint256 whitelistedUntil
    ) external;

    /**
     * @notice Sets a new MYSO token manager contract
     * @dev Can only be called by registry owner
     * @param newTokenManager Address of the new MYSO token manager contract
     */
    function setMysoTokenManager(address newTokenManager) external;

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     * @param newOwner the proposed new owner address
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice Returns the address of the funding pool implementation
     * @return The address of the funding pool implementation
     */
    function fundingPoolImpl() external view returns (address);

    /**
     * @notice Returns the address of the proposal implementation
     * @return The address of the proposal implementation
     */
    function loanProposalImpl() external view returns (address);

    /**
     * @notice Returns the address of a registered loan proposal
     * @param idx The index of the given loan proposal
     * @return The address of a registered loan proposal
     */
    function loanProposals(uint256 idx) external view returns (address);

    /**
     * @notice Returns the address of a registered funding pool
     * @param idx The index of the given funding pool
     * @return The address of a registered funding pool
     */
    function fundingPools(uint256 idx) external view returns (address);

    /**
     * @notice Returns flag whether given address is a registered loan proposal contract
     * @param addr The address to check if its a registered loan proposal
     * @return Flag indicating whether address is a registered loan proposal contract
     */
    function isLoanProposal(address addr) external view returns (bool);

    /**
     * @notice Returns flag whether given address is a registered funding pool contract
     * @param addr The address to check if its a registered funding pool
     * @return Flag indicating whether address is a registered funding pool contract
     */
    function isFundingPool(address addr) external view returns (bool);

    /**
     * @notice Returns the protocol fee
     * @return The protocol fee
     */
    function protocolFee() external view returns (uint256);

    /**
     * @notice Returns the address of the owner of this contract
     * @return The address of the owner of this contract
     */
    function owner() external view returns (address);

    /**
     * @notice Returns address of the pending owner
     * @return Address of the pending owner
     */
    function pendingOwner() external view returns (address);

    /**
     * @notice Returns the address of the MYSO token manager
     * @return Address of the MYSO token manager contract
     */
    function mysoTokenManager() external view returns (address);

    /**
     * @notice Returns boolean flag indicating whether the lender has been whitelisted by whitelistAuthority
     * @param whitelistAuthority Addresses of the whitelist authority
     * @param lender Addresses of the lender
     * @return Boolean flag indicating whether the lender has been whitelisted by whitelistAuthority
     */
    function isWhitelistedLender(
        address whitelistAuthority,
        address lender
    ) external view returns (bool);

    /**
     * @notice Returns the number of loan proposals created
     * @return Number of loan proposals created
     */
    function numLoanProposals() external view returns (uint256);
}