// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../IUSDI.sol";

import "./Vault.sol";
import "./IVault.sol";

import "./IVaultController.sol";

import "../oracle/OracleMaster.sol";
import "../curve/CurveMaster.sol";

import "../_external/IERC20.sol";
import "../_external/compound/ExponentialNoError.sol";
import "../_external/openzeppelin/OwnableUpgradeable.sol";
import "../_external/openzeppelin/Initializable.sol";
import "../_external/openzeppelin/PausableUpgradeable.sol";

/// @title Controller of all vaults in the USDi borrow/lend system
/// @notice VaultController contains all business logic for borrowing and lending through the protocol.
/// It is also in charge of accruing interest.
contract VaultController is
  Initializable,
  PausableUpgradeable,
  IVaultController,
  ExponentialNoError,
  OwnableUpgradeable
{
  // mapping of vault id to vault address
  mapping(uint96 => address) public _vaultId_vaultAddress;

  //mapping of wallet address to vault IDs []
  mapping(address => uint96[]) public _wallet_vaultIDs;

  // mapping of token address to token id
  mapping(address => uint256) public _tokenAddress_tokenId;

  //mapping of tokenId to the LTV*1
  mapping(uint256 => uint256) public _tokenId_tokenLTV;

  //mapping of tokenId to its corresponding oracleAddress (which are addresses)
  mapping(uint256 => address) public _tokenId_oracleAddress;

  //mapping of token address to its corresponding liquidation incentive
  mapping(address => uint256) public _tokenAddress_liquidationIncentive;
  address[] public _enabledTokens;

  OracleMaster public _oracleMaster;
  CurveMaster public _curveMaster;

  IUSDI public _usdi;
  uint96 public _vaultsMinted;

  uint256 private _tokensRegistered;
  uint192 private _totalBaseLiability;
  uint192 private _protocolFee;

  struct Interest {
    uint64 lastTime;
    uint192 factor;
  }
  Interest public _interest;

  /// @notice any function with this modifier will call the pay_interest() function before
  modifier paysInterest() {
    pay_interest();
    _;
  }

  ///@notice any function with this modifier can be paused by USDI._pauser() in the case of an emergency
  modifier onlyPauser() {
    require(_msgSender() == _usdi.pauser(), "only pauser");
    _;
  }

  /// @notice no initialization arguments.
  function initialize() external override initializer {
    __Ownable_init();
    __Pausable_init();
    _interest = Interest(uint64(block.timestamp), 1e18);
    _protocolFee = 1e14;

    _vaultsMinted = 0;
    _tokensRegistered = 0;
    _totalBaseLiability = 0;
  }

  /// @notice get current interest factor
  /// @return interest factor
  function interestFactor() external view override returns (uint192) {
    return _interest.factor;
  }

  /// @notice get last interest time
  /// @return interest time
  function lastInterestTime() external view override returns (uint64) {
    return _interest.lastTime;
  }

  /// @notice get current protocol fee
  /// @return protocol fee
  function protocolFee() external view override returns (uint192) {
    return _protocolFee;
  }

  /// @notice get vault address of id
  /// @return the address of vault
  function vaultAddress(uint96 id) external view override returns (address) {
    return _vaultId_vaultAddress[id];
  }

  ///@notice get vaultIDs of a particular wallet
  ///@return array of vault IDs owned by the wallet, from 0 to many
  function vaultIDs(address wallet) external view override returns (uint96[] memory) {
    return _wallet_vaultIDs[wallet];
  }

  /// @notice get total base liability of all vaults
  /// @return total base liability
  function totalBaseLiability() external view override returns (uint192) {
    return _totalBaseLiability;
  }

  /// @notice get the amount of vaults in the system
  /// @return the amount of vaults in the system
  function vaultsMinted() external view override returns (uint96) {
    return _vaultsMinted;
  }

  /// @notice get the amount of tokens regsitered in the system
  /// @return the amount of tokens registered in the system
  function tokensRegistered() external view override returns (uint256) {
    return _tokensRegistered;
  }

  /// @notice create a new vault
  /// @return address of the new vault
  function mintVault() public override returns (address) {
    // increment  minted vaults
    _vaultsMinted = _vaultsMinted + 1;
    // mint the vault itself, deploying the contract
    address vault_address = address(new Vault(_vaultsMinted, _msgSender(), address(this)));
    // add the vault to our system
    _vaultId_vaultAddress[_vaultsMinted] = vault_address;

    //push new vault ID onto mapping
    _wallet_vaultIDs[_msgSender()].push(_vaultsMinted);

    // emit the event
    emit NewVault(vault_address, _vaultsMinted, _msgSender());
    // return the vault address, allowing the caller to automatically find their vault
    return vault_address;
  }

  /// @notice pause the contract
  function pause() external override onlyPauser {
    _pause();
  }

  /// @notice unpause the contract
  function unpause() external override onlyPauser {
    _unpause();
  }

  /// @notice register the USDi contract
  /// @param usdi_address address to register as USDi
  function registerUSDi(address usdi_address) external override onlyOwner {
    _usdi = IUSDI(usdi_address);
  }

  ///  @notice get oraclemaster address
  /// @return the address
  function getOracleMaster() external view override returns (address) {
    return address(_oracleMaster);
  }

  /// @notice register the OracleMaster contract
  /// @param master_oracle_address address to register as OracleMaster
  function registerOracleMaster(address master_oracle_address) external override onlyOwner {
    _oracleMaster = OracleMaster(master_oracle_address);
    emit RegisterOracleMaster(master_oracle_address);
  }

  ///  @notice get curvemaster address
  /// @return the address
  function getCurveMaster() external view override returns (address) {
    return address(_curveMaster);
  }

  /// @notice register the CurveMaster address
  /// @param master_curve_address address to register as CurveMaster
  function registerCurveMaster(address master_curve_address) external override onlyOwner {
    _curveMaster = CurveMaster(master_curve_address);
    emit RegisterCurveMaster(master_curve_address);
  }

  /// @notice update the protocol fee
  /// @param new_protocol_fee protocol fee in terms of 1e18=100%
  function changeProtocolFee(uint192 new_protocol_fee) external override onlyOwner {
    require(new_protocol_fee < 1e18, "fee is too large");
    _protocolFee = new_protocol_fee;
    emit NewProtocolFee(new_protocol_fee);
  }

  function patchTBL() external onlyOwner {
    uint192 total = 0;
    for (uint96 i = 1; i <= _vaultsMinted; i++) {
      IVault vault = getVault(i);
      total = total + safeu192(vault.baseLiability());
    }
    _totalBaseLiability = total;
  }

  /// @notice register a new token to be used as collateral
  /// @param token_address token to register
  /// @param LTV LTV of the token, 1e18=100%
  /// @param oracle_address oracle to attach to the token
  /// @param liquidationIncentive liquidation penalty for the token, 1e18=100%
  function registerErc20(
    address token_address,
    uint256 LTV,
    address oracle_address,
    uint256 liquidationIncentive
  ) external override onlyOwner {
    // the oracle must be registered & the token must be unregistered
    require(_oracleMaster._relays(oracle_address) != address(0x0), "oracle does not exist");
    require(_tokenAddress_tokenId[token_address] == 0, "token already registered");
    //LTV must be compatible with liquidation incentive
    require(LTV < (expScale - liquidationIncentive), "incompatible LTV");
    // increment the amount of registered token
    _tokensRegistered = _tokensRegistered + 1;
    // set & give the token an id
    _tokenAddress_tokenId[token_address] = _tokensRegistered;
    // set the tokens oracle
    _tokenId_oracleAddress[_tokensRegistered] = oracle_address;
    // set the tokens ltv
    _tokenId_tokenLTV[_tokensRegistered] = LTV;
    // set the tokens liquidation incentive
    _tokenAddress_liquidationIncentive[token_address] = liquidationIncentive;
    // finally, add the token to the array of enabled tokens
    _enabledTokens.push(token_address);
    emit RegisteredErc20(token_address, LTV, oracle_address, liquidationIncentive);
  }

  /// @notice update an existing collateral with new collateral parameters
  /// @param token_address the token to modify
  /// @param LTV new loan-to-value of the token, 1e18=100%
  /// @param oracle_address new oracle to attach to the token
  /// @param liquidationIncentive new liquidation penalty for the token, 1e18=100%
  function updateRegisteredErc20(
    address token_address,
    uint256 LTV,
    address oracle_address,
    uint256 liquidationIncentive
  ) external override onlyOwner {
    // the oracle and token must both exist and be registerd
    require(_oracleMaster._relays(oracle_address) != address(0x0), "oracle does not exist");
    require(_tokenAddress_tokenId[token_address] != 0, "token is not registered");
    //LTV must be compatible with liquidation incentive
    require(LTV < (expScale - liquidationIncentive), "incompatible LTV");
    // set the oracle of the token
    _tokenId_oracleAddress[_tokensRegistered] = oracle_address;
    // set the ltv of the token
    _tokenId_tokenLTV[_tokensRegistered] = LTV;
    // set the liquidation incentive of the token
    _tokenAddress_liquidationIncentive[token_address] = liquidationIncentive;

    emit UpdateRegisteredErc20(token_address, LTV, oracle_address, liquidationIncentive);
  }

  /// @notice check an vault for over-collateralization. returns false if amount borrowed is greater than borrowing power.
  /// @param id the vault to check
  /// @return true = vault over-collateralized; false = vault under-collaterlized
  function checkVault(uint96 id) public view override returns (bool) {
    // grab the vault by id if part of our system. revert if not
    IVault vault = getVault(id);
    // calculate the total value of the vaults liquidity
    uint256 total_liquidity_value = get_vault_borrowing_power(vault);
    // calculate the total liability of the vault
    uint256 usdi_liability = truncate((vault.baseLiability() * _interest.factor));
    // if the LTV >= liability, the vault is solvent
    return (total_liquidity_value >= usdi_liability);
  }

  /// @notice borrow USDi from a vault. only vault minter may borrow from their vault
  /// @param id vault to borrow against
  /// @param amount amount of USDi to borrow
  function borrowUsdi(uint96 id, uint192 amount) external override {
    _borrowUSDi(id, amount, _msgSender());
  }

  /// @notice borrow USDi from a vault and send the USDi to a specific address
  /// @notice Only vault minter may borrow from their vault
  /// @param id vault to borrow against
  /// @param amount amount of USDi to borrow
  /// @param target address to receive borrowed USDi
  function borrowUSDIto(
    uint96 id,
    uint192 amount,
    address target
  ) external override {
    _borrowUSDi(id, amount, target);
  }

  /// @notice business logic to perform the USDi loan
  /// @param id vault to borrow against
  /// @param amount amount of USDi to borrow
  /// @param target address to receive borrowed USDi
  /// @dev pays interest
  function _borrowUSDi(
    uint96 id,
    uint192 amount,
    address target
  ) internal paysInterest whenNotPaused {
    // grab the vault by id if part of our system. revert if not
    IVault vault = getVault(id);
    // only the minter of the vault may borrow from their vault
    require(_msgSender() == vault.minter(), "sender not minter");
    // the base amount is the amount of USDi they wish to borrow divided by the interest factor
    uint192 base_amount = safeu192(uint256(amount * expScale) / uint256(_interest.factor));
    // base_liability should contain the vaults new liability, in terms of base units
    // true indicated that we are adding to the liability
    uint256 base_liability = vault.modifyLiability(true, base_amount);
    // increase the total base liability by the base_amount
    // the same amount we added to the vaults liability
    _totalBaseLiability = _totalBaseLiability + safeu192(base_amount);
    // now take the vaults total base liability and multiply it by the interest factor
    uint256 usdi_liability = truncate(uint256(_interest.factor) * base_liability);
    // now get the LTV of the vault, aka their borrowing power, in usdi
    uint256 total_liquidity_value = get_vault_borrowing_power(vault);
    // the LTV must be above the newly calculated usdi_liability, else revert
    require(total_liquidity_value >= usdi_liability, "vault insolvent");
    // now send usdi to the target, equal to the amount they are owed
    _usdi.vaultControllerMint(target, amount);
    // emit the event
    emit BorrowUSDi(id, address(vault), amount);
  }

  /// @notice borrow USDC directly from reserve
  /// @notice liability is still in USDi, and USDi must be repaid
  /// @param id vault to borrow against
  /// @param usdc_amount amount of USDC to borrow
  /// @param target address to receive borrowed USDC
  function borrowUSDCto(
    uint96 id,
    uint192 usdc_amount,
    address target
  ) external override paysInterest whenNotPaused {
    uint256 amount = usdc_amount * 1e12;

    // grab the vault by id if part of our system. revert if not
    IVault vault = getVault(id);
    // only the minter of the vault may borrow from their vault
    require(_msgSender() == vault.minter(), "sender not minter");
    // the base amount is the amount of USDi they wish to borrow divided by the interest factor
    uint192 base_amount = safeu192(uint256(amount * expScale) / uint256(_interest.factor));
    // base_liability should contain the vaults new liability, in terms of base units
    // true indicated that we are adding to the liability
    uint256 base_liability = vault.modifyLiability(true, base_amount);
    // increase the total base liability by the base_amount
    // the same amount we added to the vaults liability
    _totalBaseLiability = _totalBaseLiability + safeu192(base_amount);
    // now take the vaults total base liability and multiply it by the interest factor
    uint256 usdi_liability = truncate(uint256(_interest.factor) * base_liability);
    // now get the LTV of the vault, aka their borrowing power, in usdi
    uint256 total_liquidity_value = get_vault_borrowing_power(vault);
    // the LTV must be above the newly calculated usdi_liability, else revert
    require(total_liquidity_value >= usdi_liability, "vault insolvent");
    // emit the event
    emit BorrowUSDi(id, address(vault), amount);
    //send USDC to the target from reserve instead of mint
    _usdi.vaultControllerTransfer(target, usdc_amount);
  }

  /// @notice repay a vault's USDi loan. anyone may repay
  /// @param id vault to repay
  /// @param amount amount of USDi to repay
  /// @dev pays interest
  function repayUSDi(uint96 id, uint192 amount) external override paysInterest whenNotPaused {
    // grab the vault by id if part of our system. revert if not
    IVault vault = getVault(id);
    // the base amount is the amount of USDi entered divided by the interest factor
    uint192 base_amount = safeu192((amount * expScale) / _interest.factor);
    // decrease the total base liability by the calculated base amount
    _totalBaseLiability = _totalBaseLiability - base_amount;
    // ensure that base_amount is lower than the vaults base liability.
    // this may not be needed, since modifyLiability *should* revert if is not true
    require(base_amount <= vault.baseLiability(), "repay > borrow amount"); //repay all here if true?
    // decrease the vaults liability by the calculated base amount
    vault.modifyLiability(false, base_amount);
    // burn the amount of USDi submitted from the senders vault
    _usdi.vaultControllerBurn(_msgSender(), amount);
    // emit the event
    emit RepayUSDi(id, address(vault), amount);
  }

  /// @notice repay all of a vaults USDi. anyone may repay a vaults liabilities
  /// @param id the vault to repay
  /// @dev pays interest
  function repayAllUSDi(uint96 id) external override paysInterest whenNotPaused {
    // grab the vault by id if part of our system. revert if not
    IVault vault = getVault(id);
    // get the total USDi liability, equal to the interest factor * vault's base liabilty
    //uint256 usdi_liability = truncate(safeu192(_interest.factor * vault.baseLiability()));
    uint256 usdi_liability = uint256(safeu192(truncate(_interest.factor * vault.baseLiability())));
    // decrease the total base liability by the vaults base liability
    _totalBaseLiability = _totalBaseLiability - safeu192(vault.baseLiability());
    // decrease the vaults liability by the vauls base liability
    vault.modifyLiability(false, vault.baseLiability());
    // burn the amount of USDi paid back from the vault
    _usdi.vaultControllerBurn(_msgSender(), usdi_liability);

    emit RepayUSDi(id, address(vault), usdi_liability);
  }

  /// @notice liquidate an underwater vault
  /// @notice vaults may be liquidated up to the point where they are exactly solvent
  /// @param id the vault liquidate
  /// @param asset_address the token the liquidator wishes to liquidate
  /// @param tokens_to_liquidate  number of tokens to liquidate
  /// @dev pays interest before liquidation
  function liquidateVault(
    uint96 id,
    address asset_address,
    uint256 tokens_to_liquidate
  ) external override paysInterest whenNotPaused returns (uint256) {
    //cannot liquidate 0
    require(tokens_to_liquidate > 0, "must liquidate>0");
    //check for registered asset - audit L3
    require(_tokenAddress_tokenId[asset_address] != 0, "Token not registered");

    // calculate the amount to liquidate and the 'bad fill price' using liquidationMath
    // see _liquidationMath for more detailed explaination of the math
    (uint256 tokenAmount, uint256 badFillPrice) = _liquidationMath(id, asset_address, tokens_to_liquidate);
    // set tokens_to_liquidate to this calculated amount if the function does not fail
    if (tokenAmount != 0) {
      tokens_to_liquidate = tokenAmount;
    }
    // the USDi to repurchase is equal to the bad fill price multiplied by the amount of tokens to liquidate
    uint256 usdi_to_repurchase = truncate(badFillPrice * tokens_to_liquidate);
    // get the vault that the liquidator wishes to liquidate
    IVault vault = getVault(id);

    //decrease the vault's liability
    vault.modifyLiability(false, (usdi_to_repurchase * 1e18) / _interest.factor);

    //decrease liquidator's USDi balance
    _usdi.vaultControllerBurn(_msgSender(), usdi_to_repurchase);

    // finally, deliver tokens to liquidator
    vault.controllerTransfer(asset_address, _msgSender(), tokens_to_liquidate);

    // this might not be needed. Will always be true because it is already implied by _liquidationMath.
    require(get_vault_borrowing_power(vault) <= _vaultLiability(id), "overliquidation");

    // emit the event
    emit Liquidate(id, asset_address, usdi_to_repurchase, tokens_to_liquidate);
    // return the amount of tokens liquidated
    return tokens_to_liquidate;
  }

  /// @notice calculate amount of tokens to liquidate for a vault
  /// @param id the vault to get info for
  /// @param asset_address the token to calculate how many tokens to liquidate
  /// @return - amount of tokens liquidatable
  /// @notice the amount of tokens owed is a moving target and changes with each block as pay_interest is called
  /// @notice this function can serve to give an indication of how many tokens can be liquidated
  /// @dev all this function does is call _liquidationMath with 2**256-1 as the amount
  function tokensToLiquidate(uint96 id, address asset_address) external view override returns (uint256) {
    (
      uint256 tokenAmount, // bad fill price

    ) = _liquidationMath(id, asset_address, 2**256 - 1);
    return tokenAmount;
  }

  /// @notice internal function with business logic for liquidation math
  /// @param id the vault to get info for
  /// @param asset_address the token to calculate how many tokens to liquidate
  /// @param tokens_to_liquidate the max amount of tokens one wishes to liquidate
  /// @return the amount of tokens underwater this vault is
  /// @return the bad fill price for the token
  function _liquidationMath(
    uint96 id,
    address asset_address,
    uint256 tokens_to_liquidate
  ) internal view returns (uint256, uint256) {
    //require that the vault is solvent
    require(!checkVault(id), "Vault is solvent");

    IVault vault = getVault(id);

    //get price of asset scaled to decimal 18
    uint256 price = _oracleMaster.getLivePrice(asset_address);

    // get price discounted by liquidation penalty
    // price * (100% - liquidationIncentive)
    uint256 badFillPrice = truncate(price * (1e18 - _tokenAddress_liquidationIncentive[asset_address]));

    // the ltv discount is the amount of collateral value that one token provides
    uint256 ltvDiscount = truncate(price * _tokenId_tokenLTV[_tokenAddress_tokenId[asset_address]]);
    // this number is the denominator when calculating the max_tokens_to_liquidate
    // it is simply the badFillPrice - ltvDiscount
    uint256 denominator = badFillPrice - ltvDiscount;

    // the maximum amount of tokens to liquidate is the amount that will bring the vault to solvency
    // divided by the denominator
    uint256 max_tokens_to_liquidate = (_amountToSolvency(id) * 1e18) / denominator;

    //Cannot liquidate more than is necessary to make vault over-collateralized
    if (tokens_to_liquidate > max_tokens_to_liquidate) {
      tokens_to_liquidate = max_tokens_to_liquidate;
    }

    //Cannot liquidate more collateral than there is in the vault
    if (tokens_to_liquidate > vault.tokenBalance(asset_address)) {
      tokens_to_liquidate = vault.tokenBalance(asset_address);
    }

    return (tokens_to_liquidate, badFillPrice);
  }

  /// @notice internal helper function to wrap getting of vaults
  /// @notice it will revert if the vault does not exist
  /// @param id id of vault
  /// @return vault IVault contract of
  function getVault(uint96 id) internal view returns (IVault vault) {
    address vault_address = _vaultId_vaultAddress[id];
    require(vault_address != address(0x0), "vault does not exist");
    vault = IVault(vault_address);
  }

  ///@notice amount of USDi needed to reach even solvency
  ///@notice this amount is a moving target and changes with each block as pay_interest is called
  /// @param id id of vault
  function amountToSolvency(uint96 id) public view override returns (uint256) {
    require(!checkVault(id), "Vault is solvent");
    return _amountToSolvency(id);
  }

  ///@notice bussiness logic for amountToSolvency
  function _amountToSolvency(uint96 id) internal view returns (uint256) {
    return _vaultLiability(id) - get_vault_borrowing_power(getVault(id));
  }

  /// @notice get vault liability of vault
  /// @param id id of vault
  /// @return amount of USDi the vault owes
  /// @dev implementation _vaultLiability
  function vaultLiability(uint96 id) external view override returns (uint192) {
    return _vaultLiability(id);
  }

  ///@notice bussiness logic for vaultLiability
  function _vaultLiability(uint96 id) internal view returns (uint192) {
    address vault_address = _vaultId_vaultAddress[id];
    require(vault_address != address(0x0), "vault does not exist");
    IVault vault = IVault(vault_address);
    return safeu192(truncate(vault.baseLiability() * _interest.factor));
  }

  /// @notice get vault borrowing power for vault
  /// @param id id of vault
  /// @return amount of USDi the vault owes
  /// @dev implementation in get_vault_borrowing_power
  function vaultBorrowingPower(uint96 id) external view override returns (uint192) {
    return get_vault_borrowing_power(getVault(id));
  }

  /// @notice the actual implementation of get_vaultA_borrowing_power
  //solhint-disable-next-line code-complexity
  function get_vault_borrowing_power(IVault vault) private view returns (uint192) {
    uint192 total_liquidity_value = 0;
    // loop over each registed token, adding the indivuduals LTV to the total LTV of the vault
    for (uint192 i = 1; i <= _tokensRegistered; i++) {
      // if the ltv is 0, continue
      if (_tokenId_tokenLTV[i] == 0) {
        continue;
      }
      // get the address of the token through the array of enabled tokens
      // note that index 0 of this vaultId 1, so we must subtract 1
      address token_address = _enabledTokens[i - 1];
      // the balance is the vaults token balance of the current collateral token in the loop
      uint256 balance = vault.tokenBalance(token_address);
      if (balance == 0) {
        continue;
      }
      // the raw price is simply the oraclemaster price of the token
      uint192 raw_price = safeu192(_oracleMaster.getLivePrice(token_address));
      if (raw_price == 0) {
        continue;
      }
      // the token value is equal to the price * balance * tokenLTV
      uint192 token_value = safeu192(truncate(truncate(raw_price * balance * _tokenId_tokenLTV[i])));
      // increase the LTV of the vault by the token value
      total_liquidity_value = total_liquidity_value + token_value;
    }
    return total_liquidity_value;
  }

  /// @notice calls the pay interest function
  /// @dev implementation in pay_interest
  function calculateInterest() external override returns (uint256) {
    return pay_interest();
  }

  /// @notice accrue interest to borrowers and distribute it to USDi holders.
  /// this function is called before any function that changes the reserve ratio
  function pay_interest() private returns (uint256) {
    // calculate the time difference between the current block and the last time the block was called
    uint64 timeDifference = uint64(block.timestamp) - _interest.lastTime;
    // if the time difference is 0, there is no interest. this saves gas in the case that
    // if multiple users call interest paying functions in the same block
    if (timeDifference == 0) {
      return 0;
    }
    // the current reserve ratio, cast to a uint256
    uint256 ui18 = uint256(_usdi.reserveRatio());
    // cast the reserve ratio now to an int in order to get a curve value
    int256 reserve_ratio = int256(ui18);

    // calculate the value at the curve. this vault controller is a USDi vault and will refernce
    // the vault at address 0
    int256 int_curve_val = _curveMaster.getValueAt(address(0x00), reserve_ratio);

    // cast the integer curve value to a u192
    uint192 curve_val = safeu192(uint256(int_curve_val));
    // calculate the amount of total outstanding loans before and after this interest accrual

    // first calculate how much the interest factor should increase by
    // this is equal to (timedifference * (curve value) / (seconds in a year)) * (interest factor)
    uint192 e18_factor_increase = safeu192(
      truncate(
        truncate((uint256(timeDifference) * uint256(1e18) * uint256(curve_val)) / (365 days + 6 hours)) *
          uint256(_interest.factor)
      )
    );
    // get the total outstanding value before we increase the interest factor
    uint192 valueBefore = safeu192(truncate(uint256(_totalBaseLiability) * uint256(_interest.factor)));
    // _interest is a struct which contains the last timestamp and the current interest factor
    // set the value of this struct to a struct containing {(current block timestamp), (interest factor + increase)}
    // this should save ~5000 gas/call
    _interest = Interest(uint64(block.timestamp), _interest.factor + e18_factor_increase);
    // using that new value, calculate the new total outstanding value
    uint192 valueAfter = safeu192(truncate(uint256(_totalBaseLiability) * uint256(_interest.factor)));

    // valueAfter - valueBefore is now equal to the true amount of interest accured
    // this mitigates rounding errors
    // the protocol's fee amount is equal to this value multiplied by the protocol fee percentage, 1e18=100%
    uint192 protocolAmount = safeu192(truncate(uint256(valueAfter - valueBefore) * uint256(_protocolFee)));
    // donate the true amount of interest less the amount which the protocol is taking for itself
    // this donation is what pays out interest to USDi holders
    _usdi.vaultControllerDonate(valueAfter - valueBefore - protocolAmount);
    // send the protocol's fee to the owner of this contract.
    _usdi.vaultControllerMint(owner(), protocolAmount);
    // emit the event
    emit InterestEvent(uint64(block.timestamp), e18_factor_increase, curve_val);
    // return the interest factor increase
    return e18_factor_increase;
  }

  /// special view only function to help liquidators

  /// @notice helper function to view the status of a range of vaults
  /// @param start the vault to start looping
  /// @param stop the vault to stop looping
  /// @return VaultSummary[] a collection of vault information
  function vaultSummaries(uint96 start, uint96 stop) public view override returns (VaultSummary[] memory) {
    VaultSummary[] memory summaries = new VaultSummary[](stop - start + 1);
    for (uint96 i = start; i <= stop; i++) {
      IVault vault = getVault(i);
      uint256[] memory tokenBalances = new uint256[](_enabledTokens.length);

      for (uint256 j = 0; j < _enabledTokens.length; j++) {
        tokenBalances[j] = vault.tokenBalance(_enabledTokens[j]);
      }
      summaries[i - start] = VaultSummary(
        i,
        this.vaultBorrowingPower(i),
        this.vaultLiability(i),
        _enabledTokens,
        tokenBalances
      );
    }
    return summaries;
  }
}