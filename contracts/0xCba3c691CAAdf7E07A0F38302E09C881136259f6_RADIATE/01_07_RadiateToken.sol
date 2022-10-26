//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.8;

interface DexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface DexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract RADIATE is ERC20, Ownable {
    struct Tax {
        uint256 marketingTax;
        uint256 liquidityTax;
    }

    uint256 private constant _totalSupply = 1e7 * 1e18;
    mapping(address => uint256) private _balances;

    //Router
    DexRouter public uniswapRouter;
    address public pairAddress;

    //Taxes
    Tax public buyTaxes = Tax(3, 3);
    Tax public sellTaxes = Tax(3, 2);
    uint256 public totalBuyFees = 5;
    uint256 public totalSellFees = 5;

    //Whitelisting from taxes/maxwallet/txlimit/etc
    mapping(address => bool) private whitelisted;

    //Swapping
    uint256 public swapTokensAtAmount = _totalSupply / 100000; //after 0.001% of total supply, swap them
    bool public swapAndLiquifyEnabled = true;
    bool public isSwapping = false;

    //Wallets
    address public MarketingWallet = 0x0463DE097425A1e494468FC01ca5fc4b38F6B28f;
    address public stakingVault = 0xa3a0a0FBAF63AAC8dFEe976a917A4436e8B71Be1;
    address public stakingContract = 0xCF06B94d9AC4733D3253740dfe3B43Db5338091f;

    constructor() ERC20("Radiate", "RAD") {
        //0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 test
        //0x10ED43C718714eb63d5aA57B78B54704E256024E Pancakeswap on mainnet
        //LFT swap on ETH 0x4f381d5fF61ad1D0eC355fEd2Ac4000eA1e67854
        //UniswapV2 on ETHMain net 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        uniswapRouter = DexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pairAddress = DexFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );

        // do not whitelist liquidity pool, otherwise there wont be any taxes
        whitelisted[msg.sender] = true;
        whitelisted[address(uniswapRouter)] = true;
        whitelisted[address(this)] = true;
        uint256 stakingVaultportion = (_totalSupply * 10) / 100;
        _mint(stakingVault, stakingVaultportion);
        _approve(stakingVault, stakingContract, ~uint256(0));
        _mint(msg.sender, _totalSupply - stakingVaultportion);
    }

    function setMarketingWallet(address _newMarketing) external onlyOwner {
        require(MarketingWallet != address(0), "new marketing wallet can not be dead address!");
        MarketingWallet = _newMarketing;
    }

    function setBuyFees(
        uint256 _lpTax,
        uint256 _marketingTax
    ) external onlyOwner {
        buyTaxes.marketingTax = _marketingTax;
        buyTaxes.liquidityTax = _lpTax;
        totalBuyFees = _lpTax + _marketingTax;
    }

    function setSellFees(
        uint256 _lpTax,
        uint256 _marketingTax
    ) external onlyOwner {
        sellTaxes.marketingTax = _marketingTax;
        sellTaxes.liquidityTax = _lpTax;
        totalSellFees = _lpTax + _marketingTax;
    }

    function setSwapTokensAtAmount(uint256 _newAmount) external onlyOwner {
        require(_newAmount > 0, "Radiate : Minimum swap amount must be greater than 0!");
        swapTokensAtAmount = _newAmount;
    }

    function toggleSwapping() external onlyOwner {
        swapAndLiquifyEnabled = (swapAndLiquifyEnabled == true) ? false : true;
    }

    function setWhitelistStatus(address _wallet, bool _status) external onlyOwner {
        whitelisted[_wallet] = _status;
    }

    function checkWhitelist(address _wallet) external view returns (bool) {
        return whitelisted[_wallet];
    }

    function _takeTax(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (whitelisted[_from] || whitelisted[_to]) {
            return _amount;
        }
        uint256 totalTax = 0;
        if (_to == pairAddress) {
            totalTax = totalSellFees;
        } else if (_from == pairAddress) {
            totalTax = totalBuyFees;
        }
        uint256 tax = (_amount * totalTax) / 100;
        super._transfer(_from, address(this), tax);
        return (_amount - tax);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        require(_from != address(0), "transfer from address zero");
        require(_to != address(0), "transfer to address zero");
        uint256 toTransfer = _takeTax(_from, _to, _amount);

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if (
            swapAndLiquifyEnabled &&
            pairAddress == _to &&
            canSwap &&
            !whitelisted[_from] &&
            !whitelisted[_to] &&
            !isSwapping
        ) {
            isSwapping = true;
            manageTaxes();
            isSwapping = false;
        }
        super._transfer(_from, _to, toTransfer);
    }

    function manageTaxes() internal {
        uint256 taxAmount = balanceOf(address(this));

        //Getting total Fee Percentages And Caclculating Portinos for each tax type
        Tax memory bt = buyTaxes;
        Tax memory st = sellTaxes;
        uint256 totalTaxes = totalBuyFees + totalSellFees;

        if(totalTaxes == 0){
            return;
        }
        
        uint256 totalMarketingTax = bt.marketingTax + st.marketingTax;
        uint256 totalLPTax = bt.liquidityTax + st.liquidityTax;
        
        //Calculating portions for each type of tax (marketing, burn, liquidity, rewards)
        uint256 lpPortion = (taxAmount * totalLPTax) / totalTaxes;
        uint256 marketingPortion = (taxAmount * totalMarketingTax) / totalTaxes;

        //Add Liquidty taxes to liqudity pool
        if(lpPortion > 0){
            swapAndLiquify(lpPortion);
        }
        
        //sending to marketing wallet
        if(marketingPortion > 0){
            swapToETH(balanceOf(address(this)));
            (bool success, ) = MarketingWallet.call{value : address(this).balance}("");
        }
    }

    function swapAndLiquify(uint256 _amount) internal {
        uint256 firstHalf = _amount / 2;
        uint256 otherHalf = _amount - firstHalf;
        uint256 initialETHBalance = address(this).balance;

        //Swapping first half to ETH
        swapToETH(firstHalf);
        uint256 received = address(this).balance - initialETHBalance;
        addLiquidity(otherHalf, received);
    }

    function swapToETH(uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), _amount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function updateDexRouter(address _newDex) external onlyOwner {
        uniswapRouter = DexRouter(_newDex);
        pairAddress = DexFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );
    }

    function withdrawStuckETH() external onlyOwner {
        (bool success, ) = address(msg.sender).call{value: address(this).balance}("");
        require(success, "transfering ETH failed");
    }

    function withdrawStuckTokens(address erc20_token) external onlyOwner {
        bool success = IERC20(erc20_token).transfer(
            msg.sender,
            IERC20(erc20_token).balanceOf(address(this))
        );
        require(success, "trasfering tokens failed!");
    }

    receive() external payable {}
    
}