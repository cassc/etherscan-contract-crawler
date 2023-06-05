// SPDX-License-Identifier: Unlicensed

//           _        _           _            _       _  _  _          _  _   _   
//         /' `\    /' `\       /' `\        /~_)     ' /' `' )    )   ' /' `/' `\ 
//       /'     ) /'     )    /'     )   ~-/'-~       /'    //   /'    /'  /'   ._)
//     /'       /'      /'  /' (___,/'   /'         /'    /'/  /'    /'   (____    
//   /'   _   /'      /'  /'     )     /'         /'    /' / /'    /'          )   
// /'    ' )/'      /'  /'      /'/~\,'   _     /'    /'  //'    /'          /'    
//(_____,/'(_____,/'(,/' (___,/' (,/'`\____)(,/(_,(,/'    (_,(,/(_, (_____,/'      
                                                                                    
import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Arrays.sol';

pragma solidity >=0.8.9 <0.9.0;

contract GOBLINIS is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  
  string public hiddenMetadataUri = "ipfs://QmXNZstmXd5vE4HDi2ouEv1UtCuJ5eoyM5xLrUswZszoTj/hidden.json";
  
  uint256 public Publicprice = .0999 ether;
  uint256 public WLprice = .0999 ether;
  
  uint256 public maxSupply = 1462;
  
  uint256 public PublicmaxMintAmountPerTx = 25;
  uint256 public WLmaxMintAmountPerTx = 25;
  
  bool public paused = false;
  
  bool public formiliaSaleON = false;
  bool public friendliesSaleON = false;
  bool public publicSaleON = false;
  
  bool public revealed = false;

// collection addresses #phase 1
  address public j48baforms = 0xc78337CCbb2D08492EC152E501491D3A76Cd5172;
  address public trinkets = 0x0B0f6BC78Ea9FB88dD58fDfe4C03F0c78721f649;
  address public sudoburger = 0xeF2e3Cf741d34732227De1dAe38cdD86939fE073;

  // collection addresses #phase 2
  address public bastardgans = 0x31385d3520bCED94f77AaE104b406994D8F2168C;
  address public tubbycats = 0xCa7cA7BcC765F77339bE2d648BA53ce9c8a262bD;
  address public miladymaker = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;
  address public metalmons = 0x17aBd4Cc1382397eC2B675f98621C3Ba809897DE;
  address public dropicall = 0x8b82D758a95c84Bc5476244f91e9AC6478d2a8B0;
  address public gradis = 0x2322B56ae00A53092e2688Ab038881A0c0Cf00a3;
  address public adworld = 0x62eb144FE92Ddc1B10bCAde03A0C09f6FBffBffb;


  constructor(
    string memory _uriPrefix
) ERC721A("GOBLINIS", "GBLN")  {
    setUriPrefix(_uriPrefix);
  }


  // wl - 1 mint 
  function Formilia(uint256 _mintAmount) public payable{
    require(!paused, 'The contract is paused!');
    require(formiliaSaleON, 'Formilia Presale is not open yet');
    require(_mintAmount > 0 && _mintAmount <= WLmaxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(msg.value >= WLprice * _mintAmount, 'Insufficient funds!');
  // holder check interface
    IERC721 Col1 = IERC721(j48baforms);
    IERC721 Col2 = IERC721(trinkets);
    IERC721 Col3 = IERC721(sudoburger);
    uint256 holderCol;
    if(Col1.balanceOf(msg.sender) >= 1) {
      holderCol = Col1.balanceOf(msg.sender);
    }
    else if(Col2.balanceOf(msg.sender) >= 1) {
      holderCol = Col2.balanceOf(msg.sender);
    }
    else{
      holderCol = Col3.balanceOf(msg.sender);
    }
    require(holderCol >= 1, "You don't hold required nfts" );
    _safeMint(_msgSender(), _mintAmount);
  }

  // wl - 2 mint 
  function Friendlies(uint256 _mintAmount) public payable{
    require(!paused, 'The contract is paused!');
    require(friendliesSaleON, 'Friendlies Presale is not open yet');
    require(_mintAmount > 0 && _mintAmount <= WLmaxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(msg.value >= WLprice * _mintAmount, 'Insufficient funds!');
    // holder check interface
    IERC721 Col1 = IERC721(j48baforms);
    IERC721 Col2 = IERC721(trinkets);
    IERC721 Col3 = IERC721(sudoburger);
    IERC721 Col4 = IERC721(bastardgans);
    IERC721 Col5 = IERC721(tubbycats);
    IERC721 Col6 = IERC721(miladymaker);
    IERC721 Col7 = IERC721(metalmons);
    IERC721 Col8 = IERC721(dropicall);
    IERC721 Col9 = IERC721(gradis);
    IERC721 Col10 = IERC721(adworld);
    uint256 holderCol;
    if(Col1.balanceOf(msg.sender) >= 1) {
      holderCol = Col1.balanceOf(msg.sender);
    }
    else if(Col2.balanceOf(msg.sender) >= 1) {
      holderCol = Col2.balanceOf(msg.sender);
    }
    else if(Col3.balanceOf(msg.sender) >= 1) {
      holderCol = Col3.balanceOf(msg.sender);
    }
    else if(Col4.balanceOf(msg.sender) >= 1) {
      holderCol = Col4.balanceOf(msg.sender);
    }
    else if(Col5.balanceOf(msg.sender) >= 1) {
      holderCol = Col5.balanceOf(msg.sender);
    }
    else if(Col6.balanceOf(msg.sender) >= 1) {
      holderCol = Col6.balanceOf(msg.sender);
    }
    else if(Col7.balanceOf(msg.sender) >= 1) {
      holderCol = Col7.balanceOf(msg.sender);
    }
    else if(Col8.balanceOf(msg.sender) >= 1) {
      holderCol = Col8.balanceOf(msg.sender);
    }
    else if(Col9.balanceOf(msg.sender) >= 1) {
      holderCol = Col9.balanceOf(msg.sender);
    }
    else{
      holderCol = Col10.balanceOf(msg.sender);
    }
    require(holderCol >= 1, "You don't hold required NFTS" );
    _safeMint(_msgSender(), _mintAmount);
  }
  

  // public mint
  function PublicMint(uint256 _mintAmount) public payable{
    require(!paused, 'The contract is paused!');
    require(!formiliaSaleON, 'Formilia Presale is going down, Please wait for public sale to open');
    require(!friendliesSaleON, 'Friendlies Presale is going down, Please wait for public sale to open');
    require(publicSaleON, 'Public Sale has not started');
    require(_mintAmount > 0 && _mintAmount <= PublicmaxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(msg.value >= Publicprice * _mintAmount, 'Insufficient funds!');

    _safeMint(_msgSender(), _mintAmount);
  }


  // Aidrop/ Ownermint
  function Airdrop(uint256 _mintAmount, address _address) public onlyOwner {
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

// WL price
  function setWLPrice(uint256 _WLPrice) public onlyOwner {
    WLprice = _WLPrice;
  }  

// PublicmaxMintAmountPerTx
  function setPublicmaxMintAmountPerTx(uint256 _PublicmaxMintAmountPerTx) public onlyOwner {
    PublicmaxMintAmountPerTx = _PublicmaxMintAmountPerTx;
  }

// WLmaxMintAmountPerTx
  function setWLmaxMintAmountPerTx(uint256 _WLmaxMintAmountPerTx) public onlyOwner {
    WLmaxMintAmountPerTx = _WLmaxMintAmountPerTx;
  }

// formiliaSale
  function setformiliaSaleON(bool _state) public onlyOwner {
    formiliaSaleON = _state;
  }

// friendliesSaleON
  function setfriendliesSaleON(bool _state) public onlyOwner {
    friendliesSaleON = _state;
  }

// PublicSaleON
  function setpublicSaleON(bool _state) public onlyOwner {
    publicSaleON = _state;
  }

// J48BAFORMS
  function setj48baforms(address _contractaddress) public onlyOwner {
    j48baforms = _contractaddress;
  }

// TRINKETS
  function settrinkets(address _contractaddress) public onlyOwner {
    trinkets = _contractaddress;
  }

// SUDO BURGER
  function setsudoburger(address _contractaddress) public onlyOwner {
    sudoburger = _contractaddress;
  }

// Bastard Gans
  function setbastardgans(address _contractaddress) public onlyOwner {
    bastardgans = _contractaddress;
  }

// Tubby Cats
  function settubbycats(address _contractaddress) public onlyOwner {
    tubbycats = _contractaddress;
  }

// miladymaker
  function setmiladymaker(address _contractaddress) public onlyOwner {
    miladymaker = _contractaddress;
  }

// MetalMons
  function setmetalmons(address _contractaddress) public onlyOwner {
    metalmons = _contractaddress;
  }

// dropicall
  function setdropicall(address _contractaddress) public onlyOwner {
    dropicall = _contractaddress;
  }

 // gradis
  function setgradis(address _contractaddress) public onlyOwner {
    gradis = _contractaddress;
  }

// adworld
  function setadworld(address _contractaddress) public onlyOwner {
    adworld = _contractaddress;
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