//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./auth/Ownable.sol";
import './utils/Base64.sol';
import './utils/HexStrings.sol';
import './interfaces/INftMetadata.sol';

contract Eyebrows is ERC721Enumerable, Ownable {

  using Strings for uint256;
  using HexStrings for uint160;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  uint256 public constant limit = 1000;
  uint256 public constant curve = 1005; // price increase 0,5% with each purchase
  uint256 public price = 0.002 ether;
  INftMetadata public ebContract;
  ERC721Enumerable public miloogy;

  mapping (uint256 => bytes32) public genes;

  constructor(address owner_, ERC721Enumerable miloogy_) ERC721("Miloogy Eyebrows", "MILEB") {
    _initializeOwner(owner_);
    miloogy = miloogy_;
  }

  function mintItem() public payable returns (uint256) {
      require(_tokenIds.current() < limit, "DONE MINTING");
      require(msg.value >= price, "NOT ENOUGH");
      require(address(ebContract) != address(0), "NOT MINTING YET");
      price = (price * curve) / 1000;
      _tokenIds.increment();
      uint256 id = _tokenIds.current();
      _mint(msg.sender, id);
      genes[id] = keccak256(abi.encodePacked( id, blockhash(block.number-1), msg.sender, address(this) ));
      return id;
  }


  function setEb(INftMetadata newEb) public onlyOwner {
    require(address(ebContract) == address(0), "can only set once");
    ebContract = newEb;
  }

  function withdraw() public onlyOwner {
      bool success;
      uint donation = address(this).balance/5;
      (success, ) = 0x1F5D295778796a8b9f29600A585Ab73D452AcB1c.call{value: donation}(""); //vectorized.eth
      assert(success);
      (success, ) = 0x97843608a00e2bbc75ab0C1911387E002565DEDE.call{value: donation}(""); //buidlguidl.eth
      assert(success);
      (success, ) = owner().call{value: address(this).balance}("");
      assert(success);
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), "not exist");
    assert(address(ebContract) != address(0));
    return(ebContract.tokenURI(id));
    
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {

    string memory svg = string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));

    return svg;
  }

  function renderTokenById(uint256 id) public view returns (string memory) {
    
      assert(address(ebContract) != address(0));
      return(ebContract.renderTokenById(id));
    
  }

  function renderTokenByIdFront(uint256 id) public view returns (string memory) {
   
      assert(address(ebContract) != address(0));
      return(ebContract.renderTokenByIdFront(id));
    
  }
  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenByIdBack(uint256 id) public view returns (string memory) {
    
      assert(address(ebContract) != address(0));
      return(ebContract.renderTokenByIdBack(id));
    
  }

  function getTraits(uint id) public view returns(string memory) {
    
      assert(address(ebContract) != address(0));
      return(ebContract.getTraits(id));
    
  }
}