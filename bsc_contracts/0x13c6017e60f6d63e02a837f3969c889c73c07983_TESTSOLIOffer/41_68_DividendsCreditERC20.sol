/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./../TokenTransfer.sol";
import "../../../library/BokkyPooBahsDateTimeLibrary.sol";
import "../../../library/LiqiMathLib.sol";

/**
 * @dev DividendsCreditERC20
 * @notice Módulo para dividendos de crédito,
 * onde a quantidade de tokens emitidos é calculado a partir do valor total das parcelas, menos a porcentagem de desconto aplicada diariamente.
 */
contract DividendsCreditERC20 is TokenTransfer {
    using SafeMath for uint256;

    /**
     * @dev The price of the token
     * @notice O valor base de venda do token
     */
    uint256 public constant TOKEN_BASE_RATE = 2500;

    /**
     * @dev The value of each period
     * @notice Valor de pagamento de cada parcela
     */
    uint256[] private PERIOD_VALUES = [
        105843.00 * 100 ether,
        51557.40 * 100 ether,
        36204.00 * 100 ether,
        36204.00 * 100 ether,
        36204.00 * 100 ether
    ];

    /**
     * @dev The date for each period
     * @notice Datas de pagamento de cada parcela (unix)
     */
    uint256[] private PERIOD_DATES = [
        1661871600,
        1664550000,
        1664550000,
        1661871600,
        1661871600
    ];

    /**
     * @dev
     * @notice Data que o interesse começa a contar
     */
    uint256 public constant DATE_INTEREST_START = 1648479600;

    /**
     * @dev The daily discount rate, in %
     * @notice Taxa de desconto diária em porcentagem
     */
    uint256 public constant DAILY_DISCOUNT_RATE = 0.039769808976692 * 1 ether;

    // Index of the last token snapshot
    uint256 private nCurrentSnapshotId;
    // Reference to the token the dividends are paid in
    IERC20 private dividendsToken;
    // A flag marking if the payment was completed
    bool private bCompletedPayment;
    // Total amount of input tokens paid to holders
    uint256 private nTotalDividendsPaid;

    // Map of investor to last payment snapshot index
    mapping(address => uint256) private mapLastPaymentSnapshot;
    // Map of snapshot index to dividend date
    mapping(uint256 => uint256) private mapPaymentDate;

    uint256 private nStatus;

    // Total amount of interest
    uint256 private nTotalInterest;
    uint256 private nTotalTokens;
    uint256 private nTotalValue;
    uint256 private nTotalDiscountedValue;
    // State of contract initialization
    bool private bInitialized;

    // Array with interest for each payment index
    uint256[] private arrInterests;
    uint256[] private arrDiscountedValue;

    /**
     * @dev Constructor for DividendCreditsERC20
     * @notice Constructor para DividendCreditsERC20
     */
    constructor(
        address _issuer,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _dividendsToken
    ) public TokenTransfer(_issuer, 0, _tokenName, _tokenSymbol) {
        // make sure the dividends token isnt empty
        require(_dividendsToken != address(0), "Dividends token cant be zero");

        // make sure we have the same number of values and dates
        require(
            PERIOD_VALUES.length == PERIOD_DATES.length,
            "Values and dates must have the same size"
        );

        // convert the address to an interface
        dividendsToken = IERC20(_dividendsToken);

        // get the balance of this contract to check if the interface works
        uint256 nBalance = dividendsToken.balanceOf(address(this));

        // this is never false, it's just a failsafe so that we execute balanceOf
        require(nBalance == 0, "Contract must have no balance");
    }

    /**
     * @dev Returns true if the provided timestamp is the last day in February
     * @notice Retorna true se a timestamp provida é o último dia de Fevereiro
     */
    function isFebLastDay(uint256 _timestamp) public pure returns (bool) {
        (
            uint256 nTimeYear,
            uint256 nTimeMonth,
            uint256 nTimeDay
        ) = BokkyPooBahsDateTimeLibrary.timestampToDate(_timestamp);

        if (nTimeMonth == 2) {
            uint256 nFebDays = BokkyPooBahsDateTimeLibrary._getDaysInMonth(
                nTimeYear,
                nTimeMonth
            );

            return nTimeDay == nFebDays;
        }
        return false;
    }

    /**
     * @dev Returns how many days there are between _startDate and _endDate, considering that a year has 360 days.
     * @notice Retorna quantos dias há entre StartDate e EndDate em um ano de 360 dias. Função utilizada na inicialização, pública para referência.
     */
    function days360(
        uint256 _startDate,
        uint256 _endDate,
        bool _method
    ) public pure returns (uint256) {
        (
            uint256 nStartYear,
            uint256 nStartMonth,
            uint256 nStartDay
        ) = BokkyPooBahsDateTimeLibrary.timestampToDate(_startDate);

        (
            uint256 nEndYear,
            uint256 nEndMonth,
            uint256 nEndDay
        ) = BokkyPooBahsDateTimeLibrary.timestampToDate(_endDate);

        if (_method) {
            nStartDay = Math.min(nStartDay, 30);
            nEndDay = Math.min(nEndDay, 30);
        } else {
            // If both date A and B fall on the last day of February, then date B will be changed to
            // the 30th (unless preserving Excel compatibility)
            bool bIsStartLast = isFebLastDay(nStartDay);
            if (bIsStartLast && isFebLastDay(nEndDay)) {
                nEndDay = 30;
            }
            // If date A falls on the 31st of a month or last day of February, then date A will be changed
            // to the 30th.
            if (bIsStartLast || nStartDay == 31) {
                nStartDay = 30;
            }
            // If date A falls on the 30th of a month after applying (2) above and date B falls on the
            // 31st of a month, then date B will be changed to the 30th.
            if (nStartDay == 30 && nEndDay == 31) {
                nEndDay = 30;
            }
        }

        return
            ((nEndYear - nStartYear) * 360) +
            ((nEndMonth - nStartMonth) * 30) +
            (nEndDay - nStartDay);
    }

    /**
     * @dev
     * @notice Executada até o contrato ser inicializado,
     * faz a emissão dos tokens de acordo com as constantes definidas no contrato e
     * calcula os dados a serem utilizados por funcões de referência
     */
    function initialize() public {
        require(!bInitialized, "Contract is already initialized");
        uint256 PAGE_DIVISION = 20;
        uint256 nPages = Math.max(1, PERIOD_VALUES.length / PAGE_DIVISION);

        // convert the discount rate from 0-1 to 0-100
        uint256 nDailyDiscount = DAILY_DISCOUNT_RATE + 100 ether;

        uint256 nStartIndex = PAGE_DIVISION * nStatus;
        uint256 nFinalIndex = Math.min(
            nStartIndex + PAGE_DIVISION,
            PERIOD_VALUES.length
        );

        if (nStatus < nPages + 1) {
            for (uint256 i = nStartIndex; i < nFinalIndex; i++) {
                uint256 nPeriodValue = PERIOD_VALUES[i];
                uint256 nPeriodDate = PERIOD_DATES[i];

                require(nPeriodDate >= DATE_INTEREST_START, "Interest date provided is before one of the payments dates");

                uint256 nDays = days360(
                    DATE_INTEREST_START,
                    nPeriodDate,
                    false
                );

                // total discount = daily discount ^ number of days
                uint256 nDiscountRate = nDailyDiscount;
                for (uint256 j = 1; j < nDays; j++) {
                    nDiscountRate = nDiscountRate * nDailyDiscount;
                    nDiscountRate = nDiscountRate / 100 ether;
                }

                uint256 nDiscountedValue = nPeriodValue * 1 ether;
                nDiscountedValue = (nDiscountedValue / nDiscountRate) * 100;
                arrDiscountedValue.push(nDiscountedValue);

                nTotalValue = nTotalValue.add(nPeriodValue);
                nTotalDiscountedValue = nTotalDiscountedValue.add(
                    nDiscountedValue
                );

                // divide the discount value by the token value to get the amount of tokens this period is worth
                nTotalTokens = nTotalTokens.add(
                    nDiscountedValue.div(TOKEN_BASE_RATE)
                );
            }

            nStatus = nStatus.add(1);
        } else {
            _mint(aIssuer, nTotalTokens);

            uint256 nTotalInterestValue = nTotalValue.sub(
                nTotalDiscountedValue
            );

            uint256 nTotalInterestPC = LiqiMathLib.mulDiv(
                nTotalValue,
                100 ether,
                nTotalDiscountedValue
            );
            nTotalInterestPC = nTotalInterestPC.sub(100 ether);

            for (uint8 i = 0; i < PERIOD_VALUES.length; i++) {
                uint256 nPeriodValue = PERIOD_VALUES[i];
                uint256 nDiscountedValue = arrDiscountedValue[i];

                uint256 nPeriodInterestValue = nPeriodValue.sub(
                    nDiscountedValue
                );

                uint256 nPeriodInterestTotalPC = LiqiMathLib.mulDiv(
                    nPeriodInterestValue,
                    100 ether,
                    nTotalInterestValue
                );

                uint256 nPeriodInterestPC = LiqiMathLib.mulDiv(
                    nPeriodInterestTotalPC,
                    nTotalInterestPC,
                    100 ether
                );

                arrInterests.push(nPeriodInterestPC);

                nTotalInterest = nTotalInterest.add(nPeriodInterestPC);
            }

            bInitialized = true;
        }
    }

    /**
     * @dev Returns the discount rate for a 30-day period
     * @notice Retorna a taxa de disconto para um periodo de 30 dias
     */
    function getMonthlyDiscountRate() public pure returns (uint256) {
        uint256 nDailyDiscount = DAILY_DISCOUNT_RATE + 100 ether;

        uint256 nDiscountRate = nDailyDiscount;
        for (uint8 j = 1; j < 30; j++) {
            nDiscountRate = nDiscountRate * nDailyDiscount;
            nDiscountRate = nDiscountRate.div(100 ether);
        }

        return nDiscountRate.sub(100 ether);
    }

    function onCreate(uint256 _totalTokens) internal override {}

    /**
     * @dev Owner function to pay dividends to all token holders
     * @notice Invocado para pagar dividendos para os token holders.
     * Antes de ser chamado, é necessário chamar increaseAllowance() com no minimo o valor da próxima parcela
     */
    function payDividends() public onlyOwner {
        require(bInitialized, "Contract isn't initialized");
        require(!bCompletedPayment, "Dividends payment is already completed");

        // grab our current allowance
        uint256 nAllowance = dividendsToken.allowance(
            _msgSender(),
            address(this)
        );

        // get the amount needed to pay
        uint256 nPaymentValue = PERIOD_VALUES[nCurrentSnapshotId];

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
        if (nCurrentSnapshotId == PERIOD_VALUES.length) {
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
     * @dev Withdraws only 1 dividend for the calling user
     * @notice Saca apenas 1 dividendo para o endereço invocando a função
     */
    function withdrawDividend() public {
        address aSender = _msgSender();

        require(_withdrawDividends(aSender), "No new withdrawal");
    }

    /**
     * @dev Withdraws dividends up to 16 times for the specified user
     * @notice Saca até 16 dividendos para o endereço especificado
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
     * @dev Returns the value of the next payment
     * @notice Retorna o valor do próximo pagamento
     */
    function getNextPaymentValue() public view returns (uint256) {
        if (bCompletedPayment) {
            return 0;
        }

        return PERIOD_VALUES[nCurrentSnapshotId];
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

            // get value from index
            uint256 nPaymentValue = PERIOD_VALUES[_nPaymentIndex - 1];

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
        require(bInitialized, "Contract isn't initialized");

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

            // get value from index
            uint256 nPaymentValue = PERIOD_VALUES[nLastUserPayment];

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
     * @dev Returns the total value for the contract
     * @notice Retorna o valor que será pago ao contrato
     */
    function getTotalValue() public view returns (uint256) {
        return nTotalValue;
    }

    /**
     * @dev Returns the discounted value
     * @notice Retorna o valor descontado
     */
    function getTotalDiscountedValue() public view returns (uint256) {
        return nTotalDiscountedValue;
    }

    /**
     * @dev Returns the discounted value
     * @notice Retorna o valor total menos o descontado
     */
    function getTotalInterestValue() public view returns (uint256) {
        return nTotalValue.sub(nTotalDiscountedValue);
    }

    /**
     * @dev
     * @notice Retorna true se a função initialize foi executada todas as vezes necessárias
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
     * @dev Gets the total amount of dividends was paid to this contract
     * @notice Retorna a quantidade total de tokens pagos a esse contrato
     */
    function getTotalDividendsPaid() public view returns (uint256) {
        return nTotalDividendsPaid;
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
     * @dev Gets the value to pay (0 indexed)
     * @notice Retorna a valor de pagamento da parcela especificada
     */
    function getPaymentValue(uint256 _nIndex) public view returns (uint256) {
        return PERIOD_VALUES[_nIndex];
    }

    /**
     * @dev Gets the period date to pay
     * @notice Retorna a data do periodo
     */
    function getPeriodDate(uint256 _nIndex) public view returns (uint256) {
        return PERIOD_DATES[_nIndex];
    }

    /**
     * @dev Gets the last payment index for the specified investor
     * @notice Retorna o ultimo pagamento feito ao investidor especificado
     */
    function getLastPayment(address _aInvestor) public view returns (uint256) {
        return mapLastPaymentSnapshot[_aInvestor];
    }

    /**
     * @dev Returns the total amount of payments needed to finish this contract
     * @notice Retorna a quantidade de parcelas
     */
    function getPaymentCount() public view returns (uint256) {
        return PERIOD_VALUES.length;
    }

    /**
     * @dev Gets total interest based on all payments
     * @notice Retorna a porcentagem de interesse de todos os pagamentos
     */
    function getTotalInterest() public view returns (uint256) {
        return nTotalInterest;
    }

    /**
     * @dev Gets current interest
     * @notice Retorna a porcentagem de interesse gerada até agora
     */
    function getCurrentLinearInterest() public view returns (uint256) {
        return getLinearInterest(block.timestamp);
    }

    /**
     * @dev Gets current percent based in period
     * @notice Retorna a porcentagem de interesse gerada até a data especificada
     */
    function getLinearInterest(uint256 _nPaymentDate)
        public
        view
        returns (uint256)
    {
        if (_nPaymentDate < DATE_INTEREST_START) {
            return 0;
        }

        uint256 nInterest = 0;

        // loop all dates
        for (uint8 i = 0; i < PERIOD_DATES.length; i++) {
            uint256 nPeriodInterest = arrInterests[i];
            uint256 nPeriodDate = PERIOD_DATES[i];

            if (_nPaymentDate >= nPeriodDate) {
                // if after the payment date, all interest is already generated
                nInterest += nPeriodInterest;
            } else {
                // calculate the day difference
                uint256 nTotalDays = nPeriodDate.sub(DATE_INTEREST_START);
                uint256 nCurrentDays = nTotalDays.sub(
                    nPeriodDate.sub(_nPaymentDate)
                );
                uint256 nDifInterest = LiqiMathLib.mulDiv(
                    nCurrentDays.mul(1 ether),
                    nPeriodInterest.mul(1 ether),
                    nTotalDays.mul(1 ether)
                );
                nInterest += nDifInterest.div(1 ether);
            }
        }

        return nInterest;
    }

    /**
     * @dev Gets the total amount of interest paid so far
     * @notice Retorna a porcentagem de interesse paga até agora
     */
    function getPaidInterest() public view returns (uint256) {
        if (bCompletedPayment) {
            return nTotalInterest;
        }

        return getInterest(nCurrentSnapshotId);
    }

    /**
     * @dev Gets the total amount of interest up to the specified index
     * @notice Retorna a porcentagem de interesse paga até o índice especificado
     */
    function getInterest(uint256 _nPaymentIndex) public view returns (uint256) {
        uint256 nInterest = 0;

        // loop all dates
        uint256 nLast = Math.min(_nPaymentIndex, PERIOD_VALUES.length);
        for (uint8 i = 0; i < nLast; i++) {
            uint256 nPeriodInterest = arrInterests[i];

            nInterest = nInterest.add(nPeriodInterest);
        }

        return nInterest;
    }

    /**
     * @dev Gets the amount of interest the specified period pays
     * @notice Retorna a porcentagem de interesse que o periodo especificado paga
     */
    function getPeriodInterest(uint256 _nPeriod) public view returns (uint256) {
        if (_nPeriod >= arrInterests.length) {
            return 0;
        }

        return arrInterests[_nPeriod];
    }

    /**
     * @dev Returns the current token value
     * @notice Retorna o valor do token linear até agora
     */
    function getCurrentLinearTokenValue() public view returns (uint256) {
        return getLinearTokenValue(block.timestamp);
    }

    /**
     * @dev Gets current token value based in period
     * @notice Retorna o valor do token linear até a data especificada
     */
    function getLinearTokenValue(uint256 _nPaymentDate)
        public
        view
        returns (uint256)
    {
        if (_nPaymentDate <= DATE_INTEREST_START) {
            return TOKEN_BASE_RATE;
        }

        uint256 nTokenValue = 0;

        // loop all dates
        for (uint8 i = 0; i < PERIOD_DATES.length; i++) {
            uint256 nPeriodInterest = arrInterests[i];
            uint256 nPeriodDate = PERIOD_DATES[i];

            uint256 nInterest = 0;

            if (_nPaymentDate >= nPeriodDate) {
                // if after the payment date, all interest is already generated
                nInterest = nPeriodInterest;
            } else {
                // calculate the day difference
                uint256 nTotalDays = nPeriodDate.sub(DATE_INTEREST_START);
                uint256 nCurrentDays = nTotalDays.sub(
                    nPeriodDate.sub(_nPaymentDate)
                );
                uint256 nDifInterest = LiqiMathLib.mulDiv(
                    nCurrentDays.mul(1 ether),
                    nPeriodInterest.mul(1 ether),
                    nTotalDays.mul(1 ether)
                );

                nInterest = nDifInterest.div(1 ether);
            }

            uint256 nPeriodInterestTotalPC = LiqiMathLib.mulDiv(
                nInterest,
                100 ether,
                nTotalInterest
            );

            uint256 nTokenLinear = LiqiMathLib.mulDiv(
                TOKEN_BASE_RATE,
                nPeriodInterestTotalPC,
                100 ether
            );
            nTokenValue = nTokenValue.add(nTokenLinear);
        }

        return TOKEN_BASE_RATE.sub(nTokenValue);
    }

    /**
     * @dev Gets the value of the token up to the current payment index
     * @notice Retorna o valor do token até o ultimo pagamento efetuado pelo emissor
     */
    function getCurrentTokenValue() public view returns (uint256) {
        return getTokenValue(nCurrentSnapshotId);
    }

    /**
     * @dev Gets the value of the token up to the specified payment index
     * @notice Retorna o valor do token até o pagamento especificado
     */
    function getTokenValue(uint256 _nPaymentIndex)
        public
        view
        returns (uint256)
    {
        if (_nPaymentIndex == 0) {
            return TOKEN_BASE_RATE;
        } else if (_nPaymentIndex >= PERIOD_VALUES.length) {
            return 0;
        }

        uint256 nTokenValue = 0;

        for (uint8 i = 0; i < _nPaymentIndex; i++) {
            uint256 nInterest = arrInterests[i];

            uint256 nPeriodInterestTotalPC = LiqiMathLib.mulDiv(
                nInterest,
                100 ether,
                nTotalInterest
            );

            uint256 nTokenLinear = LiqiMathLib.mulDiv(
                TOKEN_BASE_RATE,
                nPeriodInterestTotalPC,
                100 ether
            );
            nTokenValue = nTokenValue.add(nTokenLinear);
        }

        return TOKEN_BASE_RATE.sub(nTokenValue);
    }
}