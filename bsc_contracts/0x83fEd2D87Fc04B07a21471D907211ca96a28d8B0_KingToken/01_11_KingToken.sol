// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract KingToken is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address constant public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant public PANCAKE_SWAP_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    uint256 constant public PROCENT_DENOMINATOR = 100; // 100%
    uint256 constant public TOTAL_SUPPLY = 25_000_000*1e18; // 25 000 000

    uint256 public marketingProcent = 75;
    uint256 public liquidiyProcent = 25;

    uint256 public buyTax = 4; // 4%
    uint256 public sellTax = 8; // 8%
    uint256 public swapThreshold = 1000 * 1e18; // 1000 

    address private _pair;
    IUniswapV2Factory private _factory;
    IUniswapV2Router02 private _router;

    bool public swapAndLiquifyEnabled;
    bool private _inSwapAndLiquify;    

    mapping(address => bool) public excludedFromFees;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap(){
        _inSwapAndLiquify = true;
        _; 
        _inSwapAndLiquify = false; 
    }

    //to receive BNB from pancakeswapV2Router when swapping
    receive() external payable {}

    constructor() ERC20("KingToken", "$KING"){
        _router = IUniswapV2Router02(PANCAKE_SWAP_ROUTER);
        _pair = IUniswapV2Factory(_router.factory()).createPair(WBNB, address(this));

        excludedFromFees[address(this)] = true;
        excludedFromFees[address(0)] = true;
        excludedFromFees[msg.sender] = true;

        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setSwapBackSettings(uint256 amount) external onlyOwner {
        swapThreshold = amount;
    }

    function setExcludeFromFees(address _wallet, bool _state) external onlyOwner {
        excludedFromFees[_wallet] = _state;
    }

    function setTaxValues(uint256 _buyTax, uint256 _sellTax) external onlyOwner {
        require(_buyTax >= 0 && _buyTax <= 20, 'TAX BUY ERROR: _amount > 0 && _amount <= 20');
        require(_sellTax >= 0 && _sellTax <= 20, 'TAX SELL ERROR: _amount > 0 && _amount <= 20');
        buyTax = _buyTax;
        sellTax = _sellTax;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount)
    internal override {
        if(shouldTakeFee(sender, recipient)) amount = takeFee(sender, amount);
        if(shouldSwapBack()) swapAndLiquify();
        super._transfer(sender, recipient, amount);
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool){
        return !excludedFromFees[sender] 
            && !excludedFromFees[recipient];
    }
    
    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 tax = (sender == _pair) ? buyTax : sellTax;
        uint256 _amountFee = amount.mul(tax).div(PROCENT_DENOMINATOR);
        super._transfer(sender, address(this), _amountFee);
        return amount.sub(_amountFee);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != _pair
            && swapAndLiquifyEnabled
            && !_inSwapAndLiquify
            && balanceOf(address(this)) >= swapThreshold;
    }

    function swapAndLiquify() internal lockTheSwap {
        
        uint256 amount = balanceOf(address(this));
        uint256 marketAmount = amount.mul(marketingProcent).div(PROCENT_DENOMINATOR);
        uint256 liquidityAmount = amount.sub(marketAmount);
        
        uint256 half = liquidityAmount.div(2);
        uint256 otherHalf = liquidityAmount.sub(half);
        uint256 initialBalance = address(this).balance;
        
        // swap tokens for ETH
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        
        swapTokensForEth(marketAmount);
        sendToMarket(address(this).balance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approve(address(this), address(_router), tokenAmount);

        // make the swap
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_router), tokenAmount);

        // add the liquidity
        _router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function sendToMarket(uint256 amount) private returns (bool){
        (bool success, ) = payable(owner()).call{value: amount, gas: 30000}("");
        return success;
    }

    function updateRouter(address _address) external onlyOwner {
        _router = IUniswapV2Router02(_address);
        _pair = IUniswapV2Factory(_router.factory()).createPair(WBNB, address(this));
    }

}