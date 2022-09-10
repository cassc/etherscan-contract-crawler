// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ILoanCommon.sol";
import "./LoanStructures.sol";
import "./LoanComputations.sol";
import "./LoanAirdropHelper.sol";
import "../MainLoan.sol";
import "../../utils/NftAcceptor.sol";
import "../../utils/SignHelper.sol";
import "../../interfaces/IDispatcher.sol";
import "../../utils/KeysMapping.sol";
import "../../interfaces/ILoanManager.sol";
import "../../interfaces/INftWrapper.sol";
import "../../interfaces/IAllowedPartners.sol";
import "../../interfaces/IAllowedERC20s.sol";
import "../../interfaces/IAllowedNFTs.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract LoanCommonEssential is ILoanCommon, IAllowedERC20s, MainLoan, NftAcceptor, LoanStructures {
    using SafeERC20 for IERC20;

    uint16 public constant HUNDRED_PERCENT = 10000;

    bytes32 public immutable override LOAN_COORDINATOR;

    uint256 public override maximumLoanDuration = 53 weeks;

    uint16 public override adminFeeInBasisPoints = 25;

    mapping(uint32 => LoanTerms) public override loanIdToLoan;
    mapping(uint32 => LoanExtras) public loanIdToLoanExtras;

    mapping(uint32 => bool) public override loanRepaidOrLiquidated;

    mapping(address => mapping(uint256 => uint256)) private _escrowTokens;

    mapping(address => mapping(uint256 => bool)) internal _nonceHasBeenUsedForUser;

    mapping(address => bool) private erc20Permits;

    IDispatcher public immutable hub;

    event AdminFeeUpdated(uint16 newAdminFee);

    event MaximumLoanDurationUpdated(uint256 newMaximumLoanDuration);

    event LoanStarted(
        uint32 indexed loanId,
        address indexed borrower,
        address indexed lender,
        LoanTerms loanTerms,
        LoanExtras loanExtras
    );

    event LoanRepaid(
        uint32 indexed loanId,
        address indexed borrower,
        address indexed lender,
        uint256 loanPrincipalAmount,
        uint256 nftCollateralId,
        uint256 amountPaidToLender,
        uint256 adminFee,
        uint256 revenueShare,
        address revenueSharePartner,
        address nftCollateralContract,
        address loanERC20Denomination
    );

    event LoanLiquidated(
        uint32 indexed loanId,
        address indexed borrower,
        address indexed lender,
        uint256 loanPrincipalAmount,
        uint256 nftCollateralId,
        uint256 loanMaturityDate,
        uint256 loanLiquidationDate,
        address nftCollateralContract
    );

    event LoanRenegotiated(
        uint32 indexed loanId,
        address indexed borrower,
        address indexed lender,
        uint32 newLoanDuration,
        uint256 newMaximumRepaymentAmount,
        uint256 renegotiationFee,
        uint256 renegotiationAdminFee
    );

    event ERC20Permit(address indexed erc20Contract, bool isPermitted);

    constructor(
        address _admin,
        address _dispatcher,
        bytes32 _loanCoordinatorKey,
        address[] memory _allowedERC20s
    ) MainLoan(_admin) {
        hub = IDispatcher(_dispatcher);
        LOAN_COORDINATOR = _loanCoordinatorKey;
        for (uint256 i = 0; i < _allowedERC20s.length; i++) {
            _setERC20Permit(_allowedERC20s[i], true);
        }
    }

    function updateMaximumLoanDuration(uint256 _newMaximumLoanDuration) external onlyOwner {
        require(_newMaximumLoanDuration <= uint256(type(uint32).max), "Loan duration overflow");
        maximumLoanDuration = _newMaximumLoanDuration;
        emit MaximumLoanDurationUpdated(_newMaximumLoanDuration);
    }

    function updateAdminFee(uint16 _newAdminFeeInBasisPoints) external onlyOwner {
        require(_newAdminFeeInBasisPoints <= HUNDRED_PERCENT, "basis points > 10000");
        adminFeeInBasisPoints = _newAdminFeeInBasisPoints;
        emit AdminFeeUpdated(_newAdminFeeInBasisPoints);
    }

    function pipeERC20Airdrop(address _tokenAddress, address _receiver) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        require(amount > 0, "no tokens owned");
        tokenContract.safeTransfer(_receiver, amount);
    }

    function setERC20Permit(address _erc20, bool _permit) external onlyOwner {
        _setERC20Permit(_erc20, _permit);
    }

    function setERC20Permits(address[] memory _erc20s, bool[] memory _permits) external onlyOwner {
        require(_erc20s.length == _permits.length, "setERC20Permits function information arity mismatch");

        for (uint256 i = 0; i < _erc20s.length; i++) {
            _setERC20Permit(_erc20s[i], _permits[i]);
        }
    }

    function pipeERC721Airdrop(
        address _tokenAddress,
        uint256 _tokenId,
        address _receiver
    ) external onlyOwner {
        IERC721 tokenContract = IERC721(_tokenAddress);
        require(_escrowTokens[_tokenAddress][_tokenId] == 0, "token is collateral");
        require(tokenContract.ownerOf(_tokenId) == address(this), "nft not owned");
        tokenContract.safeTransferFrom(address(this), _receiver, _tokenId);
    }

    function pipeERC1155Airdrop(
        address _tokenAddress,
        uint256 _tokenId,
        address _receiver
    ) external onlyOwner {
        IERC1155 tokenContract = IERC1155(_tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this), _tokenId);
        require(_escrowTokens[_tokenAddress][_tokenId] == 0, "token is collateral");
        require(amount > 0, "no nfts owned");
        tokenContract.safeTransferFrom(address(this), _receiver, _tokenId, amount, "");
    }

    function mintObligationReceipt(uint32 _loanId) external nonReentrant {
        address borrower = loanIdToLoan[_loanId].borrower;
        require(msg.sender == borrower, "sender has to be borrower");

        ILoanManager loanCoordinator = ILoanManager(hub.getContract(LOAN_COORDINATOR));
        loanCoordinator.mintObligationReceipt(_loanId, borrower);

        delete loanIdToLoan[_loanId].borrower;
    }

    function renegotiateLoan(
        uint32 _loanId,
        uint32 _newLoanDuration,
        uint256 _newMaximumRepaymentAmount,
        uint256 _renegotiationFee,
        uint256 _lenderNonce,
        uint256 _expiry,
        bytes memory _lenderSignature
    ) external whenNotPaused nonReentrant {
        _renegotiateLoan(
            _loanId,
            _newLoanDuration,
            _newMaximumRepaymentAmount,
            _renegotiationFee,
            _lenderNonce,
            _expiry,
            _lenderSignature
        );
    }

    function payBackLoan(uint32 _loanId) external nonReentrant {
        LoanComputations.validatePayback(_loanId, hub);
        (
            address borrower,
            address lender,
            LoanTerms memory loan,
            ILoanManager loanCoordinator
        ) = _getLoanData(_loanId);

        _payBackLoan(_loanId, borrower, lender, loan);

        _resolveLoan(_loanId, borrower, loan, loanCoordinator);

        // Delete the loan from storage in order to achieve a substantial gas savings and to lessen the burden of
        // storage on Ethereum nodes, since we will never access this loan's details again, and the details are still
        // available through event data.
        delete loanIdToLoan[_loanId];
        delete loanIdToLoanExtras[_loanId];
    }

    function liquidateExpiredLoan(uint32 _loanId) external nonReentrant {
        LoanComputations.checkLoanIdValidity(_loanId, hub);
        // Sanity check that payBackLoan() and liquidateExpiredLoan() have never been called on this loanId.
        // Depending on how the rest of the code turns out, this check may be unnecessary.
        require(!loanRepaidOrLiquidated[_loanId], "Loan already repaid/liquidated");

        (
            address borrower,
            address lender,
            LoanTerms memory loan,
            ILoanManager loanCoordinator
        ) = _getLoanData(_loanId);

        // Ensure that the loan is indeed overdue, since we can only liquidate overdue loans.
        uint256 loanMaturityDate = uint256(loan.loanStartTime) + uint256(loan.loanDuration);
        require(block.timestamp > loanMaturityDate, "Loan is not overdue yet");

        require(msg.sender == lender, "Only lender can liquidate");

        _resolveLoan(_loanId, lender, loan, loanCoordinator);

        // Emit an event with all relevant details from this transaction.
        emit LoanLiquidated(
            _loanId,
            borrower,
            lender,
            loan.loanPrincipalAmount,
            loan.nftCollateralId,
            loanMaturityDate,
            block.timestamp,
            loan.nftCollateralContract
        );

        // Delete the loan from storage in order to achieve a substantial gas savings and to lessen the burden of
        // storage on Ethereum nodes, since we will never access this loan's details again, and the details are still
        // available through event data.
        delete loanIdToLoan[_loanId];
        delete loanIdToLoanExtras[_loanId];
    }

    function pullAirdrop(
        uint32 _loanId,
        address _target,
        bytes calldata _data,
        address _nftAirdrop,
        uint256 _nftAirdropId,
        bool _is1155,
        uint256 _nftAirdropAmount
    ) external nonReentrant {
        LoanComputations.checkLoanIdValidity(_loanId, hub);
        require(!loanRepaidOrLiquidated[_loanId], "Loan already repaid/liquidated");

        LoanTerms memory loan = loanIdToLoan[_loanId];

        LoanAirdropHelper.pullAirdrop(
            _loanId,
            loan,
            _target,
            _data,
            _nftAirdrop,
            _nftAirdropId,
            _is1155,
            _nftAirdropAmount,
            hub
        );
    }

    function wrapCollateral(uint32 _loanId) external nonReentrant {
        LoanComputations.checkLoanIdValidity(_loanId, hub);
        require(!loanRepaidOrLiquidated[_loanId], "Loan already repaid/liquidated");

        LoanTerms storage loan = loanIdToLoan[_loanId];

        _escrowTokens[loan.nftCollateralContract][loan.nftCollateralId] -= 1;
        (address instance, uint256 receiverId) = LoanAirdropHelper.wrapCollateral(_loanId, loan, hub);
        _escrowTokens[instance][receiverId] += 1;
    }

    function cancelNonceForUser(uint256 _nonce) external {
        require(!_nonceHasBeenUsedForUser[msg.sender][_nonce], "Invalid nonce");
        _nonceHasBeenUsedForUser[msg.sender][_nonce] = true;
    }

    function computePayoffAmount(uint32 _loanId) external view virtual returns (uint256);

    function hasNonceBeenUsedForUser(address _user, uint256 _nonce) external view override returns (bool) {
        return _nonceHasBeenUsedForUser[_user][_nonce];
    }

    function isERC20Permitted(address _erc20) public view override returns (bool) {
        return erc20Permits[_erc20];
    }

    function _renegotiateLoan(
        uint32 _loanId,
        uint32 _newLoanDuration,
        uint256 _newMaximumRepaymentAmount,
        uint256 _renegotiationFee,
        uint256 _lenderNonce,
        uint256 _expiry,
        bytes memory _lenderSignature
    ) internal {
        LoanTerms storage loan = loanIdToLoan[_loanId];

        (address borrower, address lender) = LoanComputations.validateRenegotiation(
            loan,
            _loanId,
            _newLoanDuration,
            _newMaximumRepaymentAmount,
            _lenderNonce,
            hub
        );

        _nonceHasBeenUsedForUser[lender][_lenderNonce] = true;

        require(
            SignHelper.checkLenderRenegotiationSignatureValidity(
                _loanId,
                _newLoanDuration,
                _newMaximumRepaymentAmount,
                _renegotiationFee,
                Signature({signer: lender, nonce: _lenderNonce, expiry: _expiry, signature: _lenderSignature})
            ),
            "Renegotiation signature is invalid"
        );

        uint256 renegotiationAdminFee;

        if (_renegotiationFee > 0) {
            renegotiationAdminFee = LoanComputations.getAdminFee(
                _renegotiationFee,
                loan.loanAdminFeeInBasisPoints
            );
            // Transfer principal-plus-interest-minus-fees from the caller (always has to be borrower) to lender
            IERC20(loan.loanERC20Denomination).safeTransferFrom(
                borrower,
                lender,
                _renegotiationFee - renegotiationAdminFee
            );
            // Transfer fees from the caller (always has to be borrower) to admins
            IERC20(loan.loanERC20Denomination).safeTransferFrom(borrower, owner(), renegotiationAdminFee);
        }

        loan.loanDuration = _newLoanDuration;
        loan.maximumRepaymentAmount = _newMaximumRepaymentAmount;

        emit LoanRenegotiated(
            _loanId,
            borrower,
            lender,
            _newLoanDuration,
            _newMaximumRepaymentAmount,
            _renegotiationFee,
            renegotiationAdminFee
        );
    }

    function _createLoan(
        bytes32 _loanType,
        LoanTerms memory _loanTerms,
        LoanExtras memory _loanExtras,
        address _borrower,
        address _lender,
        address _referrer
    ) internal returns (uint32) {
        // Transfer collateral from borrower to this contract to be held until
        // loan completion.
        _transferNFT(_loanTerms, _borrower, address(this));

        return _createLoanNoNftTransfer(_loanType, _loanTerms, _loanExtras, _borrower, _lender, _referrer);
    }

    function _createLoanNoNftTransfer(
        bytes32 _loanType,
        LoanTerms memory _loanTerms,
        LoanExtras memory _loanExtras,
        address _borrower,
        address _lender,
        address _referrer
    ) internal returns (uint32 loanId) {
        _escrowTokens[_loanTerms.nftCollateralContract][_loanTerms.nftCollateralId] += 1;

        uint256 referralfee = LoanComputations.getReferralFee(
            _loanTerms.loanPrincipalAmount,
            _loanExtras.referralFeeInBasisPoints,
            _referrer
        );
        uint256 principalAmount = _loanTerms.loanPrincipalAmount - referralfee;
        if (referralfee > 0) {
            // Transfer the referral fee from lender to referrer.
            IERC20(_loanTerms.loanERC20Denomination).safeTransferFrom(_lender, _referrer, referralfee);
        }
        // Transfer principal from lender to borrower.
        IERC20(_loanTerms.loanERC20Denomination).safeTransferFrom(_lender, _borrower, principalAmount);

        // Issue an ERC721 promissory note to the lender that gives them the
        // right to either the principal-plus-interest or the collateral,
        // and an obligation note to the borrower that gives them the
        // right to pay back the loan and get the collateral back.
        ILoanManager loanCoordinator = ILoanManager(hub.getContract(LOAN_COORDINATOR));
        loanId = loanCoordinator.registerLoan(_lender, _loanType);

        // Add the loan to storage before moving collateral/principal to follow
        // the Checks-Effects-Interactions pattern.
        loanIdToLoan[loanId] = _loanTerms;
        loanIdToLoanExtras[loanId] = _loanExtras;

        return loanId;
    }

    function _transferNFT(
        LoanTerms memory _loanTerms,
        address _sender,
        address _recipient
    ) internal {
        Address.functionDelegateCall(
            _loanTerms.nftCollateralWrapper,
            abi.encodeWithSelector(
                INftWrapper(_loanTerms.nftCollateralWrapper).transferNFT.selector,
                _sender,
                _recipient,
                _loanTerms.nftCollateralContract,
                _loanTerms.nftCollateralId
            ),
            "NFT not successfully transferred"
        );
    }

    function _payBackLoan(
        uint32 _loanId,
        address _borrower,
        address _lender,
        LoanTerms memory _loan
    ) internal {
        // Fetch loan details from storage, but store them in memory for the sake of saving gas.
        LoanExtras memory loanExtras = loanIdToLoanExtras[_loanId];

        (uint256 adminFee, uint256 payoffAmount) = _payoffAndFee(_loan);

        // Transfer principal-plus-interest-minus-fees from the caller to lender
        IERC20(_loan.loanERC20Denomination).safeTransferFrom(msg.sender, _lender, payoffAmount);

        uint256 revenueShare = LoanComputations.getRevenueShare(
            adminFee,
            loanExtras.revenueShareInBasisPoints
        );
        // AllowedPartners contract doesn't allow to set a revenueShareInBasisPoints for address zero so revenuShare
        // > 0 implies that revenueSharePartner ~= address(0), BUT revenueShare can be zero for a partener when the
        // adminFee is low
        if (revenueShare > 0 && loanExtras.revenueSharePartner != address(0)) {
            adminFee -= revenueShare;
            // Transfer revenue share from the caller to permitted partner
            IERC20(_loan.loanERC20Denomination).safeTransferFrom(
                msg.sender,
                loanExtras.revenueSharePartner,
                revenueShare
            );
        }
        // Transfer fees from the caller to admins
        IERC20(_loan.loanERC20Denomination).safeTransferFrom(msg.sender, owner(), adminFee);

        // Emit an event with all relevant details from this transaction.
        emit LoanRepaid(
            _loanId,
            _borrower,
            _lender,
            _loan.loanPrincipalAmount,
            _loan.nftCollateralId,
            payoffAmount,
            adminFee,
            revenueShare,
            loanExtras.revenueSharePartner, // this could be a non address zero even if revenueShare is 0
            _loan.nftCollateralContract,
            _loan.loanERC20Denomination
        );
    }

    function _resolveLoan(
        uint32 _loanId,
        address _nftAcceptor,
        LoanTerms memory _loanTerms,
        ILoanManager _loanCoordinator
    ) internal {
        _resolveLoanNoNftTransfer(_loanId, _loanTerms, _loanCoordinator);
        // Transfer collateral from this contract to the lender, since the lender is seizing collateral for an overdue
        // loan
        _transferNFT(_loanTerms, address(this), _nftAcceptor);
    }

    function _resolveLoanNoNftTransfer(
        uint32 _loanId,
        LoanTerms memory _loanTerms,
        ILoanManager _loanCoordinator
    ) internal {
        // Mark loan as liquidated before doing any external transfers to follow the Checks-Effects-Interactions design
        // pattern
        loanRepaidOrLiquidated[_loanId] = true;

        _escrowTokens[_loanTerms.nftCollateralContract][_loanTerms.nftCollateralId] -= 1;

        // Destroy the lender's promissory note for this loan and borrower obligation receipt
        _loanCoordinator.resolveLoan(_loanId);
    }

    function _setERC20Permit(address _erc20, bool _permit) internal {
        require(_erc20 != address(0), "erc20 is zero address");

        erc20Permits[_erc20] = _permit;

        emit ERC20Permit(_erc20, _permit);
    }

    function _loanSanityChecks(LoanStructures.Offer memory _offer, address _nftWrapper) internal view {
        require(isERC20Permitted(_offer.loanERC20Denomination), "Currency denomination is not permitted");
        require(_nftWrapper != address(0), "NFT collateral contract is not permitted");
        require(uint256(_offer.loanDuration) <= maximumLoanDuration, "Loan duration exceeds maximum loan duration");
        require(uint256(_offer.loanDuration) != 0, "Loan duration cannot be zero");
        require(
            _offer.loanAdminFeeInBasisPoints == adminFeeInBasisPoints,
            "The admin fee has changed since this order was signed."
        );
    }

    function _getLoanData(uint32 _loanId)
        internal
        view
        returns (
            address borrower,
            address lender,
            LoanTerms memory loan,
            ILoanManager loanCoordinator
        )
    {
        loanCoordinator = ILoanManager(hub.getContract(LOAN_COORDINATOR));
        ILoanManager.Loan memory loanCoordinatorData = loanCoordinator.getLoanData(_loanId);
        uint256 notesNftId = loanCoordinatorData.notesNftId;
        // Fetch loan details from storage, but store them in memory for the sake of saving gas.
        loan = loanIdToLoan[_loanId];
        if (loan.borrower != address(0)) {
            borrower = loan.borrower;
        } else {
            // Fetch current owner of loan obligation note.
            borrower = IERC721(loanCoordinator.obligationReceiptToken()).ownerOf(notesNftId);
        }
        lender = IERC721(loanCoordinator.promissoryNoteToken()).ownerOf(notesNftId);
    }

    function _setupLoanExtras(address _revenueSharePartner, uint16 _referralFeeInBasisPoints)
        internal
        view
        returns (LoanExtras memory)
    {
        // Save loan details to a struct in memory first, to save on gas if any
        // of the below checks fail, and to avoid the "Stack Too Deep" error by
        // clumping the parameters together into one struct held in memory.
        return
            LoanExtras({
                revenueSharePartner: _revenueSharePartner,
                revenueShareInBasisPoints: LoanComputations.getRevenueSharePercent(_revenueSharePartner, hub),
                referralFeeInBasisPoints: _referralFeeInBasisPoints
            });
    }

    function _payoffAndFee(LoanTerms memory _loanTerms) internal view virtual returns (uint256, uint256);

    function _getWrapper(address _nftCollateralContract) internal view returns (address) {
        return IAllowedNFTs(hub.getContract(KeysMapping.PERMITTED_NFTS)).getNFTWrapper(_nftCollateralContract);
    }
}