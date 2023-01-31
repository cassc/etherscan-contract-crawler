// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./interfaces/IXY3.sol";
import "./interfaces/IDelegateV3.sol";
import "./interfaces/IAddressProvider.sol";
import "./interfaces/IServiceFee.sol";
import {IFlashExecPermits} from "./interfaces/IFlashExecPermits.sol";
import "./DataTypes.sol";
import "./LoanStatus.sol";
import "./Config.sol";
import "./utils/SigningUtils.sol";
import {InterceptorManager} from "./InterceptorManager.sol";
import {SIGNER_ROLE} from "./Roles.sol";

/**
 * @title  XY3
 * @author XY3
 * @notice Main contract for XY3 lending.
 */
contract XY3 is
    IXY3,
    Config,
    LoanStatus,
    InterceptorManager,
    ERC721Holder,
    ERC1155Holder
{
    using SafeERC20 for IERC20;

    /**
     * @notice A mapping from a loan's identifier to the loan's terms, represted by the LoanTerms struct.
     */
    mapping(uint32 => LoanDetail) public override loanDetails;

    /**
     * @notice A mapping, (collection address, token Id) -> loan ID.
     */
    mapping(address => mapping(uint256 => uint32)) public override loanIds;

    /**
     * @notice A mapping, (user address , nonce) -> boolean.
     */
    mapping(address => mapping(uint256 => bool)) internal _invalidNonce;

    /**
     * @notice A mapping that takes a user's address and a cancel timestamp.
     *
     */
    mapping(address => uint256) internal _offerCancelTimestamp;

    /**
     * modifier
     */
    modifier loanIsOpen(uint32 _loanId) {
        require(
            getLoanState(_loanId).status == StatusType.NEW,
            "Loan is not open"
        );
        _;
    }

    /**
     * @dev Init contract
     *
     * @param _admin - Initial admin of this contract.
     * @param _addressProvider - AddressProvider contract
     */
    constructor(
        address _admin,
        address _addressProvider
    )
        Config(_admin, _addressProvider)
        LoanStatus()
        InterceptorManager()
    {
    }

    /**
     PUBLIC FUNCTIONS
     */

    /**
     * @dev The borrower accept a lender's offer to create a loan.
     *
     * @param _offer - The offer made by the lender.
     * @param _nftId - The ID
     * @param _isCollectionOffer - Wether the offer is a collection offer.
     * @param _lenderSignature - The lender's signature.
     * @param _brokerSignature - The broker's signature.
     * @param _extraDeal - Create a new loan by getting a NFT colleteral from external contract call.
     * The external contract can be lending market or deal market, specially included the restricted repay of myself.
     * But should not be the Xy3Nft.mint, though this contract maybe have the permission.
     */
    function borrow(
        Offer calldata _offer,
        uint256 _nftId,
        bool _isCollectionOffer,
        Signature calldata _lenderSignature,
        Signature calldata _brokerSignature,
        CallData calldata _extraDeal
    ) external override whenNotPaused nonReentrant returns (uint32) {
        _loanSanityChecks(_offer);
        address nftAsset = _offer.nftAsset;

        beforeBorrow(nftAsset, _nftId);
        LoanDetail memory _loanDetail = _createLoanDetail(
            _offer,
            _nftId,
            _isCollectionOffer
        );
        _checkBorrow(
            _offer,
            _nftId,
            _isCollectionOffer,
            _lenderSignature,
            _brokerSignature
        );

        IAddressProvider addressProvider = getAddressProvider();
        IDelegateV3(addressProvider.getTransferDelegate()).erc20Transfer(
            _lenderSignature.signer,
            msg.sender,
            _offer.borrowAsset,
            _offer.borrowAmount
        );

        if (_extraDeal.target != address(0)) {
            require(getAgentPermit(_extraDeal.target, _extraDeal.selector), "Not valide agent");
            bytes memory data = abi.encodeWithSelector(
                _extraDeal.selector,
                msg.sender,
                _extraDeal.data
            );
            (bool succ, ) = _extraDeal.target.call(data);
            require(succ, "Borrow extra call failed");
        }
        IDelegateV3(addressProvider.getTransferDelegate()).erc721Transfer(
            msg.sender,
            address(this),
            nftAsset,
            _nftId
        );

        uint32 loanId = _createBorrowNote(
            _lenderSignature.signer,
            msg.sender,
            _loanDetail,
            _lenderSignature,
            _extraDeal
        );

        _serviceFee(_offer, loanId, _extraDeal.target);

        loanIds[nftAsset][_nftId] = loanId;
        afterBorrow(nftAsset, _nftId);
        emit BorrowRefferal(loanId, msg.sender, _extraDeal.referral);

        return loanId;
    }

    /**
     * @dev Restricted function, only called by self from borrow with target.
     * @param _sender  The borrow's msg.sender.
     * @param _param  The borrow CallData's data, encode loadId only.
     */
    function repay(address _sender, bytes calldata _param) external {
        require(msg.sender == address(this), "Invalide caller");
        uint32 loanId = abi.decode(_param, (uint32));
        _repay(_sender, loanId);
    }

    /**
     * @dev Public function for anyone to repay a loan, and return the NFT token to origin borrower.
     * @param _loanId  The loan Id.
     */
    function repay(uint32 _loanId) public override nonReentrant {
        _repay(msg.sender, _loanId);
    }

    /**
     * @dev Lender ended the load which not paid by borrow and expired.
     *
     * @param _loanId The loan Id.
     */
    function liquidate(
        uint32 _loanId
    ) external override nonReentrant loanIsOpen(_loanId) {
        (
            address borrower,
            address lender,
            LoanDetail memory loan
        ) = _getPartiesAndData(_loanId);
        address nftAsset = loan.nftAsset;
        uint nftId = loan.nftTokenId;
        beforeLiquidate(nftAsset, nftId);

        uint256 loanMaturityDate = _loanMaturityDate(loan);
        require(block.timestamp > loanMaturityDate, "Loan is not overdue yet");

        require(msg.sender == lender, "Only lender can liquidate");

        // Emit an event with all relevant details from this transaction.
        emit LoanLiquidated(
            _loanId,
            borrower,
            lender,
            loan.borrowAmount,
            nftId,
            loanMaturityDate,
            block.timestamp,
            nftAsset
        );

        // nft to lender
        IERC721(nftAsset).safeTransferFrom(address(this), lender, nftId);
        _resolveLoanNote(_loanId);
        delete loanIds[nftAsset][nftId];

        afterLiquidate(nftAsset, nftId);
    }

    /**
     * @dev Flash out the colleteral NFT.
     *
     * @param _loanId The loan Id.
     * @param _target The target contract.
     * @param _selector The callback selector.
     * @param _data The callback data.
     */
    function flashExecute(
        uint32 _loanId,
        address _target,
        bytes4 _selector,
        bytes memory _data
    ) external {
        (address borrower, , LoanDetail memory loan) = _getPartiesAndData(
            _loanId
        );
        IAddressProvider addressProvider = getAddressProvider();
        require(
            IFlashExecPermits(addressProvider.getFlashExecPermits())
                .isPermitted(_target, _selector),
            "Invalid airdrop target"
        );
        require(block.timestamp <= _loanMaturityDate(loan), "Loan is expired");
        require(msg.sender == borrower, "Only borrower");
        IERC721(loan.nftAsset).safeTransferFrom(
            address(this),
            _target,
            loan.nftTokenId
        );
        (bool succ, ) = _target.call(
            abi.encodeWithSelector(_selector, msg.sender, _data)
        );
        require(succ, "External call failed");
        address owner = IERC721(loan.nftAsset).ownerOf(loan.nftTokenId);
        require(owner == address(this), "Nft not returned");
        emit FlashExecute(_loanId, loan.nftAsset, loan.nftTokenId, _target);
    }

    /**
     * @dev A lender or a borrower to cancel all off-chain orders signed that contain this nonce.
     * @param  _nonce - User nonce
     */
    function cancelByNonce(uint256 _nonce) external override {
        require(!_invalidNonce[msg.sender][_nonce], "Invalid nonce");
        _invalidNonce[msg.sender][_nonce] = true;
        emit NonceCancelled(msg.sender, _nonce);
    }

    /**
     * @dev A borrower cancel all offers with timestamp before the _timestamp parameter.
     * @param _timestamp - cancelled timestamp
     */
    function cancelByTimestamp(uint256 _timestamp) external override {
        require(_timestamp < block.timestamp, "Invalid timestamp");
        if (_timestamp > _offerCancelTimestamp[msg.sender]) {
            _offerCancelTimestamp[msg.sender] = _timestamp;
            emit TimeStampCancelled(msg.sender, _timestamp);
        }
    }

    /**
     * @dev The amount of ERC20 currency for the loan.
     *
     * @param _loanId  loan Id.
     * @return The amount of ERC20 currency.
     */
    function getRepayAmount(
        uint32 _loanId
    ) external view override returns (uint256) {
        LoanDetail storage loan = loanDetails[_loanId];
        return loan.repayAmount;
    }

    /**
     * @notice Check a nonce has been used or not
     * @param _user - The user address.
     * @param _nonce - The order Id.
     *
     * @return A bool for used or not.
     */
    function getNonceUsed(
        address _user,
        uint256 _nonce
    ) external view override returns (bool) {
        return _invalidNonce[_user][_nonce];
    }

    /**
     * @dev This function can be used to view the last cancel timestamp a borrower has set.
     * @param _user User address
     * @return The cancel timestamp
     */
    function getTimestampCancelled(
        address _user
    ) external view override returns (uint256) {
        return _offerCancelTimestamp[_user];
    }

    /**
     * @dev Claim the ERC20 airdrop by admin timelock.
     * @param  _to - Receiver address
     * @param  tokens - Claimed token list
     * @param  amounts - Clamined amount list
     */
    function adminClaimErc20(
        address _to,
        address[] memory tokens,
        uint256[] memory amounts
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_to != address(0x0), "Invalid address");
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            IERC20(token).safeTransfer(_to, amounts[i]);
        }
    }

    /**
     * @dev Claim the ERC721 airdrop by admin timelock.
     * @param  _to - Receiver address
     * @param  tokens - Claimed token list
     * @param  tokenIds - Clamined ID list
     */
    function adminClaimErc721(
        address _to,
        address[] memory tokens,
        uint256[] memory tokenIds
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 tokenId = tokenIds[i];
            uint32 loanId = loanIds[token][tokenId];
            if (loanId == 0) {
                IERC721(token).safeTransferFrom(
                    address(this),
                    _to,
                    tokenIds[i]
                );
            }
        }
    }

    /**
     * @dev Claim the ERC1155 airdrop by admin timelock.
     * @param  _to - Receiver address
     * @param  tokens - Claimed token list
     * @param  tokenIds - Clamined ID list
     * @param  amounts - Clamined amount list
     */
    function adminClaimErc1155(
        address _to,
        address[] memory tokens,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            IERC1155(token).safeTransferFrom(
                address(this),
                _to,
                tokenIds[i],
                amounts[i],
                ""
            );
        }
    }

    /**
     * @dev ERC165 support
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControl, ERC1155Receiver)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @param _loanId  Load Id.
     */
    function _resolveLoanNote(uint32 _loanId) internal {
        resolveLoan(_loanId);
        delete loanDetails[_loanId];
    }

    /**
     * @dev Check loan parameters validation
     *
     */
    function _loanSanityChecks(Offer memory _offer) internal view {
        require(getERC20Permit(_offer.borrowAsset), "Invalid currency");
        require(getERC721Permit(_offer.nftAsset), "Invalid ERC721 token");
        require(
            uint256(_offer.borrowDuration) <= maxBorrowDuration,
            "Invalid maximum duration"
        );
        require(
            uint256(_offer.borrowDuration) >= minBorrowDuration,
            "Invalid minimum duration"
        );
        require(
            _offer.repayAmount >= _offer.borrowAmount,
            "Invalid interest rate"
        );
    }

    function _getPartiesAndData(
        uint32 _loanId
    )
        internal
        view
        returns (address borrower, address lender, LoanDetail memory loan)
    {
        uint256 xy3NftId = getLoanState(_loanId).xy3NftId;
        loan = loanDetails[_loanId];

        borrower = IERC721(getAddressProvider().getBorrowerNote()).ownerOf(xy3NftId);
        lender = IERC721(getAddressProvider().getLenderNote()).ownerOf(xy3NftId);
    }

    /**
     * @dev Get the payoff amount and admin fee
     * @param _loanDetail - Loan parameters
     */
    function _payoffAndFee(
        LoanDetail memory _loanDetail
    ) internal pure returns (uint256 adminFee, uint256 payoffAmount) {
        uint256 interestDue = _loanDetail.repayAmount -
            _loanDetail.borrowAmount;
        adminFee = (interestDue * _loanDetail.adminShare) / HUNDRED_PERCENT;
        payoffAmount = _loanDetail.repayAmount - adminFee;
    }

    /**
     * @param _offer - Offer parameters
     * @param _nftId - NFI ID
     * @param _isCollection - is collection or not
     * @param _lenderSignature - lender signature
     * @param _brokerSignature - broker signature
     */
    function _checkBorrow(
        Offer memory _offer,
        uint256 _nftId,
        bool _isCollection,
        Signature memory _lenderSignature,
        Signature memory _brokerSignature
    ) internal view {
        address _lender = _lenderSignature.signer;

        require(
            !_invalidNonce[_lender][_lenderSignature.nonce],
            "Lender nonce invalid"
        );
        require(
            hasRole(SIGNER_ROLE, _brokerSignature.signer),
            "Invalid broker signer"
        );
        require(
            _offerCancelTimestamp[_lender] < _offer.timestamp,
            "Offer cancelled"
        );

        _checkSignatures(
            _offer,
            _nftId,
            _isCollection,
            _lenderSignature,
            _brokerSignature
        );
    }

    function _createBorrowNote(
        address _lender,
        address _borrower,
        LoanDetail memory _loanDetail,
        Signature memory _lenderSignature,
        CallData memory _extraDeal
    ) internal returns (uint32) {
        _invalidNonce[_lender][_lenderSignature.nonce] = true;
        // Mint ERC721 note to the lender and borrower
        uint32 loanId = createLoan(_lender, _borrower);
        // Record
        loanDetails[loanId] = _loanDetail;
        emit LoanStarted(
            loanId,
            msg.sender,
            _lenderSignature.signer,
            _lenderSignature.nonce,
            _loanDetail,
            _extraDeal.target,
            _extraDeal.selector
        );

        return loanId;
    }

    function _repay(
        address payer,
        uint32 _loanId
    ) internal loanIsOpen(_loanId) {
        (
            address borrower,
            address lender,
            LoanDetail memory loan
        ) = _getPartiesAndData(_loanId);
        require(block.timestamp <= _loanMaturityDate(loan), "Loan is expired");

        address nftAsset = loan.nftAsset;
        uint nftId = loan.nftTokenId;

        beforeRepay(nftAsset, nftId);
        IERC721(nftAsset).safeTransferFrom(address(this), borrower, nftId);

        // pay from the payer
        _repayAsset(payer, borrower, lender, _loanId, loan);
        _resolveLoanNote(_loanId);
        delete loanIds[nftAsset][nftId];
        afterRepay(nftAsset, nftId);
    }

    function _repayAsset(
        address payer,
        address borrower,
        address lender,
        uint32 _loanId,
        LoanDetail memory loan
    ) internal {
        (uint256 adminFee, uint256 payoffAmount) = _payoffAndFee(loan);
        IAddressProvider addressProvider = getAddressProvider();
        // Paid back to lender
        IDelegateV3(addressProvider.getTransferDelegate()).erc20Transfer(
            payer,
            lender,
            loan.borrowAsset,
            payoffAmount
        );
        // Transfer admin fee
        IDelegateV3(addressProvider.getTransferDelegate()).erc20Transfer(
            payer,
            adminFeeReceiver,
            loan.borrowAsset,
            adminFee
        );

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
    }

    /**
     * @param _offer - Offer parameters
     * @param _nftId - NFI ID
     * @param _isCollection - is collection or not
     * @param _lenderSignature - lender signature
     * @param _brokerSignature - broker signature
     */
    function _checkSignatures(
        Offer memory _offer,
        uint256 _nftId,
        bool _isCollection,
        Signature memory _lenderSignature,
        Signature memory _brokerSignature
    ) private view {
        if (_isCollection) {
            require(
                SigningUtils.offerSignatureIsValid(_offer, _lenderSignature),
                "Lender signature is invalid"
            );
        } else {
            require(
                SigningUtils.offerSignatureIsValid(
                    _offer,
                    _nftId,
                    _lenderSignature
                ),
                "Lender signature is invalid"
            );
        }
        require(
            SigningUtils.offerSignatureIsValid(
                _offer,
                _nftId,
                _brokerSignature
            ),
            "Signer signature is invalid"
        );
    }

    /**
     * @param _offer - Offer parameters
     * @param _nftId - NFI ID
     * @param _isCollection - is collection or not
     */
    function _createLoanDetail(
        Offer memory _offer,
        uint256 _nftId,
        bool _isCollection
    ) internal view returns (LoanDetail memory) {
        return
            LoanDetail({
                borrowAsset: _offer.borrowAsset,
                borrowAmount: _offer.borrowAmount,
                repayAmount: _offer.repayAmount,
                nftAsset: _offer.nftAsset,
                nftTokenId: _nftId,
                loanStart: uint64(block.timestamp),
                loanDuration: _offer.borrowDuration,
                adminShare: adminShare,
                isCollection: _isCollection
            });
    }

    /**
     * @param loan - Loan parameters
     */
    function _loanMaturityDate(
        LoanDetail memory loan
    ) private pure returns (uint256) {
        return uint256(loan.loanStart) + uint256(loan.loanDuration);
    }

    function _serviceFee(Offer memory offer, uint32 loanId, address target) internal {
        if (target != address(0)) {
            IAddressProvider addressProvider = getAddressProvider();
            address nftAsset = offer.nftAsset;
            uint256 borrowAmount = offer.borrowAmount;
            address borrowAsset = offer.borrowAsset;
            address serviceFeeAddr = addressProvider.getServiceFee();
            uint16 serviceFeeRate = 0;
            uint256 fee = 0;
            if(serviceFeeAddr != address(0)) {
                serviceFeeRate = IServiceFee(serviceFeeAddr).getServiceFee(
                    target,
                    msg.sender,
                    nftAsset
                );
                if(serviceFeeRate > 0) {
                    fee = borrowAmount * serviceFeeRate / HUNDRED_PERCENT;
                    IDelegateV3(addressProvider.getTransferDelegate()).erc20Transfer(
                        msg.sender,
                        adminFeeReceiver,
                        borrowAsset,
                        fee
                    );
                }

                emit ServiceFee(loanId, target, serviceFeeRate, fee);
            }
        }
    }
}