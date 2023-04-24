/**
 *Submitted for verification at BscScan.com on 2023-04-21
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.17;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISwapRouter {
    function factory() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenDistributor {
    constructor () {
        
    }
}

abstract contract BaseToken is IERC20, Ownable {
    uint8 constant private _decimals = 18;  

    uint256 private _totalSupply;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _addPriceTokenAmount;   

    ISwapRouter private _swapRouter;
    address private _releaseAddress;
    address private _issueAddress;
    address private _marketAddress;
    address private _usdtAddress;
    address private _usdtPairAddress;
    TokenDistributor private _tokenDistributor;

    string private _name;
    string private _symbol;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _swapPairMap;
    

    constructor (string memory Name, string memory Symbol, uint256 Supply, address routerAddress, address usdtAddress, address marketAddress, address issueAddress, address releaseAddress){
        _name = Name;
        _symbol = Symbol;
        uint256 total = Supply * 1e18;
        _totalSupply = total;

        
        _marketAddress = marketAddress;
        _releaseAddress = releaseAddress;
        _issueAddress = issueAddress;
        _usdtAddress = usdtAddress;
        _addPriceTokenAmount = 1e14; 

        ISwapRouter swapRouter = ISwapRouter(routerAddress);
        _swapRouter = swapRouter;
        _allowances[address(this)][routerAddress] = MAX;

        IERC20(_usdtAddress).approve(routerAddress, MAX); 

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        _usdtPairAddress = swapFactory.createPair(usdtAddress,address(this));
        _swapPairMap[_usdtPairAddress] = true;


        _balances[address(0x000000000000000000000000000000000000dEaD)] = total/2; 
        emit Transfer(address(0), address(0x000000000000000000000000000000000000dEaD), _balances[address(0x000000000000000000000000000000000000dEaD)]);
        
        _balances[issueAddress] = total/4; 
        emit Transfer(address(0), issueAddress, _balances[issueAddress]);
        
        _balances[releaseAddress] = total/4; 
        emit Transfer(address(0), releaseAddress,  _balances[releaseAddress]);
        
        _tokenDistributor = new TokenDistributor();
    }

    function getParam() external view returns( 
        address releaseAddress,
        address issueAddress,
        address marketAddress,
        address usdtAddress,
        address pairAddress,
        address routerAddress,
        address tokenDistributor,
        uint256 addPriceTokenAmount
        ){
        releaseAddress=_releaseAddress;
        issueAddress=_issueAddress;
        marketAddress=_marketAddress;
        usdtAddress=_usdtAddress;
        pairAddress=_usdtPairAddress;
        routerAddress=address(_swapRouter);
        tokenDistributor=address(_tokenDistributor);
        addPriceTokenAmount=_addPriceTokenAmount;
    }
    
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _isLiquidity(address from,address to) internal view returns(bool isAdd,bool isDel){
        
        (uint r0,uint r1,) = IUniswapV2Pair(_usdtPairAddress).getReserves();
        uint rUsdt = r0;  
        uint bUsdt = IERC20(_usdtAddress).balanceOf(_usdtPairAddress);      
        if(address(this)<_usdtAddress){ 
            rUsdt = r1; 
        }
        if( _swapPairMap[to] ){ 
            if( bUsdt >= rUsdt ){
                isAdd = bUsdt - rUsdt >= _addPriceTokenAmount; 
            }
        }
        if( _swapPairMap[from] ){   
            isDel = bUsdt <= rUsdt;  
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {       
        require(amount > 0, "STF: transfer amount must be >0");
        if(address(_tokenDistributor)==to  || 
            _issueAddress==from || _marketAddress==from || 
            _issueAddress==to   || _marketAddress==to) {
            _tokenTransfer(from, to, amount); 
            return;
        }
        bool isAddLiquidity;
        bool isDelLiquidity;
        ( isAddLiquidity, isDelLiquidity) = _isLiquidity(from,to);
        
        if (isAddLiquidity || isDelLiquidity){            
            _tokenTransfer(from, to, amount);

        }else if(_swapPairMap[from] || _swapPairMap[to]){            
            if (_swapPairMap[to]) { 
                require(amount <= (_balances[from])*999/1000, "STF: sell amount exceeds balance 999%o");
            }else{
                
                require(false, "STF: buy is not allowed");
            }
            _tokenTransfer(from, to, amount*95/100);
            _tokenTransfer(from, _marketAddress, amount/20); 
        }else{
             _tokenTransfer(from, to, amount); 
        }
    }
    
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        _balances[recipient] = _balances[recipient] + tAmount;
        emit Transfer(sender, recipient, tAmount);
    }

    function setAddPriceTokenAmount(uint256 amount) external onlyOwner {
        _addPriceTokenAmount = amount;
    }

    function stfBuyAndBurn(uint256 amount) external returns(uint256) {      
        IERC20 _usdtContract = IERC20(_usdtAddress);
        require(_usdtContract.balanceOf(msg.sender)>=amount,"insufficient balance of USDT");
        address tokenDistributor = address(_tokenDistributor); 
        _usdtContract.transferFrom(msg.sender, address(this), amount);

        address[] memory path = new address[](2);
        path[0] = address(_usdtContract);
        path[1] = address(this);
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            tokenDistributor,
            block.timestamp
        );      
        uint256 burnAmount = _balances[tokenDistributor];
        if(burnAmount>0) _tokenTransfer(tokenDistributor, address(0x000000000000000000000000000000000000dEaD), burnAmount);
        return burnAmount;
    }

    receive() external payable {}
}

contract STF is BaseToken {
    constructor() BaseToken(
        "STF",
        "STF",
        1000000000,
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E), 
        address(0x55d398326f99059fF775485246999027B3197955), 
        address(0x6c93eB19cfa3C0E567d7f972C695A94141feDA72), 
        address(0xcE735455B34a0b9Af6bf16c5b6C267bDBEb44dCE), 
        address(0x018cE57994F6F5fB993D23DCadc6f7a4b7701012) 
    ){

    }
}