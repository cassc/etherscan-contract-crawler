// SPDX-License-Identifier: MIT

/*
    Surreal Creations by azee

    Twitter:
    https://twitter.com/surreal_azee
    https://twitter.com/SCA_Surreals

       SSSSSSSSSSSSSSS         CCCCCCCCCCCCC               AAA
     SS:::::::::::::::S     CCC::::::::::::C              A:::A
    S:::::SSSSSS::::::S   CC:::::::::::::::C             A:::::A
    S:::::S     SSSSSSS  C:::::CCCCCCCC::::C            A:::::::A
    S:::::S             C:::::C       CCCCCC           A:::::::::A
    S:::::S            C:::::C                        A:::::A:::::A
     S::::SSSS         C:::::C                       A:::::A A:::::A
      SS::::::SSSSS    C:::::C                      A:::::A   A:::::A
        SSS::::::::SS  C:::::C                     A:::::A     A:::::A
           SSSSSS::::S C:::::C                    A:::::AAAAAAAAA:::::A
                S:::::SC:::::C                   A:::::::::::::::::::::A
                S:::::S C:::::C       CCCCCC    A:::::AAAAAAAAAAAAA:::::A
    SSSSSSS     S:::::S  C:::::CCCCCCCC::::C   A:::::A             A:::::A
    S::::::SSSSSS:::::S   CC:::::::::::::::C  A:::::A               A:::::A
    S:::::::::::::::SS      CCC::::::::::::C A:::::A                 A:::::A
     SSSSSSSSSSSSSSS           CCCCCCCCCCCCCAAAAAAA                   AAAAAAA

 */

pragma solidity >=0.4.22 <0.9.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract SurrealCreations is ERC20Burnable, Ownable {
  uint256 public maxBuyAmount;
  uint256 public maxSellAmount;
  uint256 public maxWallet;

  IUniswapV2Router02 public uniswapRouter;
  address public lpPair;

  bool private swapping;
  uint256 public swapTokensAtAmount;

  address public operationsAddress;
  address public treasuryAddress;

  uint256 public tradingActiveBlock = 0; // 0 means trading is not active
  uint256 public blockForPenaltyEnd;

  bool public limitsInEffect = true;
  bool public tradingActive = false;
  bool public swapEnabled = false;

  // Anti-bot and anti-whale mappings and variables
  mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
  bool public transferDelayEnabled = true;

  uint256 public buyTotalFees;
  uint256 public buyOperationsFee;
  uint256 public buyLiquidityFee;
  uint256 public buyTreasuryFee;

  uint256 public sellTotalFees;
  uint256 public sellOperationsFee;
  uint256 public sellLiquidityFee;
  uint256 public sellTreasuryFee;

  uint256 public tokensForOperations;
  uint256 public tokensForLiquidity;
  uint256 public tokensForTreasury;

  /******************/

  // exlcude from fees and max transaction amount
  mapping(address => bool) private _isExcludedFromFees;
  mapping(address => bool) public _isExcludedMaxTransactionAmount;

  // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
  // could be subject to a maximum transfer amount
  mapping(address => bool) public automatedMarketMakerPairs;

  event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

  event EnabledTrading();

  event ExcludeFromFees(address indexed account, bool isExcluded);

  event UpdatedMaxBuyAmount(uint256 newAmount);

  event UpdatedMaxSellAmount(uint256 newAmount);

  event UpdatedMaxWalletAmount(uint256 newAmount);

  event UpdatedOperationsAddress(address indexed newWallet);

  event UpdatedTreasuryAddress(address indexed newWallet);

  event MaxTransactionExclusion(address _address, bool excluded);

  event OwnerForcedSwapBack(uint256 timestamp);

  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiquidity
  );

  event TransferForeignToken(address token, uint256 amount);

  event UpdatedPrivateMaxSell(uint256 amount);

  constructor(address _router) payable ERC20("SurrealCreations", "AZEE") {
    // initialize router
    uniswapRouter = IUniswapV2Router02(_router);

    // create pair
    lpPair = IUniswapV2Factory(uniswapRouter.factory()).createPair(
      address(this),
      uniswapRouter.WETH()
    );
    _excludeFromMaxTransaction(address(lpPair), true);
    _setAutomatedMarketMakerPair(address(lpPair), true);

    uint256 totalSupply = 69 * 1e6 * 1e18; // 69 million

    maxBuyAmount = (totalSupply * 1) / 100; // 1%
    maxSellAmount = (totalSupply * 1) / 100; // 1%
    maxWallet = (totalSupply * 2) / 100; // 2%
    swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05 %

    buyOperationsFee = 0;
    buyTreasuryFee = 9;
    buyLiquidityFee = 1;
    buyTotalFees = buyOperationsFee + buyLiquidityFee + buyTreasuryFee;

    sellOperationsFee = 0;
    sellTreasuryFee = 14;
    sellLiquidityFee = 1;
    sellTotalFees = sellOperationsFee + sellLiquidityFee + sellTreasuryFee;

    operationsAddress = address(msg.sender);
    treasuryAddress = address(0x49831118DC243C1f5C91a33F3A01bE8152201472);

    _excludeFromMaxTransaction(msg.sender, true);
    _excludeFromMaxTransaction(address(this), true);
    _excludeFromMaxTransaction(address(0xdead), true);
    _excludeFromMaxTransaction(address(uniswapRouter), true);
    _excludeFromMaxTransaction(address(0x49831118DC243C1f5C91a33F3A01bE8152201472), true);

    excludeFromFees(msg.sender, true);
    excludeFromFees(address(this), true);
    excludeFromFees(address(0xdead), true);
    excludeFromFees(address(uniswapRouter), true);
    excludeFromFees(address(0x49831118DC243C1f5C91a33F3A01bE8152201472), true);

    _mint(msg.sender, totalSupply); // Tokens for liquidity
  }

  receive() external payable {}

  function enableTrading(uint256 blocksForPenalty) external onlyOwner {
    require(!tradingActive, "Trading is already active.");
    require(blocksForPenalty < 10, "Penalty blocks > 10");

    //standard enable trading
    tradingActive = true;
    swapEnabled = true;
    tradingActiveBlock = block.number;
    blockForPenaltyEnd = tradingActiveBlock + blocksForPenalty;
    emit EnabledTrading();
  }

  // disable Transfer delay - cannot be reenabled
  function disableTransferDelay() external onlyOwner {
    transferDelayEnabled = false;
  }

  function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
    require(
      newNum >= ((totalSupply() * 5) / 1000) / 1e18,
      "Max buy amount lower than 0.5%"
    );
    require(newNum <= ((totalSupply() * 2) / 100) / 1e18, "Buy amount higher than 2%");
    maxBuyAmount = newNum * (10**18);
    emit UpdatedMaxBuyAmount(maxBuyAmount);
  }

  function updateMaxSellAmount(uint256 newNum) external onlyOwner {
    require(
      newNum >= ((totalSupply() * 5) / 1000) / 1e18,
      "Max sell amount lower than 0.5%"
    );
    require(
      newNum <= ((totalSupply() * 2) / 100) / 1e18,
      "Max sell amount higher than 2%"
    );
    maxSellAmount = newNum * (10**18);
    emit UpdatedMaxSellAmount(maxSellAmount);
  }

  function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
    require(
      newNum >= ((totalSupply() * 5) / 1000) / 1e18,
      "Cannot set max wallet amount lower than 0.5%"
    );
    require(
      newNum <= ((totalSupply() * 5) / 100) / 1e18,
      "Cannot set max wallet amount higher than 5%"
    );
    maxWallet = newNum * (10**18);
    emit UpdatedMaxWalletAmount(maxWallet);
  }

  // change the minimum amount of tokens to sell from fees
  function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
    require(
      newAmount >= (totalSupply() * 1) / 100000,
      "Swap amount < 0.001% total supply."
    );
    require(
      newAmount <= (totalSupply() * 1) / 1000,
      "Swap amount > 0.1% total supply."
    );
    swapTokensAtAmount = newAmount;
  }

  function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
    _isExcludedMaxTransactionAmount[updAds] = isExcluded;
    emit MaxTransactionExclusion(updAds, isExcluded);
  }

  function excludeFromMaxTransaction(address updAds, bool isEx) external onlyOwner {
    if (!isEx) {
      require(updAds != lpPair, "Uniswap pair must have max txn");
    }
    _isExcludedMaxTransactionAmount[updAds] = isEx;
  }

  function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
    require(
      pair != lpPair,
      "The pair cannot be removed from automatedMarketMakerPairs"
    );
    _setAutomatedMarketMakerPair(pair, value);
    emit SetAutomatedMarketMakerPair(pair, value);
  }

  function _setAutomatedMarketMakerPair(address pair, bool value) private {
    automatedMarketMakerPairs[pair] = value;
    _excludeFromMaxTransaction(pair, value);
    emit SetAutomatedMarketMakerPair(pair, value);
  }

  function updateBuyFees(
    uint256 _operationsFee,
    uint256 _liquidityFee,
    uint256 _treasuryFee
  ) external onlyOwner {
    buyOperationsFee = _operationsFee;
    buyLiquidityFee = _liquidityFee;
    buyTreasuryFee = _treasuryFee;
    buyTotalFees = buyOperationsFee + buyLiquidityFee + buyTreasuryFee;
    require(buyTotalFees <= 15, "Fees > 15%");
  }

  function updateSellFees(
    uint256 _operationsFee,
    uint256 _liquidityFee,
    uint256 _treasuryFee
  ) external onlyOwner {
    sellOperationsFee = _operationsFee;
    sellLiquidityFee = _liquidityFee;
    sellTreasuryFee = _treasuryFee;
    sellTotalFees = sellOperationsFee + sellLiquidityFee + sellTreasuryFee;
    require(sellTotalFees <= 20, "Fees > 20%");
  }

  function excludeFromFees(address account, bool excluded) public onlyOwner {
    _isExcludedFromFees[account] = excluded;
    emit ExcludeFromFees(account, excluded);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "amount must > 0");

    if (!tradingActive) {
      require(
        _isExcludedFromFees[from] || _isExcludedFromFees[to],
        "Trading is not active."
      );
    }

    if (limitsInEffect) {
      if (
        from != owner() &&
        to != owner() &&
        to != address(0xdead) &&
        !_isExcludedFromFees[from] &&
        !_isExcludedFromFees[to]
      ) {
        if (transferDelayEnabled) {
          if (to != address(uniswapRouter) && to != address(lpPair)) {
            require(
              _holderLastTransferTimestamp[tx.origin] < (block.number) &&
                _holderLastTransferTimestamp[to] < (block.number),
              "_transfer:: Transfer Delay enabled.  Try again later."
            );
            _holderLastTransferTimestamp[tx.origin] = (block.number);
            _holderLastTransferTimestamp[to] = (block.number);
          }
        }

        //when buy
        if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
          require(amount <= maxBuyAmount, "Buy transfer amount exceeds the max buy.");
          require(amount + balanceOf(to) <= maxWallet, "Max Wallet Exceeded");
        }
        //when sell
        else if (
          automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]
        ) {
          require(amount <= maxSellAmount, "Sell transfer amount >  max sell.");
        } else if (!_isExcludedMaxTransactionAmount[to]) {
          require(amount + balanceOf(to) <= maxWallet, "Max Wallet Exceeded");
        }
      }
    }

    uint256 contractTokenBalance = balanceOf(address(this));

    bool canSwap = contractTokenBalance >= swapTokensAtAmount;

    if (canSwap && swapEnabled && !swapping && automatedMarketMakerPairs[to]) {
      swapping = true;
      swapBack();
      swapping = false;
    }

    bool takeFee = true;
    // if any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
      takeFee = false;
    }

    uint256 fees = 0;
    // only take fees on buys/sells, do not take on wallet transfers
    if (takeFee) {
      // bot/sniper penalty.
      if (
        (earlyBuyPenaltyInEffect() ||
          (amount >= maxBuyAmount - .9 ether &&
            blockForPenaltyEnd + 8 >= block.number)) &&
        automatedMarketMakerPairs[from] &&
        !automatedMarketMakerPairs[to] &&
        !_isExcludedFromFees[to] &&
        buyTotalFees > 0
      ) {
        if (!earlyBuyPenaltyInEffect()) {
          // reduce by 1 wei per max buy over what Uniswap will allow to revert bots as best as possible to limit erroneously blacklisted wallets. First bot will get in and be blacklisted, rest will be reverted (*cross fingers*)
          maxBuyAmount -= 1;
        }

        // In this case (5) the end number controls how quickly the decay of taxes happens
        fees = (amount * 999) / (1000 + (block.number - tradingActiveBlock) * 100);
        tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
        tokensForOperations += (fees * buyOperationsFee) / buyTotalFees;
        tokensForTreasury += (fees * buyTreasuryFee) / buyTotalFees;
      }
      // on sell
      else if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
        fees = (amount * sellTotalFees) / 100;
        tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
        tokensForOperations += (fees * sellOperationsFee) / sellTotalFees;
        tokensForTreasury += (fees * sellTreasuryFee) / sellTotalFees;
      }
      // on buy
      else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        fees = (amount * buyTotalFees) / 100;
        tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
        tokensForOperations += (fees * buyOperationsFee) / buyTotalFees;
        tokensForTreasury += (fees * buyTreasuryFee) / buyTotalFees;
      }

      if (fees > 0) {
        super._transfer(from, address(this), fees);
      }

      amount -= fees;
    }

    super._transfer(from, to, amount);
  }

  function earlyBuyPenaltyInEffect() public view returns (bool) {
    return block.number < blockForPenaltyEnd;
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapRouter.WETH();

    _approve(address(this), address(uniswapRouter), tokenAmount);

    // make the swap
    uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapRouter), tokenAmount);

    // add the liquidity
    uniswapRouter.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      address(0xdead),
      block.timestamp
    );
  }

  function swapBack() private {
    uint256 contractBalance = balanceOf(address(this));
    uint256 totalTokensToSwap = tokensForLiquidity +
      tokensForOperations +
      tokensForTreasury;

    if (contractBalance == 0 || totalTokensToSwap == 0) {
      return;
    }

    if (contractBalance > swapTokensAtAmount * 10) {
      contractBalance = swapTokensAtAmount * 10;
    }

    bool success;

    // Halve the amount of liquidity tokens
    uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
      totalTokensToSwap /
      2;

    swapTokensForEth(contractBalance - liquidityTokens);

    uint256 ethBalance = address(this).balance;
    uint256 ethForLiquidity = ethBalance;

    uint256 ethForOperations = (ethBalance * tokensForOperations) /
      (totalTokensToSwap - (tokensForLiquidity / 2));
    uint256 ethForTreasury = (ethBalance * tokensForTreasury) /
      (totalTokensToSwap - (tokensForLiquidity / 2));

    ethForLiquidity -= ethForOperations + ethForTreasury;

    tokensForLiquidity = 0;
    tokensForOperations = 0;
    tokensForTreasury = 0;

    if (liquidityTokens > 0 && ethForLiquidity > 0) {
      addLiquidity(liquidityTokens, ethForLiquidity);
    }

    (success, ) = address(treasuryAddress).call{value: ethForTreasury}("");
    (success, ) = address(operationsAddress).call{value: address(this).balance}("");
  }

  // withdraw ETH if stuck or someone sends to the address
  function withdrawStuckETH() external onlyOwner {
    bool success;
    (success, ) = address(msg.sender).call{value: address(this).balance}("");
  }

  function setOperationsAddress(address _operationsAddress) external onlyOwner {
    require(_operationsAddress != address(0), "_operationsAddress address cannot be 0");
    operationsAddress = payable(_operationsAddress);
    emit UpdatedOperationsAddress(_operationsAddress);
  }

  function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
    require(_treasuryAddress != address(0), "_operationsAddress address cannot be 0");
    treasuryAddress = payable(_treasuryAddress);
    emit UpdatedTreasuryAddress(_treasuryAddress);
  }

  // force Swap back if slippage issues.
  function forceSwapBack() external onlyOwner {
    require(
      balanceOf(address(this)) >= swapTokensAtAmount,
      "Token amount < minimum swap tokens amount"
    );
    swapping = true;
    swapBack();
    swapping = false;
    emit OwnerForcedSwapBack(block.timestamp);
  }

  // remove limits after token is stable
  function setLimits(bool _limits) external onlyOwner {
    limitsInEffect = _limits;
  }

  function addLP(bool confirmAddLp) external onlyOwner {
    require(confirmAddLp, "Please confirm adding of the LP");
    require(!tradingActive, "Trading is already active, cannot relaunch.");

    // add the liquidity
    require(address(this).balance > 0, "Must have ETH on contract to launch");
    require(balanceOf(address(this)) > 0, "Must have Tokens on contract to launch");

    _approve(address(this), address(uniswapRouter), balanceOf(address(this)));

    uniswapRouter.addLiquidityETH{value: address(this).balance}(
      address(this),
      balanceOf(address(this)),
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      address(this),
      block.timestamp
    );
  }
}