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
Solarity Defi, Inc. Copyright © 2022.

* Telegram:  https://t.me/lnrDefi
* Twitter:   https://twitter.com/LNR
* Website:   https://solarity.io/
*/

/** 
* @title A Token Smart Contract
* @author Solarity Defi, Inc. Copyright © 2022. All rights reserved.
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

  SafeGuards public antiWhaleGuards;

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
    * @param _totalSupply         - Total Token Supply.
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
    uint256   _totalSupply,
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

    // Set Max Allocation using a private member
    maxTokenAllocation = _totalSupply;

    // Set Decimals for calculations
    _decimals = _tokenDecimals;

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
    // 1) maxWalletSize, 2) maxBuyMultiplyValue, 3) maxSellMultiplyValue
    updateAntiWhaleGuards(2 * 1e6, 1, 1);

    // Set Buy and Sell Fee struct for future fee calculations.
    // marketingFee, liquidityFee, operationsFee
    updateTransferFees(0, 0, 50);
    updateBuyFees(0, 0, 50);
    updateSellFees(0, 0, 50);

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
    _canMint(amount);
    _mint(address(this), amount);
  }

  /** 
  * @notice Transfers native currency from contract directly to the caller with a valid role.
  * @dev Withdraws native currency from this contract in case it was mistakenly sent, or needs to moved.
  * @param amount - Specific amount of native currency to be rescued from the contract.
  */
  function rescueNativeCurrency(uint256 amount) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant
  {
    // SHEPARD: Validate that the contract has enough balance to rescue native currency based on the passed amount.
    require(address(this).balance >= amount, "Insufficient amount of native currency is available in the contract. The specified rescue amount must be less than or equal to the available balance.");

    // SHEPARD: Pattern for rescuing balances from contracts.
    address _systemAccount = payable(_msgSender());
    (bool sent, ) = _systemAccount.call{value: amount}("");

    // SHEPARD: Validate that the low-level call has been succesfully completed.
    require(sent, "We were unable to rescue the amount of native currency specified at this time.");

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
    // SHEPARD: If there is a router already specified, do not re-initilize the same router.
    if (address(uniswapV2Router) != address(0))
    {
      require(newRouterAddress != address(uniswapV2Router), "The new router address should not be the same as the old router address.");
    }
    
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
  * @notice   Transfers the existing  the Buy Fee structures used for contract-wide calculations.
  * @dev      Override of the existing ERC20 transfer function. 
  * @param recipient  - Where the transfer will be sent to.
  * @param amount     - The amount of the transfer being executed.
  */
  function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) 
  {
    // SHEPARD: Check if transfers are possible across the contract.
    _canTransfer(_msgSender(), recipient, amount);

    // SHEPARD: Determine the transaction type of the current transfer. 
    TransactionType transactionType = _getTransactionType(_msgSender(), recipient);

    // SHEPARD: Check if the sender can complete a transfer.
    _canSenderTransfer(recipient, amount, transactionType);

    // SHEPARD: Calculate fees and gather all values to be transferred using '_transfer' from @ERC20.
    TransactionDetails memory transactionDetails = _getTransactionDetails(amount, transactionType);

    // MASTERJEDI: Set the value for transactionDetails so it can be recorded.
    transactionDetails.shouldBypassFees = 
       (transactionType == TransactionType.TRANSFER && (_bypassTransferFeesList[_msgSender()] || _bypassTransferFeesList[recipient])) ||
       (transactionType == TransactionType.BUY && (_bypassBuyFeesList[_msgSender()] || _bypassBuyFeesList[recipient])) ||
       (transactionType == TransactionType.SELL && (_bypassSellFeesList[_msgSender()] || _bypassSellFeesList[recipient]));
     
    emit TransactionDetailsCalculated(transactionDetails);

    // SHEPARD: Check if fees are bypassed, if so, transfer the original passed 'amount'.
    if (transactionDetails.shouldBypassFees) 
    {
      // Send to Recipient's Wallet
      _transfer(_msgSender(), recipient, amount);
      return true;
    }

    // SHEPARD: use @ERC20 to complete transfers.
    _transfer(_msgSender(), recipient, transactionDetails.adjustedAmount); // Send to Recipient's Wallet

    // SHEPARD: Check if fees exist prior to executing a transfer for a given wallet.
    if (transactionDetails.liquidityFee > 0)
    {
      _transfer(_msgSender(), liquidityWalletAddress, transactionDetails.liquidityFee); // Send to the Liquidity Wallet.
    }

    if (transactionDetails.marketingFee > 0)
    {
      _transfer(_msgSender(), marketingWalletAddress, transactionDetails.marketingFee); // Send to the Marketing Wallet.
    }
    
    if (transactionDetails.operationsFee > 0)
    {
      _transfer(_msgSender(), operationsWalletAddress, transactionDetails.operationsFee); // Send to the Operations Wallet.
    }

    // SHEPHARD: Record history of fees collected.
    _recordFeesPaidHistory(transactionDetails);

    return true;
  }

  /**
  * @notice   Updates the safeGuard structures used for contract-wide anti-whale values.
  * @dev      Updates public structs for Anti-Whale Fees all at once. 
  * @param maxWalletSize          - Updated Max Wallet Size.
  * @param maxBuyMultiplyValue    - Updated Max Buy Amount Multiply Value.
  * @param maxSellMultiplyValue   - Updated Max Sell Amount Multiply Value.
  */
  function updateAntiWhaleGuards(uint256 maxWalletSize, uint256 maxBuyMultiplyValue , uint256 maxSellMultiplyValue) public whenNotPaused onlySystemRoles
  {
    // SHEPARD: Validates that safe guards for maxWalletSize, greater than 0 and less than the allocation, are being met.
    require(maxWalletSize > 0, "The Max Wallet Size must be greater than 0.");
    // SHEPARD: Validate Multiply Values for both Buy and Sell Maxes.
    require(maxBuyMultiplyValue > 0 && maxBuyMultiplyValue <= 100, "The Max Buy Multiply Value must be greater than 0 and must not exceed 100.");
    require(maxSellMultiplyValue > 0 && maxSellMultiplyValue <= 100, "The Max Sell Multiply Value must be greater than 0 and must not exceed 100.");

    // Set local variables
    uint256 currentSupply = totalSupply();
    // SHEPARD: Assign values to antiWhaleGuards struct properties.
    antiWhaleGuards.maxWalletAmount = maxWalletSize * 10**_decimals;
    antiWhaleGuards.maxBuyAmount =  currentSupply.mul(maxBuyMultiplyValue).div(100);
    antiWhaleGuards.maxSellAmount = currentSupply.mul(maxSellMultiplyValue).div(100);

    emit AntiWhaleGuardsChanged(antiWhaleGuards.maxWalletAmount,  antiWhaleGuards.maxBuyAmount, antiWhaleGuards.maxSellAmount, block.timestamp);
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
    // SHEPARD/SENSEI: Validate that none of the fee settings are above 1000 individually.
    require(liquidityFee <= 1000 && marketingFee <= 1000 && operationsFee <= 1000, "One of the fees passed is greater 1000 (100%). Individual fee rates cannot exceed 100%.");
    // SHEPARD/SENSEI: Validate that the total sum of all fee values are not above or below 1000.
    require(liquidityFee + marketingFee + operationsFee <= 1000, "The sum of all fees is greater than 1000. Combined fees must not exceed 100%.");

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
    require(liquidityWalletAddress != newWalletAddress , "The new wallet address cannot be equivalent current wallet address.");
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
    require(marketingWalletAddress != newWalletAddress , "The new wallet address cannot be equivalent current wallet address.");
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
  * @dev We have validation to prevent the maxAllocation value from being too low or from exceeding Solarity per-chain limit.
  * @param maxAllocation - A uint256 that is greater than the current supply and less than the Solarity per-chain limit.
  */
  function updateMaxTokenAllocation(uint256 maxAllocation) external whenNotPaused onlyPlexusRoles
  {
    require(maxAllocation > 0 && maxAllocation > totalSupply(), "The specified maxAllocation must be greater than zero (0) and also greater than the number of tokens already issued.");
    maxTokenAllocation = maxAllocation;
  }

  /**
  * @notice Updates the current Operations Wallet.
  * @dev The Operations Wallet can be change and therefore the public member must be configurable.
  *      This wallet can only be updated by the DEFAULT_ADMIN_ROLE role.
  * @param newWalletAddress - The new wallet the operations wallet will represent.
  */
  function updateOperationsWalletAddress(address newWalletAddress) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(operationsWalletAddress != newWalletAddress , "The new wallet address cannot be equivalent current wallet address.");
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
    // SHEPARD/SENSEI: Validate that none of the fee settings are above 1000 individually.
    require(liquidityFee <= 1000 && marketingFee <= 1000 && operationsFee <= 1000, "One of the fees passed is greater 1000 (100%). Individual fee rates cannot exceed 100%.");
    // SHEPARD/SENSEI: Validate that the total sum of all fee values are not above or below 1000.
    require(liquidityFee + marketingFee + operationsFee <= 1000, "The sum of all fees is greater than 1000. Combined fees must not exceed 100%.");
    
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
    // SHEPARD/SENSEI: Validate that none of the fee settings are above 1000 individually.
    require(liquidityFee <= 1000 && marketingFee <= 1000 &&  operationsFee <= 1000, "One of the fees passed is greater 1000 (100%). Individual fee rates cannot exceed 100%.");
    // SHEPARD/SENSEI: Validate that the total sum of all fee values are not above or below 1000.
    require(liquidityFee + marketingFee + operationsFee <= 1000, "The sum of all fees is greater than 1000. Combined fees must not exceed 100%.");

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
  function _bypassAllFees(address account,  bool bypassing) private
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
    require(mintableTokensLeft > 0, "The contract has reached the max allocation of tokens that can minted. Please increase the Max Token Allocation and try again.");
    require(amountToMint + totalSupply() <= maxTokenAllocation,  string.concat("The amount you are trying to mint would surpass the Max Token Allocation. Please adjust the amount to be less than the following and try again: ", StringsUpgradeable.toString(mintableTokensLeft)));
  }

  /** 
  * @notice Check if a transfer can occur between two wallets given the Transaction Type.
  * @dev Private Method to check if the specific wallet can execute a transfer.
  * @param to           - The wallet address receiving the transfer. 
  * @param amount       - The amount of the transfer being executed.
  */
  function _canSenderTransfer(address to, uint256 amount, TransactionType transactionType) internal view
  {
    
    // SHEPARD: Check if anti-whale guards are being skipped. Should skip guards for
    //          Anyone recipient in Internal and any burn wallet recipient. 
    if (_internalList[_msgSender()] || _internalList[to] || to == address(0) || to == address(0xdead))
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
      require(amount <= antiWhaleGuards.maxSellAmount, string.concat("The amount you are trying to sell is greater than what we allow in any single transaction. Please adjust the amount to be less than the following and try again: ", StringsUpgradeable.toString(antiWhaleGuards.maxSellAmount)));
      return;
    }

    // SHEPARD: Check if the Max Buy is being exceeded.
    if (transactionType == TransactionType.BUY)
    {
      require(amount <= antiWhaleGuards.maxBuyAmount, string.concat("The amount you are trying to buy is greater than what we allow in any single transaction. Please adjust the amount to be less than the following and try again: ", StringsUpgradeable.toString(antiWhaleGuards.maxBuyAmount)));
    }

    // SHEPARD: Check if the wallet balance would be too large for a single wallet to hold after transfer or buy.
    uint256 walletCurrentBalance = balanceOf(to);
    if (transactionType == TransactionType.BUY)
    {
      require(walletCurrentBalance + amount <= antiWhaleGuards.maxWalletAmount, string.concat("The amount are trying to buy would put your wallet over the limit we allow any single wallet to own. Please adjust the amount to be less than the following and try again: ", StringsUpgradeable.toString(antiWhaleGuards.maxWalletAmount - walletCurrentBalance)));
    }
    else
    {
      require(walletCurrentBalance + amount <= antiWhaleGuards.maxWalletAmount, string.concat("The amount are trying to transfer would put your wallet over the limit we allow any single wallet to own. Please adjust the amount to be less than the following and try again: ", StringsUpgradeable.toString(antiWhaleGuards.maxWalletAmount - walletCurrentBalance)));
    }
  }

  /** 
  * @notice System wide check to see if a transfer can occur in general. 
  * @dev Private Method to check if transfers are even possible
  * @param from         - The wallet address sending the transfer.
  * @param to           - The wallet address receiving the transfer. 
  * @param amount       - The amount of the transfer being executed.
  */
  function _canTransfer(address from, address to, uint256 amount) internal view
  {
    // SHEPARD: Check if the user can transfer the amount they have specified.
    require(amount > 0, "Transfer amount must be greater than zero.");

    // SHEPARD: Validate user is not part of any denyList. 
    require(!_denyList[to] && !_denyList[from], "The specified wallet is not allowed to execute this function.");
    require(!_denyBotList[to] && !_denyBotList[from], "What can we say except: 'Fuck you Bots'");

    // SHEPARD: Trading must be enabled to complete transfers, unless you are in the internals list.
    if (!(_internalList[from] || _internalList[to]))
    {
      require(isTradingEnabled, "Trading is currently disabled for the entire contract. Please return once trading has been enabled.");
    }
  }
    
  /**
  * @notice Returns the Transaction Details that calculate the fees and taxes across the transaction.
  * @dev    Internal function that is utilized to generate transaction details. 
  * @param amount                 - The amount of the transfer being executed.
  * @param transactionType        - The type of the transaction being executed. 
  * @return TransactionDetails    - Total Recipient to be transferred.
  */
  function _getTransactionDetails(uint256 amount, TransactionType transactionType) internal view returns (TransactionDetails memory)
  {
    if (transactionType == TransactionType.TRANSFER)
    {
      uint256 totalTransferFees = transferFeeRates.marketingFee.add(transferFeeRates.liquidityFee).add(transferFeeRates.operationsFee);
      require(totalTransferFees <= 1000, "Total of transfer fees exceed 100%.");

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
      uint256 totalBuyFees = buyFeeRates.marketingFee.add(buyFeeRates.liquidityFee).add(buyFeeRates.operationsFee);
      require(totalBuyFees <= 1000, "Total of buy fees exceed 100%.");

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
      uint256 totalSellFees = sellFeeRates.marketingFee.add(sellFeeRates.liquidityFee).add(sellFeeRates.operationsFee);
      require(totalSellFees <= 1000, "Total of sell fees exceed 100%.");

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
  * @param from               - The wallet address sending the transfer. 
  * @param to                 - The wallet address receiving the transfer. 
  * @return TransactionType   - The type of the transaction being executed.  
  */
  function _getTransactionType(address from, address to) internal view returns (TransactionType)
  {
    // MASTERJEDI: A sell comes from the Pair to the Router.
    if (from == uniswapV2Pair && to == address(uniswapV2Router))
    {
      return TransactionType.SELL;
    }
    // MASTERJEDI: A buy comes from the pair to the end user.
    else if (from == uniswapV2Pair && to != address(uniswapV2Router))
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
  * @notice Records the history of fees paid during the lifetime the contract.
  * @dev Internal Method to track the fees paid. A single paramemter of TransactionDetails is required. 
  * @param details - Struct for TransactionDetails that contain the pre-calculated fees and adjustedTotal for a given transaction.
  */
  function _recordFeesPaidHistory(TransactionDetails memory details) private
  {
    // SHEPARD: Use addition assignment operation to increment the total fees paid history per fee type.
    contractFeesPaidHistory.totalLiquidityFeesPaid += details.liquidityFee;
    contractFeesPaidHistory.totalMarketingFeesPaid += details.marketingFee;
    contractFeesPaidHistory.totalOperationsFeesPaid += details.operationsFee;
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