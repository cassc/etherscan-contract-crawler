/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

/*

Telegram : https://t.me/GOGOERCPORTAL
Twitter : https://twitter.com/GOGOERCTOKEN

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    address private _prvsOwner;
    event OwnershipTransferred(address indexed prvsOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}  

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract GoGoGoGoToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    
    uint256 public _sellMrktngFee = 5;
    uint256 private _prvsSellMrktngFee = _sellMrktngFee;
    uint256 public _sellLiquidityFee = 5;
    uint256 private _prvsSellLiquidityFee = _sellLiquidityFee;

    uint256 public _buyMrktngFee = 5;
    uint256 private _prvsBuyMrktngFee = _buyMrktngFee;
    uint256 public _buyLiquidityFee = 5;
    uint256 private _prvsBuyLiquidityFee = _buyLiquidityFee;

    uint256 private tokensForMrktng;
    uint256 private tokensForLiquidity;

    address payable public _MrktngWallet;
    address payable public _liquidityWallet;
    
    string public constant name = "GOGO";
    string public constant symbol = "GoGo";
    uint8 public constant decimals = 12;
    uint256 public constant totalSupply = 200_000_000_000 * 10**decimals;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool public tradingEnabled;
    bool private swapping;
    bool private inSwap = false;
    bool public swaptokenEnabled = false;
    
    uint256 private _maxBuyAmount = totalSupply;
    uint256 private _maxSellAmount = totalSupply;
    uint256 private _maxWalletAmount = totalSupply;
    uint256 private swapTokensAtAmount = 0;
    
    event MaxBuyAmountUpdated(uint _maxBuyAmount);
    event MaxSellAmountUpdated(uint _maxSellAmount);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () {
        _MrktngWallet = payable(0x838a6513C5ed676C8f8ebE6f41da32353CA232d8);
        _liquidityWallet = payable(msg.sender);
        _rOwned[_msgSender()] = totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_MrktngWallet] = true;
        _isExcludedFromFee[_liquidityWallet] = true;
        emit Transfer(address(0xe5EabE8582847909F9421cC50C94bBfc765C36B6), _msgSender(), totalSupply);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approval(address(this), address(uniswapV2Router), totalSupply);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approval(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setSwapbackEnabled(bool onoff) external onlyOwner(){
        require(onoff || !onoff,"Swap enabled");
        swaptokenEnabled = onoff;
    }

    function _approval(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero adrss");
        require(spender != address(0), "ERC20: approve to the zero adrss");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero adrss");
        bool takeFeeFlag = false;
        bool shouldSwap = false;
        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
            
            require(tradingEnabled,"Trading not open yet");

            takeFeeFlag = true;
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(amount <= _maxBuyAmount, "Transfer amount exceeds the maxBuyAmount.");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Exceeds maximum wallet token amount.");
            }
            
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && !_isExcludedFromFee[from]) {
                require(amount <= _maxSellAmount, "Transfer amount exceeds the maxSellAmount.");
                shouldSwap = true;
            }
        }

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFeeFlag = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = (contractTokenBalance > swapTokensAtAmount) && shouldSwap;

        if (canSwap && swaptokenEnabled && !swapping && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            swapping = true;
            swapTokens();
            swapping = false;
        }

        _tokenTransfer(from,to,amount,takeFeeFlag, shouldSwap);
    }

    function swapTokens() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMrktng;
        bool success;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
        }
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        uint256 initialETHBalance = address(this).balance;

        sellTokensForEth(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        
        uint256 ethForMrktng = ethBalance.mul(tokensForMrktng).div(totalTokensToSwap);
        
        
        uint256 ethForLiquidity = ethBalance - ethForMrktng;
        
        
        tokensForLiquidity = 0;
        tokensForMrktng = 0;
        
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
        
        
        (success,) = address(_MrktngWallet).call{value: address(this).balance}("");
    }

    function sellTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approval(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approval(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _liquidityWallet,
            block.timestamp
        );
    }
        
    function sendETHToFee(uint256 amount) private {
        _MrktngWallet.transfer(amount);
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingEnabled,"trading is already open");
        swaptokenEnabled = true;
        _maxWalletAmount = totalSupply / 50;
        swapTokensAtAmount = totalSupply / 100;
        _maxBuyAmount = totalSupply / 100;
        _maxSellAmount = totalSupply / 100;
        tradingEnabled = true;
    }

    function manual_swap() public onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        sellTokensForEth(contractBalance);
    }
    
    function manual_send() public onlyOwner() {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function removeLimits() external onlyOwner {
        _maxWalletAmount = totalSupply / 25;
        swapTokensAtAmount = totalSupply / 1000;
        _buyMrktngFee = 4;
        _buyLiquidityFee = 1;
        _maxBuyAmount = totalSupply / 25;
        _maxSellAmount = totalSupply / 25;
        _sellMrktngFee = 4;
        _sellLiquidityFee = 1;
    }

    function finalTax() external onlyOwner {
        _maxWalletAmount = totalSupply;
        _maxBuyAmount = totalSupply / 10;
        _maxSellAmount = totalSupply / 10;
        _buyMrktngFee = 1;
        _buyLiquidityFee = 1;
        _sellMrktngFee = 1;
        _sellLiquidityFee = 1;
    }
    
    function removeAllFee() private {
        if(_buyMrktngFee == 0 && _buyLiquidityFee == 0 && _sellMrktngFee == 0 && _sellLiquidityFee == 0) return;
        
        _prvsBuyMrktngFee = _buyMrktngFee;
        _prvsBuyLiquidityFee = _buyLiquidityFee;
        _prvsSellMrktngFee = _sellMrktngFee;
        _prvsSellLiquidityFee = _sellLiquidityFee;
        
        _buyMrktngFee = 0;
        _buyLiquidityFee = 0;
        _sellMrktngFee = 0;
        _sellLiquidityFee = 0;
    }
    
    function restoreAllFee() private {
        _buyMrktngFee = _prvsBuyMrktngFee;
        _buyLiquidityFee = _prvsBuyLiquidityFee;
        _sellMrktngFee = _prvsSellMrktngFee;
        _sellLiquidityFee = _prvsSellLiquidityFee;
    }

        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFeeFlag, bool isSell) private {
        if(!takeFeeFlag) {
            removeAllFee();
        } else {
            amount = _takeFeeFlags(sender, amount, isSell);
        }

        _transferStandard(sender, recipient, amount);
        
        if(!takeFeeFlag) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _takeFeeFlags(address sender, uint256 amount, bool isSell) private returns (uint256) {
        uint256 _totalFees;
        uint256 mrktFee;
        uint256 liqFee;
        
        _totalFees = _calculateFees(isSell);
        if (isSell) {
            mrktFee = _sellMrktngFee;
            liqFee = _sellLiquidityFee;
        } else {
            mrktFee = _buyMrktngFee;
            liqFee = _buyLiquidityFee;
        }

        uint256 fees = amount.mul(_totalFees).div(100);
        tokensForMrktng += fees * mrktFee / _totalFees;
        tokensForLiquidity += fees * liqFee / _totalFees;
            
        if(fees > 0) {
            _transferStandard(sender, address(this), fees);
        }
            
        return amount -= fees;
    }

    receive() external payable {}

    function _calculateFees(bool isSell) private view returns(uint256) {
        if (isSell) {
            return _sellMrktngFee + _sellLiquidityFee;
        }
        return _buyMrktngFee + _buyLiquidityFee;
    }
}