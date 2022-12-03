/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./../TokenTransfer.sol";
import "../../../library/LiqiMathLib.sol";

/**
 * @dev FixedDividendsPMTERC20 handles the payment of a simple dividends
 * with monthly interest
 */
contract FixedDividendsPMTERC20 is TokenTransfer {
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
     * @notice Porcentagem do restante paga todo mês
     */
    uint256 public constant MONTHLY_INTEREST_RATE = 1.3 * 1 ether;
    /**
     * @dev The price of the token
     * @notice Valor do token
     */
    uint256 public constant TOKEN_BASE_RATE = 2500;
    /**
     * @dev The total amount of interest payments
     * @notice Total de parcelas de pagamento de interesse
     */
    uint256 public constant TOTAL_PERIODS = 20;
    /**
     * @dev The periods that are already prepaid prior to this contract
     * @notice A quantidade de periodos que já foram pagos antes da emissão deste contrato
     */
    uint256 public constant PRE_PAID_PERIODS = 3;

    // Index of the last token snapshot
    uint256 private nCurrentSnapshotId;
    // Reference to the token the dividends are paid in
    IERC20 private dividendsToken;
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

    // Map of investor to last payment snapshot index
    mapping(address => uint256) private mapLastPaymentSnapshot;
    // Map of snapshot index to dividend date
    mapping(uint256 => uint256) private mapPaymentDate;

    /**
     * @dev Dividends based on annual payment (PMT) formula
     */
    constructor(
        address _issuer,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _dividendsToken
    ) public TokenTransfer(_issuer, _totalTokens, _tokenName, _tokenSymbol) {
        // make sure the dividends token isnt empty
        require(_dividendsToken != address(0), "Dividends token cant be zero");

        // convert the address to an interface
        dividendsToken = IERC20(_dividendsToken);

        // get the balance of this contract to check if the interface works
        uint256 nBalance = dividendsToken.balanceOf(address(this));

        // this is never false, it's just a failsafe so that we execute balanceOf
        require(nBalance == 0, "Contract must have no balance");

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

    /**
     * @dev Owner function to pay dividends to all token holders
     * @notice Invocado para pagar dividendos para os token holders.
     * Antes de ser chamado, é necessário chamar increaseAllowance() com no minimo o valor da próxima parcela
     */
    function payDividends() public onlyOwner {
        require(bInitialized, "Contract is not initialized");
        require(!bCompletedPayment, "Dividends payment is already completed");

        // grab our current allowance
        uint256 nAllowance = dividendsToken.allowance(
            _msgSender(),
            address(this)
        );

        // make sure we are allowed to transfer the total payment value
        require(
            nPaymentValue <= nAllowance,
            "Not enough allowance to pay dividends"
        );

        // increase the total amount paid
        nTotalDividendsPaid = nTotalDividendsPaid.add(nPaymentValue);

        // transfer the tokens from the sender to the contract
        dividendsToken.transferFrom(_msgSender(), address(this), nPaymentValue);

        // snapshot the tokens at the moment the ether enters
        nCurrentSnapshotId = _snapshot();

        // check if we have paid everything
        if (nCurrentSnapshotId == TOTAL_PERIODS.sub(PRE_PAID_PERIODS)) {
            bCompletedPayment = true;
        }

        // save the date
        mapPaymentDate[nCurrentSnapshotId] = block.timestamp;
    }

    /**
     * @dev
     * @notice Invoca payDividends _count numero de vezes
     */
    function payDividendsMultiple(uint256 _count) public onlyOwner {
        for (uint256 i = 0; i < _count; i++) {
            payDividends();
        }
    }

    /**
     * @dev Withdraws dividends up to 16 times for the calling user
     * @notice Saca até 16 dividendos para o endereço invocando a função
     */
    function withdrawDividends() public {
        address aSender = _msgSender();

        require(_withdrawDividends(aSender), "No new withdrawal");

        for (uint256 i = 0; i < 15; i++) {
            if (!_withdrawDividends(aSender)) {
                return;
            }
        }
    }

    /**
     * @dev Withdraws dividends up to 16 times for the specified user
     * @notice Saca até 16 dividendos para o endereço especificado
     */
    function withdrawDividend() public {
        address aSender = _msgSender();

        require(_withdrawDividends(aSender), "No new withdrawal");
    }

    /**
     * @dev Withdraws dividends up to 16 times for any specific user
     */
    function withdrawDividendsAny(address _investor) public {
        require(_withdrawDividends(_investor), "No new withdrawal");

        for (uint256 i = 0; i < 15; i++) {
            if (!_withdrawDividends(_investor)) {
                return;
            }
        }
    }

    /**
     * @dev Withdraws only 1 dividend for the specified user
     * @notice Saca apenas 1 dividendo para o endereço especificado
     */
    function withdrawDividendAny(address _investor) public {
        require(_withdrawDividends(_investor), "No new withdrawal");
    }

    /**
     * @dev
     * @notice Retorna qual o saldo de dividendos do investidor na parcela especificada
     */
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
     * @dev Gets the total amount of dividends for an investor
     * @notice Retorna qual o saldo total de dividendos do investidor especificado.
     * Note que o limite de parcelas que esse método calcula é 16, se houverem mais dividendos pendentes o valor estará incompleto.
     */
    function getTotalDividends(address _investor)
        public
        view
        returns (uint256)
    {
        // start total balance 0
        uint256 nBalance = 0;

        // get the last payment index for the investor
        uint256 nLastPayment = mapLastPaymentSnapshot[_investor];

        // add 16 as the limit
        uint256 nEndPayment = Math.min(
            nLastPayment.add(16),
            nCurrentSnapshotId.add(1)
        );

        // loop
        for (uint256 i = nLastPayment.add(1); i < nEndPayment; i++) {
            // add the balance that would be withdrawn if called for this index
            nBalance = nBalance.add(getDividends(_investor, i));
        }

        return nBalance;
    }

    /**
     * @dev Based on how many tokens the user had at the snapshot,
     * pay dividends of the erc20 token
     * (also pays for tokens inside offer)
     */
    function _withdrawDividends(address _sender) private returns (bool) {
        // read the last payment
        uint256 nLastUserPayment = mapLastPaymentSnapshot[_sender];

        // make sure we have a next payment
        if (nLastUserPayment >= nCurrentSnapshotId) {
            return false;
        }

        // add 1 to get the next payment
        uint256 nNextUserPayment = nLastUserPayment.add(1);

        // save back that we have paid this user
        mapLastPaymentSnapshot[_sender] = nNextUserPayment;

        // get the balance of the user at this snapshot
        uint256 nTokenBalance = balanceOfAt(_sender, nNextUserPayment);

        // get the date the payment entered the system
        uint256 nPaymentDate = mapPaymentDate[nNextUserPayment];

        // get the total amount of balance this user has in offers
        uint256 nBalanceInOffers = getTotalInOffers(nPaymentDate, _sender);

        // add the total amount the user has in offers
        nTokenBalance = nTokenBalance.add(nBalanceInOffers);

        if (nTokenBalance != 0) {
            // get the total supply at this snapshot
            uint256 nTokenSupply = totalSupplyAt(nNextUserPayment);

            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive = LiqiMathLib.mulDiv(
                nTokenBalance,
                nPaymentValue,
                nTokenSupply
            );

            // send the ERC20 value to the user
            dividendsToken.transfer(_sender, nToReceive);
        }

        return true;
    }

    /**
     * @dev Returns a flag indicating if the contract has been initialized
     * @notice Retorna uma flag indicando se o metodo initialize() foi invocado e o token está inicializado
     */
    function getInitialized() public view returns (bool) {
        return bInitialized;
    }

    /**
     * @dev Gets the address of the token used for dividends
     * @notice Retorna o endereço do token de dividendos
     */
    function getDividendsToken() public view returns (address) {
        return address(dividendsToken);
    }

    /**
     * @dev Gets the total count of payments
     * @notice Retorna a quantidade total de pagamentos efetuados até agora
     */
    function getTotalDividendPayments() public view returns (uint256) {
        return nCurrentSnapshotId;
    }

    /**
     * @dev Gets the total count of dividends was paid to this contract
     * @notice Retorna a quantidade total de tokens pagos a esse contrato
     */
    function getTotalDividendsPaid() public view returns (uint256) {
        return nTotalDividendsPaid;
    }

    /**
     * @dev Gets the total amount the issuer has to pay by the end of the contract
     * @notice Retorna quanto o emissor precisa pagar até o fim do contrato
     */
    function getTotalPayment() public view returns (uint256) {
        return nTotalInputInterest;
    }

    /**
     * @dev True if the issuer paid all installments
     * @notice Retorna true se o pagamento de todas as parcelas tiverem sido efetuados
     */
    function getCompletedPayment() public view returns (bool) {
        return bCompletedPayment;
    }

    /**
     * @dev Gets the date the issuer executed the specified payment index
     * @notice Retorna a data de pagamento da parcela especificada
     */
    function getPaymentDate(uint256 _nIndex) public view returns (uint256) {
        return mapPaymentDate[_nIndex];
    }

    /**
     * @dev Gets the last payment index for the specified investor
     * @notice Retorna o ultimo pagamento feito ao investidor especificado
     */
    function getLastWithdrawal(address _aInvestor) public view returns (uint256) {
        return mapLastPaymentSnapshot[_aInvestor];
    }

    /**
     * @dev Returns the MONTHLY_INTEREST_RATE constant
     * @notice Retorna a constante MONTHLY_INTEREST_RATE
     */
    function getMonthlyInterestRate() public pure returns (uint256) {
        return MONTHLY_INTEREST_RATE;
    }

    /**
     * @dev Returns the total amount of interest generated over the specified period
     * @notice Retorna o total de interesse gerado sob o periodo especificado no contrato
     */
    function getTotalInterest() public view returns (uint256) {
        return nTotalInterest;
    }

    /**
     * @dev Returns the minimum payment value needed to execute payDividends
     * @notice Retorna o valor necessário para invocar payDividends
     */
    function getPaymentValue() public view returns (uint256) {
        return nPaymentValue;
    }

    /**
     * @dev Gets current token value based in the total payments
     * @notice Retorna o valor do token linear até a data especificada
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
     * @notice Retorna a porcentagem do total de pagamentos feito
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
     * @notice Retorna o valor do token linear até a data especificada
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
     * @notice Retorna a porcentagem do total de pagamentos linearmente até a data
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