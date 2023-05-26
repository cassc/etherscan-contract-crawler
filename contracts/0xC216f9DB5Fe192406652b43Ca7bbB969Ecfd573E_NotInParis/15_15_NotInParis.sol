// SPDX-License-Identifier: MIT

/*
  _   _       _     _____         _____           _
 | \ | |     | |   |_   _|       |  __ \         (_)
 |  \| | ___ | |_    | |  _ __   | |__) |_ _ _ __ _ ___
 | . ` |/ _ \| __|   | | | '_ \  |  ___/ _` | '__| / __|
 | |\  | (_) | |_   _| |_| | | | | |  | (_| | |  | \__ \
 |_| \_|\___/ \__| |_____|_| |_| |_|   \__,_|_|  |_|___/


zeitler.eth
*/

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NotInParis is Ownable, ReentrancyGuard, ERC721Enumerable {
  uint256 public PRICE_PER_TOKEN = 0.1 ether;
  uint256 public MAX_SUPPLY = 350;
  uint256 public RESERVE_SUPPLY = 30; // 24 are for the Team. 6 are for the HighSnobiety Museum.
  uint256 private MAX_PUBLIC_MINT = 1;
  bool public IS_SALE_ACTIVE = false;
  bool public IS_ALLOWLIST_REQUIRED = true;
  bytes32 private merkleRoot;
  string private _tokenUri = "";

  mapping(address => uint256) private balances;

  constructor() ERC721("Not In Paris", "NIP") {}

  modifier ableToMint() {
    require(totalSupply() < MAX_SUPPLY - RESERVE_SUPPLY, "Purchase would exceed max tokens");
    _;
  }

  function isWhitelisted(address _address, bytes32[] calldata _merkleProof) external view returns(bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_address));
    return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
  }

  function tokensClaimed(address _address) public view returns(uint256) {
    return balances[_address];
  }

  function mint(bytes32[] calldata _merkleProof) public payable ableToMint nonReentrant {
    require(IS_SALE_ACTIVE, "Sale is not active yet");
    require(msg.value >= PRICE_PER_TOKEN, "Wrong amount of Ether send");

    if(IS_ALLOWLIST_REQUIRED) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Merkle Proof");
    }

    balances[msg.sender]++;
    require(balances[msg.sender] <= MAX_PUBLIC_MINT, "Can't claim more than one token");

    uint256 id = totalSupply();
    id++;
    _safeMint(msg.sender, id);
  }

  function teamMint(uint256 _amount, address _address) external onlyOwner {
    require(_amount <= RESERVE_SUPPLY, "Exceeds max reserved supply");

    uint256 id = totalSupply();
    for (uint256 i; i < _amount; i++) {
      id++;
      _safeMint(_address, id);
    }

    RESERVE_SUPPLY = RESERVE_SUPPLY - _amount;
  }

  /*
    Owner Functions
  */
  function setSaleState(bool _state) external onlyOwner {
    IS_SALE_ACTIVE = _state;
  }

  function setIsAllowlistActive(bool _state) external onlyOwner {
    IS_ALLOWLIST_REQUIRED = _state;
  }

  function setBaseUri(string calldata _uri) external onlyOwner {
    _tokenUri = _uri;
  }

  function setRoot(bytes32 _root) external onlyOwner {
    merkleRoot = _root;
  }

  function setPrice(uint256 _price) external onlyOwner {
    PRICE_PER_TOKEN = _price;
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  /*
   List all the NFTs of a wallet
  */
  function tokensOfOwner(address _owner) public view returns(uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for(uint256 i; i < tokenCount; i++){
        tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  /*
    Overrides
  */
  function _baseURI() internal view virtual override returns(string memory) {
    return _tokenUri;
  }

  function renounceOwnership() public view override onlyOwner {}
}