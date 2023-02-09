// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";



pragma solidity >=0.8.0 <0.9.0;

contract TyraniteDrill is ERC1155,Ownable,ERC2981 {
    
  string public name;
  string public symbol;

  uint public totalSupply = 0;
  uint public maxSupply = 165;
  uint public WhiteLimit = 1;
  uint public PublicLimit = 2;
  uint public maxMintAmount = 2;
  uint public cost = 0.05 ether;

  bool public publicsale = false;
  bool public onlyOG = false;
  


  mapping (uint => string) private tokenURI;
  mapping (address => uint) public AddressMintedBalance_WL;
  mapping (address => uint) public AddressMintedBalance_PB;

  bytes32 public root;

  
  

  constructor(string memory _name,string memory _symbol,string memory _baseURI) ERC1155("") {
    name = _name;
    symbol = _symbol;
    tokenURI[1] = _baseURI;   
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override (ERC1155,ERC2981) returns (bool) {
         return super.supportsInterface(interfaceId);
    }

  function uri(uint _id) public view virtual override  returns (string memory) {
    return tokenURI[_id];
    
  }

  function _publicsale (bool _state) public onlyOwner {
    publicsale = _state;
  }

  function _onlyOG(bool _state) public onlyOwner {
    onlyOG = _state;
  }

  function set_root(bytes32 _root) public onlyOwner {
    root = _root;
  }

  function set_cost(uint256 new_cost) public onlyOwner {
    cost = new_cost;
  }

  function sale_switch() public onlyOwner {
    onlyOG = false;
    publicsale = true;
  }

  function set_uri(string memory new_tokenURI) public onlyOwner{
      tokenURI[1] = new_tokenURI;
  }

  function set_royalties(address receiver,uint96 feeNumerator) public onlyOwner{
    _setDefaultRoyalty(receiver,feeNumerator);// 1% = 100
  }

  function publicmint(uint256 amount) public payable {
    if(totalSupply + amount > maxSupply) revert("Amount Exceeds Max Supply"); 
    if(amount <= 0) revert("Mint at Least 1");

    if(msg.sender != owner()){
      if (publicsale == false) revert ("Function Disabled");
      if (amount + AddressMintedBalance_PB[msg.sender] > PublicLimit) revert ("Address Limit Reached");
      if(amount > maxMintAmount) revert ("Max Mint x Session Reached");
      if (msg.value != cost * amount) revert ("Incorrect Amount");
      }

      totalSupply += amount;
      AddressMintedBalance_PB[msg.sender]+= amount;
      _mint(msg.sender,1, amount ,"Thank You!!");    
  }

  function OGmint(bytes32[] memory proof) public payable {
      if (onlyOG == false) revert ("Function Disabled");
      if(totalSupply == maxSupply) revert ("Sold Out");
      if(AddressMintedBalance_WL[msg.sender] == WhiteLimit) revert ("Address Limit Reached");
      if(msg.value != cost) revert ("Incorrect Amount");

      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      if (!MerkleProof.verify(proof,root,leaf)) revert ("User not Whitelisted");

      totalSupply++;
      AddressMintedBalance_WL[msg.sender]++;
      _mint(msg.sender,1, 1 ,"Welcome aboard Pioneer!!");    
  }

  function Withdraw(address Withdraw_Address) public onlyOwner {
    address payable to = payable(Withdraw_Address);
    to.transfer(address(this).balance);
    //WITHDRAW ETH FROM THE SMARTCONTRACT TO A SPECIFIC ADDRESS// 
  }

  

  function Airdrop (address to , uint256 amount) public onlyOwner{
    if (totalSupply + amount > maxSupply) revert ("Amount Exceeds Max Supply");
    _mint(to,1,amount,"This is a Gift for You!!");
    totalSupply+= amount;
    //AIRDROP AMOUNT OF DRILLS TO A SPECIFIC ADDRESS//
  }






  


  
   


  

  

  

}