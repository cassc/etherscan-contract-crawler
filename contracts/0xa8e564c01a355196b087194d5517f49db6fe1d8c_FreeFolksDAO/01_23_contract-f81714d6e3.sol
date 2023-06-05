// SPDX-License-Identifier: MIT

/*

     ##### ##                                     ##### ##        ###       /                            ##### ##         ##          # ###    
  ######  /### /                               ######  /### /      ###    #/                          /#####  /##      /####        /  /###    
 /#   /  /  ##/                               /#   /  /  ##/        ##    ##                        //    /  / ###    /  ###       /  /  ###   
/    /  /    #                               /    /  /    #         ##    ##                       /     /  /   ###      /##      /  ##   ###  
    /  /                                         /  /               ##    ##                            /  /     ###    /  ##    /  ###    ### 
   ## ##   ###  /###     /##       /##          ## ##       /###    ##    ##  /##       /###           ## ##      ##    /  ##   ##   ##     ## 
   ## ##    ###/ #### / / ###     / ###         ## ##      / ###  / ##    ## / ###     / #### /        ## ##      ##   /    ##  ##   ##     ## 
   ## ###### ##   ###/ /   ###   /   ###        ## ###### /   ###/  ##    ##/   /     ##  ###/         ## ##      ##   /    ##  ##   ##     ## 
   ## #####  ##       ##    ### ##    ###       ## ##### ##    ##   ##    ##   /     ####              ## ##      ##  /      ## ##   ##     ## 
   ## ##     ##       ########  ########        ## ##    ##    ##   ##    ##  /        ###             ## ##      ##  /######## ##   ##     ## 
   #  ##     ##       #######   #######         #  ##    ##    ##   ##    ## ##          ###           #  ##      ## /        ## ##  ##     ## 
      #      ##       ##        ##                 #     ##    ##   ##    ######           ###            /       /  #        ##  ## #      /  
  /####      ##       ####    / ####    /      /####     ##    ##   ##    ##  ###     /###  ##       /###/       /  /####      ##  ###     /   
 /  #####    ###       ######/   ######/      /  #####    ######    ### / ##   ### / / #### /       /   ########/  /   ####    ## / ######/    
/    ###      ###       #####     #####      /    ###      ####      ##/   ##   ##/     ###/       /       ####   /     ##      #/    ###      
#                                            #                                                     #              #                            
 ##                                           ##                                                    ##             ##                          

*/

pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract FreeFolksDAO is ERC20, ERC20Permit, ERC20Votes, Ownable {
    constructor() ERC20("FreeFolksDAO", "FOLKS") ERC20Permit("FreeFolksDAO") {
        _mint(msg.sender, 1787091700000 * 10 ** decimals());
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}