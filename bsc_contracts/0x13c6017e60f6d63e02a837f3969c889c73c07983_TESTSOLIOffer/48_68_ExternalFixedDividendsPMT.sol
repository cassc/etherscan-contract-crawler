/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./../TokenTransfer.sol";
import "../../../library/LiqiMathLib.sol";

/**
 * @dev ExternalFixedDividendsPMT
 */
contract ExternalFixedDividendsPMT is TokenTransfer {
    using SafeMath for uint256;

    /**
     * @dev Date that starts the interest period
     * @notice Data que o interesse começa a contar
     */
    uint256 public constant DATE_INTEREST_START = 0; // Unix Timestamp
    /**
     * @dev Date the dividends finish
     * @notice Data que o interesse termina
     */
    uint256 public constant DATE_INTEREST_END = 1000; // Unix Timestamp

    /**
     * @dev % of the remaining paid each month
     * @notice Porcentagem do restante que será paga todo mês
     */
    uint256 public constant MONTHLY_INTEREST_RATE = 1.22 * 1 ether;
    /**
     * @dev The price of the token
     * @notice Valor do token
     */
    uint256 public constant TOKEN_BASE_RATE = 2500;
    /**
     * @dev The total amount of interest payments
     * @notice Total de parcelas de pagamento de interesse
     */
    uint256 public constant TOTAL_PERIODS = 25;
    /**
     * @dev The periods that are already prepaid prior to this contract
     * @notice A quantidade de periodos que já foram pagos antes da emissão deste contrato
     */
    uint256 public constant PRE_PAID_PERIODS = 2;

    // Index of the last token snapshot
    uint256 private nCurrentSnapshotId;
    // A flag marking if the payment was completed
    bool private bCompletedPayment;
    // Total amount of input tokens paid to holders
    uint256 private nTotalDividendsPaid;
    // Total amount of input tokens worth of total supply + interest
    uint256 private nTotalInputInterest;
    // The amount that should be paid
    uint256 private nPaymentValue;
    // The total amount of interest paid over the entire period
    uint256 private nTotalInterest;

    // A flag indicating if initialize() has been invoked
    bool private bInitialized;

    // Map of snapshot index to dividend date
    mapping(uint256 => uint256) private mapPaymentDate;

    /**
     * @dev Dividends based on annual payment (PMT) formula
     */
    constructor(
        address _issuer,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public TokenTransfer(_issuer, _totalTokens, _tokenName, _tokenSymbol) {
        // make sure all our periods aren't prepaid
        require(
            TOTAL_PERIODS - 1 > PRE_PAID_PERIODS,
            "Need at least 1 period payment"
        );
    }

    /**
     * @dev Ready the contract for dividend payments
     */
    function initialize() public {
        require(!bInitialized, "Contract is already initialized");
        bInitialized = true;

        // calculate how many input tokens we have
        uint256 nTotalValue = totalSupply().mul(TOKEN_BASE_RATE);

        // calculate the payment
        nPaymentValue = PMT(
            MONTHLY_INTEREST_RATE,
            TOTAL_PERIODS,
            nTotalValue,
            0,
            0
        );

        // round the payment value
        nPaymentValue = nPaymentValue.div(0.01 ether);
        nPaymentValue = nPaymentValue.mul(1 ether);

        // get total periods to pay
        uint256 nPeriodsToPay = TOTAL_PERIODS.sub(PRE_PAID_PERIODS);

        // calculate the total amount the issuer has to pay by the end of the contract
        nTotalInputInterest = nPaymentValue.mul(nPeriodsToPay);

        // calculate the total interest
        uint256 nTotalInc = nTotalInputInterest.mul(1 ether);
        nTotalInterest = nTotalInc.div(nTotalValue);
        nTotalInterest = nTotalInterest.mul(10);
    }

    /**
     * @dev Annual Payment
     */
    function PMT(
        uint256 ir,
        uint256 np,
        uint256 pv,
        uint256 fv,
        uint256 tp
    ) public pure returns (uint256) {
        /*
         * ir   - interest rate per month
         * np   - number of periods (months)
         * pv   - present value
         * fv   - future value
         * type - when the payments are due:
         *        0: end of the period, e.g. end of month (default)
         *        1: beginning of period
         */
        ir = ir.div(100);
        pv = pv.div(100);

        if (ir == 0) {
            // TODO: untested
            return -(pv + fv) / np;
        }

        uint256 nPvif = (1 ether + ir);

        //pmt = (-ir * (pv * pvif + fv)) / (pvif - 1);
        uint256 originalPVIF = nPvif;
        for (uint8 i = 1; i < np; i++) {
            nPvif = nPvif * originalPVIF;
            // TODO: this only works if the ir has only 1 digit
            nPvif = nPvif.div(1 ether);
        }

        uint256 nPvPviFv = pv.mul(nPvif.add(fv));
        uint256 topValue = ir.mul(nPvPviFv);
        uint256 botValue = (nPvif - 1 ether);

        uint256 pmt = topValue / botValue;

        if (tp == 1) {
            // TODO: untested
            pmt /= (1 ether + ir);
        }

        pmt /= 1 ether;

        return pmt;
    }

    function setPaidDividendsMultiple(uint256 _count) public onlyOwner {
        for (uint256 i = 0; i < _count; i++) {
            setPaidDividends();
        }
    }

    /**
     * @dev Owner function to pay dividends to all token holders
     */
    function setPaidDividends() public onlyOwner {
        require(bInitialized, "Contract is not initialized");
        require(!bCompletedPayment, "Dividends payment is already completed");

        // increase the total amount paid
        nTotalDividendsPaid = nTotalDividendsPaid.add(nPaymentValue);

        // snapshot the tokens at the moment the ether enters
        nCurrentSnapshotId = _snapshot();

        // check if we have paid everything
        if (nCurrentSnapshotId == TOTAL_PERIODS.sub(PRE_PAID_PERIODS)) {
            bCompletedPayment = true;
        }

        // save the date
        mapPaymentDate[nCurrentSnapshotId] = block.timestamp;
    }

    function getDividends(address _aInvestor, uint256 _nPaymentIndex)
        public
        view
        returns (uint256)
    {
        // get the balance of the user at this snapshot
        uint256 nTokenBalance = balanceOfAt(_aInvestor, _nPaymentIndex);

        // get the date the payment entered the system
        uint256 nPaymentDate = mapPaymentDate[_nPaymentIndex];

        // get the total amount of balance this user has in offers
        uint256 nTotalOffers = getTotalInOffers(nPaymentDate, _aInvestor);

        // add the total amount the user has in offers
        nTokenBalance = nTokenBalance.add(nTotalOffers);

        if (nTokenBalance == 0) {
            return 0;
        } else {
            // get the total supply at this snapshot
            uint256 nTokenSuppy = totalSupplyAt(_nPaymentIndex);

            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive = LiqiMathLib.mulDiv(
                nTokenBalance,
                nPaymentValue,
                nTokenSuppy
            );

            return nToReceive;
        }
    }

    /**
     * @dev Gets the total amount of available dividends
     * to be cashed out for the specified _investor
     */
    function getDividendsRange(
        address _investor,
        uint256 _startIndex,
        uint256 _endIndex
    ) public view returns (uint256) {
        // start total balance 0
        uint256 nBalance = 0;

        // loop
        for (uint256 i = _startIndex; i < _endIndex; i++) {
            // add the balance that would be withdrawn if called for this index
            nBalance = nBalance.add(getDividends(_investor, i));
        }

        return nBalance;
    }

    /**
     * @dev Returns a flag indicating if the contract has been initialized
     */
    function getInitialized() public view returns (bool) {
        return bInitialized;
    }

    /**
     * @dev Gets the total count of payments
     */
    function getTotalDividendPayments() public view returns (uint256) {
        return nCurrentSnapshotId;
    }

    /**
     * @dev Gets the total count of dividends was paid to this contract
     */
    function getTotalDividendsPaid() public view returns (uint256) {
        return nTotalDividendsPaid;
    }

    /**
     * @dev Gets the total amount the issuer has to pay by the end of the contract
     */
    function getTotalPayment() public view returns (uint256) {
        return nTotalInputInterest;
    }

    /**
     * @dev True if the issuer paid all installments
     */
    function getCompletedPayment() public view returns (bool) {
        return bCompletedPayment;
    }

    /**
     * @dev Gets the date the issuer executed the specified payment index
     */
    function getPaymentDate(uint256 _nIndex) public view returns (uint256) {
        return mapPaymentDate[_nIndex];
    }

    /**
     * @dev Returns the MONTHLY_INTEREST_RATE constant
     */
    function getMonthlyInterestRate() public pure returns (uint256) {
        return MONTHLY_INTEREST_RATE;
    }

    function getTotalInterest() public view returns (uint256) {
        return nTotalInterest;
    }

    /**
     * @dev Returns the minimum payment value needed to execute payDividends
     */
    function getPaymentValue() public view returns (uint256) {
        return nPaymentValue;
    }

    /**
     * @dev Gets current token value based in the total payments
     */
    function getCurrentTokenValue() public view returns (uint256) {
        uint256 nTotalPeriods = TOTAL_PERIODS - PRE_PAID_PERIODS;
        uint256 nDiffPercent = LiqiMathLib.mulDiv(
            nCurrentSnapshotId.mul(1 ether),
            TOKEN_BASE_RATE.mul(1 ether),
            nTotalPeriods
        );

        nDiffPercent = nDiffPercent.div(1 ether).div(1 ether);
        nDiffPercent = TOKEN_BASE_RATE.sub(nDiffPercent);

        return nDiffPercent;
    }

    /**
     * @dev Gets current percent % of total based in the total payments
     */
    function getCurrentPercentPaid() public view returns (uint256) {
        uint256 nTotalPeriods = TOTAL_PERIODS - PRE_PAID_PERIODS;
        uint256 nDiffPercent = LiqiMathLib.mulDiv(
            nCurrentSnapshotId.mul(1 ether),
            nTotalInterest,
            nTotalPeriods
        );

        nDiffPercent = nDiffPercent.div(1 ether);
        return nDiffPercent;
    }

    /**
     * @dev Gets current token value based in period
     */
    function getLinearTokenValue(uint256 _nDate) public pure returns (uint256) {
        if (_nDate >= DATE_INTEREST_END) {
            return 0;
        } else if (_nDate <= DATE_INTEREST_START) {
            return TOKEN_BASE_RATE;
        }

        uint256 nTotalDays = DATE_INTEREST_END.sub(DATE_INTEREST_START);
        uint256 nCurrentDays = DATE_INTEREST_END.sub(_nDate);
        uint256 nDiffPercent = LiqiMathLib.mulDiv(
            nCurrentDays,
            TOKEN_BASE_RATE,
            nTotalDays
        );

        return nDiffPercent;
    }

    /**
     * @dev Gets current percent based in period
     */
    function getLinearPercentPaid(uint256 _nDate)
        public
        view
        returns (uint256)
    {
        if (_nDate >= DATE_INTEREST_END) {
            return nTotalInterest;
        } else if (_nDate <= DATE_INTEREST_START) {
            return 0;
        }

        uint256 nTotalDays = DATE_INTEREST_END.sub(DATE_INTEREST_START);
        uint256 nCurrentDays = DATE_INTEREST_END.sub(_nDate);
        uint256 nDiffPercent = LiqiMathLib.mulDiv(
            nCurrentDays,
            nTotalInterest,
            nTotalDays
        );

        return nTotalInterest.sub(nDiffPercent);
    }
}