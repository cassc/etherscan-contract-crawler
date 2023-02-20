/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


interface IUniswapV2Pair {
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function mint(address to) external returns (uint liquidity);
}


interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}


interface IWETH9 {
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}


contract Rome is IERC20, Context {

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private _swapRouterAddress;
    address private _wethAddress;
    address public swapPairAddress;

    bool private immutable _isRomeToken0;
    bool liquidityAdded;
    uint8 private constant _decimals = 18;

    uint256 private _totalSupply = 1000000*10**_decimals; //1 Million
    
    address private constant _vanityAddress = 0x0000000000000000000000000000000000000001;
    string private constant _name = "Rome";
    string private constant _symbol = "Rome";   
    uint256 private _maxWallet = 20000*10**_decimals; //2%, 20,000.
    uint256 private _reflectedSupply = ~uint256(0);
    uint256 private _swapPairReflected;
    IUniswapV2Pair private _swapPair;
    IUniswapRouter private _swapRouter;
    IWETH9 private _weth;
    uint256 private _lastBuyBlock;
    uint256 private _status = 1;
   
    constructor (address swapRouterAddress) payable {  
        _swapRouter = IUniswapRouter(swapRouterAddress);
        _swapRouterAddress = swapRouterAddress;
        _wethAddress = _swapRouter.WETH();
        _weth = IWETH9(_wethAddress);
        _weth.deposit{value: msg.value}();
        swapPairAddress = IUniswapFactory(_swapRouter.factory()).createPair(address(this), _wethAddress);
        _swapPair = IUniswapV2Pair(swapPairAddress);
        _isRomeToken0 = address(this) < _wethAddress ? true : false;
        _balances[address(this)] = _reflectedSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }
    
    receive() external payable {
        buyBackAndReflect();
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

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return account == swapPairAddress ? _balances[account] : _reflectionToActual(_balances[account]);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]-amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function addLiquidity() public {
        require(!liquidityAdded, "Liquidity can only be added once");
        _weth.transfer(swapPairAddress, _weth.balanceOf(address(this)));
        uint256 rate = _getRate();
        _transferTokens(address(this), swapPairAddress, balanceOf(address(this))-1);
        _swapPair.mint(address(this));
        _swapPairReflected = balanceOf(swapPairAddress)*rate;
        _transferTokens(address(this), address(0x0), 1);
        liquidityAdded = true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
       
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0) && to != address(0), "ERC20: transfer to/from the zero address");        
        address _swapPairAddress = swapPairAddress; 
        uint256 toAmount = amount;
        if (
            (from == _swapPairAddress && to != address(this) && to != _vanityAddress) || 
            (to == _swapPairAddress && from != address(this) && from != _vanityAddress)
        )
            toAmount = _tax(from, amount);
        _transferTokens(from, to, toAmount);
    }

    function _transferTokens(address from, address to, uint256 amount) private {
        uint256 toAmount = _actualToReflection(amount);
        uint256 fromAmount = toAmount;
        address _swapPairAddress = swapPairAddress;
        uint256 currentRate = _getRate();
        if (from == _swapPairAddress){
            _swapPairReflected -= fromAmount;
            fromAmount = amount;
            if (to != _swapPairAddress)
                _lastBuyBlock = block.number;
        }
        if (to == _swapPairAddress){
            _swapPairReflected += toAmount;
            toAmount = amount;
        } else {
            require((_balances[to] + toAmount)/currentRate <= _maxWallet || to == _vanityAddress, "Max wallet exceeded");
        }
        require(_balances[from] >= fromAmount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = _balances[from] - fromAmount;
        }
        _balances[to] += toAmount;

        emit Transfer(from, to, amount);
    }

    function _tax(address from, uint256 amount) private returns (uint256 transferToAmount) {
        uint256 addToLiquiduityAmount;
        if (_balances[swapPairAddress] < (_totalSupply*20)/100)
            addToLiquiduityAmount += (amount*5)/100;
        
        if (_weth.balanceOf(swapPairAddress) < 100 ether)
            addToLiquiduityAmount += (amount*5)/100;
        
        if (addToLiquiduityAmount != 0)
            _transferTokens(from, swapPairAddress, addToLiquiduityAmount);
        
        return amount - addToLiquiduityAmount;
    }

    function buyBackAndReflect() public payable {
        require(msg.value != 0, "Message value must be more than 0");
        require(block.number - _lastBuyBlock >= 2, "Not enough time since last buy");
        require(_status != 2);
        _status = 2;
        _weth.deposit{value: msg.value}();
        (uint reserve0, uint reserve1,) = _swapPair.getReserves();
        (uint tokenReserve, uint wethReserve) = _isRomeToken0 ? (reserve0, reserve1) : (reserve1, reserve0);
        uint amountInWithFee = msg.value*997;
        uint amountOut = (amountInWithFee*tokenReserve)/((wethReserve*1000)+amountInWithFee);
        (uint amount0Out, uint amount1Out) = _isRomeToken0 ? (amountOut, uint(0)) : (uint(0), amountOut);
        _weth.transfer(swapPairAddress, msg.value);
        uint balanceBefore = balanceOf(_vanityAddress);
        _swapPair.swap(amount0Out,amount1Out,_vanityAddress,new bytes(0));
        uint reflectAmount = balanceOf(_vanityAddress) - balanceBefore;
        _balances[_vanityAddress] -= _actualToReflection(reflectAmount);
        emit Transfer(_vanityAddress, address(this), reflectAmount);
        _reflect(reflectAmount);
        _status = 1;
    }

    function _reflect(uint256 amount) private {
        _reflectedSupply -= _actualToReflection(amount);
    }

    function _reflectionToActual(uint256 reflectionAmount) private view returns(uint256) {
        uint256 currentRate =  _getRate();
        return reflectionAmount/currentRate;
    }

    function _actualToReflection(uint256 actualAmount) private view returns(uint256) {
        uint256 currentRate = _getRate();
        return actualAmount*currentRate;
    }

    function _getRate() private view returns(uint256) {
        return (_reflectedSupply-_swapPairReflected)/(_totalSupply-_balances[swapPairAddress]);
    }

}