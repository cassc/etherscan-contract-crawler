//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract Token is Context, ERC20, Ownable {
    address payable public operationsWallet;

    uint256 public marketingSellFee = 400; // 4%
    uint256 public devSellFee = 400; // 4%

    uint256 public liquidityBuyFee = 100; // 1%
    uint256 public marketingBuyFee = 500; // 5%
    uint256 public devBuyFee = 200; // 2%

    uint256 public maxTxAmountPerc = 200; // 2%
    uint256 public maxWalletAmountPerc = 200; // 2%

    uint256 public divisor = 10000;

    uint256 public totalSellFee;
    uint256 public totalBuyFee;

    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;
    uint256 public swapTokensAtAmount;

    uint256 public liquidityTokens = 0;

    bool public enableTxLimit = true;
    bool public enableFee = true;
    bool public enableWalletLimit = true;
    bool public enableSwap = true;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromWalletLimit;
    mapping(address => bool) public isExcludedFromTxLimit;
    mapping(address => bool) public automatedMarketPairs;

    IUniswapV2Router02 public router;

    address public pair;

    bool private swapping;

    constructor(
        uint256 _totalSupply,
        address _operationsWallet,
        address _routerAddress
    ) ERC20('Fuck Aped', 'FKAPED') {
        _mint(_msgSender(), _totalSupply * 10 ** decimals());

        operationsWallet = payable(_operationsWallet);

        router = IUniswapV2Router02(_routerAddress);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        _approve(address(this), address(router), type(uint256).max);

        totalSellFee = devSellFee + marketingSellFee;
        totalBuyFee = devBuyFee + marketingBuyFee + liquidityBuyFee;

        maxTxAmount = (totalSupply() * maxTxAmountPerc) / divisor;
        maxWalletAmount = (totalSupply() * maxWalletAmountPerc) / divisor;
        swapTokensAtAmount = (totalSupply() * 5) / divisor; // 0.05 %

        automatedMarketPairs[pair] = true;

        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[operationsWallet] = true;
        isExcludedFromFee[address(router)] = true;

        isExcludedFromWalletLimit[_msgSender()] = true;
        isExcludedFromWalletLimit[address(this)] = true;
        isExcludedFromWalletLimit[operationsWallet] = true;
        isExcludedFromWalletLimit[address(router)] = true;
        isExcludedFromWalletLimit[pair] = true;

        isExcludedFromTxLimit[_msgSender()] = true;
        isExcludedFromTxLimit[address(this)] = true;
        isExcludedFromTxLimit[operationsWallet] = true;
        isExcludedFromTxLimit[address(router)] = true;
        isExcludedFromTxLimit[pair] = true;
    }

    receive() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        //when buy
        if (
            enableTxLimit &&
            automatedMarketPairs[from] &&
            !isExcludedFromTxLimit[to]
        ) {
            require(
                amount <= maxTxAmount,
                'Buy transfer exeeds maximum allowed.'
            );
        }
        //when sell
        else if (
            enableTxLimit &&
            automatedMarketPairs[to] &&
            !isExcludedFromTxLimit[from]
        ) {
            require(
                amount <= maxTxAmount,
                'Sell transfer exeeds maximum allowed.'
            );
        }
        // when transfer
        else if (enableTxLimit && !isExcludedFromTxLimit[from]) {
            require(amount <= maxTxAmount, 'Transfer exeeds maximum allowed.');
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool isContractBalanceOverMinimum = contractTokenBalance >=
            swapTokensAtAmount;

        if (
            enableSwap &&
            !swapping &&
            !automatedMarketPairs[from] &&
            isContractBalanceOverMinimum
        ) {
            swapping = true;

            swap(contractTokenBalance);

            swapping = false;
        }

        bool takeFee = !swapping;

        if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
            takeFee = false;
        }

        if (takeFee && enableFee) {
            uint256 fees = 0;

            // on sell
            if (automatedMarketPairs[to]) {
                fees = (amount * totalSellFee) / divisor;
            }
            // on buy
            if (automatedMarketPairs[from]) {
                fees = (amount * totalBuyFee) / divisor;
                liquidityTokens += (amount * liquidityBuyFee) / divisor;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        //when buy
        if (
            enableWalletLimit &&
            automatedMarketPairs[from] &&
            !isExcludedFromWalletLimit[to]
        ) {
            require(
                balanceOf(to) + amount <= maxWalletAmount,
                'Buy transfer exeeds maximum allowed.'
            );
        }
        // when transfer
        else if (enableWalletLimit && !isExcludedFromWalletLimit[to]) {
            require(
                balanceOf(to) + amount <= maxWalletAmount,
                'Transfer exeeds maximum allowed.'
            );
        }

        super._transfer(from, to, amount);
    }

    function swap(uint256 contractTokens) private {
        uint256 swapTokens = contractTokens - liquidityTokens;

        if (swapTokens > swapTokensAtAmount * 5) {
            swapTokens = swapTokensAtAmount * 5;
        }

        swapTokensForEth(swapTokens);

        uint256 currEthBalance = address(this).balance;

        if (currEthBalance > 0) {
            payable(operationsWallet).transfer(currEthBalance);
        }

        if (liquidityTokens > 0) {
            uint256 lpEthTokens = (liquidityTokens * 5000) / divisor;
            liquidityTokens -= lpEthTokens;

            swapTokensForEth(lpEthTokens);

            uint256 lpEthBalance = address(this).balance;

            if (liquidityTokens > 0 && lpEthBalance > 0) {
                addLiquidity(liquidityTokens, lpEthBalance);

                liquidityTokens = 0;
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        super._approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        super._approve(address(this), address(router), tokenAmount);

        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            operationsWallet,
            block.timestamp
        );
    }

    function setOperationsWallet(address _operationsWallet) external onlyOwner {
        operationsWallet = payable(_operationsWallet);
    }

    function setEnableTxLimit(bool value) external onlyOwner {
        enableTxLimit = value;
    }

    function setEnableFee(bool value) external onlyOwner {
        enableFee = value;
    }

    function setEnableWalletLimit(bool value) external onlyOwner {
        enableWalletLimit = value;
    }

    function setEnableSwap(bool value) external onlyOwner {
        enableSwap = value;
    }

    function setIsExcludedFromFee(address addr, bool value) external onlyOwner {
        isExcludedFromFee[addr] = value;
    }

    function setIsExcludedFromWalletLimit(
        address addr,
        bool value
    ) external onlyOwner {
        isExcludedFromWalletLimit[addr] = value;
    }

    function setIsExcludedFromTxLimit(
        address addr,
        bool value
    ) external onlyOwner {
        isExcludedFromTxLimit[addr] = value;
    }

    function setAutomatedMarketPairs(
        address addr,
        bool value
    ) external onlyOwner {
        automatedMarketPairs[addr] = value;
    }
}