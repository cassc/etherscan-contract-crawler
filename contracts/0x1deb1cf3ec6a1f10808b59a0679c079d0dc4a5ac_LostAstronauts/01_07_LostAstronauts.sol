// SPDX-License-Identifier: MIT

/*///////////////////////////////////////////////////////////////////////////////////

LOST ASTRONAUTS BY KEN KELLEHER

*////////////////////////////////////////////////////////////////////////////////////

// ABASHO COLLECTIVE DROP
//-----------------------
// ART BY: ANCHORBALL / KEN KELLEHER 
// AUTHOR: NODESTARQ                                                                                 

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "erc721a/contracts/ERC721A.sol";

contract LostAstronauts is ERC721A, Ownable {

  // REGULAR MINT VARIABLES //
  bool public riftOpen; //MINT START BOOL
  uint256 public constant ASTRONAUTS = 250; //MAX SUPPLY
  uint256 public constant WALLETLIMIT = 5; //WALLET LIMIT
  uint256 public constant REGULAR_COST = 0.04 ether; //MINT PRICE FOR REGULAR MINTER
  uint256 randOffset; //RANDOM OFFSET VALUE
  string private baseURI; //TOKENURI
  mapping(address => uint) public addressClaimed; //KEEP TRACK OF CLAIMED LOST ASTRONAUTS

  // ABASHO COLLECTIVE MINT//
  bool public riftOpenAbasho; //ABASHO MINT START BOOL
  address public AbashoContract = 0xE9C79B33C3A06f5Ae7369599F5a1e2FF886e17F0; //ABASHO SMART CONTRACT ADDRESS
  uint256 public constant ABASHO_COST = 0.01 ether; //MINT PRICE FOR ABASHO HOLDER
  mapping(uint256=>bool) public abashoClaimed; //ABASHO CLAIMED CHECKER

  //CREATE NFT COLLECTION
  constructor() ERC721A("The Lost Astronauts", "LOST"){} //TOKEN NAME

  //START AT TOKEN 1 INSTEAD OF 0
  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  //STARTS REGULAR MINT
  function openRift() external onlyOwner { 
      riftOpen = true;
  }
  //STARTS ABASHO MINT
  function openRiftAbasho() external onlyOwner { 
      riftOpenAbasho = true;
  }

  //ABASHO MINT FUNCTION
  function abashoRecoverAstronaut(uint256 _abashoId) external payable {
    IERC721 abasho = IERC721(AbashoContract); //ABASHO INTERFACE
    uint256 total = totalSupply();
    require(riftOpenAbasho, "NO ABASHO SHORTCUT FOUND");  //CHECK IF ABASHO SALE STARTED
    require(total + 1 <= ASTRONAUTS, "ALL 250 LOST ASTRONAUTS HAVE BEEN RECOVERED"); //CHECK IF MINTED OUT
    require(ABASHO_COST <= msg.value, "NOT ENOUGH ETH"); //CHECK IF ENOUGH ETH PAID

    //ABASHO CHECKS START HERE
    require(abasho.ownerOf(_abashoId) == _msgSender(), "NOBASHO DETECTED");  //CHECK IF ABASHO OWNER
    require(!abashoClaimed[_abashoId], "ABASHO ID HAS ALREADY CLAIMED");  //CHECK IF ABASHO HAS CLAIMED ALREADY
    abashoClaimed[_abashoId] = true;  //SET CLAIMED VAR
    
    addressClaimed[_msgSender()] += 1; // ADD TO WALLET LIMIT COUNTER
    _safeMint(msg.sender, 1); // PULL LOST ASTRONAUT OUT OF THE MERGE EVENT HORIZON
  }

  //REGULAR MINT FUNCTION
  function recoverAstronaut() external payable {
    uint256 total = totalSupply();
    require(riftOpen, "MERGE RIFT NOT EMITTING"); //CHECK MINT STARTED
    require(total + 1 <= ASTRONAUTS, "ALL 250 LOST ASTRONAUTS HAVE BEEN RECOVERED"); //CHECK IF MINTED OUT
    require(addressClaimed[_msgSender()] + 1 <= WALLETLIMIT, "YOU CAN'T RECOVER MORE");
    require(REGULAR_COST <= msg.value, "NOT ENOUGH ETH"); //CHECK IF ENOUGH ETH PAID

    
    addressClaimed[_msgSender()] += 1; // ADD TO WALLET LIMIT COUNTER
    _safeMint(msg.sender, 1); // PULL LOST ASTRONAUT OUT OF THE MERGE EVENT HORIZON
  }

  //PSEUDO RANDOMIZER: ONLY OWNER CAN CALL
  function pseudoRandom() external onlyOwner{
        string memory salt = "lOSTaSTRONAUTS";
        uint256 number = uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender,salt))) % 250;
        number == 0 ? number++: number;
        randOffset = number;
    }

  //SET TOKENURI LINK: ONLY OWNER CAN CALL
  function setSignal(string memory baseURI_) external onlyOwner { 
      baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }
  
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ASTRONAUT ID NOT IN OUR DATABASE");

    uint256 _curId =  _tokenId + randOffset;
    if (_curId > ASTRONAUTS) {
            _curId = _curId - ASTRONAUTS;
        }
  
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(_curId), '.json'))
        : '';
  }

  //WITHDRAW FUNDS FROM SMART CONTRACT: ONLY OWNER CAN CALL
  function withdraw() external onlyOwner{
        payable(_msgSender()).transfer(address(this).balance);
    }
}