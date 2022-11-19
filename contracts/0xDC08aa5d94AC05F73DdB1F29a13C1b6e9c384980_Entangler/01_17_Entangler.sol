// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Included for marketplaces
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// =============================================================================
// =============================== STRUCTS =====================================
/**
* @notice The TokenType struct holds all the data that defines a collection of
* tokens within this contract
* @param id  The id of the collection
* @param supplyCap  The total number of tokens of the collection type that can
* exist
* @param cost  The cost to mint a token of the collection
* @param initialMintAmount  The amount of tokens to premint when the collection
* is created
* @param defaultStorageSchema  The default location/protocol used to store and
* retrieve the metadata of tokens in the collection
* @param totalSupply  The total circulating supply of the collection (i.e. the
* amount of tokens that have been minted from the collection so far)
* @param maxMultiplier  Nft collections that are part of this contract pay
* royalties to their beneficaries (charitable organizations that align with the
* collection's mandates). A multiplier can be applied to the royalty values so
* that a higer portion of a transaction goes to the beneficaries and less goes
* to the other recipient of the transaction. The max multiplier ensures that the
* multiplier never causes the royalty protion to be more than 100% of the
* transaction's value
* @param maxMint  The max number of tokens that can be minted from the collection
* in a single mint transaction
* @param fungible  True if it is a collection of fungible tokens, false if it
* is a collection of non-fungible tokens
* @param locked  True if the collection has been locked, false if it has not been.
* When a collection has been locked its supplyCap, cost, maxMint and mintable
* values can no longer be modified
* @param initialMintTo  Recipient of premint tokens
* @param mandates  Mandates that define the mission/purpose of a collection
* @param baseUris  The uri strings for retrieving the metadata of the tokens in
* the collection. Follows the erc1155 id substitution format
*/
struct TokenType {
  uint256 id;
  uint256 supplyCap;
  uint256 cost;
  uint256 initialMintAmount;
  string defaultStorageSchema;
  uint256 totalSupply;
  uint256 maxMultiplier;
  uint256 maxMint;
  bool fungible;
  bool mintable;
  bool locked;
  address initialMintTo;
  Mandate[] mandates;
  mapping(string => string[]) baseUris;
}

/**
* @notice Mandates define the purpose around which a colection of nfts is aligned
* @param description  A description of the cause that the mandate supports
* @param receiver  The ethereum address that's used for collecting funds that
* will be used for supporting charitable organizations whose work is aligned with
* the purpose of the mandate
*/
struct Mandate {
  string description;
  address payable receiver;
}

/**
* @dev  Data format that is passed to the contract to create new collections
*/
struct NewTokenType {
  uint256 id;
  uint256 supplyCap;
  uint256 cost;
  uint256 initialMintAmount;
  string defaultStorageSchema;
  uint256 maxMultiplier;
  uint256 maxMint;
  bool fungible;
  bool mintable;
  bool locked;
  address initialMintTo;
  Mandate[] mandates;
}


// =============================================================================
// ================== LIBRARY FOR CREATING NEW TOKEN TYPES =====================
library TokenTypeLib {
  function createTokenType(
    TokenType storage self,
    NewTokenType memory newTokenType,
    string[] calldata startingStorageSchemas,
    string[] calldata startingBaseUris
  ) public {
    self.id = newTokenType.id;
    self.fungible = newTokenType.fungible;
    self.supplyCap = newTokenType.supplyCap;
    self.cost = newTokenType.cost;
    self.mintable = newTokenType.mintable;
    self.maxMultiplier = newTokenType.maxMultiplier;
    self.maxMint = newTokenType.maxMint;
    self.initialMintTo = newTokenType.initialMintTo;
    self.initialMintAmount = newTokenType.initialMintAmount;
    self.defaultStorageSchema = newTokenType.defaultStorageSchema;
    self.locked = newTokenType.locked;

    // Set the mandates of the new token type
    for(uint i = 0; i < newTokenType.mandates.length; i++) {
      Mandate memory m;

      m.description = newTokenType.mandates[i].description;
      m.receiver = newTokenType.mandates[i].receiver;

      self.mandates.push(m);
    }

    // Set the storage schema mappings for the new token type
    for(uint i = 0; i < startingStorageSchemas.length; i++) {
      self.baseUris[startingStorageSchemas[i]].push(string(abi.encodePacked(startingBaseUris[i], '{id}.json')));
    }
  }
}


// =============================================================================
// ============================ CORE CONTRACT ==================================
contract Entangler is ERC1155, ERC1155Receiver, IERC2981, AccessControl, Ownable {
  using TokenTypeLib for TokenType;

  /* Mapping of collection ids (typeId) to the data that defines that collection */
  mapping(uint256 => TokenType) public tokenTypes;

  /**
  * Sequential records of the transaction logs that were used to tally up the
  * amounts due to beneficiries
  */
  string[] public beneficiaryAccountingRecords;

  /**
  * The merkle root against which beneficiries can claim their allocations of
  * funds
  */
  bytes32 public claimsMerkleRoot;

  /* List of claims that have been redeemed so that they can't be redeemed again */
  mapping(bytes32 => bool) beneficaryFundsClaimed;

  /**
  * This is the deliminator in a non-fungible token id. Numbers in digits 1-7
  * repersent individual token ids. Numbers from the 8th digit onward denote the
  * collection to which the individual token belongs
  */
  uint256 constant public supplyCapPerTokenType = 10000000;

  /**
  * Token ids can be no larger than this value. The length of this value is
  * also the number of digits that must be reverved for token ids in the least
  * significant digits of a value that is being sent to this contract as a
  * royalty payment so that the payment can be attributed the nft which it
  * involves
  */
  uint256 public tokenIdSpace;

  /* Percentages are calculated in basis points (10000bps = 100%) */
  uint256 constant public percentDenominator = 10000;

  /**
  * Current amount that third parties have stored in the contract and can
  * withdraw at any time
  */
  mapping(address => uint256) public withdrawalAmounts;

  /**
  * The royalty amounts of each nft, in basis points. Each of the token's
  * royalties correspond to the mandates of the collection to which the token
  * belongs
  */
  mapping(uint => uint16[]) public royalties;

  /**
  * Beneficary withdrawals will need to be paused for the time inbetween taking
  * a snapshot to determine new withdrawal amounts and the commitment of the new
  * merkle tree root
  */
  bool public beneficaryWithdrawalsPaused = false;

  /* Address used by the contract owner to withdraw mint payments from the contract */
  address payable ownerWithdrawalAddress;

  /* Uri of the contract level metadata */
  string public contractUri;


  // =============================== ROLES =====================================
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
  bytes32 public constant ACCOUNTANT_ROLE = keccak256("ACCOUNTANT_ROLE");
  bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");


  // =============================== EVENTS ====================================
  /**
  * @dev  The royaltyReceived event will be emitted any time that ether is sent
  * to this contract that is intended as a royalty payment to be donated to the
  * beneficaries of an nft. Attribution of which nfts are responsiable for which
  * payments is done off-chain using these events. In order to tell which nft is
  * responsible for the donation, the id of the nft must be included in the least
  * significant digits of the value of the transaction
  */
  event royaltyReceived(uint256 indexed amount);

  /**
  * @dev  Erc1155 royalty received events are used for the same purpose as base
  * ether royalty received events, except that the id of the nft involved can be
  * explicitly included in the data field of the transaction in which case
  * including the nfts id in the value of the transaction is not necessary
  */
  event erc1155RoyaltyReceived(address indexed contractAddress, uint256 indexed token, uint256 indexed amount, bytes id);
  event erc1155BatchRoyaltyReceived(address indexed contractAddress, uint256[] tokens, uint256[] amounts, bytes ids);

  /**
  * @dev  Royalty withdrawn events are used to monitor when beneficaries have
  * claimed their funds from the contract so that any unclaimed allotments can
  * be rolled over into the next merkle tree of claims
  */
  event royaltyWithdrawn(address indexed beneficary, uint256 indexed amount);
  event erc20RoyaltyWithdrawn(address indexed contractAddress, address indexed beneficary, uint256 indexed amount);
  event erc1155RoyaltyWithdrawn(address indexed contractAddress, uint256 indexed token, address indexed beneficary, uint256 amount);

  /**
  * @dev  The beneficaryClaimsUpdated event signals that a new merkle tree root
  * has been committed to the contract and there may be new allotments that
  * beneficaries can claim
  */
  event beneficaryClaimsUpdated(bytes32 indexed merkleRoot, uint256 indexed accountsRecordIndex);

  /**
  * @dev  The tokenIdSpaceChanged event signals that the length of the token id
  * space has changed. As a result the number of digits that must be reserved for
  * token ids in the value of transactions must be updated accordingly
  */
  event tokenIdSpaceChanged(uint256 indexed newTokenIdSpace);

  /**
  * @notice  The storageSchemaAdded event signals that a new storage schema for
  * metadata has been added to a collection
  */
  event storageSchemaAdded(uint256 typeId, string storageSchema);


  // ============================= MODIFIERS ===================================
  /**
  * @notice  Checks to make sure that a mint request is valid as per the rules of
  * this contract and the rules of the collection to which the tokens belong
  * @param typeId  Specifies the collection to mint from
  * @param count  The number of tokens to be minted
  */
  modifier preMintChecks(uint256 typeId, uint256 count) {
    require(tokenTypes[typeId].mintable, "Token not currently mintable");
    require(count > 0, "Mint amount cannot be less than one");
    require(count <= tokenTypes[typeId].maxMint, "Mint amount too high");
    require(tokenTypes[typeId].totalSupply + count <= tokenTypes[typeId].supplyCap, "Mint amount exceeds total supply of the token type");
    require(msg.value == tokenTypes[typeId].cost * count, "Not enough or too many funds provided");
    _;
  }

  /**
  * @notice  Checks to make sure that a new collection can be validly created
  */
  modifier tokenCreationChecks(
    NewTokenType memory newTokenType,
    string[] calldata startingStorageSchemas,
    string[] calldata startingBaseUris
  ) {
    require(tokenTypes[newTokenType.id].totalSupply == 0, "This typeId has already been set");
    require(tokenTypes[newTokenType.id].supplyCap == 0, "Token type has already been initialized");
    require(startingStorageSchemas.length == startingBaseUris.length, "Each uri schema must be initialized");
    require(newTokenType.id % supplyCapPerTokenType == 0, "Token type id invalid");

    if(!newTokenType.fungible) {
      require(newTokenType.supplyCap < supplyCapPerTokenType, "Cannot exceed the universal supply cap of this contract");
    }
    _;
  }

  /**
  * @notice  Checks that everything is valid when setting the royalties of a token
  * @param tokenId  Id of the token for which to set royalties
  * @param _royalties  Array of royalty values to be set. One royalty value per
  * beneficary of the collection to which the token belongs. Royalty values are
  * in basis points
  */
  modifier setTokenRoyaltiesCheck(uint256 tokenId, uint16[] calldata _royalties) {
    uint256 typeId = (tokenId / supplyCapPerTokenType) * supplyCapPerTokenType;
    require(tokenTypes[typeId].mandates.length == _royalties.length, "Tokens must pay all the beneficaries of their type");
    require(!tokenTypes[typeId].fungible, "Only non fungible tokens pay royalties");
    require(royalties[tokenId].length == 0, "A tokens royalties can only ever be set once");
    tokenId = tokenId - typeId;
    require(tokenId < tokenTypes[typeId].totalSupply, "Token has not been minted yet");

    for(uint i = 0; i < _royalties.length; i++) {
      require(_royalties[i] < uint16(percentDenominator), "Maximum royalty is 10000 basis points (100%)");
    }
    _;
  }

  /**
  * @notice  Ensures that certain parameters of a collection are no longer mutable
  * after that collection has been locked
  * @param typeId  Id of the collection
  */
  modifier isLocked(uint256 typeId) {
    require(!tokenTypes[typeId].locked);
    _;
  }

  /**
  * @notice  Pauses the ability to make withdrawals via merkle tree proof. This
  * is needed so that unclaimed amounts included in one merkle tree root can be
  * rolled into the next merkle tree root without risk of the funds being claimed
  * in the time between the creation of the mew merkle root and its commitment
  * to the contract. If this were to happen, the funds could be claimed twice;
  * once using the first merkle tree root and once using the second merkle tree
  * root
  */
  modifier withdrawalsPaused() {
    require(!beneficaryWithdrawalsPaused, "Beneficary withdrawals are paused for a snapshot");
    _;
  }

  // ===========================================================================
  // ========================== CORE FUNCTIONS =================================
  constructor(
    string memory defaultUri,
    address defaultAdminAddress,
    address operatorAddress,
    address lockerAddress,
    address accountantAddress,
    address payable _ownerWithdrawalAddress,
    uint256 _tokenIdSpace,
    string memory _contractUri
  )
    ERC1155(defaultUri)
  {
    _grantRole(DEFAULT_ADMIN_ROLE, defaultAdminAddress);
    _grantRole(OPERATOR_ROLE, operatorAddress);
    _grantRole(LOCKER_ROLE, lockerAddress);
    _grantRole(ACCOUNTANT_ROLE, accountantAddress);

    ownerWithdrawalAddress = _ownerWithdrawalAddress;
    tokenIdSpace = _tokenIdSpace;
    contractUri = _contractUri;

    emit tokenIdSpaceChanged(tokenIdSpace);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155, ERC1155Receiver, AccessControl, IERC165)
    returns (bool)
  {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
  * @notice  Mints tokens of the specified collection
  * @param to  The address that the tokens will be minted to
  * @param typeId  The nft collection to mint from
  * @param count  The number of nfts to mint
  */
  function mint(address to, uint256 typeId, uint256 count)
    public
    payable
    preMintChecks(typeId, count)
  {
    if(tokenTypes[typeId].fungible) {
      tokenTypes[typeId].totalSupply += count;
      _mint(to, typeId, count, "");
    } else {
      for(uint i = 0; i < count; i++) {
        uint256 tokenId = typeId + tokenTypes[typeId].totalSupply;
        tokenTypes[typeId].totalSupply++;
        _mint(to, tokenId, 1, "");
      }
    }
  }


  // ============================== PAYMENTS ===================================
  /**
  * @notice  This function will be called if ether is sent directly to the
  * contract (as opposed to sending ether to the contract by calling a specific
  * function of the contract). If the nft id has been properly included in the
  * least significant digits of the value of the transaction, the full value of
  * the transaction will be attributed to that nft
  */
  receive() external payable {
    emit royaltyReceived(msg.value);
  }

  /**
  * @dev  Allows for transactions involving an nft to be split so that royalty
  * payments are made and the rest of the value is stored in the contract and
  * can be withdrawn by the recipient of the transaction at any time (ex. an
  * nft has been incorporated into a game. An in-game purchase involving the nft
  * is made. The nfts royalties are taken from the transaction and the rest of
  * the value is stored in this contract to be claimed at any time by the game's
  * developer)
  */
  function payWithRoyalties(uint256 tokenId, address recipient, uint256 multiplier)
    external
    payable
  {
    require(royalties[tokenId].length > 0, 'Token royalties not set');
    require(msg.value >= tokenId, 'Value must be at least the tokenId');

    uint256 typeId = (tokenId / supplyCapPerTokenType) * supplyCapPerTokenType;

    require(multiplier >= 1, "Multiplier too low");
    require(multiplier <= tokenTypes[typeId].maxMultiplier, "Multiplier too high");

    uint256 amountWithMultiplier = msg.value * multiplier;
    (, uint256 royaltyAmount) = royaltyInfo(tokenId, amountWithMultiplier);

    require(msg.value >= royaltyAmount);

    withdrawalAmounts[recipient] += msg.value - royaltyAmount;

    emit royaltyReceived(royaltyAmount);
  }

  /**
  * @dev  Allows third parties to withdraw their ether from the contract.
  * Withdraws the total amount of ether that they currently have waiting for
  * them in the contract
  * @param withdrawalAddress  The address of the party with ether stored in the
  * contract
  */
  function withdraw(address withdrawalAddress) external {
    require(withdrawalAmounts[withdrawalAddress] > 0, "Account does not have any ether allocated to it");

    uint256 withdrawalAmount = withdrawalAmounts[withdrawalAddress];
    withdrawalAmounts[withdrawalAddress] = 0;

    payable(withdrawalAddress).transfer(withdrawalAmount);
  }

  /**
  * @dev  Allows beneficaries to withdraw ether from the contract using a merkle
  * proof. The parameters must match the values that were included in the merkle
  * tree
  * @param beneficary  The address where the beneficary's funds will be sent
  * @param amount  The amount of ether to be transferred
  * @param merkleProof  The merkle proof containing sibling hashes on the branch
  * from the leaf that is being claimed to the root of the merkle tree
  */
  function withdraw(address beneficary, uint256 amount, bytes32[] calldata merkleProof)
    external
    withdrawalsPaused()
  {
    bytes32 leaf = keccak256(abi.encodePacked(beneficary, amount));
    bytes32 claimReceipt = keccak256(abi.encodePacked(leaf, claimsMerkleRoot));

    require(!beneficaryFundsClaimed[claimReceipt], "Claim already made");
    require(MerkleProof.verify(merkleProof, claimsMerkleRoot, leaf), "Merkle proof failed");

    beneficaryFundsClaimed[claimReceipt] = true;
    emit royaltyWithdrawn(beneficary, amount);

    payable(beneficary).transfer(amount);
  }

  /**
  * @dev  Allows beneficaries to withdraw erc20 tokens from the contract using a
  * merkle tree proof. The parameters must match the values that were included in
  * the merkle tree
  * @param beneficary  The address where the beneficary's funds will be sent
  * @param contractAddress  The address of the erc20 contract that administers
  * the tokens being used in the transaction
  * @param amount  The amount of the token to be transferred
  * @param merkleProof  The merkle proof containing sibling hashes on the branch
  * from the leaf that is being claimed to the root of the merkle tree
  */
  function withdrawErc20(address beneficary, address contractAddress, uint256 amount, bytes32[] calldata merkleProof)
    external
    withdrawalsPaused()
  {
    bytes32 leaf = keccak256(abi.encodePacked(beneficary, contractAddress, amount));
    bytes32 claimReceipt = keccak256(abi.encodePacked(leaf, claimsMerkleRoot));

    require(!beneficaryFundsClaimed[claimReceipt], "Claim already made");
    require(MerkleProof.verify(merkleProof, claimsMerkleRoot, leaf), "Merkle proof failed");

    beneficaryFundsClaimed[claimReceipt] = true;
    emit erc20RoyaltyWithdrawn(contractAddress, beneficary, amount);

    require(IERC20(contractAddress).transfer(beneficary, amount));
  }

  /**
  * @dev  Allows beneficaries to withdraw erc1155 tokens from the contract using
  * a merkle tree proof. The parameters must match the values that were included
  * in the merkle tree
  * @param beneficary  The address where the beneficary's funds will be sent
  * @param contractAddress  The address of the erc1155 contract that administers
  * the tokens being used in the transaction
  * @param token  The specific token of the erc1155 contract that is to be used
  * in this transaction
  * @param amount  The amount of the token to be transferred
  * @param merkleProof  The merkle proof containing sibling hashes on the branch
  * from the leaf that is being claimed to the root of the merkle tree
  */
  function withdrawErc1155(
    address beneficary,
    address contractAddress,
    uint256 token,
    uint256 amount,
    bytes32[] calldata merkleProof
  )
    external
    withdrawalsPaused()
  {
    bytes32 leaf = keccak256(abi.encodePacked(beneficary, contractAddress, token, amount));
    bytes32 claimReceipt = keccak256(abi.encodePacked(leaf, claimsMerkleRoot));

    require(!beneficaryFundsClaimed[claimReceipt], "Claim already made");
    require(MerkleProof.verify(merkleProof, claimsMerkleRoot, leaf), "Merkle proof failed");

    beneficaryFundsClaimed[claimReceipt] = true;
    emit erc1155RoyaltyWithdrawn(contractAddress, token, beneficary, amount);

    IERC1155(contractAddress).safeTransferFrom(address(this), beneficary, token, amount, "");
  }

  /**
  * @dev  Allows beneficaries to make batch erc1155 withdrawals. The parameters
  * must match the values that were included in the merkle tree
  * @param beneficary  The address where the beneficary's funds will be sent
  * @param contractAddress  The address of the erc1155 contract that administers
  * the tokens being used in the transaction
  * @param tokens The array specific tokens of the erc1155 contract that are to
  * be used in this transaction
  * @param amounts  Array of the amounts of each token to be transferred
  * @param merkleProofs  The merkle proofs containing sibling hashes on the
  * branch from the leaves that are being claimed to the root of the merkle tree
  */
  function withdrawErc1155Batch(
    address beneficary,
    address contractAddress,
    uint256[] calldata tokens,
    uint256[] calldata amounts,
    bytes32[][] calldata merkleProofs
  )
    external
    withdrawalsPaused()
  {
    require(tokens.length == amounts.length);

    for(uint i = 0; i < tokens.length; i++) {
      bytes32 leaf = keccak256(abi.encodePacked(beneficary, contractAddress, tokens[i], amounts[i]));
      bytes32 claimReceipt = keccak256(abi.encodePacked(leaf, claimsMerkleRoot));

      require(!beneficaryFundsClaimed[claimReceipt], "Claim already made");
      require(MerkleProof.verify(merkleProofs[i], claimsMerkleRoot, leaf), "Merkle proof failed");

      beneficaryFundsClaimed[claimReceipt] = true;
      emit erc1155RoyaltyWithdrawn(contractAddress, tokens[i], beneficary, amounts[i]);
    }

    IERC1155(contractAddress).safeBatchTransferFrom(address(this), beneficary, tokens, amounts, "");
  }

  function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes memory _data
  ) public virtual override returns (bytes4) {
      emit erc1155RoyaltyReceived(msg.sender, _id, _value, _data);
      return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
      address _operator,
      address _from,
      uint256[] memory _ids,
      uint256[] memory _values,
      bytes memory _data
  ) public virtual override returns (bytes4) {
      emit erc1155BatchRoyaltyReceived(msg.sender, _ids, _values, _data);
      return this.onERC1155BatchReceived.selector;
  }

  /**
  * @dev  Implements erc2891 royalties. Importantly the last digits of the
  * returned value are the id of the nft involved in the transaction. It is
  * necessary to include this for the off-chain attribution of which royalty
  * payments involved which nfts.
  * @param tokenId  The id of the nft with which the transaction is associated
  * @param salePrice  The value of the transaction
  * @return address  The address to send the royalty payment to (this contract's
  * address)
  * @return uint256  The value that the transaction should send
  */
  function royaltyInfo(uint256 tokenId, uint256 salePrice) public view override returns (address, uint256) {
    require(royalties[tokenId].length > 0, "This token has not been minted yet or does not pay royalties");

    uint256 royaltyAmount;

    for(uint i = 0; i < royalties[tokenId].length; i++) {
      royaltyAmount += (salePrice * royalties[tokenId][i]) / percentDenominator;
    }

    royaltyAmount = ((royaltyAmount / tokenIdSpace) * tokenIdSpace) + tokenId;

    return (address(this), royaltyAmount);
  }


  // ========================== ADMIN FUNCTIONS ================================
  /**
  * @notice  Used to instantiate a new collection of tokens
  */
  function createNewTokenType(
    NewTokenType memory newTokenType,
    string[] calldata startingStorageSchemas,
    string[] calldata startingBaseUris
  )
    external
    payable
    onlyRole(OPERATOR_ROLE)
    tokenCreationChecks(newTokenType, startingStorageSchemas, startingBaseUris)
  {
    tokenTypes[newTokenType.id].createTokenType(newTokenType, startingStorageSchemas, startingBaseUris);

    if(newTokenType.initialMintAmount > 0) {
      mint(newTokenType.initialMintTo, newTokenType.id, newTokenType.initialMintAmount);
    }

    for(uint i = 0; i < startingStorageSchemas.length; i++) {
      emit storageSchemaAdded(newTokenType.id, startingStorageSchemas[i]);
    }
  }

  /**
  * @notice  Sets a new merkle tree root that can be used by beneficaries to
  * withdraw their funds from the contract
  * @param newAccountRecord  Record of the accounting that determined the
  * allotment of beneficary claims
  * @param newClaimsMerkleRoot  The new merkle tree root that will be used to
  * verify that claims are valid
  */
  function updateBeneficaryClaims(string calldata newAccountRecord, bytes32 newClaimsMerkleRoot)
    external
    onlyRole(ACCOUNTANT_ROLE)
  {
    beneficiaryAccountingRecords.push(newAccountRecord);
    claimsMerkleRoot = newClaimsMerkleRoot;

    emit beneficaryClaimsUpdated(newClaimsMerkleRoot, beneficiaryAccountingRecords.length);
  }

  /**
  * @notice  Sets the royalties of the specified token (once set, they are
  * immutable and can never be changed)
  */
  function setTokenRoyalties(uint256 tokenId, uint16[] calldata _royalties)
    external
    onlyRole(OPERATOR_ROLE)
    setTokenRoyaltiesCheck(tokenId, _royalties)
  {
    uint256 typeId = (tokenId / supplyCapPerTokenType) * supplyCapPerTokenType;

    royalties[tokenId] = _royalties;

    // Calculate how much to credit the balances of each party for the nft mint
    (, uint256 royaltyAmount) = royaltyInfo(tokenId, tokenTypes[typeId].cost);

    withdrawalAmounts[ownerWithdrawalAddress] += tokenTypes[typeId].cost - royaltyAmount;
    emit royaltyReceived(royaltyAmount);
  }

  /**
  * @notice  Updates the mint price of a token
  */
  function setTokenCost(uint256 typeId, uint256 newCost)
    external
    onlyRole(OPERATOR_ROLE)
    isLocked(typeId)
  {
    tokenTypes[typeId].cost = newCost;
  }

  /**
  * @notice  Allows the supply of a collection to be increased (only available
  * before the collection is locked)
  */
  function setTokenSupplyCap(uint256 typeId, uint256 newSupplyCap)
    external
    onlyRole(OPERATOR_ROLE)
    isLocked(typeId)
  {
    tokenTypes[typeId].supplyCap = newSupplyCap;
  }

  /**
  * @notice  Pauses/unpauses minting of the specified collection
  */
  function toggleMintable(uint256 typeId)
    external
    onlyRole(OPERATOR_ROLE)
    isLocked(typeId)
  {
    tokenTypes[typeId].mintable = !tokenTypes[typeId].mintable;
  }

  /**
  * @notice  Adds a new version of the metadata to the specified storage schema
  */
  function updateStorageSchema(uint256 typeId, string calldata storageSchema, string calldata newBaseUri)
    external
    onlyRole(OPERATOR_ROLE)
  {
    tokenTypes[typeId].baseUris[storageSchema].push(string(abi.encodePacked(newBaseUri, '{id}.json')));
  }

  /**
  * @notice  Used to add access to new locations where token metadata is stored
  */
  function addStorageSchema(uint256 typeId, string calldata storageSchema, string calldata baseUri)
    external
    onlyRole(OPERATOR_ROLE)
  {
    require(tokenTypes[typeId].baseUris[storageSchema].length == 0, "This storage schema already exists");
    tokenTypes[typeId].baseUris[storageSchema].push(string(abi.encodePacked(baseUri, '{id}.json')));
    emit storageSchemaAdded(typeId, storageSchema);
  }

  function setDefaultStorageSchema(uint256 typeId, string calldata newDefaultStorageSchema)
    external
    onlyRole(OPERATOR_ROLE)
  {
    tokenTypes[typeId].defaultStorageSchema = newDefaultStorageSchema;
  }

  function setownerWithdrawalAddress(address payable _ownerWithdrawalAddress)
    external
    onlyRole(OPERATOR_ROLE)
  {
    ownerWithdrawalAddress = _ownerWithdrawalAddress;
  }

  function setTokenIdSpace(uint256 _tokenIdSpace)
    external
    onlyRole(OPERATOR_ROLE)
  {
    tokenIdSpace = _tokenIdSpace;
    emit tokenIdSpaceChanged(tokenIdSpace);
  }

  /**
  * @notice  Can be used to change the max number of tokens that can be minted in
  * a single transaction for the specified collection
  */
  function setMaxMint(uint256 typeId, uint256 newMaxMint)
    external
    onlyRole(OPERATOR_ROLE)
    isLocked(typeId)
  {
    tokenTypes[typeId].maxMint = newMaxMint;
  }

  /**
  * @notice  Can be used to update the address at which a beneficary receives
  * payments
  */
  function setMandateReceiverAddress(uint256 typeId, uint256 mandateIndex, address payable newMandateReceiver)
    external
    onlyRole(OPERATOR_ROLE)
  {
    tokenTypes[typeId].mandates[mandateIndex].receiver = newMandateReceiver;
  }

  /**
  * @notice  Pauses/unpauses the ability to make withdrawals via merkle tree proofs
  */
  function toggleBeneficaryWithdrawals()
    external
    onlyRole(OPERATOR_ROLE)
  {
    beneficaryWithdrawalsPaused = !beneficaryWithdrawalsPaused;
  }

  /**
  * @notice  Sets a new uri for the contract level metadata
  */
  function setContractUri(string calldata _contractUri)
    external
    onlyRole(OPERATOR_ROLE)
  {
    contractUri = _contractUri;
  }

  /**
  * @notice  Locks in the current maxMint amount, mintability, supplyCap and token
  * cost of the specified collection so that they can never be adjusted again
  */
  function lockToken(uint256 typeId)
    external
    onlyRole(OPERATOR_ROLE)
  {
    tokenTypes[typeId].locked = true;
  }


  // ============================== GETTERS ====================================
  /**
  * @notice  Returns the uri of the contract level metadata
  */
  function contractURI() public view returns (string memory) {
      return contractUri;
  }

  /**
  * @notice  Returns the uri of the default metadata schema for a token
  * @param tokenId  Id of the token whose metadata you wish to retrieve
  * @return string  The uri where the metadata can be found
  */
  function uri(uint256 tokenId) override public view returns (string memory) {
    uint256 typeId = (tokenId / supplyCapPerTokenType) * supplyCapPerTokenType;
    string memory defaultStorageSchema = tokenTypes[typeId].defaultStorageSchema;

    uint schemasLength = tokenTypes[typeId].baseUris[defaultStorageSchema].length;
    string memory baseUri = tokenTypes[typeId].baseUris[defaultStorageSchema][schemasLength - 1];

    return baseUri;
  }

  /**
  * @notice  Returns the uri of the specified metadata schema for a token
  * @param tokenId  Id of the token whose metadata you wish to retrieve
  * @param storageSchema  The id of the storage you wish to pull the metadata
  * from (i.e. 'http,' 'ipfs,' 'arweave' or other locations where the metadata
  * has been stored)
  * @return string  The uri where the metadata can be found
  */
  function uri(uint256 tokenId, string calldata storageSchema) external view returns (string memory) {
    uint256 typeId = (tokenId / supplyCapPerTokenType) * supplyCapPerTokenType;

    uint schemasLength = tokenTypes[typeId].baseUris[storageSchema].length;
    string memory baseUri = tokenTypes[typeId].baseUris[storageSchema][schemasLength - 1];

    return baseUri;
  }

  /**
  * @notice  Returns the uri of the specified metadata schema at the specified
  * metadata version number for a token
  * @param tokenId  Id of the token whose metadata you wish to retrieve
  * @param storageSchema  The id of the storage you wish to pull the metadata
  * from (i.e. 'http,' 'ipfs,' 'arweave' or other locations where the metadata
  * has been stored)
  * @param schemaIndex  The version number of the metadata that you wish to
  * retrieve
  * @return string  The uri where the metadata can be found
  */
  function uri(uint256 tokenId, string calldata storageSchema, uint256 schemaIndex) external view returns (string memory) {
    uint256 typeId = (tokenId / supplyCapPerTokenType) * supplyCapPerTokenType;

    string memory baseUri = tokenTypes[typeId].baseUris[storageSchema][schemaIndex];

    return baseUri;
  }

  /**
  * @notice  Returns the latest version number of the metadata for the specified
  * metadata storage schema of the specified collection
  */
  function getStorageSchemaCurrentIndex(uint typeId, string calldata storageSchema) external view returns (uint) {
    return tokenTypes[typeId].baseUris[storageSchema].length - 1;
  }

  /**
  * @notice  Returns the mandates for the specified collection
  */
  function getTokenTypeMandates(uint typeId) external view returns (Mandate[] memory) {
    return tokenTypes[typeId].mandates;
  }

  /**
  * @notice  Returns the index of the current beneficary accounting record
  */
  function getBeneficiaryAccountingRecordsLength() external view returns (uint256) {
    return beneficiaryAccountingRecords.length;
  }

}