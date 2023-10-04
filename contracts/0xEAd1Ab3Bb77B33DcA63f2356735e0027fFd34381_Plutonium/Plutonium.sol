/**
 *Submitted for verification at Etherscan.io on 2023-09-24
*/

// SPDX-License-Identifier: MIT
// _______   ________  _______   __        ______  __      __  ________  _______         _______  __      __ 
//|       \ |        \|       \ |  \      /      \|  \    /  \|        \|       \       |       \|  \    /  \
//| $$$$$$$\| $$$$$$$$| $$$$$$$\| $$     |  $$$$$$\\$$\  /  $$| $$$$$$$$| $$$$$$$\      | $$$$$$$\\$$\  /  $$
//| $$  | $$| $$__    | $$__/ $$| $$     | $$  | $$ \$$\/  $$ | $$__    | $$  | $$      | $$__/ $$ \$$\/  $$ 
//| $$  | $$| $$  \   | $$    $$| $$     | $$  | $$  \$$  $$  | $$  \   | $$  | $$      | $$    $$  \$$  $$  
//| $$  | $$| $$$$$   | $$$$$$$ | $$     | $$  | $$   \$$$$   | $$$$$   | $$  | $$      | $$$$$$$\   \$$$$   
//| $$__/ $$| $$_____ | $$      | $$_____| $$__/ $$   | $$    | $$_____ | $$__/ $$      | $$__/ $$   | $$    
//| $$    $$| $$     \| $$      | $$     \\$$    $$   | $$    | $$     \| $$    $$      | $$    $$   | $$    
// \$$$$$$$  \$$$$$$$$ \$$       \$$$$$$$$ \$$$$$$     \$$     \$$$$$$$$ \$$$$$$$        \$$$$$$$     \$$    
//  ______    ______   ________  ________  __       __  ________  __       __  ________                      
// /      \  /      \ |        \|        \|  \     /  \|        \|  \     /  \|        \                     
//|  $$$$$$\|  $$$$$$\| $$$$$$$$| $$$$$$$$| $$\   /  $$| $$$$$$$$| $$\   /  $$| $$$$$$$$                     
//| $$___\$$| $$__| $$| $$__    | $$__    | $$$\ /  $$$| $$__    | $$$\ /  $$$| $$__                         
// \$$    \ | $$    $$| $$  \   | $$  \   | $$$$\  $$$$| $$  \   | $$$$\  $$$$| $$  \                        
// _\$$$$$$\| $$$$$$$$| $$$$$   | $$$$$   | $$\$$ $$ $$| $$$$$   | $$\$$ $$ $$| $$$$$                        
//|  \__| $$| $$  | $$| $$      | $$_____ | $$ \$$$| $$| $$_____ | $$ \$$$| $$| $$_____                      
// \$$    $$| $$  | $$| $$      | $$     \| $$  \$ | $$| $$     \| $$  \$ | $$| $$     \                     
//  \$$$$$$  \$$   \$$ \$$       \$$$$$$$$ \$$      \$$ \$$$$$$$$ \$$      \$$ \$$$$$$$$                     
//         
// https://www.safememe.fun/projects/pu
//
// https://twitter.com/realsafememe
// https://t.me/realsafememe
// https://www.safememe.fun/
//
//Safememe
pragma solidity ^0.8.21; //Safememe

abstract contract Context { //Safememe
    function _msgSender() internal view virtual returns (address) { //Safememe
        return msg.sender; //Safememe
    }//Safememe
} //Safememe

interface IERC20 { //Safememe
    function totalSupply() external view returns (uint256); //Safememe
    function balanceOf(address account) external view returns (uint256); //Safememe
    function transfer(address recipient, uint256 amount) external returns (bool); //Safememe
    function allowance(address owner, address spender) external view returns (uint256); //Safememe
    function approve(address spender, uint256 amount) external returns (bool); //Safememe
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); //Safememe
    event Transfer(address indexed from, address indexed to, uint256 value); //Safememe
    event Approval(address indexed owner, address indexed spender, uint256 value); //Safememe
} //Safememe

library SafeMath { //Safememe
    function add(uint256 a, uint256 b) internal pure returns (uint256) { //Safememe
        uint256 c = a + b; //Safememe
        require(c >= a, "SafeMath: addition overflow"); //Safememe
        return c; //Safememe
    } //Safememe

    function sub(uint256 a, uint256 b) internal pure returns (uint256) { //Safememe
        return sub(a, b, "SafeMath: subtraction overflow"); //Safememe
    } //Safememe

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { //Safememe
        require(b <= a, errorMessage); //Safememe
        uint256 c = a - b; //Safememe
        return c; //Safememe
    } //Safememe

    function mul(uint256 a, uint256 b) internal pure returns (uint256) { //Safememe
        if (a == 0) { //Safememe
            return 0; //Safememe
        } //Safememe
        uint256 c = a * b; //Safememe
        require(c / a == b, "SafeMath: multiplication overflow"); //Safememe
        return c; //Safememe
    } //Safememe

    function div(uint256 a, uint256 b) internal pure returns (uint256) { //Safememe
        return div(a, b, "SafeMath: division by zero"); //Safememe
    } //Safememe

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { //Safememe
        require(b > 0, errorMessage); //Safememe
        uint256 c = a / b; //Safememe
        return c; //Safememe
    } //Safememe
} //Safememe

contract Ownable is Context { //Safememe
    address private _owner; //Safememe
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); //Safememe

    constructor () { //Safememe
        address msgSender = _msgSender(); //Safememe
        _owner = msgSender; //Safememe
        emit OwnershipTransferred(address(0), msgSender); //Safememe
    } //Safememe

    function owner() public view returns (address) { //Safememe
        return _owner; //Safememe
    } //Safememe

    modifier onlyOwner() { //Safememe
        require(_owner == _msgSender(), "Ownable: caller is not the owner"); //Safememe
        _; //Safememe
    } //Safememe

    function renounceOwnership() public virtual onlyOwner { //Safememe
        emit OwnershipTransferred(_owner, address(0)); //Safememe
        _owner = address(0); //Safememe
    } //Safememe
} //Safememe

interface IUniswapV2Factory { //Safememe
    function createPair(address tokenA, address tokenB) external returns (address pair); //Safememe
} //Safememe

interface IUniswapV2Router02 { //Safememe
    function swapExactTokensForETHSupportingFeeOnTransferTokens(//Safememe
        uint amountIn,//Safememe
        uint amountOutMin,//Safememe
        address[] calldata path,//Safememe
        address to,//Safememe
        uint deadline//Safememe
    ) external; //Safememe
    function factory() external pure returns (address); //Safememe
    function WETH() external pure returns (address); //Safememe
    function addLiquidityETH(//Safememe
        address token,//Safememe
        uint amountTokenDesired,//Safememe
        uint amountTokenMin,//Safememe
        uint amountETHMin,//Safememe
        address to,//Safememe
        uint deadline//Safememe
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity); //Safememe
} //Safememe

contract Plutonium is Context, IERC20, Ownable { //Safememe
    using SafeMath for uint256; //Safememe
    mapping (address => uint256) private _balances; //Safememe
    mapping (address => mapping (address => uint256)) private _allowances; //Safememe
    mapping (address => bool) private _isExcludedFromFee; //Safememe
    mapping (address => bool) private _buyerMap; //Safememe
    mapping (address => bool) private bots; //Safememe
    mapping(address => uint256) private _holderLastTransferTimestamp; //Safememe
    bool public transferDelayEnabled = false; //Safememe
    address payable private _taxWallet; //Safememe

    uint256 private _initialBuyTax=10; //Safememe
    uint256 private _initialSellTax=30; //Safememe
    uint256 private _finalBuyTax=0; //Safememe
    uint256 private _finalSellTax=3; //Safememe
    uint256 private _reduceBuyTaxAt=50; //Safememe
    uint256 private _reduceSellTaxAt=200; //Safememe
    uint256 private _preventSwapBefore=30; //Safememe
    uint256 private _buyCount=0; //Safememe

    uint8 private constant _decimals = 8; //Safememe
    uint256 private constant _tTotal = 1000000 * 10**uint256(_decimals); //Safememe
    string private constant _name = unicode"Plutonium"; //Safememe
    string private constant _symbol = unicode"PU"; //Safememe
    uint256 public _maxTxAmount = 9999 * 10**uint256(_decimals); //Safememe
    uint256 public _maxWalletSize = 9999 * 10**uint256(_decimals); //Safememe
    uint256 public _taxSwapThreshold = 1000 * 10**uint256(_decimals); //Safememe
    uint256 public _maxTaxSwap = 5000 * 10**uint256(_decimals); //Safememe

    IUniswapV2Router02 private uniswapV2Router; //Safememe
    address private uniswapV2Pair; //Safememe
    bool private tradingOpen; //Safememe
    bool private inSwap = false; //Safememe
    bool private swapEnabled = false; //Safememe
    bool private limitsRemoved = false; //Safememe

    event MaxTxAmountUpdated(uint _maxTxAmount); //Safememe

    modifier lockTheSwap { //Safememe
        inSwap = true; //Safememe
        _; //Safememe
        inSwap = false; //Safememe
    } //Safememe

    constructor () { //Safememe
        _taxWallet = payable(_msgSender()); //Safememe
        _balances[_msgSender()] = _tTotal; //Safememe
        _isExcludedFromFee[owner()] = true; //Safememe
        _isExcludedFromFee[address(this)] = true; //Safememe
        _isExcludedFromFee[_taxWallet] = true; //Safememe

        emit Transfer(address(0), _msgSender(), _tTotal); //Safememe
    } //Safememe

    function name() public pure returns (string memory) { //Safememe
        return _name; //Safememe
    } //Safememe

    function symbol() public pure returns (string memory) { //Safememe
        return _symbol; //Safememe
    } //Safememe

    function decimals() public pure returns (uint8) { //Safememe
        return _decimals; //Safememe
    } //Safememe

    function totalSupply() public pure override returns (uint256) { //Safememe
        return _tTotal; //Safememe
    } //Safememe

    function balanceOf(address account) public view override returns (uint256) { //Safememe
        return _balances[account]; //Safememe
    } //Safememe

    function transfer(address recipient, uint256 amount) public override returns (bool) { //Safememe
        _transfer(_msgSender(), recipient, amount); //Safememe
        return true; //Safememe
    } //Safememe

    function allowance(address owner, address spender) public view override returns (uint256) { //Safememe
        return _allowances[owner][spender]; //Safememe
    } //Safememe

    function approve(address spender, uint256 amount) public override returns (bool) { //Safememe
        _approve(_msgSender(), spender, amount); //Safememe
        return true; //Safememe
    } //Safememe

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) { //Safememe
        _transfer(sender, recipient, amount); //Safememe
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")); //Safememe
        return true; //Safememe
    } //Safememe

    function _approve(address owner, address spender, uint256 amount) private { //Safememe
        require(owner != address(0), "ERC20: approve from the zero address"); //Safememe
        require(spender != address(0), "ERC20: approve to the zero address"); //Safememe
        _allowances[owner][spender] = amount; //Safememe
        emit Approval(owner, spender, amount); //Safememe
    } //Safememe

    function _transfer(address from, address to, uint256 amount) private { //Safememe
        require(from != address(0), "ERC20: transfer from the zero address"); //Safememe
        require(to != address(0), "ERC20: transfer to the zero address"); //Safememe
        require(amount > 0, "Transfer amount must be greater than zero"); //Safememe
        uint256 taxAmount=0; //Safememe
        if (from != owner() && to != owner()) { //Safememe
            require(!bots[from] && !bots[to]); //Safememe

            if (transferDelayEnabled) { //Safememe
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) { //Safememe
                  require(_holderLastTransferTimestamp[tx.origin] < block.number,"Only one transfer per block allowed."); //Safememe
                  _holderLastTransferTimestamp[tx.origin] = block.number; //Safememe
                } //Safememe
            } //Safememe

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) { //Safememe
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount."); //Safememe
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize."); //Safememe
                if(_buyCount<_preventSwapBefore){ //Safememe
                    require(!isContract(to)); //Safememe
                } //Safememe
                _buyCount++; //Safememe
                _buyerMap[to]=true; //Safememe
            } //Safememe

            taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100); //Safememe
            if(to == uniswapV2Pair && from!= address(this)){ //Safememe
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount."); //Safememe
                taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100); //Safememe
                require(_buyCount>_preventSwapBefore || _buyerMap[from], "Seller is not buyer"); //Safememe
            } //Safememe

            uint256 contractTokenBalance = balanceOf(address(this)); //Safememe
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore) { //Safememe
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap))); //Safememe
                uint256 contractETHBalance = address(this).balance; //Safememe
                if(contractETHBalance > 0) { //Safememe
                    sendETHToFee(address(this).balance); //Safememe
                } //Safememe
            } //Safememe
        } //Safememe

        if(taxAmount>0){ //Safememe
            _balances[address(this)]=_balances[address(this)].add(taxAmount); //Safememe
            emit Transfer(from, address(this),taxAmount); //Safememe
        } //Safememe
        _balances[from]=_balances[from].sub(amount); //Safememe
        _balances[to]=_balances[to].add(amount.sub(taxAmount)); //Safememe
        emit Transfer(from, to, amount.sub(taxAmount)); //Safememe
    
        _removeLimits(); //Safememe
    } //Safememe

    function min(uint256 a, uint256 b) private pure returns (uint256){ //Safememe
        return (a>b)?b:a; //Safememe
    } //Safememe

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap { //Safememe
        if(tokenAmount==0){return;} //Safememe
        if(!tradingOpen){return;} //Safememe
        address[] memory path = new address[](2); //Safememe
        path[0] = address(this); //Safememe
        path[1] = uniswapV2Router.WETH(); //Safememe
        _approve(address(this), address(uniswapV2Router), tokenAmount); //Safememe
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(//Safememe
            tokenAmount,//Safememe
            0,//Safememe
            path,//Safememe
            address(this),//Safememe
            block.timestamp//Safememe
        ); //Safememe
    } //Safememe

    function _removeLimits() internal { //Safememe
        if (_buyCount > 2500 && !limitsRemoved) { //Safememe
            _maxTxAmount = _tTotal; //Safememe
            _maxWalletSize = _tTotal; //Safememe
             transferDelayEnabled=false; //Safememe
            emit MaxTxAmountUpdated(_tTotal); //Safememe
            limitsRemoved = true; //Safememe
        } //Safememe
    } //Safememe

    function removeLimits() external onlyOwner{ //Safememe
        _maxTxAmount = _tTotal; //Safememe
        _maxWalletSize=_tTotal; //Safememe
         transferDelayEnabled=false; //Safememe
        emit MaxTxAmountUpdated(_tTotal); //Safememe
    } //Safememe

    function sendETHToFee(uint256 amount) private { //Safememe
        _taxWallet.transfer(amount); //Safememe
    } //Safememe
   
    function isBot(address a) public view returns (bool){ //Safememe
      return bots[a]; //Safememe
    } //Safememe
    
    function safeLaunch() external onlyOwner() { //Safememe
        require(!tradingOpen,"trading is already open"); //Safememe
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Safememe
        _approve(address(this), address(uniswapV2Router), _tTotal); //Safememe
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH()); //Safememe
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp); //Safememe
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max); //Safememe
        swapEnabled = true; //Safememe
        tradingOpen = true; //Safememe
    } //Safememe
    
    receive() external payable {} //Safememe

    function isContract(address account) private view returns (bool) { //Safememe
        uint256 size; //Safememe
        assembly { //Safememe
            size := extcodesize(account) //Safememe
        } //Safememe
        return size > 0; //Safememe
    } //Safememe
} //Safememe