// SPDX-License-Identifier: MIT

//.............................................................................
//.BBBBBBBBBB...LLLL.........OOOOOOO.......CCCCCCC....KKKK...KKKKK..SSSSSSS....
//.BBBBBBBBBBB..LLLL........OOOOOOOOOO....CCCCCCCCC...KKKK..KKKKK..SSSSSSSSS...
//.BBBBBBBBBBB..LLLL.......OOOOOOOOOOOO..CCCCCCCCCCC..KKKK.KKKKK...SSSSSSSSSS..
//.BBBB...BBBB..LLLL.......OOOOO..OOOOO..CCCC...CCCCC.KKKKKKKKK...KSSSS..SSSS..
//.BBBB...BBBB..LLLL......LOOOO....OOOOOOCCC.....CCC..KKKKKKKK....KSSSS........
//.BBBBBBBBBBB..LLLL......LOOO......OOOOOCCC..........KKKKKKKK.....SSSSSSS.....
//.BBBBBBBBBB...LLLL......LOOO......OOOOOCCC..........KKKKKKKK......SSSSSSSSS..
//.BBBBBBBBBBB..LLLL......LOOO......OOOOOCCC..........KKKKKKKKK.......SSSSSSS..
//.BBBB....BBBB.LLLL......LOOOO....OOOOOOCCC.....CCC..KKKK.KKKKK.........SSSS..
//.BBBB....BBBB.LLLL.......OOOOO..OOOOO..CCCC...CCCCC.KKKK..KKKK..KSSS....SSS..
//.BBBBBBBBBBBB.LLLLLLLLLL.OOOOOOOOOOOO..CCCCCCCCCCC..KKKK..KKKKK.KSSSSSSSSSS..
//.BBBBBBBBBBB..LLLLLLLLLL..OOOOOOOOOO....CCCCCCCCCC..KKKK...KKKKK.SSSSSSSSSS..
//.BBBBBBBBBB...LLLLLLLLLL....OOOOOO.......CCCCCCC....KKKK...KKKKK..SSSSSSSS...
//.............................................................................

//BLOCKSbyharvmcm official ERC-721 contract
//This is where your BLOCK is built ;)
//Deployed by @jshjdev

pragma solidity ^0.8.0;

//Import required contracts
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BLOCKS is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  //Main variables
  uint256 public BLOCKScost = 0.1 ether;
  uint256 public BLOCKSsupply = 1000; 
  uint256 public BLOCKSperaddress = 2;
  mapping (address => uint256) private	_addr_balance;
  bool public onlyBLOCKSlisted = true;
  bool public paused = true;
  bool public revealed = false;
  string private uriPrefix = "ipfs://QmbgKF7wJJz3cgkiXB4KivEFmKLvmbeMNYySjbbVDk3sez/";
  string public uriSuffix = ".json";
  string private hiddenMetadataUri;
  address[] public whitelistedAddresses;

  //Placeholder (although we are doing instant reveal)
  constructor() ERC721("BLOCKS", "BB") {
    setHiddenMetadataUri("ipfs://QmVhVpTeh9tgciD5eSWV4Fv1MfdhwQfjgBwhnQiwvK4mXK/hidden.json");
  }

  //Check how many are being minted, and to check for sellout
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= BLOCKSperaddress,                    "Over allocation");
    require(supply.current() + _mintAmount <= BLOCKSsupply,                        "Sold out");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    //To allow for minting, each requirement has to be met
    //Requires unpaused
    require(!paused,                                                               "Sale paused");

    //If BLOCKlist mint is active, check if minting address is on the list
    if (onlyBLOCKSlisted == true)
    {
    //Required address to be BLOCKlisted
    require(isBLOCKSlisted(msg.sender),                                            "Not on BLOCKSlist");
    } 

    //Checks if the an address is trying to remint, cannot be over the BLOCKsperaddress
    require(get_addr_minted_balance(msg.sender) + _mintAmount <= BLOCKSperaddress, "Allocation hit");

    //Ensure cost is correct
    require(msg.value >= BLOCKScost * _mintAmount,                                 "0.1ETH per BLOCK");
    
    //Requirements have been passed, mint function can be called
    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

 //Used to check if an address is in the BLOCKSlist
  function isBLOCKSlisted(address _user) public view returns (bool) {
    for(uint256 i=0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
        return true;
      }
    }
    return false;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= BLOCKSsupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "Query for nonexistent token" //test
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  //ERC721 default version is very expensive, used internal to save gas
  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  //Push metadata
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  //Can change mint price, you never know what may happen to ETH ;)
  function setBLOCKSCost(uint256 _BLOCKScost) public onlyOwner {
    BLOCKScost = _BLOCKScost;
  }

  //Allows for the mint amount to be changed, will be changed to 1 for public sale
  function setBLOCKSperaddress(uint256 _BLOCKSperaddress) public onlyOwner {
    BLOCKSperaddress = _BLOCKSperaddress;
  }

  //Set hiddenmetadata
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  //Set prefix type
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  //Toggle the sale of BLOCKS
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  //Toggle if BLOCKSlist is required to mint
  function setonlyBLOCKSlisted(bool _state) public onlyOwner {
    onlyBLOCKSlisted = _state;
  }
 
  //Can check how many BLOCKS an address has minted
	function get_addr_minted_balance(address user) public view returns (uint256) {
		return _addr_balance[user];
	}

  //Used to input BLOCKSlist addresses
  function whitelistUsers(address[] calldata _users) public onlyOwner
  {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }

 //Your BLOCKS are created here :0
  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _addr_balance[msg.sender] += 1; //keeps note of how many BLOCKS an address has minted
      _safeMint(_receiver, supply.current());
    }
  }

  //Allows for contract funds to be deposited to the BLOCKSdeployer
  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

    function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}