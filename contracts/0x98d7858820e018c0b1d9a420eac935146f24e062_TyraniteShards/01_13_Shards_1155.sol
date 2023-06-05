// SPDX-License-Identifier: MIT

/*
_____/\\\\\\\\\\\____/\\\________/\\\_____/\\\\\\\\\_______/\\\\\\\\\______/\\\\\\\\\\\\________/\\\\\\\\\\\___        
 ___/\\\/////////\\\_\/\\\_______\/\\\___/\\\\\\\\\\\\\___/\\\///////\\\___\/\\\////////\\\____/\\\/////////\\\_       
  __\//\\\______\///__\/\\\_______\/\\\__/\\\/////////\\\_\/\\\_____\/\\\___\/\\\______\//\\\__\//\\\______\///__      
   ___\////\\\_________\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\\\\\\\\\/____\/\\\_______\/\\\___\////\\\_________     
    ______\////\\\______\/\\\/////////\\\_\/\\\\\\\\\\\\\\\_\/\\\//////\\\____\/\\\_______\/\\\______\////\\\______    
     _________\////\\\___\/\\\_______\/\\\_\/\\\/////////\\\_\/\\\____\//\\\___\/\\\_______\/\\\_________\////\\\___   
      __/\\\______\//\\\__\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\_____\//\\\__\/\\\_______/\\\___/\\\______\//\\\__  
       _\///\\\\\\\\\\\/___\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\______\//\\\_\/\\\\\\\\\\\\/___\///\\\\\\\\\\\/___ 
        ___\///////////_____\///________\///__\///________\///__\///________\///__\////////////_______\///////////_____
*/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



pragma solidity >=0.8.0 <0.9.0;

contract TyraniteShards is ERC1155,Ownable {
    
  string public name;
  string public symbol;

  mapping (uint => string) private tokenURI;
  
  ERC20 public token;
  
  constructor(string memory _name,string memory _symbol,

    string memory _baseURI,
    string memory _baseURI2,
    string memory _baseURI3,
    string memory _baseURI4,
    string memory _baseURI5) ERC1155("") 
    
  {
    name = _name;
    symbol = _symbol;
    tokenURI[1] = _baseURI;
    tokenURI[2] = _baseURI2;
    tokenURI[3] = _baseURI3;
    tokenURI[4] = _baseURI4;
    tokenURI[5] = _baseURI5;   
  }


  function uri(uint _id) public view virtual override  returns (string memory) {
    return tokenURI[_id];
    
  }

//ADMIN PANNEL
  function set_Tyranite_contract(address new_contract)public onlyOwner{
    token = ERC20(new_contract);
  }

  function set_uri(uint256 i,string memory new_tokenURI) public onlyOwner{
      tokenURI[i] = new_tokenURI;
     
  }

  
//SHRAD TYPES MINT
  function mint_1()public{
    uint256 price = 150 ether;
    token.transferFrom(msg.sender,address(this),price);
    _mint(msg.sender, 1, 1, "");
  }

  function mint_2()public{
    uint256 price = 250 ether;
    token.transferFrom(msg.sender,address(this),price);
    _mint(msg.sender, 2, 1, "");
  }

  function mint_3()public{
    uint256 price = 500 ether;
    token.transferFrom(msg.sender,address(this),price);
    _mint(msg.sender, 3, 1, "");
  }

  function mint_4()public{
    uint256 price = 1000 ether;
    token.transferFrom(msg.sender,address(this),price);
    _mint(msg.sender, 4, 1, "");
  }

  function mint_5()public{
    uint256 price = 1500 ether;
    token.transferFrom(msg.sender,address(this),price);
    _mint(msg.sender, 5, 1, "");
  }
//SHARD BURN 

  function burn_1()public{
    uint256 price = 150 ether;
    _burn(msg.sender, 1, 1);
    token.transfer(msg.sender,price);
  }

  function burn_2()public{
    uint256 price = 250 ether;
    _burn(msg.sender, 2, 1);
    token.transfer(msg.sender,price);
  }

  function burn_3()public{
    uint256 price = 500 ether;
    _burn(msg.sender, 3, 1);
    token.transfer(msg.sender,price);
  }

  function burn_4()public{
    uint256 price = 1000 ether;
    _burn(msg.sender, 4, 1);
    token.transfer(msg.sender,price);
  }

  function burn_5()public{
    uint256 price = 1500 ether;
    _burn(msg.sender, 5, 1);
    token.transfer(msg.sender,price);
  }

  

  
}