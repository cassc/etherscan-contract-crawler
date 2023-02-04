// SPDX-License-Identifier: MIT
/*
 ________ __                                                         
/        /  |                                                        
$$$$$$$$/$$ |____    ______                                          
   $$ |  $$      \  /      \                                         
   $$ |  $$$$$$$  |/$$$$$$  |                                        
   $$ |  $$ |  $$ |$$    $$ |                                        
   $$ |  $$ |  $$ |$$$$$$$$/                                         
   $$ |  $$ |  $$ |$$       |                                        
   $$/   $$/   $$/  $$$$$$$/                                         
 __       __              __                                         
/  \     /  |            /  |                                        
$$  \   /$$ |  ______   _$$ |_    ______                             
$$$  \ /$$$ | /      \ / $$   |  /      \                            
$$$$  /$$$$ |/$$$$$$  |$$$$$$/   $$$$$$  |                           
$$ $$ $$/$$ |$$    $$ |  $$ | __ /    $$ |                           
$$ |$$$/ $$ |$$$$$$$$/   $$ |/  /$$$$$$$ |                           
$$ | $/  $$ |$$       |  $$  $$/$$    $$ |                           
$$/      $$/  $$$$$$$/    $$$$/  $$$$$$$/                            
 _______             __        __                                    
/       \           /  |      /  |                                   
$$$$$$$  |  ______  $$ |____  $$ |____    ______    ______   _______ 
$$ |__$$ | /      \ $$      \ $$      \  /      \  /      \ /       |
$$    $$< /$$$$$$  |$$$$$$$  |$$$$$$$  |/$$$$$$  |/$$$$$$  /$$$$$$$/ 
$$$$$$$  |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$    $$ |$$ |  $$/$$      \ 
$$ |  $$ |$$ \__$$ |$$ |__$$ |$$ |__$$ |$$$$$$$$/ $$ |      $$$$$$  |
$$ |  $$ |$$    $$/ $$    $$/ $$    $$/ $$       |$$ |     /     $$/ 
$$/   $$/  $$$$$$/  $$$$$$$/  $$$$$$$/   $$$$$$$/ $$/      $$$$$$$/   */
                                                                         
pragma solidity >=0.8.9 <0.9.0;


import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
/*
 ________ __                               
/        /  |                              
$$$$$$$$/$$ |____    ______                
   $$ |  $$      \  /      \               
   $$ |  $$$$$$$  |/$$$$$$  |              
   $$ |  $$ |  $$ |$$    $$ |              
   $$ |  $$ |  $$ |$$$$$$$$/               
   $$ |  $$ |  $$ |$$       | __    __     
   $$/   $$/   $$/  $$$$$$$/ /  |  /  |    
 __     __ ______   __    __ $$ | _$$ |_   
/  \   /  /      \ /  |  /  |$$ |/ $$   |  
$$  \ /$$/$$$$$$  |$$ |  $$ |$$ |$$$$$$/   
 $$  /$$/ /    $$ |$$ |  $$ |$$ |  $$ | __ 
  $$ $$/ /$$$$$$$ |$$ \__$$ |$$ |  $$ |/  |
   $$$/  $$    $$ |$$    $$/ $$ |  $$  $$/ 
    $/    $$$$$$$/  $$$$$$/  $$/    $$$$/  */
                                           
abstract contract Vault{
  function enterVault(address to, uint256 tokenId)public virtual returns (uint256);
}

//Vault error messages
error  CannotEnterUnopenedVault();
error  VaultOpeningIsClosed();
error  VaultNotOpenYet();

contract TheMetaRobbers3Vaults is ERC721AQueryable, ERC2981, Ownable, ReentrancyGuard, AccessControl{

  using Strings for uint256;
  using ECDSA for bytes32;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  //Vault Variables
  address private VaultContract;
  bool public canEnterVault;
  
 
  //variables for URI Strings
  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
 
  //variables for Cost and Mint Amounts
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  //variables for admin functions
  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
  address payable payments;
 constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  )ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  } 


  //modifier for compliance of mint amounts during sale of Vault
    modifier mintCompliance(uint256 _mintAmount) {
      require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
      require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
    }
  //modifier for compliance of price. assures the message sender has sufficient funds
    modifier mintPriceCompliance(uint256 _mintAmount) {
      require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
   }

 
          function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

   
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl, ERC2981)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    //Burns token Id for Vault and mints Rift Trip NFT from proxy contracts
      function enterVault(uint256 tokenId) public nonReentrant() returns (uint256) {
        if (!canEnterVault) {
            if (msg.sender != owner()) revert VaultOpeningIsClosed();
        }

        address to = ownerOf(tokenId);

        if (to != msg.sender) {
            if (msg.sender != owner()) revert CannotEnterUnopenedVault();
        }

       Vault factory = Vault(VaultContract);

        _burn(tokenId, true);

        uint256 VaultTokenId = factory.enterVault(to, tokenId);
        return VaultTokenId;
    }

    //sets the contract address for the proxy contract to be able to mint after manual reveal.
    function setVaultContract(address contractAddress) external onlyOwner  nonReentrant{
        VaultContract = contractAddress;
    }

    //reads the amount of Vault opened(burned)
    function VaultOpened(address addr) external view returns (uint256) {
        return _numberBurned(addr);
    }

  

    //Mint function for whitelisted wallets.  
    function whitelistVault(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  //public mint function
  function MintHeistList(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  //admin mint function(mints Vault for address)
  function AirdropVault(uint256 _mintAmount, address _receiver) public onlyOwner nonReentrant{
    _safeMint(_receiver, _mintAmount);
  }


  function _starttokenId() internal view virtual returns (uint256) {
    return 1;
  }

  //reads the location of the Vault uri
  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A) returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent Vault');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner nonReentrant{
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner nonReentrant {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner nonReentrant{
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner nonReentrant {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  //toggles Vault entrance on and off
   function toggleCanEnterVault() external onlyOwner nonReentrant{
        if (VaultContract == address(0)) revert VaultNotOpenYet();
        canEnterVault = !canEnterVault;
    }
  function setUriPrefix(string memory _uriPrefix) public onlyOwner nonReentrant{
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner nonReentrant{
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner nonReentrant{
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner nonReentrant{
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner nonReentrant{
    whitelistMintEnabled = _state;
  }
  function withdraw() public onlyOwner nonReentrant {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

}