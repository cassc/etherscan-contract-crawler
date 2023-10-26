// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract SAMBO is Context, ERC20, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    _samboWallets public samboWallets;
    _buyTaxes public buyTaxes;
    _sellTaxes public sellTaxes;

    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public pair;
    mapping(address => bool) public _isEarlyBuyer;
    mapping (address => uint256) private _balances;

    bool public starting;
    bool public swapping;
    bool private checkEarlyBuyer;

    uint256 private _supply;
    uint256 private swapTokensAtAmount;
    uint256 private earlyBuyerFee;
    uint256 private earlySellerFee;
    uint256 public maxWallet;
    uint256 public maxBuy;
    uint256 public maxSell;

    // @dev All wallets are multi-sig gnosis safe's
    struct _samboWallets {
        address payable alphaWallet;
        address payable devWallet;
        address payable leadWallet;
        address payable liquidityWallet;
        address payable investmentWallet;
    }

    struct _buyTaxes {
        uint256 alphaFee;
        uint256 devFee;
        uint256 leadFee;
        uint256 liquidityFee;
        uint256 investmentFee;
        uint256 totalBuyFees;
    }

    struct _sellTaxes {
        uint256 alphaFee;
        uint256 devFee;
        uint256 leadFee;
        uint256 liquidityFee;
        uint256 investmentFee;
        uint256 totalSellFees;
    }

    event MaxBuyUpdated(
        uint256 MaxBuy
    );

    event MaxSellUpdated(
        uint256 MaxSell
    );

    event MaxWalletUpdated(
        uint256 MaxWallet
    );

    event TaxesSent(
        address taxWallet,
        uint256 ETHAmount
    );

    event SwapAndLiquify(
        uint256 liquidityETH,
        uint256 half
    ); 

    event FeesUpdated(
        uint256 AlphaFee,
        uint256 DevFee,
        uint256 LeadFee,
        uint256 LiquidityFee,
        uint256 InvestmentFee
    );

    event WalletsUpdated(
        address AlphaWallet,
        address DevWallet,
        address LeadWallet,
        address LiquidityWallet,
        address InvestmentWallet
    );

    constructor(address payable _alphaWallet, address payable _devWallet, address payable _leadWallet, address payable _liquidityWallet, address payable _investmentWallet) ERC20 ("Samurai Bot", "SAMBO") Ownable(msg.sender) payable {

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Router address for UniSwap
        
        setBuyFees(10,20,15,0,5);
        setSellFees(10,20,15,0,5);

        earlyBuyerFee = 500;
        earlySellerFee = 500;

        _supply = 1 * 10 ** 9 * 10 ** decimals();

        starting = true;
        checkEarlyBuyer = true;

        samboWallets.alphaWallet = payable(_alphaWallet);
        samboWallets.devWallet = payable(_devWallet);
        samboWallets.leadWallet = payable(_leadWallet);
        samboWallets.liquidityWallet = payable(_liquidityWallet);
        samboWallets.investmentWallet = payable(_investmentWallet);

        swapTokensAtAmount = ((_supply * 25) / 10000);
        maxBuy = ((_supply * 150) / 10000);
        maxSell = ((_supply * 150) / 10000);
        maxWallet = ((_supply * 150) / 10000);

        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;

        _mint(owner(), _supply);

    }

    receive() external payable {

  	}

    function setBuyFees(
        uint256 _alphaFee,
        uint256 _devFee,
        uint256 _leadFee,
        uint256 _liquidityFee,
        uint256 _investmentFee
    ) public onlyOwner {
        require((_alphaFee + _devFee) <= 50, "Taxes cannot exceed 5%");
        buyTaxes.alphaFee = _alphaFee;
        buyTaxes.devFee = _devFee;
        buyTaxes.leadFee = _leadFee;
        buyTaxes.liquidityFee = _liquidityFee;
        buyTaxes.investmentFee = _investmentFee;
        buyTaxes.totalBuyFees = (_alphaFee + _devFee + _leadFee + _liquidityFee + _investmentFee);

        emit FeesUpdated(_alphaFee, _devFee, _leadFee, _liquidityFee, _investmentFee);
    }

    function setSellFees(
        uint256 _alphaFee,
        uint256 _devFee,
        uint256 _leadFee,
        uint256 _liquidityFee,
        uint256 _investmentFee
    ) public onlyOwner {
        require((_alphaFee + _devFee) <= 50, "Taxes cannot exceed 5%");
        sellTaxes.alphaFee = _alphaFee;
        sellTaxes.devFee = _devFee;
        sellTaxes.leadFee = _leadFee;
        sellTaxes.liquidityFee = _liquidityFee;
        sellTaxes.investmentFee = _investmentFee;
        sellTaxes.totalSellFees = (_alphaFee + _devFee + _leadFee + _liquidityFee + _investmentFee);

        emit FeesUpdated(_alphaFee, _devFee, _leadFee, _liquidityFee, _investmentFee);
    }

    function setWalletAddresses(
        address payable _alphaWallet,
        address payable _devWallet,
        address payable _leadWallet,
        address payable _liquidityWallet,
        address payable _investmentWallet
    ) external onlyOwner {
        samboWallets.alphaWallet = _alphaWallet;
        samboWallets.devWallet = _devWallet;
        samboWallets.leadWallet = _leadWallet;
        samboWallets.liquidityWallet = _liquidityWallet;
        samboWallets.investmentWallet = _investmentWallet;

        emit WalletsUpdated(_alphaWallet, _devWallet, _leadWallet, _liquidityWallet, _investmentWallet);
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet >= ((_supply * 10) / 1000), "Max Wallet cannot be less than 1.5% of Total Supply");

        maxWallet = _maxWallet;

        emit MaxWalletUpdated(_maxWallet);
    }

    function setMaxBuy(uint256 _maxBuy) external onlyOwner {
        require(_maxBuy >= ((_supply * 5) / 1000), "Max Buy cannot be less than 1.5% of Total Supply");

        maxBuy = _maxBuy;

        emit MaxBuyUpdated(_maxBuy);
    }

    function setMaxSell(uint256 _maxSell) external onlyOwner {
        require(_maxSell >= ((_supply * 5) / 1000), "Max Buy cannot be less than 1.5% of Total Supply");

        maxSell = _maxSell;

        emit MaxSellUpdated(_maxSell);
    }

    function burnRoughAmount(uint256 amount) public {
        _burn(msg.sender, amount * 10 ** decimals());
    }

    function burnExactAmount(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function addPair(address _uniswap) external onlyOwner {
        require(starting, "Trading already enabled");
        pair[_uniswap] = true;
        uniswapV2Pair = _uniswap;

        starting = false;
    }

    function disableEarlyBuyerCheck() external onlyOwner {
        require(checkEarlyBuyer, "This check is already disabled");

        checkEarlyBuyer = false;
    }

    function updateSwapTokensAtAmount(uint256 swapPercentDivisibleBy10000) external onlyOwner {
        swapTokensAtAmount = ((totalSupply() * swapPercentDivisibleBy10000) / 10000);
    }

    function excludeAddressFromFees(address _excludedAddress) external onlyOwner {
        require(!_isExcludedFromFees[_excludedAddress], "This address is already excluded from fees");

        _isExcludedFromFees[_excludedAddress] = true;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if(starting) {
            require(from == owner() || to == owner(), "Trading is not yet enabled");
        }

        if(from != owner() && to != owner() && to != address(0) && to != uniswapV2Pair && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]) {
            require(amount <= maxBuy, "Transfer amount exceeds the maxTxAmount.");
            uint256 contractBalanceRecepient = balanceOf(to);
            require(contractBalanceRecepient + amount <= maxWallet, "Exceeds maximum wallet token amount.");
        }

        if(from != owner() && to != owner() && to != address(0) && from != uniswapV2Pair && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]) {
            require(amount <= maxSell, "Transfer amount exceeds the maxTxAmount.");
        }

		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if(canSwap && !swapping && pair[to] && from != address(uniswapV2Router) && from != owner() && to != owner() && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]) {
            
		    contractTokenBalance = swapTokensAtAmount;

            if(sellTaxes.liquidityFee > 0) {
                contractTokenBalance -= (((contractTokenBalance * sellTaxes.liquidityFee) / sellTaxes.totalSellFees) / 2);
            }
            
            swapping = true;
            
            if (sellTaxes.totalSellFees > 0) {
                
                swapTokensForEth((contractTokenBalance), uniswapV2Router);

                if (sellTaxes.liquidityFee > 0) {
                    uint256 liquidityETH = ((address(this).balance * sellTaxes.liquidityFee) / sellTaxes.totalSellFees);
                
                    // add liquidity to uniswap
                    addLiquidity((((swapTokensAtAmount * sellTaxes.liquidityFee) / sellTaxes.totalSellFees) / 2), liquidityETH);

                    emit SwapAndLiquify(liquidityETH, (((swapTokensAtAmount * sellTaxes.liquidityFee) / sellTaxes.totalSellFees) / 2));   
                }

                if (sellTaxes.alphaFee > 0) {
                    uint256 alphaAmount = ((address(this).balance * sellTaxes.alphaFee) / sellTaxes.totalSellFees);
                    (bool success, ) = address(samboWallets.alphaWallet).call{value: alphaAmount}("");
                    require(success, "Failed to send alpha fee");
                    
                    emit TaxesSent(address(samboWallets.alphaWallet), alphaAmount);
                }
                
                if (sellTaxes.devFee > 0) {
                    uint256 devAmount = ((address(this).balance * sellTaxes.devFee) / sellTaxes.totalSellFees);
                    (bool success, ) = address(samboWallets.devWallet).call{value: devAmount}("");
                    require(success, "Failed to send dev fee");

                    emit TaxesSent(address(samboWallets.devWallet), devAmount);
                }

                if (sellTaxes.leadFee > 0) {
                    uint256 leadAmount = ((address(this).balance * sellTaxes.leadFee) / sellTaxes.totalSellFees);
                    (bool success, ) = address(samboWallets.leadWallet).call{value: leadAmount}("");
                    require(success, "Failed to send lead fee");

                    emit TaxesSent(address(samboWallets.leadWallet), leadAmount);
                }

                if (sellTaxes.investmentFee > 0) {
                    uint256 investmentAmount = address(this).balance;
                    (bool success, ) = address(samboWallets.investmentWallet).call{value: investmentAmount}("");
                    require(success, "Failed to send Investment fee");

                    emit TaxesSent(address(samboWallets.investmentWallet), investmentAmount);
                }
                
            }
			
            swapping = false;
        }

        bool takeFee = !swapping;

        uint256 BuyFees = ((amount * buyTaxes.totalBuyFees) / 1000);
        uint256 SellFees = ((amount * sellTaxes.totalSellFees) / 1000);
        uint256 EarlyBuyerFees = ((amount * earlyBuyerFee) / 1000);
        uint256 EarlySellerFees = ((amount * earlySellerFee) / 1000);

         // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
            super._update(from, to, amount);
        }

        else if(!pair[to] && !pair[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            if(_isEarlyBuyer[to] || _isEarlyBuyer[from]) {
                amount -= EarlyBuyerFees;

                super._update(from, address(this), EarlyBuyerFees);
                super._update(from, to, amount);
            } else {
                takeFee = false;
                super._update(from, to, amount);
            }
        }

        if(takeFee) {

            // if early buyer
            if(pair[from] && _isEarlyBuyer[to]) {
                amount -= EarlyBuyerFees;

                super._update(from, address(this), EarlyBuyerFees);
                super._update(from, to, amount);
            }

            if(pair[to] && _isEarlyBuyer[from]) {
                amount -= EarlySellerFees;

                super._update(from, address(this), EarlySellerFees);
                super._update(from, to, amount);
            }

            // if sell
            else if(pair[to] && sellTaxes.totalSellFees > 0) {
                amount -= SellFees;
                
                super._update(from, address(this), SellFees);
                super._update(from, to, amount);
            }

            // if buy transfer
            else if(pair[from] && buyTaxes.totalBuyFees > 0) {

                if(checkEarlyBuyer) {
                    _isEarlyBuyer[to] = true;

                    amount -= EarlyBuyerFees;

                    super._update(from, address(this), EarlyBuyerFees);
                    super._update(from, to, amount);
                } else {

                    amount -= BuyFees;

                    super._update(from, address(this), BuyFees);
                    super._update(from, to, amount);
                    }
            }

            else {
                super._update(from, to, amount);
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount, IUniswapV2Router02 swapRouter) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        _approve(address(this), address(swapRouter), tokenAmount);

        // make the swap
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
       uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(samboWallets.liquidityWallet),
            block.timestamp
        );
    }
}