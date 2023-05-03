// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import { IPortfolio } from "./interfaces/IPortfolio.sol";
import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import { ERC721 } from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IFixedInterestBulletLoans, FixedInterestBulletLoanStatus } from "./interfaces/IFixedInterestBulletLoans.sol";
import { Base } from "./Base.sol";
import { IProtocolConfig } from "./interfaces/IProtocolConfig.sol";
import { MathUtils } from "./libraries/MathUtils.sol";
import { ICurrencyConverter } from "./interfaces/ICurrencyConverter.sol";

contract FixedInterestBulletLoans is Base, ERC721, IFixedInterestBulletLoans {
    IPortfolio public portfolio;
    ICurrencyConverter public currencyConverter;
    LoanMetadata[] internal loans;

    modifier onlyLoanStatus(uint256 loanId, FixedInterestBulletLoanStatus _status) {
        if (loans[loanId].status != _status) {
            revert NotSuitableLoanStatus();
        }
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        IProtocolConfig _protocolConfig,
        ICurrencyConverter _currencyConverter,
        address _manager
    )
        ERC721(name_, symbol_)
        Base(_protocolConfig.protocolAdmin(), _protocolConfig.pauser())
    {
        _grantManagerRole(_manager);
        currencyConverter = _currencyConverter;
    }

    /// @inheritdoc IFixedInterestBulletLoans
    function loanData(uint256 loanId) external view returns (LoanMetadata memory) {
        return loans[loanId];
    }

    /// @inheritdoc IFixedInterestBulletLoans
    function getRecipient(uint256 loanId) external view returns (address) {
        return loans[loanId].recipient;
    }

    /// @inheritdoc IFixedInterestBulletLoans
    function getStatus(uint256 loanId) external view returns (FixedInterestBulletLoanStatus) {
        return loans[loanId].status;
    }

    /// @inheritdoc IFixedInterestBulletLoans
    function currentUsdValue(uint256 loanId) public view override returns (uint256) {
        LoanMetadata storage loan = loans[loanId];

        uint256 currentTimestamp = block.timestamp;
        uint256 loanEndTimestamp = loan.startDate + loan.duration;
        if (loanEndTimestamp < currentTimestamp) {
            currentTimestamp = loanEndTimestamp;
        }
        uint256 interestInKRW =
            MathUtils.calculateLinearInterest(loan.krwPrincipal, loan.interestRate, loan.startDate, currentTimestamp);

        return currencyConverter.convertToUSD(loan.krwPrincipal + interestInKRW);
    }

    /// @inheritdoc IFixedInterestBulletLoans
    function expectedUsdRepayAmount(uint256 loanId) public view override returns (uint256) {
        LoanMetadata storage loan = loans[loanId];
        uint256 fullInterestInKRW = MathUtils.calculateLinearInterest(
            loan.krwPrincipal, loan.interestRate, loan.startDate, loan.startDate + loan.duration
        );

        return currencyConverter.convertToUSD(loan.krwPrincipal + fullInterestInKRW);
    }

    // TODO: How to prevent from being called by a stranger before Portfolio.constructor()
    /// @inheritdoc IFixedInterestBulletLoans
    function setPortfolio(IPortfolio _portfolio) external {
        if (address(portfolio) != address(0)) {
            revert PortfolioAlreadySet();
        }
        portfolio = _portfolio;
    }

    /// @inheritdoc IFixedInterestBulletLoans
    function setCurrencyConverter(ICurrencyConverter _currencyConverter) external {
        _requireManagerRole();
        currencyConverter = _currencyConverter;
    }

    /// @inheritdoc IFixedInterestBulletLoans
    function issueLoan(IssueLoanInputs calldata loanInputs) external override returns (uint256) {
        _requirePortfolio();

        uint256 id = loans.length;
        loans.push(
            LoanMetadata({
                recipient: loanInputs.recipient,
                krwPrincipal: loanInputs.krwPrincipal,
                usdPrincipal: 0,
                usdRepaid: 0,
                interestRate: loanInputs.interestRate,
                collateral: loanInputs.collateral,
                collateralId: loanInputs.collateralId,
                status: FixedInterestBulletLoanStatus.Created,
                startDate: 0,
                duration: loanInputs.duration,
                asset: loanInputs.asset
            })
        );

        _safeMint(msg.sender, id);
        emit Created(id);

        return id;
    }

    /// @inheritdoc IFixedInterestBulletLoans
    function startLoan(uint256 loanId)
        external
        whenNotPaused
        onlyLoanStatus(loanId, FixedInterestBulletLoanStatus.Created)
        returns (uint256 principal)
    {
        _requirePortfolio();

        LoanMetadata storage loan = loans[loanId];
        principal = _getUsdPrincipal(loanId);

        loan.startDate = block.timestamp;
        loan.usdPrincipal = principal;

        _changeLoanStatus(loanId, FixedInterestBulletLoanStatus.Started);
        emit Started(loanId);
    }

    /// @inheritdoc IFixedInterestBulletLoans
    function repayLoan(
        uint256 loanId,
        uint256 usdAmount
    )
        external
        whenNotPaused
        onlyLoanStatus(loanId, FixedInterestBulletLoanStatus.Started)
    {
        _requirePortfolio();

        uint256 expectedAmount = expectedUsdRepayAmount(loanId);
        LoanMetadata storage loan = loans[loanId];

        if (usdAmount != expectedAmount) {
            revert NotEqualRepayAmount();
        }

        loans[loanId].usdRepaid = usdAmount;
        _changeLoanStatus(loanId, FixedInterestBulletLoanStatus.Repaid);

        emit Repaid(loanId, usdAmount);
    }

    /// @inheritdoc IFixedInterestBulletLoans
    function repayDefaultedLoan(
        uint256 loanId,
        uint256 usdAmount
    )
        external
        whenNotPaused
        onlyLoanStatus(loanId, FixedInterestBulletLoanStatus.Defaulted)
    {
        _requirePortfolio();

        loans[loanId].usdRepaid = usdAmount;
        _changeLoanStatus(loanId, FixedInterestBulletLoanStatus.Repaid);

        emit RepayDefaulted(loanId, usdAmount);
    }

    /// @inheritdoc IFixedInterestBulletLoans
    function cancelLoan(uint256 loanId)
        external
        whenNotPaused
        onlyLoanStatus(loanId, FixedInterestBulletLoanStatus.Created)
    {
        _requirePortfolio();
        _changeLoanStatus(loanId, FixedInterestBulletLoanStatus.Canceled);
        emit Canceled(loanId);
    }

    /// @inheritdoc IFixedInterestBulletLoans
    function markLoanAsDefaulted(uint256 loanId)
        external
        whenNotPaused
        onlyLoanStatus(loanId, FixedInterestBulletLoanStatus.Started)
    {
        _requirePortfolio();
        _changeLoanStatus(loanId, FixedInterestBulletLoanStatus.Defaulted);
        emit Defaulted(loanId);
    }

    /// @inheritdoc IFixedInterestBulletLoans
    function getLoansLength() external view returns (uint256) {
        return loans.length;
    }

    /// @inheritdoc IFixedInterestBulletLoans
    function isOverdue(uint256 loanId) external view returns (bool) {
        return loans[loanId].startDate + loans[loanId].duration < block.timestamp;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _getUsdPrincipal(uint256 loanId) internal view returns (uint256) {
        return currencyConverter.convertToUSD(loans[loanId].krwPrincipal);
    }

    function _changeLoanStatus(uint256 loanId, FixedInterestBulletLoanStatus _status) internal {
        loans[loanId].status = _status;
        emit LoanStatusChanged(loanId, _status);
    }

    function _requirePortfolio() internal view {
        if (_msgSender() != address(portfolio)) {
            revert NotPortfolio();
        }
    }
}