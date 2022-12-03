// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "../../base/BaseOfferToken.sol";
import "../../base/IOffer_v2.sol";

/**
 * @dev TokenTransfer has most of the implementations
 * needed to interact with offer contracts automatically
 * @notice Contrato base para todos os tokens ofertáveis ERC20.
 * Possui várias implementações para se conectar direto com ofertas Liqi.
 */
contract TokenTransfer is BaseOfferToken {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // A map of the offer index to the start date
    mapping(uint256 => uint256) internal mapOfferStartDate;
    // A map of the offer index to the offer object
    mapping(uint256 => IOffer) internal mapOffers;
    // A map of the investor to the last cashout he did
    mapping(address => uint256) internal mapLastCashout;

    // An internal counter to keep track of the offers
    Counters.Counter internal counterTotalOffers;

    // Address of the issuer
    address internal aIssuer;

    /**
     * @dev Constructor for TokenTransfer
     * @notice Constructor para o token base Token Transfer
     */
    constructor(
        address _issuer,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public BaseOfferToken(_tokenName, _tokenSymbol) {
        // make sure the issuer is not empty
        require(_issuer != address(0));

        // save address of the issuer
        aIssuer = _issuer;

        // call onCreate so inheriting contracts can override base mint functionality
        onCreate(_totalTokens);
    }

    function onCreate(uint256 _totalTokens) internal virtual {
        // make sure were not starting with 0 tokens
        require(_totalTokens != 0, "Tokens to be minted is 0");

        // mints all tokens to issuer
        _mint(aIssuer, _totalTokens);
    }

    /**
     * @dev Registers a offer on the token
     * @notice Método para iniciar uma oferta de venda de token Liqi (parte do sistema interno de deployment)
     */
    function startOffer(address _aTokenOffer)
        public
        onlyOwner
        returns (uint256)
    {
        // make sure the address isn't empty
        require(_aTokenOffer != address(0), "Offer cant be empty");

        // convert the offer to a interface
        IOffer objOffer = IOffer(_aTokenOffer);

        // make sure the offer is intiialized
        require(!objOffer.getInitialized(), "Offer should not be initialized");

        // gets the index of the last offer, if it exists
        uint256 nLastId = counterTotalOffers.current();

        // check if its the first offer
        if (nLastId != 0) {
            // get a reference to the last offer
            IOffer objLastOFfer = IOffer(mapOffers[nLastId]);

            // make sure the last offer is finished
            require(objLastOFfer.getFinished(), "Offer should be finished");
        }

        // increment the total of offers
        counterTotalOffers.increment();

        // gets the current offer index
        uint256 nCurrentId = counterTotalOffers.current();

        // save the address of the offer
        mapOffers[nCurrentId] = objOffer;

        // save the date the offer should be considered for dividends
        mapOfferStartDate[nCurrentId] = block.timestamp;

        // initialize the offer
        objOffer.initialize();

        return nCurrentId;
    }

    /**
     * @dev Try to cashout up to 5 times
     * @notice Faz o cashout de até 6 compras de tokens na(s) oferta(s), para a carteira especificada
     */
    function cashoutFrozenMultipleAny(address aSender) public {
        bool bHasCashout = cashoutFrozenAny(aSender);
        require(bHasCashout, "No cashouts available");

        for (uint256 i = 0; i < 5; i++) {
            if (!cashoutFrozenAny(aSender)) {
                return;
            }
        }
    }

    /**
     * @dev Main cashout function, cashouts up to 16 times
     * @notice Faz o cashout de até 6 compras de tokens na(s) oferta(s), para a carteira que chama essa função
     */
    function cashoutFrozen() public {
        // cache the sender
        address aSender = _msgSender();

        // try to do 10 cashouts
        cashoutFrozenMultipleAny(aSender);
    }

    /**
     * @return true if it changed the state
     * @notice Faz o cashout de apenas 1 compra para o endereço especificado.
     * Retorna true se mudar o estado do contrato.
     */
    function cashoutFrozenAny(address _account) public virtual returns (bool) {
        // get the latest token sale that was cashed out
        uint256 nCurSnapshotId = counterTotalOffers.current();

        // get the last token sale that this user cashed out
        uint256 nLastCashout = mapLastCashout[_account];

        // return if its the latest offer
        if (nCurSnapshotId <= nLastCashout) {
            return false;
        }

        // add 1 to get the next payment index
        uint256 nNextCashoutIndex = nLastCashout.add(1);

        // get the address of the offer this user is cashing out
        IOffer offer = mapOffers[nNextCashoutIndex];

        // cashout the tokens, if the offer allows
        bool bOfferCashout = offer.cashoutTokens(_account);

        // check if the sale is finished
        if (offer.getFinished()) {
            // save that it was cashed out, if the offer is over
            mapLastCashout[_account] = nNextCashoutIndex;

            return true;
        }

        return bOfferCashout;
    }

    /**
     * @dev Returns the total amount of tokens the
     * caller has in offers, up to _nPaymentDate
     * @notice Calcula quantos tokens o endereço tem dentro de ofertas com sucesso (possíveis de saque) até a data de pagamento especificada
     */
    function getTotalInOffers(uint256 _nPaymentDate, address _aInvestor)
        public
        view
        returns (uint256)
    {
        // start the final balance as 0
        uint256 nBalance = 0;

        // get the latest offer index
        uint256 nCurrent = counterTotalOffers.current();

        for (uint256 i = 1; i <= nCurrent; i++) {
            // get offer start date
            uint256 nOfferDate = getOfferDate(i);

            // break if the offer started after the payment date
            if (nOfferDate >= _nPaymentDate) {
                break;
            }

            // grab the offer from the map
            IOffer objOffer = mapOffers[i];

            // only get if offer is finished
            if (!objOffer.getFinished()) {
                break;
            }

            if (!objOffer.getSuccess()) {
                continue;
            }

            // get the total amount the user bought at the offer
            uint256 nAddBalance = objOffer.getTotalBoughtDate(
                _aInvestor,
                _nPaymentDate
            );

            // get the total amount the user cashed out at the offer
            uint256 nRmvBalance = objOffer.getTotalCashedOutDate(
                _aInvestor,
                _nPaymentDate
            );

            // add the bought and remove the cashed out
            nBalance = nBalance.add(nAddBalance).sub(nRmvBalance);
        }

        return nBalance;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(to != address(this), "Sending to contract address");

        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Get the date the offer of the _index started
     * @notice Retorna a data de inicio da oferta especificada
     */
    function getOfferDate(uint256 _index) public view returns (uint256) {
        return mapOfferStartDate[_index];
    }

    /**
     * @dev Get the address of the _index offer
     * @notice Retorna o endereço da oferta especificada
     */
    function getOfferAddress(uint256 _index) public view returns (address) {
        return address(mapOffers[_index]);
    }

    /**
     * @dev Get the index of the last cashout for the _account
     * @notice Retorna o índice da ultima oferta que o endereço especificado fez o cashout
     */
    function getLastCashout(address _account) public view returns (uint256) {
        return mapLastCashout[_account];
    }

    /**
     * @dev Get the total amount of offers registered
     * @notice Retorna o total de ofertas que foram linkadas a esse token
     */
    function getTotalOffers() public view returns (uint256) {
        return counterTotalOffers.current();
    }

    /**
     * @dev Gets the address of the issuer
     * @notice Retorna o endereço da carteira do emissor
     */
    function getIssuer() public view returns (address) {
        return aIssuer;
    }
}