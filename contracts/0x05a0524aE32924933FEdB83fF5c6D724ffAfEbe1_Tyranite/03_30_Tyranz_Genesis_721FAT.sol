/*SPDX-License-Identifier: MIT
      _____                _____                    _____                    _____                    _____                    _____          
     /\    \              |\    \                  /\    \                  /\    \                  /\    \                  /\    \         
    /::\    \             |:\____\                /::\    \                /::\    \                /::\____\                /::\    \        
    \:::\    \            |::|   |               /::::\    \              /::::\    \              /::::|   |                \:::\    \       
     \:::\    \           |::|   |              /::::::\    \            /::::::\    \            /:::::|   |                 \:::\    \      
      \:::\    \          |::|   |             /:::/\:::\    \          /:::/\:::\    \          /::::::|   |                  \:::\    \     
       \:::\    \         |::|   |            /:::/__\:::\    \        /:::/__\:::\    \        /:::/|::|   |                   \:::\    \    
       /::::\    \        |::|   |           /::::\   \:::\    \      /::::\   \:::\    \      /:::/ |::|   |                    \:::\    \   
      /::::::\    \       |::|___|______    /::::::\   \:::\    \    /::::::\   \:::\    \    /:::/  |::|   | _____               \:::\    \  
     /:::/\:::\    \      /::::::::\    \  /:::/\:::\   \:::\____\  /:::/\:::\   \:::\    \  /:::/   |::|   |/\    \               \:::\    \ 
    /:::/  \:::\____\    /::::::::::\____\/:::/  \:::\   \:::|    |/:::/  \:::\   \:::\____\/:: /    |::|   /::\____\_______________\:::\____\
   /:::/    \::/    /   /:::/~~~~/~~      \::/   |::::\  /:::|____|\::/    \:::\  /:::/    /\::/    /|::|  /:::/    /\::::::::::::::::::/    /
  /:::/    / \/____/   /:::/    /          \/____|:::::\/:::/    /  \/____/ \:::\/:::/    /  \/____/ |::| /:::/    /  \::::::::::::::::/____/ 
 /:::/    /           /:::/    /                 |:::::::::/    /            \::::::/    /           |::|/:::/    /    \:::\~~~~\~~~~~~       
/:::/    /           /:::/    /                  |::|\::::/    /              \::::/    /            |::::::/    /      \:::\    \            
\::/    /            \::/    /                   |::| \::/____/               /:::/    /             |:::::/    /        \:::\    \           
 \/____/              \/____/                    |::|  ~|                    /:::/    /              |::::/    /          \:::\    \          
                                                 |::|   |                   /:::/    /               /:::/    /            \:::\    \         
                                                 \::|   |                  /:::/    /               /:::/    /              \:::\____\        
                                                  \:|   |                  \::/    /                \::/    /                \::/    /        
                                                   \|___|                   \/____/                  \/____/                  \/____/         
*/                                                                                                                                            
pragma solidity >=0.8.0 <0.9.0;

import ".deps/ERC721F.sol";
import ".deps/IERC4906.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "contracts/Drill_1155.sol";
import ".deps/project_os/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TyranzGenesis is ERC721FAT,ERC2981,IERC4906,Ownable,DefaultOperatorFilterer {
  using Strings for uint256;

  string public baseURI;
  string public notRevealedUri;
  string public legendURI;
  string public notRevLegendUri;
  string public InjectedURI;
  string public baseExtension = ".json";
  

  uint256 public pre_maxSupply = 3168;
  uint256 public maxSupply = 3333;  
  uint256 public cost = 0.033 ether;  
  uint256 public maxMintAmount = 3;
  uint256 public nftPerAddressLimit = 3;
  uint256 public Infusion_cap;
  uint256 public Infusion_cost = 1000 ether;

  bool public presaleactive = false;
  bool public saleactive = false;
  bool public freemintactive = false;
  bool public revealed = false; 
  bool public injecting = false;
  
  mapping(address => uint256) public addressMintedBalance;
  mapping(address => uint256) public addressMintedBalance_WL;
  mapping(address => uint256) public addressMintedTyranite;
  mapping (uint256 => bool) public legendary;
  mapping (uint256 => bool) public revlegendary;
  mapping(uint256  => bool) public Injected;

  bytes32 public root;
  bytes32 public free_root;

  TyraniteDrill public item;
  IERC20 public token;



  
  constructor(string memory _name,
              string memory _symbol,
              string memory _initNotRevealedUri,
              string memory _initNotRevLegendUri,address drillContract) ERC721FAT(_name, _symbol)
  {
    setNotRevealedURI(_initNotRevealedUri);
    setNotRevLegendURI(_initNotRevLegendUri);
    item = TyraniteDrill(drillContract);
    isLegendary();
 
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721FAT,ERC2981,IERC165) returns (bool) {
         return super.supportsInterface(interfaceId);
  }

//Metadata Service Functions

  function _startTokenId() internal view virtual override returns (uint256) { 
        return 1;
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _legendURI() internal view virtual returns (string memory) {
    return legendURI;
  }

  function _notRevealedUri() internal view virtual returns (string memory) {
    return notRevealedUri;
  }

  function _notRevLegendUri() internal view virtual returns (string memory) {
    return notRevLegendUri;
  }

  function _InjectedURI() internal view virtual returns (string memory) {
    return InjectedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner { 
    baseURI = _newBaseURI;
    emit BatchMetadataUpdate(11,3333);
  }

  function setLegendURI(string memory _newLegendURI) public onlyOwner { 
    legendURI = _newLegendURI;
    emit BatchMetadataUpdate(1,10);
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner { 
    notRevealedUri = _notRevealedURI;
    
  }

  function setNotRevLegendURI(string memory _notRevLegendURI) public onlyOwner { 
    notRevLegendUri = _notRevLegendURI;
  }

  function setInjectedURI(string memory _InjectURI) public onlyOwner { 
    InjectedURI = _InjectURI;
  }

  function bulk_metadata_refresh(uint256 startid,uint256 lastid) public onlyOwner {
    emit BatchMetadataUpdate(startid,lastid);
  }

  function sigle_metadata_refresh(uint256 tokenid) public onlyOwner {
    emit MetadataUpdate(tokenid);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (_exists(tokenId) == false) revert ("URI query for unexistent Token");

        if(revealed == false && legendary[tokenId] == false) {
        
        return notRevealedUri;
        }

        if(revealed == false && legendary[tokenId] == true ) {
        
        return notRevLegendUri;
        }

        if(revealed == true && legendary[tokenId] == true && revlegendary[tokenId] == false ) {
        
        return notRevLegendUri;
        }

        if(revealed == true && Injected[tokenId] == true && legendary[tokenId] == false){
          string memory currentInjectedURI = _InjectedURI();
          return bytes(currentInjectedURI).length != 0 ? string(abi.encodePacked(InjectedURI,tokenId.toString(),baseExtension)) : '';
        }

        if(revealed == true && legendary[tokenId] == true && revlegendary[tokenId] == true){
         string memory currentlegendURI = _legendURI();
         return bytes(currentlegendURI).length != 0 ? string(abi.encodePacked(legendURI,tokenId.toString(),baseExtension)) : '';
        }

        string memory currentbaseURI = _baseURI();
        return bytes(currentbaseURI).length != 0 ? string(abi.encodePacked(baseURI,tokenId.toString(),baseExtension)) : '';
  }

  //Admin Service Function

  function active_Infusion(bool _state) public onlyOwner { 
    
    injecting = _state;  
  }

    
  function presale(bool _state) public onlyOwner { 
    presaleactive = _state;
    
  }

  function freemint(bool _state) public onlyOwner { 
    freemintactive = _state;
    
  }

  function publicsale(bool _state) public onlyOwner { 
    
    saleactive = _state;  
  }

  function sale_switch() public onlyOwner { 
    presaleactive = false;
    saleactive = true;   
  }

  function isLegendary() private onlyOwner {
    legendary[1] = true;
    legendary[2] = true;
    legendary[3] = true;
    legendary[4] = true;
    legendary[5] = true;
    legendary[6] = true;
    legendary[7] = true;
    legendary[8] = true;
    legendary[9] = true;
    legendary[10] = true;  
  }

  function revLegendary(uint256 tokenId) public onlyOwner {
    revlegendary[tokenId] = true;
    emit MetadataUpdate(tokenId);
  }

  function reveal(string memory _newBaseURI) public onlyOwner {
    require (!revealed,"one time use Only be careful my Dev");
    baseURI = _newBaseURI;  
    revealed = true;
    emit BatchMetadataUpdate(11,3333);
  }



  function set_root(bytes32 new_root) public onlyOwner{
    root = new_root;
  }

  function set_freeroot(bytes32 new_freeroot) public onlyOwner{
    free_root = new_freeroot;
  } 

  function Whitdraw(address Withdraw_Address) public onlyOwner {
    address payable to = payable(Withdraw_Address);
    to.transfer(address(this).balance);

  }

  function set_royalties(address receiver,uint96 feeNumerator) public onlyOwner{
    _setDefaultRoyalty(receiver,feeNumerator);
  }


  function set_cost(uint256 new_cost) public onlyOwner{
    cost = new_cost;
  }

  function set_Infusion_cost(uint256 new_Infusion_cost) public onlyOwner{
    Infusion_cost = new_Infusion_cost;
  }



  function set_public_limits(uint256 new_nftPerAddressLimit,uint256 new_maxMintAmount) public onlyOwner{
      maxMintAmount = new_nftPerAddressLimit;
      nftPerAddressLimit = new_maxMintAmount;
  }

  function airdrop(address beneficiary,uint256 amount) public onlyOwner{
    uint256 supply = totalSupply();
    if(supply + amount > maxSupply) revert ("Max Supply reached");
    _safeMint(beneficiary,amount);
  }

  function set_tyranite_contract(address tyraniteContract) public onlyOwner{
    token = IERC20(tyraniteContract);
  }
    


  //Minting Stage

  function public_sale(uint256 quantity) public payable {  

    uint256 supply = totalSupply();
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    
    
    if(quantity <= 0) revert ("need to mint at least 1 NFT");
    if(supply + quantity > maxSupply) revert ("Sold Out");

    if (msg.sender != owner()) 
    {
      if(supply + quantity > pre_maxSupply) revert ("Sold Out");
      if(saleactive == false) revert ("Function Disabled");
      if(ownerMintedCount + quantity > nftPerAddressLimit) revert ("max NFT per address exceeded");
      if(quantity > maxMintAmount) revert ("max mint x session reached");
      if(msg.value != cost * quantity) revert ("incorrect amount");

      addressMintedBalance[msg.sender] += quantity;
      _safeMint(msg.sender,quantity);    
    }else{
      _safeMint(msg.sender,quantity);
    }
  
  }

  function pre_sale(uint256 quantity,bytes32[] memory proof) public payable {

    uint256 supply = totalSupply();
    uint256 ownerMintedCount = addressMintedBalance_WL[msg.sender];
    uint256 drills = item.balanceOf(msg.sender,1);
    uint256 pre_nftPerAddressLimit_WL = drills *3; 
    uint256 nftPerAddressLimit_WL = 3 + pre_nftPerAddressLimit_WL;
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    if(presaleactive == false) revert ("Function Disabled");
    if(MerkleProof.verify(proof,root,leaf) == false) revert ("user not Whitelisted");
    if(quantity <= 0) revert ("need to mint at least 1 NFT");
    if(supply + quantity > pre_maxSupply) revert ("Sold Out");
    if(ownerMintedCount + quantity > nftPerAddressLimit_WL) revert ("max NFT per address exceeded");
    if(quantity > 6) revert ("max mint x session reached");
    if(msg.value != cost * quantity) revert ("incorrect amount");
    addressMintedBalance_WL[msg.sender] += quantity;
    _safeMint(msg.sender,quantity); 
  
  }

  function free_claim(uint256 quantity,bytes32[] memory proof) public {

    uint256 supply = totalSupply();
    uint256 ownerMintedCount_free = addressMintedTyranite[msg.sender];
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender,quantity));

    if(freemintactive == false) revert ("Function Disabled");
    if(MerkleProof.verify(proof,free_root,leaf) == false) revert ("not eligible to claim");
    if(ownerMintedCount_free > 0) revert ("Already Claimed"); 
    if(quantity <= 0) revert ("need to mint at least 1 NFT");
    if(supply + quantity > maxSupply) revert ("Sold Out");
     
    for(uint256 i = 0; i < quantity; i++) {
      addressMintedTyranite[msg.sender]++;
      _safeMint(msg.sender,1);
    }
    
  }

  //OS operator filter function overrides//----------------------------------------------------

  function setApprovalForAll(address operator, bool approved) public virtual override (ERC721FAT,IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    
    function approve(address operator, uint256 tokenId) public virtual override (ERC721FAT,IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    
    function transferFrom(address from, address to, uint256 tokenId) public virtual override (ERC721FAT,IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override (ERC721FAT,IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override (ERC721FAT,IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

//DAPP METRICS----------------------------------------------------
  
  function drill_of_Holder(address Holder) public view returns(uint256)
    {
      return item.balanceOf(Holder,1);
   
    }

    function Tyranite_Balance(address Staker) public view returns(uint256)
    {
      return token.balanceOf(Staker);
   
    }

//Special Mechanics-------------------------------------------------

function InfuseTyranite(uint256 tokenid) public {
  
  uint256 tyranitebalance = token.balanceOf(msg.sender);

  if(injecting == false) revert ("Function Disabled");
  if(msg.sender != ownerOf(tokenid)) revert ("Sender must be Owner");
  if(Infusion_cap >= 33) revert ("Infusion Cap Reached");
  if(legendary[tokenid] == true) revert ("Can't Infuse Primals");
  if(Injected[tokenid] == true) revert ("Already Infused");
  if(tyranitebalance < Infusion_cost) revert ("Insufficent Tyranite");

  Infusion_cap++;
  Injected[tokenid] = true;
  emit MetadataUpdate(tokenid);
  token.transferFrom(msg.sender,address(this),Infusion_cost);
  

}


}