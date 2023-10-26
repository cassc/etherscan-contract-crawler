// SPDX-License-Identifier: MIT

/*

                                     ..         .=++#       .:-==-==                                
                                   :*%=     .-++=..%.  :=**+=:.  :@=                                
                                 .#+ #=   -**:    -#:+*=:       :%*.+**+**.                         
                                -%:  ** :#+       =%=          -@+=%-  ##--  .                      
                               *#    .%**        #=           .@=+*   :@:    *#+                    
                              #*      %=        #:            .@*+     =%=   *=-%:                  
                      =@:    #*      --        .              -#:        +%: #- -@.                 
                     *@:%:  +#       :                                    .%:@.  *#                 
                    +@: .#*-@.                                             -@+   :@. :              
                   -@:    .-.                                             -#=     @+**=             
                   @+                               :.                   =-  :.-+#*: +*             
                  =@.           +%%*:            =#@@@#                      :--.   .%=             
                  =@            +@@@@=         .#@@@@@*                            =%##             
                  -@:             =%@#         %@@%*=.                         .-+#=.-@.            
                  .@.          .:.  ::        :=:   :=*+=:                     .:   :%*             
                .=@=         :-#@@#.              =%@@@%::+                      :=##:              
              =#@*:::       --.@@@@*            -%@@@@@*  -*                  .++=:**               
           .*@@@%@#=       :# -@@@@@           +@@@@@@@@   #:                       ##              
         .#@%*#@*:         #. -@@@@@          *@@@@@@@@@   -+                       :@*             
        :+-.:#+.          :#-  +%%@@         -@@@@@@@@@+   .#                        +@:            
           *%:    .:        -++:  :*         #=*@@@@@%=     #                         @#            
         :%+.-+*+=:     :.     -==+:        :=   :::.      :#                         +@.           
        -@%%@@:         =%:                 .==-.....:-=++=-                    *#+:  :@-           
       -@#=.%*          =+=*:                  .:-=--::                          +@#%: @-           
       +.  #%            %  -++-                            .                    @@ -@:@:           
         :%#  ::         .=-   :*-             ::.        =*=                    @@  .%@            
     .=+%%- .-@@           .+=   -*:       :++=::-========.-=                    *@.  .-            
        :=+**+#@.            .+-   =+=====+-              :*                     -@+                
              =@-   :%=        +*                      .-+=                       #@                
               @*  .@@@:        .*=.        .=++++==+++-.                    -+:  :@=               
               -@: *@:+@=         .=+++++=-+-.                              -@@@-  %#               
                =@.%#  :%#:                                                =@#.#%  +@               
                 -%@=    =%#-                                :+          -%%-  :@: +%               
                   *:      :+#+:                           :#%%+     :=#%+:     @- %+               
                            .%@#@                        -#%+ +# .=*#@%.        #=+#                
                           .%@-:@-  .:                .=%%=   =%*=:  :@#        *@*                 
                           #@=  +% #%%*  +##-       -*@#-             =@+       ..                  
                          *@+    *%- -@=@*:@+   -+#@#=.                #@:                          
                         +@*          %#:  #**%@*+-             .       @%                          
                        :@%  =             :-:.                 #-      =@*                         
                       .@@. #-                                  -%       #@:                        
                       #@= **                                    %=      :@#                        
                      +@* =%                                     =@       #@:                       
                     :@% :@:                                      @=      :@*                       
                     %@: %+                                       +%       %@.                      
                    +@+ *%                                        :@-      =@+
 */
pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

struct SaleConfig {
    uint256 price;
    uint256 maxPerWallet;
    uint256 maxPerTx;
}
struct SaleStateInfo {
    SaleConfig goldlistSale;
    SaleConfig dreamlistSale;
    SaleConfig publicSale;
}

contract LilDreamerz is ERC721A, Ownable, ReentrancyGuard {
    enum SaleStates {
        OFF,
        PRIVATE_SALE,
        PUBLIC_SALE
    }
    using Strings for uint256;

    bytes32 public goldMerkleRoot;
    bytes32 public dreamMerkleRoot;
    SaleStateInfo public saleStateInfo;
    mapping(address => uint256) public dreamerzClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public maxSupply;
    SaleStates public currentState = SaleStates.OFF;
    bool public revealed = true;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        string memory _hiddenMetadataUri,
        SaleStateInfo memory _saleStateInfo
    ) ERC721A(_tokenName, _tokenSymbol) {
        maxSupply = _maxSupply;
        setHiddenMetadataUri(_hiddenMetadataUri);
        saleStateInfo = _saleStateInfo;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= maxSupply, "Purchase would exceed max supply");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount, uint256 _price) {
        require(msg.value >= _price * _mintAmount, "Funds received insufficient");
        _;
    }

    function setupGoldlistMint(uint256 _mintAmount)
        internal
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount, saleStateInfo.goldlistSale.price)
    {
        // Verify goldlist requirements
        bool canMintThisMany = dreamerzClaimed[_msgSender()] + _mintAmount <= saleStateInfo.goldlistSale.maxPerWallet;
        require(canMintThisMany, "Maximum mints per wallet exceed.");
    }

    function setupDreamlistMint(uint256 _mintAmount)
        internal
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount, saleStateInfo.dreamlistSale.price)
    {
        // Verify dreamlist requirements
        bool canMintThisMany = dreamerzClaimed[_msgSender()] + _mintAmount <= saleStateInfo.dreamlistSale.maxPerWallet;
        require(canMintThisMany, "Maximum mints per wallet exceed.");
    }

    function privateMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
        require(currentState == SaleStates.PRIVATE_SALE, "The private sale is not open!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        if (MerkleProof.verify(_merkleProof, goldMerkleRoot, leaf)) {
            setupGoldlistMint(_mintAmount);
        } else if (MerkleProof.verify(_merkleProof, dreamMerkleRoot, leaf)) {
            setupDreamlistMint(_mintAmount);
        } else {
            require(false, "Invalid proof!");
        }
        _safeMint(_msgSender(), _mintAmount);
        dreamerzClaimed[_msgSender()] += _mintAmount;
    }

    function publicMint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount, saleStateInfo.publicSale.price)
    {
        require(currentState == SaleStates.PUBLIC_SALE, "The sale has not started!");
        require(_mintAmount <= saleStateInfo.publicSale.maxPerTx, "Mint amount exceeds per transaction capacity!");
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setConfigData(SaleStateInfo memory _saleStateInfo) public onlyOwner {
        saleStateInfo = _saleStateInfo;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setGoldMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        goldMerkleRoot = _merkleRoot;
    }

    function setDreamMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        dreamMerkleRoot = _merkleRoot;
    }

    function setSaleState(SaleStates _state) public onlyOwner {
        currentState = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}