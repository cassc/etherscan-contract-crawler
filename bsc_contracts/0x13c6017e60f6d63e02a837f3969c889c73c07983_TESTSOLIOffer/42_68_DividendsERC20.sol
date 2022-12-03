/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./../TokenTransfer.sol";
import "../../../library/LiqiMathLib.sol";

/**
 * @dev DividendsERC20 handles the payment of dividends by using any IERC20 compatible token
 *
 * PAYMENT
 *  Emitter
 *  - Emitter calls increaseAllowance on the dividends token, with the amount he wants to pay in dividends to the holders
 *  - Emitter calls payDividends with the amount he wants to pay in dividends to the holders
 *
 * @notice Módulo para dividendos genérico, paga parcelas de qualquer valor utilizando um token ERC20
 *
 */
contract DividendsERC20 is TokenTransfer {
    using SafeMath for uint256;

    // Index of the current token snapshot
    uint256 private nCurrentSnapshotId;
    // Reference to the token the dividends are paid in
    IERC20 private dividendsToken;

    // Map of investor to last payment snapshot index
    mapping(address => uint256) private mapLastPaymentSnapshot;
    // Map of snapshot index to dividend total amount
    mapping(uint256 => uint256) private mapERCPayment;
    // Map of snapshot index to dividend date
    mapping(uint256 => uint256) private mapPaymentDate;

    /**
     * @dev Constructor for DividendsERC20
     * @notice Construtor para DividendosERC20
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
    }

    /**
     * @dev Gets the address of the token used for dividends
     * @notice Retorna o endereço do token de pagamento de dividendos
     */
    function getDividendsToken() public view returns (address) {
        return address(dividendsToken);
    }

    /**
     * @dev Gets the total count of payments
     * @notice Retorna o total de pagamentos de dividendos feitos à este contrato
     */
    function getTotalDividendPayments() public view returns (uint256) {
        return nCurrentSnapshotId;
    }

    /**
     * @dev Gets payment data for the specified index
     * @notice Retorna dados sobre o pagamento no índice especificado.
     * nERCPayment: Valor pago no token ERC20 de dividendos.
     * nDate: Data em formato unix do pagamento desse dividendo
     */
    function getPayment(uint256 _nIndex)
        public
        view
        returns (uint256 nERCPayment, uint256 nDate)
    {
        nERCPayment = mapERCPayment[_nIndex];
        nDate = mapPaymentDate[_nIndex];
    }

    /**
     * @dev Gets the last payment cashed out by the specified _investor
     * @notice Retorna o ID do último saque feito para essa carteira
     */
    function getLastPayment(address _aInvestor) public view returns (uint256) {
        return mapLastPaymentSnapshot[_aInvestor];
    }

    /**
     * @dev Function made for owner to transfer tokens to contract for dividend payment
     * @notice Faz um pagamento de dividendos ao contrato, no valor especificado
     */
    function payDividends(uint256 _amount) public onlyOwner {
        // make sure the amount is not zero
        require(_amount > 0, "Amount cant be zero");

        // grab our current allowance
        uint256 nAllowance = dividendsToken.allowance(
            _msgSender(),
            address(this)
        );

        // make sure we at least have the balance added
        require(_amount <= nAllowance, "Not enough balance to pay dividends");

        // transfer the tokens from the sender to the contract
        dividendsToken.transferFrom(_msgSender(), address(this), _amount);

        // snapshot the tokens at the moment the ether enters
        nCurrentSnapshotId = _snapshot();

        // register the balance in ether that entered
        mapERCPayment[nCurrentSnapshotId] = _amount;

        // save the date
        mapPaymentDate[nCurrentSnapshotId] = block.timestamp;
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
     * @dev Withdraws only 1 dividend for the specified user
     * @notice Saca apenas 1 dividendo para o endereço especificado
     */
    function withdrawDividendAny(address _investor) public {
        require(_withdrawDividends(_investor), "No new withdrawal");
    }

    function _recursiveGetTotalDividends(
        address _aInvestor,
        uint256 _nPaymentIndex
    ) internal view returns (uint256) {
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
            uint256 nTokenSupply = totalSupplyAt(_nPaymentIndex);

            // get the total token amount for this payment
            uint256 nTotalTokens = mapERCPayment[_nPaymentIndex];

            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive = LiqiMathLib.mulDiv(
                nTokenBalance,
                nTotalTokens,
                nTokenSupply
            );

            return nToReceive;
        }
    }

    /**
     * @dev Gets the total amount of available dividends
     * to be cashed out for the specified _investor
     * @notice Retorna o total de dividendos que esse endereço pode sacar
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
            nBalance = nBalance.add(_recursiveGetTotalDividends(_investor, i));
        }

        return nBalance;
    }

    /**
     * @dev Based on how many tokens the user had at the snapshot,
     * pay dividends of the ERC20 token
     * Be aware that this function will pay dividends
     * even if the tokens are currently in possession of the offer
     */
    function _withdrawDividends(address _sender) private returns (bool) {
        // read the last payment
        uint256 nLastPayment = mapLastPaymentSnapshot[_sender];

        // make sure we have a next payment
        if (nLastPayment >= nCurrentSnapshotId) {
            return false;
        }

        // add 1 to get the next payment
        uint256 nNextUserPayment = nLastPayment.add(1);

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

            // get the total token amount for this payment
            uint256 nTotalTokens = mapERCPayment[nNextUserPayment];

            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive = LiqiMathLib.mulDiv(
                nTokenBalance,
                nTotalTokens,
                nTokenSupply
            );

            // send the ERC20 value to the user
            dividendsToken.transfer(_sender, nToReceive);
        }

        return true;
    }
}