pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error NotTokenOwner();

contract OMGKirby is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter public _nonClaimIds = Counters.Counter({
      _value: 3071
  });

  Counters.Counter private _totalSupply;
  
  // Timestamps
  uint public immutable claimStartTime;
  uint public immutable claimTimeLock;
  uint public immutable allowlistStartTime;
  uint public immutable allowlistTimeLock;

  // Constants
  uint256 public constant maxSupply = 5000;
  uint256 constant private mintAmount = 1;

  // Vars
  string public baseURI;
  string public baseExtension = ".json";
  bool public lockClaim = false;
  uint256 private teamClaimStartAmount = 3000;

  // Allowlist
  bytes32 public allowlistMerkleRoot;
  mapping(address => uint) public addressClaimed;

  // Addresses
  address public immutable dao;
  address public immutable genesisAddr;

  constructor(address _genesisAddr, uint _claimStartTime, uint _allowlistStartTime, address _dao) ERC721("OMGKirby", "OMG") {
    genesisAddr = _genesisAddr;
    _totalSupply.increment();
    claimStartTime = _claimStartTime;
    allowlistStartTime = _allowlistStartTime;
    allowlistTimeLock = allowlistStartTime + 2 hours;
    claimTimeLock = claimStartTime + 29 days;
    dao = _dao;
  }

  function claimMint(uint256[] memory _ids) external {
    require(block.timestamp <= claimTimeLock, "Claim period has expired");
    require(block.timestamp >= claimStartTime, "Claim has not started yet");
    IERC721 genesisContract = IERC721(genesisAddr);

    for (uint256 i = 0; i < _ids.length; i++) {
      if(genesisContract.ownerOf(_ids[i]) != msg.sender) revert NotTokenOwner();
    }

    for (uint256 i = 0; i < _ids.length; i++) {
      _mint(msg.sender, _ids[i]);
      _totalSupply.increment();
    }
  }

  function allowlistMint(bytes32[] calldata _merkleProof) public {
    require(addressClaimed[_msgSender()] + 1 <= mintAmount, "Exceeds wallet mint amt");
    require(_nonClaimIds.current() <= maxSupply, "allowlist mint has sold out");
    require(block.timestamp >= allowlistStartTime, "WL has not started yet");
    require(block.timestamp < allowlistTimeLock, "WL has ended");

    // Verify merkle proof
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf), "Invalid proof");

    // Mark address as having claimed
    addressClaimed[_msgSender()] += 1;

    uint256 mintIndex = _nonClaimIds.current();
    _mint(msg.sender, mintIndex);
    _totalSupply.increment();
    _nonClaimIds.increment();
  }

  function publicMint() external {
    require(addressClaimed[_msgSender()] + 1 <= mintAmount, "Exceeds wallet mint amt");
    require(_nonClaimIds.current() <= maxSupply, "Public mint has sold out");
    require(tx.origin == msg.sender);
    require(block.timestamp > allowlistTimeLock, "Public mint has not started yet");
    addressClaimed[_msgSender()] += 1;

    uint256 mintIndex = _nonClaimIds.current();
    _mint(msg.sender, mintIndex);

    _nonClaimIds.increment();
    _totalSupply.increment();
  }

  function teamClaim(uint256 quantity) external onlyOwner{
    require(teamClaimStartAmount + quantity <= 3070, "Quantity requested exceeds team claim amount");

    for (uint256 i = 1; i <= quantity; i++) {
      teamClaimStartAmount = teamClaimStartAmount + 1;
      _mint(msg.sender, teamClaimStartAmount);
      _totalSupply.increment();
    }
  }

  function daoClaim(uint256[] memory _ids) external {
    require(msg.sender == dao, "Only DAO owner can claim!");
    require(block.timestamp > claimTimeLock, "Claim period hasn't ended");
    require(!lockClaim, "DAO cannot claim anymore!");

    for (uint256 i = 0; i < _ids.length; i++) {
      if(_ids[i] <= maxSupply){
        _mint(msg.sender, _ids[i]); 
        _totalSupply.increment();
      }
    }
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply.current() - 1;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function isClaimed(uint256 _tokenId) public view returns (bool){
    return _exists(_tokenId);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot) external onlyOwner {
      allowlistMerkleRoot = _allowlistMerkleRoot;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function disableClaim() public {
    require(msg.sender == dao, "Only DAO owner can claim!");
    lockClaim = true;
  }
}