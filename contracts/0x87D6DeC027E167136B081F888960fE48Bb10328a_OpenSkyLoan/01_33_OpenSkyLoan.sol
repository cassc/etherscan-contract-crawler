// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';

import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './interfaces/IOpenSkyFlashClaimReceiver.sol';
import './interfaces/IOpenSkyLoan.sol';
import './interfaces/IOpenSkySettings.sol';
import './interfaces/IACLManager.sol';
import './interfaces/IOpenSkyNFTDescriptor.sol';
import './libraries/types/DataTypes.sol';
import './libraries/math/WadRayMath.sol';
import './libraries/math/MathUtils.sol';
import './libraries/math/PercentageMath.sol';
import './libraries/helpers/Errors.sol';
import './interfaces/IOpenSkyIncentivesController.sol';

/**
 * @title OpenSkyLoan contract
 * @author OpenSky Labs
 * @notice Implementation of the loan NFT for the OpenSky protocol
 * @dev The functions about handling loan are callable by the OpenSkyPool contract defined also in the OpenSkySettings
 **/
contract OpenSkyLoan is Context, ERC721Enumerable, Ownable, ERC721Holder, ERC1155Holder, ReentrancyGuard, IOpenSkyLoan {
    using Counters for Counters.Counter;
    using PercentageMath for uint256;
    using SafeERC20 for IERC20;
    using WadRayMath for uint128;


    mapping(uint256 => DataTypes.LoanData) internal _loans;

    /// @inheritdoc IOpenSkyLoan
    mapping(address => mapping(uint256 => uint256)) public override getLoanId;

    uint256 public totalBorrows;

    mapping(address => uint256) public userBorrows;

    Counters.Counter private _tokenIdTracker;
    IOpenSkySettings public immutable SETTINGS;
    
    address internal _pool;

    modifier onlyPool(){
        require(_msgSender() == _pool, Errors.ACL_ONLY_POOL_CAN_CALL);
        _;
    }

    modifier onlyAirdropOperator() {
        IACLManager ACLManager = IACLManager(SETTINGS.ACLManagerAddress());
        require(ACLManager.isAirdropOperator(_msgSender()), Errors.ACL_ONLY_AIRDROP_OPERATOR_CAN_CALL);
        _;
    }

    modifier checkLoanExists(uint256 loanId) {
        require(_exists(loanId), Errors.LOAN_DOES_NOT_EXIST);
        _;
    }
    
    /**
     * @dev Constructor.
     * @param name The name of OpenSkyLoan NFT
     * @param symbol The symbol of OpenSkyLoan NFT
     * @param _settings The address of the OpenSkySettings contract
     */
    constructor(
        string memory name,
        string memory symbol,
        address _settings,
        address pool
    ) Ownable() ERC721(name, symbol) ReentrancyGuard() {
        SETTINGS = IOpenSkySettings(_settings);
        _pool = pool;
    }

    struct BorrowLocalVars {
        uint40 borrowBegin;
        uint40 overdueTime;
        uint40 liquidatableTime;
        uint40 extendableTime;
        uint256 interestPerSecond;
    }

    /// @inheritdoc IOpenSkyLoan
    function mint(
        uint256 reserveId,
        address borrower,
        address nftAddress,
        uint256 nftTokenId,
        uint256 amount,
        uint256 duration,
        uint256 borrowRate
    ) external override onlyPool returns (uint256 loanId, DataTypes.LoanData memory loan) {
        DataTypes.WhitelistInfo memory whitelistInfo = SETTINGS.getWhitelistDetail(reserveId, nftAddress);
        BorrowLocalVars memory vars;

        vars.borrowBegin = uint40(block.timestamp);
        vars.overdueTime = uint40(block.timestamp + duration);
        vars.liquidatableTime = uint40(block.timestamp + duration + whitelistInfo.overdueDuration);
        // add setting config
        vars.extendableTime = uint40(block.timestamp + duration - whitelistInfo.extendableDuration);

        vars.interestPerSecond = MathUtils.calculateBorrowInterestPerSecond(borrowRate, amount);

        loan = DataTypes.LoanData({
            reserveId: reserveId,
            nftAddress: nftAddress,
            tokenId: nftTokenId,
            borrower: borrower,
            amount: amount,
            borrowBegin: vars.borrowBegin,
            borrowDuration: uint40(duration),
            borrowOverdueTime: vars.overdueTime,
            liquidatableTime: vars.liquidatableTime,
            borrowRate: uint128(borrowRate),
            interestPerSecond: uint128(vars.interestPerSecond),
            extendableTime: vars.extendableTime,
            borrowEnd: 0,
            status: DataTypes.LoanStatus.BORROWING
        });
        loanId = _mint(loan, borrower);
        IERC721(loan.nftAddress).approve(_pool, loan.tokenId);

        getLoanId[nftAddress][nftTokenId] = loanId;
        emit Mint(loanId, borrower);
    }

    function _mint(DataTypes.LoanData memory loanData, address recipient) internal returns (uint256 tokenId) {
        _tokenIdTracker.increment();
        tokenId = _tokenIdTracker.current();
        _safeMint(recipient, tokenId);
        _loans[tokenId] = loanData;

        _triggerIncentive(loanData.borrower);

        totalBorrows = totalBorrows + loanData.amount;
        userBorrows[loanData.borrower] = userBorrows[loanData.borrower] + loanData.amount;
    }

    function _triggerIncentive(address borrower) internal {
        address incentiveControllerAddress = SETTINGS.incentiveControllerAddress();
        if (incentiveControllerAddress != address(0)) {
            IOpenSkyIncentivesController incentivesController = IOpenSkyIncentivesController(
                incentiveControllerAddress
            );
            incentivesController.handleAction(borrower, userBorrows[borrower], totalBorrows);
        }
    }

    /// @inheritdoc IOpenSkyLoan
    function startLiquidation(uint256 tokenId) external override onlyPool checkLoanExists(tokenId) {
        _updateStatus(tokenId, DataTypes.LoanStatus.LIQUIDATING);
        _loans[tokenId].borrowEnd = uint40(block.timestamp);

        address owner = ownerOf(tokenId);
        _triggerIncentive(owner);

        userBorrows[owner] = userBorrows[owner] - _loans[tokenId].amount;
        totalBorrows = totalBorrows - _loans[tokenId].amount;

        emit StartLiquidation(tokenId, _msgSender());
    }

    /// @inheritdoc IOpenSkyLoan
    function endLiquidation(uint256 tokenId) external override onlyPool checkLoanExists(tokenId) {
        _burn(tokenId);

        delete getLoanId[_loans[tokenId].nftAddress][_loans[tokenId].tokenId];
        delete _loans[tokenId];

        emit EndLiquidation(tokenId, _msgSender());
    }

    /// @inheritdoc IOpenSkyLoan
    function end(
        uint256 tokenId,
        address onBehalfOf,
        address repayer
    ) external override onlyPool checkLoanExists(tokenId) {
        require(ownerOf(tokenId) == onBehalfOf, Errors.LOAN_REPAYER_IS_NOT_OWNER);

        if (_loans[tokenId].status != DataTypes.LoanStatus.LIQUIDATING) {
            address owner = ownerOf(tokenId);
            _triggerIncentive(owner);

            userBorrows[owner] = userBorrows[owner] - _loans[tokenId].amount;
            totalBorrows = totalBorrows - _loans[tokenId].amount;
        }

        _burn(tokenId);

        delete getLoanId[_loans[tokenId].nftAddress][_loans[tokenId].tokenId];
        delete _loans[tokenId];

        emit End(tokenId, onBehalfOf, repayer);
    }

    /**
     * @notice Updates the status of a loan.
     * @param tokenId The id of the loan
     * @param status The status of the loan will be set
     **/
    function _updateStatus(uint256 tokenId, DataTypes.LoanStatus status) internal {
        DataTypes.LoanData storage loanData = _loans[tokenId];
        require(loanData.status != DataTypes.LoanStatus.LIQUIDATING, Errors.LOAN_LIQUIDATING_STATUS_CAN_NOT_BE_UPDATED);
        require(loanData.status != status, Errors.LOAN_SET_STATUS_ERROR);
        loanData.status = status;
        emit UpdateStatus(tokenId, status);
    }

    /**
     * @notice Transfers the loan between two users. Calls the function of the incentives controller contract.
     * @param from The source address
     * @param to The destination address
     * @param tokenId The id of the loan
     **/
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._transfer(from, to, tokenId);

        DataTypes.LoanStatus status = getStatus(tokenId);
        if (status == DataTypes.LoanStatus.BORROWING || status == DataTypes.LoanStatus.EXTENDABLE) {
            address incentiveControllerAddress = SETTINGS.incentiveControllerAddress();
            DataTypes.LoanData memory loanData = _loans[tokenId];
            if (incentiveControllerAddress != address(0)) {
                IOpenSkyIncentivesController incentivesController = IOpenSkyIncentivesController(
                    incentiveControllerAddress
                );
                incentivesController.handleAction(from, userBorrows[from], totalBorrows);
                if (from != to) {
                    incentivesController.handleAction(to, userBorrows[to], totalBorrows);
                }
            }
            userBorrows[from] = userBorrows[from] - loanData.amount;
            userBorrows[to] = userBorrows[to] + loanData.amount;
        }
    }

    /// @inheritdoc IOpenSkyLoan
    function getLoanData(uint256 tokenId) external view override checkLoanExists(tokenId) returns (DataTypes.LoanData memory) {
        DataTypes.LoanData memory loan = _loans[tokenId];
        loan.status = getStatus(tokenId);
        return loan;
    }

    /// @inheritdoc IOpenSkyLoan
    function getBorrowInterest(uint256 tokenId) public view override checkLoanExists(tokenId) returns (uint256) {
        DataTypes.LoanData memory loan = _loans[tokenId];
        uint256 endTime = loan.borrowEnd > 0 ? loan.borrowEnd : block.timestamp;
        return loan.interestPerSecond.rayMul(endTime - loan.borrowBegin);
    }

    /// @inheritdoc IOpenSkyLoan
    function getStatus(uint256 tokenId) public view override checkLoanExists(tokenId) returns (DataTypes.LoanStatus) {
        DataTypes.LoanData memory loan = _loans[tokenId];
        DataTypes.LoanStatus status = _loans[tokenId].status;
        if (status == DataTypes.LoanStatus.BORROWING) {
            if (loan.liquidatableTime < block.timestamp) {
                status = DataTypes.LoanStatus.LIQUIDATABLE;
            } else if (loan.borrowOverdueTime < block.timestamp) {
                status = DataTypes.LoanStatus.OVERDUE;
            } else if (loan.extendableTime < block.timestamp) {
                status = DataTypes.LoanStatus.EXTENDABLE;
            }
        }
        return status;
    }

    /// @inheritdoc IOpenSkyLoan
    function getBorrowBalance(uint256 tokenId) external view override checkLoanExists(tokenId) returns (uint256) {
        return _loans[tokenId].amount + getBorrowInterest(tokenId);
    }

    /// @inheritdoc IOpenSkyLoan
    function getPenalty(uint256 tokenId) external view override checkLoanExists(tokenId) returns (uint256) {
        DataTypes.LoanStatus status = getStatus(tokenId);
        DataTypes.LoanData memory loan = _loans[tokenId];
        uint256 penalty = 0;
        if (status == DataTypes.LoanStatus.BORROWING) {
            penalty = loan.amount.percentMul(SETTINGS.prepaymentFeeFactor());
        } else if (status == DataTypes.LoanStatus.OVERDUE) {
            penalty = loan.amount.percentMul(SETTINGS.overdueLoanFeeFactor());
        }
        return penalty;
    }

    /// @inheritdoc IOpenSkyLoan
    function flashClaim(
        address receiverAddress,
        uint256[] calldata loanIds,
        bytes calldata params
    ) external override nonReentrant {
        uint256 i;
        IOpenSkyFlashClaimReceiver receiver = IOpenSkyFlashClaimReceiver(receiverAddress);
        // !!!CAUTION: receiver contract may reentry mint, burn, flashclaim again

        // only loan owner can do flashclaim
        address[] memory nftAddresses = new address[](loanIds.length);
        uint256[] memory tokenIds = new uint256[](loanIds.length);
        for (i = 0; i < loanIds.length; i++) {
            require(ownerOf(loanIds[i]) == _msgSender(), Errors.LOAN_CALLER_IS_NOT_OWNER);
            DataTypes.LoanStatus status = getStatus(loanIds[i]);
            require(
                status != DataTypes.LoanStatus.LIQUIDATABLE && status != DataTypes.LoanStatus.LIQUIDATING,
                Errors.FLASHCLAIM_STATUS_ERROR
            );
            DataTypes.LoanData memory loan = _loans[loanIds[i]];
            nftAddresses[i] = loan.nftAddress;
            tokenIds[i] = loan.tokenId;
        }

        // step 1: moving underlying asset forward to receiver contract
        for (i = 0; i < loanIds.length; i++) {
            IERC721(nftAddresses[i]).safeTransferFrom(address(this), receiverAddress, tokenIds[i]);
        }

        // setup 2: execute receiver contract, doing something like airdrop
        require(
            receiver.executeOperation(nftAddresses, tokenIds, _msgSender(), address(this), params),
            Errors.FLASHCLAIM_EXECUTOR_ERROR
        );

        // setup 3: moving underlying asset backward from receiver contract
        for (i = 0; i < loanIds.length; i++) {
            IERC721(nftAddresses[i]).safeTransferFrom(receiverAddress, address(this), tokenIds[i]);
            emit FlashClaim(receiverAddress, _msgSender(), nftAddresses[i], tokenIds[i]);
        }
    }

    /// @inheritdoc IOpenSkyLoan
    function claimERC20Airdrop(
        address token,
        address to,
        uint256 amount
    ) external override onlyAirdropOperator {
        // make sure that params are checked in admin contract
        IERC20(token).safeTransfer(to, amount);
        emit ClaimERC20Airdrop(token, to, amount);
    }

    /// @inheritdoc IOpenSkyLoan
    function claimERC721Airdrop(
        address token,
        address to,
        uint256[] calldata ids
    ) external override onlyAirdropOperator {
        // make sure that params are checked in admin contract
        for (uint256 i = 0; i < ids.length; i++) {
            require(getLoanId[token][ids[i]] == 0, Errors.LOAN_COLLATERAL_NFT_CAN_NOT_BE_CLAIMED);
            IERC721(token).safeTransferFrom(address(this), to, ids[i]);
        }
        emit ClaimERC721Airdrop(token, to, ids);
    }

    /// @inheritdoc IOpenSkyLoan
    function claimERC1155Airdrop(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override onlyAirdropOperator {
        // make sure that params are checked in admin contract
        IERC1155(token).safeBatchTransferFrom(address(this), to, ids, amounts, data);
        emit ClaimERC1155Airdrop(token, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver, IERC165, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (SETTINGS.loanDescriptorAddress() != address(0)) {
            return IOpenSkyNFTDescriptor(SETTINGS.loanDescriptorAddress()).tokenURI(tokenId);
        } else {
            return '';
        }
    }
}