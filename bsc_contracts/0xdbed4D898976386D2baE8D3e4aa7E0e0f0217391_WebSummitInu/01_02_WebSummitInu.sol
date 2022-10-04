/**
WebSummitInu V1

For those that find this piece of code early Kudos!
You are experts in searching for the 🦄 Unicorns 🦄 on Chain!
Enjoy the gem and the collective hopes you can make it to the Gathering!


For more info visit:
https://www.websummitinu.com




                                       @
                                    @@[email protected]@
                 @@@@@@/           @([email protected]
               @**@@%,,[email protected]@#       @@#[email protected]@               [email protected]@@*
             (@*@@ ,*@@,,,[email protected]@   /@,[email protected]        /@@@,,,,,/%*%@
             @*@%   *@*@@,,,[email protected]@&@@@@@@@%[email protected]@   &@@,,,,,@@/**  @/@@
            @@@@  [email protected]//@@@/,,,,,@,,,,,,,,,,@@@@/,,,,,@@@@*,    @@*@
            @*@**&@#,,,,,,,,,,&@,,,,#@@@@,@@,,,,,,,@**@@*     @@*@
            @*@@,,,,,,,,,,,,,,,,,,@@@@@@@@@,,,,,,,,,%@@@@**   @*@@
            @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@%**%@*@@
          (@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@**@
         @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/@@
        @%,,,,,,,,,.      ,,,,,,,,,,,,   .,,,,,,,,,,,,,,,,,,,,,,@
       @(,,,,,,,,,,,,,.,,,,,,,,,,,,,,.      ,,,,,,,,,,,,,,,,,,,,,@
      @/,,,,,,,,@@  @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&
    @@,,,,,,,,,@@# &@@@@,,,,,,,,,,,,,,,,@@/@@,,,,,,,,,,,,,,,,,,,,,@,
   @%****** ,,,@@@@@@@@*,,,,,,,,,,,,,,,@   @@@@,,,,,,,,,,,,,,,,,,,,@
  @(**********  @@@@/@,. @@@@@@@  ,,,,@@@@@@@@@,,,,,,,,,,,,,,,,,,,,@(
  @***********             @@@@%     .,@@@@/@@,,,,,..,,,,,,,,,,,,,,@(((
  @*********.          @  [email protected]            *   ************     ,,,,@((((
  ,@                         @@@@@(          ***************.     @@((((((
    @@                                       ,***************     @((((((((
      @@..                                       *********.     [email protected](((((((((((
         @@&...                                              [email protected]@(((((((((((((
             ,@@@.....*                                 [email protected]@#(((((((((((((((((
                    @@@@,[email protected]@@&((((((((((((((((((((((   [email protected]@%[email protected]@@@@@[email protected]@@
                  @@@@@@............*&@@@@@@@@@@%(((((((((((((((((((((((((((((((((@@@@************@@[email protected]@
                 @@@@@@@@............,,,,,,,(((((((((((((((((((((((((((((((((((((@@@**@@@%%%%%@@*****@[email protected]#
               @@@@@@@@@@..........,,,,,,,,(((((((((((((((((((((((((((((((((((((#@%*(@%%%%%%%%%%%@****@([email protected](
              @@@@@@@@@@@@........,,,,,,,((((((((((((((((((((((((((((((((((((((((@**@&%&@@@%%%%%%@@****@[email protected]
            @@@@@@@@@@@@@@@[email protected],,,,,((((((((((((((((((((((((((((((((((((((((((@@%@%@  @@%%%%%&@****@[email protected]
           @@@@@@@@@@@@@**%@[email protected]&,,,*(((((((((((((((((((((((((((((((((((((((((((((((((((@%%%%%%@*****@[email protected]
         ,@@@@@@@@@@@@@@,,**@([email protected]#,,((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%@*****@[email protected]
        @@@@@@@@@@@@@@@@,,,,**@/[email protected],,((((((((((((((((((((((((((((((((((((((((((((((((((((((((#@@******@[email protected]
       @@@@@@@@@@@@@@@@@,,,,,,**@@((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((****@@[email protected]@
     @@@@@@@@@@@@@@@@@@,,,,,,,,**((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@[email protected]@
    @@@@@@@@@@@@@@@@@@@@/,,,,,,(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((([email protected]@&
  @@@@@@@@@@@@@@@@@ #       @@((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((.
 @@@@@@@@@@@@@@@@@@*@[email protected]((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
*/

// SPDX-License-Identifier: MIT

import "./utils/WebSummitInuUtils.sol";

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

contract WebSummitInu is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    address public USDC = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    bool private swapping;

    address public unicornWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public buyTotalFees;
    uint256 public buyUnicornFee;
    uint256 public buyLiquidityFee;

    uint256 public sellTotalFees;
    uint256 public sellUnicornFee;
    uint256 public sellLiquidityFee;

    /******************/

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) private _isNonFrenBot;
    event ExcludeFromFees(address indexed account, bool isExcluded);

    event unicornWalletUpdated(address indexed newWallet, address indexed oldWallet);

    constructor() ERC20("Web Summit Inu", "WSI") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), USDC);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);

        uint256 _buyUnicornFee = 5;
        uint256 _buyLiquidityFee = 1;

        uint256 _sellUnicornFee = 7;
        uint256 _sellLiquidityFee = 2;

        uint256 totalSupply = 144_000_000_000 * 1e18;

        maxTransactionAmount = (totalSupply * 1) / 100; // 1% from total supply maxTransactionAmountTxn
        maxWallet = (totalSupply * 3) / 100; // 2% from total supply maxWallet
        swapTokensAtAmount = (totalSupply * 6) / 10000; // 0.05% swap wallet

        buyUnicornFee = _buyUnicornFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyTotalFees = buyUnicornFee + buyLiquidityFee;

        sellUnicornFee = _sellUnicornFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellTotalFees = sellUnicornFee + sellLiquidityFee;

        unicornWallet = address(0x047f3B3a47BC81078BB2D3C7dca7F8f325131840); // set as unicorn wallet

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
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
        require(newAmount <= (totalSupply() * 5) / 1000, "Swap amount cannot be higher than 0.5% total supply.");
        swapTokensAtAmount = newAmount;
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

    // only use to updateRouter if absolutely necessary (emergency use only)
    function updateRouter(address router) external onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
    }

    // only use to updatePair if absolutely necessary (emergency use only)
    function updatePair(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
        excludeFromMaxTransaction(address(_uniswapV2Pair), true);
    }

    // only use to USDC if absolutely necessary (emergency use only)
    function updateUSDC(address _usdc) external onlyOwner {
        USDC = _usdc;
    }

    function updateBuyFees(uint256 _devFee, uint256 _liquidityFee) external onlyOwner {
        buyUnicornFee = _devFee;
        buyLiquidityFee = _liquidityFee;
        buyTotalFees = buyUnicornFee + buyLiquidityFee;
        require(buyTotalFees <= 15, "Must keep fees at 15% or less");
    }

    function updateSellFees(uint256 _devFee, uint256 _liquidityFee) external onlyOwner {
        sellUnicornFee = _devFee;
        sellLiquidityFee = _liquidityFee;
        sellTotalFees = sellUnicornFee + sellLiquidityFee;
        require(sellTotalFees <= 15, "Must keep fees at 15% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setBots(address[] calldata _addresses, bool bot) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _isNonFrenBot[_addresses[i]] = bot;
        }
    }

    function updateUnicornWallet(address newUnicornWallet) external onlyOwner {
        emit unicornWalletUpdated(newUnicornWallet, unicornWallet);
        unicornWallet = newUnicornWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function somethingAboutTokens(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isNonFrenBot[from] && !_isNonFrenBot[to], "no non frens allowed");

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
        uint256 tokensForGathering = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (to == uniswapV2Pair && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity = (fees * sellLiquidityFee) / sellTotalFees;
                tokensForGathering = (fees * sellUnicornFee) / sellTotalFees;
            }
            // on buy
            else if (from == uniswapV2Pair && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity = (fees * buyLiquidityFee) / buyTotalFees;
                tokensForGathering = (fees * buyUnicornFee) / buyTotalFees;
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
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of USDC
            path,
            unicornWallet,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        swapTokensForUSDC(contractBalance);
    }
}