// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

contract DiabloToken is ERC20, Ownable {
  using SafeMath for uint256;

  IUniswapV2Router02 public immutable uniswapV2Router;
  address public immutable uniswapV2Pair;
  address public constant deadAddress = address(0xdead);

  bool private swapping;

  address public deployerAddress;
  address public ecoSystemWallet;
  address public strategicWallet;

  uint256 public maxTransactionAmount;
  uint256 public swapTokensAtAmount;
  uint256 public maxWallet;

  bool public swapEnabled = true;

  uint256 public buyTotalFees;
  uint256 public buyMarketingFee;
  uint256 public buyLiquidityFee;
  uint256 public buyBurnFee;

  uint256 public sellTotalFees;
  uint256 public sellMarketingFee;
  uint256 public sellLiquidityFee;
  uint256 public sellBurnFee;

  uint256 public tokensForMarketing;
  uint256 public tokensForLiquidity;
  uint256 public tokensForBurn;

  /******************/

  mapping(address => bool) private _isExcludedFromFees;
  mapping(address => bool) public _isExcludedMaxTransactionAmount;

  mapping(address => bool) public automatedMarketMakerPairs;

  event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

  event ExcludeFromFees(address indexed account, bool isExcluded);

  event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

  event strategicWalletUpdated(address indexed newWallet, address indexed oldWallet);
  event ecosystemWalletUpdated(address indexed newWallet, address indexed oldWallet);
  event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

  event BuyBackTriggered(uint256 amount);

  constructor() ERC20('DiabloToken', 'DIABLO') {
    address newOwner = address(owner());

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    excludeFromMaxTransaction(address(_uniswapV2Router), true);
    uniswapV2Router = _uniswapV2Router;

    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    excludeFromMaxTransaction(address(uniswapV2Pair), true);
    _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

    uint256 _buyMarketingFee = 3;
    uint256 _buyLiquidityFee = 0;
    uint256 _buyBurnFee = 0;

    uint256 _sellMarketingFee = 3;
    uint256 _sellLiquidityFee = 0;
    uint256 _sellBurnFee = 0;

    uint256 totalSupply = 666666666 * 10 ** decimals();

    maxTransactionAmount = (totalSupply * 1) / 100; // 1% maxTransactionAmountTxn
    swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05% swap wallet
    maxWallet = (totalSupply * 1) / 100; // 1% max wallet

    buyMarketingFee = _buyMarketingFee;
    buyLiquidityFee = _buyLiquidityFee;
    buyBurnFee = _buyBurnFee;
    buyTotalFees = buyMarketingFee + buyLiquidityFee + buyBurnFee;

    sellMarketingFee = _sellMarketingFee;
    sellLiquidityFee = _sellLiquidityFee;
    sellBurnFee = _sellBurnFee;
    sellTotalFees = sellMarketingFee + sellLiquidityFee + sellBurnFee;

    deployerAddress = address(0x1001f784FBed1B19A4Bf56ae5C8f8fA2A111d993);
    strategicWallet = address(0x1fF6CEA679eA9651C120509F479b0804bdBa4745);
    ecoSystemWallet = address(0x8A57aca7f2d4554351821B72D8fE66BA7Ea3e774);

    excludeFromFees(newOwner, true); // Owner address
    excludeFromFees(address(this), true); // CA
    excludeFromFees(address(0xdead), true); // Burn address
    excludeFromFees(strategicWallet, true); // Marketing wallet
    excludeFromFees(ecoSystemWallet, true); // ecosystem wallet
    excludeFromFees(deployerAddress, true); // Deployer Address

    excludeFromMaxTransaction(newOwner, true); // Owner address
    excludeFromMaxTransaction(address(this), true); // CA
    excludeFromMaxTransaction(address(0xdead), true); // Burn address
    excludeFromMaxTransaction(strategicWallet, true); // Marketing wallet
    excludeFromMaxTransaction(ecoSystemWallet, true); // ecosystem wallet
    excludeFromMaxTransaction(deployerAddress, true); // Deployer Address

    /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
    _mint(newOwner, totalSupply);

    transferOwnership(newOwner);
  }

  receive() external payable {}

  function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool) {
    require(newAmount >= (totalSupply() * 1) / 100000, 'Swap amount cannot be lower than 0.001% total supply.');
    require(newAmount <= (totalSupply() * 5) / 1000, 'Swap amount cannot be higher than 0.5% total supply.');
    swapTokensAtAmount = newAmount;
    return true;
  }

  function updateMaxAmount(uint256 newNum) external onlyOwner {
    require(newNum >= ((totalSupply() * 5) / 1000) / 1e9, 'Cannot set maxTransactionAmount lower than 0.5%');
    maxTransactionAmount = newNum * (10 ** 18);
  }

  function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
    _isExcludedMaxTransactionAmount[updAds] = isEx;
  }

  function updateSwapEnabled(bool enabled) external onlyOwner {
    swapEnabled = enabled;
  }

  function updateBuyFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _burnFee) external onlyOwner {
    buyMarketingFee = _marketingFee;
    buyLiquidityFee = _liquidityFee;
    buyBurnFee = _burnFee;
    buyTotalFees = buyMarketingFee + buyLiquidityFee + buyBurnFee;
    require(buyTotalFees <= 10, 'Must keep fees at 10% or less');
  }

  function updateSellFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _burnFee) external onlyOwner {
    sellMarketingFee = _marketingFee;
    sellLiquidityFee = _liquidityFee;
    sellBurnFee = _burnFee;
    sellTotalFees = sellMarketingFee + sellLiquidityFee + sellBurnFee;
    require(sellTotalFees <= 99, 'Must keep fees at 99% or less');
  }

  function removeLimits() external onlyOwner {
    maxTransactionAmount = totalSupply();
    maxWallet = totalSupply();
  }

  function excludeFromFees(address account, bool excluded) public onlyOwner {
    _isExcludedFromFees[account] = excluded;
    emit ExcludeFromFees(account, excluded);
  }

  function excludeWalletsFromFees(address[] memory accounts, bool excluded) public onlyOwner {
    for (uint i = 0; i < accounts.length; i++) {
      excludeFromFees(accounts[i], excluded);
    }
  }

  function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
    require(pair != uniswapV2Pair, 'The pair cannot be removed from automatedMarketMakerPairs');

    _setAutomatedMarketMakerPair(pair, value);
  }

  function _setAutomatedMarketMakerPair(address pair, bool value) private {
    automatedMarketMakerPairs[pair] = value;

    emit SetAutomatedMarketMakerPair(pair, value);
  }

  function updateStrategicWallet(address newMarketingWallet) external onlyOwner {
    emit strategicWalletUpdated(newMarketingWallet, strategicWallet);
    strategicWallet = newMarketingWallet;
  }

  function updateEcosystemWallet(address newEcosystemWallet) external onlyOwner {
    emit ecosystemWalletUpdated(newEcosystemWallet, ecoSystemWallet);
    ecoSystemWallet = newEcosystemWallet;
  }

  function isExcludedFromFees(address account) public view returns (bool) {
    return _isExcludedFromFees[account];
  }

  function _transfer(address from, address to, uint256 amount) internal override {
    require(from != address(0), 'ERC20: transfer from the zero address');
    require(to != address(0), 'ERC20: transfer to the zero address');

    if (amount == 0) {
      super._transfer(from, to, 0);
      return;
    }

    if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
      //when buy
      if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
        require(amount <= maxTransactionAmount, 'Buy transfer amount exceeds the maxTransactionAmount.');
        require(amount + balanceOf(to) <= maxWallet, 'Max wallet exceeded');
      }
      //when sell
      else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
        require(amount <= maxTransactionAmount, 'Sell transfer amount exceeds the maxTransactionAmount.');
      } else if (!_isExcludedMaxTransactionAmount[to]) {
        require(amount + balanceOf(to) <= maxWallet, 'Max wallet exceeded');
      }
    }

    uint256 contractTokenBalance = balanceOf(address(this));

    bool canSwap = contractTokenBalance >= swapTokensAtAmount;

    if (
      canSwap &&
      swapEnabled &&
      !swapping &&
      !automatedMarketMakerPairs[from] &&
      !_isExcludedFromFees[from] &&
      !_isExcludedFromFees[to]
    ) {
      swapping = true;

      swapBack();

      swapping = false;
    }

    bool takeFee = !swapping;

    if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
      takeFee = false;
    }

    uint256 fees = 0;
    // only take fees on buys/sells, do not take on wallet transfers
    if (takeFee) {
      if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
        fees = amount.mul(sellTotalFees).div(100);
        tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
        tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
        tokensForBurn += (fees * sellBurnFee) / sellTotalFees;
      }
      // on buy
      else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        fees = amount.mul(buyTotalFees).div(100);
        tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
        tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
        tokensForBurn += (fees * buyBurnFee) / buyTotalFees;
      }

      if (fees > 0) {
        super._transfer(from, address(this), (fees - tokensForBurn));
      }

      if (tokensForBurn > 0) {
        super._transfer(from, deadAddress, tokensForBurn);
        tokensForBurn = 0;
      }

      amount -= fees;
    }

    super._transfer(from, to, amount);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      address(this),
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, deadAddress, block.timestamp);
  }

  function swapBack() private {
    uint256 contractBalance = balanceOf(address(this));
    uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing;

    if (contractBalance == 0 || totalTokensToSwap == 0) {
      return;
    }

    uint256 liquidityTokens = (contractBalance * tokensForLiquidity) / totalTokensToSwap / 2;
    uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

    uint256 initialETHBalance = address(this).balance;

    swapTokensForEth(amountToSwapForETH);

    uint256 ethBalance = address(this).balance.sub(initialETHBalance);

    uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);

    uint256 ethForLiquidity = ethBalance - ethForMarketing;
    tokensForLiquidity = 0;
    tokensForMarketing = 0;

    (bool success, ) = address(ecoSystemWallet).call{value: ethForMarketing}('');
    if (liquidityTokens > 0 && ethForLiquidity > 0) {
      addLiquidity(liquidityTokens, ethForLiquidity);
      emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
    }

    (success, ) = address(ecoSystemWallet).call{value: address(this).balance}('');
  }
}