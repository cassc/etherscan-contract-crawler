// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Egglins is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  //aadak dtigs is mint state
  bool public isGrabbable = false;
  bool public isRevealed = false;

  uint256 constant public egglinArmy = 5001;
  uint256 constant public maxAmountPaid = 11;
  uint256 constant public freeMintAmount = 1001;
  uint256 constant public tooLatePrice = 0.002 ether;

  mapping(address => uint256) public egglinTray;
  mapping(address => uint256) public freeEgglinsGrabbed;

  constructor(
  ) ERC721A("egglins.xyz", "EGGL") {
  }

  modifier callerIsEgglin() {
    require(tx.origin == msg.sender, "Wee Wee you can't bot this!");
    _;
  }

  modifier grabbableEgglins() {
    require(isGrabbable, "egglins are hidden!a aauuuuiaagg");
    _;
  }

  function freeMint(uint256 quantity) external nonReentrant callerIsEgglin grabbableEgglins
  {
    require(quantity < 3, "too many free mints");
    require(totalSupply() + quantity < freeMintAmount, "No more free mints left!");
    require(totalSupply() + 1 < egglinArmy, "All have been grabbed!");
    require(freeEgglinsGrabbed[msg.sender] < 2, "!yu grreeeddyyy mfer");
    freeEgglinsGrabbed[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  function grabEgglins(uint256 quantity)
    external payable
    nonReentrant
    callerIsEgglin
    grabbableEgglins
  {
    require(msg.value > (tooLatePrice * quantity));
    require(totalSupply() + quantity < egglinArmy, "!yu grreeeddyyy mfer");
    require(
      egglinTray[msg.sender] + quantity < maxAmountPaid,
      "!yu grreeeddyyy mfer"
    );
    egglinTray[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  function snitchOnEgglins() public onlyOwner {
    isGrabbable = true;
  }

  function hideEgglins() public onlyOwner {
    isGrabbable = false;
  }

  function iCracKEggOK() public onlyOwner {
    isRevealed = true;
  }

  function gimmeFunds() public payable onlyOwner {
	  (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		  require(success, "WTF ERROR???!!");
	}

  function howManyGrabbedFree(address _address) public view returns (uint256){
    return freeEgglinsGrabbed[_address];
  }

  function howManyGrabbedNonFree(address _address) public view returns (uint256){
    return egglinTray[_address];
  }

  string private _birthOfAnEgglin;

  function _baseURI() internal view virtual override returns (string memory) {
    return _birthOfAnEgglin;
  }

  function setBaseURI(string calldata newRainbow) external onlyOwner {
    _birthOfAnEgglin = newRainbow;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "Egglin still hiding!");

    string memory baseURI = _baseURI();
    string memory json = ".json";

    if(isRevealed){
      return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), json))
        : '';
    }else{
      return baseURI;
    }
  }
}