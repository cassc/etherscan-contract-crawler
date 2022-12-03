/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./../TokenTransfer.sol";
import "../../../library/BokkyPooBahsDateTimeLibrary.sol";
import "../../../library/LiqiMathLib.sol";

/**
 * @dev DividendsFixedAmortizationERC20
 * @notice Modelo de amortização fixa.
 */
contract DividendsFixedAmortizationERC20 is TokenTransfer {
    using SafeMath for uint256;

    /**
     * @dev The price of the token
     * @notice O valor base de venda do token
     */
    uint256 public constant TOKEN_BASE_RATE = 2500;

    /**
     * @dev The value of amortization for each period
     * @notice Valor amortizado em cada parcela, em %
     */
    uint256[] public PERIOD_AMORTIZATIONS = [
        0.00000000000000000 * 1 ether,
        0.00000000000000000 * 1 ether,
        0.00000000000000000 * 1 ether,
        0.00000000000000000 * 1 ether,
        0.00000000000000000 * 1 ether,
        0.00000000000000000 * 1 ether,
        0.23895378866673800 * 1 ether,
        0.24161830905694500 * 1 ether,
        0.24431906644393600 * 1 ether,
        0.24705670087784600 * 1 ether,
        0.24983186718019700 * 1 ether,
        0.25264523537307000 * 1 ether,
        0.25549749112333000 * 1 ether,
        0.25838933620255700 * 1 ether,
        0.26132148896331000 * 1 ether,
        0.26429468483242600 * 1 ether,
        0.26730967682204400 * 1 ether,
        0.27036723605913200 * 1 ether,
        1.05635384154210000 * 1 ether,
        1.07695714141704000 * 1 ether,
        1.09819097069802000 * 1 ether,
        1.12008388283328000 * 1 ether,
        1.14266618031847000 * 1 ether,
        1.16597005072170000 * 1 ether,
        1.19002971560380000 * 1 ether,
        1.21488159378298000 * 1 ether,
        1.24056448058198000 * 1 ether,
        1.26711974491363000 * 1 ether,
        1.29459154631054000 * 1 ether,
        1.32302707429418000 * 1 ether,
        2.25549352484844000 * 1 ether,
        2.32769536284686000 * 1 ether,
        2.40398426668549000 * 1 ether,
        2.48471423202313000 * 1 ether,
        2.57028134806588000 * 1 ether,
        2.66113024601454000 * 1 ether,
        2.75776177041047000 * 1 ether,
        2.86074215277641000 * 1 ether,
        2.97071404236315000 * 1 ether,
        3.08840984792722000 * 1 ether,
        3.21466797585396000 * 1 ether,
        3.35045272572048000 * 1 ether,
        4.75815971467191000 * 1 ether,
        5.03950815392482000 * 1 ether,
        5.35330652979335000 * 1 ether,
        5.70549830105151000 * 1 ether,
        6.10357275087688000 * 1 ether,
        6.55710250124111000 * 1 ether,
        7.07852207636936000 * 1 ether,
        7.68428381804897000 * 1 ether,
        8.39662327999144000 * 1 ether,
        9.24634514262560000 * 1 ether,
        10.27739128132860000 * 1 ether,
        11.55467977111910000 * 1 ether,
        16.32541211388320000 * 1 ether,
        19.68101471872620000 * 1 ether,
        24.71759362846210000 * 1 ether,
        33.11994524464220000 * 1 ether,
        49.95395807617220000 * 1 ether,
        100.00000000000000000 * 1 ether
    ];

    /**
     * @dev The daily discount rate, in %
     * @notice Valor de juros mensal, em %
     */
    uint256 public constant MONTHLY_INTEREST_RATE = 0.8734593823552 * 1 ether;

    // Index of the last token snapshot
    uint256 private nCurrentSnapshotId;
    // Reference to the token the dividends are paid in
    IERC20 private dividendsToken;
    // A flag marking if the payment was completed
    bool private bCompletedPayment;
    // Total amount of input tokens paid to holders
    uint256 private nTotalDividendsPaid;
    // Total amount of input tokens worth of total supply
    uint256 private nTotalInput;

    uint256 private nTotalPayment;

    // Map of investor to last payment snapshot index
    mapping(address => uint256) private mapLastUserPayment;
    // Map of snapshot index to dividend date
    mapping(uint256 => uint256) private mapPaymentDate;
    // Map of snapshot index to dividend value
    mapping(uint256 => uint256) private mapPaymentValue;

    // Total amount of interest
    uint256 private nTotalInterest;

    // Array with interest for each payment index
    uint256[] private arrInterests;

    // State of contract initialization
    bool private bInitialized;

    /**
     * @dev DividendsFixedAmortizationERC20
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

        // calculate total input token amount to payoff all dividends
        nTotalInput = _totalTokens.mul(TOKEN_BASE_RATE);
    }

    /**
     * @dev
     * @notice Executada até o contrato ser inicializado,
     * faz a emissão dos tokens de acordo com as constantes definidas no contrato e
     * calcula os dados a serem utilizados por funcões de referência
     */
    function initialize() public {
        require(!bInitialized, "Contract is already initialized");
        bInitialized = true;

        uint256 nCurrentTotalDebit = nTotalInput;

        for (uint256 i = 0; i < PERIOD_AMORTIZATIONS.length; i++) {
            uint256 nLastDebt = nCurrentTotalDebit;

            uint256 nInterest = LiqiMathLib.mulDiv(
                MONTHLY_INTEREST_RATE,
                nCurrentTotalDebit,
                100 ether
            );

            uint256 nAmortizationPc = PERIOD_AMORTIZATIONS[i];

            // calculate how much the user needs to pay from percentage
            if (nAmortizationPc == 0) {
                mapPaymentValue[i] = 0;

                nCurrentTotalDebit = nCurrentTotalDebit.add(nInterest);
            } else {
                uint256 nAmortizationValue = LiqiMathLib.mulDiv(
                    nAmortizationPc,
                    nLastDebt,
                    100 ether
                );

                // remove amortization from total debit
                nCurrentTotalDebit = nCurrentTotalDebit.sub(nAmortizationValue);

                // add interest to payment
                uint256 nPaymentValue = nAmortizationValue.add(nInterest);
                nTotalPayment = nTotalPayment.add(nPaymentValue);

                mapPaymentValue[i] = nPaymentValue;
            }
        }

        uint256 nTotalInterestPC = LiqiMathLib.mulDiv(
            nTotalPayment,
            100 ether,
            nTotalInput
        );
        nTotalInterestPC = nTotalInterestPC.sub(100 ether);

        // save interest values
        for (uint256 i = 0; i < PERIOD_AMORTIZATIONS.length; i++) {
            uint256 nPaymentValue = mapPaymentValue[i];

            uint256 nTotalPeriodInterest = LiqiMathLib.mulDiv(
                nPaymentValue,
                100 ether,
                nTotalPayment
            );

            uint256 nPeriodInterest = LiqiMathLib.mulDiv(
                nTotalPeriodInterest,
                nTotalInterestPC,
                100 ether
            );

            arrInterests.push(nPeriodInterest);
            nTotalInterest = nTotalInterest.add(nPeriodInterest);
        }
    }

    /**
     * @dev Owner function to pay dividends to all token holders
     * @notice Função do dono para pagar dividendos ã todos os token holders
     */
    function payDividends() public onlyOwner {
        require(bInitialized, "Contract isn't initialized");
        require(!bCompletedPayment, "Dividends payment is already completed");

        uint256 nPaymentValue = mapPaymentValue[nCurrentSnapshotId];

        // calculate how much the user needs to pay from percentage
        if (nPaymentValue != 0) {
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
            dividendsToken.transferFrom(
                _msgSender(),
                address(this),
                nPaymentValue
            );
        }

        // snapshot the tokens at the moment the ether enters
        nCurrentSnapshotId = _snapshot();

        // check if we have paid everything
        if (nCurrentSnapshotId == PERIOD_AMORTIZATIONS.length) {
            bCompletedPayment = true;
        }

        // save the date
        mapPaymentDate[nCurrentSnapshotId] = block.timestamp;
    }

    /**
     * @dev Invokes the payDividends function multiple times
     * @notice Invoca a função payDividends count vezes
     */
    function payDividendsMultiple(uint256 _count) public onlyOwner {
        for (uint256 i = 0; i < _count; i++) {
            payDividends();
        }
    }

    /**
     * @dev Withdraws dividends (up to 16 times in the same call, if available)
     * @notice Faz o saque de até 16 dividendos para a carteira que chama essa função
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
     * @dev Withdraws one single dividend, if available
     * @notice Faz o saque de apenas 1 dividendo para a carteira que chama essa função
     * (se tiver disponivel)
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
     * @dev Withdraws one single dividend, if available
     * @notice Faz o saque de apenas 1 dividendo para a carteira que chama essa função
     * (se tiver disponivel)
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

        return mapPaymentValue[nCurrentSnapshotId];
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
            uint256 nPaymentValue = mapPaymentValue[_nPaymentIndex - 1];

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
        uint256 nLastPayment = mapLastUserPayment[_investor];

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
        uint256 nLastUserPayment = mapLastUserPayment[_sender];

        // make sure we have a next payment
        if (nLastUserPayment >= nCurrentSnapshotId) {
            return false;
        }

        // add 1 to get the next payment
        uint256 nNextUserPayment = nLastUserPayment.add(1);

        // save back that we have paid this user
        mapLastUserPayment[_sender] = nNextUserPayment;

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
            uint256 nPaymentValue = mapPaymentValue[nLastUserPayment];

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
     * @dev Gets the amortization percentage for the specified period
     * @notice Retorna a porcentagem de amortização do período especificado
     */
    function getAmortizationValue(uint256 _nPaymentIndex)
        public
        view
        returns (uint256)
    {
        return PERIOD_AMORTIZATIONS[_nPaymentIndex];
    }

    /**
     * @dev Gets the MONTHLY_INTEREST_RATE constant value
     * @notice Retorna o valor da constante MONTHLY_INTEREST_RATE
     */
    function getMonthlyInterestRate() public pure returns (uint256) {
        return MONTHLY_INTEREST_RATE;
    }

    /**
     * @dev Gets the TOKEN_BASE_RATE constant value
     * @notice Retorna o valor da constante TOKEN_BASE_RATE (valor base do token)
     */
    function getTokenBaseRate() public pure returns (uint256) {
        return TOKEN_BASE_RATE;
    }

    /**
     * @dev Gets total interest based on all payments
     * @notice Retorna a porcentagem de interesse de todos os pagamentos
     */
    function getTotalInterest() public view returns (uint256) {
        return nTotalInterest;
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

        // loop all payment interests
        uint256 nLast = Math.min(_nPaymentIndex, PERIOD_AMORTIZATIONS.length);
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
        } else if (_nPaymentIndex >= PERIOD_AMORTIZATIONS.length) {
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
        return nTotalPayment;
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
    function getLastPayment(address _aInvestor) public view returns (uint256) {
        return mapLastUserPayment[_aInvestor];
    }

    /**
     * @dev
     * @notice Retorna true se a função initialize foi executada todas as vezes necessárias
     */
    function getInitialized() public view returns (bool) {
        return bInitialized;
    }
}