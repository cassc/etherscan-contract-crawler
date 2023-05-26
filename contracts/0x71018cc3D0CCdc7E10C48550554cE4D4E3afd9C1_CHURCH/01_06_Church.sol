//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CHURCH is ERC20, Ownable {
    /* Token Tax */
    uint16 public _taxTotal = 77; // Initial tax amount
    uint32 public _taxPercision = 10000;
    bool public _taxActive = true;

    mapping(string => mapping(address => bool)) public _whitelists;

    /* Events */
    event UpdateTaxPercentage(uint16 _newTaxAmount);
    event RemoveFromWhitelist(string list, address indexed wallet);
    event AddToWhitelist(string list, address indexed wallet);
    event ToggleTax(bool _active);

    uint256 private _totalSupply;

    constructor() ERC20('Church DAO', 'CHURCH') payable {
      _totalSupply = 777777777777777777777777777777777;

      addToWhitelist('from', address(this));
      addToWhitelist('to', address(this));
      addToWhitelist('from', msg.sender);

      _mint(msg.sender, _totalSupply);
    }

    /**
      * @notice overrides ERC20 transferFrom function to add tax
      * @param from address amount is coming from
      * @param to address amount is going to
      * @param amount amount being sent
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
      address spender = _msgSender();
      _spendAllowance(from, spender, amount);
      require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");
      if(_taxActive && !_whitelists['from'][from] && !_whitelists['to'][to]) {
        uint256 tax = amount *_taxTotal / _taxPercision;
        amount = amount - tax;
        _transfer(from, address(this), tax);
      }
      _transfer(from, to, amount);
      return true;
    }


    /**
      * @notice overrides ERC20 transferFrom function to add tax
      * @param to address amount is going to
      * @param amount amount being sent
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
      address owner = _msgSender();
      require(balanceOf(owner) >= amount, "ERC20: transfer amount exceeds balance");
      if(_taxActive && !_whitelists['from'][owner] && !_whitelists['to'][to]) {
        uint256 tax = amount*_taxTotal/_taxPercision;
        amount = amount - tax;
        _transfer(owner, address(this), tax);
      }
      _transfer(owner, to, amount);
      return true;
    }

    /* ADMIN Functions */

    /**
       * @notice : toggles the tax on or off
    */
    function toggleTax() external onlyOwner {
      _taxActive = !_taxActive;
      emit ToggleTax(_taxActive);
    }

    /**
      * @notice : updates address tax amount
      * @param newTax new tax amount
     */
    function setTax(uint16 newTax) external onlyOwner {
      require(newTax <= 4 * _taxPercision / 100, 'Tax can not be set to more than 4%');

      _taxTotal = newTax;
      emit UpdateTaxPercentage(newTax);
    }

    /**
    * @notice : add address to tax whitelist
    * @param list indicates which whitelist ('to' or 'from')
    * @param wallet address to add to whitelist
    */
    function addToWhitelist(string memory list, address wallet) public onlyOwner {
      require(wallet != address(0), "Cant use 0 address");
      require(!_whitelists[list][wallet], "Address already added");
      _whitelists[list][wallet] = true;

      emit AddToWhitelist(list, wallet);
    }

    /**
    * @notice : remoe address from a whitelist
    * @param list indicates which whitelist ('to' or 'from')
    * @param wallet address to remove from whitelist
    */
    function removeFromWhitelist(string memory list, address wallet) external onlyOwner {
      require(wallet != address(0), "Cant use 0 address");
      require(_whitelists[list][wallet], "Address not added");
      _whitelists[list][wallet] = false;

      emit RemoveFromWhitelist(list, wallet);
    }

    /**
      * @notice : withdraws taxes to the contract owner
     */
    function withdrawTaxes() external onlyOwner {
      uint256 amount = balanceOf(address(this));
      require(amount > 0, "Nothing to withdraw");
      _transfer(address(this), msg.sender, amount);
    }
}