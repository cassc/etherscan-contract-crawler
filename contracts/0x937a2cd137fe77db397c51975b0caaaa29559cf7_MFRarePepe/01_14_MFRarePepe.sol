//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
*  ______     ______     ______     ______        ______   ______     ______   ______           
* /\  == \   /\  __ \   /\  == \   /\  ___\      /\  == \ /\  ___\   /\  == \ /\  ___\          
* \ \  __<   \ \  __ \  \ \  __<   \ \  __\      \ \  _-/ \ \  __\   \ \  _-/ \ \  __\          
*  \ \_\ \_\  \ \_\ \_\  \ \_\ \_\  \ \_____\     \ \_\    \ \_____\  \ \_\    \ \_____\        
*  _\/_/ /_/   \/_/\/_/   \/_/_/_/  _\/_____/   ___\/_/  __ \/_____/___\/_/    _\/_____/____    
* /\ "-./  \   /\  __ \   /\__  _\ /\__  _\    /\  ___\ /\ \/\ \   /\  == \   /\ \   /\  ___\   
* \ \ \-./\ \  \ \  __ \  \/_/\ \/ \/_/\ \/    \ \  __\ \ \ \_\ \  \ \  __<   \ \ \  \ \  __\   
*  \ \_\ \ \_\  \ \_\ \_\    \ \_\    \ \_\     \ \_\    \ \_____\  \ \_\ \_\  \ \_\  \ \_____\ 
*   \/_/  \/_/   \/_/\/_/     \/_/     \/_/      \/_/     \/_____/   \/_/ /_/   \/_/   \/_____/ 
*                                                                                               
* "Rare Pepe" by Matt Furie is a collection of 100 collectible cards, 
* plus a few ultra-rare drops for a total collection size of 103. Each card 
* bears a unique, hand-crafted animation depicting visions of Matt's 
* iconic character "Pepe the Frog."
* 
* This collection explores Pepe's infinite incarnations while paying homage
* to the seminal "Rare Pepe" project that planted a seed on the Bitcoin 
* sidechain Counterparty that has blossomed into the wild world of NFTs 
* that we know today.
* 
* This project is brought to you with love by Matt Furie and co. 
* in association with Chain/Saw and PEGZDAO.
*
*/

// Rinkeby: 0x943Ef5eB5c4aF95a0384c0c9C301DD23329cd2CD
// Mainnet: 0x937a2cd137FE77dB397c51975b0CaAaa29559CF7

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract MFRarePepe is ERC721Enumerable, ERC721URIStorage, Ownable {  
  uint8 public maxTokens = 103;
  string public _contractURI;  
  address public immutable proxyRegistryAddress;
  mapping(uint256 => bool) public frozenMetadataByTokenId;
  mapping(address => bool) public minters;

  event PermanentURI(string _value, uint256 indexed _id);
  
  constructor(address _proxyRegistryAddress) 
    ERC721("RarePepe by Matt Furie", "MFRP") 
  {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  modifier onlyMinter() {
    require(
      msg.sender == owner() || minters[msg.sender] == true,
      "MFRarePepe#mint: Caller is not not authorized minter"
    );
    _;
  }

  /**
   * @dev Override for OpenSea proxy accounts
   */
  function isApprovedForAll(address owner, address operator) 
    public 
    view 
    override 
    returns (bool) 
  { 
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

  /**
  * @dev OpenSea specific contract metadata
  */
  function contractURI() 
    public 
    view 
    returns (string memory) 
  {
    return _contractURI;
  }

  function setContractURI(string memory newContractURI)
    public
    onlyMinter
  {
    _contractURI = newContractURI;
  }

  function _baseURI() 
    internal 
    view 
    virtual 
    override 
    returns (string memory) 
  {
    return "ipfs://";
  }

  function mint(address to, uint256 tokenId, string memory _tokenURI) 
    external 
    virtual 
    onlyMinter 
  {
    require(
      tokenId <= maxTokens,
      "MFRarePepe#mint: All tokens have been minted. It's over."
    );
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, _tokenURI);    
  }

  /**
  * @dev TokenURI remains modifiable until frozen
  */
  function setTokenURI(uint256 tokenId, string memory _tokenURI)
    external
    onlyMinter
  {
    require(
      frozenMetadataByTokenId[tokenId] == false, 
      "MFRarePepe#setTokenURI: Token URI is frozen."
    );
    _setTokenURI(tokenId, _tokenURI);    
  }

  /**
  * @dev Irrevocable action that freezes token metadata to it's current value in storage
  */
  function freezeMetadata(uint256 tokenId)
    external
    onlyMinter
  {
    require(
      _exists(tokenId), 
      "MFRarePepe#freezeMetadata: Cannot freeze nonexistent token."
    );
    require(
      frozenMetadataByTokenId[tokenId] == false,
       "MFRarePepe#freezeMetadata: Token URI is already frozen."
    );
    
    frozenMetadataByTokenId[tokenId] = true;
    string memory _tokenURI = super.tokenURI(tokenId);
    emit PermanentURI(_tokenURI, tokenId);
  }

  function addMinter(address _minter) 
    external
    onlyOwner
  {
    minters[_minter] = true;
  }

  function removeMinter(address _minter) 
    external
    onlyOwner
  {
    delete minters[_minter];
  }

  /**
    * @dev See {IERC721Metadata-tokenURI}.
  */
  function tokenURI(uint256 tokenId)
      public
      view
      override(ERC721, ERC721URIStorage)
      returns (string memory)
  {
      return super.tokenURI(tokenId);
  }

  /**
    * @dev See {IERC165-supportsInterface}.
  */
  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }
  
  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }
}