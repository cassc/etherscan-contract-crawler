// SPDX-License-Identifier: MIT


    //   __         ______     __  __     __   __     ______     __  __     __     ______   __    
    //  /\ \       /\  __ \   /\ \/\ \   /\ "-.\ \   /\  ___\   /\ \_\ \   /\ \   /\  ___\ /\ \   
    //  \ \ \____  \ \  __ \  \ \ \_\ \  \ \ \-.  \  \ \ \____  \ \  __ \  \ \ \  \ \  __\ \ \ \  
    //   \ \_____\  \ \_\ \_\  \ \_____\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \_\  \ \_\    \ \_\ 
    //    \/_____/   \/_/\/_/   \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/   \/_/   \/_/     \/_/ 

    pragma solidity >=0.8.13 <0.9.0;

        
    import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";
    import "@openzeppelin/contracts/utils/Counters.sol";
    import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
    import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
        
    contract SuperEarlyBulldogs is ERC721, Ownable, ReentrancyGuard  , DefaultOperatorFilterer {
        using Strings for uint256;
        using Counters for Counters.Counter;
    
        uint256 public price;
        uint256 public _maxSupply;
        uint256 public maxMintAmountPerTx;
        uint256 public maxMintAmountPerWallet;
        string baseURL = "";
        string ExtensionURL = ".json";
        bool paused = false;
        Counters.Counter private _tokenIdCounter;

             
        error ContractPaused();
        error MaxMintWalletExceeded();
        error MaxSupply();
        error InvalidMintAmount();
        error InsufficientFund();
        error NoSmartContract();
        error TokenNotExisting();
         
        
        constructor(uint256 _price, uint256 __maxSupply, string memory _initBaseURI, uint256 _maxMintAmountPerTx, uint256 _maxMintAmountPerWallet) ERC721("Super Early Bulldogs", "bdog") {
            baseURL = _initBaseURI;
            price = _price;
            _maxSupply = __maxSupply;
            maxMintAmountPerTx = _maxMintAmountPerTx;
            maxMintAmountPerWallet = _maxMintAmountPerWallet;
              
        }
    
        // ================= Mint Function =======================

        modifier mintCompliance(uint256 _mintAmount) {
            if (msg.sender != tx.origin) revert NoSmartContract();
            if (_mintAmount < 0 || _mintAmount > maxMintAmountPerTx) revert InvalidMintAmount();
            if (currentSupply() + _mintAmount > _maxSupply) revert MaxSupply();
            if (msg.value < price) revert InsufficientFund();
            if(paused) revert ContractPaused();
            if(balanceOf(msg.sender) + _mintAmount > maxMintAmountPerWallet) revert MaxMintWalletExceeded();
            _;
        }

   

   /// @notice compliance of minting
    /// @dev user (msg.sender) mint
    /// @param _mintAmount the amount of tokens to mint
        function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount)
        {   
           
          multiMint(msg.sender, _mintAmount);
        }
            
            
    
        // =================== Orange Functions (Owner Only) ===============

        /// @dev pause/unpause minting
        function pause() public onlyOwner {
            paused = !paused;
        }
    
        
            /// @notice airdrop function to airdrop same amount of tokens to addresses
            /// @dev only owner function
            /// @param _receiver  array of addresses
            /// @param _mintAmount the amount of tokens to airdrop users
            function airdrop(address[] memory _receiver, uint _mintAmount ) public onlyOwner{
            if (currentSupply() + (_receiver.length * _mintAmount) > _maxSupply) revert MaxSupply();
            if(paused) revert ContractPaused();
            for (uint i=0 ; i<_receiver.length; i++)
              multiMint(_receiver[i],  _mintAmount);
        }
    
        
        /// @dev set URI
        function setbaseURL(string memory uri) public onlyOwner{
            baseURL = uri;
        }

        /// @dev extension URI like 'json'
        function setExtensionURL(string memory uri) public onlyOwner{
            ExtensionURL = uri;
        }   

        /// @dev only owner
        /// @param supply  new max supply
        function setMaxSupply(uint256 supply) public onlyOwner{
          _maxSupply = supply;
        }

        /// @dev only owner
        /// @param perTx  new max mint per transaction
        function setMaxMintAmountPerTx(uint256 perTx) public onlyOwner{
          maxMintAmountPerTx = perTx;
        }

        /// @dev only owner
        /// @param perWallet  new max mint per wallet
        function setMaxMintAmountPerWallet(uint256 perWallet) public onlyOwner{
          maxMintAmountPerWallet = perWallet;
        }      

        // ================== Withdraw Function =============================

        /// @notice withdraw ether from contract.
        /// @dev only owner function
        function withdraw() public onlyOwner nonReentrant{
            
            
            (bool owner, ) = payable(owner()).call{value: address(this).balance}('');
            require(owner);    
        }
    
        // =================== Blue Functions (View Only) ====================
    
        /// @dev return uri of token ID
        /// @param tokenId  token ID to find uri for
        ///@return value for 'tokenId uri'
        function tokenURI(uint256 tokenId)public view virtual override returns (string memory){
            if (!_exists(tokenId)) revert TokenNotExisting();
    
           
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ExtensionURL))
                : '';
        }
        
        function _baseURI() internal view virtual override returns (string memory) {
        return baseURL;
        }
        
        /// @dev return currentSupply of tokens
        ///@return current supply 
        function currentSupply() public view returns (uint256){
            return _tokenIdCounter.current();
        }
    
        /// @dev set new cost of tokenId in WEI
        /// @param _cost  new price in wei
        function setCostPrice(uint256 _cost) public onlyOwner{
            price = _cost;
        } 

        // ================ Internal Functions ===================
    
        // function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override{
        //     super._beforeTokenTransfer(from, to, tokenId);
        // }

          /// @dev internal function
        function multiMint(address _receiver,   uint _mintAmount) internal {
           for (uint256 i = 0; i < _mintAmount; i++){
                _tokenIdCounter.increment();               
                _safeMint(_receiver, _tokenIdCounter.current());
            }
        }    
           function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }
    
    /// @dev internal function to 
    /// @param from  user address where token belongs
    /// @param to  user address
    /// @param tokenId  number of tokenId
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
    /// @dev internal function to 
    /// @param from  user address where token belongs
    /// @param to  user address
    /// @param tokenId  number of tokenId
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }
    
    /// @dev internal function to 
    /// @param from  user address where token belongs
    /// @param to  user address
    /// @param tokenId  number of tokenId
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    } 
    }