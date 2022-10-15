/** TakaraKuji - Treasure Raffle
 *
 *  Token with auto-LP mechanism and lottery for buyers
 *
 *  Initial Anti-Whales Limits:
 *        - Max. Transaction Amount: 1% (1.000.000.000 TAKARA)
 *        - Max. Wallet: 2% (2.000.000.000 TAKARA)
 *
 *  Buy/Sell tax: 6%
 *        - 2%: Added to Liquidity Pool
 *        - 2%: Marketing / Development
 *        - 2%: Added to Lottery Pool Prize
 *
 *  Lotery Raffle
 *        - You'll obtain 1 lotery ticket for each 1.000.000 TAKARA buyed
 *        - When lottery pool prize arrives at 1.000.000.000 TAKARA a new lottery winner will be picked
 *        - Auto tranfer the total lottery pool prize to the winner
 *        - The tickets holders will be reset and a new Lottery will start with the new buyers
 *        - This token implements Chainlink VRF (Verifiable Random Function)
 *          to get a fair and verifiable random number and pick a Lotery Winner
 *
 *  Telegram: https://t.me/takarakujiportal
 *  Twitter:  https://twitter.com/Takarakuji_eth
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract TakaraKuji is ERC20, Ownable, VRFConsumerBaseV2 {
  using SafeMath for uint256;

  enum LotteryState {
    OPEN,
    CALCULATING
  }

  IUniswapV2Router02 public immutable uniswapV2Router;
  address public immutable uniswapV2Pair;
  address public constant deadAddress = address(0xdead);
  address private immutable i_usdc;
  bool private swapping;

  address public devWallet;

  uint256 public maxTransactionAmount;
  uint256 public swapTokensAtAmount;
  uint256 public pickLotteryWinnerAtAmount;
  uint256 public maxWallet;

  bool public limitsInEffect = true;
  bool public tradingActive = false;
  bool public swapEnabled = false;

  uint256 public buyTotalFees;
  uint256 public buyDevFee;
  uint256 public buyLiquidityFee;
  uint256 public buyLotteryFee;

  uint256 public sellTotalFees;
  uint256 public sellDevFee;
  uint256 public sellLiquidityFee;
  uint256 public sellLotteryFee;

  // exclude from fees and max transaction amount
  mapping(address => bool) private _isExcludedFromFees;
  mapping(address => bool) public _isExcludedMaxTransactionAmount;

  uint256 public lotteryRound = 0;
  mapping(uint256 => address[]) public lotteryTicketsAtRound;
  uint256 public minTicketLotteryAmount;
  VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
  bytes32 private immutable i_keyHash;
  uint64 private immutable i_subscriptionId;
  uint16 private constant REQUEST_CONFIRMATIONS = 3;
  uint32 private immutable i_callbackGasLimit;
  uint16 private constant NUM_WORDS = 1;

  address public lastLotteryWinner;
  uint256 public lastLotteryTokensWinned;
  uint256 public totalLotteryTokens;
  LotteryState public lotteryState;

  event LotteryTicketsAdded(address indexed account, uint256 numTickets);
  event RequestedLotteryWinner(uint256 indexed requestId);
  event PickedLotteryWinner(address indexed winner, uint256 numTokens);

  event ExcludeFromFees(address indexed account, bool isExcluded);

  event devWalletUpdated(address indexed newWallet, address indexed oldWallet);

  constructor(
    address _vrfCoordinatorV2,
    bytes32 _keyHash,
    uint64 _subscriptionId,
    uint32 _callbackGasLimit,
    address _uniswapV2Router,
    address _usdc
  ) ERC20("TakaraKuji", "TAKARA") VRFConsumerBaseV2(_vrfCoordinatorV2) {
    // Chainlink VRF data
    i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
    i_keyHash = _keyHash;
    i_subscriptionId = _subscriptionId;
    i_callbackGasLimit = _callbackGasLimit;
    lotteryState = LotteryState.OPEN;
    // USDC Address
    i_usdc = _usdc;
    // Uniswap Router
    uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
    excludeFromMaxTransaction(_uniswapV2Router, true);
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), i_usdc);
    excludeFromMaxTransaction(address(uniswapV2Pair), true);

    uint256 _buyDevFee = 2;
    uint256 _buyLiquidityFee = 2;
    uint256 _buyLotteryFee = 2;

    uint256 _sellDevFee = 2;
    uint256 _sellLiquidityFee = 2;
    uint256 _sellLotteryFee = 2;

    uint256 totalSupply = 100_000_000_000 * 1e18;

    maxTransactionAmount = (totalSupply * 1) / 100; // 1% from total supply (1_000_000_000) maxTransactionAmountTxn
    maxWallet = (totalSupply * 2) / 100; // 2% from total supply (2_000_000_000) maxWallet
    minTicketLotteryAmount = (totalSupply * 1) / 100000; // 0.001% from from total supply (1_000_000) to obtain a new lottery ticket
    pickLotteryWinnerAtAmount = (totalSupply * 1) / 100; // 1% from total supply (1_000_000_000) for pick a new lottery winner
    swapTokensAtAmount = (totalSupply * 1) / 100; // 1% from total supply (1_000_000_000) to swap wallet

    buyDevFee = _buyDevFee;
    buyLiquidityFee = _buyLiquidityFee;
    buyLotteryFee = _buyLotteryFee;
    buyTotalFees = buyDevFee + buyLiquidityFee + buyLotteryFee;

    sellDevFee = _sellDevFee;
    sellLiquidityFee = _sellLiquidityFee;
    sellLotteryFee = _sellLotteryFee;
    sellTotalFees = sellDevFee + sellLiquidityFee + sellLotteryFee;

    devWallet = address(0xC24DAf9A82b3bA4A962e17812CC177883625322B); // set as dev wallet

    // exclude from paying fees or having max transaction amount
    excludeFromFees(owner(), true);
    excludeFromFees(address(this), true);
    excludeFromFees(address(0xdead), true);

    excludeFromMaxTransaction(owner(), true);
    excludeFromMaxTransaction(address(this), true);
    excludeFromMaxTransaction(address(0xdead), true);

    /** @dev
     *   _mint is an internal function in ERC20.sol that is only called here,
     *    and CANNOT be called ever again
     */
    _mint(msg.sender, totalSupply);
  }

  receive() external payable {}

  // once enabled, can never be turned off
  function enableTrading() external onlyOwner {
    tradingActive = true;
    swapEnabled = true;
  }

  // remove limits after token is stable
  function removeLimits() external onlyOwner returns (bool) {
    limitsInEffect = false;
    return true;
  }

  // change the minimum amount of tokens to sell from fees
  function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool) {
    require(newAmount >= (totalSupply() * 1) / 100000, "Swap amount cannot be lower than 0.001% total supply.");
    require(newAmount <= (totalSupply() * 1) / 100, "Swap amount cannot be higher than 1% total supply.");
    swapTokensAtAmount = newAmount * (10**18);
    return true;
  }

  // change the minimum amount of tokens to pick a new lottery winner
  function updatePickLotteryWinnerAtAmount(uint256 newAmount) external onlyOwner returns (bool) {
    require(
      newAmount >= (totalSupply() * 1) / 100000,
      "pickLotteryWinnerAtAmount cannot be lower than 0.001% total supply."
    );
    require(newAmount <= (totalSupply() * 1) / 100, "pickLotteryWinnerAtAmount cannot be higher than 1% total supply.");
    pickLotteryWinnerAtAmount = newAmount * (10**18);
    return true;
  }

  function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
    require(newNum >= ((totalSupply() * 1) / 1000) / 1e18, "Cannot set maxTransactionAmount lower than 0.1%");
    maxTransactionAmount = newNum * (10**18);
  }

  function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
    require(newNum >= ((totalSupply() * 5) / 1000) / 1e18, "Cannot set maxWallet lower than 0.5%");
    maxWallet = newNum * (10**18);
  }

  function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
    _isExcludedMaxTransactionAmount[updAds] = isEx;
  }

  // only use to disable contract sales if absolutely necessary (emergency use only)
  function updateSwapEnabled(bool enabled) external onlyOwner {
    swapEnabled = enabled;
  }

  function updateBuyFees(uint256 _devFee, uint256 _liquidityFee) external onlyOwner {
    buyDevFee = _devFee;
    buyLiquidityFee = _liquidityFee;
    buyTotalFees = buyDevFee + buyLiquidityFee;
    require(buyTotalFees <= 10, "Must keep fees at 10% or less");
  }

  function updateSellFees(uint256 _devFee, uint256 _liquidityFee) external onlyOwner {
    sellDevFee = _devFee;
    sellLiquidityFee = _liquidityFee;
    sellTotalFees = sellDevFee + sellLiquidityFee;
    require(sellTotalFees <= 10, "Must keep fees at 10% or less");
  }

  function excludeFromFees(address account, bool excluded) public onlyOwner {
    _isExcludedFromFees[account] = excluded;
    emit ExcludeFromFees(account, excluded);
  }

  function updateDevWallet(address newDevWallet) external onlyOwner {
    emit devWalletUpdated(newDevWallet, devWallet);
    devWallet = newDevWallet;
  }

  function isExcludedFromFees(address account) public view returns (bool) {
    return _isExcludedFromFees[account];
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    if (amount == 0) {
      super._transfer(from, to, 0);
      return;
    }

    if (limitsInEffect) {
      if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
        if (!tradingActive) {
          require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }

        // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
        //when buy
        if (from == uniswapV2Pair && !_isExcludedMaxTransactionAmount[to]) {
          require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
          require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
        } else if (!_isExcludedMaxTransactionAmount[to]) {
          require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
        }
      }
    }

    uint256 contractTokenBalance = balanceOf(address(this));

    bool canSwap = contractTokenBalance >= swapTokensAtAmount;

    if (
      canSwap &&
      swapEnabled &&
      !swapping &&
      to == uniswapV2Pair &&
      !_isExcludedFromFees[from] &&
      !_isExcludedFromFees[to]
    ) {
      swapping = true;

      swapBack();

      swapping = false;
    }

    bool takeFee = !swapping;

    // if any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
      takeFee = false;
    }

    uint256 fees = 0;
    uint256 tokensForLiquidity = 0;
    uint256 tokensForDev = 0;
    uint256 tokensForLottery = 0;
    // only take fees on buys/sells, do not take on wallet transfers
    if (takeFee) {
      // on sell
      if (to == uniswapV2Pair && sellTotalFees > 0) {
        fees = amount.mul(sellTotalFees).div(100);
        tokensForLiquidity = (fees * sellLiquidityFee) / sellTotalFees;
        tokensForDev = (fees * sellDevFee) / sellTotalFees;
        tokensForLottery = (fees * sellLotteryFee) / sellTotalFees;
        totalLotteryTokens = totalLotteryTokens + tokensForLottery;
      }
      // on buy
      else if (from == uniswapV2Pair && buyTotalFees > 0) {
        fees = amount.mul(buyTotalFees).div(100);
        tokensForLiquidity = (fees * buyLiquidityFee) / buyTotalFees;
        tokensForDev = (fees * buyDevFee) / buyTotalFees;
        tokensForLottery = (fees * buyLotteryFee) / buyTotalFees;
        totalLotteryTokens = totalLotteryTokens + tokensForLottery;
        addLotteryTickets(to, tokensForLottery);
      }

      if (fees > 0) {
        super._transfer(from, address(this), fees);
      }
      if (tokensForLiquidity > 0) {
        super._transfer(address(this), uniswapV2Pair, tokensForLiquidity);
      }

      amount -= fees;
    }

    super._transfer(from, to, amount);
  }

  function swapTokensForUSDC(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> usdc
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = i_usdc;

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of USDC
      path,
      devWallet,
      block.timestamp
    );
  }

  function swapBack() private {
    uint256 contractBalance = balanceOf(address(this));
    if (contractBalance == 0) {
      return;
    }
    contractBalance = contractBalance - totalLotteryTokens;
    if (contractBalance > swapTokensAtAmount) {
      contractBalance = swapTokensAtAmount;
    }
    swapTokensForUSDC(contractBalance);
    // Check if we have to pick a new lottery winner
    if (
      lotteryState == LotteryState.OPEN &&
      lotteryTicketsAtRound[lotteryRound].length > 0 &&
      totalLotteryTokens > pickLotteryWinnerAtAmount
    ) {
      requestRandomWinner();
    }
  }

  function addLotteryTickets(address holder, uint256 tokensForLottery) private {
    if (tokensForLottery >= minTicketLotteryAmount && lotteryState == LotteryState.OPEN) {
      uint256 numTickets = tokensForLottery / minTicketLotteryAmount;
      for (uint256 i = 1; i <= numTickets; i++) {
        lotteryTicketsAtRound[lotteryRound].push(holder);
      }
      emit LotteryTicketsAdded(holder, numTickets);
    }
  }

  function requestRandomWinner() private {
    // Will revert if subscription is not set and funded.
    lotteryState = LotteryState.CALCULATING;
    uint256 requestId = i_vrfCoordinator.requestRandomWords(
      i_keyHash,
      i_subscriptionId,
      REQUEST_CONFIRMATIONS,
      i_callbackGasLimit,
      NUM_WORDS
    );
    emit RequestedLotteryWinner(requestId);
  }

  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    uint256 indexOfWinner = randomWords[0] % lotteryTicketsAtRound[lotteryRound].length;
    // lastLotteryWinner = lotteryTickets[indexOfWinner];
    lastLotteryWinner = lotteryTicketsAtRound[lotteryRound][indexOfWinner];
    // Reset accumulated Current Lottery Tokens
    lastLotteryTokensWinned = totalLotteryTokens;
    totalLotteryTokens = 0;
    // Reset lotteryTickets after winner picked
    lotteryRound++;
    lotteryState = LotteryState.OPEN;
    // Transfer the last Lottery Tokens winned to the winner
    super._transfer(address(this), lastLotteryWinner, lastLotteryTokensWinned);
    emit PickedLotteryWinner(lastLotteryWinner, lastLotteryTokensWinned);
  }

  function getCurrentNumberOfLotteryTickets() public view returns (uint256) {
    return lotteryTicketsAtRound[lotteryRound].length;
  }
}