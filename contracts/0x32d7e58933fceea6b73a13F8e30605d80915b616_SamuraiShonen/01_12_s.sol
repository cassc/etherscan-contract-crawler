// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SamuraiShonen is ERC721A, Ownable, DefaultOperatorFilterer {

  using Strings for uint256;

// Variables
    
  string public uri;
  string public prerevealURI= "ipfs://bafkreig72wdwkvdjxbjqkeeszcruv3rewf5m2uocilgcnqztqvaro4kmti";
  uint256 public supplyLimit = 1111;
  bool internal publicsale = false;
  string public _name = "Samurai Shonen";
  string public _symbol = "SS";
  bool public unreveal = false;
  
// Constructor

  constructor(address _address, uint256 quantity
  ) ERC721A(_name, _symbol)  {
    seturi("ipfs://");
  _safeMint(_address,quantity);
  }

// Mint Functions

function OwnerMint(address addresses, uint256 _amount ) public onlyOwner {
        require(_amount + totalSupply() <= supplyLimit, "Quantity Exceeds Tokens Available");
            _safeMint(addresses, _amount);
        }
 
function mint(address _address, string memory signature) public payable {
    require(balanceOf(_address)==0, "Already minted");
    require(publicsale==true, "Mint hasn't begun");
    require(totalSupply()+1<=supplyLimit,"Out of stock");
    {
        _safeMint(_address,1);
    }
}

// Set Functions

function reveal() public onlyOwner{

  unreveal=!unreveal;
}
// uri
  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

function setsale() public onlyOwner{

  publicsale=!publicsale;
}

// Withdraw Function
  
  function withdraw() public onlyOwner  {
    //owner withdraw
                require(payable(msg.sender).send(address(this).balance));
               
  }

// Read Functions
 
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

 
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
         if(unreveal == false) {
            return prerevealURI;
        }

        return string(abi.encodePacked(_baseURI(), "", uint256(tokenId).toString(),".json"));

    }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }    
  function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}