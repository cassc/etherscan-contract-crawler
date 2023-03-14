// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

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
Copyright © 2022-2023 Solarity Foundation All rights reserved.

* Telegram:  https://t.me/LNRDAO
* Twitter:   https://twitter.com/LNRDAO
* Website:   https://solarity.io/
*/

/** 
* @title A Token Smart Contract
* @author Copyright © 2022-2023 Solarity Foundation All rights reserved.
* @notice This is the base contract for all Solarity Tokens.
* @dev This contract is also upgradeable and contains public & private functions for a variety of use cases for official Solarity Tokens.
*/
contract Solarity is Initializable, ERC20Upgradeable, UUPSUpgradeable, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
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
  * @dev Custom Event | SafeGuardsChanged
  * @param guardType           - Central Exchange Wallets = 0; AntiWhale Wallets = 1;
  * @param maxWalletSize       - Updated Max Wallet Size.
  * @param maxBuyAmount        - Updated Max Buy Amount.
  * @param maxSellAmount       - Updated Max Sell Amount.
  * @param updatedTimestamp    - Timestamp to track when AntiWhale Guards change.
  */
  event SafeGuardsChanged(uint16 guardType, uint256 maxWalletSize, uint256 maxBuyAmount, uint256 maxSellAmount, uint256 updatedTimestamp);

  /**
  * @notice Triggered when the fee struct has been updated for buy fees.
  * @dev Custom Event | BuyFeesChanged
  * @param liquidityFee       - Updated Liquidity Fee.
  * @param marketingFee       - Updated Marketing Fee.
  * @param operationsFee      - Updated Operations Fee.
  * @param developmentFee     - Updated Development Fee.
  * @param updatedTimestamp   - Timestamp to track when Buy Fees change.
  */
  event BuyFeesChanged(uint256 liquidityFee, uint256 marketingFee, uint256 operationsFee, uint256 developmentFee, uint256 updatedTimestamp);
  
  /**
  * @notice Triggered when the fee struct has been updated for sell fees.
  * @dev Custom Event | SellFeesChanged
  * @param liquidityFee       - Updated Liquidity Fee.
  * @param marketingFee       - Updated Marketing Fee.
  * @param operationsFee      - Updated Operations Fee.
  * @param developmentFee     - Updated Development Fee.
  * @param updatedTimestamp   - Timestamp to track when Sell Fees change.
  */
  event SellFeesChanged(uint256 liquidityFee, uint256 marketingFee, uint256 operationsFee, uint256 developmentFee, uint256 updatedTimestamp);
  
  /**
  * @notice Triggered when the fee structure has been updated for transfer fees.
  * @dev Custom Event | TransferFeesChanged
  * @param liquidityFee       - Updated Liquidity Fee.
  * @param marketingFee       - Updated Marketing Fee.
  * @param operationsFee      - Updated Operations Fee.
  * @param developmentFee     - Updated Development Fee.
  * @param updatedTimestamp   - Timestamp to track when Transfer Fees change.
  */
  event TransferFeesChanged(uint256 liquidityFee, uint256 marketingFee, uint256 operationsFee, uint256 developmentFee, uint256 updatedTimestamp);

  /**
  * @notice Triggered when native currency has been rescued from the contract.
  * @dev Custom Event | NativeCurrencyMoved
  * @param adminAccount       - Wallet address from which the rescue call has been invoked.
  * @param amount             - Integer representing the amount of native currency rescued from the contract.
  */
  event NativeCurrencyMoved(address adminAccount, uint256 amount);

  /**
  * @notice Triggered when tokens of a given token address are rescued from the contract.
  * @dev Custom Event | TokensRescued
  * @param adminAccount       - The administrative wallet were rescued tokens are being sent to.
  * @param fromAddress        - The wallet where the tokens are being rescued from.
  * @param amount             - Integer representing the amount of tokens rescued from the source wallet.
  */
  event TokensRescued(address adminAccount, address fromAddress, uint256 amount);

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
  * @param details            - The TransacrionDetails object calculated during the transaction.
  */
  event TransactionDetailsCalculated(TransactionDetails details);

  /**
  * @notice Triggered when a given contract wallet is updated.
  * @dev Custom Event | ContractWalletChanged
  * @param newWalletAddress   - The new wallet address for the given wallet type.
  * @param walletType         - The given wallet type being updated. Based on a enum value.
  * @param updatedTimestamp   - Timestamp to track when the new wallet was updated.
  */
  event ContractWalletChanged(address newWalletAddress, WalletType walletType, uint256 updatedTimestamp);

  /**
  * @notice Triggered when the router address has been updated.
  * @dev Custom Event | RouterAddressChanged
  * @param routerAddress      - The new Router Address used by the uniswapV2Router.
  * @param pairAddress        - The new Router Pair Address used by the uniswapV2Pair.
  * @param updatedTimestamp   - Timestamp to track when the router pair was updated.
  */
  event RouterAddressChanged(address routerAddress, address pairAddress, uint256 updatedTimestamp);

  /**
  * @notice Triggered when tokens have been moved to an admin wallet.
  * @dev Custom Event | TokensMoved
  * @param adminAccount       - Wallet address from which the rescue call has been invoked.
  * @param amount             - Integer representing the amount of native currency rescued from the contract.
  */
  event TokensMoved(address adminAccount, uint256 amount);

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
  * @notice This structure provides the pre-calculated fees that will be used for the duration of a transaction.
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
    /** The fee calculated from FeeRates.DevelopmentFee x msg.Amount. */
    uint256 developmentFee;
    /** A boolean specifying whether or not we will be taking fees from this transaction. */
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
  * @notice This structure provides the protections to SafeGuard the contract.
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

  /* These are fees that get paid to each wallet during cross-wallet transfers. */
  FeeRates public transferFeeRates;

  /* These are fees that get paid to each wallet when a transaction is coming from the pair. */
  FeeRates public buyFeeRates;

  /* These are fees that get paid to each wallet when a transaction is going to the pair. */
  FeeRates public sellFeeRates;

  /** These are the rates set by calling updateAntiWhaleGuards(). */
  SafeGuards public antiWhaleGuardRates;

  /** 
      These are the calculated maximum wallet sizes that change from calling updateAntiWhaleGuards().
      We calculate this once instead of on every request to save on gas. 
  */
  SafeGuards public antiWhaleGuardCalculated;

  /** This is a running history of all the fees every paid. */
  FeesPaidHistory public contractFeesPaidHistory;
  
  /** 
      These are the calculated maximum wallet sizes that exchanges must adhere to. 
      We calculate these this once instead of on every request to save on gas. 
  */
  SafeGuards public exchangesGuardCalculated;
    
  /** These are the rates set by calling exchangesGuardRates(). */
  SafeGuards public exchangesGuardRates;

  /**Used to track exchange (CEX/DEX) addresses across the contract */
  mapping (address => bool) private _exchangesList;

  /* Development Wallet needed for fee calculations. */
  address public developmentWalletAddress;

  /**
  * @notice Extension of existing Structs for FeesPaidHistory
  */
  struct FeeRatesDev
  {
    /** The fee that should be taken to support development efforts. */
    uint256 developmentFee;
  }
  
  /**
 * @notice Extension of existing Structs for FeesPaidHistory
  */
  struct FeesPaidHistoryDev
  { 
    uint256 totalDevelopmentFeesPaid;
  }

  /* These are Dev fees that get paid to each wallet during cross-wallet transfers. */
  FeeRatesDev public transferFeeRatesDev;

  /* These are Dev fees that get paid to each wallet when a transaction is coming from the pair. */
  FeeRatesDev public buyFeeRatesDev;

  /* These are Dev fees that get paid to each wallet when a transaction is going to the pair. */
  FeeRatesDev public sellFeeRatesDev;
  
  /** This is a running history of all the fees every paid. */
  FeesPaidHistoryDev public contractFeesPaidHistoryDev;

  /// DEVELOPMENT   =   0 
  /// LIQUIDITY     =   1 
  /// MARKETING     =   2 
  /// OPERATIONS    =   3
  enum WalletType 
  {
    DEVELOPMENT,
    LIQUIDITY,
    MARKETING,
    OPERATIONS
  }

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
    * @param _developmentAddress  - Collects funds for all development efforts.
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
    address   _operationsAddress,
    address   _developmentAddress) public initializer
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
    developmentWalletAddress = _developmentAddress;

    // Grant initial roles
    _grantRole(DEPLOYER_ROLE, msg.sender);
    _grantRole(DEFAULT_ADMIN_ROLE, _adminAddress);
    _grantRole(TRANSACTION_ROLE, _transactionAddress);

    // Add initial wallets to _internalList List.
    updateInternalList(_adminAddress, true);
    updateInternalList(_transactionAddress, true);
    updateInternalList(_liquidityAddress, true);
    updateInternalList(_operationsAddress, true);
    updateInternalList(_developmentAddress, true);

    // Set initial SafeGuards for Anti-Whale & Exchanges checks.
    updateAntiWhaleGuards(10, 10, 10, 0); // CEX / DEX
    updateAntiWhaleGuards(10, 10, 10, 1); // AntiWhales

    // Set Buy and Sell Fee struct for future fee calculations.
    // liquidityFee, marketingFee, operationsFee, developmentFee
    updateTransferFees(0, 0, 0, 0);
    updateBuyFees(0, 0, 60, 0);
    updateSellFees(0, 0, 60, 0);

    // Bypass Transfer, Buy and Sell fees across all initial wallets.
    _bypassAllFees(_adminAddress, true);
    _bypassAllFees(_transactionAddress, true);
    _bypassAllFees(_liquidityAddress, true);
    _bypassAllFees(_operationsAddress, true);
    _bypassAllFees(_developmentAddress, true);

    // Pause the contract on initialization.
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
    require(hasRole(TRANSACTION_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Wallet cannot execute function.");
    // SHEPARD: This line matters for modifiers, don't take it out!
    _;
  }

  /**
  * @dev Modifier to ensure that only System roles can make function calls.
  */
  modifier onlySystemRoles() 
  {
    // SHEPARD: Check if sender has the correct role.
    require(hasRole(DEPLOYER_ROLE, msg.sender) || hasRole(TRANSACTION_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Wallet cannot execute function.");
    // SHEPARD: This line matters for modifiers, don't take it out!
    _;
  }

  /**
  * @dev Modifier to ensure that only administrative roles can make function calls.
  */
  modifier onlyAdminRoles() 
  {
    // SHEPARD: Check if sender has the correct role.
    require(hasRole(DEPLOYER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Wallet cannot execute function.");
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
  * @dev This function is called during upgrade by using OpenZeppelin upgrade resources during deployment of new implementation 
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
  * @param account    - The wallet address to create or edit a bypass record for.
  * @param bypassing  - Boolean indicating whether or not buyer fees should be assessed for the specified wallet.
  */
  function bypassBuyFees(address account, bool bypassing) public whenNotPaused onlySystemRoles
  {
    require(!_isAddressDeadOrEmpty(account), "account can't be dead or empty.");
    _bypassBuyFeesList[account] = bypassing;
  }

  /** 
  * @notice   Updates list of bypassed Sell Fee wallets.
  * @dev      Public function to update in-memory Sell Fee Bypassing in-memory key-value pair. 
  * @param account    - The wallet address to create or edit a bypass record for.
  * @param bypassing  - Boolean indicating whether or not seller fees should be assessed for the specified wallet.
  */
  function bypassSellFees(address account, bool bypassing) public whenNotPaused onlySystemRoles
  {
    require(!_isAddressDeadOrEmpty(account), "account can't be dead or empty.");
    _bypassSellFeesList[account] = bypassing;
  }

  /** 
  * @notice   Updates list of bypassed Transfer Fee wallets.
  * @dev      Public function to update in-memory Transfer Fees Bypassing in-memory key-value pair. 
  * @param account    - The wallet address to create or edit a bypass record for.
  * @param bypassing  - Boolean indicating whether or not transfer fees should be assessed for the specified wallet.
  */
  function bypassTransferFees(address account, bool bypassing) public whenNotPaused onlySystemRoles
  {
    require(!_isAddressDeadOrEmpty(account), "account can't be dead or empty.");
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
  * @dev Public function to check if a given wallet is bypassing sell fees.
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
  * @notice Mints tokens to the specified destination wallet and recalculates the SafeGuards values for both exchange wallets and anti-whale protections.
  * @dev External function to mint. Made external so that mints must occur outside the contract calls.
  * @param amount                 - Amount of tokens being minted.
  * @param destinationAddress     - The destiniation address were the minted tokens are set to.
  */
  function plexusMint(uint256 amount, address destinationAddress) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _canMint(amount * 10**_decimals);
    _mint(destinationAddress, amount * 10**_decimals);
    //SHEPARD: Because we have modified the supply, we must re-calculate the SafeGuardValues for anti-whales and exchanges.
    _calculateAntiWhaleGuardValues(0);
    _calculateAntiWhaleGuardValues(1);
  }

  /** 
  * @notice Moves the specified amount of blockchain-native currency stored on the contract to the admin wallet that is calling the function.
  * @dev Because we're moving a token that is not native to this contract, this method invokes a low-level call to move the tokens to the calling wallet.
  * @param amount - Specific amount of native currency to be rescued from the contract.
  */
  function moveNativeCurrency(uint256 amount) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant
  {
    // SHEPARD: Validate that the contract has enough balance to rescue native currency based on the passed amount.
    require(address(this).balance >= amount, "Insufficient balance.");

    // SHEPARD: Pattern for rescuing balances from contracts.
    address _adminWallet = payable(_msgSender());
    (bool sent, ) = _adminWallet.call{value: amount}("");

    // SHEPARD: Validate that the low-level call has completed succesfully.
    require(sent, "Unable to rescue amount.");

    emit NativeCurrencyMoved(_adminWallet, amount);
  }

  /** 
  * @notice Transfers contract tokens from the specified address to the admin wallet.
  * @dev This can be utilized in an emergency to recover stolen tokens.
  * @param fromAddress - address of the wallet to recover tokens from.
  */
  function rescueTokens(address fromAddress) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant
  {
    // SHEPARD: The recovery of tokens shall be restricted to foreign tokens and shall confirm balance is available to transfer.
    require(fromAddress != address(this), "Use EOA transfer.");
    require(balanceOf(fromAddress) > 0, "No balance available.");

    // SHEPARD: Retrieve the available tokens based on the balance. 
    uint256 _amount = balanceOf(fromAddress);
    address _adminWallet = payable(_msgSender());

    // SHEPARD: Conduct transfer from source wallet to administrator wallet.
    _transfer(fromAddress, _adminWallet, _amount);

    emit TokensRescued(_adminWallet, fromAddress, _amount);
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
      require(newRouterAddress != address(uniswapV2Router), "address must be new.");
    }

    // SHEPARD: Now, if the newRouterAddress is empty or dead, fail to update the Router address.
    require(!_isAddressDeadOrEmpty(newRouterAddress), "address must not be dead or empty.");

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

    emit RouterAddressChanged(address(uniswapV2Router), uniswapV2Pair, block.timestamp);
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
  * @notice   Updates the SafeGuards structures used for contract-wide anti-whale values.
  * @dev      Updates public structs for Anti-Whale Fees all at once. 
  * @param maxWalletPercent     - The maximum size of any wallet, given as a percent of the total supply. (ex: 10 = 1.0% or 25 = 2.5%)
  * @param maxBuyPercent        - The maximum size of any purchase, given as a percent of the total supply. (ex: 10 = 1.0% or 25 = 2.5%)
  * @param maxSellPercent       - The maximum size of any sell, given as a percent of the total supply. (ex: 10 = 1.0% or 25 = 2.5%)
  */
  function updateAntiWhaleGuards(uint256 maxWalletPercent, uint256 maxBuyPercent, uint256 maxSellPercent, uint16 guardType) public whenNotPaused onlySystemRoles
  {
    // SHEPARD: Validates that safeguards for maxWalletPercent are greater than 1% of the max supply and less than 100%.
    require(maxWalletPercent >= 10 && maxWalletPercent <= 1000, "maxWalletPercent: 1% - 100%");
    
    // SHEPARD: Validate Multiply Values for both Buy and Sell Maxes.
    require(maxBuyPercent >= 1 && maxBuyPercent <= 1000, "maxBuyPercent: 0.1% - 100%");
    require(maxSellPercent >= 1 && maxSellPercent <= 1000, "maxSellPercent: 0.1% - 100%");

    // SHEPARD: Ensure that you cannot buy or sell more than a single wallet can hold.
    require(maxBuyPercent <= maxWalletPercent, "maxBuyPercent too high.");
    require(maxSellPercent <= maxWalletPercent, "maxSellPercent too high.");

    // SHEPARD: Determine the rates that are being set, and then set them accordingly.
    if( guardType == 0)
    {
      exchangesGuardRates.maxWalletAmount = maxWalletPercent;
      exchangesGuardRates.maxBuyAmount = maxBuyPercent;
      exchangesGuardRates.maxSellAmount = maxSellPercent;
    }
    else
    {
      antiWhaleGuardRates.maxWalletAmount = maxWalletPercent;
      antiWhaleGuardRates.maxBuyAmount = maxBuyPercent;
      antiWhaleGuardRates.maxSellAmount = maxSellPercent;
    }

    // SHEPARD: Go re-calculate the AntiWhaleGuardValues with the new rates applied.    
    _calculateAntiWhaleGuardValues(guardType);
  }

  /**
  * @notice   Updates the Buy Fee structures used for contract-wide calculations.
  * @dev      Updates public structs for Buy Fees all at once. 
  * @param liquidityFee     - Liquidity Fee.
  * @param marketingFee     - Marketing Fee.
  * @param operationsFee    - Operations Fee.
  * @param developmentFee   - Development Fee.
  */
  function updateBuyFees(uint256 liquidityFee, uint256 marketingFee, uint256 operationsFee, uint256 developmentFee) public whenNotPaused onlySystemRoles
  {
    // SHEPARD/SENSEI: Validate that none of the fee settings are above 250 individually.
    require(liquidityFee <= 250 && marketingFee <= 250 && operationsFee <= 250 && developmentFee <= 250, "Each fee must be < 25%.");
    // SHEPARD/SENSEI: Validate that the total sum of all fee values are not above or below 250.
    require(liquidityFee + marketingFee + operationsFee + developmentFee <= 250, "Total must be < 25%.");

    // SHEPARD: Assign values to Buy Fee Rates struct properties.
    buyFeeRates.liquidityFee = liquidityFee;
    buyFeeRates.marketingFee = marketingFee;
    buyFeeRates.operationsFee = operationsFee;
    buyFeeRatesDev.developmentFee = developmentFee;

    emit BuyFeesChanged(liquidityFee, marketingFee, operationsFee, developmentFee, block.timestamp);
  }

  /** 
  * @notice   Updates list of denied wallets.
  * @dev      Public function to update in-memory key-value pair list for bot wallets. 
  * @param account    - Address for a bot wallet.
  * @param active     - Boolean indicating whether or not the wallet is active.
  */
  function updateDeniedBotList(address account, bool active) public whenNotPaused onlySystemRoles
  {
    require(!_isAddressDeadOrEmpty(account), "account can't be dead or empty.");
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
    require(!_isAddressDeadOrEmpty(account), "account can't be dead or empty.");
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
    require(!_isAddressDeadOrEmpty(account), "account can't be dead or empty.");
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
    require(!_isAddressDeadOrEmpty(newWalletAddress), "address must not be dead or empty.");
    require(liquidityWalletAddress != newWalletAddress , "address must be different.");
    // SHEPARD: Immediately deny the old wallet and add the new wallet to all bypass and internal lists. 
    _bypassAllFees(liquidityWalletAddress, false);
    updateInternalList(liquidityWalletAddress, false);
    _bypassAllFees(newWalletAddress, true);
    updateInternalList(newWalletAddress, true);

    // SHEPARD: Replace the public member with the new wallet value. 
    liquidityWalletAddress = newWalletAddress;

    emit ContractWalletChanged(newWalletAddress, WalletType.LIQUIDITY, block.timestamp);
  }

    /**
  * @notice Updates the current Marketing Wallet.
  * @dev The Marketing Wallet can be change and therefore the public member must be configurable.
  *      This wallet can only be updated by the DEFAULT_ADMIN_ROLE role.
  * @param newWalletAddress - The new wallet the marketing wallet will represent.
  */
  function updateMarketingWalletAddress(address newWalletAddress) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(!_isAddressDeadOrEmpty(newWalletAddress), "address must not be dead or empty.");
    require(marketingWalletAddress != newWalletAddress , "address must be different.");
    // SHEPARD: Immediately deny the old wallet and add the new wallet to all bypass lists. 
    _bypassAllFees(marketingWalletAddress, false);
    updateInternalList(marketingWalletAddress, false);
    _bypassAllFees(newWalletAddress, true);
    updateInternalList(newWalletAddress, true);

    // SHEPARD: Replace the public member with the new wallet value.
    marketingWalletAddress = newWalletAddress;

    emit ContractWalletChanged(newWalletAddress, WalletType.MARKETING, block.timestamp);
  }

  /**
  * @notice Updates the maxTokenAllocation value based on the passed parameter.
  * @dev We have validation to prevent the maxAllocation value from being too low or from exceeding Solarity per-chain limit.
  * @param maxAllocation - A uint256 that is greater than the current supply and less than the Solarity per-chain limit.
  */
  function updateMaxTokenAllocation(uint256 maxAllocation) external whenNotPaused onlyPlexusRoles
  {
    require(maxAllocation > 0 && maxAllocation * 10**_decimals > totalSupply(), "maxAllocation must be > 0 > totalSupply.");
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
    require(!_isAddressDeadOrEmpty(newWalletAddress), "address must not be dead or empty.");
    require(operationsWalletAddress != newWalletAddress , "address must be different.");
    // SHEPARD: Immediately deny the old wallet and add the new wallet to all bypass lists. 
    _bypassAllFees(operationsWalletAddress, false);
    updateInternalList(operationsWalletAddress, false);
    _bypassAllFees(newWalletAddress, true);
    updateInternalList(newWalletAddress, true);

    // SHEPARD: Replace the public member with the new wallet value. 
    operationsWalletAddress = newWalletAddress;

    emit ContractWalletChanged(newWalletAddress, WalletType.OPERATIONS, block.timestamp);
  }

  /**
  * @notice   Updates the Sell Fee structures used for contract-wide calculations.
  * @dev      Updates public structs for Sell Fees all at once. 
  * @param liquidityFee     - Liquidity Fee.
  * @param marketingFee     - Marketing Fee.
  * @param operationsFee    - Operations Fee.
  * @param developmentFee   - Development Fee.
  */
  function updateSellFees(uint256 liquidityFee, uint256 marketingFee, uint256 operationsFee, uint256 developmentFee) public whenNotPaused onlySystemRoles
  {
    // SHEPARD/SENSEI: Validate that none of the fee settings are above 250 individually.
    require(liquidityFee <= 250 && marketingFee <= 250 && operationsFee <= 250 && developmentFee <= 250, "Each fee must be < 25%.");
    
    // SHEPARD/SENSEI: Validate that the total sum of all fee values are not above or below 250.
    require(liquidityFee + marketingFee + operationsFee + developmentFee <= 250, "Total must be < 25%.");
    
    // SHEPARD: Assign values to Sell Fee Rates struct properties.
    sellFeeRates.liquidityFee = liquidityFee;
    sellFeeRates.marketingFee = marketingFee;
    sellFeeRates.operationsFee = operationsFee;
    sellFeeRatesDev.developmentFee = developmentFee;

    emit SellFeesChanged(liquidityFee, marketingFee, operationsFee, developmentFee, block.timestamp);
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
  * @param developmentFee   - Development Fee.
  */
  function updateTransferFees(uint256 liquidityFee, uint256 marketingFee, uint256 operationsFee, uint256 developmentFee) public whenNotPaused onlySystemRoles
  {
    // SHEPARD/SENSEI: Validate that none of the fee settings are above 250 individually.
    require(liquidityFee <= 250 && marketingFee <= 250 &&  operationsFee <= 250 && developmentFee <= 250, "Each fee must be < 25%.");
    
    // SHEPARD/SENSEI: Validate that the total sum of all fee values are not above or below 250.
    require(liquidityFee + marketingFee + operationsFee + developmentFee <= 250, "Total must be < 25%.");

    // SHEPARD: Assign values to Transfer Fee Rates struct properties.
    transferFeeRates.liquidityFee = liquidityFee;
    transferFeeRates.marketingFee = marketingFee;
    transferFeeRates.operationsFee = operationsFee;
    transferFeeRatesDev.developmentFee = developmentFee;

    emit TransferFeesChanged(liquidityFee, marketingFee, operationsFee, developmentFee, block.timestamp);
  }

  /*
  Private Functions
  */

  /** 
  * @notice Bypasses fee lists for a specific account.
  * @dev Immediate bypassing of fees by updating ever identified fee list. 
  * @param account      - The account being bypassed for fees.
  * @param bypassing    - Boolean indicating whether or not bypassing is occurring.
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
    require(amountToMint + totalSupply() <= maxTokenAllocation,  string.concat("amountToMint must be <: ", StringsUpgradeable.toString(mintableTokensLeft)));
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

    SafeGuards memory currentGuardsCalculated = (_exchangesList[from] || _exchangesList[to]) ? exchangesGuardCalculated : antiWhaleGuardCalculated;

    /* 
      SHEPARD: Check if our anti-whale guards are being breached. (HAHA, get it? breached).
      This includes Transfer, Buy & Sell anti-whale guards.
    */
    // SHEPARD: Check if the Max Sell is being exceeded.
    if (transactionType == TransactionType.SELL)
    {
      require(amount <= currentGuardsCalculated.maxSellAmount && amount <= currentGuardsCalculated.maxSellAmount, string.concat("Sell amount too high. Try new amount less than: ", StringsUpgradeable.toString(currentGuardsCalculated.maxSellAmount)));
      return;
    }

    // SHEPARD: Check if the Max Buy is being exceeded.
    if (transactionType == TransactionType.BUY)
    {
      require(amount <= currentGuardsCalculated.maxBuyAmount, string.concat("Buy amount too high. Try new amount less than: ", StringsUpgradeable.toString(currentGuardsCalculated.maxBuyAmount)));
    }

    // SHEPARD: Check if the wallet balance would be too large for a single wallet to hold after transfer or buy.
    uint256 walletCurrentBalance = balanceOf(to);
    if (transactionType == TransactionType.BUY)
    {
      require(walletCurrentBalance + amount <= currentGuardsCalculated.maxWalletAmount, string.concat("Buy amount over limits. Try new amount less than: ", StringsUpgradeable.toString(currentGuardsCalculated.maxWalletAmount - walletCurrentBalance)));
    }
    else
    {
      require(walletCurrentBalance + amount <= currentGuardsCalculated.maxWalletAmount, string.concat("Transfer amount over limits. Try new amount less than: ", StringsUpgradeable.toString(currentGuardsCalculated.maxWalletAmount - walletCurrentBalance)));
    }
  }

  /** 
  * @notice Calculate the AntiWhale SafeGuards values to be used in each transaction.
  * @dev This is calculated only when they are modified, to speed up contract execution and save gas for the end-user.
  */
  function _calculateAntiWhaleGuardValues(uint16 guardType) internal
  {
    uint256 currentSupply = totalSupply();

    // SHEPARD: Determine which Calculated rates must be updated and then assign the calculated rates based on the rates previously set.
    if(guardType == 0)
    {
      exchangesGuardCalculated.maxWalletAmount = currentSupply.mul(exchangesGuardRates.maxWalletAmount).add(500).div(1000);
      exchangesGuardCalculated.maxBuyAmount =  currentSupply.mul(exchangesGuardRates.maxBuyAmount).add(500).div(1000);
      exchangesGuardCalculated.maxSellAmount = currentSupply.mul(exchangesGuardRates.maxSellAmount).add(500).div(1000);
      emit SafeGuardsChanged(guardType, exchangesGuardCalculated.maxWalletAmount, exchangesGuardCalculated.maxBuyAmount, exchangesGuardCalculated.maxSellAmount, block.timestamp);
    }
    else
    {
      antiWhaleGuardCalculated.maxWalletAmount = currentSupply.mul(antiWhaleGuardRates.maxWalletAmount).add(500).div(1000);
      antiWhaleGuardCalculated.maxBuyAmount =  currentSupply.mul(antiWhaleGuardRates.maxBuyAmount).add(500).div(1000);
      antiWhaleGuardCalculated.maxSellAmount = currentSupply.mul(antiWhaleGuardRates.maxSellAmount).add(500).div(1000);
      emit SafeGuardsChanged(guardType, antiWhaleGuardCalculated.maxWalletAmount, antiWhaleGuardCalculated.maxBuyAmount, antiWhaleGuardCalculated.maxSellAmount, block.timestamp);
    }
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
    require(amount > 0, "Transfer must be greater than zero.");

    // MASTERJEDI: The Router and therefore the Pair must be present to allow transactions to occur.
    require(!_isAddressDeadOrEmpty(uniswapV2Pair) && !_isAddressDeadOrEmpty(address(uniswapV2Router)), "Router and Pair must be set.");
 
    // SHEPARD: Validate user is not part of any denyList. 
    require(!_denyList[to] && !_denyList[from], "Wallet cannot execute function.");
    require(!_denyBotList[to] && !_denyBotList[from], "No Bots.");

    // SHEPARD: Trading must be enabled to complete transfers, unless you are in the internals list.
    if (!(_internalList[from] || _internalList[to]) && !(_exchangesList[from] || _exchangesList[to]))
    {
      require(isTradingEnabled, "Trading is disabled.");
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
      uint256 totalTransferFees = transferFeeRates.liquidityFee.add(transferFeeRates.marketingFee).add(transferFeeRates.operationsFee).add(transferFeeRatesDev.developmentFee);

      return TransactionDetails({
        // SENSEI: adding 500 after the mul() call causes the calculation to round-up at .5 of a percent
        adjustedAmount : amount - amount.mul(totalTransferFees).add(500).div(1000),
        liquidityFee : amount.mul(transferFeeRates.liquidityFee).add(500).div(1000),
        marketingFee : amount.mul(transferFeeRates.marketingFee).add(500).div(1000),
        operationsFee : amount.mul(transferFeeRates.operationsFee).add(500).div(1000),
        developmentFee : amount.mul(transferFeeRatesDev.developmentFee).add(500).div(1000),
        shouldBypassFees : false,
        transactionType : transactionType
      });
    }
    else if (transactionType == TransactionType.BUY)
    {
      uint256 totalBuyFees = buyFeeRates.liquidityFee.add(buyFeeRates.marketingFee).add(buyFeeRates.operationsFee).add(buyFeeRatesDev.developmentFee);

      return TransactionDetails({
        // SENSEI: adding 500 after the mul() call causes the calculation to round-up at .5 of a percent
        adjustedAmount : amount - amount.mul(totalBuyFees).add(500).div(1000),
        liquidityFee : amount.mul(buyFeeRates.liquidityFee).add(500).div(1000),
        marketingFee : amount.mul(buyFeeRates.marketingFee).add(500).div(1000),
        operationsFee : amount.mul(buyFeeRates.operationsFee).add(500).div(1000),
        developmentFee : amount.mul(buyFeeRatesDev.developmentFee).add(500).div(1000),
        shouldBypassFees : false,
        transactionType : transactionType
      });
    }
    else
    {
      uint256 totalSellFees = sellFeeRates.liquidityFee.add(sellFeeRates.marketingFee).add(sellFeeRates.operationsFee).add(sellFeeRatesDev.developmentFee);

      return TransactionDetails({
        // SENSEI: adding 500 after the mul() call causes the calculation to round-up at .5 of a percent
        adjustedAmount : amount - amount.mul(totalSellFees).add(500).div(1000),
        liquidityFee : amount.mul(sellFeeRates.liquidityFee).add(500).div(1000),
        marketingFee : amount.mul(sellFeeRates.marketingFee).add(500).div(1000),
        operationsFee : amount.mul(sellFeeRates.operationsFee).add(500).div(1000),
        developmentFee : amount.mul(sellFeeRatesDev.developmentFee).add(500).div(1000),
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
  * @dev Internal function to track the fees paid. A single parameter of TransactionDetails is required. 
  * @param details - Struct for TransactionDetails that contain the pre-calculated fees and adjustedTotal for a given transaction.
  */
  function _recordFeesPaidHistory(TransactionDetails memory details) private
  {
    // SHEPARD: Use addition assignment operation to increment the total fees paid history per fee type.
    contractFeesPaidHistory.totalLiquidityFeesPaid += details.liquidityFee;
    contractFeesPaidHistory.totalMarketingFeesPaid += details.marketingFee;
    contractFeesPaidHistory.totalOperationsFeesPaid += details.operationsFee;
    contractFeesPaidHistoryDev.totalDevelopmentFeesPaid += details.developmentFee;
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

    // SHEPARD: Check if fee amounts exist prior to executing a transfer for a given wallet.
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

    if (transactionDetails.developmentFee > 0)
    {
      _transfer(from, developmentWalletAddress, transactionDetails.developmentFee); // Send to the Development Wallet.
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

  /** 
  * @notice   Updates list of exchange wallets.
  * @dev      Public function to update in-memory key-value pair list for exchange wallets. 
  * @param account    - Address for a exchange wallet.
  * @param active     - Boolean indicating whether or not the wallet is active.
  */
  function updateExchangeList(address account, bool active) public whenNotPaused onlySystemRoles
  {
    require(!_isAddressDeadOrEmpty(account), "account can't be dead or empty.");
    _exchangesList[account] = active;
  }

  /**
  * @notice Checks if a specific account is considered an exchange address. 
  * @dev Public function to check if a given wallet is an exchange accounts.
  * @param account - The account being checked for exchanges list presence.
  * @return - Returns boolean that specifies if the wallet is found under the _exchangesList list.
  */
  function isExchangeAddress(address account) public view returns (bool)
  {
    return _exchangesList[account];
  }

  /**
  * @notice Updates the current Development Wallet.
  * @dev The Development Wallet can be change and therefore the public member must be configurable.
  *      This wallet can only be updated by the DEFAULT_ADMIN_ROLE role.
  * @param newWalletAddress - The new wallet the development wallet will represent.
  */
  function updateDevelopmentWalletAddress(address newWalletAddress) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(!_isAddressDeadOrEmpty(newWalletAddress), "address must not be dead or empty.");
    require(developmentWalletAddress != newWalletAddress , "address must be different.");
    /* SHEPARD: Immediately deny the old wallet and add the new wallet to all bypass and internal lists.
                Skip removal of bypass and internal lists if no wallet has ever been set.*/
    if(!_isAddressDeadOrEmpty(developmentWalletAddress))
    {
      _bypassAllFees(developmentWalletAddress, false);
      updateInternalList(developmentWalletAddress, false);
    }
    _bypassAllFees(newWalletAddress, true);
    updateInternalList(newWalletAddress, true);

    // SHEPARD: Replace the public member with the new wallet value. 
    developmentWalletAddress = newWalletAddress;

    emit ContractWalletChanged(newWalletAddress, WalletType.DEVELOPMENT, block.timestamp);
  }

  /** 
  * @notice Moves tokens from the contract to the admin wallet.
  * @dev See above.
  */
  function moveTokens() external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant
  {
    // SHEPARD: Fail if no balance would be available for this 
    require(balanceOf(address(this)) > 0, "No balance available.");

    // SHEPARD: Retrieve the tokens that reside on the contract and move them to the administrative wallet.
    uint256 _amount = balanceOf(address(this));
    address _adminWallet = payable(_msgSender());

    // SHEPARD: Conduct transfer from contract to the admin wallet.
    _transfer(address(this), _adminWallet, _amount);

    emit TokensMoved(_adminWallet, _amount);
  }


  /**
  * @dev This empty reserved space is put in place to allow future versions to add new
  * variables without shifting down storage in the inheritance chain.
  * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  */
  int256[45] private __gap;
  
}