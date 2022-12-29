// SPDX-License-Identifier: AGPL-3.0-only
// @author creco.xyz 🐊 2022 
                                                                                             
pragma solidity ^0.8.17;
import "../lib/ERC721M.sol";

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

contract CryptoTeddies is ERC721M {

    bool public isFinalizedCollection;
    
    uint public tokenTracker;
    uint public constant LAST_MIGRATION_INDEX = 175;

    constructor(string memory _name, string memory _symbol, string memory _baseUri) 
    ERC721M(_name, _symbol, _baseUri) {
      // @dev startIndex for new mints starts at 176. 1-175 are reserved for mifrated tokens.
      tokenTracker = LAST_MIGRATION_INDEX + 1;
    }

    /** @dev finalizes collection and freezes collection supply
    */
    function finalizeCollection() onlyAdmin external {
      isFinalizedCollection = true;
    }

    /** @dev mints token to a specific tokenId 
     */ 
    function mintTokenId(address _to, uint256 _tokenId) onlyMinter public returns(uint256) {
      // tokenIds <=175 can be minted even if collection finalized
      require((!isFinalizedCollection || _tokenId <= LAST_MIGRATION_INDEX), "Cryptoteddies - Collection is already finalized");
      _mint(_to, _tokenId);
      return _tokenId;
    }

    /** @dev mints token to default incremented id. Id increment startIndex = 175.
     */ 
    function mintTo(address _to) onlyMinter public returns(uint256) {
      uint tokenId = tokenTracker;
      tokenTracker++;
      return mintTokenId(_to, tokenId);
    }

    /** @dev mints token to a specific tokenId and sets the token DNA
     */
    function mintWithDNA(address _to, uint256 _dna) onlyMinter external returns(uint256) {
      uint tokenId = mintTo(_to);
      uint256[] memory ids = new uint256[](1);
      ids[0] = tokenId;
      uint256[] memory dnas = new uint256[](1);
      dnas[0] = _dna;
      setDNA(ids, dnas);
      return tokenId; 
    }  
}