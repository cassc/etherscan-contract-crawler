// SPDX-License-Identifier: MIT

/*

     _ __    .=-.-.         ,-.--,   ,----.                                 _,.---._       _,.---._     
  .-`.' ,`. /==/_ /.--.-.  /=/, .',-.--` , \   _.-.             ,--,----. ,-.' , -  `.   ,-.' , -  `.   
 /==/, -   \==|, | \==\ -\/=/- / |==|-  _.-` .-,.'|            /==/` - .//==/_,  ,  - \ /==/_,  ,  - \  
|==| _ .=. |==|  |  \==\ `-' ,/  |==|   `.-.|==|, |            `--`=/. /|==|   .=.     |==|   .=.     | 
|==| , '=',|==|- |   |==|,  - | /==/_ ,    /|==|- |             /==/- / |==|_ : ;=:  - |==|_ : ;=:  - | 
|==|-  '..'|==| ,|  /==/   ,   \|==|    .-' |==|, |            /==/- /-.|==| , '='     |==| , '='     | 
|==|,  |   |==|- | /==/, .--, - \==|_  ,`-._|==|- `-._        /==/, `--`\\==\ -    ,_ / \==\ -    ,_ /  
/==/ - |   /==/. / \==\- \/=/ , /==/ ,     //==/ - , ,/       \==\-  -, | '.='. -   .'   '.='. -   .'   
`--`---'   `--`-`   `--`-'  `--``--`-----`` `--`-----'         `--`.-.--`   `--`--''       `--`--''     

*/


import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'erc721a/contracts/ERC721A.sol';


pragma solidity >=0.8.13 <0.9.0;

contract PixelZoo is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

// ================== Variables Start =======================
  
  bytes32 public merkleRoot;
  
  string public uri;
  string public uriSuffix = ".json";
  string public hiddenMetadataUri = "ipfs://CID/filename.json";
  uint256 public price = 0 ether;
  uint256 public supplyLimit = 2222;
  uint256 public maxMintAmountPerTx = 2;
  uint256 public wlmaxMintAmountPerTx = 2;
  uint256 public maxLimitPerWallet = 20;
  uint256 public wlmaxLimitPerWallet = 10;

  bool public whitelistSale = false;
  bool public publicSale = false;

  bool public revealed = false;

// ================== Variables End =======================  

// ================== Constructor Start =======================

  constructor(
    string memory _uri
  ) ERC721A("PixelZoo", "PXLZOO")  {
    seturi(_uri);
  }

// ================== Constructor End =======================

// ================== Mint Functions Start =======================

  function WlMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {

    require(whitelistSale, 'The WlSale is paused!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');


    require(_mintAmount > 0 && _mintAmount <= wlmaxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(balanceOf(msg.sender) + _mintAmount <= wlmaxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(msg.value >= price * _mintAmount, 'Insufficient funds!');
     
     _safeMint(_msgSender(), _mintAmount);
  }

  function PublicMint(uint256 _mintAmount) public payable {
    
    require(publicSale, 'The PublicSale is paused!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(balanceOf(msg.sender) + _mintAmount <= maxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(msg.value >= price * _mintAmount, 'Insufficient funds!');
     
     _safeMint(_msgSender(), _mintAmount);
  }  

  function Airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

// ================== Mint Functions End =======================  

// ================== Set Functions Start =======================

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setpublicSale(bool _publicSale) public onlyOwner {
    publicSale = _publicSale;
  }

  function setwlSale(bool _whitelistSale) public onlyOwner {
    whitelistSale = _whitelistSale;
  }

  function setwlMerkleRootHash(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setwlmaxMintAmountPerTx(uint256 _wlmaxMintAmountPerTx) public onlyOwner {
    wlmaxMintAmountPerTx = _wlmaxMintAmountPerTx;
  }

  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
    maxLimitPerWallet = _maxLimitPerWallet;
  }

  function setwlmaxLimitPerWallet(uint256 _wlmaxLimitPerWallet) public onlyOwner {
    wlmaxLimitPerWallet = _wlmaxLimitPerWallet;
  }  

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
    supplyLimit = _supplyLimit;
  }

// ================== Set Functions End =======================

// ================== Withdraw Function Start =======================
  
  function withdraw() public onlyOwner nonReentrant {
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