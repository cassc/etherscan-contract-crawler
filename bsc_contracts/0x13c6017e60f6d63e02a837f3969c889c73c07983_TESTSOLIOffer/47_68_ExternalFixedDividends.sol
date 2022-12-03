/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./../TokenTransfer.sol";
import "../../../library/LiqiMathLib.sol";

/**
 * @dev ExternalFixedDividends handles the payment of a fixed amount of dividends partially
 * @notice ExternalFixedDividends é um token customizado onde os dividendos são pagos de forma externa, com valor pré-fixado.
 */
contract ExternalFixedDividends is TokenTransfer {
    using SafeMath for uint256;

    /**
     * @dev Date that starts the interest period
     * @notice Data que o interesse começa a contar
     */
    uint256 public constant DATE_INTEREST_START = 4102455600; // Unix Timestamp
    /**
     * @dev Date the dividends finish
     * @notice Data que o interesse termina
     */
    uint256 public constant DATE_INTEREST_END = 4133991600; // Unix Timestamp

    /**
     * @dev The % of interest generated in the entire interest period
     * @notice A % de interesse gerado sob todo o periodo
     */
    uint256 public constant INTEREST_RATE = 37.532 * 1 ether;

    /**
     * @dev The price of the token
     * @notice Valor do token
     */
    uint256 public constant TOKEN_BASE_RATE = 5000;
    
    /**
     * @dev The total amount of interest payments
     * @notice Total de parcelas de pagamento de interesse
     */
    uint256 public constant TOTAL_PERIODS = 24;

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

    // Map of snapshot index to dividend date
    mapping(uint256 => uint256) private mapPaymentDate;

    /**
     * @dev Fixed Dividends
     */
    constructor(
        address _issuer,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public TokenTransfer(_issuer, _totalTokens, _tokenName, _tokenSymbol) {
        // calculate the total supply of tokens with interest
        uint256 nInterestTokenSupply = LiqiMathLib.mulDiv(
            totalSupply(),
            INTEREST_RATE.add(100 ether),
            100 ether
        );

        // calculate total input token amount to payoff all dividends
        nTotalInputInterest = nInterestTokenSupply.mul(TOKEN_BASE_RATE);

        // calculate how much each payment should be
        nPaymentValue = nTotalInputInterest.div(TOTAL_PERIODS);
    }

    function setPaidDividendsMultiple(uint256 _count) public onlyOwner {
        for (uint256 i = 0; i < _count; i++) {
            setPaidDividends();
        }
    }

    /**
     * @dev Owner function to flag dividends were paid to all token holders
     */
    function setPaidDividends() public onlyOwner {
        require(!bCompletedPayment, "Dividends payment is already completed");

        // increase the total amount paid
        nTotalDividendsPaid = nTotalDividendsPaid.add(nPaymentValue);

        // snapshot the tokens at the moment the Ether enters
        nCurrentSnapshotId = _snapshot();

        // check if we have paid everything
        if (nCurrentSnapshotId == TOTAL_PERIODS) {
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
     * @dev Gets current interest
     */
    function getCurrentInterest() public view returns (uint256) {
        return getPercentByTime(block.timestamp);
    }

    /**
     * @dev Returns the INTEREST_RATE constant
     */
    function getInterestRate() public pure returns (uint256) {
        return INTEREST_RATE;
    }

    /**
     * @dev Returns the minimum payment value needed to execute payDividends
     */
    function getPaymentValue() public view returns (uint256) {
        return nPaymentValue;
    }

    /**
     * @dev Gets current percent based in period
     */
    function getPercentByTime(uint256 _nPaymentDate)
        public
        pure
        returns (uint256)
    {
        if (_nPaymentDate >= DATE_INTEREST_END) {
            return INTEREST_RATE;
        } else if (_nPaymentDate <= DATE_INTEREST_START) {
            return 0;
        }

        uint256 nTotalDays = DATE_INTEREST_END.sub(DATE_INTEREST_START);
        uint256 nCurrentDays = DATE_INTEREST_END.sub(_nPaymentDate);
        uint256 nDiffPercent = LiqiMathLib.mulDiv(
            nCurrentDays.mul(1 ether),
            INTEREST_RATE.mul(1 ether),
            nTotalDays.mul(1 ether)
        );

        uint256 nInterestRate = INTEREST_RATE.mul(1 ether);

        uint256 nFinalValue = nInterestRate.sub(nDiffPercent);

        return nFinalValue.div(1 ether);
    }

    function getCurrentTokenValue() public view returns (uint256) {
        return getLinearTokenValue(block.timestamp);
    }

    /**
     * @dev Gets current token value based in period
     */
    function getLinearTokenValue(uint256 _nDate) public pure returns (uint256) {
        if (_nDate <= DATE_INTEREST_START) {
            return TOKEN_BASE_RATE;
        }

        uint256 nInterest = LiqiMathLib.mulDiv(
            TOKEN_BASE_RATE,
            INTEREST_RATE,
            100 ether
        );

        if (_nDate >= DATE_INTEREST_END) {
            return nInterest.add(TOKEN_BASE_RATE);
        }

        uint256 nTotalDays = DATE_INTEREST_END.sub(DATE_INTEREST_START);
        uint256 nCurrentDays = DATE_INTEREST_END.sub(_nDate);
        uint256 nDiffPercent = LiqiMathLib.mulDiv(
            nCurrentDays,
            nInterest,
            nTotalDays
        );

        nDiffPercent = nInterest.sub(nDiffPercent);

        return TOKEN_BASE_RATE.add(nDiffPercent);
    }
}