// SPDX-License-Identifier: Unlicensed
                                                                                                                                       
//                                 ,--.                                                ,-.----.                                    ,--. 
// .--.--.      ,---,          ,--/  /|              ,-.----.      ,---,               \    /  \     ,---,       ,-.----.      ,--/  /| 
// /  /    '.   '  .' \      ,---,': / '         ,--, \    /  \    '  .' \              |   :    \   '  .' \      \    /  \  ,---,': / ' 
//|  :  /`. /  /  ;    '.    :   : '/ /        ,'_ /| ;   :    \  /  ;    '.            |   |  .\ : /  ;    '.    ;   :    \ :   : '/ /  
//;  |  |--`  :  :       \   |   '   ,    .--. |  | : |   | .\ : :  :       \           .   :  |: |:  :       \   |   | .\ : |   '   ,   
//|  :  ;_    :  |   /\   \  '   |  /   ,'_ /| :  . | .   : |: | :  |   /\   \          |   |   \ ::  |   /\   \  .   : |: | '   |  /    
// \  \    `. |  :  ' ;.   : |   ;  ;   |  ' | |  . . |   |  \ : |  :  ' ;.   :         |   : .   /|  :  ' ;.   : |   |  \ : |   ;  ;    
//  `----.   \|  |  ;/  \   \:   '   \  |  | ' |  | | |   : .  / |  |  ;/  \   \        ;   | |`-' |  |  ;/  \   \|   : .  / :   '   \   
//  __ \  \  |'  :  | \  \ ,'|   |    ' :  | | :  ' ; ;   | |  \ '  :  | \  \ ,'        |   | ;    '  :  | \  \ ,';   | |  \ |   |    '  
// /  /`--'  /|  |  '  '--'  '   : |.  \|  ; ' |  | ' |   | ;\  \|  |  '  '--'          :   ' |    |  |  '  '--'  |   | ;\  \'   : |.  \ 
//'--'.     / |  :  :        |   | '_\.':  | : ;  ; | :   ' | \.'|  :  :                :   : :    |  :  :        :   ' | \.'|   | '_\.' 
//  `--'---'  |  | ,'        '   : |    '  :  `--'   \:   : :-'  |  | ,'                |   | :    |  | ,'        :   : :-'  '   : |     
//            `--''          ;   |,'    :  ,      .-./|   |.'    `--''                  `---'.|    `--''          |   |.'    ;   |,'     
//                           '---'       `--`----'    `---'                               `---`                   `---'      '---'       
                                                                                                                                       

                                                                                    
import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Arrays.sol';

pragma solidity >=0.8.9 <0.9.0;

contract SakuraPark is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  
  string public hiddenMetadataUri = "ipfs://QmcXsQzFhkj1ymEwfpj48SbppfTVforDmFyTPm3jTE4TC7/hidden.json";
  
  uint256 public Publicprice = .042 ether;
  
  uint256 public maxSupply = 2669;
  
  uint256 public PublicmaxMintAmountPerTx = 25;
  
  bool public paused = false;
  bool public publicSaleON = true;

  bool public revealed = false;

  constructor(
    string memory _uriPrefix
) ERC721A("Sakura Park", "SKRA")  {
    setUriPrefix(_uriPrefix);
  }


  
 // public mint
  function PublicMint(uint256 _mintAmount) public payable{
    require(!paused, 'The contract is paused!');
    require(publicSaleON, 'Public Sale has not started');
    require(_mintAmount > 0 && _mintAmount <= PublicmaxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(msg.value >= Publicprice * _mintAmount, 'Insufficient funds!');
    _safeMint(_msgSender(), _mintAmount);
  }

  // Aidrop/ Ownermint
  function airdrop(uint256 _mintAmount, address _address) public onlyOwner {
      require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_address, _mintAmount);
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
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

// PublicSaleON
  function setpublicSaleON(bool _state) public onlyOwner {
    publicSaleON = _state;
  }

//reveal
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

// hidden uri
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

// actual uri
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

// uri suffix
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

// pause
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

// supply
  function setmaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

// public price
  function setPublicPrice(uint256 _PublicPrice) public onlyOwner {
    Publicprice = _PublicPrice;
  }

// PublicmaxMintAmountPerTx
  function setPublicmaxMintAmountPerTx(uint256 _PublicmaxMintAmountPerTx) public onlyOwner {
    PublicmaxMintAmountPerTx = _PublicmaxMintAmountPerTx;
  }

// withdraw
  function withdraw() public onlyOwner nonReentrant {
    //owner withdraw
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
  

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}