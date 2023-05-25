// SPDX-License-Identifier: Unlicensed


//     _____ __                 __      
//    / ___// /_________  ___  / /______
//    \__ \/ __/ ___/ _ \/ _ \/ __/ ___/
//   ___/ / /_/ /  /  __/  __/ /_(__  ) 
//  /____/\__/_/_  \___/\___/\__/____/  
//    ____  / __/                       
//   / __ \/ /_                         
//  / /_/ / __/                         
//  \____/_/____ __          __         
//     /  |/  (_) /___ _____/ /_  __    
//    / /|_/ / / / __ `/ __  / / / /    
//   / /  / / / / /_/ / /_/ / /_/ /     
//  /_/  /_/_/_/\__,_/\__,_/\__, /      
//                         /____/       


import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Arrays.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'erc721a/contracts/ERC721A.sol';


pragma solidity >=0.8.13 <0.9.0;

contract StreetsOfMilady is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

// ================== Variables Start =======================
  
  // merkletree root hash - p.s set it after deploy from scan
  bytes32 public merkleRoot;
  
  // reveal uri - p.s set it in contructor (if sniper proof, else put some dummy text and set the actual revealed uri just before reveal)
  string public uri;
  string public uriSuffix = ".json";

  // hidden uri - replace it with yours
  string public hiddenMetadataUri = "ipfs://CID/filename.json";

  // prices - replace it with yours
  uint256 public price = 0.033 ether;

  // supply - replace it with yours
  uint256 public supplyLimit = 2121;
  uint256 public freemintSupplyLimit = 500;

  // max per tx - replace it with yours - public
  uint256 public maxMintAmountPerTx = 999;

  // max per wallet - replace it with yours - public
  uint256 public maxLimitPerWallet = 999;

  // enabled
  bool public publicSale = true;
  bool public freeMintSale = true;

  // claim mapping and free mint claim count
  mapping(address => bool) public claimed;
  uint256 public freeMintsCount = 0;


  // reveal
  bool public revealed = true;

// ================== Variables End =======================  

// ================== Constructor Start =======================

  // Token NAME and SYMBOL - Replace it with yours
  constructor(
    string memory _uri,
    bytes32 _merklerootHash
  ) ERC721A("Streets of Milady", "STREETS")  {
    uri = _uri;
    merkleRoot = _merklerootHash;
    
  }

// ================== Constructor End =======================

// ================== Mint Functions Start =======================


  function FreeMint(bytes32[] calldata _merkleProof) public payable {

    // Verify freemint requirements
    require(freeMintSale, 'The freeMint is paused!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');


    // Normal requirements 
    require(totalSupply() + 1 <= supplyLimit, 'Max supply exceeded!');
    require(msg.value >= 0 * 1, 'Insufficient funds!');
    require(!claimed[_msgSender()], 'Address already claimed!');
    require(freeMintsCount <=freemintSupplyLimit, 'Free Mint Supply Minted Out');

    claimed[_msgSender()] = true;
    freeMintsCount += 1;
     
    // Mint
     _safeMint(_msgSender(), 1);
  }

  function PublicMint(uint256 _mintAmount) public payable {
    
    // Normal requirements 
    require(publicSale, 'The PublicSale is paused!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(balanceOf(msg.sender) + _mintAmount <= maxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(msg.value >= price * _mintAmount, 'Insufficient funds!');
     
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
  function setpublicSale(bool _publicSale) public onlyOwner {
    publicSale = _publicSale;
  }

  function setfreeMintSale(bool _freeMintSale) public onlyOwner {
    freeMintSale = _freeMintSale;
  }

  function openAllSales() public onlyOwner {
    publicSale = true;
    freeMintSale = true;
  }

  function closeAllSales() public onlyOwner {
    publicSale = false;
    freeMintSale = false;
  } 


// hash set
  function setMerkleRootHash(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

// max per tx
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }


// pax per wallet
  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
    maxLimitPerWallet = _maxLimitPerWallet;
  }


// price
  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
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



// ================== Read Functions End =======================  

}

//freeMintSale