/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./../TokenTransfer.sol";
import "../../../library/LiqiMathLib.sol";

/**
 * @dev FixedDividendsCreditERC20
 */
contract FixedDividendsCreditERC20 is TokenTransfer {
    using SafeMath for uint256;

    /**
     * @dev The price of the token
     * @notice Valor do token
     */
    uint256 public constant TOKEN_BASE_RATE = 2500;

    /**
     * @dev The amount of each interest payment
     * @notice Um array com o valor de cada pagamento de interesse
     */
    uint256[] public PERIOD_VALUES = [
        70739.99 * 100 ether,
        21586.83 * 100 ether,
        8842.62 * 100 ether,
        15972.36 * 100 ether,
        8977.41 * 100 ether,
        35744.54 * 100 ether,
        61234.10 * 100 ether,
        38005.14 * 100 ether
    ];

    /**
     * @dev The discount for each period payment
     * @notice Um array com o valor de cada desconto
     */
    uint256[] public PERIOD_DISCOUNTS = [
        100 ether - 2.7934579093017 * 1 ether,
        100 ether - 3.70716072229092 * 1 ether,
        100 ether - 5.50888174769298 * 1 ether,
        100 ether - 6.39706065718524 * 1 ether,
        100 ether - 8.14845136409965 * 1 ether,
        100 ether - 9.81030615668181 * 1 ether,
        100 ether - 11.5535358979457 * 1 ether,
        100 ether - 12.3848974638534 * 1 ether
    ];

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

    // Map of investor to last payment snapshot index
    mapping(address => uint256) private mapLastPaymentSnapshot;
    // Map of snapshot index to dividend date
    mapping(uint256 => uint256) private mapPaymentDate;

    bool private bInitialized;

    uint256[] private arrInterests;
    uint256 private nTotalInterest;

    /**
     * @dev Fixed Dividends
     */
    constructor(
        address _issuer,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _dividendsToken
    ) public TokenTransfer(_issuer, 0, _tokenName, _tokenSymbol) {
        // make sure the dividends token isnt empty
        require(_dividendsToken != address(0), "Dividends token cant be zero");

        // convert the address to an interface
        dividendsToken = IERC20(_dividendsToken);

        // get the balance of this contract to check if the interface works
        uint256 nBalance = dividendsToken.balanceOf(address(this));

        // this is never false, it's just a failsafe so that we execute balanceOf
        require(nBalance == 0, "Contract must have no balance");
    }

    function onCreate(uint256 _totalTokens) internal override {}

    /**
     * @dev
     * @notice Retorna true se a função initialize foi executada
     */
    function getInitialized() public view returns (bool) {
        return bInitialized;
    }

    /**
     * @dev
     * @notice Executada apenas 1 vez, faz a emissão dos tokens de acordo com as constantes definidas no contrato.
     */
    function initialize() public {
        require(!bInitialized, "Contract is already initialized");

        uint256 nTotalValue = 0;
        uint256 nTotalDiscountedValue = 0;

        uint256 nTotalTokens = 0;
        for (uint8 i = 0; i < PERIOD_VALUES.length; i++) {
            uint256 nPeriodValue = PERIOD_VALUES[i];
            uint256 nPeriodDiscount = PERIOD_DISCOUNTS[i];

            uint256 nDiscountedValue = LiqiMathLib.mulDiv(
                nPeriodValue,
                nPeriodDiscount,
                100 ether
            );

            nTotalValue = nTotalValue.add(nPeriodValue);
            nTotalDiscountedValue = nTotalDiscountedValue.add(nDiscountedValue);

            nTotalTokens = nTotalTokens.add(
                nDiscountedValue.div(TOKEN_BASE_RATE)
            );
        }

        _mint(aIssuer, nTotalTokens);

        // save interest for reference functions
        nTotalInterest = LiqiMathLib.mulDiv(
            nTotalValue,
            1 ether,
            nTotalDiscountedValue
        );

        for (uint8 i = 0; i < PERIOD_VALUES.length; i++) {
            uint256 nPeriodValue = PERIOD_VALUES[i];

            uint256 nInterest = LiqiMathLib.mulDiv(
                nPeriodValue,
                1 ether,
                nTotalDiscountedValue
            );
            arrInterests.push(nInterest);
        }

        bInitialized = true;
    }

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
    function getLastPayment(address _aInvestor) public view returns (uint256) {
        return mapLastPaymentSnapshot[_aInvestor];
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
     * @dev Gets the total amount of interest paid so far
     * @notice Retorna a porcentagem de interesse paga até agora
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

        // loop all dates
        for (uint8 i = 0; i < _nPaymentIndex; i++) {
            uint256 nInterest = arrInterests[i];

            uint256 nTokenInterest = LiqiMathLib.mulDiv(
                TOKEN_BASE_RATE,
                nInterest.mul(100 ether),
                100 ether
            );

            nTokenValue = nTokenValue.add(nTokenInterest);
        }

        uint256 nTokenInterest = LiqiMathLib.mulDiv(
            TOKEN_BASE_RATE,
            nTotalInterest.mul(100 ether),
            100 ether
        );

        uint256 nLinearToken = LiqiMathLib.mulDiv(
            nTokenValue,
            100 ether,
            nTokenInterest
        );

        uint256 nFinalTokenValue = LiqiMathLib.mulDiv(
            TOKEN_BASE_RATE,
            nLinearToken,
            100 ether
        );

        return TOKEN_BASE_RATE.sub(nFinalTokenValue);
    }
}