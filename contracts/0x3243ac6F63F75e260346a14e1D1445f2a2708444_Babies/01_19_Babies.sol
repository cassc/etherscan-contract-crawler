// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Babies is ERC721Royalty, Ownable, ReentrancyGuard {
  // Smart contract status
  enum Status {
    CLOSED,
    FREE,
    ALLOWLIST,
    WAITLIST,
    PUBLIC
  }

  Status public status = Status.CLOSED;

  // Claim status
  bool public isClaimActive = false;

  // Counters
  uint256 private _claimed = 0;

  // Params
  string private _baseTokenURI;
  uint256 public supply = 20000;
  uint256 public claimLastIndex = 9999;
  uint256 public publicIndex = claimLastIndex;
  uint256 public price = 0.195 ether;
  uint256[5] public maxPerStatus = [0, 1, 2, 2, 2];
  address public teamWalletAddress;

  // Mappings
  mapping(address => bool) private hasMintedFree;
  mapping(address => bool) private hasMintedList; // ALLOWLIST or WAITLIST
  mapping(address => bool) private hasMintedPublic;

  // CoolmansUniverse
  ERC721Enumerable public coolmansUniverse = ERC721Enumerable(0xa5C0Bd78D1667c13BFB403E2a3336871396713c5);

  // Merkle tree
  bytes32[5] public merkleRoots;

  // Event declaration
  event ChangedStatusEvent(uint256 newStatus);
  event ChangedBaseURIEvent(string newURI);
  event ChangedMerkleRoot(uint256 status, bytes32 newMerkleRoot);
  event ChangedTeamWallet(address newAddress);

  // Contructor
  constructor(string memory _URI) ERC721("Babies", "Babies") {
    setBaseURI(_URI);
  }

  // Coolman's Universe holders claim
  function claim(uint256[] calldata _ids) external nonReentrant {
    require(tx.origin == msg.sender, "Smart contract interactions disabled");
    require(isClaimActive, "Contract closed");

    uint256 len = _ids.length;
    _claimed += len;

    for (uint256 i = 0; i < len; ++i) {
      uint256 id = _ids[i];
      require(!_exists(id), "Token already claimed");
      require(coolmansUniverse.ownerOf(id) == msg.sender, "Not allowed");
      _mint(msg.sender, id);
    }
  }

  // Mint
  function mint(uint256 _qty, bytes32[] calldata _proof) public payable nonReentrant {
    require(tx.origin == msg.sender, "Smart contract interactions disabled");
    require(status != Status.CLOSED, "Contract closed");
    require(publicIndex + _qty < supply, "Quantity not available");
    require(_qty > 0 && _qty <= maxPerStatus[uint256(status)], "Quantity constraints not satisfied");
    if (status != Status.FREE) {
      require(msg.value == price * _qty, "Price not matched");
    }
    if (status != Status.PUBLIC) {
      checkProof(_proof);
    }

    if (status == Status.FREE) {
      require(!hasMintedFree[msg.sender], "Already minted");
      hasMintedFree[msg.sender] = true;
    } else if (status == Status.ALLOWLIST || status == Status.WAITLIST) {
      require(!hasMintedList[msg.sender], "Already minted");
      hasMintedList[msg.sender] = true;
    } else {
      require(!hasMintedPublic[msg.sender], "Already minted");
      hasMintedPublic[msg.sender] = true;
    }

    uint256 tmpIndex = publicIndex;
    publicIndex += _qty;

    for (uint256 i = 1; i <= _qty; ++i) {
      _mint(msg.sender, tmpIndex + i);
    }
  }

  function teamMint(uint256 _qty) public nonReentrant {
    require(teamWalletAddress != address(0), "No team wallet address found");
    require(msg.sender == teamWalletAddress, "Not allowed");
    require(publicIndex + _qty < supply, "Quantity not available");
    uint256 tmpIndex = publicIndex;
    publicIndex += _qty;
    for (uint256 i = 1; i <= _qty; ++i) {
      _mint(msg.sender, tmpIndex + i);
    }
  }

  // Merkle Proof validation
  function checkProof(bytes32[] calldata _proof) private view {
    require(
      MerkleProof.verify(_proof, merkleRoots[uint256(status)], keccak256(abi.encodePacked(msg.sender))),
      "Not allowed"
    );
  }

  // Getters
  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenExists(uint256 _id) public view returns (bool) {
    return _exists(_id);
  }

  function getIsClaimed(uint256 _id) public view returns (bool) {
    return _exists(_id);
  }

  function getHasMinted(address _address) public view returns (bool) {
    if (status == Status.FREE) {
      return hasMintedFree[_address];
    } else if (status == Status.ALLOWLIST || status == Status.WAITLIST) {
      return hasMintedList[_address];
    } else {
      return hasMintedPublic[_address];
    }
  }

  function claimableBy(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = coolmansUniverse.balanceOf(_owner);
    uint256 counter = 0;

    for (uint256 i = 0; i < tokenCount; i++) {
      uint256 _tokenId = coolmansUniverse.tokenOfOwnerByIndex(_owner, i);
      if (!_exists(_tokenId)) {
        counter++;
      }
    }

    uint256 counter2 = 0;
    uint256[] memory tokensId = new uint256[](counter);
    for (uint256 i = 0; i < tokenCount; i++) {
      uint256 _tokenId = coolmansUniverse.tokenOfOwnerByIndex(_owner, i);
      if (!_exists(_tokenId)) {
        tokensId[counter2] = _tokenId;
        counter2++;
      }
    }
    return tokensId;
  }

  function totalSupply() public view returns (uint256) {
    return _claimed + (publicIndex - claimLastIndex);
  }

  // Setters
  function setBaseURI(string memory _URI) public onlyOwner {
    _baseTokenURI = _URI;
    emit ChangedBaseURIEvent(_URI);
  }

  function setTeamWalletAddress(address _address) public onlyOwner {
    teamWalletAddress = _address;
    emit ChangedTeamWallet(_address);
  }

  function setStatus(uint256 _status) public onlyOwner {
    // _status -> 0: CLOSED, 1: FREE, 2: ALLOWLIST, 3: WAITLIST, 4: PUBLIC
    require(_status >= 0 && _status <= 4, "Mint status must be between 0 and 4");
    status = Status(_status);
    emit ChangedStatusEvent(_status);
  }

  function toggleClaimActive() external onlyOwner {
    isClaimActive = !isClaimActive;
  }

  function setMerkleRoot(bytes32 _merkleRoot, uint256 _status) public onlyOwner {
    // _status -> 0: CLOSED, 1: FREE, 2: ALLOWLIST, 3: WAITLIST, 4: PUBLIC
    require(_status >= 0 && _status <= 4, "Mint status must be between 0 and 4");
    merkleRoots[_status] = _merkleRoot;
    emit ChangedMerkleRoot(_status, _merkleRoot);
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  // Withdraw
  function withdraw(address payable withdrawAddress) external payable nonReentrant onlyOwner {
    require(withdrawAddress != address(0), "Withdraw address cannot be zero");
    require(address(this).balance >= 0, "Not enough eth");
    payable(withdrawAddress).transfer(address(this).balance);
  }
}