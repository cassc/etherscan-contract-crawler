// SPDX-License-Identifier: MIT
// contract written by @jishai 

// ........................................................................
// ........................................................................
// ........................................................................
// ............................s&&&&&&&&&&&&&ss............................
// ......................s&&&**:::::::::::::::*&&&s........................
// ..................s&&&*::::::::::::::::::::::::&&s......................
// ...............s&&*::::::::::::::::::::::::::::::&&.....................
// .............&&&:::::::::::::::::::::::::::::::::::&&...................
// ...........&&*::::::::::::::::::::::::::::::::::::::&&..................
// ..........&&:::::::::::::::::::::::::::::::::::::::::&&s................
// ........&&;::::::::::::::::::::ss&&s.:::::::::::::::&& *&&..............
// .......&&;;:::::::::::::::::::&*    *&&:::::::::::::&*   &&.............
// ......s&;;;::::::::::::::::::&&       &&::::::::::::&&    &&............
// ......&&;;;;:::::::::::::::::&&       &&:::::::::::::&s   &&............
// ......&&;;;;::::::::::::::::::&&      &&:::::::::::::::&s &s............
// ......&&;;;;;::::::::::::::::::&s    s&::::::::sss&&&&&&&&&ss...........
// ......&&;;;;;;:::::::::::::::::::*&&&::::s&&&&*;;;;;;;;;;s&&&&&&&&&s....
// ......&&;;;;;;;:::::::::::::::::::::::&&*;;;;;;;;;;;;;s&*;;;;;;;;;;&&...
// ......s&;;;;;;;;:::::::::::::::::::&&*;;;;;;;;;;;;;;s&*;;;;;;;;;;;;&&...
// .......&&;;;;;;;;:::::::::::::::::&&;;;;;;;;;;;;;s&*;;;;;;;;;;;;;;;&&...
// ........&&;;;;;;;;;::::::::::::::&&;;;;;;;;;;;ss&&&&&&&&QUACK&&&&&&&....
// ........*&s;;;;;;;;;;:::::::::::*&&&&&ssss&&&**;;;;;;;;;;;;;;;;;;;&&....
// ..........&&;;;;;;;;;;;::::::::::::::**&&&&s;;;;;;;;;;;;;;;;;;;;;&&.....
// ...........&&;;;;;;;;;;;;::::::::::::::::::*&&&&&&&&&&&&&&&&&&&&&*......
// ............*&&;;;;;;;;;;;;;;;:::::::::::::::::::::::&&*................
// ..............*&&;;;;;;;;;;;;;;;;;;;::::::::::::::::&&..................
// .................*&&s;;;;;;;;;;;;;;;;;;;;;;;;;;;s&&&*...................
// .....................*&&ss;;;;;;;;;;;;;;;ss&&&&&*.......................
// ..........................*&&&&&&&&&&&&&*...............................
// ........................................................................
// ........................................................................
// ........................................................................

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RubberDuckBathParty is ERC721, Ownable {
  using Strings for uint256;

  using Counters for Counters.Counter;
  Counters.Counter private _nextTokenId;

  string public baseURI;
  string public ipfsURI;

  uint256 public price = 0.08 ether;
  uint256 public constant maxSupply = 10000;
  uint256 public constant mintPerAddressLimit = 2;
  uint256 public constant ownerMintLimit = 100;

  bool public mintActive = false;
  bool public earlyMintActive = false;

  bytes32 public merkleRoot;

  mapping(address => uint256) public addressMintedBalance;

  constructor() ERC721("RubberDuckBathParty", "RDBP") {
    setBaseURI("https://duck.art/meta/");
    _nextTokenId.increment();
  }

  // Early mint function for people on the pregame list
  function earlyMint(bytes32[] calldata _merkleProof, uint256 _mintAmount) public payable {
    require(earlyMintActive, "the early mint is paused");
    require(totalSupply() + _mintAmount <= maxSupply, "all ducks are minted!");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "invalid proof, you're not on the pregame list.");
    require(addressMintedBalance[msg.sender] + _mintAmount <= mintPerAddressLimit, "max ducks per address exceeded");
    require(msg.value == price * _mintAmount, "insufficient funds");

    addressMintedBalance[msg.sender] += _mintAmount;
    for (uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(msg.sender, _nextTokenId.current());
      _nextTokenId.increment();
    }
  }
  
  // Public mint function
  function mint(uint256 _mintAmount) public payable {
    require(mintActive, "the public mint is paused");
    require(totalSupply() + _mintAmount <= maxSupply, "all ducks are minted!");
    require(addressMintedBalance[msg.sender] + _mintAmount <= mintPerAddressLimit, "max ducks per address exceeded");
    require(msg.value == price * _mintAmount, "insufficient funds");
    require(msg.sender == tx.origin, "caller should not be a contract.");

    addressMintedBalance[msg.sender] += _mintAmount;
    for (uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(msg.sender, _nextTokenId.current());
      _nextTokenId.increment();      
    }
  }

  // Owner mint function
  function ownerMint(address _to, uint256 _mintAmount) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, "all ducks are minted!");
    require(addressMintedBalance[msg.sender] + _mintAmount <= ownerMintLimit, "max ducks for team exceeded");

    addressMintedBalance[msg.sender] += _mintAmount;
    for (uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(_to, _nextTokenId.current());
      _nextTokenId.increment();
    }
  }

  // Function to return the total supply
  function totalSupply() public view returns (uint256) {
      return _nextTokenId.current() - 1;
  }

  // Function to set the mint price  
  function setPrice(uint256 _newPrice) public onlyOwner {
    price = _newPrice;
  }

  // Function to set the merkle root  
  function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
    merkleRoot = _newMerkleRoot;
  }

  // Function to toggle the early mint
  function toggleEarlyMint() public onlyOwner {
    earlyMintActive = !earlyMintActive;
  }

  // Function to toggle the public mint
  function toggleMint() public onlyOwner {
    mintActive = !mintActive;
  }
 
  // Function to set the base URI
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  // Function to return the base URI
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // PARTY TIME! Function to change the ipfs URI
  function party(string memory _ipfsURI) public onlyOwner {
    ipfsURI = _ipfsURI;
  }

  // Function to withdraw funds from the contract
  function withdrawBalance() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}