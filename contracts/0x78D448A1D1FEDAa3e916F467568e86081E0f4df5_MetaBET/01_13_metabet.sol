// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract MetaBET is Context, ERC20, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Router02 public shibaswapRouter;
    address public uniswapV2Pair;
    address public shibaswapV2Pair;

    _metaBETWallets public metaBETWallets;
    _buyTaxes public buyTaxes;
    _sellTaxes public sellTaxes;

    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public pair;
    mapping (address => uint256) private _balances;

    bool public starting;
    bool public swapping;

    uint256 private _supply;
    uint256 private swapTokensAtAmount;

    // @dev All wallets are multi-sig gnosis safe's
    struct _metaBETWallets {
        address payable liquidityWallet;
        address payable devWallet;
    }

    struct _buyTaxes {
        uint256 liquidityFee;
        uint256 devFee;
        uint256 totalBuyFees;
    }

    struct _sellTaxes {
        uint256 liquidityFee;
        uint256 devFee;
        uint256 totalSellFees;
    }

    event swapRouterUpdated(
        address newUniRouter,
        address newShibaRouter
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
        uint256 LiquidityFee,
        uint256 DevFee
    );

    constructor(address payable _liquidityWallet, address payable _devWallet) ERC20 ("metaBET", "MBET") payable {

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Router address for UniSwap
        shibaswapRouter = IUniswapV2Router02(0x03f7724180AA6b939894B5Ca4314783B0b36b329); // Router address for ShibaSwap
        
        setBuyFees(0,20);
        setSellFees(0,40);

        _supply = 1 * 10 ** 8 * 10 ** decimals();

        starting = true;

        metaBETWallets.liquidityWallet = payable(_liquidityWallet);
        metaBETWallets.devWallet = payable(_devWallet);

        swapTokensAtAmount = ((_supply * 25) / 10000);

        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;

        _mint(owner(), _supply);

    }

    receive() external payable {

  	}

    function setBuyFees(
        uint256 _liquidityFee,
        uint256 _devFee
    ) public onlyOwner {
        require((_liquidityFee + _devFee) <= 50, "Taxes cannot exceed 5%");
        buyTaxes.liquidityFee = _liquidityFee;
        buyTaxes.devFee = _devFee;
        buyTaxes.totalBuyFees = (_liquidityFee + _devFee);

        emit FeesUpdated(_liquidityFee, _devFee);
    }

    function setSellFees(
        uint256 _liquidityFee,
        uint256 _devFee
    ) public onlyOwner {
        require((_liquidityFee + _devFee) <= 50, "Taxes cannot exceed 5%");
        sellTaxes.liquidityFee = _liquidityFee;
        sellTaxes.devFee = _devFee;
        sellTaxes.totalSellFees = (_liquidityFee + _devFee);

        emit FeesUpdated(_liquidityFee, _devFee);
    }


    function burn(uint256 amount) public {
        _burn(msg.sender, amount * 10 ** decimals());
    }

    function addPair(address _uniswap, address _shibaswap) external onlyOwner {

        pair[_uniswap] = true;
        uniswapV2Pair = _uniswap;
        pair[_shibaswap] = true;
        shibaswapV2Pair = _shibaswap;

        starting = false;
    }

    function updateRouterAddress(address _uniswapRouter, address _shibaswapRouter) external onlyOwner {
        
        uniswapV2Router = IUniswapV2Router02(_uniswapRouter);
        shibaswapRouter = IUniswapV2Router02(_shibaswapRouter);

         emit swapRouterUpdated(_uniswapRouter, _shibaswapRouter);
    }

    function updateSwapTokensAtAmount(uint256 swapPercentDivisibleBy10000) external onlyOwner {
        swapTokensAtAmount = ((totalSupply() * swapPercentDivisibleBy10000) / 10000);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(starting) {
            require(from == owner() || to == owner(), "Trading is not yet enabled");
        }

		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if(canSwap && !swapping && pair[to] && from != address(uniswapV2Router) && from != address(shibaswapRouter) && from != owner() && to != owner() && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]) {
            
		    contractTokenBalance = swapTokensAtAmount;
            contractTokenBalance -= (((contractTokenBalance * sellTaxes.liquidityFee) / sellTaxes.totalSellFees) / 2);
            
            swapping = true;
            
            if (sellTaxes.totalSellFees > 0) {
                
                swapTokensForEth((contractTokenBalance / 2), uniswapV2Router);
                swapTokensForEth((contractTokenBalance / 2), shibaswapRouter);

                if (sellTaxes.liquidityFee > 0) {
                    uint256 liquidityETH = ((address(this).balance * sellTaxes.liquidityFee) / sellTaxes.totalSellFees);
                
                    // add liquidity to uniswap
                    addLiquidity((((swapTokensAtAmount * sellTaxes.liquidityFee) / sellTaxes.totalSellFees) / 4), (liquidityETH / 2), uniswapV2Router);
                    addLiquidity((((swapTokensAtAmount * sellTaxes.liquidityFee) / sellTaxes.totalSellFees) / 4), (liquidityETH / 2), shibaswapRouter);

                    emit SwapAndLiquify(liquidityETH, (((swapTokensAtAmount * sellTaxes.liquidityFee) / sellTaxes.totalSellFees) / 2));   
                }
                
                if (sellTaxes.devFee > 0) {
                    uint256 devAmount = ((address(this).balance * sellTaxes.devFee) / sellTaxes.totalSellFees);
                    (bool success, ) = address(metaBETWallets.devWallet).call{value: devAmount}("");
                    require(success, "Failed to send dev fee");

                    emit TaxesSent(address(metaBETWallets.devWallet), devAmount);
                }
                
            }
			
            swapping = false;
        }

        bool takeFee = !swapping;

         // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
            super._transfer(from, to, amount);
        }

        else if(!pair[to] && !pair[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            takeFee = false;
            super._transfer(from, to, amount);
        }

        if(takeFee) {

            uint256 BuyFees = ((amount * buyTaxes.totalBuyFees) / 1000);
            uint256 SellFees = ((amount * sellTaxes.totalSellFees) / 1000);

            // if sell
            if(pair[to] && sellTaxes.totalSellFees > 0) {
                amount -= SellFees;
                
                super._transfer(from, address(this), SellFees);
                super._transfer(from, to, amount);
            }

            // if buy transfer
            else if(pair[from] && buyTaxes.totalBuyFees > 0) {
                amount -= BuyFees;

                super._transfer(from, address(this), BuyFees);
                super._transfer(from, to, amount);
                }

            else {
                super._transfer(from, to, amount);
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount, IUniswapV2Router02 swapRouter) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(swapRouter), tokenAmount);

        // add the liquidity
       swapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(metaBETWallets.liquidityWallet),
            block.timestamp
        );
    }

    function airdrop(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Arrays should be the same length");

        uint256 batchSize = 150; // The maximum number of transfers in each batch
        uint256 numBatches = (recipients.length + batchSize - 1) / batchSize; // Calculate the number of batches required

        for (uint256 i = 0; i < numBatches; i++) {
            uint256 start = i * batchSize;
            uint256 end = (i + 1) * batchSize;
            if (end > recipients.length) {
                end = recipients.length;
            }

            address[] memory batchRecipients = new address[](end - start);
            uint256[] memory batchAmounts = new uint256[](end - start);

            for (uint256 j = start; j < end; j++) {
                batchRecipients[j - start] = recipients[j];
                batchAmounts[j - start] = amounts[j];
            }

            _batchTransfer(batchRecipients, batchAmounts);
        }
    }

    function _batchTransfer(address[] memory recipients, uint256[] memory amounts) private {
        require(recipients.length == amounts.length, "Arrays should be the same length");

        for (uint256 i = 0; i < recipients.length; i++) {
            _balances[recipients[i]] += amounts[i];
            _balances[msg.sender] -= amounts[i];
            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }
    }
}