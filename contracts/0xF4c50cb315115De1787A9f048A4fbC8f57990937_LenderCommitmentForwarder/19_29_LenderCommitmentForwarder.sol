pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./TellerV2MarketForwarder.sol";

contract LenderCommitmentForwarder is TellerV2MarketForwarder {
    /**
     * @notice Details about a lender's capital commitment.
     * @param amount Amount of tokens being committed by the lender.
     * @param expiration Expiration time in seconds, when the commitment expires.
     * @param maxDuration Length of time, in seconds that the lender's capital can be lent out for.
     * @param minAPR Minimum Annual percentage to be applied for loans using the lender's capital.
     */
    struct Commitment {
        uint256 maxPrincipal;
        uint32 expiration;
        uint32 maxDuration;
        uint16 minInterestRate;
    }

    modifier onlyMarketOwner(uint256 marketId) {
        require(_msgSender() == getTellerV2MarketOwner(marketId));
        _;
    }

    // Mapping of lender address => market ID => lending token => commitment
    mapping(address => mapping(uint256 => mapping(address => Commitment)))
        public lenderMarketCommitments;

    /**
     * @notice This event is emitted when a lender's commitment is submitted.
     * @param lender The address of the lender.
     * @param marketId The Id of the market the commitment applies to.
     * @param lendingToken The address of the asset being committed.
     * @param tokenAmount The amount of the asset being committed.
     */
    event UpdatedCommitment(
        address indexed lender,
        uint256 indexed marketId,
        address indexed lendingToken,
        uint256 tokenAmount
    );

    /**
     * @notice This event is emitted when a lender's commitment has been removed.
     * @param lender The address of the lender.
     * @param marketId The Id of the market the commitment removal applies to.
     * @param lendingToken The address of the asset the commitment removal applies to.
     */
    event DeletedCommitment(
        address indexed lender,
        uint256 indexed marketId,
        address indexed lendingToken
    );

    /**
     * @notice This event is emitted when a lender's commitment is exercised for a loan.
     * @param lender The address of the lender.
     * @param marketId The Id of the market the commitment applies to.
     * @param lendingToken The address of the asset being committed.
     * @param tokenAmount The amount of the asset being committed.
     * @param bidId The bid id for the loan from TellerV2.
     */
    event ExercisedCommitment(
        address indexed lender,
        uint256 indexed marketId,
        address indexed lendingToken,
        uint256 tokenAmount,
        uint256 bidId
    );

    /** External Functions **/

    constructor(address _protocolAddress, address _marketRegistry)
        TellerV2MarketForwarder(_protocolAddress, _marketRegistry)
    {}

    /**
     * @notice Updates the commitment of a lender to a market.
     * @param _tokenAddress The address of the asset being committed.
     * @param _marketId The Id of the market the commitment applies to.
     * @param _maxPrincipal Amount of tokens being committed by the lender.
     * @param _maxLoanDuration Length of time, in seconds that the lender's capital can be lent out for.
     * @param _minInterestRate Minimum Annual percentage to be applied for loans using the lender's capital.
     * @param _expiration Expiration time in seconds, when the commitment expires.
     */
    function updateCommitment(
        uint256 _marketId,
        address _tokenAddress,
        uint256 _maxPrincipal,
        uint32 _maxLoanDuration,
        uint16 _minInterestRate,
        uint32 _expiration
    ) public {
        address lender = _msgSender();
        require(_expiration > uint32(block.timestamp));

        Commitment storage commitment = lenderMarketCommitments[lender][
            _marketId
        ][_tokenAddress];
        commitment.maxPrincipal = _maxPrincipal;
        commitment.expiration = _expiration;
        commitment.maxDuration = _maxLoanDuration;
        commitment.minInterestRate = _minInterestRate;

        emit UpdatedCommitment(lender, _marketId, _tokenAddress, _maxPrincipal);
    }

    /**
     * @notice Removes the commitment of a lender to a market.
     * @param _marketId The Id of the market the commitment removal applies to.
     * @param _tokenAddress The address of the asset for which the commitment is being removed.
     */
    function deleteCommitment(uint256 _marketId, address _tokenAddress) public {
        _deleteCommitment(_msgSender(), _marketId, _tokenAddress);
    }

    /**
     * @notice Removes the commitment of a lender to a market.
     * @param _lender The address of the lender of the commitment.
     * @param _marketId The Id of the market the commitment removal applies to.
     * @param _tokenAddress The address of the asset for which the commitment is being removed.
     */
    function _deleteCommitment(
        address _lender,
        uint256 _marketId,
        address _tokenAddress
    ) internal {
        if (
            lenderMarketCommitments[_lender][_marketId][_tokenAddress]
                .maxPrincipal > 0
        ) {
            delete lenderMarketCommitments[_lender][_marketId][_tokenAddress];
            emit DeletedCommitment(_lender, _marketId, _tokenAddress);
        }
    }

    /**
     * @notice Reduces the commitment amount for a lender to a market.
     * @param _lender The address of the lender of the commitment.
     * @param _marketId The Id of the market the commitment removal applies to.
     * @param _tokenAddress The address of the asset for which the commitment is being removed.
     * @param _tokenAmountDelta The amount of change in the maxPrincipal.
     */
    function _decrementCommitment(
        address _lender,
        uint256 _marketId,
        address _tokenAddress,
        uint256 _tokenAmountDelta
    ) internal {
        lenderMarketCommitments[_lender][_marketId][_tokenAddress]
            .maxPrincipal -= _tokenAmountDelta;
    }

    /**
     * @notice Accept the commitment to submitBid and acceptBid using the funds
     * @param _marketId The Id of the market the commitment removal applies to.
     * @param _lender The address of the lender of the commitment.
     * @param _tokenAddress The address of the asset for which the commitment is being removed.
     * @param _principal The amount of currency to borrow for the loan.
     * @param _loanDuration The loan duration for the TellerV2 loan.
     * @param _interestRate The interest rate for the TellerV2 loan.
     */
    function acceptCommitment(
        uint256 _marketId,
        address _lender,
        address _tokenAddress,
        uint256 _principal,
        uint32 _loanDuration,
        uint16 _interestRate
    ) external onlyMarketOwner(_marketId) returns (uint256 bidId) {
        address borrower = _msgSender();

        Commitment storage commitment = lenderMarketCommitments[_lender][
            _marketId
        ][_tokenAddress];

        require(
            _principal <= commitment.maxPrincipal,
            "Commitment principal insufficient"
        );
        require(
            _loanDuration <= commitment.maxDuration,
            "Commitment duration insufficient"
        );
        require(
            _interestRate >= commitment.minInterestRate,
            "Interest rate insufficient for commitment"
        );
        require(
            block.timestamp < commitment.expiration,
            "Commitment has expired"
        );

        CreateLoanArgs memory createLoanArgs;
        createLoanArgs.marketId = _marketId;
        createLoanArgs.lendingToken = _tokenAddress;
        createLoanArgs.principal = _principal;
        createLoanArgs.duration = _loanDuration;
        createLoanArgs.interestRate = _interestRate;

        bidId = _submitBid(createLoanArgs, borrower);

        _acceptBid(bidId, _lender);

        _decrementCommitment(_lender, _marketId, _tokenAddress, _principal);

        emit ExercisedCommitment(
            _lender,
            _marketId,
            _tokenAddress,
            _principal,
            bidId
        );
    }
}