// SPDX-License-Identifier: MIT

/*

We save the best wrapped meta coin for last.

Don't miss the moon ride.

Telegram: https://t.me/wbayc
Twitter: https://twitter.com/wbayceth
Website: https://wbayc.com
                               

                                  :+#%%@@@@@@@%#+-          
               .=***=:          :=+*#@@@@@@@@@@@@@@+        
              [email protected]@@#**#@#++*#%@@@@@@#*-=%@@@@@@@@@@@@%-      
             [email protected]@#:*-  .%@@@@+=-  .-#@@%:*@@@@@@@@@@@@@%-    
             #@@.%%    #@@@@@%.     [email protected]@% %@@@@@@@@@@@@@@@+  
             @@:+#     @@[email protected]#        #@@[email protected]@@@@@@@@@@@@@@@- 
            *%:##     [email protected]@.#@         #@@[email protected]@@@@@@@@@@@@@@@: 
           [email protected][email protected]    .%@@ %#        [email protected]@@[email protected]@@@@@@@@@@@@@@#  
          :@@@*===+*%@@@@--#       #@@@@[email protected]@@@@@@@@@@@@@@.  
         [email protected]@@%#%@@@@@@@@@@%+=---=*@@@@@@[email protected]@@@@@@@@@@@@@+   
        *@@%.+-  .-#@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@:   
        *@@=-%      [email protected]@@@@@@@@@@@@@@@@@@@=-=*#@@@@@@@@@=    
         %@.#*      %@@@@@@@@@@@@@@@@@@@%%%@%*===#@@@%:     
        :@[email protected]    :%@@@@@@@@@@@@@@@@@*-=**+=:=*%@= :.       
      :*@@-=#   -#@@@@@@@@@@@@@@@@@@+:@@@@@:*@#-            
    .#@@@@@#++#@@@@@@@@@@@@@@@@@@%=-*@@@@%.#@@+             
   .=*##@@@@@@@@@@@@@@@@@@@@@@@@@ #@@@@@@.%@@%              
  [email protected]+:*.-=:-==%@@@@@@@@@@@@@@@@@@ @@@@@@*[email protected]@@#              
 .:-.#.#@=:%@+..:======+===+:[email protected] %@%#*+:#@@@#              
 :.#.+.-:[email protected]#@@:*@[email protected]#% *--#.==+*#%@@@@@#              
   *[email protected][email protected]@@:[email protected]@:#@* ** -= -+ ** [email protected]@@@@@@@@@@@#              
   [email protected]#:#@@@==+.%## @@.**.--*@@@@@@@@@@@@@:              
   [email protected]@@#-=:+*##-:::@%:.==-**@@@@@@@@@@@@@@@@:               
    :@@@@@@%#**#@@*=+%@@@@@@@@@@@@@@@@@@@@#.                
     .*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-                  
        -+##%@@@@@@@@@@@@@@%*=-:.....                       
                            
*/                                                                 
        
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract WrappedBoredApeYachtClub is ERC20, ERC20Snapshot, Ownable {
    constructor() ERC20("Wrapped Bored Ape Yacht Club", "WBAYC") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}