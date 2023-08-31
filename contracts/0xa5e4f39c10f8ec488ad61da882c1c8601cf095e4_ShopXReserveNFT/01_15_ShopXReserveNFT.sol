// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./helpers/ERC2981ContractWideRoyalties.sol";
import "./helpers/IShopXReserveNFT.sol";

contract ShopXReserveNFT is ERC721A, Ownable, ERC2981ContractWideRoyalties, AccessControl, Pausable {

  bytes32 public merkleRoot;
  address public factory;
  mapping(address => uint256) private claimed;
  string private brand; // Brand Name

  // ERC721
  string private baseURI;// Include '/' at the end. ex) www.shopx.co/nft/
  uint256 public maxSupply;     // Maximum supply of NFT
  uint256 public mintPrice;     // Price in ETH required to mint NFTs (in wei)
  uint256 public mintLimitPerWallet;

  // EIP2981
  // value percentage (using 2 decimals: 10000 = 100.00%, 0 = 0.00%)
  // shopxFee value (between 0 and 10000)
  uint256 public royaltyValue;
  address public royaltyRecipient;

  // SHOPX Settings
  // value percentage (using 2 decimals: 10000 = 100.00%, 0 = 0.00%)
  // shopxFee value (between 0 and 10000)
  address public shopxAddress;
  uint256 public shopxFee;

  // Brand Settings
  address public beneficiaryAddress;

  // Access Control - Admin Roles
  bytes32 public constant SHOPX_ADMIN = keccak256("SHOPX");
  bytes32 public constant BRAND_ADMIN = keccak256("BRAND");
  bytes32 public constant SALE_ADMIN = keccak256("SALE");

  // Events
  event NFTClaim(address indexed _claimant, uint256 indexed _tokenId, uint256 _mintPrice);
  event PriceChange(uint _mintPrice);
  event MerkleRootChange(bytes32 indexed merkleRoot);
  event ShopxAddressUpdate(address indexed _shopxAddress);
  event BeneficiaryAddressUpdate(address indexed _beneficiaryAddress);

  /*
  // Constructor()
  string memory _name,
  string memory _symbol,
  string memory _brand,

  // Initializer()
  // ERC721
  string memory _baseURI,
  uint256 _maxSupply,
  uint256 _mintPrice,
  uint256 _mintLimitPerWallet,

  // EIP2981
  //address _royaltyRecipient,
  //uint256 _royaltyValue,

  // SHOPX Settings
  //address _shopxAddress,
  //uint256 _shopxFee,

  // Brand Settings
  //address _beneficiaryAddress,

  // Grouping arguments to avoid stack too deep (too many arguments) error
  _uintArgs[0]: _maxSupply
  _uintArgs[1]: _mintPrice
  _uintArgs[2]: _mintLimitPerWallet
  _uintArgs[3]: _royaltyValue

  _addressArgs[0]: _royaltyRecipient
  _addressArgs[1]: _beneficiaryAddress
  */

  constructor (
    string memory _name,
    string memory _symbol,
    string memory _brand
  ) ERC721A(_name, _symbol) {
    brand = _brand;
    factory = msg.sender;
  }

  // called once by the factory at time of deployment
  function initialize(
    address _owner,
    string memory _baseURI,
    uint256[4] memory _uintArgs,
    address[2] memory _addressArgs,
    address[] memory _brandAdmins,
    address[] memory _saleAdmins,
    uint256 _shopxFee,
    address _shopxAddress,
    address[] memory _shopxAdmins
  ) external {
    require(msg.sender == factory, "ReserveNFT: FORBIDDEN"); // sufficient check
    transferOwnership(_owner);
    _setBaseURI(_baseURI);
    maxSupply = _uintArgs[0];
    mintPrice = _uintArgs[1]; //in wei
    mintLimitPerWallet = _uintArgs[2];

    // EIP2981
    // value percentage (using 2 decimals: 10000 = 100.00%, 0 = 0.00%)
    // royalties value (between 0 and 10000)
    _setRoyalties(_addressArgs[0], _uintArgs[3]);
    royaltyValue = _uintArgs[3];
    royaltyRecipient = _addressArgs[0];

    // Brand Settings
    beneficiaryAddress = _addressArgs[1];

    // SHOPX Settings
    // value percentage (using 2 decimals: 10000 = 100.00%, 0 = 0.00%)
    // shopxFee value (between 0 and 10000)
    shopxFee = _shopxFee;
    shopxAddress = _shopxAddress;

    // Access Control - Roles
    // _setRoleAdmin(bytes32 role, bytes32 adminRole): Sets adminRole as role's admin role.
    _setRoleAdmin(SHOPX_ADMIN, SHOPX_ADMIN);
    _setRoleAdmin(BRAND_ADMIN, BRAND_ADMIN);
    _setRoleAdmin(SALE_ADMIN, SALE_ADMIN);

    for (uint i = 0; i < _shopxAdmins.length; i++) {
      _setupRole(SHOPX_ADMIN, _shopxAdmins[i]);
    }

    for (uint i = 0; i < _brandAdmins.length; i++) {
      _setupRole(BRAND_ADMIN, _brandAdmins[i]);
    }

    for (uint i = 0; i < _saleAdmins.length; i++) {
      _setupRole(SALE_ADMIN, _saleAdmins[i]);
    }

    _pause(); // initializes in paused state. setMerkleRoot() or unpause() will unpause the contract.
  }

  /**
   * @notice Fails on calls with no `msg.data` but with `msg.value`
     */
  receive() external payable {
    revert("Bad Call: ETH should be sent to mint() function.");
  }

  // -----------------------------------------------------------------------
  // SETTERS
  // -----------------------------------------------------------------------

  function updateShopxAddress (address _shopxAddress) onlyRole(SHOPX_ADMIN) external {
    require(_shopxAddress != address(0), "ReserveX: address zero is not a valid shopxAddress");
    shopxAddress = _shopxAddress;
    emit ShopxAddressUpdate(shopxAddress);
  }

  function updateBeneficiaryAddress (address _beneficiaryAddress) onlyRole(BRAND_ADMIN) external {
    require(_beneficiaryAddress != address(0), "ReserveX: address zero is not a valid beneficiaryAddress");
    beneficiaryAddress = _beneficiaryAddress;
    emit BeneficiaryAddressUpdate(beneficiaryAddress);
  }

  /**
 * @dev Sets the merkle root.
     * @param _merkleRoot The merkle root to set.
     */
  //addToAllowList
  function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(SALE_ADMIN) {
    // Enable this will make setMerkleRoot() only callable if the root is not yet set.
    // require(merkleRoot == bytes32(0), "ReserveNFT: Merkle root already set");
    merkleRoot = _merkleRoot;
    emit MerkleRootChange(_merkleRoot);
    _unpause();
  }

  function setMintPrice(uint256 _mintPrice) onlyRole(SALE_ADMIN) external {
    mintPrice = _mintPrice;
    emit PriceChange(_mintPrice);
  }

  // Grand and Revoke Admin Roles
  function addAdmin(bytes32 _role, address _address) onlyRole(_role) external {
    grantRole(_role, _address);
  }

  function removeAdmin(bytes32 _role, address _address) onlyRole(_role) external {
    revokeRole(_role, _address);
  }

  /**
  * @dev function to set the base URI for all token IDs. It is
    * automatically added as a prefix to the value returned in {tokenURI},
    * or to the token ID if {tokenURI} is empty.
    */
  function setBaseURI(string memory _baseURI) onlyRole(SALE_ADMIN) external {
    _setBaseURI(_baseURI);
  }

  function pause() onlyRole(SALE_ADMIN) external {
    _pause();
  }

  function unpause() onlyRole(SALE_ADMIN) external {
    _unpause();
  }


  // -----------------------------------------------------------------------
  // GETTERS
  // -----------------------------------------------------------------------

  /**
 * @dev Returns the number of NFTs that has been claimed by an address so far.
     * @param _address The address to check.
     */
  function getClaimed(address _address) public view returns (uint256) {
    return claimed[_address];
  }

  /**
    * @dev Returns the balance of the fund 
    */

  function getBalance() public view returns(uint) {
    return address(this).balance;
  }

  function exists(uint256 tokenId) public view returns (bool) {
    return _exists(tokenId);
  }

  /**
  * @dev Returns the name of brand
    */

  function getBrand() public view returns(string memory) {
    return brand;
  }

  /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
  function getBaseURI() public view returns (string memory) {
      return _baseURI();
  } 

  /**
    * @dev totalMintedSupply():Returns the total tokens minted so far.
    * 1 is always subtracted from the Counter since it tracks the next available tokenId.
    *
    * @dev Note. totalSupply() is the count of valid NFTs tracked by this contract, where each one of
    * them has an assigned and queryable owner not equal to the zero address
    * totalSupply(): NFTs minted so far - NFTs burned so far (totalCirculatingSupply)
    * ref: https://eips.ethereum.org/EIPS/eip-721
    * See {IERC721Enumerable-totalSupply}
    */
  function totalMintedSupply() public view returns (uint256) {
    return _totalMinted();
  }

  function getShopXFee() public view returns (uint256) {
    return shopxFee;
  }

  /**
    * @dev Gets info about line nft
    */
  function getInfo() public view returns (
    uint256 _balance,
    uint256 _maxSupply,
    uint256 _totalSupply,
    uint256 _totalMintedSupply,
    uint256 _mintPrice,
    uint256 _mintLimitPerWallet,
    bool _paused,
    address _royaltyRecipient,
    address _shopxAddress,
    address _beneficiaryAddress,
    uint256 _royaltyValue,
    uint256 _shopxFee ) {
    return (
      getBalance(),
      maxSupply,
      totalSupply(),
      totalMintedSupply(),
      mintPrice,
      mintLimitPerWallet,
      paused(),
      royaltyRecipient,
      shopxAddress,
      beneficiaryAddress,
      royaltyValue,
      shopxFee
    );
  }
  // -----------------------------------------------------------------------
  // Royalties
  // -----------------------------------------------------------------------

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981Base, AccessControl) returns (bool) {
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981Base.supportsInterface(interfaceId) ||
      AccessControl.supportsInterface(interfaceId);

  }

  /// @notice Allows to set the royalties on the contract
  /// @dev This function in a real contract should be protected with a onlyOwner (or equivalent) modifier
  /// @param recipient the royalties recipient
  function updateRoyaltyAddress(address recipient) onlyRole(BRAND_ADMIN) external {
    require(recipient != address(0), "ReserveX: address zero is not a valid royalty recipient");
    _setRoyalties(recipient, royaltyValue);
  }

  // -----------------------------------------------------------------------
  // NFT
  // -----------------------------------------------------------------------

  /**
* @dev Mints a token to the msg.sender. It consumes whitelisted supplies.
    */
  function mint(bytes32[] calldata merkleProof, uint256 quantity) payable external whenNotPaused {
    require(totalSupply() + quantity <= maxSupply, "NotEnoughNFT: NFT supply not available");
    require(claimed[msg.sender] + quantity <= mintLimitPerWallet, "ReserveNFT: NFTs already claimed.");
    require(msg.value == mintPrice * quantity, "WrongETHAmount: More or less than the required amount of ETH sent.");
    require (merkleRoot == bytes32(0) || MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "ReserveNFT: Invalid Proof. Valid proof required.");

    // Mark it claimed and send the NFT
    claimed[msg.sender] += quantity;

    // Mint
    _safeMint(msg.sender, quantity);
    for (uint i = 0; i < quantity; i++) {
      emit NFTClaim(msg.sender, _nextTokenId()-quantity+i, mintPrice);
    }

    // Fee
    payable(shopxAddress).transfer(this.getBalance()*shopxFee/10000);

    // Sweep
    payable(beneficiaryAddress).transfer(this.getBalance());
  }

  /**
    * @dev Mints a token to an address with a tokenURI.
    * @param to address of the future owner of the token.
    */  
  function mintTo(address to, uint256 quantity) external whenNotPaused onlyRole(SALE_ADMIN)  {
    require(totalSupply() + quantity <= maxSupply, "NotEnoughNFT: NFT supply not available");

    // Mint
    _safeMint(to, quantity);
  }

  /**
 * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
  function burn(uint256 tokenId) external {
    _burn(tokenId, true);
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  /**
   * @dev Returns the starting token ID.
   * To change the starting token ID, please override this function.
   */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
    * @dev function to set the base URI for all token IDs. It is
    * automatically added as a prefix to the value returned in {tokenURI},
    * or to the token ID if {tokenURI} is empty.
    */   
  function _setBaseURI(string memory baseURI_) internal {
    baseURI = baseURI_;
  }

  /**
    * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
    * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
    * by default, can be overriden in child contracts.
    */
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

}