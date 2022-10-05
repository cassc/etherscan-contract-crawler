pragma solidity 0.8.4;

import "./IXY3.sol";
import "./DataTypes.sol";
import "./LoanStatus.sol";
import "./Config.sol";
import "./utils/SigningUtils.sol";
import "./IDelegate.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract XY3 is IXY3, Config, LoanStatus {
    using SafeERC20 for IERC20;

    
    mapping(uint32 => LoanDetail) public override loanDetails;

    
    mapping(address => mapping(uint256 => bool)) internal _invalidNonce;

    
    mapping(address => uint256) internal _offerCancelTimestamp;

    
    modifier loanIsOpen(uint32 _loanId) {
        require(getLoanState(_loanId).status == StatusType.NEW, "Loan is not open");
        _;
    }

    
    address public delegate;
    
    constructor(
        address _admin,
        address _ticketToken,
        address _delegate
    ) Config(_admin) LoanStatus(_ticketToken) {
        delegate = _delegate;
    }

    

    
    function borrow(
        Offer memory _offer,
        uint256 _nftId,
        bool _isCollectionOffer,
        Signature memory _lenderSignature,
        Signature memory _brokerSignature
    ) external override whenNotPaused nonReentrant {
        _loanSanityChecks(_offer);
        _borrow(
            _createLoanDetail(_offer, _nftId, _isCollectionOffer),
            _offer,
            _nftId,
            _isCollectionOffer,
            _lenderSignature,
            _brokerSignature
        );
    }

    
    function repay(uint32 _loanId) external override nonReentrant loanIsOpen(_loanId) {
        (
            address borrower,
            address lender,
            LoanDetail memory loan
        ) = _getPartiesAndData(_loanId);

        require(block.timestamp  <= _loanMaturityDate(loan), "Loan is expired");

        (uint256 adminFee, uint256 payoffAmount) = _payoffAndFee(loan);

        
        IDelegate(delegate).erc20Transfer(msg.sender, lender, loan.borrowAsset, payoffAmount);

        
        IDelegate(delegate).erc20Transfer(msg.sender, adminFeeReceiver,loan.borrowAsset, adminFee);

        emit LoanRepaid(
            _loanId,
            borrower,
            lender,
            loan.borrowAmount,
            loan.nftTokenId,
            payoffAmount,
            adminFee,
            loan.nftAsset,
            loan.borrowAsset
        );

        _resolveLoan(_loanId, borrower, loan);
    }

    
    function liquidate(uint32 _loanId) external override nonReentrant loanIsOpen(_loanId) {
        (
            address borrower,
            address lender,
            LoanDetail memory loan
        ) = _getPartiesAndData(_loanId);

        uint256 loanMaturityDate = _loanMaturityDate(loan);
        require(block.timestamp > loanMaturityDate, "Loan is not overdue yet");

        require(msg.sender == lender, "Only lender can liquidate");

        
        emit LoanLiquidated(
            _loanId,
            borrower,
            lender,
            loan.borrowAmount,
            loan.nftTokenId,
            loanMaturityDate,
            block.timestamp,
            loan.nftAsset
        );

        _resolveLoan(_loanId, lender, loan);

    }

    
    function cancelByNonce(uint256 _nonce) override external {
        require(!_invalidNonce[msg.sender][_nonce], "Invalid nonce");
        _invalidNonce[msg.sender][_nonce] = true;
        emit NonceCancelled(msg.sender, _nonce);
    }

    
    function cancelByTimestamp(uint256 _timestamp) override external {
        require(_timestamp < block.timestamp, "Invalid timestamp");
        if (_timestamp >_offerCancelTimestamp[msg.sender]) {
            _offerCancelTimestamp[msg.sender] = _timestamp;
            emit TimeStampCancelled(msg.sender, _timestamp);
        }
    }

    
    function getRepayAmount(uint32 _loanId) external view override returns (uint256) {
        LoanDetail storage loan = loanDetails[_loanId];
        return loan.repayAmount;
    }

    
    function getNonceUsed(address _user, uint256 _nonce) external view override returns (bool) {
        return _invalidNonce[_user][_nonce];
    }

    
    function getTimestampCancelled(address _user) external override view returns (uint256) {
        return _offerCancelTimestamp[_user];
    }
    

    
    function _resolveLoan(
        uint32 _loanId,
        address _nftReceiver,
        LoanDetail memory _loanDetail
    ) internal {
        resolveLoan(_loanId);
        
        IERC721(_loanDetail.nftAsset).safeTransferFrom(address(this), _nftReceiver, _loanDetail.nftTokenId);
        delete loanDetails[_loanId];
    }

    
    function _loanSanityChecks(Offer memory _offer) internal view {
        require(getERC20Permit(_offer.borrowAsset), "Invalid currency");
        require(getERC721Permit(_offer.nftAsset), "Invalid ERC721 token");
        require(uint256(_offer.borrowDuration) <= maxBorrowDuration, "Invalid maximum duration");
        require(uint256(_offer.borrowDuration) >= minBorrowDuration, "Invalid minimum duration");
        require(
            _offer.repayAmount >= _offer.borrowAmount,
            "Invalid interest rate"
        );

        require(
            _offer.adminShare == adminShare,
            "Admin fee changed"
        );
    }

    function _getPartiesAndData(uint32 _loanId)
        internal
        view
        returns (
            address borrower,
            address lender,
            LoanDetail memory loan
        )
    {
        uint256 xy3NftId = getLoanState(_loanId).xy3NftId;
        loan = loanDetails[_loanId];
        borrower = loan.borrower;
        lender = IERC721(ticketToken).ownerOf(xy3NftId);
    }

    
    function _payoffAndFee(LoanDetail memory _loanDetail)
        internal
        pure
        returns (uint256 adminFee, uint256 payoffAmount)
    {
        uint256 interestDue = _loanDetail.repayAmount - _loanDetail.borrowAmount;
        adminFee =  (interestDue * _loanDetail.adminShare) / HUNDRED_PERCENT;
        payoffAmount = _loanDetail.repayAmount - adminFee;
    }

    
    function _borrow(
        LoanDetail memory _loanDetail,
        Offer memory _offer,
        uint256 _nftId,
        bool _isCollection,
        Signature memory _lenderSignature,
        Signature memory _brokerSignature
    ) internal {
        address _lender = _lenderSignature.signer;

        require(!_invalidNonce[_lender][_lenderSignature.nonce], "Lender nonce invalid");
        require(hasRole(SIGNER_ROLE, _brokerSignature.signer),"Invalid broker signer");
        require(_offerCancelTimestamp[_lender] < _offer.timestamp, "Offer cancelled");

        _checkSignatures(_offer, _nftId, _isCollection, _lenderSignature, _brokerSignature);

        _invalidNonce[_lender][_lenderSignature.nonce] = true;

        IDelegate(delegate).erc721Transfer(msg.sender, address(this),_loanDetail.nftAsset, _loanDetail.nftTokenId);

        IDelegate(delegate).erc20Transfer(_lender, msg.sender, _loanDetail.borrowAsset, _loanDetail.borrowAmount);

        
        uint32 loanId = createLoan(_lender);

        
        loanDetails[loanId] = _loanDetail;

        emit LoanStarted(loanId, msg.sender, _lenderSignature.signer, _lenderSignature.nonce, _loanDetail);
    }

    
    function _checkSignatures(Offer memory _offer,uint256 _nftId, bool _isCollection, Signature memory _lenderSignature, Signature memory _brokerSignature) private view {
        if (_isCollection) {
            require(SigningUtils.offerSignatureIsValid(_offer, _lenderSignature), "Lender signature is invalid");
        } else {
            require(SigningUtils.offerSignatureIsValid(_offer, _nftId, _lenderSignature), "Lender signature is invalid");
        }
        require(SigningUtils.offerSignatureIsValid(_offer, _nftId, _brokerSignature), "Signer signature is invalid");
    }

    
    function _createLoanDetail(Offer memory _offer, uint256 _nftId, bool _isCollection) internal view returns (LoanDetail memory) {
        return
            LoanDetail({
                borrowAsset: _offer.borrowAsset,
                borrowAmount: _offer.borrowAmount,
                repayAmount: _offer.repayAmount,
                nftAsset: _offer.nftAsset,
                nftTokenId: _nftId,
                loanStart: uint64(block.timestamp),
                loanDuration: _offer.borrowDuration,
                adminShare: _offer.adminShare,
                borrower: msg.sender,
                isCollection: _isCollection
            });
    }

    
    function _loanMaturityDate(LoanDetail memory loan) private pure returns (uint256) {
        return uint256(loan.loanStart) + uint256(loan.loanDuration);
    }
}