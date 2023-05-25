// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface ICoolCats {
  function ownerOf(uint256 tokenId) external returns (address);
}

//..............................................................................
//..............................................................................
//..............................................................................
//......................................&&&&&&&.................................
//...................................&&****&&***&&&&............................
//..................................&****&....&&***&&...........................
//.................................&&***&&......&&&.............................
//..........................&&&&****&****&*******%&&&...........................
//......................&&*****************************&&.......................
//....................&&*********************************&&.....................
//..................&&***&&&&&***********&&&&&&************&....................
//.................&&**&      &&*******&&      .&**********&&...................
//.................&&*&&   &&  &&*****&&  &&    &&**********&...................
//.................&&*&&      &&*******&&      &&**********&&...................
//..................&&***&&&&***&&&&*&&***&&&&***********(&&....................
//...................&&&*******************************(%&......................
//..................&&&&#*********************************&&&...................
//...............&&&**&&**************************************&&................
//.............&&****&&***********&&****************&&**&******&&...............
//............&&**&&&&***********&&(&&*************/(((&&*******&...............
//...........&&***&&&&((********&%((((&***********(((((&********&&..............
//...........&*&&&&&&&*********&&(((((&&*************&&*******&& &..............
//...........&**&*& &&(*********&&(((&&*************&&****&&& &&&&**#&..........
//............&&&&...&&*****************************&**&& &&********&&..........
//.....................&&&******************************&&******/&&&&...........
//........................&&*******&&%/***************&&&&&&&& &.&&&............
//.........................&&******&&.......&&*******&&.........................
//...........................&&&&&&...........&&&&&&&...........................
//..............................................................................
//..............................................................................
// ........................ [ In memory of Duhtred  ] ..........................
// .............................................................................
contract CoolPets is ERC721, Ownable {
  using ECDSA for bytes32;

  // Addresses
  address public _ccAddress;
  address public _w1 = 0x1fFa3371A45C22B1284fE5a251eD64F40580a1E3;
  address public _systemAddress = address(0);

  // Token mint values
  uint256 public constant MAX_PET_ID = 19999;
  // Track minting outside of Cool Cat ids.
  uint256 public _currentPetId = 9999;
  // for giveaways, staff and partnerships
  uint256 public _reserved = 100;

  bytes32 public _merkleRoot = 0x0;
  uint256 public _price = 0.5 ether;

  bool public _claimsPaused = true;
  bool public _merkleLocked = false;
  string public _baseTokenURI;

  // For bit manipulation
  uint256[] _allowListTicketSlots;

  // Handle public mint access
  enum EPublicMintStatus {
    CLOSED,
    RESERVED_MINT,
    ALLOW_LIST,
    OPEN
  }
  EPublicMintStatus public _publicMintStatus;

  // Tracks if address has minted
  mapping(address => bool) public _minted;

  // Genetics: petId => genetics
  mapping(uint256 => bytes32) public _petGenetics;

  constructor(string memory baseURI, address ccContractAddress) ERC721("Cool Pets", "PETS") {
    _baseTokenURI = baseURI;
    _ccAddress = ccContractAddress;
  }

  /// @notice Adopt via public minting
  /// @dev Id tracking starts at 9999 to prevent id contamination
  /// @dev Signature to help avoid bot minting
  /// @param salt Some simple salting for the signature
  /// @param signature Verify that this transaction came from the desired location
  function publicAdopt(uint256 salt, bytes memory signature) external payable {
    uint256 currentPetId = _currentPetId;
    require(msg.sender == tx.origin, "CP: We like real users");
    require(_publicMintStatus == EPublicMintStatus.OPEN, "CP: Minting closed");
    require(currentPetId < MAX_PET_ID, "CP: Exceeds maximum Pet supply");
    require(msg.value == _price, "CP: Invalid Eth sent");
    require(_minted[msg.sender] == false, "CP: Address has minted a pet");

    // Mark address as minted
    _minted[msg.sender] = true;

    // verify
    require(_isValidSignature(keccak256(abi.encodePacked(msg.sender, salt)), signature), "CP: Invalid signature");

    // Pets bought by non-cat holders will have token ID increasing from 9,999 onwards, after cat and allow list holders
    _mint(msg.sender, currentPetId);

    unchecked {
      currentPetId++;
    }
    _currentPetId = currentPetId;
  }

  /// @notice Adopt via allow list with reference to a ticket number + merkle tree
  /// @dev Id tracking starts at 9999 to prevent id contamination
  /// @dev We could allow contracts to mint but saving gas for users is more important
  /// @dev Dont start ticketNumber at 0
  /// @param merkleProof Merkle proof for verifcation
  /// @param ticketNumber ticket number assigned to user's address
  function allowListAdopt(bytes32[] calldata merkleProof, uint256 ticketNumber) external payable {
    uint256 currentPetId = _currentPetId;
    require(msg.sender == tx.origin, "CP: We like real users");
    require(_publicMintStatus == EPublicMintStatus.ALLOW_LIST, "CP: Allow list closed");
    require(msg.value == _price, "CP: Invalid Eth sent");

    // Merkle magic
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, ticketNumber));
    require(MerkleProof.verify(merkleProof, _merkleRoot, leaf), "CP: Invalid merkle proof");

    // claim ticket
    _claimTicket(ticketNumber);

    // Pets bought by non-cat holders will have token ID increasing from 9,999 onwards
    _mint(msg.sender, currentPetId);

    unchecked {
      currentPetId++;
    }
    _currentPetId = currentPetId;
  }

  /// @notice To check and track ticket numbers being claimed against
  /// @dev Returns error if ticket is larger than range or has been claimed against
  /// @dev Uses bit manipulation in place of mapping
  /// @dev https://medium.com/donkeverse/hardcore-gas-savings-in-nft-minting-part-3-save-30-000-in-presale-gas-c945406e89f0
  /// @param ticketNumber ticket number assigned to user's address
  function _claimTicket(uint256 ticketNumber) internal {
    require(ticketNumber < _allowListTicketSlots.length * 256, "CP: Invalid ticket");

    uint256 storageOffset; // [][][]
    uint256 localGroup; // [][x][]
    uint256 offsetWithin256; // 0xF[x]FFF

    // We can trust the admin arent adding silly numbers - we hope :P
    unchecked {
      storageOffset = ticketNumber / 256;
      offsetWithin256 = ticketNumber % 256;
    }
    localGroup = _allowListTicketSlots[storageOffset];

    // [][x][] > 0x1111[x]1111 > 1
    require((localGroup >> offsetWithin256) & uint256(1) == 1, "CP: Ticket claimed");

    // [][x][] > 0x1111[x]1111 > (1) flip to (0)
    localGroup = localGroup & ~(uint256(1) << offsetWithin256);

    _allowListTicketSlots[storageOffset] = localGroup;
  }

  /// @notice Adopt N pets against cat Ids
  /// @dev Allows for users to select specific cats to claim against
  /// @dev Requires cat ownership to mint
  /// @dev Takes in an array of CC tokenIds to allow option for users with multiple cats to choose which to claim against
  /// @dev Checks tokenIds items against ERC721's _exist(id) function prior to mint
  /// @param tokenIds Array of CC tokenIds to be claimed against
  function adoptNPets(uint256[] memory tokenIds) external {
    require(msg.sender == tx.origin, "CP: We like real users");
    require(!_claimsPaused, "CP: Claiming paused");

    // Check if user is adopting less than 51 pets to avoid gassing out
    require(tokenIds.length < 51, "CP: Adoption limit is 50");

    ICoolCats memCats = ICoolCats(_ccAddress);

    for (uint256 i; i < tokenIds.length; i++) {
      uint256 catId = tokenIds[i];

      // Only cat owner can mint pets that dont already exist for their corresponding cat id
      // Gas loss prevention, for less careful users
      if (memCats.ownerOf(catId) == msg.sender && !_exists(catId)) {
        _mint(msg.sender, catId);
      }
    }
  }

  /// @notice Let Admin mint out 100 pets for giveaways and collabs
  function reservedMint() external onlyOwner {
    uint256 currentPetId = _currentPetId;
    uint256 reserved = _reserved;

    require(_publicMintStatus == EPublicMintStatus.RESERVED_MINT, "CP: Reserved mint closed");
    require(reserved > 0, "CP: No more reserve mints left");

    for (uint256 i; i < 20; i++) {
      _mint(msg.sender, currentPetId++);
    }

    _currentPetId = currentPetId;
    reserved -= 20;
    _reserved = reserved;
  }

  /// @notice Pause claiming of pets by cat holders
  /// @param val True or false
  function pauseClaim(bool val) external onlyOwner {
    _claimsPaused = val;
  }

  /// @notice Change the public minting status
  /// @param status Status to change to
  function setPublicMintStatus(uint256 status) external onlyOwner {
    require(status <= uint256(EPublicMintStatus.OPEN), "CP: Out of bounds");

    _publicMintStatus = EPublicMintStatus(status);
  }

  /// @notice Sets the mint data slot length that tracks the state of tickets
  /// @param num number of tickets available for allow list
  function setMintSlotLength(uint256 num) external onlyOwner {
    // Prevents us from over filling the Allow List
    require(_currentPetId + num <= MAX_PET_ID, "CP: More tickets than pets");

    // account for solidity rounding down
    uint256 slotCount = (num / 256) + 1;

    // set each element in the slot to binaries of 1
    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // create a temporary array based on number of slots required
    uint256[] memory arr = new uint256[](slotCount);

    // fill each element with MAX_INT
    for (uint256 i; i < slotCount; i++) {
      arr[i] = MAX_INT;
    }

    _allowListTicketSlots = arr;
  }

  /// @notice Set baseURI
  /// @param baseURI URI of the pet image server
  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  /// @notice Get uri of tokens
  /// @return string Uri
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /// @notice Set the purchase price of pets
  /// @param newPrice In wei - 10 ** 18
  function setPrice(uint256 newPrice) external onlyOwner {
    _price = newPrice;
  }

  /// @notice Set final genetics of a single pet
  /// @param id Id of the pet in question
  /// @param genes Genetics details of pet in question
  function setGenetics(uint256 id, bytes32 genes) external onlyOwner {
    _petGenetics[id] = genes;
  }

  /// @notice Set the system address
  /// @param systemAddress Address to set as systemAddress
  function setSystemAddress(address systemAddress) external onlyOwner {
    _systemAddress = systemAddress;
  }

  /// @notice Se the Cool Cats contract address
  /// @param ccAddress Address of the Cool Cats contract
  function setCoolCatsAddress(address ccAddress) external onlyOwner {
    _ccAddress = ccAddress;
  }

  /// @notice Set withdrawal address
  /// @param wallet Address of withdrawal target
  function setWithdrawalWallet(address wallet) external onlyOwner {
    _w1 = wallet;
  }

  /// @notice Set new Merkle Root
  /// @param merkleRoot Root of merkle tree
  function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    require(!_merkleLocked, "CP: Merkle tree is locked");
    _merkleRoot = merkleRoot;
  }

  /// @notice Get genetics for this cat - future use (maybe :))
  /// @param id Id of the pet in question
  /// @return genes Genetics of the desired pet
  function getGenetics(uint256 id) external view returns (bytes32 genes) {
    return _petGenetics[id];
  }

  /// @notice Verify hashed data
  /// param hash Hashed data bundle
  /// @param signature Signature to check hash against
  /// @return bool Is verified or not
  function _isValidSignature(bytes32 hash, bytes memory signature) internal view returns (bool) {
    require(_systemAddress != address(0), "CP: Invalid system address");
    bytes32 signedHash = hash.toEthSignedMessageHash();
    return signedHash.recover(signature) == _systemAddress;
  }

  /// @notice Withdraw funds from contract
  function withdraw() external payable onlyOwner {
    payable(_w1).transfer(address(this).balance);
  }

  /// @notice Lock the merkle tree so it can not be edited
  function lockMerkle() external onlyOwner {
    _merkleLocked = true;
  }
}