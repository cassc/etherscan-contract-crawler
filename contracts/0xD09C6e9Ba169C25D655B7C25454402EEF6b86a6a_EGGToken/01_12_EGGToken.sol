// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './interfaces/IEGGToken.sol';
import './interfaces/IEGGTaxCalc.sol';
import './interfaces/IRandomizer.sol';
import './external/UniSwapV2/IUniswapV2Factory.sol';
import './external/UniSwapV2/IUniswapV2Router02.sol';

contract EGGToken is Context, ERC20, Ownable {
  // Events
  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
  event InitializedContract(address thisContract);

  struct TaxFeeStructure {
    address recipientAddress; // address to send fee to
    bool sendToContract; // This enables sending to above contract or not
    uint256 fee; // Percentage of tax fee
    uint256 previousFee; // Previous fee
    bool swapForEth; // if true then run swapTokensForEth
  }

  /**
   * 0 => Liquidity Fee Tax structure
   * 1 => Auto Burn Fee Tax structure
   * 2 => Dev Fee Tax structure
   * 3 => HenHouse Contract Fee Tax structure
   * 4 => DAO Fee Tax structure
   */

  TaxFeeStructure[] public taxFeeStructures;

  mapping(address => bool) private controllers; // address => allowedToCallFunctions

  mapping(address => bool) private _isExcludedFee; // Address list to exculde the tax fee when EGG transfer
  mapping(address => bool) private _isExcludedReward; // Address list to exculde the reflection reward
  address[] private _excluded; // Address array excluded from reflection

  // References
  IRandomizer public randomizer; // Reference to Randomizer
  IEGGTaxCalc public eggTaxCalc; // Reference to EGGTaxCalc
  IUniswapV2Router02 public immutable uniswapV2Router; // Ref to Router

  uint256 public totalMinted = 0; // Track the total minted amount

  uint256 public totalBurned = 0; // Track the total burned amount

  uint256 public _maxTxAmount = 4000000000 * 10**18; // Max amount avaialble for a single tx
  uint256 private numTokensSellToAddToLiquidity = 500000 * 10**18; // Minimum amount to add EGG to liquidity pool
  uint256 private globalMutiplier = 4;

  uint256 private accruedSwapTax = 0;
  address public immutable uniswapV2Pair;

  address public liquidityTokenRecipient; // Recipient Address to get liquidityToken while swapping

  // Dev wallet
  uint256 public emissionPercent = 909; // Rate for the dev emission => 9.09%. 10000 = 100%, 500 = 5%
  address public emissionsAddress; // Dev emission address to receive 9.09% of mint $EGG

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = false;

  /**
   * @dev Modifer to require the swap and liquify is alloed or not
   */

  modifier lockTheSwap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  /**
   * @dev Modifer to require _msgSender() to be a controller
   */
  modifier onlyController() {
    _isController();
    _;
  }

  // Optimize for bytecode size
  function _isController() internal view {
    require(controllers[_msgSender()], 'Only controllers');
  }

  // Tracks the last block that a caller has written to state.
  // Disallow some access to functions if they occur while a change is being written.
  mapping(address => uint256) private lastWrite;

  uint256 taxDivisor = 10; // Tax rate
  address public burnAddress = 0x000000000000000000000000000000000000dEaD;

  constructor(
    IRandomizer _randomizer,
    address sushiswapRouter,
    IEGGTaxCalc _eggTaxCalc
  ) ERC20('TFG: EGG Token', 'EGG') {
    controllers[_msgSender()] = true;
    randomizer = _randomizer;
    eggTaxCalc = _eggTaxCalc;
    emissionsAddress = _msgSender();

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(sushiswapRouter);
    // Set the rest of the contract variables
    uniswapV2Router = _uniswapV2Router;

    // Create a sushiswap pair for this new token
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

    // Exclude owner and this contract from fee
    _isExcludedFee[owner()] = true;
    _isExcludedFee[address(this)] = true;
    controllers[_msgSender()] = true;

    emit InitializedContract(address(this));
  }

  /**
   * @notice Mints EGG to a recipient.
   * @param to the recipient of the EGG
   * @param amount Amount of EGG to mint
   */

  function mint(address to, uint256 amount) external onlyController {
    uint256 tDevEmissionFee = calculateDevEmission(amount);
    _mint(to, amount);

    _mint(emissionsAddress, tDevEmissionFee);

    totalMinted = totalMinted + (amount + tDevEmissionFee);
  }

  /**
   * @notice Burn the EGG tokens from the address
   * @param _from Receipt address to mint the tokens
   * @param _amount The amount of tokens to burn
   */

  function burn(address _from, uint256 _amount) public onlyController {
    _burn(_from, _amount);
    totalBurned = totalBurned + _amount;
  }

  function transfer(address to, uint256 amount) public override returns (bool) {
    require(amount > 0, 'Transfer amount must be greater than zero');

    uint256 balanceSender = balanceOf(msg.sender);
    require(balanceSender >= amount, 'ERC20: Not enought balance for transfer');
    if (msg.sender != owner() && to != owner()) require(amount <= _maxTxAmount, 'Transfer amount exceeds maxTxAmount');

    // Is the token balance of this contract address over the min number of
    // tokens that we need to initiate a swap + liquidity lock?
    // also, don't get caught in a circular liquidity event.
    // also, don't swap & liquify if sender is uniswap pair.
    uint256 contractTokenBalance = balanceOf(address(this));
    contractTokenBalance = contractTokenBalance - accruedSwapTax;

    if (contractTokenBalance >= _maxTxAmount) {
      contractTokenBalance = _maxTxAmount;
    }

    bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;

    if (overMinTokenBalance && !inSwapAndLiquify && msg.sender != uniswapV2Pair && swapAndLiquifyEnabled) {
      contractTokenBalance = numTokensSellToAddToLiquidity;
      // Add liquidity
      swapAndLiquify(contractTokenBalance);
    }

    // Indicates if fee should be deducted from transfer

    uint256 transferAmount = amount;
    uint256 taxAmount = 0;
    // If any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFee[msg.sender] || _isExcludedFee[to]) {
      _transfer(msg.sender, to, transferAmount);
    } else {
      // Transfer Tax is applied by 50% chance
      (uint256 randomTaxRate, uint256 taxChance) = eggTaxCalc.getTaxRate(msg.sender);

      uint256 randomChance = randomizer.random() % 10000;

      if (randomChance > taxChance) {
        _transfer(msg.sender, to, transferAmount);
      } else {
        taxAmount = (amount * randomTaxRate) / 10**globalMutiplier;

        transferAmount = transferAmount - taxAmount;
        _transfer(msg.sender, to, transferAmount);
        uint256[] memory _taxFees = calculateTaxFees(taxAmount);
        distributeTax(_taxFees);
      }
    }

    // _transfer(msg.sender, burnAddress, taxAmount);

    return true;
  }

  /**
   * ██ ███    ██ ████████
   * ██ ████   ██    ██
   * ██ ██ ██  ██    ██
   * ██ ██  ██ ██    ██
   * ██ ██   ████    ██
   * This section has internal only functions
   */

  /**
   * @notice Internal call to enable an address to call controller only functions
   * @param _address the address to enable
   */
  function _addController(address _address) internal {
    controllers[_address] = true;
  }

  /**
   * @notice Exclude the account from the tax fee
   * @dev Only callable by an existing controller
   * @param account Address to exclude the tax fee
   */

  function _excludeFromFee(address account) internal {
    require(!_isExcludedFee[account], 'Account already excluded');
    _isExcludedFee[account] = true;
  }

  /**
   * ██████  ██████  ██ ██    ██  █████  ████████ ███████
   * ██   ██ ██   ██ ██ ██    ██ ██   ██    ██    ██
   * ██████  ██████  ██ ██    ██ ███████    ██    █████
   * ██      ██   ██ ██  ██  ██  ██   ██    ██    ██
   * ██      ██   ██ ██   ████   ██   ██    ██    ███████
   * This section is for private fucntions
   */

  /**
   * @notice Calculate the dev emission fee when the tokens mint
   * @param _amount EGG token tax amount
   */

  function calculateDevEmission(uint256 _amount) private view returns (uint256) {
    uint256 emission = (_amount * emissionPercent) / 10**globalMutiplier;
    return emission;
  }

  /**
   * @notice Calculate the all taxFees (liquidity, autoburn, dev, henhouse, dao)
   * @param _amount EGG token tax amount
   */

  function calculateTaxFees(uint256 _amount) private view returns (uint256[] memory) {
    uint256[] memory _taxFees = new uint256[](taxFeeStructures.length);
    uint256 max = taxFeeStructures.length;
    for (uint8 i = 0; i < max; ) {
      TaxFeeStructure memory taxFeeStructure = taxFeeStructures[i];
      uint256 taxFeeCalc = (_amount * taxFeeStructure.fee) / 10**globalMutiplier;
      _taxFees[i] = taxFeeCalc;
      unchecked {
        i++;
      }
    }
    return _taxFees;
  }

  /**
   * @notice Transfer all tax fees to specific address regarding TaxFeeStructure data
   * @param _tAmounts Array of tax fees (0 => liquidity, 1 => autoburn, 2 => dev, 3 => henhouse, 4 => dao)
   */

  function distributeTax(uint256[] memory _tAmounts) private {
    uint256 max = _tAmounts.length;
    for (uint8 i = 0; i < max; ) {
      if (_tAmounts[i] == 0) continue;
      TaxFeeStructure memory taxFeeStructure = taxFeeStructures[i];

      address recipientAddress = taxFeeStructure.recipientAddress;

      require(address(recipientAddress) != address(0), "Recipient address isn't set yet!");

      uint256 tAmount = _tAmounts[i];

      if (taxFeeStructure.swapForEth) {
        if (swapAndLiquifyEnabled) {
          // 1. Transfer full EGG amount from msg.sender to this contract
          // 2. Add any accrued taxes to tAmount
          // 3. Divide EGG amount in half
          // 4. swapTokensForEth half EGG amount to ETH & transfer to recipient
          // 5. Transfer EGg to recpient
          _transfer(msg.sender, address(this), tAmount);
          accruedSwapTax += tAmount;

          accruedSwapTax = accruedSwapTax / 2;

          swapTokensForEth(accruedSwapTax, recipientAddress);

          _transfer(address(this), recipientAddress, accruedSwapTax);
          accruedSwapTax = 0;
        } else {
          accruedSwapTax += tAmount;

          _transfer(msg.sender, address(this), tAmount);
        }
      } else {
        _transfer(msg.sender, recipientAddress, tAmount);
      }
      unchecked {
        i++;
      }
    }
  }

  /**
   * @notice Swap the half amount of contract balance to WETH and add to liquidity pool
   * @param _amount Amount of the EggToken to swap
   */

  function swapAndLiquify(uint256 _amount) private lockTheSwap {
    // Split the contract token balance into halves
    uint256 half = _amount / 2;
    uint256 otherHalf = _amount - half;

    // Capture the contract's current ETH balance.
    // This is so that we can capture exactly the amount of ETH that the
    // swap creates, and not make the liquidity event include any ETH that
    // has been manually sent to the contract
    uint256 initialBalance = address(this).balance - accruedSwapTax;

    // Swap tokens for ETH
    swapTokensForEth(half, address(this)); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

    // Calculate how much ETH was just swapped into this contract
    uint256 newBalance = address(this).balance - initialBalance;

    // Add liquidity to sushiswap
    addLiquidity(otherHalf, newBalance);

    emit SwapAndLiquify(half, newBalance, otherHalf);
  }

  /**
   * @notice Swap the EGG amount to WETH
   * @dev This is used to convert EGG to ETH. The ETH is added this contract, which then gets used by swapAndLiquify to add LP
   * @param tokenAmount EGG token amount to swap ETH
   *
   */

  function swapTokensForEth(uint256 tokenAmount, address recipient) private {
    // Generate the sushiswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // Make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // Accept any amount of ETH
      path,
      recipient,
      block.timestamp
    );
  }

  /**
   * @notice Swap the EGG amount to WETH
   * @param tokenAmount EGG token amount to add liquidity pool
   * @param ethAmount ETH amount to add liquidity pool
   */

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // Approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    _approve(address(this), address(uniswapV2Pair), tokenAmount);

    // Add the liquidity
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0, // Slippage is unavoidable
      0, // Slippage is unavoidable
      liquidityTokenRecipient,
      block.timestamp
    );
  }

  /**
   * @notice Swap the EGG amount to WETH
   * @param tokenAmount EGG token amount to add liquidity pool
   * @param _ethAmount ETH amount to add liquidity pool
   */

  function addLiquidityETH(uint256 tokenAmount, uint256 _ethAmount)
    external
    payable
    onlyController
    returns (
      uint256 _amountToken,
      uint256 _amountETH,
      uint256 _liquidity
    )
  {
    _mint(address(this), tokenAmount);

    // Approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uint256 allowanceNow = allowance(address(this), address(uniswapV2Router));

    _approve(_msgSender(), address(uniswapV2Router), tokenAmount);
    allowanceNow = allowance(_msgSender(), address(uniswapV2Router));

    // Add the liquidity
    (uint256 amountToken, uint256 amountETH, uint256 liquidity) = uniswapV2Router.addLiquidityETH{ value: _ethAmount }(
      address(this),
      tokenAmount,
      0, // Slippage is unavoidable
      0, // Slippage is unavoidable
      liquidityTokenRecipient,
      block.timestamp
    );
    return (amountToken, amountETH, liquidity);
  }

  /**
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override(ERC20) disallowIfStateIsChanging returns (bool) {
    require(controllers[_msgSender()] || lastWrite[sender] < block.number, 'Not allowed');
    // If the entity invoking this transfer is an admin (i.e. the gameContract)
    // allow the transfer without approval. This saves gas and a transaction.
    // The sender address will still need to actually have the amount being attempted to send.
    if (controllers[_msgSender()]) {
      // NOTE: This will omit any events from being written. This saves additional gas,
      // and the event emission is not a requirement by the EIP
      // (read this function summary / ERC20 summary for more details)
      _transfer(sender, recipient, amount);
      return true;
    }

    // If it's not an admin entity (game contract, tower, etc)
    // The entity will need to be given permission to transfer these funds
    return super.transferFrom(sender, recipient, amount);
  }

  /** SECURITEEEEEEEEEEEEEEEEE */

  modifier disallowIfStateIsChanging() {
    // frens can always call whenever they want :)
    require(controllers[_msgSender()] || lastWrite[tx.origin] < block.number, 'Not allowed');
    _;
  }

  /**
   *  ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████
   * ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   * ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████
   * ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   *  ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██
   * This section if for controllers (possibly Owner) only functions
   */

  /**
   * @notice enables multiple addresses to call controller only functions
   * @dev Only callable by an existing controller
   * @param _addresses array of the address to enable
   */
  function addManyControllers(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _addController(_addresses[i]);
    }
  }

  /**
   * @notice removes an address from controller list and ability to call controller only functions
   * @dev Only callable by an existing controller
   * @param _address the address to disable
   */
  function removeController(address _address) external onlyController {
    controllers[_address] = false;
  }

  /**
   * @notice Add the tax data into TaxFeeStructure
   * @param _recipientAddress Recipient address to get EGG tokens
   * @param _sendToContract If _recipientAddress is Deployed contract address, _sendToContract => true. If no, _sendToContract => false
   * @param _fee Tax Fee value of this TaxFeeStructure 10000 = 100%, 1010 = 10.10%
   * @param _previousFee Previous Tax Fee value of this TaxFeeStructure
   * @param _swapForEth If true then run swapTokensForEth
   */

  function addTaxFeeStructure(
    address _recipientAddress,
    bool _sendToContract,
    uint256 _fee,
    uint256 _previousFee,
    bool _swapForEth
  ) external onlyController {
    require(_recipientAddress != address(0), 'Recipient zero address.');
    taxFeeStructures.push(
      TaxFeeStructure({
        recipientAddress: _recipientAddress,
        sendToContract: _sendToContract,
        fee: _fee,
        previousFee: _previousFee,
        swapForEth: _swapForEth
      })
    );
  }

  /**
   * @notice Update the TaxFeeStructure regarding TaxFeeStructure id
   * @dev Only callable by an existing controller
   * @param _recipientAddress Recipient address to get EGG tokens
   * @param _sendToContract If _recipientAddress is Deployed contract address, _sendToContract => true. If no, _sendToContract => false
   * @param _fee Tax Fee value of this TaxFeeStructure. 10000 = 100%, 1010 = 10.10%
   * @param _previousFee Previous Tax Fee value of this TaxFeeStructure
   * @param _swapForEth If true then run swapTokensForEth
   */

  function setTaxFeeStructure(
    uint16 id,
    address _recipientAddress,
    bool _sendToContract,
    uint256 _fee,
    uint256 _previousFee,
    bool _swapForEth
  ) external onlyController {
    require(id < taxFeeStructures.length, "TaxFeeStructrue doesn't exist");
    require(_recipientAddress != address(0), 'Recipient zero address');
    taxFeeStructures[id] = TaxFeeStructure(_recipientAddress, _sendToContract, _fee, _previousFee, _swapForEth);
  }

  /**
   * @notice Remove the TaxFeeStructure regarding TaxFeeStructure id
   * @dev Only callable by an existing controller
   * @param id TaxFeeStructure id to remove the tax fee data from TaxFeeStructure
   */

  function removeTaxFeeStructure(uint16 id) external onlyController {
    require(id < taxFeeStructures.length, "TaxFeeStructrue doesn't exist");
    TaxFeeStructure memory lastTaxFeeStructure = taxFeeStructures[taxFeeStructures.length - 1];
    taxFeeStructures[id] = lastTaxFeeStructure; //  Shuffle last taxFeeStructures to current position
    taxFeeStructures.pop();
  }

  /**
   @notice Get the Tax Fee Structure Info by structure id
   @param id Structure id to get the tax fee structure info
   */

  function getTaxFeeStructure(uint8 id) public view returns (TaxFeeStructure memory) {
    require(id < taxFeeStructures.length, "TaxFeeStructure data isn't exist");
    return taxFeeStructures[id];
  }

  /**
   * @notice Exclude multiple addresses from being taxed fees
   * @dev Only callable by controllers
   * @param _addresses array of the address to exclude
   */
  function excludeManyFromFee(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _excludeFromFee(_addresses[i]);
    }
  }

  /**
   * @notice Include the account from the tax fee
   * @dev Only callable by an existing controller
   * @param account Address to include the tax fee
   */

  function includeInFee(address account) public onlyController {
    _isExcludedFee[account] = false;
  }

  /**
   * @notice Remove the account from the rewardExculed
   * @dev Only callable by an existing controller
   * @param account Address to include from the reward
   */

  function includeInReward(address account) external onlyController {
    require(_isExcludedReward[account], 'Account already included');
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_excluded[i] == account) {
        _excluded[i] = _excluded[_excluded.length - 1];
        _isExcludedReward[account] = false;
        _excluded.pop();
        break;
      }
    }
  }

  /**
   * @notice Set the dev emission rate to mint the EGG token to the dev wallet
   * @dev Only callable by an existing controller
   * @param devEmission Rate of dev emission // 909 = 9.09%
   */

  function setDevEmission(uint256 devEmission) external onlyController {
    emissionPercent = devEmission;
  }

  /**
   * @notice Set the dev emission address to send the emission tokens when EGG Tokens mint
   * @dev Only callable by an existing controller
   * @param _emissionAddress Emission address to get the emission EGG Tokens when EGG tokens mint
   */

  function setDevEmissionAddress(address _emissionAddress) external onlyController {
    emissionsAddress = _emissionAddress;
  }

  function setGlobalMutiplier(uint256 _number) external onlyController {
    globalMutiplier = _number;
  }

  /**
   * @notice Set enable state of the swapAndLqiuidityPool
   * @dev Only callable by an existing controller
   * @param _enabled Enable state of the swapAndLiquidityPool
   */

  function setSwapAndLiquifyEnabled(bool _enabled) external onlyController {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  /**
   * @notice Set the liquidity Token Recipient Address
   * @dev Only callable by an existing controller
   * @param _recipient Recipient Address
   */

  function setLiquidityTokenRecipient(address _recipient) public onlyController {
    liquidityTokenRecipient = _recipient;
  }
}