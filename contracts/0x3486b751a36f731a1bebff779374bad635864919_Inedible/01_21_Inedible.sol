// SPDX-License-Identifier: MIT License
pragma solidity 0.8.18;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**

                                  .:^~!7??JYYY55555555YYYJJ?7!~^:.                                  
                             :^!7?JY5555555555555555555555555555YJJ7!^:                             
                        .:~7JY5555555555555555555555555555555555555555YJ7~:.                        
                     .~7J555555555555555555555YYYYYYYY555555555555555555555J7~.                     
                  .~?Y55555555555555YJJ7!!~^::::....::::^~!!7JJY55555555555555Y?~.                  
                ^7Y555555555555YJ7~^..                        ..^~7JY555555555555Y7^                
             .~J55555555555Y?!^.                                    .^!?Y55555555555J~.             
           .!Y5555555555Y7~.                                            .!Y55555555555Y!.           
          ~J555555555Y?~.                                              :!Y55555555555555J~          
        :?555555555Y7:                                               :7Y555555555555555555?:        
       !Y55555555Y!.                                               :7Y555555555Y!!Y55555555Y!       
     .?5555555557:                                               ^?5555555555J~.  :7555555555?.     
    :J55555555Y^                                               ^?5555555555J~.      ^J55555555J:    
   :J55555555?.  .:.............................. ........  .~J5555555555J~.   .     ^J55555555J:   
  .J555555557.   ^7!~^^:::::::::::::::::::::::::::::::::::^!J5555555555J~:::::::::^~~!~755555555J.  
  ?555555557     ~777!!~^^::::::::::::::::::::::::::::::^!Y5555555555?~:::::::^^^~!!~!!.755555555?  
 ~55555555?.     ~7!!!!~!!~~^:::::::::::::::::::::::::^7Y555555555Y?~::::::^~~~!~~~~~!!  ?55555555~ 
.Y5555555Y.      :??7!~!!!!!!~~^::::::::::::::::::::^7Y555555555Y7^:::::^~~~!~~~~~~~~^.  .Y5555555Y.
!55555555~     .~7???7!!!!!!!!!!~~^:::::::::::::::^?Y555555555Y7^:::^^^~~!~~~~~~~~!!!.    ~55555555!
J5555555J.    :!77!!777!7!!~!!!!!!~~~^^:::::::::~?Y555555555Y7^::^~~!!~~~~~~~~~!!!777~.   .J5555555J
555555557    :7!!!!7777????7!!!!!!~~~!~~~^::::~?5555555555J!^:^~~~!!!~~~~~~!7?Y?777!!7!.   75555555Y
55555555~    ~?77777777777????!!~~~~~~~~~~~~!J5555555555J!^:^~!!!~!!!~~~!?JY5PP5777!!77:   ~55555555
55555555^  !Y557!!7?YJ?77777?J?7??!~~~~~~!7J5555555555J!^~~!!!!!!!~!!!7J5PPPPPPPJ?7!77:    ^55555555
55555555^ ~PP55YJJY55J77!!7??7?JYYYJ?!~!7Y5555555555J!~!!!!!!!!!!!~~~JPPPPPP5YYY5J77~^.    ^55555555
55555555! ~PPPPPPP555YY!!~~~^~YYYYJYYYYY555555555YJ?7!77!!!!~!!!~^:::^?YYJ??JY55PJ77~.     ~55555555
Y5555555?  ^?YPPPPPP555555J?7!!?JYY555555555555YJ7!7?777!!!!7JJJ~:^^^^^~!?Y5PPPPP?!!7!.    ?5555555Y
?5555555Y:   .^!7?JY555PPPPP55?!~!?55555555555Y7~~!777!!7?JY55557~~~~!?J5PPPPP55?7777~.   :Y5555555J
~555555557  .:::::::^^~~7?77????JY555555555YYYYYJ?77?7?JYYYY55Y?!~!?5PPP55YYJYYJ?777!.    755555555~
.?55555555^  ......:~!7!!77!7?J5555555555Y?77??JYY5YYYYJ?7777!~!7?5Y!7?J?7!77777!~^^.    ^55555555J.
 ^Y5555555Y:        .:^~!77?J55555555555J!!!!!!777?7!!!~~~~~!?Y55YJ7::::^~~~~^.         :Y55555555^ 
  !55555555J.           .!Y55555555555555YJ7!!!!7777!~~~~!?Y5PJ!7777!~~~~^:::          .J55555555!  
   755555555J:         ^?5555555555J7JP5555777?77777!!7?J55555?~!!!!!!~^:.            :J555555557   
    755555555Y~     .~J5555555555J7!~~7JJJJ?JY55YJJJJYYYJ??JJ7!~~!~~:.               ~Y555555557    
     !5555555557. .~J555555555Y?^.^~!!~~~!~!!77???????777!~!!!!~^:.                .75555555557     
      ~Y55555555Y7J555555555Y7:     .^~~!!~~~~~~!77!!!!!!!!!!~^.                 .~Y55555555Y~      
       :?55555555555555555Y7:          .:^~!!~~~!77777!!!~^:.                  .~J555555555?:       
         ~Y5555555555555Y!:               .:~~!!!7777!~^.                    :!J555555555Y!         
          .7Y5555555555Y!.                   .:^!77~^.                    .^?Y555555555Y7.          
            :7Y5555555555Y?~:                    ..                    :~?Y5555555555Y7:            
              :!J55555555555YJ7~:.                                .:~7JY55555555555J!:              
                .^?Y555555555555YY?7~^:.                    .:^~7?JY555555555555Y?^.                
                   .~?Y555555555555555YYJJ?77!!~~~~~~!!!7?JJYY555555555555555Y?~.                   
                      .^7JY5555555555555555555555555555555555555555555555YJ7^.                      
                          .^!?JY555555555555555555555555555555555555YY?!^:                          
                              .:^!7?JYY5555555555555555555555YYJ?7!^:.                              
                                     .:^^~!77??????????77!~^^:..                                                  

@title Inedible Coin
@author Robert M.C. Forster, Chiranjibi Poudyal

Trading coin designed to avoid sandwich attacks. It should still
allow classic arbitrage and only rarely block innocent users from
making their trades.

It allows 2 swaps on each registered dex per block. So 40 dex 
swaps can occur per block if there are 20 registered dexes, but 
no more than 2 on each.

Added in votes capability to potentially change admin to a DAO.
**/                                                                                                                                           

contract Inedible is ERC20Votes {

    // Only privilege admin has is to add more dexes.
    // The centralization here shouldn't cause any problem.
    address public admin;
    address public pendingAdmin;

    // Dexes that you want to limit interaction with.
    mapping (address => uint256) private dexSwaps;

    constructor() 
        ERC20("Inedible Coin", "INEDIBLE")
        ERC20Permit("Inedible Coin") 
    {
        _mint(msg.sender, 888_888_888_888_888 ether);
        admin = msg.sender;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Only the administrator may call this function.");
        _;
    }

    /**
     * @dev Only thing happening here is checking if it's a dex transaction, then
     *      making sure not too many have happened if so and updating.
     * @param _to Address that the funds are being sent to.
     * @param _from Address that the funds are being sent from.
    **/
    function _beforeTokenTransfer(address _to, address _from, uint256) 
      internal
      override
    {
        uint256 toSwap = dexSwaps[_to];
        uint256 fromSwap = dexSwaps[_from];

        if (toSwap > 0) {
            if (toSwap < block.timestamp) { // No interactions have occurred this block.
                dexSwaps[_to] = block.timestamp;
            } else if (toSwap == block.timestamp) { // 1 interaction has occurred this block.
                dexSwaps[_to] = block.timestamp + 1;
            } 
        }
        
        if (fromSwap > 0) {
            if (fromSwap < block.timestamp) {
                dexSwaps[_from] = block.timestamp;
            } else if (fromSwap == block.timestamp) {
                dexSwaps[_from] = block.timestamp + 1;
            }
        }
        
        require(toSwap <= block.timestamp && fromSwap <= block.timestamp, "Too many dex transactions this block.");
    }

    /**
     * @dev Turn a new dex address either on or off
     * @param _newDex The address of the dex.
    **/
    function toggleDex(address _newDex) 
      external
      onlyAdmin
    {
        if (dexSwaps[_newDex] > 0) dexSwaps[_newDex] = 0;
        else dexSwaps[_newDex] = block.timestamp - 1;
    }

    /**
     * @dev Make a new admin pending. I hate 1-step ownership transfers. They terrify me.
     * @param _newAdmin The new address to transfer to.
    **/
    function transferAdmin(address _newAdmin)
      external
      onlyAdmin
    {
        pendingAdmin = _newAdmin;
    }
    
    /**
     * @dev Renounce admin if no one should have it anymore.
    **/
    function renounceAdmin()
      external
      onlyAdmin
    {
        admin = address(0);
    }

    /**
     * @dev Accept administrator from the pending address.
    **/
    function acceptAdmin()
      external
    {
        require(msg.sender == pendingAdmin, "Only the pending administrator may call this function.");
        admin = pendingAdmin;
        delete pendingAdmin;
    }

}