// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';

import '../dependencies/weth/IWETH.sol';
import '../libraries/math/PercentageMath.sol';
import '../libraries/math/WadRayMath.sol';
import '../libraries/math/MathUtils.sol';

import './libraries/BespokeTypes.sol';
import './libraries/BespokeLogic.sol';

import '../interfaces/IOpenSkySettings.sol';
import '../interfaces/IOpenSkyPool.sol';
import '../interfaces/IACLManager.sol';
import '../interfaces/IOpenSkyFlashClaimReceiver.sol';

import './interfaces/IOpenSkyBespokeLoanNFT.sol';
import './interfaces/IOpenSkyBespokeMarket.sol';
import './interfaces/IOpenSkyBespokeSettings.sol';

contract OpenSkyBespokeMarket is
    Context,
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC721Holder,
    ERC1155Holder,
    IOpenSkyBespokeMarket
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using PercentageMath for uint256;
    using WadRayMath for uint256;

    IOpenSkySettings public immutable SETTINGS;
    IOpenSkyBespokeSettings public immutable BESPOKE_SETTINGS;
    IWETH public immutable WETH;

    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    mapping(address => uint256) public minNonce;
    mapping(address => mapping(uint256 => bool)) private _nonce;

    uint256 private _loanIdTracker;
    mapping(uint256 => BespokeTypes.LoanData) internal _loans;

    // nft address=> amount
    // tracking how many loans are ongoing for an nft
    mapping(address => uint256) public nftBorrowStat;

    constructor(
        address SETTINGS_,
        address BESPOKE_SETTINGS_,
        address WETH_
    ) Pausable() ReentrancyGuard() {
        SETTINGS = IOpenSkySettings(SETTINGS_);
        BESPOKE_SETTINGS = IOpenSkyBespokeSettings(BESPOKE_SETTINGS_);
        WETH = IWETH(WETH_);
    }

    /// @dev Only emergency admin can call functions marked by this modifier.
    modifier onlyEmergencyAdmin() {
        IACLManager ACLManager = IACLManager(SETTINGS.ACLManagerAddress());
        require(ACLManager.isEmergencyAdmin(_msgSender()), 'BM_ACL_ONLY_EMERGENCY_ADMIN_CAN_CALL');
        _;
    }

    modifier onlyAirdropOperator() {
        IACLManager ACLManager = IACLManager(SETTINGS.ACLManagerAddress());
        require(ACLManager.isAirdropOperator(_msgSender()), 'BM_ACL_ONLY_AIRDROP_OPERATOR_CAN_CALL');
        _;
    }

    modifier checkLoanExists(uint256 loanId) {
        require(_loans[loanId].reserveId > 0, 'BM_CHECK_LOAN_NOT_EXISTS');
        _;
    }

    /// @dev Pause pool for emergency case, can only be called by emergency admin.
    function pause() external onlyEmergencyAdmin {
        _pause();
    }

    /// @dev Unpause pool for emergency case, can only be called by emergency admin.
    function unpause() external onlyEmergencyAdmin {
        _unpause();
    }

    /// @notice Cancel all pending offers for a sender
    /// @param minNonce_ minimum user nonce
    function cancelAllBorrowOffersForSender(uint256 minNonce_) external {
        require(minNonce_ > minNonce[msg.sender], 'BM_CANCEL_NONCE_LOWER_THAN_CURRENT');
        require(minNonce_ < minNonce[msg.sender] + 500000, 'BM_CANCEL_CANNOT_CANCEL_MORE');
        minNonce[msg.sender] = minNonce_;

        emit CancelAllOffers(msg.sender, minNonce_);
    }

    /// @param offerNonces array of borrowOffer nonces
    function cancelMultipleBorrowOffers(uint256[] calldata offerNonces) external {
        require(offerNonces.length > 0, 'BM_CANCEL_CANNOT_BE_EMPTY');

        for (uint256 i = 0; i < offerNonces.length; i++) {
            require(offerNonces[i] >= minNonce[msg.sender], 'BM_CANCEL_NONCE_LOWER_THAN_CURRENT');
            _nonce[msg.sender][offerNonces[i]] = true;
        }

        emit CancelMultipleOffers(msg.sender, offerNonces);
    }

    function isValidNonce(address account, uint256 nonce) external view returns (bool) {
        return !_nonce[account][nonce] && nonce >= minNonce[account];
    }

    /// @notice take an borrowing offer using ERC20 include WETH
    function takeBorrowOffer(
        BespokeTypes.BorrowOffer memory offerData,
        uint256 supplyAmount,
        uint256 supplyDuration
    ) public override whenNotPaused nonReentrant {
        bytes32 offerHash = BespokeLogic.hashBorrowOffer(offerData);

        BespokeLogic.validateTakeBorrowOffer(
            _nonce,
            minNonce,
            offerData,
            offerHash,
            address(0),
            supplyAmount,
            supplyDuration,
            _getDomainSeparator(),
            BESPOKE_SETTINGS,
            SETTINGS
        );

        // prevents replay
        _nonce[offerData.borrower][offerData.nonce] = true;

        // transfer NFT
        _transferNFT(offerData.nftAddress, offerData.borrower, address(this), offerData.tokenId, offerData.tokenAmount);

        // oToken balance
        DataTypes.ReserveData memory reserve = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(offerData.reserveId);
        (uint256 oTokenToUse, uint256 inputAmount) = _calculateTokenToUse(
            offerData.reserveId,
            reserve.oTokenAddress,
            _msgSender(),
            supplyAmount
        );

        if (oTokenToUse > 0) {
            // transfer oToken from lender
            address oTokenAddress = IOpenSkyPool(SETTINGS.poolAddress())
                .getReserveData(offerData.reserveId)
                .oTokenAddress;
            IERC20(oTokenAddress).safeTransferFrom(_msgSender(), address(this), oTokenToUse);

            // withdraw underlying to borrower
            IOpenSkyPool(SETTINGS.poolAddress()).withdraw(offerData.reserveId, oTokenToUse, offerData.borrower);
        }

        if (inputAmount > 0) {
            IERC20(reserve.underlyingAsset).safeTransferFrom(_msgSender(), offerData.borrower, inputAmount);
        }

        uint256 loanId = _mintLoanNFT(offerData.borrower, _msgSender(), offerData.nftAddress);
        BespokeLogic.createLoan(_loans, offerData, loanId, supplyAmount, supplyDuration, BESPOKE_SETTINGS);

        emit TakeBorrowOffer(offerHash, loanId, _msgSender(), offerData.borrower, offerData.nonce);
    }

    /// @notice Take a borrow offer. Only for WETH reserve.
    /// @notice Consider using taker's oWETH balance first, then ETH if oWETH is not enough
    /// @notice Borrower will receive WETH
    function takeBorrowOfferETH(
        BespokeTypes.BorrowOffer memory offerData,
        uint256 supplyAmount,
        uint256 supplyDuration
    ) public payable override whenNotPaused nonReentrant {
        bytes32 offerHash = BespokeLogic.hashBorrowOffer(offerData);

        BespokeLogic.validateTakeBorrowOffer(
            _nonce,
            minNonce,
            offerData,
            offerHash,
            address(WETH),
            supplyAmount,
            supplyDuration,
            _getDomainSeparator(),
            BESPOKE_SETTINGS,
            SETTINGS
        );

        // prevents replay
        _nonce[offerData.borrower][offerData.nonce] = true;

        // transfer NFT
        _transferNFT(offerData.nftAddress, offerData.borrower, address(this), offerData.tokenId, offerData.tokenAmount);

        // oWeth balance
        address oTokenAddress = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(offerData.reserveId).oTokenAddress;
        (uint256 oTokenToUse, uint256 inputETH) = _calculateTokenToUse(
            offerData.reserveId,
            oTokenAddress,
            _msgSender(),
            supplyAmount
        );

        if (oTokenToUse > 0) {
            IERC20(oTokenAddress).safeTransferFrom(_msgSender(), address(this), oTokenToUse);
            // oWETH => WETH
            IOpenSkyPool(SETTINGS.poolAddress()).withdraw(offerData.reserveId, oTokenToUse, address(this));
        }
        if (inputETH > 0) {
            require(msg.value >= inputETH, 'BM_TAKE_BORROW_OFFER_ETH_INPUT_NOT_ENOUGH');
            // convert to WETH
            WETH.deposit{value: inputETH}();
        }

        // transfer WETH to borrower
        require(WETH.balanceOf(address(this)) >= supplyAmount, 'BM_TAKE_BORROW_OFFER_ETH_BALANCE_NOT_ENOUGH');
        WETH.transferFrom(address(this), offerData.borrower, supplyAmount);

        uint256 loanId = _mintLoanNFT(offerData.borrower, _msgSender(), offerData.nftAddress);
        BespokeLogic.createLoan(_loans, offerData, loanId, supplyAmount, supplyDuration, BESPOKE_SETTINGS);

        // refund remaining dust eth
        if (msg.value > inputETH) {
            uint256 refundAmount = msg.value - inputETH;
            _safeTransferETH(msg.sender, refundAmount);
        }

        emit TakeBorrowOfferETH(offerHash, loanId, _msgSender(), offerData.borrower, offerData.nonce);
    }

    /// @notice Only OpenSkyBorrowNFT owner can repay
    /// @notice Only OpenSkyLendNFT owner can recieve the payment
    /// @notice This function is not pausable for safety
    function repay(uint256 loanId) public override nonReentrant checkLoanExists(loanId) {
        BespokeTypes.LoanData memory loanData = getLoanData(loanId);
        require(
            loanData.status == BespokeTypes.LoanStatus.BORROWING || loanData.status == BespokeTypes.LoanStatus.OVERDUE,
            'BM_REPAY_STATUS_ERROR'
        );

        (address borrower, address lender) = _getLoanParties(loanId);
        require(_msgSender() == borrower, 'BM_REPAY_NOT_BORROW_NFT_OWNER');

        (uint256 repayTotal, uint256 lenderAmount, uint256 protocolFee) = _calculateRepayAmountAndProtocolFee(loanId);

        // repay oToken to lender
        address underlyingAsset = IOpenSkyPool(SETTINGS.poolAddress())
            .getReserveData(loanData.reserveId)
            .underlyingAsset;
        IERC20(underlyingAsset).safeTransferFrom(_msgSender(), address(this), repayTotal);
        IERC20(underlyingAsset).approve(SETTINGS.poolAddress(), lenderAmount);
        IOpenSkyPool(SETTINGS.poolAddress()).deposit(loanData.reserveId, lenderAmount, lender, 0);

        // dao vault
        if (protocolFee > 0) IERC20(underlyingAsset).safeTransfer(SETTINGS.daoVaultAddress(), protocolFee);

        // transfer nft back to borrower
        _transferNFT(loanData.nftAddress, address(this), borrower, loanData.tokenId, loanData.tokenAmount);

        _burnLoanNft(loanId, loanData.nftAddress);

        emit Repay(loanId, _msgSender());
    }

    /// @notice Only OpenSkyBorrowNFT owner can repay
    /// @notice Only OpenSkyLendNFT owner can recieve the payment
    /// @notice This function is not pausable for safety
    function repayETH(uint256 loanId) public payable override nonReentrant checkLoanExists(loanId) {
        BespokeTypes.LoanData memory loanData = getLoanData(loanId);
        address underlyingAsset = IOpenSkyPool(SETTINGS.poolAddress())
            .getReserveData(loanData.reserveId)
            .underlyingAsset;
        require(underlyingAsset == address(WETH), 'BM_REPAY_ETH_ASSET_NOT_MATCH');
        require(
            loanData.status == BespokeTypes.LoanStatus.BORROWING || loanData.status == BespokeTypes.LoanStatus.OVERDUE,
            'BM_REPAY_STATUS_ERROR'
        );

        (address borrower, address lender) = _getLoanParties(loanId);
        require(_msgSender() == borrower, 'BM_REPAY_NOT_BORROW_NFT_OWNER');

        (uint256 repayTotal, uint256 lenderAmount, uint256 protocolFee) = _calculateRepayAmountAndProtocolFee(loanId);

        require(msg.value >= repayTotal, 'BM_REPAY_ETH_INPUT_NOT_ENOUGH');

        // convert to weth
        WETH.deposit{value: repayTotal}();

        // transfer  to lender
        IERC20(underlyingAsset).approve(SETTINGS.poolAddress(), lenderAmount);
        IOpenSkyPool(SETTINGS.poolAddress()).deposit(loanData.reserveId, lenderAmount, lender, 0);

        // dao vault
        if (protocolFee > 0) IERC20(underlyingAsset).safeTransfer(SETTINGS.daoVaultAddress(), protocolFee);

        // transfer nft back to borrower
        _transferNFT(loanData.nftAddress, address(this), borrower, loanData.tokenId, loanData.tokenAmount);

        _burnLoanNft(loanId, loanData.nftAddress);

        // refund
        if (msg.value > repayTotal) _safeTransferETH(_msgSender(), msg.value - repayTotal);

        emit RepayETH(loanId, _msgSender());
    }

    /// @notice anyone can trigger but only OpenSkyLendNFT owner can receive collateral
    function foreclose(uint256 loanId) public override whenNotPaused nonReentrant checkLoanExists(loanId) {
        BespokeTypes.LoanData memory loanData = getLoanData(loanId);
        require(loanData.status == BespokeTypes.LoanStatus.LIQUIDATABLE, 'BM_FORECLOSE_STATUS_ERROR');

        (, address lender) = _getLoanParties(loanId);

        _transferNFT(loanData.nftAddress, address(this), lender, loanData.tokenId, loanData.tokenAmount);

        _burnLoanNft(loanId, loanData.nftAddress);

        emit Foreclose(loanId, _msgSender());
    }

    function getLoanData(uint256 loanId) public view override returns (BespokeTypes.LoanData memory) {
        BespokeTypes.LoanData memory loan = _loans[loanId];
        loan.status = getStatus(loanId);
        return loan;
    }

    function getStatus(uint256 loanId) public view override returns (BespokeTypes.LoanStatus) {
        BespokeTypes.LoanData memory loan = _loans[loanId];
        BespokeTypes.LoanStatus status = _loans[loanId].status;
        if (status == BespokeTypes.LoanStatus.BORROWING) {
            if (loan.liquidatableTime < block.timestamp) {
                status = BespokeTypes.LoanStatus.LIQUIDATABLE;
            } else if (loan.borrowOverdueTime < block.timestamp) {
                status = BespokeTypes.LoanStatus.OVERDUE;
            }
        }
        return status;
    }

    function getBorrowInterest(uint256 loanId) public view override returns (uint256) {
        BespokeTypes.LoanData memory loan = _loans[loanId];
        uint256 endTime = block.timestamp < loan.borrowOverdueTime ? loan.borrowOverdueTime : block.timestamp;
        return uint256(loan.interestPerSecond).rayMul(endTime.sub(loan.borrowBegin));
    }

    // @dev principal + fixed-price interest + extra interest(if overdue)
    function getBorrowBalance(uint256 loanId) public view override returns (uint256) {
        return _loans[loanId].amount.add(getBorrowInterest(loanId));
    }

    function getPenalty(uint256 loanId) public view override returns (uint256) {
        BespokeTypes.LoanData memory loan = getLoanData(loanId);
        uint256 penalty = 0;
        if (loan.status == BespokeTypes.LoanStatus.OVERDUE) {
            penalty = loan.amount.percentMul(BESPOKE_SETTINGS.overdueLoanFeeFactor());
        }
        return penalty;
    }

    function _calculateTokenToUse(
        uint256 reserveId,
        address oTokenAddress,
        address lender,
        uint256 supplyAmount
    ) internal view returns (uint256 oTokenToUse, uint256 inputAmount) {
        uint256 oTokenBalance = IERC20(oTokenAddress).balanceOf(lender);
        uint256 availableLiquidity = IOpenSkyPool(SETTINGS.poolAddress()).getAvailableLiquidity(reserveId);
        oTokenBalance = availableLiquidity > oTokenBalance ? oTokenBalance : availableLiquidity;
        oTokenToUse = oTokenBalance < supplyAmount ? oTokenBalance : supplyAmount;
        inputAmount = oTokenBalance < supplyAmount ? supplyAmount.sub(oTokenBalance) : 0;
    }

    function _calculateRepayAmountAndProtocolFee(uint256 loanId)
        internal
        view
        returns (
            uint256 total,
            uint256 lenderAmount,
            uint256 protocolFee
        )
    {
        uint256 penalty = getPenalty(loanId);
        total = getBorrowBalance(loanId).add(penalty);
        protocolFee = getBorrowInterest(loanId).add(penalty).percentMul(BESPOKE_SETTINGS.reserveFactor());
        lenderAmount = total.sub(protocolFee);
    }

    function _safeTransferETH(address recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'BM_ETH_TRANSFER_FAILED');
    }

    function _mintLoanNFT(
        address borrower,
        address lender,
        address relatedCollateralNft
    ) internal returns (uint256) {
        _loanIdTracker = _loanIdTracker + 1;
        uint256 tokenId = _loanIdTracker;

        IOpenSkyBespokeLoanNFT(BESPOKE_SETTINGS.borrowLoanAddress()).mint(tokenId, borrower);
        IOpenSkyBespokeLoanNFT(BESPOKE_SETTINGS.lendLoanAddress()).mint(tokenId, lender);

        nftBorrowStat[relatedCollateralNft] += 1;
        return tokenId;
    }

    function _burnLoanNft(uint256 tokenId, address relatedCollateralNft) internal {
        IOpenSkyBespokeLoanNFT(BESPOKE_SETTINGS.borrowLoanAddress()).burn(tokenId);
        IOpenSkyBespokeLoanNFT(BESPOKE_SETTINGS.lendLoanAddress()).burn(tokenId);
        nftBorrowStat[relatedCollateralNft] -= 1;
        delete _loans[tokenId];
    }

    function _getLoanParties(uint256 loanId) internal returns (address borrower, address lender) {
        lender = IERC721(BESPOKE_SETTINGS.lendLoanAddress()).ownerOf(loanId);
        borrower = IERC721(BESPOKE_SETTINGS.borrowLoanAddress()).ownerOf(loanId);
    }

    //
    /// @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
    /// direct transfers to the contract address.
    /// @param token token to transfer
    /// @param to recipient of the transfer
    /// @param amount amount to send
    function emergencyTokenTransfer(
        address token,
        address to,
        uint256 amount
    ) external onlyEmergencyAdmin {
        IERC20(token).safeTransfer(to, amount);
    }

    /// @inheritdoc IOpenSkyBespokeMarket
    function flashClaim(
        address receiverAddress,
        uint256[] calldata loanIds,
        bytes calldata params
    ) external override {
        uint256 i;
        IOpenSkyFlashClaimReceiver receiver = IOpenSkyFlashClaimReceiver(receiverAddress);
        // !!!CAUTION: receiver contract may reentry mint, burn, flashClaim again

        // only loan owner can do flashClaim
        address[] memory nftAddresses = new address[](loanIds.length);
        uint256[] memory tokenIds = new uint256[](loanIds.length);
        for (i = 0; i < loanIds.length; i++) {
            require(
                IERC721(BESPOKE_SETTINGS.borrowLoanAddress()).ownerOf(loanIds[i]) == _msgSender(),
                'BM_FLASHCLAIM_CALLER_IS_NOT_OWNER'
            );
            BespokeTypes.LoanData memory loanData = getLoanData(loanIds[i]);
            require(loanData.status != BespokeTypes.LoanStatus.LIQUIDATABLE, 'BM_FLASHCLAIM_STATUS_ERROR');
            nftAddresses[i] = loanData.nftAddress;
            tokenIds[i] = loanData.tokenId;
        }

        // step 1: moving underlying asset forward to receiver contract
        for (i = 0; i < loanIds.length; i++) {
            IERC721(nftAddresses[i]).safeTransferFrom(address(this), receiverAddress, tokenIds[i]);
        }

        // setup 2: execute receiver contract, doing something like aidrop
        require(
            receiver.executeOperation(nftAddresses, tokenIds, _msgSender(), address(this), params),
            'BM_FLASHCLAIM_EXECUTOR_ERROR'
        );

        // setup 3: moving underlying asset backword from receiver contract
        for (i = 0; i < loanIds.length; i++) {
            IERC721(nftAddresses[i]).safeTransferFrom(receiverAddress, address(this), tokenIds[i]);
            emit FlashClaim(receiverAddress, _msgSender(), nftAddresses[i], tokenIds[i]);
        }
    }

    /// @inheritdoc IOpenSkyBespokeMarket
    function claimERC20Airdrop(
        address token,
        address to,
        uint256 amount
    ) external override onlyAirdropOperator {
        // make sure that params are checked in admin contract
        IERC20(token).safeTransfer(to, amount);
        emit ClaimERC20Airdrop(token, to, amount);
    }

    /// @inheritdoc IOpenSkyBespokeMarket
    function claimERC721Airdrop(
        address token,
        address to,
        uint256[] calldata ids
    ) external override onlyAirdropOperator {
        require(nftBorrowStat[token] == 0, 'BM_CLAIM_ERC721_AIRDROP_NOT_SUPPORTED');
        // make sure that params are checked in admin contract
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(token).safeTransferFrom(address(this), to, ids[i]);
        }
        emit ClaimERC721Airdrop(token, to, ids);
    }

    /// @inheritdoc IOpenSkyBespokeMarket
    function claimERC1155Airdrop(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override onlyAirdropOperator {
        require(nftBorrowStat[token] == 0, 'BM_CLAIM_ERC1155_AIRDROP_NOT_SUPPORTED');
        // make sure that params are checked in admin contract
        IERC1155(token).safeBatchTransferFrom(address(this), to, ids, amounts, data);
        emit ClaimERC1155Airdrop(token, to, ids, amounts, data);
    }

    function _transferNFT(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(collection).safeTransferFrom(from, to, tokenId);
        } else if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)) {
            IERC1155(collection).safeTransferFrom(from, to, tokenId, amount, '');
        } else {
            revert('BM_NFT_NOT_SUPPORTED');
        }
    }

    function _getDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    0xf0cf7ce475272740cae17eb3cadd6d254800be81c53f84a2f273b99036471c62, // keccak256("OpenSkyBespokeMarket")
                    0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                    block.chainid,
                    address(this)
                )
            );
    }

    receive() external payable {
        revert('BM_RECEIVE_NOT_ALLOWED');
    }

    fallback() external payable {
        revert('BM_FALLBACK_NOT_ALLOWED');
    }
}