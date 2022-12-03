/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./../TokenTransfer.sol";
import "../../../library/LiqiMathLib.sol";

/**
 * @dev FixedDividendsERC20 handles the payment of a fixed amount of dividends partially
 * @notice FixedDividendsERC20 administra o pagamento de uma quantidade fixa de dividendos
 */
contract FixedDividendsERC20 is TokenTransfer {
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
     * @notice A porcentagem de interesse gerado no periodo inteiro
     */
    uint256 public constant INTEREST_RATE = 37.532 * 1 ether;
    /**
     * @dev The price of the token
     * @notice Valor do token
     */
    uint256 public constant TOKEN_BASE_RATE = 2500;
    /**
     * @dev The total amount of interest payments
     * @notice Total de parcelas de pagamento de interesse
     */
    uint256 public constant TOTAL_PERIODS = 33;

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

    // Map of investor to last payment snapshot index
    mapping(address => uint256) private mapLastPaymentSnapshot;
    // Map of snapshot index to dividend date
    mapping(uint256 => uint256) private mapPaymentDate;

    /**
     * @dev Fixed Dividends
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

        // calculate the total supply of tokens with interest
        uint256 nInterestTokenSupply = LiqiMathLib.mulDiv(
            _totalTokens,
            INTEREST_RATE.add(100 ether),
            100 ether
        );

        // calculate total input token amount to payoff all dividends
        nTotalInputInterest = nInterestTokenSupply.mul(TOKEN_BASE_RATE);

        // calculate how much each payment should be
        nPaymentValue = nTotalInputInterest.div(TOTAL_PERIODS);
    }

    /**
     * @dev Owner function to pay dividends to all token holders
     * @notice Função do dono para pagar dividendos ã todos os token holders
     */
    function payDividends() public onlyOwner {
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
        if (nCurrentSnapshotId == TOTAL_PERIODS) {
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
     * @notice Retorna a data de pagamento da parcela especificada
     */
    function getLastPayment(address _aInvestor) public view returns (uint256) {
        return mapLastPaymentSnapshot[_aInvestor];
    }

    /**
     * @dev Returns the INTEREST_RATE constant
     * @notice Retorna a constante INTEREST_RATE
     */
    function getInterestRate() public pure returns (uint256) {
        return INTEREST_RATE;
    }

    /**
     * @dev Returns the minimum payment value needed to execute payDividends
     * @notice Retorna o valor necessário para invocar payDividends
     */
    function getPaymentValue() public view returns (uint256) {
        return nPaymentValue;
    }

    /**
     * @dev Gets current interest
     * @notice Retorna a porcentagem de interesse gerada até agora
     */
    function getCurrentInterest() public view returns (uint256) {
        return getPercentByTime(block.timestamp);
    }

    /**
     * @dev Gets current percent based in period
     * @notice Retorna a porcentagem de interesse gerada até a data especificada
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

    /**
     * @dev Returns the current token value
     * @notice Retorna o valor do token linear até a data especificada
     */
    function getCurrentTokenValue() public view returns (uint256) {
        return getLinearTokenValue(block.timestamp);
    }

    /**
     * @dev Gets current token value based in period
     * @notice Retorna o valor do token linear até a data especificada
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