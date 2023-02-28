pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

// Contracts
import "./TellerV2MarketForwarder.sol";

// Interfaces
import "./interfaces/ICollateralManager.sol";
import { Collateral, CollateralType } from "./interfaces/escrow/ICollateralEscrowV1.sol";

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

// Libraries
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

contract LenderCommitmentForwarder is TellerV2MarketForwarder {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    enum CommitmentCollateralType {
        NONE, // no collateral required
        ERC20,
        ERC721,
        ERC1155,
        ERC721_ANY_ID,
        ERC1155_ANY_ID
    }

    /**
     * @notice Details about a lender's capital commitment.
     * @param maxPrincipal Amount of tokens being committed by the lender. Max amount that can be loaned.
     * @param expiration Expiration time in seconds, when the commitment expires.
     * @param maxDuration Length of time, in seconds that the lender's capital can be lent out for.
     * @param minInterestRate Minimum Annual percentage to be applied for loans using the lender's capital.
     * @param collateralTokenAddress The address for the token contract that must be used to provide collateral for loans for this commitment.
     * @param maxPrincipalPerCollateralAmount The amount of principal that can be used for a loan per each unit of collateral, expanded additionally by principal decimals.
     * @param collateralTokenType The type of asset of the collateralTokenAddress (ERC20, ERC721, or ERC1155).
     * @param lender The address of the lender for this commitment.
     * @param marketId The market id for this commitment.
     * @param principalTokenAddress The address for the token contract that will be used to provide principal for loans of this commitment.
     */
    struct Commitment {
        uint256 maxPrincipal;
        uint32 expiration;
        uint32 maxDuration;
        uint16 minInterestRate;
        address collateralTokenAddress;
        uint256 collateralTokenId;
        uint256 maxPrincipalPerCollateralAmount;
        CommitmentCollateralType collateralTokenType;
        address lender;
        uint256 marketId;
        address principalTokenAddress;
    }

    // CommitmentId => commitment
    mapping(uint256 => Commitment) public commitments;

    uint256 commitmentCount;

    mapping(uint256 => EnumerableSetUpgradeable.AddressSet)
        internal commitmentBorrowersList;

    /**
     * @notice This event is emitted when a lender's commitment is created.
     * @param lender The address of the lender.
     * @param marketId The Id of the market the commitment applies to.
     * @param lendingToken The address of the asset being committed.
     * @param tokenAmount The amount of the asset being committed.
     */
    event CreatedCommitment(
        uint256 indexed commitmentId,
        address lender,
        uint256 marketId,
        address lendingToken,
        uint256 tokenAmount
    );

    /**
     * @notice This event is emitted when a lender's commitment is updated.
     * @param commitmentId The id of the commitment that was updated.
     * @param lender The address of the lender.
     * @param marketId The Id of the market the commitment applies to.
     * @param lendingToken The address of the asset being committed.
     * @param tokenAmount The amount of the asset being committed.
     */
    event UpdatedCommitment(
        uint256 indexed commitmentId,
        address lender,
        uint256 marketId,
        address lendingToken,
        uint256 tokenAmount
    );

    /**
     * @notice This event is emitted when the allowed borrowers for a commitment is updated.
     * @param commitmentId The id of the commitment that was updated.
     */
    event UpdatedCommitmentBorrowers(uint256 indexed commitmentId);

    /**
     * @notice This event is emitted when a lender's commitment has been deleted.
     * @param commitmentId The id of the commitment that was deleted.
     */
    event DeletedCommitment(uint256 indexed commitmentId);

    /**
     * @notice This event is emitted when a lender's commitment is exercised for a loan.
     * @param commitmentId The id of the commitment that was exercised.
     * @param borrower The address of the borrower.
     * @param tokenAmount The amount of the asset being committed.
     * @param bidId The bid id for the loan from TellerV2.
     */
    event ExercisedCommitment(
        uint256 indexed commitmentId,
        address borrower,
        uint256 tokenAmount,
        uint256 bidId
    );

    error InsufficientCommitmentAllocation(
        uint256 allocated,
        uint256 requested
    );
    error InsufficientBorrowerCollateral(uint256 required, uint256 actual);

    /** Modifiers **/

    modifier commitmentLender(uint256 _commitmentId) {
        require(
            commitments[_commitmentId].lender == _msgSender(),
            "unauthorized commitment lender"
        );
        _;
    }

    function validateCommitment(Commitment storage _commitment) internal {
        require(
            _commitment.expiration > uint32(block.timestamp),
            "expired commitment"
        );
        require(
            _commitment.maxPrincipal > 0,
            "commitment principal allocation 0"
        );

        if (_commitment.collateralTokenType != CommitmentCollateralType.NONE) {
            require(
                _commitment.maxPrincipalPerCollateralAmount > 0,
                "commitment collateral ratio 0"
            );

            if (
                _commitment.collateralTokenType ==
                CommitmentCollateralType.ERC20
            ) {
                require(
                    _commitment.collateralTokenId == 0,
                    "commitment collateral token id must be 0 for ERC20"
                );
            }
        }
    }

    /** External Functions **/

    constructor(address _protocolAddress, address _marketRegistry)
        TellerV2MarketForwarder(_protocolAddress, _marketRegistry)
    {}

    /**
     * @notice Creates a loan commitment from a lender for a market.
     * @param _commitment The new commitment data expressed as a struct
     * @param _borrowerAddressList The array of borrowers that are allowed to accept loans using this commitment
     * @return commitmentId_ returns the commitmentId for the created commitment
     */
    function createCommitment(
        Commitment calldata _commitment,
        address[] calldata _borrowerAddressList
    ) public returns (uint256 commitmentId_) {
        commitmentId_ = commitmentCount++;

        require(
            _commitment.lender == _msgSender(),
            "unauthorized commitment creator"
        );

        commitments[commitmentId_] = _commitment;

        validateCommitment(commitments[commitmentId_]);

        _addBorrowersToCommitmentAllowlist(commitmentId_, _borrowerAddressList);

        emit CreatedCommitment(
            commitmentId_,
            _commitment.lender,
            _commitment.marketId,
            _commitment.principalTokenAddress,
            _commitment.maxPrincipal
        );
    }

    /**
     * @notice Updates the commitment of a lender to a market.
     * @param _commitmentId The Id of the commitment to update.
     * @param _commitment The new commitment data expressed as a struct
     */
    function updateCommitment(
        uint256 _commitmentId,
        Commitment calldata _commitment
    ) public commitmentLender(_commitmentId) {
        require(
            _commitment.principalTokenAddress ==
                commitments[_commitmentId].principalTokenAddress,
            "Principal token address cannot be updated."
        );
        require(
            _commitment.marketId == commitments[_commitmentId].marketId,
            "Market Id cannot be updated."
        );

        commitments[_commitmentId] = _commitment;

        validateCommitment(commitments[_commitmentId]);

        emit UpdatedCommitment(
            _commitmentId,
            _commitment.lender,
            _commitment.marketId,
            _commitment.principalTokenAddress,
            _commitment.maxPrincipal
        );
    }

    /**
     * @notice Updates the borrowers allowed to accept a commitment
     * @param _commitmentId The Id of the commitment to update.
     * @param _borrowerAddressList The array of borrowers that are allowed to accept loans using this commitment
     */
    function updateCommitmentBorrowers(
        uint256 _commitmentId,
        address[] calldata _borrowerAddressList
    ) public commitmentLender(_commitmentId) {
        delete commitmentBorrowersList[_commitmentId];
        _addBorrowersToCommitmentAllowlist(_commitmentId, _borrowerAddressList);
    }

    /**
     * @notice Adds a borrower to the allowlist for a commmitment.
     * @param _commitmentId The id of the commitment that will allow the new borrower
     * @param _borrowerArray the address array of the borrowers that will be allowed to accept loans using the commitment
     */
    function _addBorrowersToCommitmentAllowlist(
        uint256 _commitmentId,
        address[] calldata _borrowerArray
    ) internal {
        for (uint256 i = 0; i < _borrowerArray.length; i++) {
            commitmentBorrowersList[_commitmentId].add(_borrowerArray[i]);
        }
        emit UpdatedCommitmentBorrowers(_commitmentId);
    }

    /**
     * @notice Removes the commitment of a lender to a market.
     * @param _commitmentId The id of the commitment to delete.
     */
    function deleteCommitment(uint256 _commitmentId)
        public
        commitmentLender(_commitmentId)
    {
        delete commitments[_commitmentId];
        delete commitmentBorrowersList[_commitmentId];
        emit DeletedCommitment(_commitmentId);
    }

    /**
     * @notice Reduces the commitment amount for a lender to a market.
     * @param _commitmentId The id of the commitment to modify.
     * @param _tokenAmountDelta The amount of change in the maxPrincipal.
     */
    function _decrementCommitment(
        uint256 _commitmentId,
        uint256 _tokenAmountDelta
    ) internal {
        commitments[_commitmentId].maxPrincipal -= _tokenAmountDelta;
    }

    /**
     * @notice Accept the commitment to submitBid and acceptBid using the funds
     * @dev LoanDuration must be longer than the market payment cycle
     * @param _commitmentId The id of the commitment being accepted.
     * @param _principalAmount The amount of currency to borrow for the loan.
     * @param _collateralAmount The amount of collateral to use for the loan.
     * @param _collateralTokenId The tokenId of collateral to use for the loan if ERC721 or ERC1155.
     * @param _collateralTokenAddress The contract address to use for the loan collateral token.s
     * @param _interestRate The interest rate APY to use for the loan in basis points.
     * @param _loanDuration The overall duratiion for the loan.  Must be longer than market payment cycle duration.
     * @return bidId The ID of the loan that was created on TellerV2
     */
    function acceptCommitment(
        uint256 _commitmentId,
        uint256 _principalAmount,
        uint256 _collateralAmount,
        uint256 _collateralTokenId,
        address _collateralTokenAddress,
        uint16 _interestRate,
        uint32 _loanDuration
    ) external returns (uint256 bidId) {
        address borrower = _msgSender();

        Commitment storage commitment = commitments[_commitmentId];

        validateCommitment(commitment);

        require(
            _collateralTokenAddress == commitment.collateralTokenAddress,
            "Mismatching collateral token"
        );
        require(
            _interestRate >= commitment.minInterestRate,
            "Invalid interest rate"
        );
        require(
            _loanDuration <= commitment.maxDuration,
            "Invalid loan max duration"
        );

        require(
            commitmentBorrowersList[_commitmentId].length() == 0 ||
                commitmentBorrowersList[_commitmentId].contains(borrower),
            "unauthorized commitment borrower"
        );

        if (_principalAmount > commitment.maxPrincipal) {
            revert InsufficientCommitmentAllocation({
                allocated: commitment.maxPrincipal,
                requested: _principalAmount
            });
        }

        uint256 requiredCollateral = getRequiredCollateral(
            _principalAmount,
            commitment.maxPrincipalPerCollateralAmount,
            commitment.collateralTokenType,
            commitment.collateralTokenAddress,
            commitment.principalTokenAddress
        );
        if (_collateralAmount < requiredCollateral) {
            revert InsufficientBorrowerCollateral({
                required: requiredCollateral,
                actual: _collateralAmount
            });
        }

        if (
            commitment.collateralTokenType == CommitmentCollateralType.ERC721 ||
            commitment.collateralTokenType ==
            CommitmentCollateralType.ERC721_ANY_ID
        ) {
            require(
                _collateralAmount == 1,
                "invalid commitment collateral amount for ERC721"
            );
        }

        if (
            commitment.collateralTokenType == CommitmentCollateralType.ERC721 ||
            commitment.collateralTokenType == CommitmentCollateralType.ERC1155
        ) {
            require(
                commitment.collateralTokenId == _collateralTokenId,
                "invalid commitment collateral tokenId"
            );
        }

        bidId = _submitBidFromCommitment(
            borrower,
            commitment.marketId,
            commitment.principalTokenAddress,
            _principalAmount,
            commitment.collateralTokenAddress,
            _collateralAmount,
            _collateralTokenId,
            commitment.collateralTokenType,
            _loanDuration,
            _interestRate
        );

        _acceptBid(bidId, commitment.lender);

        _decrementCommitment(_commitmentId, _principalAmount);

        emit ExercisedCommitment(
            _commitmentId,
            borrower,
            _principalAmount,
            bidId
        );
    }

    /**
     * @notice Calculate the amount of collateral required to borrow a loan with _principalAmount of principal
     * @param _principalAmount The amount of currency to borrow for the loan.
     * @param _maxPrincipalPerCollateralAmount The ratio for the amount of principal that can be borrowed for each amount of collateral. This is expanded additionally by the principal decimals.
     * @param _collateralTokenType The type of collateral for the loan either ERC20, ERC721, ERC1155, or None.
     * @param _collateralTokenAddress The contract address for the collateral for the loan.
     * @param _principalTokenAddress The contract address for the principal for the loan.
     */
    function getRequiredCollateral(
        uint256 _principalAmount,
        uint256 _maxPrincipalPerCollateralAmount,
        CommitmentCollateralType _collateralTokenType,
        address _collateralTokenAddress,
        address _principalTokenAddress
    ) public view virtual returns (uint256) {
        if (_collateralTokenType == CommitmentCollateralType.NONE) {
            return 0;
        }

        uint8 collateralDecimals;
        uint8 principalDecimals = IERC20MetadataUpgradeable(
            _principalTokenAddress
        ).decimals();

        if (_collateralTokenType == CommitmentCollateralType.ERC20) {
            collateralDecimals = IERC20MetadataUpgradeable(
                _collateralTokenAddress
            ).decimals();
        }

        /*
         * The principalAmount is expanded by (collateralDecimals+principalDecimals) to increase precision
         * and then it is divided by _maxPrincipalPerCollateralAmount which should already been expanded by principalDecimals
         */
        return
            MathUpgradeable.mulDiv(
                _principalAmount,
                (10**(collateralDecimals + principalDecimals)),
                _maxPrincipalPerCollateralAmount,
                MathUpgradeable.Rounding.Up
            );
    }

    /**
     * @notice Return the array of borrowers that are allowlisted for a commitment
     * @param _commitmentId The commitment id for the commitment to query.
     * @return borrowers_ An array of addresses restricted to accept the commitment. Empty array means unrestricted.
     */
    function getCommitmentBorrowers(uint256 _commitmentId)
        external
        view
        returns (address[] memory borrowers_)
    {
        borrowers_ = commitmentBorrowersList[_commitmentId].values();
    }

    /**
     * @notice Internal function to submit a bid to the lending protocol using a commitment
     * @param _borrower The address of the borrower for the loan.
     * @param _marketId The id for the market of the loan in the lending protocol.
     * @param _principalTokenAddress The contract address for the principal token.
     * @param _principalAmount The amount of principal to borrow for the loan.
     * @param _collateralTokenAddress The contract address for the collateral token.
     * @param _collateralAmount The amount of collateral to use for the loan.
     * @param _collateralTokenId The tokenId for the collateral (if it is ERC721 or ERC1155).
     * @param _collateralTokenType The type of collateral token (ERC20,ERC721,ERC1177,None).
     * @param _loanDuration The duration of the loan in seconds delta.  Must be longer than loan payment cycle for the market.
     * @param _interestRate The amount of interest APY for the loan expressed in basis points.
     */
    function _submitBidFromCommitment(
        address _borrower,
        uint256 _marketId,
        address _principalTokenAddress,
        uint256 _principalAmount,
        address _collateralTokenAddress,
        uint256 _collateralAmount,
        uint256 _collateralTokenId,
        CommitmentCollateralType _collateralTokenType,
        uint32 _loanDuration,
        uint16 _interestRate
    ) internal returns (uint256 bidId) {
        CreateLoanArgs memory createLoanArgs;
        createLoanArgs.marketId = _marketId;
        createLoanArgs.lendingToken = _principalTokenAddress;
        createLoanArgs.principal = _principalAmount;
        createLoanArgs.duration = _loanDuration;
        createLoanArgs.interestRate = _interestRate;

        Collateral[] memory collateralInfo;
        if (_collateralTokenType != CommitmentCollateralType.NONE) {
            collateralInfo = new Collateral[](1);
            collateralInfo[0] = Collateral({
                _collateralType: _getEscrowCollateralType(_collateralTokenType),
                _tokenId: _collateralTokenId,
                _amount: _collateralAmount,
                _collateralAddress: _collateralTokenAddress
            });
        }

        bidId = _submitBidWithCollateral(
            createLoanArgs,
            collateralInfo,
            _borrower
        );
    }

    /**
     * @notice Return the collateral type based on the commitmentcollateral type.  Collateral type is used in the base lending protocol.
     * @param _type The type of collateral to be used for the loan.
     */
    function _getEscrowCollateralType(CommitmentCollateralType _type)
        internal
        pure
        returns (CollateralType)
    {
        if (_type == CommitmentCollateralType.ERC20) {
            return CollateralType.ERC20;
        }
        if (
            _type == CommitmentCollateralType.ERC721 ||
            _type == CommitmentCollateralType.ERC721_ANY_ID
        ) {
            return CollateralType.ERC721;
        }
        if (
            _type == CommitmentCollateralType.ERC1155 ||
            _type == CommitmentCollateralType.ERC1155_ANY_ID
        ) {
            return CollateralType.ERC1155;
        }

        revert("Unknown Collateral Type");
    }
}