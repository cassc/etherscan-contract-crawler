// SPDX-License-Identifier: Apache 2.0
/**

                                            ...::::::::::..                               
                                   .-==++**##*************###**+==-:                      
                      =      .:=+*#******************************--=+=-.                  
                      #=  :=*************************************-::::=#+.                
                 .-==-******************************************=::::-***#=               
                    -******************************************-:::=+*******.             
                 -+******************************************=:::-=====+*****             
                -*********************************************+++==:::::****#-            
                ****************************************************:::+*****#            
               :#***********************+-+***********************+-:=*******#.           
               :#***********************----=+******************=--=*********#            
               .#********************+=--------=++***********+===***%#******#-            
                ******************+=------------------=========-----+#*****#=             
                =*+==---::+****+*=---------------=++=----------------*****#-              
                .+:::::----::::-+------------=++*++*%#*==---==-------=#*#+.               
                 =++***+-:-==++=------------=*#*############+#=+*****###*=--:             
                 .****++*****=--------------#**+----------+**#*#**====++++***+            
               .--+**********=--------------#*#=-----------#**=#*=---------=*#            
             -==-------+*#****+=------------+#**::::--::..-*#+=#*=::----:--+*+            
            ==--======---+**++*+=------------+#**=-::.::-=**+-+**+:.:::...=**.            
           .*---------=+=++===*----------------+*#********+===+#***+=---=*#+.             
           .*-----------+#=++=+=-----------=====+====+=---------:-=+*+*#**-               
            *------------#=::--*-------=====+==++====-=++++=-:-=**#+====+**=-             
            .*-----------#----=+=--====----:::::-=====-:::----===-::--==+===-+.           
             .+=--==+----#-==-::+==::-==-:---::::::::::::::::----:::::::----:-+           
               :*+*==---=#-----=--:==-:::==::::::::::::::::::::::::::::::----:+.          
              .+=-.:-=+*-#=-==-::=+-:-:=+-::::::::::::::--::::::::::::-:::=--==-          
              ==+:   :=+:*==-::=+-:---+-:::-::-::::::::--:::::::::-::---:::+--++          
              .+==-:-==+.-==--+=::=-=+:::-=::=-:-:::::--:::::::::-:=:-:--:::+:=#          
                :-----.    ..+===+-+=:::-=::=-:--:--:-=:::-::::-:=:=::=:=::--=:+.         
                                 :-======::==:--:=-::+:::-::-:--:=:=::=:-=:-:+:+:         
                                     .:=***#+=+--=::+-::--:--:=::=:=-:=-:+:---=+:         
                              .:--++*#++#**#++**##***+==*==+--=::=:=-:-=:=-:-:+=:         
                         :-=+***+=**=**+***=-====#*+#+=**=*##*+=-------------:-:.         
                      .+****+#+**+=**=*#***=  +: ****+**=+**=*#**+=-.                     
                       .=**++++*##++**=****= -=+ +**+#*=+##**++++**+:                     
                         .=**++++**+*#+***** =:=.=**+#+***+++++**+:                       
                           :##**+++*+**#***# :** =**+#*+*++++*#*.                         
                           *++*##**********#.-:::=**+#****####+*-                         
                          -*+++*****#####+**+====+***####****+++*.                        
                         .*+++**#++**+*+#+**+.=+.+****+++*+***++*+                        
                         +*++*****++++++#+***  . +**+*+++++#***+++=          


 */
pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Broskees Contract
/// @author UncleAaroh
/// @custom:security-contact  [email protected]

contract BroskeesContract is
    ERC721A,
    IERC2981,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using Strings for uint256;

    /// @dev === CONTRACT META ===
    string public contractURIstr = "ipfs://QmcZn3ZpDrHJGCkRAAQKsPXqPAmN8fZ9EhFBJBySijEtAb";
    string public baseExtension = ".json";
    string public notRevealedUri = "ipfs://QmcZn3ZpDrHJGCkRAAQKsPXqPAmN8fZ9EhFBJBySijEtAb";
    string private baseURI;

    /// @dev === WHITELIST CONFIGURATION ===
    bytes32 public whitelistMerkleRoot;
    mapping(address => uint256) private _whitelistMintTracker;

    /// @dev === PRICE CONFIGURATION ===
    uint256 public constant WHITELIST_PRICE = 0.1691 ether;
    uint256 public royalty = 75; // 75 is divided by 10 in the royalty info function to make 7.5%

    /// @dev === RESERVE/DROPS CONFIGURATION ===
    uint256 public constant NUMBER_RESERVED_TOKENS = 10;

    /// @dev === SALE CONFIGURATION ===
    bool public revealed = false;
    bool public whiteListSaleIsActive = false;
    uint256 public constant MAX_SUPPLY = 1691;
    uint256 public maxPerTransaction = 1;
    uint256 public maxPerWallet = 1;

    /// @dev === Stats ===
    uint256 public currentId = 0;
    uint256 public whitelistMint = 0;
    uint256 public reservedTokensMinted = 0;

    /// @dev === ACCEPTANCE TEST  ====
    bool public testWithDraw = false;
    bool public testReserved = false;

    constructor() ERC721A("Broskees", "BROSKEES") {}

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
        _safeMint(msg.sender, numberOfTokens);
        currentId = currentId + numberOfTokens;
        whitelistMint = whitelistMint + numberOfTokens;
        _whitelistMintTracker[msg.sender] =
            _whitelistMintTracker[msg.sender] +
            numberOfTokens;
    }

    function mintReservedToken(address to, uint256 numberOfTokens)
        external
        canReserveToken(numberOfTokens)
        isNonZero(numberOfTokens)
        nonReentrant
        onlyOwner
    {
        testReserved = true;
        _safeMint(to, numberOfTokens);
        reservedTokensMinted = reservedTokensMinted + numberOfTokens;
    }

    /// @dev === Withdraw - Output  ====

    function withdraw() external onlyOwner {
        // This is a test to ensure we have atleast withdrawn the amount once in production.
        testWithDraw = true;
        payable(owner()).transfer(address(this).balance);
    }

    /// @dev === Override ERC721A ===

    /**
        We want our tokens to start at 1 not zero.
    */
    function _startTokenId() 
        internal 
        view 
        virtual 
        override 
        returns (uint256) 
    {
        return 1;
    }

    /// @dev === PUBLIC READ-ONLY ===

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /// @dev This is based on https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() 
        external 
        view 
        returns 
        (string memory) 
    {
        return contractURIstr;
    }

    function numberMinted(address owner) 
        public 
        view 
        returns 
        (uint256) 
    {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    /// @dev === INTERNAL READ-ONLY ===
    function _baseURI() 
        internal 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        return baseURI;
    }

    /// @dev === Owner Control/Configuration Functions ===

    function setReveal(bool _reveal) 
        public 
        onlyOwner 
    {
        revealed = _reveal;
    }

    function setBaseURI(string memory _newBaseURI) 
        public 
        onlyOwner 
    {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) 
        public 
        onlyOwner 
    {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setContractURI(string calldata newuri) 
        external 
        onlyOwner
    {
        contractURIstr = newuri;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) 
        external 
        onlyOwner 
    {
        whitelistMerkleRoot = merkleRoot;
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
    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) 
        public 
        override 
        view 
        returns 
        (bool isOperator) 
    {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721A.isApprovedForAll(_owner, _operator);
    }

    function royaltyInfo(
        uint256, /*_tokenId*/
        uint256 _salePrice
    )
        external
        view
        override(IERC2981)
        returns (address Receiver, uint256 royaltyAmount)
    {
        return (owner(), (_salePrice * royalty) / 1000); //100*10 = 1000
    }

    /// @dev === MODIFIERS ===
    modifier isValidMerkleProof(
        bytes32[] calldata merkleProof, 
        bytes32 root
    ) {
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

    modifier canClaimToken(uint256 numberOfTokens) {
        require(
            _whitelistMintTracker[msg.sender] + numberOfTokens <= maxPerWallet,
            "Cannot claim more than allowed limit per address"
        );
        _;
    }

    modifier canReserveToken(uint256 numberOfTokens) {
        require(
            reservedTokensMinted + numberOfTokens <= NUMBER_RESERVED_TOKENS,
            "Cannot reserve more than 10 tokens"
        );
        _;
    }

    modifier isCorrectPayment(
        uint256 price, 
        uint256 numberOfTokens
    ) {
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
        _;
    }

    modifier isSupplyRemaining(uint256 numberOfTokens) {
        require(
            totalSupply() + numberOfTokens <=
                MAX_SUPPLY - (NUMBER_RESERVED_TOKENS - reservedTokensMinted),
            "Purchase would exceed max supply"
        );
        _;
    }

    modifier isSaleActive(bool active) {
        require(active, "Sale must be active to mint");
        _;
    }

    modifier isNonZero(uint256 num) {
        require(num > 0, "Parameter value cannot be zero");
        _;
    }

    /// @dev === Support Functions ==
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }
}