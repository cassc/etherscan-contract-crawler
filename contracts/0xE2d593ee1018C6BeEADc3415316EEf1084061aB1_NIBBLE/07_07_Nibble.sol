//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Nibble
/// @author Nibble Team
/// @notice A revolution in the making by means of Democracy in a decentralised new world; this is a platform for the gamers by the gamers! NO DEGENS HERE!

import {ERC20} from "openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin/contracts/security/ReentrancyGuard.sol";


contract NIBBLE is
  ERC20,
  Ownable,
  ReentrancyGuard
{
  /// @notice The stage of the token sale
  /// @param SaleOne - The first stage of the token sale
  /// @param SaleTwo - The second stage of the token sale
  /// @param SaleThree - The third stage of the token sale
  /// @param Live - The final stage of the token sale
  enum Stages {
    SaleOne,
    SaleTwo,
    SaleThree,
    Live
  }

  /// @notice The current stage of the token sale
  Stages public stage;
  bool public maxBalanceOn;
  bool public isTaxable;
  /// @notice boolean to check if the contract is paused
  bool public paused;

  /// @notice The address of the multisig wallet
  address public multiSigWallet;
  /// @notice The address of the underlying owner
  address public immutable underlying;
  /// @notice an array of all the minter addresses
  address[] public minters;
  address[] public routers;
  /// @notice The address of the minter that is pending to be added
  address public pendingMinter;
  uint256 public delayMinter;
  /// @notice The delay for the minter to be added
  uint256 public constant DELAY = 2 days;
  /// @notice The max amount of tokens that can be held by any wallet
  /// @dev This is to prevent whales from holding too many tokens
  uint256 public constant MAX_WALLET_BALANCE = 17600 * 10**18;
  /// @notice The max amount of tokens that can be minted in each stage
  uint256 public constant MAX_STAGE_SUPPLY = 296000 * 10**18;
  /// @notice The max amount of tokens that can be minted
  /// @dev This is to prevent the total supply from exceeding the max
  uint256 public constant MAX_TOTAL_SUPPLY = 888000 * 10**18;
  /// @notice The default cooldown time after interacting with the contract
  uint256 public cooldownTime = 60 minutes;
  /// @notice The default tax fee for each transaction
  /// @dev value / 10000 = tax fee% (e.g. 250 / 10000 = 2.5%)
  uint96 public taxFee;
  /// @notice address => timestamp of last interaction with the contract
  mapping(address => uint256) public cooldowns;
  /// @notice address => boolean to check if the address is excluded from the cooldown
  mapping(address => bool) public addrsExcludedFromCooldown;
  /// @notice address => boolean to check if the address is excluded from the tax
  mapping(address => bool) public addrsExcludedFromTax;
  /// @notice address => boolean to check if the address is excluded from the max wallet balance
  mapping(address => bool) public addrsExcludedFromMaxWalletBalance;
  /// @notice address => boolean to check if the address is a minter
  mapping(address => bool) public isMinter;
  mapping(address => bool) public isRouter;

  event Minted(address to, uint256 amount);
  event TaxFeeChanged(uint96 taxFee);
  event CooldownTimeChanged(uint256 cooldownTime);
  event StageChanged(Stages stage);
  event CooldownSet(address addr, uint256 cooldown);
  event TransferWithTax(
    address sender,
    address taxRecipient,
    uint256 amount,
    uint256 taxAmount
  );
  event TransferWithoutTax(
    address sender,
    address recipient,
    uint256 amount
  );
  event MinterApplied(address addedMinter);
  event MinterRevoked(address removedMinter);
  event MinterPending(address pendingMinter, uint256 pendingDelay);

  /// @notice Constructor for the Nibble token
  /// @param name - The name of the token
  /// @param symbol - The symbol of the token
  /// @param _multiSigWallet - The address of the multisig wallet
  /// @param _coreTeamAddrs - The addresses of the core team
  /// @param _taxFee - The default tax fee for each transaction
  constructor(
    string memory name,
    string memory symbol,
    address _underlying,
    address _minter,
    address _multiSigWallet,
    address[] memory _coreTeamAddrs,
    uint96 _taxFee
  ) ERC20(name, symbol) {
    multiSigWallet = _multiSigWallet;
    transferOwnership(_multiSigWallet);
    //set to Stage one
    stage = Stages.SaleOne;
    taxFee = _taxFee;
    isTaxable = false;
    maxBalanceOn = false;
    underlying = _underlying;
    //add core team addresses to excluded list
    addrsExcludedFromCooldown[_multiSigWallet] = true;
    addrsExcludedFromTax[_multiSigWallet] = true;
    addrsExcludedFromMaxWalletBalance[_multiSigWallet] = true;
    for (uint256 i = 0; i < _coreTeamAddrs.length; i++) {
      addrsExcludedFromCooldown[_coreTeamAddrs[i]] = true;
      addrsExcludedFromTax[_coreTeamAddrs[i]] = true;
      addrsExcludedFromMaxWalletBalance[_coreTeamAddrs[i]] = true;
    }
    isMinter[_minter] = true;
    minters.push(_minter);

    _mint(_multiSigWallet, 296000 * 10**18);
  }

  /// @notice checks if the address is zero
  /// @param _addr - The address to check
  modifier isNotZero(address _addr) {
    require(_addr != address(0), "NIBBLE: Address cannot be zero");
    _;
  }

  /// @notice checks if the contract is paused
  modifier isNotPaused() {
    require(!paused, "NIBBLE: Contract is paused");
    _;
  }

  /// @notice checks if the msg.sender is a minter, or owner
  modifier onlyAuth() {
    require(
      isMinter[msg.sender] || msg.sender == owner(),
      "NIBBLE: Only authorised addresses can mint"
    );
    _;
  }

  /// @notice Only Owner function to mint tokens, Mints full supply of tokens for each stage
  /// @param to - The address to mint tokens to
  /// @param amount - The amount of tokens to mint
  function mint(address to, uint256 amount) external onlyAuth returns (bool) {
    require(amount <= MAX_STAGE_SUPPLY, "NIBBLE: Cannot mint more than max supply");
    require(totalSupply() + amount <= MAX_TOTAL_SUPPLY, "NIBBLE: Cannot mint more than max total supply");

    _mint(to, amount);
    return true;
    }

  /// @notice Only Authorized function to burn tokens
  /// @param from - The address to burn tokens from
  /// @param amount - The amount of tokens to burn
  function burn(address from, uint256 amount) external onlyAuth returns (bool) {
    require(from != address(0), "AnyswapV3ERC20: address(0x0)");
    _burn(from, amount);
    return true;
  }

  /// @notice Only Owner function to set stage of token sale
  function setStage(Stages _stage) external onlyOwner {
    require(_stage != stage, "NIBBLE: Cannot set stage to current stage");
    require(uint256(_stage) > uint256(stage), "NIBBLE: Cannot set stage to previous stage");
    if (_stage == Stages.SaleOne) {
      taxFee = 4000;
    } else if (_stage == Stages.SaleTwo) {
      taxFee = 3000;
    } else if (_stage == Stages.SaleThree) {
      taxFee = 2000;
    } else if (_stage == Stages.Live) {
      taxFee = 250;
    }
    stage = _stage;
    emit StageChanged(stage);
  }

  /// @notice Only owner function to pause the contract
  function togglePause() external onlyOwner {
    paused = !paused;
  }

  /// @notice Only owner function to exclude addresses from the cooldown
  /// @param _addrs - The addresses to exclude from the cooldown
  function excludedAddrsFromCooldown(address[] calldata _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != multiSigWallet, "NIBBLE: Cannot remove multiSigWallet from excluded list");
      require(_addrs[i] != address(0), "NIBBLE: Address cannot be zero");
      addrsExcludedFromCooldown[_addrs[i]] = true;
    }
  }

  /// @notice Only owner function to remove excluded addresses from the cooldown
  /// @param _addrs - The addresses to remove from the excluded list
  function removeExcludedAddrsFromCooldown(address[] calldata _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != multiSigWallet, "NIBBLE: Cannot remove multiSigWallet from excluded list");
      require(_addrs[i] != address(0), "NIBBLE: Address cannot be zero");
      addrsExcludedFromCooldown[_addrs[i]] = false;
    }
  }

  /// @notice Only owner function to exclude addresses from the tax
  /// @param _addrs - The addresses to exclude from the tax
  function excludedAddrsFromTax(address[] calldata _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != address(0), "NIBBLE: Address cannot be zero");
      addrsExcludedFromTax[_addrs[i]] = true;
    }
  }

  /// @notice Only owner function to remove excluded addresses from the tax
  /// @param _addrs - The addresses to remove from the excluded list
  function removeExcludedAddrsFromTax(address[] calldata _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != multiSigWallet, "NIBBLE: Cannot remove multiSigWallet from excluded list");
      require(_addrs[i] != address(0), "NIBBLE: Address cannot be zero");
      addrsExcludedFromTax[_addrs[i]] = false;
    }
  }

  /// @notice Only owner function to exclude addresses from the max wallet balance
  /// @param _addrs - The addresses to exclude from the max wallet balance
  function excludedAddrsFromMaxWalletBalance(address[] calldata _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != address(0), "NIBBLE: Address cannot be zero");
      addrsExcludedFromMaxWalletBalance[_addrs[i]] = true;
    }
  }

  /// @notice Only owner function to remove excluded addresses from the max wallet balance
  /// @param _addrs - The addresses to remove from the excluded list
  function removeExcludedAddrsFromMaxWalletBalance(address[] calldata _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != multiSigWallet, "NIBBLE: Cannot remove multiSigWallet from excluded list");
      require(_addrs[i] != address(0), "NIBBLE: Address cannot be zero");
      addrsExcludedFromMaxWalletBalance[_addrs[i]] = false;
    }
  }

  /// @notice Only owner function to set the cooldown time
  /// @param _cooldownTime The new cooldown time in seconds
  /// @dev cooldown time is the time after interacting with the contract before the user can interact again
  function setCooldownTime(uint256 _cooldownTime) external onlyOwner {
    require(_cooldownTime >= 0, "NIBBLE: Cooldown time cannot be negative");
    require(_cooldownTime <= 86400, "NIBBLE: Cooldown time cannot be greater than 24 hours");
    cooldownTime = _cooldownTime;
    emit CooldownTimeChanged(cooldownTime);
  }

  /// @notice Only owner function to set the current tax fee
  /// @param _taxFee The new tax fee is denominated by 10000 (e.g. 250 = 2.5%)
  function setTaxFee(uint96 _taxFee) external onlyOwner  {
    require(_taxFee >= 0, "NIBBLE: Tax fee cannot be negative");
    require(_taxFee <= 5000, "NIBBLE: Tax fee cannot be greater than 100%");
    taxFee = _taxFee;
    emit TaxFeeChanged(taxFee);
  }

  /// @notice Only owner function to set the multiSigWallet address
  /// @param newAddrs The new multiSigWallet address
  /// @dev The new address will get ownership of the contract
  function setMultiSigWallet(address newAddrs) external onlyOwner isNotZero(newAddrs) {
    multiSigWallet = newAddrs;
    transferOwnership(multiSigWallet);
  }

  function addRouters(address[] calldata _routers) external onlyOwner {
    for (uint256 i = 0; i < _routers.length; i++) {
      require(_routers[i] != address(0), "NIBBLE: Address cannot be zero");
      isRouter[_routers[i]] = true;
    }
  }

  function removeRouters(address[] calldata _routers) external onlyOwner {
    for (uint256 i = 0; i < _routers.length; i++) {
      require(_routers[i] != address(0), "NIBBLE: Address cannot be zero");
      isRouter[_routers[i]] = false;
    }
  }

  /// @notice Only owner function to set minter address
  /// @param _auth The address of the minter
  /// @dev The _auth address will be set into pendingMinter, after the DELAY period, the owner can apply the minter
  function setMinter(address _auth) external onlyOwner isNotZero(_auth) {
    pendingMinter = _auth;
    delayMinter = block.timestamp + DELAY;
    emit MinterPending(pendingMinter, delayMinter);
  }

  /// @notice Only owner function to revoke minter address
  /// @param _auth The address of the minter
  function revokeMinter(address _auth) external onlyOwner {
    isMinter[_auth] = false;
    emit MinterRevoked(_auth);
  }

  /// @notice Only owner function to apply minter address
  /// @dev The minter address will be applied after the delay period
  function applyMinter() external onlyOwner {
    require(pendingMinter != address(0) && block.timestamp >= delayMinter, "NIBBLE: Cannot apply minter");
    isMinter[pendingMinter] = true;
    minters.push(pendingMinter);
    pendingMinter = address(0);
    delayMinter = 0;
    emit MinterApplied(minters[minters.length - 1]);
  }

  function setMaxBalanceOn(bool onOff) external onlyOwner {
    maxBalanceOn = onOff;
  }

  function setTaxable(bool taxable) external onlyOwner {
    isTaxable = taxable;
  }

  /// @notice Internal mint function to mint tokens
  /// @param account The address of the recipient
  /// @param amount The amount of tokens to mint
  function _mint(address account, uint256 amount) internal override isNotZero(account) {
    //Check if the total supply will exceed the max total supply
    require(
      totalSupply() + amount <= MAX_TOTAL_SUPPLY,
      "Cannot exceed max total supply"
    );
    //check if the wallet balance will exceed the max wallet balance
    if(!addrsExcludedFromMaxWalletBalance[account]) {
      require(
        balanceOf(account) + amount <= MAX_WALLET_BALANCE,
        "Cannot exceed max wallet balance"
      );
    }
    //check if the stage is correct
    if(stage == Stages.SaleOne) {
      require(
        totalSupply() + amount <= MAX_STAGE_SUPPLY,
        'Cannot exceed max stage supply'
      );
    } else if(stage == Stages.SaleTwo) {
      require(
        totalSupply() + amount <= MAX_STAGE_SUPPLY * 2,
        'Cannot exceed max stage supply'
      );
    } else if(stage == Stages.SaleThree) {
      require(
        totalSupply() + amount <= MAX_STAGE_SUPPLY * 3,
        'Cannot exceed max stage supply'
      );
    }
    emit Minted(account, amount);
    super._mint(account, amount);
  }

  /// @notice Internal function called before any token transfer
  /// @param from The address of the sender
  /// @param to The address of the recipient
  /// @param amount The amount of tokens to transfer
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override  {
    require(!paused, "NIBBLE: Contract is paused");
    //check if the wallet balance will exceed the max wallet balance
    if(!maxBalanceOn) {
      return;
    } else {
      if(!addrsExcludedFromMaxWalletBalance[to]) {
        require(
          balanceOf(to) + amount <= MAX_WALLET_BALANCE,
          "Cannot exceed max wallet balance"
        );
      } else {
        return;
      }
    }

    //check if the address is excluded from cooldown
    if (addrsExcludedFromCooldown[from] || addrsExcludedFromCooldown[to]) {
      return;
    }
    
    //check if the address is on cooldown
    super._beforeTokenTransfer(from, to, amount);
  }

  /// @notice Internal function to transfer tokens
  /// @param sender The address of the sender
  /// @param recipient The address of the recipient
  /// @param amount The amount of tokens to transfer
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal override isNotPaused {
    require(sender != address(0), "NIBBLE: Cannot transfer from the zero address");
    require(recipient != address(0), "NIBBLE: Cannot transfer to the zero address");
    require(amount > 0, "NIBBLE: Cannot transfer zero amount");
    require(
      block.timestamp >= cooldowns[sender],
      "NIBBLE: Sender is on cooldown"
    );
    
    //check isTaxable bool to determine if tax should be applied
    if (isTaxable) {
      //Check if tx is swapping tokens
      if (isRouter[recipient] || isRouter[msg.sender]) {
        //Check if the address is excluded from tax
        if (addrsExcludedFromTax[sender]) {
          super._transfer(sender, recipient, amount);
          !addrsExcludedFromCooldown[sender] ? cooldowns[sender] = block.timestamp + cooldownTime : cooldowns[sender] = block.timestamp;
          emit CooldownSet(sender, cooldowns[sender]);
          emit TransferWithoutTax(sender, recipient, amount);
          return;
        } else {
          //Calculate tax amount
          uint256 taxAmount = amount * taxFee / 10000;
          //Calculate amount to transfer
          uint256 transferAmount = amount - taxAmount;
          //Transfer tokens
          super._transfer(sender, recipient, transferAmount);
          //Transfer tax to the tax address
          super._transfer(sender, multiSigWallet, taxAmount);
          !addrsExcludedFromCooldown[sender] ? cooldowns[sender] = block.timestamp + cooldownTime : cooldowns[sender] = block.timestamp;
          emit TransferWithTax(sender, multiSigWallet, amount, taxAmount);
          emit CooldownSet(sender, cooldowns[sender]);
          return;
        }
      } else {
        super._transfer(sender, recipient, amount);
        !addrsExcludedFromCooldown[sender] ? cooldowns[sender] = block.timestamp + cooldownTime : cooldowns[sender] = block.timestamp;
        emit CooldownSet(sender, cooldowns[sender]);
        return;
      }
    } else {
      super._transfer(sender, recipient, amount);
      !addrsExcludedFromCooldown[sender] ? cooldowns[sender] = block.timestamp + cooldownTime : cooldowns[sender] = block.timestamp;
      emit CooldownSet(sender, cooldowns[sender]);
      return;
    }
  }
}