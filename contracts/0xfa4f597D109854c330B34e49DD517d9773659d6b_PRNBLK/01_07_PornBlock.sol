//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.17;

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

contract PRNBLK is ERC20, Ownable {

    struct Tax {
        uint256 DevTax;
        uint256 liquidityTax;
    }

    uint256 private constant _totalSupply = 69e6 * 1e18;

    //Router
    DexRouter public uniswapRouter;
    address public pairAddress;

    //Taxes
    Tax public buyTaxes = Tax(4, 2);
    Tax public sellTaxes = Tax(6, 3);
    uint256 public totalBuyFees = 6;
    uint256 public totalSellFees = 9;

    //Whitelisting from taxes/maxwallet/txlimit/etc
    mapping(address => bool) private whitelisted;

    //Swapping
    uint256 public swapTokensAtAmount = _totalSupply / 100000; //after 0.001% of total supply, swap them
    bool public swapAndLiquifyEnabled = true;
    bool public isSwapping = false;
    bool public tradingStatus = false;

    //Wallets
    address public DevWallet = 0x937cd3a2A18bEC7F090DD444826b2c8f92d7EC05;

    constructor() ERC20("Porn Block", "PRNBLK") {
        //0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 test
        //0x10ED43C718714eb63d5aA57B78B54704E256024E Pancakeswap on mainnet
        //LFT swap on ETH 0x4f381d5fF61ad1D0eC355fEd2Ac4000eA1e67854
        //UniswapV2 on ETHMain net 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        uniswapRouter = DexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // do not whitelist liquidity pool, otherwise there wont be any taxes
        whitelisted[msg.sender] = true;
        whitelisted[address(uniswapRouter)] = true;
        whitelisted[address(this)] = true;

        _mint(msg.sender, _totalSupply);
    }

    function initializePair(address _pairAddress) external onlyOwner{
        pairAddress = _pairAddress;
        tradingStatus = true;
    }

    function setDevWallet(address _newDev) external onlyOwner {
        DevWallet = _newDev;
    }

    function setBuyFees(
        uint256 _lpTax,
        uint256 _DevTax
    ) external onlyOwner {
        buyTaxes.DevTax = _DevTax;
        buyTaxes.liquidityTax = _lpTax;
        totalBuyFees = _lpTax + _DevTax;
    }

    function setSellFees(
        uint256 _lpTax,
        uint256 _DevTax
    ) external onlyOwner {
        sellTaxes.DevTax = _DevTax;
        sellTaxes.liquidityTax = _lpTax;
        totalSellFees = _lpTax + _DevTax;
    }

    function setSwapTokensAtAmount(uint256 _newAmount) external onlyOwner {
        require(_newAmount > 0, "PRNBLK : Minimum swap amount must be greater than 0!");
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
        require(tradingStatus, "Trading is not enabled yet!");
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
        
        uint256 totalDevTax = bt.DevTax + st.DevTax;
        uint256 totalLPTax = bt.liquidityTax + st.liquidityTax;
        
        //Calculating portions for each type of tax (Dev, burn, liquidity, rewards)
        uint256 lpPortion = (taxAmount * totalLPTax) / totalTaxes;
        uint256 DevPortion = (taxAmount * totalDevTax) / totalTaxes;

        //Add Liquidty taxes to liqudity pool
        if(lpPortion > 0){
            swapAndLiquify(lpPortion);
        }
        
        //sending to Dev wallet
        if(DevPortion > 0){
            swapToETH(balanceOf(address(this)));
            (bool success, ) = DevWallet.call{value : address(this).balance}("");
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