// SPDX-License-Identifier: Unlicensed
// Developer - ReservedSnow (https://linktr.ee/reservedsnow)

/*
___.           __________                                            .____________                     
\_ |__ ___.__. \______   \ ____   ______ ______________  __ ____   __| _/   _____/ ____   ______  _  __
 | __ <   |  |  |       _// __ \ /  ___// __ \_  __ \  \/ // __ \ / __ |\_____  \ /    \ /  _ \ \/ \/ /
 | \_\ \___  |  |    |   \  ___/ \___ \\  ___/|  | \/\   /\  ___// /_/ |/        \   |  (  <_> )     / 
 |___  / ____|  |____|_  /\___  >____  >\___  >__|    \_/  \___  >____ /_______  /___|  /\____/ \/\_/  
     \/\/              \/     \/     \/     \/                 \/     \/       \/     \/               
*/

/**
    !Disclaimer!
    please review this code on your own before using any of
    the following code for production.
    ReservedSnow will not be liable in any way if for the use 
    of the code. That being said, the code has been tested 
    to the best of the developers' knowledge to work as intended.
    If you find any problems please let the dev know in order to improve
    the contract and fix vulnerabilities if there is one.
    YOU ARE NOT ALLOWED TO SELL IT
*/

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'erc721a/contracts/ERC721A.sol';


pragma solidity >=0.8.15 <0.9.0;

contract m00ts is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

// ================== Variables Start =======================
  
  bytes32 public merkleRoot;
  string public uri;
  string public uriSuffix = ".json";
  string public hiddenMetadataUri = "ipfs://JSON-CID/hidden.json";
  uint256 public price = 0.005 ether;
  uint256 public wlprice = 0.005 ether;
  uint256 public supplyLimit = 5555;
  uint256 public maxLimitPerWallet = 20;
  uint256 public wlmaxLimitPerWallet = 20;
  uint256 public freemaxLimitPerWallet = 1;
  uint256 public freewlmaxLimitPerWallet = 1; 
  bool public whitelistSale = false;
  bool public publicSale = false;
  bool public revealed = true;
  mapping(address => uint256) public freewlMintCount;
  mapping(address => uint256) public wlMintCount;
  mapping(address => uint256) public freepublicMintCount;
  mapping(address => uint256) public publicMintCount;  

// ================== Variables End =======================  

// ================== Constructor Start =======================

  constructor(
    string memory _uri
  ) ERC721A("m00ts", "m00t") payable {
    seturi(_uri);
  }

// ================== Constructor End =======================

// ================== Mint Functions Start =======================


  function whitelistMint(uint256 _mintAmount , bytes32[] calldata _merkleProof) public payable {
    // Verify wl requirements
    require(whitelistSale, 'The WlSale is paused!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    // free mint verify
    uint256 freelimitavail = freewlmaxLimitPerWallet - freewlMintCount[msg.sender];
    if(freelimitavail > 0) {
      if(_mintAmount> freelimitavail){
       require(msg.value >= wlprice * (_mintAmount - freelimitavail), 'Insufficient funds!');
      }  
      require(msg.value >= 0 * _mintAmount, 'Insufficient funds!');
      require(_mintAmount+ wlMintCount[msg.sender] <= wlmaxLimitPerWallet, 'Max free mint per wallet exceeded!');
      freewlMintCount[msg.sender] += _mintAmount - (_mintAmount - freelimitavail);
      wlMintCount[msg.sender] += _mintAmount;
    }
    else{
      require(msg.value >= wlprice * _mintAmount, 'Insufficient funds!');
      require(_mintAmount + wlMintCount[msg.sender] <= wlmaxLimitPerWallet, 'Max mint per wallet exceeded!');
      wlMintCount[msg.sender] += _mintAmount;
    }

    // Normal requirements 
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
     
    // Mint
     _safeMint(_msgSender(), _mintAmount);
  }

  function PublicMint(uint256 _mintAmount) public payable {
    
    // Normal requirements 
    require(publicSale, 'The PublicSale is paused!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');

    // free mint verify
    uint256 freelimit = freemaxLimitPerWallet - freepublicMintCount[msg.sender];
    if(freelimit > 0) {
      if(_mintAmount> freelimit){
       require(msg.value >= price * (_mintAmount - freelimit), 'Insufficient funds!');
      }         
      require(msg.value >= 0 * _mintAmount, 'Insufficient funds!');
      require(_mintAmount+ publicMintCount[msg.sender] <= maxLimitPerWallet, 'Max free mint per wallet exceeded!');
      freepublicMintCount[msg.sender] += _mintAmount - (_mintAmount - freelimit);
      publicMintCount[msg.sender] += _mintAmount;
    }
    else{
      require(msg.value >= price * _mintAmount, 'Insufficient funds!');
      require(_mintAmount + publicMintCount[msg.sender] <= maxLimitPerWallet, 'Max mint per wallet exceeded!');
      publicMintCount[msg.sender] += _mintAmount;
    } 

     
    // Mint
     _safeMint(_msgSender(), _mintAmount);
  }  

  function Airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

// ================== Mint Functions End =======================  

// ================== Set Functions Start =======================

// reveal
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

// uri
  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

// sales toggle
  function setpublicSale() public onlyOwner {
    publicSale = !publicSale;
  }

  function setwlSale() public onlyOwner {
    whitelistSale = !whitelistSale;
  }


// hash set
  function setwlMerkleRootHash(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }


// pax per wallet
  function setmaxLimitPerWallet(uint256 _pub , uint256 _pubfree, uint256 _wlfree , uint256 _wl) public onlyOwner {
  maxLimitPerWallet = _pub;
  wlmaxLimitPerWallet = _wl;
  freemaxLimitPerWallet = _pubfree;
  freewlmaxLimitPerWallet = _wlfree;
  }

// price
  function setPrice(uint256 _price, uint256 _wlprice) public onlyOwner {
    price = _price;
    wlprice = _wlprice;    
  }

// supply limit
  function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
    supplyLimit = _supplyLimit;
  }

// ================== Set Functions End =======================

// ================== Withdraw Function Start =======================
  
  function withdraw() public onlyOwner nonReentrant {
    //owner withdraw
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

// ================== Withdraw Function End=======================  

// ================== Read Functions Start =======================
  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
        uint256[] memory a = new uint256[](balanceOf(owner)); 
        uint256 end = _nextTokenId();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        for (uint256 i; i < end; i++) {
            TokenOwnership memory ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                a[tokenIdsIdx++] = i;
            }
        }
        return a;    
    }
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

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

// This Contract Has been developed / made by ReservedSnow (https://linktr.ee/reservedsnow)  

// ================== Read Functions End =======================  

}