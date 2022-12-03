// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AccessManager.sol";

/**
 * @dev LiqiBrlToken is Liqi's stable coin linked to the Brazilian Real. The token has 20 decimals 
 * @notice LiqiBrlToken é a stable coin da Liqi linkada ao Real Brasileiro. O token possui 20 decimais
**/
contract LiqiBRLToken is ERC20, Ownable, AccessManager {
    using SafeMath for uint256;

    /**
     * @dev Liqi Offer Token
     */
    constructor() public ERC20("Liqi BRL", "BRLT") {
        _setupDecimals(20);
    }

    /**
     * @dev Allow minting by the owner
     * @notice Minta tokens na carteira especificada.
     * Somente o owner pode invocar.
     */
    function mint(address _account, uint256 _amount) public onlyOwner {
        require(_account != address(0), "Account is empty");
        require(_amount != 0, "Amount is zero");

        _mint(_account, _amount);
    }

    /**
     * @dev Allow burning by the owner
     * @notice Queima os tokens na carteira do dono do contrato.
     * Somente o owner pode invocar.
     */
    function burn(uint256 _amount) public onlyOwner {
        require(_amount != 0, "Amount is zero");

        _burn(owner(), _amount);
    }

    /**
     * @dev Exchanges the funds of one address to another
     * @notice Troca o balanço da conta _from e _to.
     * Somente o owner pode invocar.
     */
    function exchangeBalance(address _from, address _to) public onlyOwner {
        require(_from != address(0), "From is empty");
        require(_to != address(0), "To is empty");

        // get current balance of _from address
        uint256 nAmount = balanceOf(_from);

        // dont proceed if theres nothing to exchange
        require(nAmount != 0, "Amount is zero");

        // transfer balance to new address
        _transfer(_from, _to, nAmount);
    }

    /**
     * @dev Invest mints the funds on the _investor address and transfers them to the sender address
     * @notice Invest minta a quantidade de fundos no endereço especificado, e os transfere para o endereço de chamada
     */
    function invest(address _investor, uint256 _amount)
        public
        onlyAllowedAddress
    {
        // no empty address
        require(_investor != address(0), "Investor is empty");

        // no zero amount
        require(_amount != 0, "Amount is zero");

        // mint the BRLT tokens to the investor account
        _mint(_investor, _amount);

        // transfer balance to new address
        _transfer(_investor, _msgSender(), _amount);
    }

    /**
     * @dev FailedSale is only called from failed sales
     * @notice FailedSale é chamado pelo contrato de oferta quando uma oferta é finalizada sem sucesso.
     * Esse método queima todos os tokens BRLT do endereço que invoca
     */
    function failedSale() public onlyAllowedAddress {
        // get the address of the caller
        address aSender = _msgSender();

        // get the balance of the offer
        uint256 nBalance = balanceOf(aSender);

        // burn everything
        _burn(aSender, nBalance);
    }
}