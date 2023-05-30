//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0; // tells the solidity version to the complier

// get the OpenZeppelin Contracts, we will use to creat our own
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract TacoGatosNFT is ERC721Enumerable, Ownable  {
  using Strings for uint256;
  using SafeMath for uint256;
  using ECDSA for bytes32;

  //NFT params
  string public baseURI;
  string public defaultURI;
  string public mycontractURI;
  bool public finalizeBaseUri = false;

  //Mint Stages:
  //Stage 0: Mint/Sale NOT Live
  //Stage 1: Mint Pass (Free Mint)
  //Stage 2: Private Mint (Pre-Sale)
  //Stage 3: Private Mint (Pre-Sale) Clearance
  //Stage 4: external Mint (Sale)
  //Stage 5: Mint Closed
  
  uint8 public stage = 0;
  
  uint256 public mintPassSupply = 300;
  uint256 public mintPassMax = 1;
  mapping(address => uint8) public mintPassCount;

  uint256 public presalePrice = 0.04 ether;
  uint256 public presaleSupply = 5000;
  uint256 public presaleMintMax = 3;
  mapping(address => uint8) public presaleMintCount;

  //pre-sale-clearance (stage=3)
  uint256 public clearanceMintMax = 10; 
  mapping(address => uint8) public presaleClearanceMintCount;

  //external sale (stage=4)
  uint256 public salePrice = 0.05 ether;
  uint256 public saleMintPerTransactionMax = 20;
  uint256 public totalSaleSupply = 10000;  

  //others
  bool public isSalePaused = false;

  //royalty
  address public royaltyAddr = 0x503e781c619ce0dcaD1B76Cd92f6D054d05FEe5c;
  uint256 public royaltyBasis = 500;

  address private _signerAddress = 0x3eE985d69f541dB0f5aaA05cd3542005B68D3C6C;
  address private _vaultAddress = 0x503e781c619ce0dcaD1B76Cd92f6D054d05FEe5c;

  constructor() ERC721("Taco Gatos", "TG") { 
    setBaseURI("https://api.tacogatosnft.com/token/");
    defaultURI = "https://api.tacogatosnft.com/token/0";
    mycontractURI = "https://api.tacogatosnft.com/contract/";
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mintStage1(bytes memory signature, uint8 _mintAmount) external payable {
    uint256 supply = totalSupply();
    bytes memory message = abi.encodePacked(msg.sender);
    bytes32 messagehash =  keccak256(message);

    require(!isSalePaused);
    require(matchAddressSigner(messagehash, signature), "INVALID MINT SIGNATURE!");
    require(stage == 1, "MINT PASS PHASE NOT OPEN!");
    require(supply + _mintAmount <= mintPassSupply, 'MINT PASS SUPPLY REACHED!');
    require(_mintAmount + mintPassCount[msg.sender] <= mintPassMax, 'MAX MINT PASS SUPPLY FOR THIS WALLET REACHED');   
    mintPassCount[msg.sender] += _mintAmount;

    
    _mint(_mintAmount, supply);
  }

  function mintStage2(bytes memory signature, uint8 _mintAmount) external payable {
    uint256 supply = totalSupply();
    bytes memory message = abi.encodePacked(msg.sender);
    bytes32 messagehash =  keccak256(message);

    require(!isSalePaused);
    require(matchAddressSigner(messagehash, signature), "INVALID MINT SIGNATURE!");
    require(stage == 2, "PRE-SALE STAGE NOT OPEN!");
    require(supply + _mintAmount <= presaleSupply, 'PRESALE SUPPLY REACHED');
    require(_mintAmount + presaleMintCount[msg.sender] <= presaleMintMax, 'MAX PRESALE SUPPLY FOR THIS WALLET REACHED');      
    require(msg.value >= presalePrice * _mintAmount);
    presaleMintCount[msg.sender] += _mintAmount;

    _mint(_mintAmount, supply);
  }

  function mintStage3(bytes memory signature, uint8 _mintAmount) external payable {
    uint256 supply = totalSupply();
    bytes memory message = abi.encodePacked(msg.sender);
    bytes32 messagehash =  keccak256(message);

    require(!isSalePaused);
    require(matchAddressSigner(messagehash, signature), "INVALID MINT SIGNATURE!");
    require(stage == 3, "PRE-SALE CLEARANCE STAGE NOT OPEN!");
    require(supply + _mintAmount <= presaleSupply, 'PRESALE SUPPLY REACHED');
    require(_mintAmount + presaleClearanceMintCount[msg.sender] <= clearanceMintMax, 'MAX PRESALE CLEARANCE SUPPLY FOR THIS WALLET REACHED');      
    require(msg.value >= presalePrice * _mintAmount);
    presaleClearanceMintCount[msg.sender] += _mintAmount;

    _mint(_mintAmount, supply);
  }
  
  function mintStage4(bytes memory signature, uint8 _mintAmount) external payable  {
    uint256 supply = totalSupply();
    bytes memory message = abi.encodePacked(msg.sender);
    bytes32 messagehash =  keccak256(message);

    require(!isSalePaused);
    require(matchAddressSigner(messagehash, signature), "INVALID MINT SIGNATURE!");
    require(stage == 4, "PUBLIC SALE STAGE NOT OPEN!");
    require(supply + _mintAmount <= totalSaleSupply, 'MINT TOTAL SUPPLY REACHED!');
    require(_mintAmount<= saleMintPerTransactionMax, 'MAX PER TRANSACTION REACHED!');
    require(msg.value >= salePrice * _mintAmount);

    _mint(_mintAmount, supply);
  }

  function _mint(uint8 _mintAmount, uint256 supply) internal {
       
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }

  }

  function walletOfOwner(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
        : defaultURI;
  }

  function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(mycontractURI));
  }


  //ERC-2981
  function royaltyInfo(uint256, uint256 _salePrice) external view 
  returns (address receiver, uint256 royaltyAmount){
    return (royaltyAddr, _salePrice.mul(royaltyBasis).div(10000));
  }
  
  //OWNER FUNCTIONS

  function nextStage() external onlyOwner {
    require(stage < 4);
    stage++;
  }

  function setStage(uint8 s) external onlyOwner {
    stage = s;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    require(!finalizeBaseUri);
    baseURI = _newBaseURI;
  }

  function finalizeBaseURI() external onlyOwner {
    finalizeBaseUri = true;
  }

  function setContractURI(string memory _contractURI) external onlyOwner {
    mycontractURI = _contractURI; //Contract Metadata format based on:  https://docs.opensea.io/docs/contract-level-metadata    
  }

  function setRoyalty(address _royaltyAddr, uint256 _royaltyBasis) external onlyOwner {
    royaltyAddr = _royaltyAddr;
    royaltyBasis = _royaltyBasis;
  }

  function setSignerAddress(address signerAddress) external onlyOwner {
    _signerAddress = signerAddress;
  }

  function setVaultAddress(address vaultAddress) external onlyOwner {
    _vaultAddress = vaultAddress;
  }

  function pause(bool _state) external onlyOwner {
    isSalePaused = _state;
  } 

  function reserveMint(uint256 _mintAmount, address _to) external onlyOwner {
    uint256 supply = totalSupply();
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }

  function withdraw() external onlyOwner {
    payable(_vaultAddress).transfer(address(this).balance);
  }
    
  function matchAddressSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
    return _signerAddress == hash.recover(signature);
  }

  function currentStage() external onlyOwner view returns (uint8) {
    return stage;
  }

  function healthCheck() external onlyOwner view returns (bool) {
    return true;
  }

  function setPresaleMax(uint256 psm) external onlyOwner {
    presaleMintMax = psm;
  }
  
  function setSaleMintMax(uint256 smm) external onlyOwner {
    saleMintPerTransactionMax = smm;
  }

  function setPresalePrice(uint256 psp) external onlyOwner {
    presalePrice = psp;
  } 

  function setSalePrice(uint256 sp) external onlyOwner {
    salePrice = sp;
  }

  function getContractBalance() external onlyOwner view returns (uint256) {
    return address(this).balance;
  }

  function testKeccak256(address sender) external onlyOwner view returns (bytes32) {    
    bytes memory message = abi.encodePacked(sender);
    bytes32 messagehash =  keccak256(message);
    return messagehash;
  }

  function testEncodePacked(address sender) external onlyOwner view returns (bytes memory) {
    bytes memory message = abi.encodePacked(sender);
    return message;
  }
}