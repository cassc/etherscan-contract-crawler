// SPDX-License-Identifier: AGPL-3.0-only
// @author creco.xyz 🐊 2022 
                                                                                             
pragma solidity ^0.8.17;
import "../lib/ERC1155M.sol";

 /*  
   _____                  _     _______       _     _ _           
  / ____|                | |   |__   __|     | |   | (_)          
 | |     _ __ _   _ _ __ | |_ ___ | | ___  __| | __| |_  ___  ___ 
 | |    | '__| | | | '_ \| __/ _ \| |/ _ \/ _` |/ _` | |/ _ \/ __|
 | |____| |  | |_| | |_) | || (_) | |  __/ (_| | (_| | |  __/\__ \
  \_____|_|   \__, | .__/ \__\___/|_|\___|\__,_|\__,_|_|\___||___/
               __/ | |                                            
              |___/|_|     
                              
           ----  ----####-           
         -#**++********+-#           
         #**-+***********            
          -##******#***#**           
            ####****---*+*           
            #####*----*%*-           
             -####*++++++            
             -########**-            
           -****####*****##-         
          *****###********###-       
         *****###**********####      
        *****####*********--##-      
        **** -######***##-           
         --  -*##----##**---         
            -****-    *******        
            *******   -*++--.        
              ----      
🐻               
*/   

contract CryptoTeddiesEditions is ERC1155M {

    bool public isFinalizedCollection;
    uint public tokenTracker;
    uint public constant LAST_MIGRATION_INDEX = 6;

    constructor(string memory _baseUri) 
        ERC1155M(_baseUri) {
        tokenTracker = LAST_MIGRATION_INDEX + 1;
    }


    /** @dev finalizes collection and freezes collection supply
    */
    function finalizeCollection() onlyAdmin external {
      isFinalizedCollection = true;
    }

    /** @dev mints n tokens with certain DNA
     */ 
    function mintTo(address _to, uint _amount, uint256 _tokenId) onlyMinter public returns(uint256) {
      require((!isFinalizedCollection || _tokenId <= LAST_MIGRATION_INDEX), "Cryptoteddies Editions - Collection is already finalized");
      _mint(_to, _tokenId, _amount,"");
      return _tokenId;
    }

    /** @dev mints n tokens with certain DNA
     */ 
    function mintWithDNA(address _to, uint amount, uint256 _dna) onlyMinter public returns(uint256) {
      require((!isFinalizedCollection), "Cryptoteddies Editions - Collection is already finalized");
      uint tokenId = dnaToTokenId[_dna];
      if (tokenId != 0) {
        _mint(_to, tokenId, amount, "");
      } else {
         tokenId = tokenTracker;
         tokenTracker++;
        _mint(_to, tokenId, amount, "");
         uint256[] memory ids = new uint256[](1);
         ids[0] = tokenId;
         uint256[] memory dnas = new uint256[](1);
         dnas[0] = _dna;
         setDNA(ids, dnas);
      }
      return tokenId;
    }
}