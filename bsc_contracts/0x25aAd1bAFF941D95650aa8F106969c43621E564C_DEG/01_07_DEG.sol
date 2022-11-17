// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Operator is Context {
    address private _operator;
    constructor() {
        _transferOperator(_msgSender());
    }

    modifier onlyOperator() {
        require(_operator == _msgSender(), "Operator: caller is not the operator");
        _;
    }
    function renounceOperator() public virtual onlyOperator {
        _transferOperator(address(0));
    }
    function transferOperator(address newOperator) public virtual onlyOperator {
        require(newOperator != address(0), "Operator: new operator is the zero address");
        _transferOperator(newOperator);
    }
    function _transferOperator(address newOperator) internal virtual {
        // address oldOperator = _operator;
        _operator = newOperator;
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

contract DEG is IERC20Metadata, Ownable, Operator {
    using SafeMath for uint256;
    using Address for address;
 
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _antiRobot;

    uint8 private _decimals = 18;
    uint256 private _totalSupply = 100000000 * 10**18;
    uint256 private _stopBurn = 20000000 * 10**18;
 
    string private _name = "Defi Guru"; // Defi guru
    string private _symbol = "DEG"; // DEG
    
    uint256 private _commonDiv = 100;
    uint256 public _burnFee = 1; // 1%
    uint256 public _buildFee = 2; //2%
    uint256 public _guruFee = 3; //3%
    uint256 public totalFee = 6; //6%

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    address private uniswapV2Pair_BNB;
 
    mapping(address => bool) public ammPairs;
    
    uint256 private constant MAX = type(uint256).max;
    address private _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //prod
    address public usdtAddress = 0x55d398326f99059fF775485246999027B3197955; // prod
    
    address private buildFeeAddress;
    address private defiGuruAddress;

    uint256 public startTime;

    constructor (){
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Router = _uniswapV2Router;
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), usdtAddress);
        uniswapV2Pair = _uniswapV2Pair;
        address _uniswapV2Pair_bnb = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Pair_BNB = _uniswapV2Pair_bnb;
        ammPairs[uniswapV2Pair] = true;
        ammPairs[uniswapV2Pair_BNB] = true;

        _isExcludedFromFee[address(this)] = true;
        startTime = block.timestamp;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
        
    receive() external payable {}

    function excludeFromFees(address[] memory accounts) public onlyOwner{
        uint len = accounts.length;
        for( uint i = 0; i < len; i++ ){
            _isExcludedFromFee[accounts[i]] = true;
        }
    }

    function setStartTime(uint _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function getTheDay() public view returns (uint) {
        return (block.timestamp - startTime)/1 days;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setAmmPair(address pair,bool hasPair) external onlyOwner{
        require(pair != address(0), "Amm pair must be a address");
        ammPairs[pair] = hasPair;
    }

    function setRobotAddress(address _addr, bool _flag) external onlyOwner{
        _antiRobot[_addr] = _flag;
    }
    
    function setDefiGuruAddress(address account) external onlyOwner{
        require(account != defiGuruAddress, "Guru address must be a new address");
        _isExcludedFromFee[account] = true;
        defiGuruAddress = account;
    }

    function setBuildAddress(address account) external onlyOwner{
        require(account != buildFeeAddress, "Build fee address must be a new address");
        _isExcludedFromFee[account] = true;
        buildFeeAddress = account;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        require(_isExcludedFromFee[msg.sender], "Not allowed");
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
 
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
 
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    struct Param{
        bool takeFee;
        uint256 tTransferAmount;
        uint256 tBurnFee;
        uint256 tBuildFee;
        uint256 tGuruFee;
    }

    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_antiRobot[from], "Robot address can't exchange");

        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || from ==  address(uniswapV2Router)){
            takeFee = false;
        } 

        Param memory param;
        if( takeFee ){
            param.takeFee = true;
            if(ammPairs[from]){
                _getParam(amount, param);   // buy or removeLiquidity
            } 
            if(ammPairs[to]){
                _getParam(amount, param);   //sell or addLiquidity
            } 
            if(!ammPairs[from] && !ammPairs[to]){
                param.takeFee = false;
                param.tTransferAmount = amount; //no fee
            }
        } else {
            param.takeFee = false;
            param.tTransferAmount = amount; //no fee
        }
        _tokenTransfer(from, to, amount, param);
    }

    function _getParam(uint256 tAmount,Param memory param) private view  {
        uint256 _totalFee = _buildFee.add(_guruFee);
        if(_totalSupply > _stopBurn){
            param.tBurnFee = tAmount.mul(_burnFee).div(_commonDiv);
            _totalFee = _totalFee.add(_burnFee);
        }
        param.tBuildFee = tAmount.mul(_buildFee).div(_commonDiv);
        param.tGuruFee = tAmount.mul(_guruFee).div(_commonDiv);
        uint256 tFee = tAmount.mul(_totalFee).div(_commonDiv);
        param.tTransferAmount = tAmount.sub(tFee);
    }

    function _take(uint256 tValue,address from,address to) private {
        _balances[to] = _balances[to].add(tValue);
        emit Transfer(from, to, tValue);
    }

    function _burn(address _from, uint256 _amount) private{
        _totalSupply = _totalSupply.sub(_amount);
        emit Transfer(_from, address(0), _amount);
    }

    function _takeFee(Param memory param, address from) private {
        if( param.tBurnFee > 0 ){
            _burn(from, param.tBurnFee);
        }
        if( param.tBuildFee > 0 ){
            _take(param.tBuildFee, from, buildFeeAddress);
        }        
        if( param.tGuruFee > 0 ){
            _take(param.tGuruFee, from, defiGuruAddress);
        }
    }

    event ParamEvent(
        address indexed sender, 
        address indexed to, 
        uint256 tBuildFee, 
        uint256 tGuruFee, 
        uint256 tBurnFee,
        uint256 tTransferAmount,
        string a);

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, Param memory param) private {
        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(param.tTransferAmount);
         emit Transfer(sender, recipient, param.tTransferAmount);

        if( param.takeFee ){
            emit ParamEvent(sender, recipient, param.tBuildFee, 
            param.tGuruFee, 
            param.tBurnFee,
            param.tTransferAmount,"Take fee true");
            _takeFee(param,sender);
        }
    }

    function clearStuckBalance(address _receiver) external onlyOperator {
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);
    }

    function rescueToken(address _token, uint256 _value) external onlyOperator{
        IERC20(_token).transfer(msg.sender, _value);
    }
}