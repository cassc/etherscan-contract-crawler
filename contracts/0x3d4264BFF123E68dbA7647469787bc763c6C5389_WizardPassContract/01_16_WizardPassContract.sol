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
/// @author UncleAaroh
/// @custom:security-contact  [email protected]
contract WizardPassContract is 
    ERC1155Supply, 
    IERC2981, 
    Ownable, 
    Pausable, 
    ReentrancyGuard 
{
     /// @dev === CONTRACT META ===
    string public name = "Wizard Pass";
    string public contractURIstr = "ipfs://Qmb2cVWGDkRZyNEjJrvRgAn46PPkemL4V748eq9RkBBfyL/";
    
    /// @dev === WHITELIST CONFIGURATION ===
    bytes32 public whitelistMerkleRoot;
    mapping(address => uint256) private _whitelistMintTracker;
    
    /// @dev === PRICE CONFIGURATION ===
    uint256 public constant WHITELIST_PRICE = 0.25 ether;
    uint256 public constant PRICE = 0.45 ether;
    uint256 public royalty = 88; // 88 is divided by 10 in the royalty info function to make 8.8% 

    /// @dev === RESERVE/DROPS CONFIGURATION ===
    uint256 public constant NUMBER_RESERVED_TOKENS = 197;

    /// @dev === SALE CONFIGURATION ===
    bool public saleIsActive = false;
    bool public whiteListSaleIsActive = false;
    uint256 public constant MAX_SUPPLY = 2997;
    uint256 public maxPerTransaction = 3;
    uint256 public maxPerWallet = 3;

    /// @dev === Stats ===
    uint256 public currentId = 0;
    uint256 public whitelistMint = 0;
    uint256 public publicMint = 0;
    uint256 public reservedTokensMinted = 0;

    /// @dev === ACCEPTANCE TEST  ====
    bool public testWithDraw = false;

    constructor() ERC1155("ipfs://QmZnDqcQMdHCALJuNfCjzGQFbLNJLxfkUBPsy4KZksJHWT/{id}.json") {}

    /// @dev === Minting Function - Input ====
     function mintWhitelist(
      bytes32[] calldata merkleProof,
      uint256 numberOfTokens
    )
        external
        payable
        isSaleActive(whiteListSaleIsActive)
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        canClaimToken(numberOfTokens)
        isCorrectPayment(WHITELIST_PRICE, numberOfTokens)
        isCorrectAmount(numberOfTokens)
        isSupplyRemaining(numberOfTokens)
        nonReentrant
        whenNotPaused
    {
        _mint(msg.sender, 1, numberOfTokens, "");
        currentId  = currentId + numberOfTokens;
        whitelistMint = whitelistMint + numberOfTokens;
        _whitelistMintTracker[msg.sender] = _whitelistMintTracker[msg.sender] + numberOfTokens;
    }

    function mintToken(uint256 numberOfTokens) 
        external
        payable
        isSaleActive(saleIsActive)
        isCorrectPayment(PRICE, numberOfTokens)
        isCorrectAmount(numberOfTokens)
        isSupplyRemaining(numberOfTokens)
        nonReentrant
        whenNotPaused
    {
        _mint(msg.sender, 1, numberOfTokens, "");
        currentId  = currentId + numberOfTokens;
        publicMint = publicMint + numberOfTokens;
    }

    function mintReservedToken(
        address to, 
        uint256 numberOfTokens
    ) 
        external
        isSupplyRemaining(numberOfTokens)
        canReserveToken(numberOfTokens)
        isNonZero(numberOfTokens)
        nonReentrant
        onlyOwner
    {
        _mint(to, 1, numberOfTokens, "");
        currentId  = currentId + numberOfTokens;
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
    function setWhitelistMerkleRoot(bytes32 merkleRoot) 
        external 
        onlyOwner 
    {
        whitelistMerkleRoot = merkleRoot;
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

    function flipPublicSaleState() 
        external 
        onlyOwner
    {
        saleIsActive = !saleIsActive;
    }
    
    function flipWhitelistSaleState() 
        external 
        onlyOwner
    {
        whiteListSaleIsActive = !whiteListSaleIsActive;
    }

    /// @dev Royalty should be added as whole number example 8.8 should be added as 88
    function updateSaleDetails(
        uint256 _royalty, 
        uint256 _maxPerTransaction, 
        uint256 _maxPerWallet
    ) 
        external
        isNonZero(_royalty)
        isNonZero(_maxPerTransaction)
        isNonZero(_maxPerWallet)
        onlyOwner
    {
        royalty = _royalty;
        maxPerTransaction = _maxPerTransaction;
        maxPerWallet = _maxPerWallet;
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
    modifier isValidMerkleProof(
        bytes32[] calldata merkleProof, 
        bytes32 root
    ) 
    {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier canClaimToken(uint256 numberOfTokens) 
    {
        require(
            _whitelistMintTracker[msg.sender] + numberOfTokens <= 3,
            "Cannot claim more than 3 per whitelist address"
        );
        _;
    }

    modifier canReserveToken(uint256 numberOfTokens) 
    {
        require(
            reservedTokensMinted + numberOfTokens <= NUMBER_RESERVED_TOKENS,
            "Cannot reserve more than 197 tokens"
        );
        _;
    }

    modifier isCorrectPayment(
        uint256 price, 
        uint256 numberOfTokens
    ) 
    {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isCorrectAmount(uint256 numberOfTokens) {
        require(
            numberOfTokens > 0 && numberOfTokens <= maxPerTransaction, 
            "Max per transaction reached, sale not allowed"
        );
        require(balanceOf(msg.sender, 1) + numberOfTokens <= maxPerWallet,      
            "Limit per wallet reached with this amount, sale not allowed"
        );
        _;
    }

    modifier isSupplyRemaining(uint256 numberOfTokens) {
        require(
            totalSupply(1) + numberOfTokens <= MAX_SUPPLY - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), 
            "Purchase would exceed max supply"
        );
        _;
    }

    modifier isSaleActive(bool active) {
        require(
            active,
            "Sale must be active to mint"
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