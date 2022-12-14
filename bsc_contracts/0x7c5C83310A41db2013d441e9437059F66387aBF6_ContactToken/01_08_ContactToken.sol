// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract ContactToken is ERC20, ERC20Burnable, Pausable, Ownable {
  struct AddressDistribution {
    address wallet;
    uint32 perThousand;
  }

  // Blacklist
  mapping(address => bool) blacklist;

  // Tax
  bool public taxEnabled = true;
  uint256 public taxFee; // min 0‰, max 1000‰
  address[] taxReceivers;
  mapping(address => uint256) taxReceiversPerThousand;

  mapping(address => bool) taxWhitelistedAddresses;

  // Constructor
  constructor(AddressDistribution[] memory mintArray, AddressDistribution[] memory taxesArray) ERC20('ContactToken', 'CTT') {
    // Mint
    uint256 totalSupply = 110000000 * 10**decimals();
    for (uint256 i = 0; i < mintArray.length; i++) {
      AddressDistribution memory element = mintArray[i];
      _mint(element.wallet, ((totalSupply * element.perThousand) / 1000));
    }

    // Set tax receivers
    for (uint256 i = 0; i < taxesArray.length; i++) {
      AddressDistribution memory element = taxesArray[i];
      setTaxReceiver(element.wallet, element.perThousand);
    }
  }

  // Pause
  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }

  // Burn
  function burn(uint256 amount) public override onlyOwner {
    _burn(msg.sender, amount);
  }

  // Blacklist
  function isBlacklisted(address account) public view returns (bool) {
    return blacklist[account];
  }

  function addToBlacklist(address account) public onlyOwner {
    require(!blacklist[account], 'ContactToken: Account is already blacklisted');
    blacklist[account] = true;
  }

  function removeFromBlacklist(address account) public onlyOwner {
    require(blacklist[account], 'ContactToken: Account is not blacklisted');
    blacklist[account] = false;
  }

  // Tax global
  function enableTax() public onlyOwner {
    require(!taxEnabled, 'ContactToken: Tax is already enabled');
    taxEnabled = true;
  }

  function disableTax() public onlyOwner {
    require(taxEnabled, 'ContactToken: Tax is already disabled');
    taxEnabled = false;
  }

  // Tax receivers
  function isTaxReceiver(address account) public view returns (bool) {
    return taxReceiversPerThousand[account] > 0;
  }

  function taxReceiverFee(address account) public view returns (uint256) {
    return taxReceiversPerThousand[account];
  }

  function setTaxReceiver(address account, uint32 _taxPerThousand) public onlyOwner {
    require(_taxPerThousand > 0, 'ContactToken: Tax perThousand must be greater than 0');
    require(_taxPerThousand <= 1000, 'ContactToken: Tax perThousand must be equal to or lower than 1000');

    bool isExistent = isTaxReceiver(account);
    uint256 currentAddressTaxPerThousand = taxReceiversPerThousand[account];

    // Update cumulative tax perThousand
    uint256 newTaxReceiversPerThousandTotal = taxFee + _taxPerThousand - currentAddressTaxPerThousand;
    require(newTaxReceiversPerThousandTotal <= 1000, 'ContactToken: Taxes perThousand sum must be equal or lower than 1000');
    taxFee = newTaxReceiversPerThousandTotal;

    // Push to list if new wallet
    if (!isExistent) {
      taxReceivers.push(account);
    }

    // Update wallet perThousand
    taxReceiversPerThousand[account] = _taxPerThousand;
  }

  function removeTaxReceiver(address account) public onlyOwner {
    require(isTaxReceiver(account), 'ContactToken: Wallet not present');

    // Find index to remove
    uint256 arrayLength = taxReceivers.length;
    uint256 indexToBeDeleted;
    for (uint256 i = 0; i < arrayLength; i++) {
      if (taxReceivers[i] == account) {
        indexToBeDeleted = i;
        break;
      }
    }
    // if index to be deleted is not the last index, swap position.
    if (indexToBeDeleted < arrayLength - 1) {
      taxReceivers[indexToBeDeleted] = taxReceivers[arrayLength - 1];
    }

    // Decrease tax total
    taxFee -= taxReceiversPerThousand[account];

    // Remove from mapping
    delete taxReceiversPerThousand[account];
  }

  // Tax whitelist
  function isTaxWhitelisted(address account) public view returns (bool) {
    return taxWhitelistedAddresses[account];
  }

  function addToTaxWhitelist(address account) public onlyOwner {
    require(!taxWhitelistedAddresses[account], 'ContactToken: Address already exists');
    taxWhitelistedAddresses[account] = true;
  }

  function removeFromTaxWhitelist(address account) public onlyOwner {
    require(taxWhitelistedAddresses[account], 'ContactToken: Address not present');
    delete taxWhitelistedAddresses[account];
  }

  // Transfer fees
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override whenNotPaused {
    require(!paused(), 'ContactToken: Token transfer while paused');
    require(!isBlacklisted(msg.sender), 'ContactToken: Sender blacklisted');
    require(!isBlacklisted(recipient), 'ContactToken: Recipient blacklisted');
    require(!isBlacklisted(tx.origin), 'ContactToken: Sender blacklisted');

    uint256 netAmount;
    if (taxEnabled) {
      netAmount = handleTax(sender, recipient, amount);
    } else {
      netAmount = amount;
    }

    super._transfer(sender, recipient, netAmount);
  }

  function handleTax(
    address from,
    address to,
    uint256 amount
  ) private returns (uint256) {
    if (!taxEnabled) {
      return amount;
    }

    // If address is whitelisted avoid tax fee
    if (taxWhitelistedAddresses[from] == true || taxWhitelistedAddresses[to] == true) {
      return amount;
    }

    // No total taxes perThousand
    if (taxFee == 0) {
      return amount;
    }

    // Divide directly amount by denominator instead of dividing multiple time taxesFees
    uint256 baseUnit = amount / 1000;
    uint256 cumulativeTax;

    // Transfer tax
    for (uint256 i = 0; i < taxReceivers.length; i++) {
      address wallet = taxReceivers[i];
      uint256 partialTax = baseUnit * taxReceiversPerThousand[wallet];
      cumulativeTax += partialTax;
      super._transfer(from, wallet, partialTax);
    }

    // Return amount less distributed tax amount
    return amount - cumulativeTax;
  }
}