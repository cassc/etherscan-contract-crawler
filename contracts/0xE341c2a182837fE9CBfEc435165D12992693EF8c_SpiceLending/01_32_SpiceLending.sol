// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "../interfaces/ISpiceLending.sol";
import "../interfaces/INote.sol";

interface ISpiceFiNFT4626 {
    function asset() external view returns (address);

    function tokenShares(uint256 tokenId) external view returns (uint256);

    function previewRedeem(
        uint256 shares
    ) external view returns (uint256 assets);

    function deposit(
        uint256 tokenId,
        uint256 assets
    ) external returns (uint256 shares);

    function withdraw(
        uint256 tokenId,
        uint256 assets,
        address receiver
    ) external returns (uint256 shares);
}

/**
 * @title Storage for SpiceLending
 * @author Spice Finance Inc
 */
abstract contract SpiceLendingStorage {
    /// @notice loan id tracker
    CountersUpgradeable.Counter internal loanIdTracker;

    /// @notice keep track of loans
    mapping(uint256 => LibLoan.LoanData) public loans;

    /// @notice Lender Note
    INote public lenderNote;

    /// @notice Borrwoer Note
    INote public borrowerNote;

    /// @notice Interest fee rate
    uint256 public interestFee;

    /// @notice Liquidation ratio
    uint256 public liquidationRatio;

    /// @notice Liquidation fee
    uint256 public liquidationFeeRatio;

    /// @notice Loan ratio
    uint256 public loanRatio;

    /// @notice Signature used
    mapping(bytes32 => bool) public signatureUsed;

    /// @notice Collateral contract => Collateral Id => Loan Id
    mapping(address => mapping(uint256 => uint256)) public collateralToLoanId;

    /// @notice Borrower => List of loan ids
    mapping(address => EnumerableSetUpgradeable.UintSet) internal activeLoans;
}

/**
 * @title SpiceLending
 * @author Spice Finance Inc
 */
contract SpiceLending is
    ISpiceLending,
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    EIP712Upgradeable,
    ERC721Holder,
    SpiceLendingStorage
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /*************/
    /* Constants */
    /*************/

    /// @notice Spice role
    bytes32 public constant SPICE_ROLE = keccak256("SPICE_ROLE");

    /// @notice Spice NFT role
    bytes32 public constant SPICE_NFT_ROLE = keccak256("SPICE_NFT_ROLE");

    /// @notice Signer role
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    /// @notice Interest denominator
    uint256 public constant DENOMINATOR = 10000;

    /// @notice Seconds per year
    uint256 public constant ONE_YEAR = 365 days;

    /**********/
    /* Errors */
    /**********/

    /// @notice LoanTerms expired
    error LoanTermsExpired();

    /// @notice Invalid loan terms
    error InvalidLoanTerms();

    /// @notice Invalid address (e.g. zero address)
    error InvalidAddress();

    /// @notice Parameter out of bounds
    error ParameterOutOfBounds();

    /// @notice Invalid Signature
    error InvalidSignature();

    /// @notice Invalid Signer
    error InvalidSigner();

    /// @notice Invalid msg.sender
    error InvalidMsgSender();

    /// @notice Invalid Loan State
    /// @param state Current loan state
    error InvalidState(LibLoan.LoanState state);

    /// @notice Loan Ended
    error NotLiquidatible();

    /// @notice Signature Used
    error SignatureUsed(bytes signature);

    /// @notice loanAmount Exceeds Max LTV
    error LoanAmountExceeded();

    /// @notice Signer not enabled
    error SignerNotEnabled();

    /***************/
    /* Constructor */
    /***************/

    /// @notice SpiceLending constructor (for proxy)
    /// @param _signer Signer address
    /// @param _lenderNote Lender note contract address
    /// @param _borrowerNote Borrower note contract address
    /// @param _interestFee Interest fee rate
    /// @param _liquidationRatio Liquidation ratio
    /// @param _liquidationFeeRatio Liquidation fee
    /// @param _loanRatio Loan ratio
    function initialize(
        address _signer,
        INote _lenderNote,
        INote _borrowerNote,
        uint256 _interestFee,
        uint256 _liquidationRatio,
        uint256 _liquidationFeeRatio,
        uint256 _loanRatio,
        address _feeRecipient
    ) external initializer {
        if (_signer == address(0)) {
            revert InvalidAddress();
        }
        if (address(_lenderNote) == address(0)) {
            revert InvalidAddress();
        }
        if (address(_borrowerNote) == address(0)) {
            revert InvalidAddress();
        }
        if (_interestFee > DENOMINATOR) {
            revert ParameterOutOfBounds();
        }
        if (_liquidationRatio > DENOMINATOR) {
            revert ParameterOutOfBounds();
        }
        if (_liquidationFeeRatio > DENOMINATOR) {
            revert ParameterOutOfBounds();
        }
        if (_loanRatio > DENOMINATOR) {
            revert ParameterOutOfBounds();
        }
        if (_feeRecipient == address(0)) {
            revert InvalidAddress();
        }

        __EIP712_init("Spice Finance", "1");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SIGNER_ROLE, _signer);
        _grantRole(SPICE_ROLE, _feeRecipient);

        lenderNote = _lenderNote;
        borrowerNote = _borrowerNote;
        interestFee = _interestFee;
        liquidationRatio = _liquidationRatio;
        liquidationFeeRatio = _liquidationFeeRatio;
        loanRatio = _loanRatio;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /***********/
    /* Setters */
    /***********/

    /// @notice Set the interest fee rate
    ///
    /// Emits a {InterestFeeUpdated} event.
    ///
    /// @param _interestFee Interest fee rate
    function setInterestFee(
        uint256 _interestFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_interestFee > DENOMINATOR) {
            revert ParameterOutOfBounds();
        }
        interestFee = _interestFee;

        emit InterestFeeUpdated(_interestFee);
    }

    /// @notice Set the liquidation ratio
    ///
    /// Emits a {LiquidationRatioUpdated} event.
    ///
    /// @param _liquidationRatio Liquidation ratio
    function setLiquidationRatio(
        uint256 _liquidationRatio
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_liquidationRatio > DENOMINATOR) {
            revert ParameterOutOfBounds();
        }
        liquidationRatio = _liquidationRatio;

        emit LiquidationRatioUpdated(_liquidationRatio);
    }

    /// @notice Set the liquidation ratio
    ///
    /// Emits a {LiquidationFeeRatioUpdated} event.
    ///
    /// @param _liquidationFeeRatio Liquidation ratio
    function setLiquidationFeeRatio(
        uint256 _liquidationFeeRatio
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_liquidationFeeRatio > DENOMINATOR) {
            revert ParameterOutOfBounds();
        }
        liquidationFeeRatio = _liquidationFeeRatio;

        emit LiquidationFeeRatioUpdated(_liquidationFeeRatio);
    }

    /// @notice Set the loan ratio
    ///
    /// Emits a {LoanRatioUpdated} event.
    ///
    /// @param _loanRatio Loan ratio
    function setLoanRatio(
        uint256 _loanRatio
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_loanRatio > DENOMINATOR) {
            revert ParameterOutOfBounds();
        }
        loanRatio = _loanRatio;

        emit LoanRatioUpdated(_loanRatio);
    }

    /******************/
    /* User Functions */
    /******************/

    /// @notice See {ISpiceLending-initiateLoan}
    function initiateLoan(
        LibLoan.LoanTerms calldata _terms,
        bytes calldata _signature
    ) external nonReentrant returns (uint256 loanId) {
        // check loan terms expiration
        if (block.timestamp > _terms.expiration) {
            revert LoanTermsExpired();
        }

        // check borrower
        if (msg.sender != _terms.borrower) {
            revert InvalidMsgSender();
        }

        // check loan amount
        uint256 collateral = _getCollateralAmount(
            _terms.collateralAddress,
            _terms.collateralId
        );
        if (_terms.loanAmount > (collateral * loanRatio) / DENOMINATOR) {
            revert LoanAmountExceeded();
        }

        // check if signature is used
        _checkSignatureUsage(_signature);

        // verify loan terms signature
        _verifyLoanTermsSignature(_terms, _signature);

        // get current loanId
        loanIdTracker.increment();
        loanId = loanIdTracker.current();

        activeLoans[msg.sender].add(loanId);

        // initiate new loan
        loans[loanId] = LibLoan.LoanData({
            state: LibLoan.LoanState.Active,
            terms: _terms,
            startedAt: block.timestamp,
            balance: _terms.loanAmount,
            interestAccrued: 0,
            updatedAt: block.timestamp
        });
        collateralToLoanId[_terms.collateralAddress][
            _terms.collateralId
        ] = loanId;

        // mint notes
        _mintNote(loanId, _terms.lender, _terms.borrower);

        // transfer NFT collateral
        IERC721Upgradeable(_terms.collateralAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _terms.collateralId
        );

        // deposit borrowed funds on behalf of borrower
        IERC20Upgradeable(_terms.currency).safeTransferFrom(
            _terms.lender,
            address(this),
            _terms.loanAmount
        );

        IERC20Upgradeable(_terms.currency).safeApprove(
            _terms.collateralAddress,
            _terms.loanAmount
        );
        ISpiceFiNFT4626(_terms.collateralAddress).deposit(
            _terms.collateralId,
            _terms.loanAmount
        );

        emit LoanStarted(loanId, msg.sender);
    }

    /// @notice See {ISpiceLending-updateLoan}
    function updateLoan(
        uint256 _loanId,
        LibLoan.LoanTerms calldata _terms,
        bytes calldata _signature
    ) external nonReentrant {
        // get loan data
        LibLoan.LoanData storage data = loans[_loanId];

        // check loan state
        if (data.state != LibLoan.LoanState.Active) {
            revert InvalidState(data.state);
        }

        // calc interestAccrued and reset interestAccrued and updatedAt
        uint256 interestAccrued = _calcInterest(data);
        data.interestAccrued = 0;
        data.updatedAt = block.timestamp;

        // check borrower & lender
        address lender = lenderNote.ownerOf(_loanId);
        if (
            msg.sender != data.terms.borrower &&
            msg.sender != lender &&
            !hasRole(SIGNER_ROLE, msg.sender)
        ) {
            revert InvalidMsgSender();
        }
        if (_terms.lender != lender) {
            revert InvalidMsgSender();
        }

        // check loan amount
        uint256 collateral = _getCollateralAmount(
            _terms.collateralAddress,
            _terms.collateralId
        );
        if (_terms.loanAmount > (collateral * loanRatio) / DENOMINATOR) {
            revert LoanAmountExceeded();
        }

        // check if signature is used
        _checkSignatureUsage(_signature);

        // validate loan terms
        _validateLoanTerms(data, _terms);

        // verify loan terms signature
        _verifyLoanTermsSignature(_terms, _signature);

        uint256 additionalTransfer = _terms.loanAmount >
            (data.balance + interestAccrued)
            ? (_terms.loanAmount - data.balance - interestAccrued)
            : 0;

        // update loan
        data.terms = _terms;
        data.balance = _terms.loanAmount;
        data.startedAt = block.timestamp;

        if (additionalTransfer > 0) {
            IERC20Upgradeable(_terms.currency).safeTransferFrom(
                lender,
                address(this),
                additionalTransfer
            );
            IERC20Upgradeable(_terms.currency).safeApprove(
                _terms.collateralAddress,
                additionalTransfer
            );
            ISpiceFiNFT4626(_terms.collateralAddress).deposit(
                _terms.collateralId,
                additionalTransfer
            );
        }

        emit LoanUpdated(_loanId);
    }

    /// @notice See {ISpiceLending-deposit}
    function deposit(
        uint256 _loanId,
        uint256 _amount
    ) external nonReentrant returns (uint256 shares) {
        LibLoan.LoanData storage data = loans[_loanId];

        // deposit funds on behalf of borrower
        IERC20Upgradeable(data.terms.currency).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        IERC20Upgradeable(data.terms.currency).safeApprove(
            data.terms.collateralAddress,
            _amount
        );
        shares = ISpiceFiNFT4626(data.terms.collateralAddress).deposit(
            data.terms.collateralId,
            _amount
        );
    }

    /// @notice See {ISpiceLending-withdraw}
    function withdraw(
        uint256 _loanId,
        uint256 _amount
    ) external nonReentrant returns (uint256 shares) {
        LibLoan.LoanData storage data = loans[_loanId];

        if (msg.sender != data.terms.borrower) {
            revert InvalidMsgSender();
        }

        uint256 collateral = _getCollateralAmount(
            data.terms.collateralAddress,
            data.terms.collateralId
        );
        uint256 interestToPay = _calcInterest(data);
        uint256 payment = data.balance + interestToPay;

        if (
            _amount >
            collateral -
                data.terms.loanAmount -
                ((payment * DENOMINATOR) / loanRatio)
        ) {
            revert LoanAmountExceeded();
        }

        // withdraw funds and transfer to borrower
        shares = ISpiceFiNFT4626(data.terms.collateralAddress).withdraw(
            data.terms.collateralId,
            _amount,
            msg.sender
        );
    }

    /// @notice See {ISpiceLending-partialRepay}
    function partialRepay(
        uint256 _loanId,
        uint256 _payment
    ) external nonReentrant {
        LibLoan.LoanData storage data = loans[_loanId];
        if (data.state != LibLoan.LoanState.Active) {
            revert InvalidState(data.state);
        }

        address lender = lenderNote.ownerOf(_loanId);
        address borrower = data.terms.borrower;

        if (msg.sender != borrower) {
            revert InvalidMsgSender();
        }

        // calc total interest to pay
        uint256 interestToPay = _calcInterest(data);
        uint256 totalAmountToPay = data.balance + interestToPay;

        if (_payment > totalAmountToPay) {
            _payment = totalAmountToPay;
        }

        uint256 interestPayment;
        if (_payment > interestToPay) {
            interestPayment = interestToPay;
            data.balance -= _payment - interestToPay;
            data.interestAccrued = 0;
        } else {
            interestPayment = _payment;
            data.interestAccrued = interestToPay - _payment;
        }

        // update loan data
        data.updatedAt = block.timestamp;

        IERC20Upgradeable currency = IERC20Upgradeable(data.terms.currency);

        _transferRepayment(
            data.terms.collateralAddress,
            data.terms.collateralId,
            address(currency),
            borrower,
            _payment
        );

        uint256 fee = (interestPayment * interestFee) / DENOMINATOR;
        currency.safeTransfer(lender, _payment - fee);

        address feesAddr = getRoleMember(SPICE_ROLE, 0);
        if (feesAddr != address(0)) {
            currency.safeTransfer(feesAddr, fee);
        }

        // if loan is fully repaid
        if (_payment == totalAmountToPay) {
            data.state = LibLoan.LoanState.Repaid;

            // burn notes
            lenderNote.burn(_loanId);
            borrowerNote.burn(_loanId);

            activeLoans[borrower].remove(_loanId);

            collateralToLoanId[data.terms.collateralAddress][
                data.terms.collateralId
            ] = 0;

            // return collateral NFT to borrower
            IERC721Upgradeable(data.terms.collateralAddress).safeTransferFrom(
                address(this),
                borrower,
                data.terms.collateralId
            );
        }

        emit LoanRepaid(_loanId);
    }

    /// @notice See {ISpiceLending-repay}
    function repay(uint256 _loanId) external nonReentrant {
        LibLoan.LoanData storage data = loans[_loanId];
        if (data.state != LibLoan.LoanState.Active) {
            revert InvalidState(data.state);
        }

        address lender = lenderNote.ownerOf(_loanId);
        address borrower = data.terms.borrower;

        if (msg.sender != borrower) {
            revert InvalidMsgSender();
        }

        // update loan state to Repaid
        data.state = LibLoan.LoanState.Repaid;

        // calc total interest to pay
        uint256 interestToPay = _calcInterest(data);
        uint256 payment = data.balance + interestToPay;

        // update loan data
        data.balance = 0;
        data.interestAccrued = 0;
        data.updatedAt = block.timestamp;

        IERC20Upgradeable currency = IERC20Upgradeable(data.terms.currency);

        _transferRepayment(
            data.terms.collateralAddress,
            data.terms.collateralId,
            address(currency),
            borrower,
            payment
        );

        uint256 fee = (interestToPay * interestFee) / DENOMINATOR;
        currency.safeTransfer(lender, payment - fee);

        address feesAddr = getRoleMember(SPICE_ROLE, 0);
        if (feesAddr != address(0)) {
            currency.safeTransfer(feesAddr, fee);
        }

        // burn notes
        lenderNote.burn(_loanId);
        borrowerNote.burn(_loanId);

        activeLoans[borrower].remove(_loanId);

        collateralToLoanId[data.terms.collateralAddress][
            data.terms.collateralId
        ] = 0;

        // return collateral NFT to borrower
        IERC721Upgradeable(data.terms.collateralAddress).safeTransferFrom(
            address(this),
            borrower,
            data.terms.collateralId
        );

        emit LoanRepaid(_loanId);
    }

    /// @notice See {ISpiceLending-liquidate}
    function liquidate(uint256 _loanId) external nonReentrant {
        LibLoan.LoanData storage data = loans[_loanId];
        if (data.state != LibLoan.LoanState.Active) {
            revert InvalidState(data.state);
        }

        // time based liquidation
        uint32 duration = data.terms.duration;
        uint256 loanEndTime = data.startedAt + duration;
        uint256 owedAmount = data.balance + _calcInterest(data);
        if (loanEndTime > block.timestamp) {
            if (data.terms.priceLiquidation) {
                // price liquidation
                uint256 collateral = _getCollateralAmount(
                    data.terms.collateralAddress,
                    data.terms.collateralId
                );
                if (
                    owedAmount <= (collateral * liquidationRatio) / DENOMINATOR
                ) {
                    revert NotLiquidatible();
                }
            } else {
                revert NotLiquidatible();
            }
        }

        // update loan state to Defaulted
        data.state = LibLoan.LoanState.Defaulted;

        address lender = lenderNote.ownerOf(_loanId);
        address borrower = borrowerNote.ownerOf(_loanId);

        // send owed amount to lender
        ISpiceFiNFT4626(data.terms.collateralAddress).withdraw(
            data.terms.collateralId,
            (owedAmount * (DENOMINATOR + liquidationFeeRatio)) / DENOMINATOR,
            lender
        );

        // burn notes
        lenderNote.burn(_loanId);
        borrowerNote.burn(_loanId);

        activeLoans[borrower].remove(_loanId);

        collateralToLoanId[data.terms.collateralAddress][
            data.terms.collateralId
        ] = 0;

        IERC721Upgradeable(data.terms.collateralAddress).safeTransferFrom(
            address(this),
            borrower,
            data.terms.collateralId
        );

        emit LoanLiquidated(_loanId);
    }

    /******************/
    /* View Functions */
    /******************/

    /// @notice See {ISpiceLending-getLoanData}
    function getLoanData(
        uint256 _loanId
    ) external view returns (LibLoan.LoanData memory) {
        return loans[_loanId];
    }

    /// @notice See {ISpiceLending-getNextLoanId}
    function getNextLoanId() external view returns (uint256) {
        return loanIdTracker.current() + 1;
    }

    /// @notice See {ISpiceLending-getActiveLoans}
    function getActiveLoans(
        address borrower
    ) external view returns (uint256[] memory) {
        return activeLoans[borrower].values();
    }

    /// @notice See {ISpiceLending-repayAmount}
    function repayAmount(uint256 _loanId) external view returns (uint256) {
        LibLoan.LoanData storage data = loans[_loanId];
        if (data.state != LibLoan.LoanState.Active) {
            revert InvalidState(data.state);
        }
        return data.balance + _calcInterest(data);
    }

    /**********************/
    /* Internal Functions */
    /**********************/

    /// @dev Check if the signature is used
    /// @param _signature Signature
    function _checkSignatureUsage(bytes calldata _signature) internal {
        bytes32 sigHash = keccak256(_signature);
        if (signatureUsed[sigHash]) {
            revert SignatureUsed(_signature);
        }
        signatureUsed[sigHash] = true;
    }

    /// @dev Verify loan terms signature
    /// @param _terms Loan terms
    /// @param _signature Signature
    function _verifyLoanTermsSignature(
        LibLoan.LoanTerms calldata _terms,
        bytes calldata _signature
    ) internal view {
        // check if the loan terms is signed by signer
        bytes32 termsHash = LibLoan.getLoanTermsHash(_terms);
        _verifySignature(termsHash, _signature, _terms.lender);
    }

    /// @dev Verify signature
    /// @param _termsHash Hash for terms
    /// @param _signature Signature
    /// @param _lender Lender address
    function _verifySignature(
        bytes32 _termsHash,
        bytes calldata _signature,
        address _lender
    ) internal view {
        bytes32 hash = _hashTypedDataV4(_termsHash);
        address recoveredSigner = ECDSA.recover(hash, _signature);
        if (
            getRoleMemberCount(SIGNER_ROLE) > 0 &&
            !hasRole(SIGNER_ROLE, recoveredSigner)
        ) {
            revert SignerNotEnabled();
        }

        if (recoveredSigner != _lender) {
            bytes4 magicValue = IERC1271(_lender).isValidSignature(
                hash,
                _signature
            );
            // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
            if (magicValue != 0x1626ba7e) {
                revert InvalidSigner();
            }
        }
    }

    /// @dev Validate loan terms
    /// @param oldData Current loan terms
    /// @param _newTerms New loan terms
    function _validateLoanTerms(
        LibLoan.LoanData storage oldData,
        LibLoan.LoanTerms calldata _newTerms
    ) internal view {
        // check loan terms expiration
        if (block.timestamp > _newTerms.expiration) {
            revert LoanTermsExpired();
        }
        if (oldData.terms.collateralAddress != _newTerms.collateralAddress) {
            revert InvalidLoanTerms();
        }
        if (oldData.terms.collateralId != _newTerms.collateralId) {
            revert InvalidLoanTerms();
        }
        if (oldData.balance >= _newTerms.loanAmount) {
            revert InvalidLoanTerms();
        }
        if (oldData.terms.borrower != _newTerms.borrower) {
            revert InvalidLoanTerms();
        }
        if (oldData.terms.currency != _newTerms.currency) {
            revert InvalidLoanTerms();
        }
        if (oldData.terms.priceLiquidation != _newTerms.priceLiquidation) {
            revert InvalidLoanTerms();
        }
    }

    /// @dev Mints new notes
    /// @param _loanId Loan ID
    /// @param _lender Lender address to receive lender note
    /// @param _borrower Lender address to receive lender note
    function _mintNote(
        uint256 _loanId,
        address _lender,
        address _borrower
    ) internal {
        lenderNote.mint(_lender, _loanId);
        borrowerNote.mint(_borrower, _loanId);
    }

    /// @dev Transfer repayment from borrower.
    ///      If the collateral NFT is Spice NFT, then withdraw from the vault
    /// @param _collateralAddress Collateral NFT address
    /// @param _collateralId Collateral NFT Id
    /// @param _currency Currenty address
    /// @param _borrower Borrower address
    /// @param _payment Repayment amount
    function _transferRepayment(
        address _collateralAddress,
        uint256 _collateralId,
        address _currency,
        address _borrower,
        uint256 _payment
    ) internal {
        if (
            hasRole(SPICE_NFT_ROLE, _collateralAddress) &&
            ISpiceFiNFT4626(_collateralAddress).asset() == _currency
        ) {
            // withdraw assets from spice nft vault
            ISpiceFiNFT4626(_collateralAddress).withdraw(
                _collateralId,
                _payment,
                address(this)
            );
        } else {
            IERC20Upgradeable(_currency).safeTransferFrom(
                _borrower,
                address(this),
                _payment
            );
        }
    }

    /// @dev Get collateral amount for Spice NFT
    /// @param _collateralAddress Collateral NFT address
    /// @param _collateralId Collateral NFT Id
    /// @return assets Collateral amount
    function _getCollateralAmount(
        address _collateralAddress,
        uint256 _collateralId
    ) internal view returns (uint256 assets) {
        uint256 shares = ISpiceFiNFT4626(_collateralAddress).tokenShares(
            _collateralId
        );
        assets = ISpiceFiNFT4626(_collateralAddress).previewRedeem(shares);
    }

    /// @dev Calc total interest to pay
    ///      Total Interest = Interest Accrued + New Interest since last repayment
    /// @param _data Loan data
    /// @return interest Total interest
    function _calcInterest(
        LibLoan.LoanData storage _data
    ) internal view returns (uint256 interest) {
        uint256 loanEndTime = _data.startedAt + _data.terms.duration;
        uint256 timeElapsed = (
            block.timestamp < loanEndTime ? block.timestamp : loanEndTime
        ) - _data.updatedAt;
        uint256 newInterest = (_data.balance *
            _data.terms.interestRate *
            timeElapsed) /
            DENOMINATOR /
            ONE_YEAR;

        return _data.interestAccrued + newInterest;
    }
}