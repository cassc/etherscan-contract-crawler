// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "./oz/access/Ownable.sol";
import {IERC20, ERC20, ERC20Permit, ERC20Votes} from "./oz/token/ERC20/extensions/ERC20Votes.sol";
import {IERC165} from "./oz/utils/introspection/IERC165.sol";
import {SafeERC20} from "./oz/token/ERC20/utils/SafeERC20.sol";

import {OFTV2} from "./lz/token/oft/v2/OFTV2.sol";

import {IBuyTaxReceiver} from "./interfaces/IBuyTaxReceiver.sol";
import {IAntiMevStrategy} from "./interfaces/IAntiMevStrategy.sol";

contract BenCoinV2 is OFTV2, ERC20Votes {
  using SafeERC20 for IERC20;

  event SetTax(uint buyTax, uint sellTax, bool isTaxing);
  event SetBuyTaxReceiver(address buyTaxReceiver);
  event SetTaxableContract(address taxableContract, bool isTaxable);
  event SetTaxWhitelist(address whitelist, bool isWhitelisted);
  event SetIsAntiMEV(bool isAntiMEV);
  event SetMEVWhitelist(address whitelist, bool isWhitelisted);
  event SetIsTransferBlacklisting(bool isBlacklisting);
  event SetTransferBlacklist(address blacklist, bool isBlacklisted);

  error OnlyMigrator();
  error MaxTaxExceeded();
  error BothAddressesAreContracts();
  error TransferBlacklisted(address);
  error InvalidBuyTaxReceiver();
  error InvalidArrayLength();
  error AlreadyInitialized();

  address private migrator; // Only used on Ethereum for the initial migration from BenV1 to BenV2
  uint16 private buyTax;
  uint16 private sellTax;
  bool private isTaxingEnabled;
  bool private isAntiMEV;
  bool private isBlacklisting;
  bool private isInitialized;
  uint8 private taxFlag = NOT_TAXING;
  address private buyTaxReceiver;
  // Using 1 & 2 instead of 0 to save gas when resetting
  uint96 private minimumBenToSwapReached;
  mapping(address contractAddress => bool isTaxable) private taxableContracts;
  mapping(address whitelist => bool isWhitelisted) private taxWhitelist; // For certain addresses to be exempt from tax like exchanges

  mapping(address whitelist => bool isWhitelisted) private MEVWhitelist; // For certain addresses to be exempt from MEV like exchanges
  mapping(address blacklist => bool isBlacklisted) private transferBlacklist;
  IAntiMevStrategy private antiMEVStrategy;

  uint256 private constant MAX_TAX = 10; // 10%
  uint8 private constant NOT_TAXING = 1;
  uint8 private constant TAXING = 2;
  uint256 private constant FEE_DENOMINATOR = 10000;
  uint8 private constant SHARED_DECIMALS = 8;

  constructor() OFTV2("BEN TEST", "BENTEST", SHARED_DECIMALS) ERC20Permit("BEN TEST") {
    _setTax(100, 300, true); // 1% buy, 3% sell
    _setIsAntiMEV(true);
    _setIsTransferBlacklisting(true);
  }

  function initialize(
    address _lzEndpoint,
    address _buyTaxReceiver,
    address _antiMEVStrategy,
    address _migrator
  ) external notInitialized onlyOwner {
    __OFTV2_init(_lzEndpoint);
    _setBuyTaxReceiver(_buyTaxReceiver);
    antiMEVStrategy = IAntiMevStrategy(_antiMEVStrategy);
    migrator = _migrator;
    isInitialized = true;
  }

  modifier notInitialized() {
    if (isInitialized) {
      revert AlreadyInitialized();
    }
    _;
  }

  modifier antiMEV(
    address _from,
    address _to,
    uint256 _amount
  ) {
    if (isAntiMEV) {
      bool fromIsWhitelisted = MEVWhitelist[_from];
      bool toIsWhitelisted = MEVWhitelist[_to];
      antiMEVStrategy.onTransfer(_from, _to, fromIsWhitelisted, toIsWhitelisted, _amount, taxFlag == TAXING);
    }
    _;
  }

  modifier onlyMigrator() {
    if (_msgSender() != migrator) {
      revert OnlyMigrator();
    }
    _;
  }

  function burn(uint256 _amount) external {
    _burn(_msgSender(), _amount);
  }

  function burnFrom(address _account, uint256 _amount) external {
    _spendAllowance(_account, _msgSender(), _amount);
    _burn(_account, _amount);
  }

  function _mint(address _account, uint256 _amount) internal override(ERC20, ERC20Votes) {
    super._mint(_account, _amount);
  }

  function _burn(address _account, uint256 _amount) internal override(ERC20, ERC20Votes) {
    super._burn(_account, _amount);
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal override(ERC20) antiMEV(_from, _to, _amount) {
    if (isBlacklisting && transferBlacklist[_from]) {
      revert TransferBlacklisted(_from);
    }

    ERC20._beforeTokenTransfer(_from, _to, _amount);

    if (
      isTaxingEnabled &&
      taxFlag == NOT_TAXING &&
      taxableContracts[_to] &&
      !taxWhitelist[_from] &&
      balanceOf(buyTaxReceiver) >= minimumBenToSwapReached
    ) {
      taxFlag = TAXING; // Set this so no further taxing is done
      IBuyTaxReceiver(buyTaxReceiver).swapCallback();
      taxFlag = NOT_TAXING;
    }
  }

  function _afterTokenTransfer(address _from, address _to, uint256 _amount) internal override(ERC20, ERC20Votes) {
    ERC20Votes._afterTokenTransfer(_from, _to, _amount);

    // Take a fee if it is a taxable contract
    if (isTaxingEnabled && taxFlag == NOT_TAXING) {
      // If it's a buy then we take from who-ever it is sent to and send to the contract for selling back to ETH
      if (taxableContracts[_from] && !taxWhitelist[_to]) {
        uint fee = _calcTax(buyTax, _amount);
        // Transfers from the receiver to the buy tax receiver for later selling
        taxFlag = TAXING;
        _transfer(_to, buyTaxReceiver, fee);
        taxFlag = NOT_TAXING;
      } else if (taxableContracts[_to] && !taxWhitelist[_from]) {
        uint fee = _calcTax(sellTax, _amount);
        // Transfers from taxable contracts (like LPs) to the admin directly
        taxFlag = TAXING;
        _transfer(_to, owner(), fee);
        taxFlag = NOT_TAXING;
      }
    }
  }

  function _calcTax(uint _tax, uint _amount) private pure returns (uint fees) {
    fees = (_amount * _tax) / FEE_DENOMINATOR;
  }

  function _setTax(uint256 _buyTax, uint256 _sellTax, bool _isTaxingEnabled) internal {
    // Cannot set tax higher than MAX_TAX (10%)
    if ((_buyTax * MAX_TAX > FEE_DENOMINATOR) || (_sellTax * MAX_TAX > FEE_DENOMINATOR)) {
      revert MaxTaxExceeded();
    }

    buyTax = uint16(_buyTax);
    sellTax = uint16(_sellTax);
    isTaxingEnabled = _isTaxingEnabled;

    emit SetTax(_buyTax, _sellTax, _isTaxingEnabled);
  }

  function _setIsAntiMEV(bool _isAntiMEV) private {
    isAntiMEV = _isAntiMEV;
    emit SetIsAntiMEV(_isAntiMEV);
  }

  function _setIsTransferBlacklisting(bool _isBlacklisting) private {
    isBlacklisting = _isBlacklisting;
    emit SetIsTransferBlacklisting(_isBlacklisting);
  }

  function _setBuyTaxReceiver(address _buyTaxReceiver) private {
    if (!IERC165(_buyTaxReceiver).supportsInterface(type(IBuyTaxReceiver).interfaceId)) {
      revert InvalidBuyTaxReceiver();
    }

    // Remove previous tax receiveer from the whitelist
    if (MEVWhitelist[buyTaxReceiver]) {
      _setMEVWhitelist(buyTaxReceiver, false);
    }

    buyTaxReceiver = _buyTaxReceiver;
    if (!MEVWhitelist[_buyTaxReceiver]) {
      _setMEVWhitelist(_buyTaxReceiver, true);
    }
    emit SetBuyTaxReceiver(_buyTaxReceiver);
  }

  function _setMEVWhitelist(address _whitelist, bool _isWhitelisted) private {
    MEVWhitelist[_whitelist] = _isWhitelisted;
    emit SetMEVWhitelist(_whitelist, _isWhitelisted);
  }

  function setTax(uint256 _buyTax, uint256 _sellTax, bool _isTaxingEnabled) external onlyOwner {
    _setTax(_buyTax, _sellTax, _isTaxingEnabled);
  }

  function setIsAntiMEV(bool _isAntiMEV) external onlyOwner {
    _setIsAntiMEV(_isAntiMEV);
  }

  function recoverToken(IERC20 _token, uint _amount) external onlyOwner {
    _token.safeTransfer(owner(), _amount);
  }

  function setTaxableContract(address _taxableContract, bool _isTaxable) external onlyOwner {
    taxableContracts[_taxableContract] = _isTaxable;
    emit SetTaxableContract(_taxableContract, _isTaxable);
  }

  function setTaxWhitelist(address _whitelist, bool _isWhitelisted) external onlyOwner {
    taxWhitelist[_whitelist] = _isWhitelisted;
    emit SetTaxWhitelist(_whitelist, _isWhitelisted);
  }

  function setMEVWhitelist(address _whitelist, bool _isWhitelisted) external onlyOwner {
    _setMEVWhitelist(_whitelist, _isWhitelisted);
  }

  function setBuyTaxReceiver(address _buyTaxReceiver) external onlyOwner {
    _setBuyTaxReceiver(_buyTaxReceiver);
  }

  function setIsTransferBlacklisting(bool _isBlacklisting) external onlyOwner {
    _setIsTransferBlacklisting(_isBlacklisting);
  }

  function setTransferBlacklist(address _blacklist, bool _isBlacklisted) external onlyOwner {
    transferBlacklist[_blacklist] = _isBlacklisted;
    emit SetTransferBlacklist(_blacklist, _isBlacklisted);
  }

  function setAntiMevStrategy(IAntiMevStrategy _antiMEVStrategy) external onlyOwner {
    antiMEVStrategy = _antiMEVStrategy;
  }

  function setMinimumBenToSwapReached(uint88 _minimumBenToSwapReached) external onlyOwner {
    minimumBenToSwapReached = _minimumBenToSwapReached;
  }

  // Only used on Ethereum for the initial migration from BenV1 to BenV2
  function mint(address _to, uint _amount) external onlyMigrator {
    _mint(_to, _amount);
  }

  // TODO: Make sure to remove!!
  function testMint(uint _amount) external {
    _mint(msg.sender, _amount);
  }
}