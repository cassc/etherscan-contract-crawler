// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/* 
                                               `--:::-.                         
                                           `/sdmmddddmmms:`                     
                                         -smmh+--------+hNm+`                   
                                  `..---sNmo..://++++//-.-yMd-                  
                           `.:+shdmddddmNo../+++++++++++/:`+Mm.                 
                       .:ohdmmdyo/::-----`:++++++/-...:+++: yMy                 
                    ./ymmdo/-...::////////+++++++:``/- :+++`:MN///:`            
          `...`` `-ymmy/-.-:/++.:+++++++++++++++++/:.  -++/ `+ddddNm/           
      ./shddddddhhNd+..:/++++++/.:+++++++++++++++++++:-`-/.`.  .:.-mMo          
    .sNNy+::--:/oy/.-/++++++++++/.+++++++++++++++++++++/.` :. `.od-.dMs`        
   :mNs..://////:-:/++++++++++++++++++++++++++++++++++++/. .:-::ymd:.hMy`       
  -NN:`:+++++++++++++++++++++++++++-:+++++++++++++++++++++- odh+mmmd:`hMh`      
  dMo :++++/:/+++++++++++++++++++++/.:+++++++++++++++++++++- ::-ohmmd/`yMd`     
 .MM.`+++/`.- :+++++++++++++++++++++/.:++++++++-``./++++++++``dh/:ymmm+ oMm.    
 -MM .+++- +o -++++++++++++++++++++++//++++++++`   -++++++++/ /dy..smmmo +MN-   
 `MM.`++++:.`.:++++++++++++++++++++++++/-++/:--------/+++++++.`dmo:o/omms`/MN:  
  dMo :++++++++++++++++++++++++++++++++/`.--/+++++++/-./+++++- smmy+.ymmmo :MM` 
  -NM/ -/++++++++++++++++++++/-.-/+/:--:/+++++//++++++/`/++++: :dmmo+dy+.-odMh  
   -dMh/-...`:+++++++++++++++`    --:/++++:-``:/.++++++--++++: `-hdy+.:omNdo-   
    `:ydmNNm`.+++++++++++++++/-``-/++++++:  YMH ++++++//++++- h:..:omNdo-`     
       ``.dMo /+++++++++++++++-./++++++++/.`    -+++/+++++++/ /MMmmNdo.`        
          -MN-`/+++++++++++++/-++++++++++++/::..+++:.++++++/`.mM+::.`           
           oMm.`/++++++++++++++++++++++++/++++/`::--/+++++:`-mMo                
            oMm:`:+++++++++++++++++++++++:------://+++++/-`+NN/                 
             /mNo../+++++++++++++++++++++++///++++++++/-.:hNh-                  
              .sNm/.-/+++++++++++++++++++++++++++++/:..+dNh:`                   
                -hNd/.-/+++++++++++++++++++++++//-.-:smmy-                      
                  :ymms:---:////++++++++////:-.-:ohmmh+.                        
                    .+hmmhs+:--------------:+ydmmdo:.                           
                       .:+shmmmmdddhhdddmmmmhs+:.                               
                             `.--::::::--.`          
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YMH is ERC721, Ownable{
  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  bytes32 private _merkleRoot;
  bytes32 private _merkleRootDoge;
  address private psa;

  uint public constant maxSupply = 10000;
  uint private constant presalePrice = 1 ether; 
  uint private constant startPriceDA = 1.8 ether; 
  uint private constant endPriceDA = 1.1 ether; 
  uint private constant reservedAmount = 50; 
  uint private constant maxMintsPerAddressPresale = 1;
  uint private constant maxMintsPerAddressSale = 10;
  uint public reservedMintedAlready;
  uint public dwc;

  uint public constant presaleStartDate = 1642885200; 
  uint public constant saleStartDate = 1642971600; 
  
  string private baseUri = "https://ymh.mypinata.cloud/ipfs/QmUKGx2maqiVxkBQMyYchCqxVXD4vLiystho4vp6wSdp4L/"; 
  string private baseExtension = ".json"; 
  
  mapping(address => uint) public mintedTokensByAddress;

  constructor() ERC721("YOUR MOMS HOUSE", "YMH") {} 

  modifier onlyEOA() {
    require(msg.sender == tx.origin, "Only EOA");
    _;
  }

  function calculateTokenPriceDA() public view returns(uint) {
    // 1 interval := 3h -> 10800s
    uint elapsedIntervalsDA = (block.timestamp - saleStartDate) / 10800; 
    if (elapsedIntervalsDA >= 7){
      return endPriceDA;
    }
    else {
      return startPriceDA - (0.1 ether * elapsedIntervalsDA);
    }
  }

  function isPresaleOpen() public view returns(bool) {
    if(block.timestamp >= presaleStartDate
    && block.timestamp <= saleStartDate){
      return true;
    }
    else{
      return false;
    }
  }

  function isSaleOpen() public view returns(bool) {
    if(block.timestamp >= saleStartDate 
    && block.timestamp <= saleStartDate + 1 days){ 
      return true;
    }
    else{
      return false;
    }
  }

  function mintSale(uint amount) external payable onlyEOA {
    require(isSaleOpen(), "Sale not open");
    require((amount > 0) && (amount <= maxMintsPerAddressSale), "Incorrect amount");
    require(totalSupply() + amount <= mintableSupply(), "Max Supply reached");
    require(mintedTokensByAddress[msg.sender] + amount <= maxMintsPerAddressSale, "Max per address");
    require(msg.value >= calculateTokenPriceDA() * amount , "Incorrect Price sent");
    mintedTokensByAddress[msg.sender] += amount;
    _mintToken(msg.sender, amount);
  }
  
  function mintReserved(address receiver, uint amount) external onlyOwner {
    require(totalSupply() + amount <= maxSupply, "Max Supply reached");
    require(reservedMintedAlready + amount <= reservedAmount, "Reserved Max reached");
    reservedMintedAlready += amount;
    _mintToken(receiver, amount);
  }

  function mintWhitelist(bytes32[] calldata proof) external payable onlyEOA {
    require(isPresaleOpen(), "Presale not open");
    require(mintedTokensByAddress[msg.sender] + 1 <= maxMintsPerAddressPresale, "Already minted");
    require(verifyWhitelist(proof, _merkleRoot), "Not whitelisted");
    require(totalSupply() + 1 <= mintableSupply(), "Max Supply reached");
    require(msg.value == presalePrice , "Incorrect price sent");
    mintedTokensByAddress[msg.sender] += 1;
    _mintToken(msg.sender, 1);
  }

  function _mintToken(address to, uint amount) private {
    uint id;
    for(uint i = 0; i < amount; i++){
      _tokenIds.increment();
      id = _tokenIds.current();
      _mint(to, id);
    }
  }

  function mintDogeWhitelist(bytes32[] calldata proof) external payable onlyEOA {
    require(isPresaleOpen(), "Presale not open");
    require(mintedTokensByAddress[msg.sender] + 1 <= maxMintsPerAddressPresale, "Already minted");
    require(verifyWhitelist(proof, _merkleRootDoge), "Not whitelisted");
    require(totalSupply() + 1 <= mintableSupply(), "Max Supply reached");
    require(msg.value == presalePrice, "Incorrect price sent");
    dwc++;
    mintedTokensByAddress[msg.sender] += 1;
    _mintToken(msg.sender, 1);
  }

  function mintableSupply() private view returns(uint) {
    return maxSupply - (reservedAmount - reservedMintedAlready);
  }

  function setBaseExtension(string memory newBaseExtension) external onlyOwner {
    baseExtension = newBaseExtension;
  }

  function setBaseUri(string memory newBaseUri) external onlyOwner {
    baseUri = newBaseUri;
  }

  function setDogeMerkleRoot(bytes32 root) external onlyOwner {
    _merkleRootDoge = root;
  }

  function setMerkleRoot(bytes32 root) external onlyOwner {
    _merkleRoot = root;
  }

  function setPSA(address newPSA) external onlyOwner {
    psa = newPSA;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory _tokenURI = "Token with that ID does not exist.";
    if (_exists(tokenId)){
      _tokenURI = string(abi.encodePacked(baseUri, tokenId.toString(), baseExtension));
    }
    return _tokenURI;
  }
  
  function totalSupply() public view returns(uint){
    return _tokenIds.current();
  }

  function verifyWhitelist(bytes32[] memory _proof, bytes32 _roothash)   
    private view 
    returns (bool) {
      bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
      return MerkleProof.verify(_proof, _roothash, _leaf);
  }

  function walletOfOwner(address _owner) external view returns (uint256[] memory) {
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

  function withdrawBalance() external onlyOwner {
    (bool s,) = payable(psa).call{value: address(this).balance}("");
    require(s, "tx failed");
  }

}