// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./helpers/ERC2981ContractWideRoyalties.sol";
import "./helpers/IShopXReserveNFT.sol";


contract ShopXReserveNFT is ERC721A, Ownable, ERC2981ContractWideRoyalties, AccessControl, Pausable, ReentrancyGuard {

  bytes32 public merkleRoot;
  address public factory;
  uint256 public configId;
  mapping(address => uint256) private claimed;
  string public brand; // Brand Name

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

  // Platform Settings
  uint256 public platformFee;
  address public platformAddress;

  // Platform Settings
  uint256 public agencyFee;
  address public agencyAddress;

  // Brand Settings
  address[] public beneficiaryAddresses;
  uint256[] public beneficiaryFees;

  // CrossMint
  address public crossmintAddress;

  // Access Control - Admin Roles
  bytes32 public constant SHOPX_ADMIN = keccak256("SHOPX");
  bytes32 public constant BRAND_ADMIN = keccak256("BRAND");
  bytes32 public constant SALE_ADMIN = keccak256("SALE");

  // Events
  event NFTClaim(address indexed _claimant, uint256 indexed _tokenId, uint256 _mintPrice);
  event PriceChange(uint _mintPrice);
  event MerkleRootChange(bytes32 indexed merkleRoot);
  event ShopxAddressUpdate(address indexed _shopxAddress);

  event PlatformAddressUpdate(address indexed _platformAddress);
  event AgencyAddressUpdate(address indexed _agencyAddress);
  event BeneficiaryAddressUpdate(uint256 beneficiaryIndex, address indexed _beneficiaryAddress);
  event CrossmintAddressUpdate(address indexed _crossmintAddress);

/*
  // Constructor()
  string memory _name,
  string memory _symbol,
  string memory _brand,
*/

  constructor (
    string memory _name,
    string memory _symbol,
    string memory _brand
  ) ERC721A(_name, _symbol) {
    brand = _brand;
    factory = msg.sender;
  }

  /*
    // Initializer()
    string memory _baseURI,

    // Grouping arguments to avoid stack too deep (too many arguments) error
    _uintArgs[0]: _configId
    _uintArgs[1]: _maxSupply
    _uintArgs[2]: _mintPrice
    _uintArgs[3]: _mintLimitPerWallet
    _uintArgs[4]: _royaltyValue
    _uintArgs[5]: _shopxFee
    _uintArgs[6]: _platformFee
    _uintArgs[7]: _agencyFee

    _addressArgs[0]: _owner
    _addressArgs[1]: _royaltyRecipient
    _addressArgs[2]: _shopxAddress
    _addressArgs[3]: _platformAddress
    _addressArgs[4]: _agencyAddress

    _beneficiaryFees[]: beneficiary1, beneficiary2, ...
    _beneficiaryAddresses[]: beneficiary1, beneficiary2, ...
    */
  // called once by the factory at time of deployment
  function initialize(
    string memory _baseURI,
    uint256[8] memory _uintArgsX,
    address[5] memory _addressArgsX,
    uint256[] memory _beneficiaryFees,
    address[] memory _beneficiaryAddresses,
    address[] memory _brandAdmins,
    address[] memory _saleAdmins,
    address[] memory _shopxAdmins
  ) external {
    require(msg.sender == factory); // sufficient check
    transferOwnership(_addressArgsX[0]);
    _setBaseURI(_baseURI);

    configId = _uintArgsX[0];
    maxSupply = _uintArgsX[1];
    mintPrice = _uintArgsX[2]; //in wei
    mintLimitPerWallet = _uintArgsX[3];

    // EIP2981
    // value percentage (using 2 decimals: 10000 = 100.00%, 0 = 0.00%)
    // royalties value (between 0 and 10000)
    _setRoyalties(_addressArgsX[1], _uintArgsX[4]);
    royaltyValue = _uintArgsX[4];
    royaltyRecipient = _addressArgsX[1];

    // SHOPX Settings
    // value percentage (using 2 decimals: 10000 = 100.00%, 0 = 0.00%)
    // shopxFee value (between 0 and 10000)
    shopxFee = _uintArgsX[5];
    shopxAddress = _addressArgsX[2];

    // Platform Settings
    platformFee = _uintArgsX[6];
    platformAddress = _addressArgsX[3];

    // Agency Settings
    agencyFee = _uintArgsX[7];
    agencyAddress = _addressArgsX[4];

    // Brand Settings
    for (uint i = 0; i < _beneficiaryAddresses.length; i++) {
      beneficiaryFees.push(_beneficiaryFees[i]);
      beneficiaryAddresses.push(_beneficiaryAddresses[i]);
    }

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
    revert();
  }

  // -----------------------------------------------------------------------
  // SETTERS
  // -----------------------------------------------------------------------

  function updateShopxAddress (address _shopxAddress) onlyRole(SHOPX_ADMIN) external {
    require(_shopxAddress != address(0));
    shopxAddress = _shopxAddress;
    emit ShopxAddressUpdate(shopxAddress);
  }

  function updatePlatformAddress (address _platformAddress) onlyRole(SHOPX_ADMIN) external {
    require(_platformAddress != address(0));
    platformAddress = _platformAddress;
    emit PlatformAddressUpdate(platformAddress);
  }

  function updateAgencyAddress (address _agencyAddress) onlyRole(SHOPX_ADMIN) external {
    require(_agencyAddress != address(0));
    agencyAddress = _agencyAddress;
    emit AgencyAddressUpdate(agencyAddress);
  }

  function updateBeneficiaryAddress (uint256 _beneficiaryIndex, address _beneficiaryAddress) onlyRole(BRAND_ADMIN) external {
    require(_beneficiaryAddress != address(0));
    beneficiaryAddresses[_beneficiaryIndex] = _beneficiaryAddress;
    emit BeneficiaryAddressUpdate(_beneficiaryIndex, _beneficiaryAddress);
  }

  function updateCrossmintAddress (address _crossmintAddress) onlyRole(SHOPX_ADMIN) external {
    require(_crossmintAddress != address(0));
    crossmintAddress = _crossmintAddress;
    emit CrossmintAddressUpdate(crossmintAddress);
  }

  /**
 * @dev Sets the merkle root.
     * @param _merkleRoot The merkle root to set.
     */
  function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(SHOPX_ADMIN) {
    if (!paused()) _pause();
    merkleRoot = _merkleRoot;
    emit MerkleRootChange(_merkleRoot);
    _unpause();
  }

  function setFCFS() external onlyRole(SHOPX_ADMIN) {
    if (!paused()) _pause();
    merkleRoot = bytes32(0);
    emit MerkleRootChange(bytes32(0));
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

  function destroySmartContract(address _caller, address payable _to) external {
    require(msg.sender == factory);
    require(hasRole(SHOPX_ADMIN, _caller) == true);
    selfdestruct(_to);
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
  /*
  function updateRoyaltyAddress(address recipient) onlyRole(BRAND_ADMIN) external {
    require(recipient != address(0));
    _setRoyalties(recipient, royaltyValue);
  }
  */

  // -----------------------------------------------------------------------
  // NFT
  // -----------------------------------------------------------------------

  /**
* @dev Mints a token to the msg.sender. It consumes whitelisted supplies.
    */
  function mint(bytes32[] calldata merkleProof, uint256 quantity) payable external whenNotPaused nonReentrant {
    require(totalSupply() + quantity <= maxSupply);
    require(claimed[msg.sender] + quantity <= mintLimitPerWallet);
    require(msg.value == mintPrice * quantity);
    require (merkleRoot == bytes32(0) || MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))));

    // Mark it claimed and send the NFT
    claimed[msg.sender] += quantity;

    // Mint
    _safeMint(msg.sender, quantity);
    for (uint i = 0; i < quantity; i++) {
      emit NFTClaim(msg.sender, _nextTokenId()-quantity+i, mintPrice);
    }

    uint256 balance = msg.value;
    // Call returns a boolean value indicating success or failure.

    // ShopX Fee
    if (shopxFee != 0) {
      (bool shopxFeeSent, ) = payable(shopxAddress).call{ value: balance*shopxFee/10000 }('');
      require(shopxFeeSent);
    }

    // Platform Fee
    if (platformFee != 0) {
      (bool platformFeeSent, ) = payable(platformAddress).call{ value: balance*platformFee/10000 }('');
      require(platformFeeSent);
    }

    // Agency Fee
    if (agencyFee != 0) {
      (bool agencyFeeSent, ) = payable(agencyAddress).call{ value: balance*agencyFee/10000 }('');
      require(agencyFeeSent);
    }

    // Beneficiaries
    for (uint i = 0; i < beneficiaryAddresses.length - 1; i++) {
      (bool sent, ) = payable(beneficiaryAddresses[i]).call{ value: balance*beneficiaryFees[i]/10000 }('');
      require(sent);
    }

    // Sweep to the last beneficiaryAddress
    (bool sweepSent, ) = payable(beneficiaryAddresses[beneficiaryAddresses.length-1]).call{ value: this.getBalance() }('');
    require(sweepSent);
  }

  /**
    * @dev Mints a token to an address with a tokenURI.
    * @param to address of the future owner of the token.
    */  
  function mintTo(address to, uint256 quantity) external whenNotPaused onlyRole(SALE_ADMIN) nonReentrant {
    require(totalSupply() + quantity <= maxSupply);

    // Mint
    _safeMint(to, quantity);
  }

  /**
  * @dev Only allowed for CrossMint. Mints a token to an address but also checks if the destination address is in the allowList.
    * @param to address of the future owner of the token.
    */
  function crossMint(bytes32[] calldata merkleProof, address to, uint256 quantity) payable external whenNotPaused nonReentrant {
    require(msg.sender == crossmintAddress);
    require(totalSupply() + quantity <= maxSupply);
    require(claimed[to] + quantity <= mintLimitPerWallet);
    require(msg.value == mintPrice * quantity);
    require (merkleRoot == bytes32(0) || MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(to))));

    // Mark it claimed and send the NFT
    claimed[to] += quantity;

    // Mint
    _safeMint(to, quantity);
    for (uint i = 0; i < quantity; i++) {
      emit NFTClaim(to, _nextTokenId()-quantity+i, mintPrice);
    }

    uint256 balance = msg.value;
    // Call returns a boolean value indicating success or failure.

    // ShopX Fee
    if (shopxFee != 0) {
      (bool shopxFeeSent, ) = payable(shopxAddress).call{ value: balance*shopxFee/10000 }('');
      require(shopxFeeSent);
    }

    // Platform Fee
    if (platformFee != 0) {
      (bool platformFeeSent, ) = payable(platformAddress).call{ value: balance*platformFee/10000 }('');
      require(platformFeeSent);
    }

    // Agency Fee
    if (agencyFee != 0) {
      (bool agencyFeeSent, ) = payable(agencyAddress).call{ value: balance*agencyFee/10000 }('');
      require(agencyFeeSent);
    }

    // Beneficiaries
    for (uint i = 0; i < beneficiaryAddresses.length - 1; i++) {
      (bool sent, ) = payable(beneficiaryAddresses[i]).call{ value: balance*beneficiaryFees[i]/10000 }('');
      require(sent);
    }

    // Sweep to the last beneficiaryAddress
    (bool sweepSent, ) = payable(beneficiaryAddresses[beneficiaryAddresses.length-1]).call{ value: this.getBalance() }('');
    require(sweepSent);
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