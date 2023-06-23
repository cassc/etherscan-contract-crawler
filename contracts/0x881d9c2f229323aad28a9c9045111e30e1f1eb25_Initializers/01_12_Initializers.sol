// SPDX-License-Identifier: MIT
//..........................................................................................................
//.BBBBBBBBBBBBBBBB......LLLLLL..................AAAAAAAA........NNNNNN.......NNNNNN...KKKKK.......KKKKKKK..
//.BBBBBBBBBBBBBBBBBB....LLLLLL..................AAAAAAAA........NNNNNNN......NNNNNN...KKKKK......KKKKKKKK..
//.BBBBBBBBBBBBBBBBBB....LLLLLL.................AAAAAAAAA........NNNNNNNN.....NNNNNN...KKKKK.....KKKKKKKK...
//.BBBBBBBBBBBBBBBBBBB...LLLLLL.................AAAAAAAAAA.......NNNNNNNN.....NNNNNN...KKKKK....KKKKKKKK....
//.BBBBBB.....BBBBBBBB...LLLLLL.................AAAAAAAAAA.......NNNNNNNNN....NNNNNN...KKKKK...KKKKKKKK.....
//.BBBBBB.......BBBBBB...LLLLLL................AAAAAAAAAAA.......NNNNNNNNN....NNNNNN...KKKKK..KKKKKKKK......
//.BBBBBB.......BBBBBB...LLLLLL................AAAAAAAAAAAA......NNNNNNNNNN...NNNNNN...KKKKK..KKKKKKK.......
//.BBBBBB.......BBBBBB...LLLLLL...............AAAAAA.AAAAAA......NNNNNNNNNNN..NNNNNN...KKKKK.KKKKKKK........
//.BBBBBB.....BBBBBBBB...LLLLLL...............AAAAAA.AAAAAA......NNNNNNNNNNN..NNNNNN...KKKKKKKKKKKK.........
//.BBBBBBBBBBBBBBBBBB....LLLLLL...............AAAAAA..AAAAAA.....NNNNNNNNNNNN.NNNNNN...KKKKKKKKKKKKK........
//.BBBBBBBBBBBBBBBBB.....LLLLLL..............AAAAAA...AAAAAA.....NNNNNNNNNNNN.NNNNNN...KKKKKKKKKKKKKK.......
//.BBBBBBBBBBBBBBBBBB....LLLLLL..............AAAAAA...AAAAAAA....NNNNNNNNNNNNNNNNNNN...KKKKKKKKKKKKKK.......
//.BBBBBBBBBBBBBBBBBBB...LLLLLL..............AAAAAA....AAAAAA....NNNNNN.NNNNNNNNNNNN...KKKKKKKKKKKKKKK......
//.BBBBBB.....BBBBBBBBB..LLLLLL.............AAAAAAAAAAAAAAAAA....NNNNNN..NNNNNNNNNNN...KKKKKKK.KKKKKKKK.....
//.BBBBBB........BBBBBB..LLLLLL.............AAAAAAAAAAAAAAAAAA...NNNNNN..NNNNNNNNNNN...KKKKKK...KKKKKKK.....
//.BBBBBB........BBBBBB..LLLLLL.............AAAAAAAAAAAAAAAAAA...NNNNNN...NNNNNNNNNN...KKKKK.....KKKKKKK....
//.BBBBBB........BBBBBB..LLLLLL............AAAAAAAAAAAAAAAAAAA...NNNNNN...NNNNNNNNNN...KKKKK.....KKKKKKK....
//.BBBBBB......BBBBBBBB..LLLLLL............AAAAAA.......AAAAAAA..NNNNNN....NNNNNNNNN...KKKKK......KKKKKKK...
//.BBBBBBBBBBBBBBBBBBBB..LLLLLLLLLLLLLLLLLLAAAAA.........AAAAAA..NNNNNN.....NNNNNNNN...KKKKK......KKKKKKKK..
//.BBBBBBBBBBBBBBBBBBB...LLLLLLLLLLLLLLLLLLAAAAA.........AAAAAA..NNNNNN.....NNNNNNNN...KKKKK.......KKKKKKK..
//.BBBBBBBBBBBBBBBBBB....LLLLLLLLLLLLLLLLLLAAAAA.........AAAAAAA.NNNNNN......NNNNNNN...KKKKK........KKKKKK..
//.BBBBBBBBBBBBBBBBB.....LLLLLLLLLLLLLLLLLLAAAA...........AAAAAA.NNNNNN......NNNNNNN...KKKKK........KKKKKK..
//..........................................................................................................

pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Initializers is ERC721,Ownable {

  string public PROVENANCE = ""; // Stores a hash identifying the order of the metadata/artwork

  uint16 private nextTokenId = 0; // Incremented upon the creation of each token

  uint16 public publicSupplyAvailable = 868; // 868 available to general public
  uint16 public reserveSupplyAvailable = 101; // 101 reserved in treasury
  bool public saleIsActive = true; // Can tokens be purchased?
  bool public openToPublic = false; // Are sales open to the public, or only those whitelisted?
  uint256 public price = 55000000000000000; //0.055 ETH

  // The baseURI token IDs are concatenated to when accessing metadata
  string private baseURIextended = "";

  // The root hash of the Merkle Tree used for our whitelist
  bytes32 public whitelistMerkleRoot;
  // Mapping variable to mark whitelist addresses as having claimed
  // Allows for tracking mints in multiple whitelist phases
  // ie. whitelistClaimed[walletAddress] = whitelistPhase
  uint8 private whitelistPhase = 1;
  mapping(address => uint8) public whitelistPhaseClaimed;

  // The root hash of the Merkle Tree used for our freelist
  bytes32 public freelistMerkleRoot;
  // Mapping variable to mark freelist addresses as having claimed
  mapping(address => bool) public freelistClaimed;

  constructor() ERC721("Initializers", "INIT") {}

  /**
   * @dev Internal token minting function called from all other mint functions
   */
  function mintToken(address to) internal {
    _safeMint(to, nextTokenId);
    nextTokenId = nextTokenId+1;
  }

  /**
   * @dev Allows the contract owner to mint from the reserve
   */
  function reserveMint(address to)
    public
    onlyOwner
    onlyDuringActiveSale
  {
    mintToken(to);
    reserveSupplyAvailable -= 1; // reverts transaction if supply falls below 0
  }

  /**
   * @dev Allows those on the whitelist to mint for a set price
   */
  function whitelistMint(bytes32[] calldata merkleProof)
    public
    payable
    priced
    onlyDuringActiveSale
    onlyWithValidProof(whitelistMerkleRoot, merkleProof)
  {
    require(whitelistPhaseClaimed[msg.sender] < whitelistPhase, "Already claimed");
    whitelistPhaseClaimed[msg.sender] = whitelistPhase;

    mintToken(msg.sender);
    publicSupplyAvailable -= 1; // Reverts transaction if supply falls below 0
  }

  /**
   * @dev Allows those on the freelist to mint for free
   */
  function freeMint(bytes32[] calldata merkleProof)
    public
    onlyDuringActiveSale
    onlyWithValidProof(freelistMerkleRoot, merkleProof)
  {
    require(!freelistClaimed[msg.sender], "Already claimed");
    freelistClaimed[msg.sender]= true;

    mintToken(msg.sender);
    publicSupplyAvailable -= 1; // Reverts transaction if supply falls below 0
  }

  /**
   * @dev Allows anyone to mint if public sale is active
   */
  function publicMint()
    public
    payable
    priced
    onlyDuringActiveSale
    onlyDuringPublicSale
  {
    mintToken(msg.sender);
    publicSupplyAvailable -= 1; // Reverts transaction if supply falls below 0
  }

  // Getter functions
  function totalSupply() public view returns (uint256) {
    return nextTokenId + reserveSupplyAvailable; // Consider reserve tokens always in existence
  }

  // PROVENANCE
  // When the final public mint function call is executed and totalSupply() == 969,
  // (meaning all Initializers are allocated), then:
  //    - The ordering of the "initial sequence" of Initializer art/metadata
  //      (verifiable via the hash stored in PROVENANCE) will be offset by
  //      the transaction's blockNumber % 969. This is handled off-chain.
  //    - setBaseURI() will be called, pointing to the corresponding shifted
  //      metadata/art
  //    - Token metadata/art is revealed

  // Owner functions
  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function setProvenance(string calldata provenance) public onlyOwner {
    PROVENANCE = provenance;
  }

  function setSaleState(bool saleState) public onlyOwner {
    saleIsActive = saleState;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setOpenToPublic(bool isOpen) public onlyOwner {
    openToPublic = isOpen;
  }

  function setFreelistMerkleRoot(bytes32 merkleRoot) public onlyOwner {
    freelistMerkleRoot = merkleRoot;
  }

  function setWhitelistMerkleRoot(bytes32 merkleRoot) public onlyOwner {
    whitelistMerkleRoot = merkleRoot;
  }

  function setWhitelistPhase(uint8 _whitelistPhase) public onlyOwner {
    whitelistPhase = _whitelistPhase;
  }

  // URI functions
  function setBaseURI(string calldata baseURI) external onlyOwner {
      baseURIextended = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURIextended;
  }

  // Modifiers
  modifier onlyDuringActiveSale() {
    require(saleIsActive, "Sale is not active");
      _;
  }

  modifier onlyDuringPublicSale() {
    require(openToPublic, "Public sale closed");
      _;
  }

  /**
   * @dev Requires a provided merkle proof to be verified for the modified function to execute
   */
  modifier onlyWithValidProof(bytes32 root, bytes32[] calldata merkleProof) {
    // Verify the provided proof
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(merkleProof, root, leaf), "Invalid proof");
      _;
  }

  modifier priced() {
    require(msg.value >= price, "Invalid payment amount");
      _;
  }
}