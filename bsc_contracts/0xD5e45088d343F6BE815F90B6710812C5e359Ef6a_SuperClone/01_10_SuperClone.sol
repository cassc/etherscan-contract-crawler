// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BEP20Detailed.sol";
import "./BEP20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract SuperClone is BEP20Detailed, BEP20 {
    mapping(address => bool) private isBlacklist;
    address public immutable uniswapV2Pair;

    address payable private marketingAddress =
        payable(address(0)); // Marketing Address

    uint8 private buyTax;
    uint8 private sellTax;
    uint256 private taxAmount;
    uint8 private totalFee;

    event changeBlacklist(address _wallet, bool status);
    event changeCooldown(uint8 tradeCooldown);
    event changeTax(uint8 _sellTax, uint8 _buyTax);
    event changeLiquidityPoolStatus(address lpAddress, bool status);
    event SwapTokensForETH(uint256 amountIn, address[] path);

    uint256 private minimumTokensBeforeSwap = 5 * 10^18;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    IUniswapV2Router02 public immutable uniswapV2Router;

    constructor() BEP20Detailed("SuperClone", "SPC", 18) {
        uint256 totalTokens = 100000000 * 10**uint256(decimals());
        marketingAddress = payable(msg.sender);
        _mint(msg.sender, totalTokens);
        totalFee = 6;
        sellTax = 5;
        buyTax = 1;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
    }

    function setBlacklist(address _wallet, bool _status) external onlyOwner {
        isBlacklist[_wallet] = _status;
        emit changeBlacklist(_wallet, _status);
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = payable(_marketingAddress);
    }

    function setTaxes(
        uint8 _sellTax,
        uint8 _buyTax
    ) external onlyOwner {
        require(_sellTax + _buyTax < 20);
        sellTax = _sellTax;
        buyTax = _buyTax;
        emit changeTax(_sellTax, _buyTax);
    }

    function getTaxes()
        external
        view
        returns (
            uint8 _sellTax,
            uint8 _buyTax
        )
    {
        return (sellTax, buyTax);
    }


    function _transfer(
        address sender,
        address receiver,
        uint256 amount
    ) internal virtual override {
        require(!isBlacklist[sender], "User blacklisted");
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            minimumTokensBeforeSwap;

        if (
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            receiver == uniswapV2Pair
        ) {
            if (overMinimumTokenBalance) {
                contractTokenBalance = minimumTokensBeforeSwap;
                swapTokens(contractTokenBalance);
            }
        }
        if (sender == uniswapV2Pair) {
            //It's an LP Pair and it's a buy
            taxAmount = (amount * buyTax) / 100;
        } else if (receiver == uniswapV2Pair) {
            //It's an LP Pair and it's a sell
            taxAmount = (amount * sellTax) / 100;
        }
        else{
            taxAmount = 0;
        }
        if(taxAmount > 0) {
            super._transfer(sender, address(this), taxAmount);
        }   
        super._transfer(sender, receiver, amount - taxAmount);
    }

    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
        swapTokensForEth(contractTokenBalance);
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
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }
    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap)
        external
        onlyOwner
    {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }
    //Withdraw section
    function transferToAddressETH(address payable recipient, uint256 amount)
        private
    {
        recipient.transfer(amount);
    }
}