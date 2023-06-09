pragma solidity 0.6.7;
import "./../app/node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";


contract ArtToken is ERC721 {
  uint public index;

  mapping(bytes32 => Art) public userArt;

  struct Art {
    bytes32 title;
    string description;
    address creator;
  } 

  constructor() public ERC721("Portion Art Token", "PAT") {
   index = 0;
 }

 function createUniqueArt(bytes32 _title, string calldata _description, string calldata _tokenURI) external returns (uint) {

  bytes32 hash = keccak256(abi.encodePacked(_title));
  require(userArt[hash].creator == address(0));
  userArt[hash] = Art(_title, _description, msg.sender);
    //Check if this piece name & description is unique
    //create an art token

    index += 1;
    _safeMint(msg.sender, index);
    _setTokenURI(index, _tokenURI);
    
    return index;
  }
}