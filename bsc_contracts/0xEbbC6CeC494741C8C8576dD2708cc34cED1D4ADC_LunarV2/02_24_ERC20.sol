// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
Lunar Defi, Inc. Copyright © 2022.

* Telegram:  https://t.me/lnrDefi
* Twitter:   https://twitter.com/LNR
* Website:   https://lunar.io/
*/

/** 
* @title A Token Smart Contract
* @author Lunar Defi, Inc. Copyright © 2022. All rights reserved.
* @notice This is the base contract for all Lunar Tokens.
* @dev This contract is also upgradeable and contains public & private functions for a variety of use cases for official Lunar Tokens.
*/
contract Lunar is Initializable, ERC20Upgradeable, UUPSUpgradeable, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
  /*
  Includes
  */
  using SafeMathUpgradeable for uint256;
  
  /*
  Private Members
  */

  // Private mapping arrays/lists
  mapping (address => bool) private _bypassTransferFeesList;  //Used to track addresses that bypass transfer fees.
  mapping (address => bool) private _bypassBuyFeesList;       //Used to track addresses that bypass buy fees.
  mapping (address => bool) private _bypassSellFeesList;      //Used to track addresses that bypass sell fees.
  mapping (address => bool) private _internalList;            //Used to track addresses that bypass major contract restrictions.
  mapping (address => bool) private _denyList;                //Used to track addresses that completely denied from using the contract.
  mapping (address => bool) private _denyBotList;             //What can we say except: 'Fuck you Bots'.

  // Sets the number of decimal places for calculation displays.
  uint8 private _decimals;

  /*
  Public Members
  */
  
  /*
  Indicators
  */

  // Max token allocation.
  uint256 public maxTokenAllocation; 

  // Specifies if trading is currently enabled.
  bool public isTradingEnabled;

  /*
  Addresses
  */

  // Pairing and Router address
  address public uniswapV2Pair;

  IUniswapV2Router02 public uniswapV2Router;

  // Contract-wide Wallets
  address public liquidityWalletAddress;
  address public marketingWalletAddress;
  address public operationsWalletAddress;

  /*
  Custom Contract Roles
  */

  // Deployer Role 
  bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
  
  // Transaction Role
  bytes32 public constant TRANSACTION_ROLE = keccak256("TRANSACTION_ROLE");

  /*
  Contract Events
  */

  /**
  * @notice Triggered when the Anti Whale Guard struct has been updated.
  * @dev Custom Event | AntiWhaleGuardsChanged
  * @param maxWalletSize        - Updated Max Wallet Size.
  * @param maxBuyAmount         - Updated Max Buy Amount.
  * @param maxSellAmount        - Updated Max Sell Amount.
  * @param updatedTimestamp     - Timestamp to track when AntiWhale Guards change.
  */
  event AntiWhaleGuardsChanged(uint256 maxWalletSize, uint256 maxBuyAmount, uint256 maxSellAmount, uint256 updatedTimestamp);

  /**
  * @notice Triggered when the fee struct has been updated for buy fees.
  * @dev Custom Event | BuyFeesChanged
  * @param liquidityFee       - Updated Liquidity Fee.
  * @param marketingFee       - Updated Marketing Fee.
  * @param operationsFee      - Updated Operations Fee.
  * @param updatedTimestamp   - Timestamp to track when Buy Fees change.
  */
  event BuyFeesChanged(uint256 liquidityFee, uint256 marketingFee, uint256 operationsFee, uint256 updatedTimestamp);

  /**
  * @notice Triggered when native currency has been rescued from the contract.
  * @dev Custom Event | NativeCurrencyRescued
  * @param systemAccount    - Wallet address from which the rescue call has been invoked.
  * @param amount           - Integer representing the amount of native currency rescued from the contract.
  */
  event NativeCurrencyRescued(address systemAccount, uint256 amount);

  /**
  * @notice Triggered when the fee struct has been updated for sell fees.
  * @dev Custom Event | SellFeesChanged
  * @param liquidityFee       - Updated Liquidity Fee.
  * @param marketingFee       - Updated Marketing Fee.
  * @param operationsFee      - Updated Operations Fee.
  * @param updatedTimestamp   - Timestamp to track when Sell Fees change.
  */
  event SellFeesChanged(uint256 liquidityFee, uint256 marketingFee, uint256 operationsFee, uint256 updatedTimestamp);

  /**
  * @notice Triggered when tokens of a given token address are rescued from the contract.
  * @dev Custom Event | TokensRescued
  * @param systemAccount    - The wallet address from which the rescue call has been invoked.
  * @param tokenAddress     - The address of the token that is withdrawn
  * @param amount           - Integer representing the the amount of tokens rescued from contract.
  */
  event TokensRescued(address systemAccount, address tokenAddress, uint256 amount);

  /**
  * @notice Triggered when the trading flag is been modified.
  * @dev Custom Event | TradingEnabled
  * @param isEnabled          - Boolean that determines if trading is enabled or disabled.
  * @param updatedTimestamp   - Timestamp to track when trading and swapping has been modified.
  */
  event TradingEnabled(bool isEnabled, uint256 updatedTimestamp);

  /**
  * @notice Triggered when the details of a transfer transaction have been calculated.
  * @dev Custom Event | TransactionDetailsCalculated
  * @param details          - The TransacrionDetails object calculated during the transaction.
  */
  event TransactionDetailsCalculated(TransactionDetails details);

  /**
  * @notice Triggered when the fee structure has been updated for transfer fees.
  * @dev Custom Event | TransferFeesChanged
  * @param liquidityFee       - Updated Liquidity Fee.
  * @param marketingFee       - Updated Marketing Fee.
  * @param operationsFee      - Updated Operations Fee.
  * @param updatedTimestamp   - Timestamp to track when Transfer Fees change.
  */
  event TransferFeesChanged(uint256 liquidityFee, uint256 marketingFee, uint256 operationsFee, uint256 updatedTimestamp);

  /*
  Enumerations 
  */

  /// TRANSFER = 0,    Identifies the direct exchange of tokens. 
  /// BUY =      1,    Identifies the purchase of tokens. 
  /// SELL =     2,    Identifies the selling of tokens.
  enum TransactionType 
  {
    TRANSFER,
    BUY,
    SELL
  }

  /*
  Structures
  */

  /**
  * @notice This structure provides the pre-calculated fees that will be used for the duration of this transaction.
  */
  struct TransactionDetails
  {
    /** The amount after fees. */
    uint256 adjustedAmount;
    /** The fee calculated from FeeRates.LiquidityFee x msg.Amount. */
    uint256 liquidityFee;
    /** The fee calculated from FeeRates.MarketingFee x msg.Amount. */
    uint256 marketingFee;
    /** The fee calculated from FeeRates.OperationsFee x msg.Amount. */
    uint256 operationsFee;
    /** A boolean specifying whether or not we will be taking fees from this transation. */
    bool shouldBypassFees;
    /** The calculated TransactionType for this Transaction. */
    TransactionType transactionType;
  }

  /**
  * @notice This structure provides the fee rates throughout the contract.
  */
  struct FeeRates 
  {
    /** The fee that should be taken to improve token liquidity. */
    uint256 liquidityFee;
    /** The fee that should be taken to drive the marketing budget. */
    uint256 marketingFee;
    /** The fee that should be taken to cover other operational expenses. */
    uint256 operationsFee;
  }
  
  /**
  * @notice This structure provides .
  */
  struct SafeGuards
  {
    /** The max buy amount that a single wallet can execute. */
    uint256 maxBuyAmount;
    /** The max sell amount that a single wallet can execute. */
    uint256 maxSellAmount;
    /** The maximum amount of this token that a wallet may possess. */
    uint256 maxWalletAmount;
  }

  /**
  * @notice This structure provides the fees paid throughout the history of the contract.
  */
  struct FeesPaidHistory 
  {
    /** The total fees that have ever been taken to improve the liquidity pool. */
    uint256 totalLiquidityFeesPaid;
    /** The total fees that have ever been taken to drive the marketing budget. */
    uint256 totalMarketingFeesPaid;
    /** The total fees that have ever been taken to cover other operational expenses. */
    uint256 totalOperationsFeesPaid;
  }

  /*
  Structure Implementations
  */

  FeeRates public transferFeeRates;

  FeeRates public buyFeeRates;

  FeeRates public sellFeeRates;

  SafeGuards public antiWhaleGuardRates;

  SafeGuards public antiWhaleGuardCalculated;

  FeesPaidHistory public contractFeesPaidHistory;

  /*
  Contract Constructor
  */ 

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  /** @notice Replaces constructor for an upgradeable contract
    * @dev oz-contracts-upgrades are initialized here along with some private members.
    * @param _name                - Name of the token.
    * @param _symbol              - Symbol identifier for the token.
    * @param _maxTokenAllocation  - The maximum number of whole tokens that can be issued on this contract.
    * @param _tokenDecimals       - Decimal places for all tokens.
    * @param _adminAddress        - Default Admin Address.
    * @param _transactionAddress  - Executes Plexus(TM) functions.
    * @param _marketingAddress    - Collects marketing funds and tokens.
    * @param _liquidityAddress    - Transfers liquidity out of the contract.
    * @param _operationsAddress   - Collects operational funds and tokens.
  */
  function initialize(
    string memory _name,
    string memory _symbol,
    uint256   _maxTokenAllocation,
    uint8     _tokenDecimals,
    address   _adminAddress,
    address   _transactionAddress,
    address   _marketingAddress,
    address   _liquidityAddress,
    address   _operationsAddress) public initializer
  {
    // Initialize default contracts
    __ERC20_init(_name, _symbol);
    __Pausable_init();
    __AccessControl_init();
    __UUPSUpgradeable_init();

    // Set Decimals for calculations
    _decimals = _tokenDecimals;

    // Set Max Allocation using a private member
    maxTokenAllocation = _maxTokenAllocation * 10**_decimals;

    // Set Default Wallet Values
    marketingWalletAddress = _marketingAddress;
    liquidityWalletAddress = _liquidityAddress;
    operationsWalletAddress = _operationsAddress;

    // Grant initial roles
    _grantRole(DEPLOYER_ROLE, msg.sender);
    _grantRole(DEFAULT_ADMIN_ROLE, _adminAddress);
    _grantRole(TRANSACTION_ROLE, _transactionAddress);

    // Add initial wallets to _internalList List.
    updateInternalList(_adminAddress, true);
    updateInternalList(_transactionAddress, true);
    updateInternalList(_liquidityAddress, true);
    updateInternalList(_operationsAddress, true);

    // Set initial safeGuards for Anti-Whale checks.
    updateAntiWhaleGuards(10, 10, 10);

    // Set Buy and Sell Fee struct for future fee calculations.
    // liquidityFee, marketingFee, operationsFee
    updateTransferFees(0, 0, 0);
    updateBuyFees(0, 0, 60);
    updateSellFees(0, 0, 60);

    // Bypass Transfer, Buy and Sell fees across all initial wallets.
    _bypassAllFees(_adminAddress, true);
    _bypassAllFees(_transactionAddress, true);
    _bypassAllFees(_liquidityAddress, true);
    _bypassAllFees(_operationsAddress, true);

    // Pause the contract on initilization.
    pause();
  }

  /*
  Modifiers
  */

  /**
  * @dev Modifier to ensure that only Plexus(TM) roles can make function calls.
  */
  modifier onlyPlexusRoles() 
  {
    // SHEPARD: Check if sender has the correct role.
    require(hasRole(TRANSACTION_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "The specified wallet is not allowed to execute this function.");
    // SHEPARD: This line matters for modifiers, don't take it out!
    _;
  }

  /**
  * @dev Modifier to ensure that only System roles can make function calls.
  */
  modifier onlySystemRoles() 
  {
    // SHEPARD: Check if sender has the correct role.
    require(hasRole(DEPLOYER_ROLE, msg.sender) || hasRole(TRANSACTION_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "The specified wallet is not allowed to execute this function.");
    // SHEPARD: This line matters for modifiers, don't take it out!
    _;
  }

  /**
  * @dev Modifier to ensure that only administrative roles can make function calls.
  */
  modifier onlyAdminRoles() 
  {
    // SHEPARD: Check if sender has the correct role.
    require(hasRole(DEPLOYER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "The specified wallet is not allowed to execute this function.");
    // SHEPARD: This line matters for modifiers, don't take it out!
    _;
  }

  /*
  Standard Functions
  */

  /*
  * Contract Standard Functions | The following code is required by the contract specification.
  */

  /**
  * @notice Upgrades the contract with a new implementation
  * @dev This function is called during upgrade by using OpenZepplin upgrade resources during deployment of new implementation 
  * @param newImplementation - The address of the new contract
  */
  function _authorizeUpgrade(address newImplementation)
    internal
    onlyAdminRoles
    override
  {
  }

  /**
  *@notice This intercepts calls to the OpenZeppelin transferFrom call to ensure transfers aren't executed when the contract is paused.
  */
  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }
  
  /**
  * @dev Returns the number of decimals used to get its user representation.
  * For example, if `decimals` equals `2`, a balance of `505` tokens should
  * be displayed to a user as `5.05` (`505 / 10 ** 2`).
  *
  * Tokens usually opt for a value of 18, imitating the relationship between
  * Ether and Wei. This is the value {ERC20} uses, unless this function is
  * overridden;
  *
  * NOTE: This information is only used for _display_ purposes: it in
  * no way affects any of the arithmetic of the contract, including
  * {IERC20-balanceOf} and {IERC20-transfer}.
  */
  function decimals() public view virtual override returns (uint8) 
  {
    return _decimals;
  }

  /** 
  * @notice Disables execution of public contract functions.
  * @dev Pausing the contract also disables trading and swapping so that when you unpause the contract
  *      you must explicitly choose to re-enable both trading and swapping to allow Plexus to clear its backlog.
  */
  function pause() public onlySystemRoles
  {
    isTradingEnabled = false;
    _pause();
  }

  /**
  *@notice Enables execution of public contract functions.
  */
  function unpause() public onlySystemRoles
  {
    _unpause();
  }

  /**
  * @notice Shows the version of the contract being used
  * @dev The value represents the current version of the contract should be updated and overridden with new implementations
  * @return version - The current version of the contract
  */
  function version() external virtual pure returns(string memory)
  {
    return "2.0.0";
  }

  /*
  Public Functions
  */

  /** 
  * @notice   Updates list of bypassed Buy Fee wallets.
  * @dev      Public function to update in-memory Buy Fee Bypassing in-memory key-value pair. 
  * @param account    - Address for which Buy Bypassing updates are ocurring for.
  * @param bypassing  - Boolean indicating whether or not bypassing is ocurring.
  */
  function bypassBuyFees(address account, bool bypassing) public whenNotPaused onlySystemRoles
  {
    require(!_isAddressDeadOrEmpty(account), "account should not be empty or dead.");
    _bypassBuyFeesList[account] = bypassing;
  }

  /** 
  * @notice   Updates list of bypassed Sell Fee wallets.
  * @dev      Public function to update in-memory Sell Fee Bypassing in-memory key-value pair. 
  * @param account    - Address for which Sell Bypassing updates are ocurring for.
  * @param bypassing  - Boolean indicating whether or not bypassing is ocurring.
  */
  function bypassSellFees(address account, bool bypassing) public whenNotPaused onlySystemRoles
  {
    require(!_isAddressDeadOrEmpty(account), "account should not be empty or dead.");
    _bypassSellFeesList[account] = bypassing;
  }

  /** 
  * @notice   Updates list of bypassed Transfer Fee wallets.
  * @dev      Public function to update in-memory Transfer Fees Bypassing in-memory key-value pair. 
  * @param account    - Address for which Transfer Bypassing updates are ocurring for.
  * @param bypassing  - Boolean indicating whether or not bypassing is ocurring.
  */
  function bypassTransferFees(address account, bool bypassing) public whenNotPaused onlySystemRoles
  {
    require(!_isAddressDeadOrEmpty(account), "account should not be empty or dead.");
    _bypassTransferFeesList[account] = bypassing;
  }

  /**
  * @notice Checks if a specific account is bypassing buy fees. 
  * @dev Public function to check if a given wallet is bypassing buy fees.
  * @param account - The account being checked for bypassing fees.
  * @return - Returns boolean that specifies if the wallet is found under the _bypassBuyFeesList list.
  */
  function isBypassingBuyFees(address account) public view returns (bool)
  {
    return _bypassBuyFeesList[account];
  }

  /**
  * @notice Checks if a specific account is bypassing sell fees. 
  * @dev Public function to check if a given wallet is bypassing sell sell.
  * @param account - The account being checked for bypassing fees.
  * @return - Returns boolean that specifies if the wallet is found under the _bypassSellFeesList list.
  */
  function isBypassingSellFees(address account) public view returns (bool)
  {
    return _bypassSellFeesList[account];
  }

  /**
  * @notice Checks if a specific account is bypassing transfer fees. 
  * @dev Public function to check if a given wallet is bypassing transfer fees.
  * @param account - The account being checked for bypassing fees.
  * @return - Returns boolean that specifies if the wallet is found under the _bypassTransferFeesList list.
  */
  function isBypassingTransferFees(address account) public view returns (bool)
  {
    return _bypassTransferFeesList[account];
  }

  /**
  * @notice Checks if a specific account is part of the deny list. 
  * @dev Public function to check if a given wallet is deny list accounts.
  * @param account - The account being checked for deny list presence.
  * @return - Returns boolean that specifies if the wallet is found under the _denyList list.
  */
  function isDeniedAddress(address account) public view returns (bool)
  {
    return _denyList[account];
  }

  /**
  * @notice Checks if a specific account is part of the denied bot list. 
  * @dev Public function to check if a given wallet is denied bot list accounts.
  * @param account - The account being checked for denied bot list presence.
  * @return - Returns boolean that specifies if the wallet is found under the _denyBotList list.
  */
  function isDeniedBotAddress(address account) public view returns (bool)
  {
    return _denyBotList[account];
  }

  /**
  * @notice Checks if a specific account is part of the internal list. 
  * @dev Public function to check if a given wallet is internal list accounts.
  * @param account - The account being checked for internal list presence.
  * @return - Returns boolean that specifies if the wallet is found under the _internalList list.
  */
  function isInternalAddress(address account) public view returns (bool)
  {
    return _internalList[account];
  }

  /** 
  * @notice Mints tokens based on the passed amount to the beneficiary account. 
  * @dev External function to mint. Made external so that mints must occur outside the contract calls.
  * @param amount     - Amount being minted.
  */
  function plexusMint(uint256 amount) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _canMint(amount * 10**_decimals);
    _mint(address(this), amount * 10**_decimals);
    _calculateAntiWhaleGuardValues();
  }

  /** 
  * @notice Transfers native currency from contract directly to the caller with a valid role.
  * @dev Withdraws native currency from this contract in case it was mistakenly sent, or needs to moved.
  * @param amount - Specific amount of native currency to be rescued from the contract.
  */
  function rescueNativeCurrency(uint256 amount) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant
  {
    // SHEPARD: Validate that the contract has enough balance to rescue native currency based on the passed amount.
    require(address(this).balance >= amount, "Insufficient balance on the contract. The amount must be less than or equal to the available balance.");

    // SHEPARD: Pattern for rescuing balances from contracts.
    address _systemAccount = payable(_msgSender());
    (bool sent, ) = _systemAccount.call{value: amount}("");

    // SHEPARD: Validate that the low-level call has been succesfully completed.
    require(sent, "Unable to rescue the specified amount.");

    emit NativeCurrencyRescued(_systemAccount, amount);
  }

  /** 
  * @notice Transfers all tokens of a specified token address from the contract to the caller with a valid role.
  * @dev Withdraws ERC20Upgradeable tokens from this contract in case it was mistakenly sent or needs to moved.
  * @param tokenAddress - address of token to be withdrawn
  */
  function rescueTokens(address tokenAddress) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant
  {
    // SHEPARD: Retrieve the available tokens
    uint256 _amount = ERC20Upgradeable(tokenAddress).balanceOf(address(this));
    address _systemAccount = payable(_msgSender());

    // SHEPARD: Conduct transfer from contract to systemAccount.
    ERC20Upgradeable(tokenAddress).transfer(_systemAccount, _amount);

    emit TokensRescued(_systemAccount, tokenAddress, _amount);
  }

  /**
  * @notice Sets the router address for the contract and connects the new router address to a pair.
  * @dev External function to modify the router for the existing pair. 
  * @param newRouterAddress - The account being checked for bypassing fees.
  */
  function setRouterAddress(address newRouterAddress) external onlyAdminRoles
  {
    // SHEPARD: If the new address is not null, then confirm the newRouterAddress is different than the old one.
    if (address(uniswapV2Router) != address(0))
    {
      require(newRouterAddress != address(uniswapV2Router), "newRouterAddress must be different than uniswapV2Router.");
    }

    // SHEPARD: Now, if the newRouterAddress is empty or dead, fail to update the Router address.
    require(!_isAddressDeadOrEmpty(address(uniswapV2Router)), "newRouterAddress must not be dead or empty.");

    uniswapV2Router = IUniswapV2Router02(newRouterAddress);

    // MASTERJEDI: Check to see if the pair already exists before creating a new one.
    address existingPair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
    if (existingPair == address(0))
    {
      uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }
    else 
    {
      uniswapV2Pair = existingPair;
    }
  }

  /**
  * @notice   Transfers ERC-20 tokens, including fees.
  * @dev      This method is typically called when native currency is exchanged for this ERC-20 token (AKA a Buy), or inter-wallet transfers.
  * @param to         - The destination wallet address.
  * @param amount     - The number of ERC-20 tokens being transferred.
  */
  function transfer(address to, uint256 amount) public virtual override whenNotPaused returns (bool) 
  {
    address owner = _msgSender();
    _transferInternal(owner, to, amount);
    return true;
  }

  /**
  * @notice   Transfers ERC-20 tokens, including fees, on behalf of another wallet.
  * @dev      This method is typically called when this ERC-20 token is exchanged for native currency (AKA a Sell).
  * @param from       - The source wallet address.
  * @param to         - The destination wallet address.
  * @param amount     - The number of ERC-20 tokens being transferred.
  */
  function transferFrom(address from, address to, uint256 amount) public virtual override whenNotPaused returns (bool)
  {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    _transferInternal(from, to, amount);
    return true;
  }

  /**
  * @notice   Updates the safeGuard structures used for contract-wide anti-whale values.
  * @dev      Updates public structs for Anti-Whale Fees all at once. 
  * @param maxWalletPercent     - The maximum size of any wallet, given as a percent of the total supply. (ex: 10 = 1.0% or 25 = 2.5%)
  * @param maxBuyPercent        - The maximum size of any purchase, given as a percent of the total supply. (ex: 10 = 1.0% or 25 = 2.5%)
  * @param maxSellPercent       - The maximum size of any sell, given as a percent of the total supply. (ex: 10 = 1.0% or 25 = 2.5%)
  */
  function updateAntiWhaleGuards(uint256 maxWalletPercent, uint256 maxBuyPercent , uint256 maxSellPercent) public whenNotPaused onlySystemRoles
  {
    // SHEPARD: Validates that safeguards for maxWalletPercent are greater than 1% of the max supply and less than 100%.
    require(maxWalletPercent >= 10 && maxWalletPercent <= 1000, "maxWalletPercent cannot less than 1% or greater than 100%.");
    // SHEPARD: Validate Multiply Values for both Buy and Sell Maxes.
    require(maxBuyPercent >= 1 && maxBuyPercent <= 1000, "maxBuyPercent cannot less than 0.1% or greater than 100%.");
    require(maxSellPercent >= 1 && maxSellPercent <= 1000, "maxSellPercent cannot less than 0.1% or greater than 100%.");

    // SHEPARD: Ensure that you cannot buy or sell more than a single wallet can hold.
    require(maxBuyPercent <= maxWalletPercent, "maxBuyPercent must not exceed maxWalletPercent.");
    require(maxSellPercent <= maxWalletPercent, "maxSellPercent must not exceed maxWalletPercent.");

    antiWhaleGuardRates.maxWalletAmount = maxWalletPercent;
    antiWhaleGuardRates.maxBuyAmount = maxBuyPercent;
    antiWhaleGuardRates.maxSellAmount = maxSellPercent;

    // SHEPARD: Go re-calculate the AntiWhaleGuardValues with the new rates applied.    
    _calculateAntiWhaleGuardValues();
  }

  /**
  * @notice   Updates the Buy Fee structures used for contract-wide calculations.
  * @dev      Updates public structs for Buy Fees all at once. 
  * @param liquidityFee     - Liquidity Fee.
  * @param marketingFee     - Marketing Fee.
  * @param operationsFee    - Operations Fee.
  */
  function updateBuyFees(uint256 liquidityFee, uint256 marketingFee, uint256 operationsFee) public whenNotPaused onlySystemRoles
  {
    // SHEPARD/SENSEI: Validate that none of the fee settings are above 250 individually.
    require(liquidityFee <= 250 && marketingFee <= 250 && operationsFee <= 250, "Individual fee rates cannot exceed 25%.");
    // SHEPARD/SENSEI: Validate that the total sum of all fee values are not above or below 250.
    require(liquidityFee + marketingFee + operationsFee <= 250, "Combined fees cannot exceed 25%.");

    // SHEPARD: Assign values to Buy Fee Rates struct properties.
    buyFeeRates.liquidityFee = liquidityFee;
    buyFeeRates.marketingFee = marketingFee;
    buyFeeRates.operationsFee = operationsFee;

    emit BuyFeesChanged(liquidityFee, marketingFee, operationsFee, block.timestamp);
  }

  /** 
  * @notice   Updates list of denied wallets.
  * @dev      Public function to update in-memory key-value pair list for bot wallets. 
  * @param account    - Address for a bot wallet.
  * @param active     - Boolean indicating whether or not the wallet is active.
  */
  function updateDeniedBotList(address account, bool active) public whenNotPaused onlySystemRoles
  {
    require(!_isAddressDeadOrEmpty(account), "account must not be dead or empty.");
    _denyBotList[account] = active;
  }

  /** 
  * @notice   Updates list of denied wallets.
  * @dev      Public function to update in-memory key-value pair list for denied wallets. 
  * @param account    - Address for a denied wallet.
  * @param active     - Boolean indicating whether or not the wallet is active.
  */
  function updateDeniedList(address account, bool active) public whenNotPaused onlySystemRoles
  {
    require(!_isAddressDeadOrEmpty(account), "account must not be dead or empty.");
    _denyList[account] = active;
  }

  /** 
  * @notice   Updates list of internal wallets.
  * @dev      Public function to update in-memory key-value pair list for internal wallets. 
  * @param account    - Address for a internal wallet.
  * @param active     - Boolean indicating whether or not the wallet is active.
  */
  function updateInternalList(address account, bool active) public whenNotPaused onlySystemRoles
  {
    require(!_isAddressDeadOrEmpty(account), "account must not be dead or empty.");
    _internalList[account] = active;
  }

  /**
  * @notice Updates the current Liquidity Wallet.
  * @dev The Liquidity Wallet can be change and therefore the public member must be configurable.
  *      This wallet can only be updated by the DEFAULT_ADMIN_ROLE role.
  * @param newWalletAddress - The new wallet the liquidity wallet will represent.
  */
  function updateLiquidityWalletAddress(address newWalletAddress) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(!_isAddressDeadOrEmpty(newWalletAddress), "newWalletAddress must not be dead or empty.");
    require(liquidityWalletAddress != newWalletAddress , "newWalletAddress must be different than liquidityWalletAddress.");
    // SHEPARD: Immediately deny the old wallet and add the new wallet to all bypass and internal lists. 
    _bypassAllFees(liquidityWalletAddress, false);
    updateInternalList(liquidityWalletAddress, false);
    _bypassAllFees(newWalletAddress, true);
    updateInternalList(newWalletAddress, true);

    // SHEPARD: Replace the public member with the new wallet value. 
    liquidityWalletAddress = newWalletAddress;
  }

    /**
  * @notice Updates the current Marketing Wallet.
  * @dev The Marketing Wallet can be change and therefore the public member must be configurable.
  *      This wallet can only be updated by the DEFAULT_ADMIN_ROLE role.
  * @param newWalletAddress - The new wallet the marketing wallet will represent.
  */
  function updateMarketingWalletAddress(address newWalletAddress) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(!_isAddressDeadOrEmpty(newWalletAddress), "newWalletAddress must not be dead or empty.");
    require(marketingWalletAddress != newWalletAddress , "newWalletAddress must be different than marketingWalletAddress.");
    // SHEPARD: Immediately deny the old wallet and add the new wallet to all bypass lists. 
    _bypassAllFees(marketingWalletAddress, false);
    updateInternalList(marketingWalletAddress, false);
    _bypassAllFees(newWalletAddress, true);
    updateInternalList(newWalletAddress, true);

    // SHEPARD: Replace the public member with the new wallet value.
    marketingWalletAddress = newWalletAddress;
  }

  /**
  * @notice Updates the maxTokenAllocation value based on the passed parameter.
  * @dev We have validation to prevent the maxAllocation value from being too low or from exceeding Lunar per-chain limit.
  * @param maxAllocation - A uint256 that is greater than the current supply and less than the Lunar per-chain limit.
  */
  function updateMaxTokenAllocation(uint256 maxAllocation) external whenNotPaused onlyPlexusRoles
  {
    require(maxAllocation > 0 && maxAllocation * 10**_decimals > totalSupply(), "maxAllocation must be greater than both zero and totalSupply.");
    maxTokenAllocation = maxAllocation * 10**_decimals;
  }

  /**
  * @notice Updates the current Operations Wallet.
  * @dev The Operations Wallet can be change and therefore the public member must be configurable.
  *      This wallet can only be updated by the DEFAULT_ADMIN_ROLE role.
  * @param newWalletAddress - The new wallet the operations wallet will represent.
  */
  function updateOperationsWalletAddress(address newWalletAddress) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(!_isAddressDeadOrEmpty(newWalletAddress), "newWalletAddress must not be dead or empty.");
    require(operationsWalletAddress != newWalletAddress , "newWalletAddress must be different than operationsWalletAddress.");
    // SHEPARD: Immediately deny the old wallet and add the new wallet to all bypass lists. 
    _bypassAllFees(operationsWalletAddress, false);
    updateInternalList(operationsWalletAddress, false);
    _bypassAllFees(newWalletAddress, true);
    updateInternalList(newWalletAddress, true);

    // SHEPARD: Replace the public member with the new wallet value. 
    operationsWalletAddress = newWalletAddress;
  }

  /**
  * @notice   Updates the Sell Fee structures used for contract-wide calculations.
  * @dev      Updates public structs for Sell Fees all at once. 
  * @param liquidityFee     - Liquidity Fee.
  * @param marketingFee     - Marketing Fee.
  * @param operationsFee    - Operations Fee.
  */
  function updateSellFees(uint256 liquidityFee, uint256 marketingFee, uint256 operationsFee) public whenNotPaused onlySystemRoles
  {
    // SHEPARD/SENSEI: Validate that none of the fee settings are above 250 individually.
    require(liquidityFee <= 250 && marketingFee <= 250 && operationsFee <= 250, "Individual fee rates cannot exceed 25%.");
    // SHEPARD/SENSEI: Validate that the total sum of all fee values are not above or below 250.
    require(liquidityFee + marketingFee + operationsFee <= 250, "Combined fees cannot exceed 25%.");
    
    // SHEPARD: Assign values to Sell Fee Rates struct properties.
    sellFeeRates.liquidityFee = liquidityFee;
    sellFeeRates.marketingFee = marketingFee;
    sellFeeRates.operationsFee = operationsFee;

    emit SellFeesChanged(liquidityFee, marketingFee, operationsFee, block.timestamp);
  }

  /**
  * @notice   Updates the isTradingEnabled flag based on the boolean value being passed.
  * @dev      Updates the individual boolean flag for trading, represented as public member.
  * @param enableTradesFlag - boolean value determining if trading is enabled or disabled.
  */
  function updateTradingEnabled(bool enableTradesFlag) external whenNotPaused onlyPlexusRoles 
  {
    isTradingEnabled = enableTradesFlag;
    emit TradingEnabled(enableTradesFlag, block.timestamp);
  }

  /**
  * @notice   Updates the Transfer Fee structures used for contract-wide calculations.
  * @dev      Updates public structs for Transfer Fees all at once. 
  * @param liquidityFee     - Liquidity Fee.
  * @param marketingFee     - Marketing Fee.
  * @param operationsFee    - Operations Fee.
  */
  function updateTransferFees(uint256 liquidityFee, uint256 marketingFee, uint256 operationsFee) public whenNotPaused onlySystemRoles
  {
    // SHEPARD/SENSEI: Validate that none of the fee settings are above 250 individually.
    require(liquidityFee <= 250 && marketingFee <= 250 &&  operationsFee <= 250, "Individual fee rates cannot exceed 25%.");
    // SHEPARD/SENSEI: Validate that the total sum of all fee values are not above or below 250.
    require(liquidityFee + marketingFee + operationsFee <= 250, "Combined fees cannot exceed 25%.");

    // SHEPARD: Assign values to Transfer Fee Rates struct properties.
    transferFeeRates.liquidityFee = liquidityFee;
    transferFeeRates.marketingFee = marketingFee;
    transferFeeRates.operationsFee = operationsFee;

    emit TransferFeesChanged(liquidityFee, marketingFee, operationsFee, block.timestamp);
  }

  /*
  Private Functions
  */

  /** 
  * @notice Bypasses fee lists for a specific account.
  * @dev Immediate bypassing of fees by updating ever identified fee list. 
  * @param account      - The account being bypassed for fees.
  * @param bypassing    - Boolean indicating whether or not bypassing is ocurring.
  */
  function _bypassAllFees(address account, bool bypassing) private
  {
    // SHEPARD: Bypasses all identified bypassFeeLists.
    _bypassTransferFeesList[account] = bypassing;
    _bypassBuyFeesList[account] = bypassing;
    _bypassSellFeesList[account] = bypassing;
  }

  /** 
  * @notice System wide check to see if minting can occur against the contract. 
  * @dev Private check
  */
  function _canMint(uint256 amountToMint) internal view
  {
    //Check if the current tokenSupply is less than the max number of tokens that can be mined.
    uint256 mintableTokensLeft = maxTokenAllocation - totalSupply();
    require(mintableTokensLeft > 0, "maxTokenAllocation has been reached.");
    require(amountToMint + totalSupply() <= maxTokenAllocation,  string.concat("amountToMint + totalSupply is greater than maxTokenAllocation. Adjust amountToMint to be less than ", StringsUpgradeable.toString(mintableTokensLeft)));
  }
  
  /** 
  * @notice Check if a transfer can occur between two wallets given the Transaction Type.
  * @dev Private Method to check if the specific wallet can execute a transfer.
  *      The logic here must be separated out between Sender and Recipient to allow proper testing.
  * @param from       - The destination wallet address.
  * @param to         - The destination wallet address.
  * @param amount     - The number of ERC-20 tokens being transferred.
  */
  function _canSenderTransfer(address from, address to, uint256 amount, TransactionType transactionType) internal view
  {
    
    // SHEPARD: Check if anti-whale guards are being skipped. Should skip guards for
    //          Anyone recipient in Internal and any burn wallet recipient. 
    if (_internalList[from] || _internalList[to] || _isAddressDeadOrEmpty(to))
    {
      return;
    }

    /* 
      SHEPARD: Check if our anti-whale guards are being breach. (haha, puns).
      This includes Transfer, Buy & Sell anti-whale guards.
    */
    // SHEPARD: Check if the Max Sell is being exceeded.
    if (transactionType == TransactionType.SELL)
    {
      require(amount <= antiWhaleGuardCalculated.maxSellAmount, string.concat("The amount you are trying to sell is greater than what we allow in any single transaction. Please adjust the amount to be less than the following and try again: ", StringsUpgradeable.toString(antiWhaleGuardCalculated.maxSellAmount)));
      return;
    }

    // SHEPARD: Check if the Max Buy is being exceeded.
    if (transactionType == TransactionType.BUY)
    {
      require(amount <= antiWhaleGuardCalculated.maxBuyAmount, string.concat("The amount you are trying to buy is greater than what we allow in any single transaction. Please adjust the amount to be less than the following and try again: ", StringsUpgradeable.toString(antiWhaleGuardCalculated.maxBuyAmount)));
    }

    // SHEPARD: Check if the wallet balance would be too large for a single wallet to hold after transfer or buy.
    uint256 walletCurrentBalance = balanceOf(to);
    if (transactionType == TransactionType.BUY)
    {
      require(walletCurrentBalance + amount <= antiWhaleGuardCalculated.maxWalletAmount, string.concat("The amount are trying to buy would put your wallet over the limit we allow any single wallet to own. Please adjust the amount to be less than the following and try again: ", StringsUpgradeable.toString(antiWhaleGuardCalculated.maxWalletAmount - walletCurrentBalance)));
    }
    else
    {
      require(walletCurrentBalance + amount <= antiWhaleGuardCalculated.maxWalletAmount, string.concat("The amount are trying to transfer would put your wallet over the limit we allow any single wallet to own. Please adjust the amount to be less than the following and try again: ", StringsUpgradeable.toString(antiWhaleGuardCalculated.maxWalletAmount - walletCurrentBalance)));
    }
  }

  /** 
  * @notice System wide check to see if a transfer can occur in general. 
  * @dev Private Method to check if transfers are even possible
  */
  function _calculateAntiWhaleGuardValues() internal
  {
    uint256 currentSupply = totalSupply();

    // SHEPARD: Calculate the values to AntiWhaleGuardCalculated struct properties.
    antiWhaleGuardCalculated.maxWalletAmount = currentSupply.mul(antiWhaleGuardRates.maxWalletAmount).add(500).div(1000);
    antiWhaleGuardCalculated.maxBuyAmount =  currentSupply.mul(antiWhaleGuardRates.maxBuyAmount).add(500).div(1000);
    antiWhaleGuardCalculated.maxSellAmount = currentSupply.mul(antiWhaleGuardRates.maxSellAmount).add(500).div(1000);

    emit AntiWhaleGuardsChanged(antiWhaleGuardCalculated.maxWalletAmount,  antiWhaleGuardCalculated.maxBuyAmount, antiWhaleGuardCalculated.maxSellAmount, block.timestamp);
  }

  /** 
  * @notice System wide check to see if a transfer can occur in general. 
  * @dev Private Method to check if transfers are even possible
  * @param from       - The source wallet address.
  * @param to         - The destination wallet address.
  * @param amount     - The number of ERC-20 tokens being transferred.
  */
  function _canTransfer(address from, address to, uint256 amount) internal view
  {
    // SHEPARD: Check if the user can transfer the amount they have specified.
    require(amount > 0, "Transfer amount must be greater than zero.");

    // MASTERJEDI: The Router and therefore the Pair must be present to allow transactions to occurr.
    require(!_isAddressDeadOrEmpty(uniswapV2Pair) && !_isAddressDeadOrEmpty(address(uniswapV2Router)), "Uniswap V2 Router and Pair must be set in order to complete transactions.");
 
    // SHEPARD: Validate user is not part of any denyList. 
    require(!_denyList[to] && !_denyList[from], "The specified wallet is not allowed to execute this function.");
    require(!_denyBotList[to] && !_denyBotList[from], "What can we say except: 'Fuck you Bots'");

    // SHEPARD: Trading must be enabled to complete transfers, unless you are in the internals list.
    if (!(_internalList[from] || _internalList[to]))
    {
      require(isTradingEnabled, "Trading is currently disabled for the entire contract.");
    }
  }
    
  /**
  * @notice Returns the Transaction Details that calculate the fees and taxes across the transaction.
  * @dev    Internal function that encapsulates how we calculate what should happen during the transaction so we can capture those details in an Event. 
  * @param amount                 - The number of ERC-20 tokens being transferred.
  * @param transactionType        - The type of the transaction being executed. 
  * @return TransactionDetails    - Total Recipient to be transferred.
  */
  function _getTransactionDetails(uint256 amount, TransactionType transactionType) internal view returns (TransactionDetails memory)
  {
    if (transactionType == TransactionType.TRANSFER)
    {
      uint256 totalTransferFees = transferFeeRates.liquidityFee.add(transferFeeRates.marketingFee).add(transferFeeRates.operationsFee);

      return TransactionDetails({
        // SENSEI: adding 500 after the mul() call causes the calculation to round-up at .5 of a percent
        adjustedAmount : amount - amount.mul(totalTransferFees).add(500).div(1000),
        liquidityFee : amount.mul(transferFeeRates.liquidityFee).add(500).div(1000),
        marketingFee : amount.mul(transferFeeRates.marketingFee).add(500).div(1000),
        operationsFee : amount.mul(transferFeeRates.operationsFee).add(500).div(1000),
        shouldBypassFees : false,
        transactionType : transactionType
      });
    }
    else if (transactionType == TransactionType.BUY)
    {
      uint256 totalBuyFees = buyFeeRates.liquidityFee.add(buyFeeRates.marketingFee).add(buyFeeRates.operationsFee);

      return TransactionDetails({
        // SENSEI: adding 500 after the mul() call causes the calculation to round-up at .5 of a percent
        adjustedAmount : amount - amount.mul(totalBuyFees).add(500).div(1000),
        liquidityFee : amount.mul(buyFeeRates.liquidityFee).add(500).div(1000),
        marketingFee : amount.mul(buyFeeRates.marketingFee).add(500).div(1000),
        operationsFee : amount.mul(buyFeeRates.operationsFee).add(500).div(1000),
        shouldBypassFees : false,
        transactionType : transactionType
      });
    }
    else
    {
      uint256 totalSellFees = sellFeeRates.liquidityFee.add(sellFeeRates.marketingFee).add(sellFeeRates.operationsFee);

      return TransactionDetails({
        // SENSEI: adding 500 after the mul() call causes the calculation to round-up at .5 of a percent
        adjustedAmount : amount - amount.mul(totalSellFees).add(500).div(1000),
        liquidityFee : amount.mul(sellFeeRates.liquidityFee).add(500).div(1000),
        marketingFee : amount.mul(sellFeeRates.marketingFee).add(500).div(1000),
        operationsFee : amount.mul(sellFeeRates.operationsFee).add(500).div(1000),
        shouldBypassFees : false,
        transactionType : transactionType
      });
    }
  }

  /**
  * @notice   Returns the Transaction Type based on the 'from'/'to' being passed.
  * @dev      Internal function that determines the type of transaction based on the 'from'/'to' being passed.
  *           If none of the 'from'/'to' values are pairs, then transaction shall be considered a 'transfer'. 
  * @param from               - The source wallet address.
  * @param to                 - The destination wallet address.
  * @return TransactionType   - The type of the transaction being executed.  
  */
  function _getTransactionType(address from, address to) internal view returns (TransactionType)
  {
    // MASTERJEDI: A sell comes from the End User to the Pair.
    if ((from != uniswapV2Pair && from != address(uniswapV2Router)) && to == uniswapV2Pair)
    {
      return TransactionType.SELL;
    }
    // MASTERJEDI: A buy comes from the Pair to the End User.
    else if (from == uniswapV2Pair && (to != uniswapV2Pair && to != address(uniswapV2Router)))
    {
      return TransactionType.BUY;
    }
    // MASTERJEDI: Everything else is just a transfer.
    else
    {
      return TransactionType.TRANSFER;
    }
  }
  
  /**
  * @notice Determines if a given address is dead or empty.
  * @dev Internal function that determines whether or not a given address is dead or empty.
  * @param addressToCheck - The address to check and validate.
  * @return - Returns a boolean that specifies if the given address is dead or empty.
  */
  function _isAddressDeadOrEmpty(address addressToCheck) internal pure returns (bool)
  {
    return addressToCheck == address(0xdead) || addressToCheck == address(0);
  }

  /**
  * @notice Records the history of fees paid during the lifetime the contract.
  * @dev Internal function to track the fees paid. A single paramemter of TransactionDetails is required. 
  * @param details - Struct for TransactionDetails that contain the pre-calculated fees and adjustedTotal for a given transaction.
  */
  function _recordFeesPaidHistory(TransactionDetails memory details) private
  {
    // SHEPARD: Use addition assignment operation to increment the total fees paid history per fee type.
    contractFeesPaidHistory.totalLiquidityFeesPaid += details.liquidityFee;
    contractFeesPaidHistory.totalMarketingFeesPaid += details.marketingFee;
    contractFeesPaidHistory.totalOperationsFeesPaid += details.operationsFee;
  }

  /**
  * @notice   Transfers ERC-20 tokens, including Buy, Sell, or Transfer fees where appropriate.
  * @dev      This sits between transfer or transferFrom, and _transfer to make sure we're still leveraging the OpenZeppelin ERC-20 _transfer logic.
  * @param from       - The source wallet address.
  * @param to         - The destination wallet address.
  * @param amount     - The number of ERC-20 tokens being transferred.
  */
  function _transferInternal(address from, address to, uint256 amount) internal virtual 
  {
    // SHEPARD: Check if transfers are possible across the contract.
    _canTransfer(from, to, amount);

    // SHEPARD: Determine the transaction type of the current transfer. 
    TransactionType transactionType = _getTransactionType(from, to);

    // SHEPARD: Check if the sender can complete a transfer.
    _canSenderTransfer(from, to, amount, transactionType);

    // SHEPARD: Calculate fees and gather all values to be transferred using '_transfer' from @ERC20.
    TransactionDetails memory transactionDetails = _getTransactionDetails(amount, transactionType);

    // MASTERJEDI: Set the value for transactionDetails so it can be recorded.
    transactionDetails.shouldBypassFees = 
       (transactionType == TransactionType.TRANSFER && (_bypassTransferFeesList[from] || _bypassTransferFeesList[to])) ||
       (transactionType == TransactionType.BUY && (_bypassBuyFeesList[from] || _bypassBuyFeesList[to])) ||
       (transactionType == TransactionType.SELL && (_bypassSellFeesList[from] || _bypassSellFeesList[to]));
     
    emit TransactionDetailsCalculated(transactionDetails);

    // SHEPARD: Check if fees are bypassed, if so, transfer the original passed 'amount'.
    if (transactionDetails.shouldBypassFees) 
    {
      // Send to Recipient's Wallet
      _transfer(from, to, amount);
      return;
    }

    // SHEPARD: use @ERC20 to complete transfers.
    _transfer(from, to, transactionDetails.adjustedAmount); // Send to Recipient's Wallet

    // SHEPARD: Check if fees exist prior to executing a transfer for a given wallet.
    if (transactionDetails.liquidityFee > 0)
    {
      _transfer(from, liquidityWalletAddress, transactionDetails.liquidityFee); // Send to the Liquidity Wallet.
    }

    if (transactionDetails.marketingFee > 0)
    {
      _transfer(from, marketingWalletAddress, transactionDetails.marketingFee); // Send to the Marketing Wallet.
    }
    
    if (transactionDetails.operationsFee > 0)
    {
      _transfer(from, operationsWalletAddress, transactionDetails.operationsFee); // Send to the Operations Wallet.
    }

    // SHEPHARD: Record history of fees collected.
    _recordFeesPaidHistory(transactionDetails);
  }

  // SHEPARD: Allow for the receive() and fallback() functions to be payable and not allow reentrance.
  //          Link to research: https://ethereum.stackexchange.com/a/78374
  receive() external payable nonReentrant
  {
  }

  fallback() external payable nonReentrant
  {
  }

  /*
  Expanded Functionality
  */

  /* #This is where we must add functionality after major upgrades to maintain a valid ABI to memory space connection.*/
}