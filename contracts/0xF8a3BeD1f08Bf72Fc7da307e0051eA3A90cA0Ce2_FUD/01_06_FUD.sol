// SPDX-License-Identifier: MIT

/*                                            
FFFFFFFFFFFFFFFFFFFFFFUUUUUUUU     UUUUUUUUDDDDDDDDDDDDD        
F::::::::::::::::::::FU::::::U     U::::::UD::::::::::::DDD     
F::::::::::::::::::::FU::::::U     U::::::UD:::::::::::::::DD   
FF::::::FFFFFFFFF::::FUU:::::U     U:::::UUDDD:::::DDDDD:::::D  
  F:::::F       FFFFFF U:::::U     U:::::U   D:::::D    D:::::D 
  F:::::F              U:::::D     D:::::U   D:::::D     D:::::D
  F::::::FFFFFFFFFF    U:::::D     D:::::U   D:::::D     D:::::D
  F:::::::::::::::F    U:::::D     D:::::U   D:::::D     D:::::D
  F:::::::::::::::F    U:::::D     D:::::U   D:::::D     D:::::D
  F::::::FFFFFFFFFF    U:::::D     D:::::U   D:::::D     D:::::D
  F:::::F              U:::::D     D:::::U   D:::::D     D:::::D
  F:::::F              U::::::U   U::::::U   D:::::D    D:::::D 
FF:::::::FF            U:::::::UUU:::::::U DDD:::::DDDDD:::::D  
F::::::::FF             UU:::::::::::::UU  D:::::::::::::::DD   
F::::::::FF               UU:::::::::UU    D::::::::::::DDD     
FFFFFFFFFFF                 UUUUUUUUU      DDDDDDDDDDDDD        
                                                                
                                                                
 “Stay away from it. It’s a mirage, basically. In terms of cryptocurrencies, generally, I can say almost with certainty that they will come to a bad ending.” – Warren Buffett, legendary investor                                                           
                                                                

LISTEN TO WALLET BUFFER
HE SAID ITS A MIRAGE, ITS NOT REAL
CRYPTO IS COMING TO A BAD ENDING

DO NOT BUY THIS.
YOU WILL LOSE MONEY
STAY AWAY

THIS WILL ULTIMATELY GO TO 0, UNLESS YOU WANT TO BAG HOLD $FUD 

THERE IS NO UTILITY IN THIS, ABSOLUTELY NO FUCKING REASON TO BUY IT
DO NOT TURN OFF YOUR BRAIN & APE IN
DO NOT BE EXIT LIQUIDITY


Official Twitter: https://twitter.com/fudcoin420
Telegram: https://t.me/fudcoin420                       
Website:  TBA



*/
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract FUD is ERC20, Ownable {
    constructor() ERC20("Stay Away, its FUD", "FUD") {
        _mint(msg.sender, 420000000000000000000000000);
    }

}