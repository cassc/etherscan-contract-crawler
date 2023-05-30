//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SHUEY is ERC20, Ownable {
    /* Token Tax */
    uint32 public _taxPercision = 100000;
    address[] public _taxRecipients;
    uint16 public _taxTotal;
    bool public _taxActive;

    mapping(address => uint16) public _taxRecipientAmounts;
    mapping(address => bool) private _isTaxRecipient;
    mapping(address => bool) public _whitelisted;

    /* Events */
    event UpdateTaxPercentage(address indexed wallet, uint16 _newTaxAmount);
    event AddTaxRecipient(address indexed wallet, uint16 _taxAmount);
    event RemoveFromWhitelist(address indexed wallet);
    event RemoveTaxRecipient(address indexed wallet);
    event AddToWhitelist(address indexed wallet);
    event ToggleTax(bool _active);

    uint256 private _totalSupply;

    /**
     * @dev Constructor.
     */
    constructor() ERC20('Shuey Rhon Inu', 'SHUEY') payable {
      _totalSupply = 44030000000 * (10**18);

      _mint(msg.sender, _totalSupply);
    }

    /**
      * @notice overrides ERC20 transferFrom function to introduce tax functionality
      * @param from address amount is coming from
      * @param to address amount is going to
      * @param amount amount being sent
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");
        if(_taxActive && !_whitelisted[from] && !_whitelisted[to]) {
          uint256 tax = amount *_taxTotal / _taxPercision;
          amount = amount - tax;
          _transfer(from, address(this), tax);
        }
        _transfer(from, to, amount);
        return true;
    }


    /**
      * @notice : overrides ERC20 transfer function to introduce tax functionality
      * @param to address amount is going to
      * @param amount amount being sent
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
      address owner = _msgSender();
      require(balanceOf(owner) >= amount, "ERC20: transfer amount exceeds balance");
      if(_taxActive && !_whitelisted[owner] && !_whitelisted[to]) {
        uint256 tax = amount*_taxTotal/_taxPercision;
        amount = amount - tax;
        _transfer(owner, address(this), tax);
      }
      _transfer(owner, to, amount);
      return true;
    }


    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of lowest token units to be burned.
     */
    function burn(uint256 value) public {
      _burn(msg.sender, value);
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
      * @notice : adds address with tax amount to taxable addresses list
      * @param wallet address to add
      * @param _tax tax amount this address receives
    */
    function addTaxRecipient(address wallet, uint16 _tax) external onlyOwner {
      require(_taxRecipients.length < 100, "Reached maximum number of tax addresses");
      require(wallet != address(0), "Cannot add 0 address");
      require(!_isTaxRecipient[wallet], "Recipient already added");
      require(_tax > 0 && _tax + _taxTotal <= _taxPercision/10, "Total tax amount must be between 0 and 10%");

      _isTaxRecipient[wallet] = true;
      _taxRecipients.push(wallet);
      _taxRecipientAmounts[wallet] = _tax;
      _taxTotal = _taxTotal + _tax;
      emit AddTaxRecipient(wallet, _tax);
    }

    /**
      * @notice : updates address tax amount
      * @param wallet address to update
      * @param newTax new tax amount
     */
    function updateTaxPercentage(address wallet, uint16 newTax) external onlyOwner {
      require(wallet != address(0), "Cannot add 0 address");
      require(_isTaxRecipient[wallet], "Not a tax address");

      uint16 currentTax = _taxRecipientAmounts[wallet];
      require(currentTax != newTax, "Tax already this amount for this address");

      if(currentTax < newTax) {
        uint16 diff = newTax - currentTax;
        require(_taxTotal + diff <= 10000, "Tax amount too high for current tax rate");
        _taxTotal = _taxTotal + diff;
      } else {
        uint16 diff = currentTax - newTax;
        _taxTotal = _taxTotal - diff;
      }
      _taxRecipientAmounts[wallet] = newTax;
      emit UpdateTaxPercentage(wallet, newTax);
    }

    /**
      * @notice : remove address from taxed list
      * @param wallet address to remove
     */
    function removeTaxRecipient(address wallet) external onlyOwner {
      require(wallet != address(0), "Cannot add 0 address");
      require(_isTaxRecipient[wallet], "Recipient has not been added");
      uint16 _tax = _taxRecipientAmounts[wallet];

      for(uint8 i = 0; i < _taxRecipients.length; i++) {
        if(_taxRecipients[i] == wallet) {
          _taxTotal = _taxTotal - _tax;
          _taxRecipientAmounts[wallet] = 0;
          _taxRecipients[i] = _taxRecipients[_taxRecipients.length - 1];
          _isTaxRecipient[wallet] = false;
          _taxRecipients.pop();
          emit RemoveTaxRecipient(wallet);

          break;
        }
      }
    }

    /**
    * @notice : add address to tax whitelist
    * @param wallet address to add to whitelist
    */
    function addToWhitelist(address wallet) external onlyOwner {
      require(wallet != address(0), "Cant use 0 address");
      require(!_whitelisted[wallet], "Address already added");
      _whitelisted[wallet] = true;

      emit AddToWhitelist(wallet);
    }

    /**
    * @notice : add address to whitelist (non taxed)
    * @param wallet address to remove from whitelist
    */
    function removeFromWhitelist(address wallet) external onlyOwner {
      require(wallet != address(0), "Cant use 0 address");
      require(_whitelisted[wallet], "Address not added");
      _whitelisted[wallet] = false;

      emit RemoveFromWhitelist(wallet);
    }

    /**
    * @notice : resets tax settings to initial state
    */
    function taxReset() external onlyOwner {
      _taxActive = false;
      _taxTotal = 0;

      for(uint8 i = 0; i < _taxRecipients.length; i++) {
        _taxRecipientAmounts[_taxRecipients[i]] = 0;
        _isTaxRecipient[_taxRecipients[i]] = false;
      }

      delete _taxRecipients;
    }

    /**
      * @notice : withdraws taxable amount to tax recipients
     */
    function distributeTaxes() external onlyOwner {
      require(balanceOf(address(this)) > 0, "Nothing to withdraw");
      uint256 taxableAmount = balanceOf(address(this));
      for(uint8 i = 0; i < _taxRecipients.length; i++) {
        address taxAddress = _taxRecipients[i];
        if(i == _taxRecipients.length - 1) {
           _transfer(address(this), taxAddress, balanceOf(address(this)));
        } else {
          uint256 amount = taxableAmount * _taxRecipientAmounts[taxAddress]/_taxTotal;
          _transfer(address(this), taxAddress, amount);
        }
      }
    }
}