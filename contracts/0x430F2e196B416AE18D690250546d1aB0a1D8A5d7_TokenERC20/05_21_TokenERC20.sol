//Made with Student Coin Terminal
//SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IToken} from "../interfaces/IToken.sol";

contract TokenERC20 is ERC20, AccessControl, IToken {
  // roles
  bytes32 public constant CAN_MINT_ROLE = keccak256("CAN MINT");
  bytes32 public constant CAN_BURN_ROLE = keccak256("CAN BURN");

  // basic
  uint8 private immutable _decimals;
  uint256 private immutable _cap;

  // tax
  uint8 public immutable tax;

  // sale
  address public immutable saleAddress;
  uint256 private immutable _saleSupply;

  // vesting
  address public immutable vestingAddress;
  uint256 private immutable _vestingSupply;

  // internal
  mapping(address => bool) public internalContracts;

  // errors
  error InvalidDecimals(uint8 decimals_);
  error SupplyGreaterThanCap(
    uint256 supply_,
    uint256 saleSupply_,
    uint256 vestingSupply_,
    uint256 cap_
  );
  error CapExceeded(uint256 amount_, uint256 cap_);
  error InvalidTransactionTax(uint256 percentage_);
  error InvalidAllowance(uint256 allowance_, uint256 amount_);
  error InvalidSaleConfig(address sale_, uint256 saleSupply_);
  error InvalidVestingConfig(address vesting_, uint256 vestingSupply_);

  constructor(
    string memory name_,
    string memory symbol_,
    bytes memory arguments_
  ) ERC20(name_, symbol_) {
    // tx members
    address sender = tx.origin;

    // decode
    (
      uint8 decimals_,
      uint256 cap_,
      uint256 initialSupply_,
      bool canMint_,
      bool canBurn_,
      uint8 tax_,
      address sale_,
      uint256 saleSupply_,
      address vesting_,
      uint256 vestingSupply_
    ) = abi.decode(
        arguments_,
        (uint8, uint256, uint256, bool, bool, uint8, address, uint256, address, uint256)
      );

    // verify decimals
    if (decimals_ > 18) {
      revert InvalidDecimals(decimals_);
    }

    // for uncapped use max uint256
    if (cap_ == 0) {
      cap_ = type(uint256).max;
    }

    // verify supply
    if (initialSupply_ + saleSupply_ + vestingSupply_ > cap_) {
      revert SupplyGreaterThanCap(initialSupply_, saleSupply_, vestingSupply_, cap_);
    }

    // verify transaction tax
    if (tax_ > 100) {
      revert InvalidTransactionTax(tax_);
    }

    if ((saleSupply_ > 0 && sale_ == address(0x0)) || (saleSupply_ == 0 && sale_ != address(0x0))) {
      revert InvalidSaleConfig(sale_, saleSupply_);
    }

    if (
      (vestingSupply_ > 0 && vesting_ == address(0x0)) ||
      (vestingSupply_ == 0 && vesting_ != address(0x0))
    ) {
      revert InvalidVestingConfig(vesting_, vestingSupply_);
    }

    // token
    _decimals = decimals_;
    _cap = cap_;
    tax = tax_;

    // mint supply
    if (initialSupply_ > 0) {
      _mint(sender, initialSupply_);
    }

    // setup sale
    saleAddress = sale_;
    _saleSupply = saleSupply_;
    if (sale_ != address(0x0)) {
      // internal
      internalContracts[sale_] = true;

      // mint
      _mint(sale_, saleSupply_);
    } else {
      if (saleSupply_ != 0) revert InvalidSaleConfig(sale_, saleSupply_);
    }

    // setup vesting
    vestingAddress = vesting_;
    _vestingSupply = vestingSupply_;
    if (vesting_ != address(0x0)) {
      // internal
      internalContracts[vesting_] = true;

      // mint
      _mint(vesting_, vestingSupply_);
    } else {
      if (vestingSupply_ != 0) revert InvalidVestingConfig(vesting_, vestingSupply_);
    }

    // base role setup
    _setupRole(DEFAULT_ADMIN_ROLE, sender);
    _setRoleAdmin(CAN_MINT_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(CAN_BURN_ROLE, DEFAULT_ADMIN_ROLE);

    // mint role
    if (canMint_) {
      _setupRole(CAN_MINT_ROLE, sender);
    }

    // burn role
    if (canBurn_) {
      _setupRole(CAN_BURN_ROLE, sender);
    }

    // burn for sale
    if (sale_ != address(0x0)) {
      _setupRole(CAN_BURN_ROLE, sale_);
    }
  }

  // getters
  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  function cap() public view virtual returns (uint256) {
    return _cap;
  }

  function saleSupply() external view override returns (uint256) {
    return _saleSupply;
  }

  function vestingSupply() external view override returns (uint256) {
    return _vestingSupply;
  }

  // mint & burn
  function mint(address account, uint256 amount) external onlyRole(CAN_MINT_ROLE) {
    _mint(account, amount);
  }

  function burn(uint256 amount) external override onlyRole(CAN_BURN_ROLE) {
    _burn(msg.sender, amount);
  }

  function _mint(address account, uint256 amount) internal virtual override {
    uint256 sum = ERC20.totalSupply() + amount;
    if (sum > _cap) {
      revert CapExceeded(sum, _cap);
    }
    super._mint(account, amount);
  }

  // transfer
  function _calculateTax(uint256 amount) internal view returns (uint256, uint256) {
    uint256 burned = (amount * tax) / 100;
    uint256 untaxed = amount - burned;
    return (burned, untaxed);
  }

  function isNotInternalTransfer() private view returns (bool) {
    return !internalContracts[msg.sender];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    if (tax > 0 && isNotInternalTransfer()) {
      // calculate tax
      (uint256 burned, uint256 untaxed) = _calculateTax(amount);

      // burn and transfer
      _burn(msg.sender, burned);
      return super.transfer(recipient, untaxed);
    } else {
      return super.transfer(recipient, amount);
    }
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    if (tax > 0 && isNotInternalTransfer()) {
      // calculate tax
      (uint256 burned, uint256 untaxed) = _calculateTax(amount);

      // allowance for burn
      uint256 currentAllowance = allowance(sender, _msgSender());
      if (currentAllowance < amount) {
        revert InvalidAllowance(currentAllowance, amount);
      }
      unchecked {
        _approve(sender, _msgSender(), currentAllowance - burned);
      }

      // burn and transfer
      _burn(sender, burned);
      return super.transferFrom(sender, recipient, untaxed);
    } else {
      return super.transferFrom(sender, recipient, amount);
    }
  }
}