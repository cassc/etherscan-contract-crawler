// SPDX-License-Identifier: MIT


        //   __         ______     __  __     __   __     ______     __  __     __     ______   __    
        //  /\ \       /\  __ \   /\ \/\ \   /\ "-.\ \   /\  ___\   /\ \_\ \   /\ \   /\  ___\ /\ \   
        //  \ \ \____  \ \  __ \  \ \ \_\ \  \ \ \-.  \  \ \ \____  \ \  __ \  \ \ \  \ \  __\ \ \ \  
        //   \ \_____\  \ \_\ \_\  \ \_____\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \_\  \ \_\    \ \_\ 
        //    \/_____/   \/_/\/_/   \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/   \/_/   \/_/     \/_/ 

        pragma solidity ^0.8.10;

        import "@openzeppelin/contracts/access/Ownable.sol";
        import "erc721a/contracts/ERC721A.sol";
        import "@openzeppelin/contracts/utils/Strings.sol";
        import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
        import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

        contract DegenGhouls is ERC721A, Ownable, ReentrancyGuard  , DefaultOperatorFilterer{
            using Strings for uint256;
            uint256 public _maxSupply = 2000;
            uint256 public maxMintAmountPerWallet = 5;
            uint256 public maxMintAmountPerTx = 5;
            string baseURL = "";
            string ExtensionURL = ".json";
            uint256 _initalPrice = 0 ether;
            uint256 public costOfNFT = 0.0069 ether;
            uint256 public numberOfFreeNFTs = 1;
            
            string HiddenURL;
            bool revealed = false;
            bool paused = true;
            
            error ContractPaused();
            error MaxMintWalletExceeded();
            error MaxSupply();
            error InvalidMintAmount();
            error InsufficientFund();
            error NoSmartContract();
            error TokenNotExisting();

        constructor(string memory _initBaseURI) ERC721A("Degen Ghouls", "DG") {
            baseURL = _initBaseURI;
        }

        // ================== Mint Function =======================

        modifier mintCompliance(uint256 _mintAmount) {
            if (msg.sender != tx.origin) revert NoSmartContract();
            if (totalSupply()  + _mintAmount > _maxSupply) revert MaxSupply();
            if (_mintAmount > maxMintAmountPerTx) revert InvalidMintAmount();
            if(paused) revert ContractPaused();
            _;
        }

        modifier mintPriceCompliance(uint256 _mintAmount) {
            if(balanceOf(msg.sender) + _mintAmount > maxMintAmountPerWallet) revert MaxMintWalletExceeded();
            if (_mintAmount < 0 || _mintAmount > maxMintAmountPerWallet) revert InvalidMintAmount();
              if (msg.value < checkCost(_mintAmount)) revert InsufficientFund();
            _;
        }
        

        function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount){
          _safeMint(msg.sender, _mintAmount);
          
          }

        function checkCost(uint256 _mintAmount) public view returns (uint256) {
          uint256 totalMints = _mintAmount + balanceOf(msg.sender);
          if ((totalMints <= numberOfFreeNFTs) ) {
          return _initalPrice;
          } else if ((balanceOf(msg.sender) == 0) && (totalMints > numberOfFreeNFTs) ) { 
          uint256 total = costOfNFT * (_mintAmount - numberOfFreeNFTs);
          return total;
          } 
          else {
          uint256 total2 = costOfNFT * _mintAmount;
          return total2;
            }
        }
        

        function airdrop(address[] memory accounts, uint256 amount)public onlyOwner mintCompliance(amount) {
          for(uint256 i = 0; i < accounts.length; i++){
          _safeMint(accounts[i], amount);
          }
        }

        // =================== Orange Functions (Owner Only) ===============

        function pause() public onlyOwner {
          paused = !paused;
        }

        

        function setbaseURL(string memory uri) public onlyOwner{
          baseURL = uri;
        }

        function setExtensionURL(string memory uri) public onlyOwner{
          ExtensionURL = uri;
        }

        function setCostPrice(uint256 _cost) public onlyOwner{
          costOfNFT = _cost;
        } 

        function setSupply(uint256 supply) public onlyOwner{
          _maxSupply = supply;
        }

        function setMaxMintAmountPerTx(uint256 perTx) public onlyOwner{
          maxMintAmountPerTx = perTx;
        }

        function setMaxMintAmountPerWallet(uint256 perWallet) public onlyOwner{
          maxMintAmountPerWallet = perWallet;
        }  
        
        function setnumberOfFreeNFTs(uint256 perWallet) public onlyOwner{
          numberOfFreeNFTs = perWallet;
        }            

        // ================================ Withdraw Function ====================

        function withdraw() public onlyOwner nonReentrant{
          

          

        (bool owner, ) = payable(owner()).call{value: address(this).balance}('');
        require(owner);
        }
        // =================== Blue Functions (View Only) ====================

        function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
          if (!_exists(tokenId)) revert TokenNotExisting();   

        

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ExtensionURL))
        : '';
        }
        
        function _startTokenId() internal view virtual override returns (uint256) {
          return 1;
        }

        function _baseURI() internal view virtual override returns (string memory) {
          return baseURL;
        }

        
            function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
            super.transferFrom(from, to, tokenId);
            }

            function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
            super.safeTransferFrom(from, to, tokenId);
            }

            function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
            public 
            override
            onlyAllowedOperator(from)
            {
            super.safeTransferFrom(from, to, tokenId, data);
            } 

      }