// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TheMinersComicPages contract
 * @dev Extends ERC721A Non-Fungible Token Standard basic implementation
 */
contract TheMinersComicPages is ERC721A, Ownable, ReentrancyGuard {
/*    
  ________            ___       __                 __                          ____  ____
 /_  __/ /_  ___     /   | ____/ /   _____  ____  / /___  __________  _____   / __ \/ __/
  / / / __ \/ _ \   / /| |/ __  / | / / _ \/ __ \/ __/ / / / ___/ _ \/ ___/  / / / / /_  
 / / / / / /  __/  / ___ / /_/ /| |/ /  __/ / / / /_/ /_/ / /  /  __(__  )  / /_/ / __/  
/_/ /_/ /_/\___/  /_/  |_\__,_/ |___/\___/_/ /_/\__/\__,_/_/   \___/____/   \____/_/                                                                                                                                                                                                                                                                                                    
    ████████ ██   ██ ███████     ███    ███ ██ ███    ██ ███████ ██████  ███████                                                           
       ██    ██   ██ ██          ████  ████ ██ ████   ██ ██      ██   ██ ██                                                                
       ██    ███████ █████       ██ ████ ██ ██ ██ ██  ██ █████   ██████  ███████                                                           
       ██    ██   ██ ██          ██  ██  ██ ██ ██  ██ ██ ██      ██   ██      ██                                                           
       ██    ██   ██ ███████     ██      ██ ██ ██   ████ ███████ ██   ██ ███████                                                                                                      
                                                                                
                              ,                     ,                            
                            @                         @                          
                        @@@                             @@&                      
                      @@                                   @@                    
                   @@@                                       @@@                 
                 @@             [email protected]@@@@@@@@@@@@@@@             &@@               
           @ @@@@           @@@@ @@@,            @@@@@           @@@@ @         
           @@@@@@@@@     @@@@&@@@                    @@@      @@@@@@@@@         
           @@&@@@@(@ @  @@@@@@@@                       &@@.  @ @ @@@@[email protected]@         
          @@      @@@@@@@@ @@@@                    @@.  @@ @@@@@      @@        
         @@          &@@  [email protected]@@                      @@@ %@@            @@       
        @.           @/ @ @@@@*          @           @@  @@             @@      
       @             @@@( @@@@@.                     @@ @@@               @     
      @              @@@ @@@@@@@@                  &@@ @@@@                @    
     @                @@@@@@@@@@@@@              @@  *@@@@@                 @   
                      @@@@,@@@@@@@@@@@@           @@@@@@@(                  *   
    @                     @@#@@@,@@@@@@@@@@@@@@@@@@@@@@@                     @  
                           @@#@@@@@@@@@@#@@@@@@@@@@#@,@                         
                             @@@@@ @@@@ @@@ @@@#@@@#@ @@                        
                      @@@@@    #@@ @@@@ @@@ @@@ @@# @@@@@@@@                    
                   @@@@@@@                               @@@@@@@                 
                    @@@                                     @@@                 
*/                                                                   
  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(bytes32 => bool) public claimed;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public whitelistMintEnabled = false;
  bool public paused = true;


  struct page {
    uint256 startIndex;
    uint256 endIndex;
    bool revealed;
    bool doubleDown; // If enabled, those who already minted the current page can mint a second time. 
  }

  uint256 public currentPage;
  mapping(uint256 => page) internal pages;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
    currentPage = 0;
    pages[currentPage].startIndex = _currentIndex;
    pages[currentPage].endIndex = _currentIndex;
  }

  modifier mintCompliance(address _sender) {
    require(_currentIndex - pages[currentPage].startIndex + 1 <= 490, "Comic pages are sold out!");
    require(!claimed[keccak256(abi.encodePacked(currentPage, pages[currentPage].doubleDown, _sender))], "Already minted this page!");
    _;
  }

  modifier mintComplianceAdmin(uint256 _mintAmount) {
    require(_currentIndex - pages[currentPage].startIndex + _mintAmount <= 490, "Comic pages are sold out!");
    _;
  }
  
  /**
   * Mint a comic book page for whitelisted mint
   */
  function whitelistMint(bytes32[] calldata _merkleProof) public mintCompliance(msg.sender) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");
    
    _safeMint(msg.sender,1);
    claimed[keccak256(abi.encodePacked(currentPage, pages[currentPage].doubleDown, msg.sender))] = true;
  }

  /**
   * Mint a comic book page available for public mint
   */
  function mint() public mintCompliance(msg.sender){
    require(!paused, "The contract is paused!");

    _safeMint(msg.sender, 1);
    claimed[keccak256(abi.encodePacked(currentPage, pages[currentPage].doubleDown, msg.sender))] = true;
  }

  /**
   * Admin - Airdrop a comic book page to a specified address
   */
  function mintForAddressAdmin(address _receiver,uint256 _mintAmount) public mintComplianceAdmin(_mintAmount) onlyOwner {
    _safeMint(_receiver,_mintAmount);
  }

  /**
   * Admin - Airdrop comic book pages to specified addresses
   */
  function mintForAddressesAdmin( address[] calldata _receivers, uint256[] calldata _mintAmounts) public onlyOwner {
    for (uint i=0; i<_receivers.length; i++) {
       require(_currentIndex - pages[currentPage].startIndex + _mintAmounts[i] <= 490, "Amount minted would exceed max supply!");
        _safeMint(_receivers[i], _mintAmounts[i]);
    }
  }

  /**
   * View all tokens that belong to a specified address
   */
  function walletOfOwner(address _owner) public view returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;
        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  /**
   * View a specified token's metadata link
   */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
  {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (pages[tokenToPage(_tokenId)].revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  /**
   * View all of a specified page's information
   */
  function getPageInfo(uint _pageId) public view returns (string memory){
    require(_pageId <= currentPage, "Page does not exist.");
    page memory pageInfo = pages[_pageId];
    if(pageInfo.endIndex == 0)
      pageInfo.endIndex = _currentIndex;
    string memory IsRevealed = pageInfo.revealed ? "Revealed" : "Hidden";
    string memory DoubledDown = pageInfo.doubleDown ? "Yes, Holders of this page can mint this page a second time" : "No, One mint of this page per Person";
    return string(abi.encodePacked("First Token: ", pageInfo.startIndex.toString(),
                                   " | Last Token: ", pageInfo.endIndex.toString(),
                                   " | Visibility: ", IsRevealed,
                                   " | Doubled Down: ", DoubledDown
                                   )
                  );
  }

  /**
   * View page number of a specified token
   */
  function tokenToPage(uint _tokenId) public view returns (uint256){
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    uint256 pageNumber;
    for(uint256 i=0; i<=currentPage; i++){
      if((_tokenId >= pages[i].startIndex && _tokenId <= pages[i].endIndex) || _tokenId >= pages[i].startIndex){
        pageNumber = i;
      }
    }
    return pageNumber;
  }

  /**
   * Admin - Set a specified page to be revealed
   */
  function setRevealed(bool _state, uint256 _pageId) public onlyOwner {
    pages[_pageId].revealed = _state;
  }

  /**
   * Admin - Set double down option for current page
   */
  function setDoubleDown(bool _state) public onlyOwner {
     pages[currentPage].doubleDown = _state;
  }

  /**
   * Admin - Set hidden reveal metadata
   */
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  /**
   * Admin - Set metadata link
   */
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  /**
   * Admin - Set metadata link suffix
   */
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }


  /**
   * Admin - Set current page for minting to be the next page
   */
  function setNextPageForSale() public onlyOwner {
    pages[currentPage].endIndex = _currentIndex - 1;
    currentPage = currentPage + 1;
    pages[currentPage].startIndex = _currentIndex;
  }

  /**
   * Admin - Start/Stop minting of the current page
   */
  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  /**
   * Admin - Start/Stop public minting of the current page
   */
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }
  /**
   * Admin - Set which addresses are allowed to mint
   */
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  /**
   * Admin - Withdraw any ETH accidentally sent to the contract
   */
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  /**
   * DM TRich.ETH on discord that you are standing right behind him
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  /**
   * Sets the first token to be number 1 instead of 0
   */
  function _startTokenId() internal override view virtual returns (uint256) {
    return 1;
  }
}