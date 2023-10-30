// SPDX-License-Identifier: Apache 2.0
/**

                               ...                                                        
                              .:::::..                                                    
                            ..::::::::::..                                                
                          ...:::::::::::::::.                                             
                        ..::::::::::::::::::::::.                                         
                      .::::.. .::::::::::::::::::::..                                     
                    .:..        ..:::::::::::::::::--:                                    
                                   .:::::::::::::-----:                                   
                                ..    .:::::::---------:                                  
          :.                   .:::::::.:::-------------:                                 
        .::::                 .:::::::::-----------------:                                
       .::::::.               :::::-----------------------:                               
         .::                 :-----------------------------:                              
                            :-------------------------------:                             
                           :--------------------------------=.                   .        
                          :----------------------------=======.                 :=-       
                         :------------------------=============.              .-====:     
                        :------------------=====================.           .-========:.  
                       .=========================================.        .-============: 
                      .===========================================.          :=======-.   
                     .=============================================            :===-      
    .=:              ===============================================             =:       
  .-====.           =================================================                     
    :=-            ===================================================                    
                  =++++++++++++++++=============================++++++=                   
                 =++++++++++++++++++++++++++++++++++++++++++++++++=-:.                    
               .=+++++++++++++++++++++++++++++++++++++++++++++=-:.     .::                
             .=++++++++++++++++++++++++++++++++++++++++++++-:.   ..:-=+++++-              
           .=**++++++++++++++++++++++++++++++++++++++++=:. ..:-=+++++++++++++-            
         :=************++++++++++++++++++++++++++++-::::-=+++++++++++++++++++++-          
       :+********************+++++++++++++++++++++=++++++++++++++++++++++++++++++-.       
     -****************************+++++++++++++++++++++++++++++++++++++++++++++++++-.     
   -*********************************++++++++++++++++++++++++++++++++++++++++++++++++=.   
.=***************************************++++++++++++++++++++++++++++++++++++++++++++++=. 
:=+*########********************************++++++++++++++++++++++++++++++++++++++++++=-. 
    .:=+*########******************************++++++++++++++++++++++++++++++++++=-:.     
         .:=*########****************************+++++++++++++++++++++++++++=-:.          
              .-=*######***************************++++++++++++++++++++=-:.               
.++-:.             .:=+*##****************************++++++++++++=-:.             .:-=+: 
 .=++++=-:.             .:=+*****************************++++=-:.             .:-=+++++:  
   -++++++++=-:.             .:-+**********************+=-:.              :-=++++++++=    
    :++++++++++++=-:.             .:-=*************=-:.             .:-=++++++++++++-     
     .++++++++++++++++=-:.              :-=+**=-:.              :-=++++++++++++++++:      
       =+++++++++++++++++++=-:.                            :-=+*****++++++++++++++.       
        :+++++++++++++++++++++++=-:                  .:-=+************++++++++++=         
         .+++++++++++++++++++++++++++=:.         .-=********************+++++++:          
           =+++++++++++++++++++++++++++++=-:.:=+****************************++.           
            -++++++++++++++++++++++++++++++++*******************************=             
             :+++++++++++++++++++++++++++++++******************************-              
              .=+++++++++++++++++++++++++++++****************************+:               
                -++++++++++++++++++++++++++++***************************=                 
                 :+++++++++++++++++++++++++++**************************:                  
                   =+++++++++++++++++++++++++************************+.                   
                    -++++++++++++++++++++++++#**********************=                     
                     .+++++++++++++++++++++++##********************-                      
                      .++++++++++++++++++++++###******************:                       
                        -++++++++++++++++++++####***************+.                        
                         :+++++++++++++++++++#####*************=                          
                          .++++++++++++++++++######***********:                           
                            =++++++++++++++++#######********+.                            
                             :++++++++++++++*#########*****=                              
                              .+++++++++++++*##########***-                               
                                =+++++++++++*###########*.                                
                                 -++++++++++*##########+                                  
                                  :+++++++++*#########-                                   
                                   .=+++++++*#######*.                                    
                                     :++++++*######+                                      
                                      .+++++*#####-                                       
                                        =+++*###*.                                        
                                         -++*##+                                          
                                          .+*#-                                           


*/

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title Wizard Pass Contract
/// @author @UncleAaroh - @HashtagHodling
/// @custom:security-contact  [email protected]
contract WizardGoldPassContract is 
    ERC1155Supply, 
    IERC2981, 
    Ownable, 
    Pausable, 
    ReentrancyGuard 
{
     /// @dev === CONTRACT META ===
    string public name = "Wizard Gold Pass";
    string public contractURIstr = "ipfs://Qme3wFagfssfuZJgFB8CLnog9BeFgNjqjkFBGZcbznjWcE";
    
    /// @dev === PRICE CONFIGURATION ===
    uint256 public royalty = 88; // 88 is divided by 10 in the royalty info function to make 8.8% 

    /// @dev === RESERVE/DROPS CONFIGURATION ===
    uint256 public constant NUMBER_RESERVED_TOKENS = 188;

    /// @dev === Stats ===
    uint256 public reservedTokensMinted = 0;

    /// @dev === ACCEPTANCE TEST  ====
    bool public testWithDraw = false;
    constructor() ERC1155("ipfs://QmXH8jF95rkAeYFbEBdvCPvPhNp7Jpm55cFGRkc9wZXa97/{id}.json") {}

    function mintReservedToken(
        address to, 
        uint256 numberOfTokens
    ) 
        external
        canReserveToken(numberOfTokens)
        isNonZero(numberOfTokens)
        nonReentrant
        onlyOwner
    {
        _mint(to, 1, numberOfTokens, "");
        reservedTokensMinted = reservedTokensMinted + numberOfTokens;
    }

    /// @dev === Withdraw - Output  ====

    function withdraw() 
        external 
        onlyOwner 
    {
        // This is a test to ensure we have atleast withdrawn the amount once in production.
        testWithDraw = true; 
        payable(owner()).transfer(address(this).balance);
    }

    /// @dev === PUBLIC READ-ONLY ===
    function getName() 
        external 
        view 
        returns (string memory) 
    {
       return name;
    }
    function contractURI() 
        external 
        view 
        returns (string memory)
    {
       return contractURIstr;
    }

    /// @dev === Owner Control/Configuration Functions ===
    function setName(string calldata _name) 
        external 
        onlyOwner 
    {
        name = _name;
    }

    function setContractURI(string calldata newuri) 
        external 
        onlyOwner
    {
       contractURIstr = newuri;
    }

    function setTokenURI(string calldata newuri) 
        external 
        onlyOwner
    {
        _setURI(newuri);
    }

    function pause() 
        external 
        onlyOwner 
    {
        _pause();
    }

    function unpause() 
        external 
        onlyOwner 
    {
        _unpause();
    }

    /// @dev Royalty should be added as whole number example 8.8 should be added as 88
    function setRoyalty(
        uint256 _royalty
    ) 
        external
        isNonZero(_royalty)
        onlyOwner
    {
        royalty = _royalty;
    }

    /// @dev === Marketplace Functions ===
    function royaltyInfo(
        uint256 /*_tokenId*/, 
        uint256 _salePrice
    ) 
        external 
        view 
        override(IERC2981) 
        returns (address Receiver, uint256 royaltyAmount) 
    {
        return (owner(), _salePrice * royalty / 1000);
    }

    /// @dev === MODIFIERS ===
    modifier canReserveToken(uint256 numberOfTokens) 
    {
        require(
            reservedTokensMinted + numberOfTokens <= NUMBER_RESERVED_TOKENS,
            "Cannot reserve more than 188 tokens"
        );
        _;
    }

    modifier isNonZero(uint256 num) {
        require(
            num > 0,
            "Parameter value cannot be zero"
        );
        _;
    }

    /// @dev === Support Functions ==
     function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}