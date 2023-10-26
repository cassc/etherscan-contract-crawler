// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*                                        .......                            
                                    .-=+********##*=-.                       
                                 .=**++===----====+**#+-                     
                               :*#*====-==-::========+*#*=                   
                             :*#*===--::================+**-                 
                            +#*+==-::::-==================*#+.               
                          :*#*==--:::::-====================**:              
                         -*#+==-::::::-======================+*:             
                        -##+=-:::::::-========================+#-            
                       :##+=-::::::-===========================+#:           
                      .*#+=-::::::-=============================+*.          
                      +#+=-::::::-===============*=======--*=====+*          
                     :#*=-::::::-===============*#*======-*#*=====+=         
                     **=-::::::::==-----------=* ##---===* ##======*.        
                    :#+=::::::::::------------=*###------*###-======+        
                    +*=-::::::::::-------------"##-------"##------==*.       
                    *+--::::::::::---------------------------------=+-       
                   .#+--:::::::::----------------------------------=*.       
                    :*+=-----------------------------------------=**:        
                      :=*++=--------------------------------==+**=:          
                         .:=++*+++=====----------=====+++***+=:.             
                               ..:--==+++++++++++++==--:.. 

                                                                                           
 :BBBBBBBBBBBBBBBB:.    :LLLLLL:               ..:OOOOOOOO:..        :BBBBBBBBBBBBBBBB:.    
 :BBBBBBBBBBBBBBBBBB:.  :LLLLLL:             .OOOOOOOOOOOOOOOO.      :BBBBBBBBBBBBBBBBBB:.  
 :BBBBBBBBBBBBBBBBBBBB. :LLLLLL:           .OOOOOOOOOOOOOOOOOOOO.    :BBBBBBBBBBBBBBBBBBBB. 
 :BBBBBB:     'BBBBBBB: :LLLLLL:          :OOOOOOOO"    "OOOOOOOO:   :BBBBBB:     'BBBBBBB: 
 :BBBBBB:     .BBBBBBB' :LLLLLL:         :OOOOOOO"        "OOOOOOO:  :BBBBBB:     .BBBBBBB' 
 :BBBBBBBBBBBBBBBBBBB'  :LLLLLL:         OOOOOOO.          .OOOOOOO  :BBBBBBBBBBBBBBBBBBB'  
 :BBBBBBBBBBBBBBBBBB.   :LLLLLL:        :OOOOOOO:          :OOOOOOO: :BBBBBBBBBBBBBBBBBB.   
 :BBBBBBBBBBBBBBBBBBB.  :LLLLLL:        'OOOOOOO.          .OOOOOOO' :BBBBBBBBBBBBBBBBBBB.  
 :BBBBBB:     'BBBBBBB. :LLLLLL:         OOOOOOOO.        .OOOOOOOO  :BBBBBB:     'BBBBBBB. 
 :BBBBBB:     .BBBBBBB: :LLLLLL:         :OOOOOOOO:.    .:OOOOOOOO:  :BBBBBB:     .BBBBBBB: 
 :BBBBBBBBBBBBBBBBBBBB: :LLLLLLLLLLLLLL:  'OOOOOOOOOOOOOOOOOOOOOO'   :BBBBBBBBBBBBBBBBBBBB: 
 :BBBBBBBBBBBBBBBBBBBB  :LLLLLLLLLLLLLL:    "OOOOOOOOOOOOOOOOOO"     :BBBBBBBBBBBBBBBBBBBB  
 :BBBBBBBBBBBBBBBBBB"   :LLLLLLLLLLLLLL:       "":OOOOOOOO:""        :BBBBBBBBBBBBBBBBBB"   

*/

import "./ERC20Mod.sol";

contract BlobToken is ERC20Mod {
    string private _name = "Blob";
    string private constant _symbol = "BLOB";
    uint private constant _numTokens = 10_000_000_000;

    constructor() ERC20Mod(_name, _symbol) {
        address deployer = 0x6bC42c45aE8108CeE5205E0Ec7757a3e3E88131E;
        _mint(deployer, _numTokens * 10 ** decimals());
        transferOwnership(deployer);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}