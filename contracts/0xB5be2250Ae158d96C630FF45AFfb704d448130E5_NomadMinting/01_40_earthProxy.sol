//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IMetadata {
  function setBaseUri(string memory _uri) external;

  function setTokenData(uint256 ensId, uint256 newId) external;
}

interface NameWrapper {
  function setSubnodeRecord(
    bytes32 parentNode,
    string memory label,
    address newOwner,
    address resolver,
    uint64 ttl,
    uint32 fuses,
    uint64 expiry
  ) external;

  function ownerOf(uint256 id) external returns (address);
}

interface ENSRegistry {
  function setResolver(bytes32 node, address resolver) external;

  function resolver(bytes32 node) external view returns (address);

  function setApprovalForAll(address operator, bool approved) external;
}

// We do not approve of any minting directly from the contract.
// No warranties or promises are made by Company with respect to Nomads minted directly from the contract.
// By minting a Nomad from this contract you agree to all terms and conditions found on www.earth.domains.

contract NomadMinting is Initializable, OwnableUpgradeable, UUPSUpgradeable {
  event TokenMinted(address to, uint256 ensId, uint256 contractId);
  using Strings for uint256;
  address public nameWrapper;
  address public metadataService;
  uint256 public price;
  uint256 public tokenCount;
  uint256 public constant MAX_SUPPLY = 10000;
  uint256 public reservedTokens;
  uint256 public reservedFreeTokens;
  uint256 public teamTokens;
  uint256 public start;
  bool public salesOn;
  bytes32 public parentNode;
  bytes32 private _merklerootAL;
  bytes32 private _merklerootFL;
  mapping(address => bool) public freeMint;
  mapping(uint256 => uint256) public tokenId;
  mapping(address => bool) public alMint;
  // bool public salesOn;
  address public resolver;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address _nameWrapper,
    address _metadata,
    address newOwner,
    bytes32 node
  ) public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    nameWrapper = _nameWrapper;
    metadataService = _metadata;
    parentNode = node;
    price = 0.25 ether;
    start = block.timestamp;
    teamTokens = 30;
    tokenCount = 1;
    reservedTokens = 587;
    reservedFreeTokens = 552;
    _merklerootFL = 0x206e5c16d8852b25cf2966fec444289fd63e9690c186d3084cd2c021e97d6737;
    _merklerootAL = 0x4ae2c9187bd44b06072377e610c2e9b28c41f5e524d0b89efcf8dcc810588fc9;
    _transferOwnership(newOwner); //0x8287F5dC2A30A8E9c21fAab366663f643e5776FF
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  /**
   * @notice Set the hash of the parent Node, only the owner can use the function
   * @param node namehash of the domain
   */
  function setParentNode(bytes32 node) public onlyOwner {
    parentNode = node;
  }

  function setSales(bool _sales) public onlyOwner {
    salesOn = _sales;
  }

  /**
   * @notice Set the address of the nameWrapper contract, only the owner can use the function
   * @param _nameWrapper address of the nameWrapper contract
   */
  function setNameWrapper(address _nameWrapper) public onlyOwner {
    nameWrapper = _nameWrapper;
  }

  /**
   * @notice Set the address for the metadata service;
   * @param _metadata address of the metadata contract
   */
  function setMetadataService(address _metadata) public onlyOwner {
    metadataService = _metadata;
  }

  function merkleroots(bytes32 merkleAL, bytes32 merkleFT) public onlyOwner {
    _merklerootAL = merkleAL;
    _merklerootFL = merkleFT;
  }

  /**
   * @notice Set the minting price, only the owner can use the function
   * @param _price minting price
   */
  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  /**
   * @notice compute an hash from a parent node and a subdomain labelhash
   * @dev taken From ens nameWrapper contract
   * @param node hash of a parent node
   * @param label labelhash of the subdomain
   */
  function _makeNode(bytes32 node, bytes32 label)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(node, label));
  }

  function reserveTimer() public view returns (bool) {
    return block.timestamp < start + 48 hours;
  }

  /**
   * @notice Mint the nomad token, a value (in ETH) must be passed.
   * @dev Will assign an easy-to-read ID to the ENS computed id to make it easy to store metadata, compute a label following the format 00X 0X0 X00.earth.eth
   */
  function mint(address to, uint256 amount) public payable {
    require(salesOn, "Not started");
    require(msg.value == price * amount, "Wrong value");
    for (uint256 index = 0; index < amount; index++) {
      if (block.timestamp < start + 48 hours) {
        require(
          tokenCount <
            MAX_SUPPLY - reservedTokens - teamTokens - reservedFreeTokens,
          "Minted Out"
        );
      } else {
        require(
          tokenCount < MAX_SUPPLY - teamTokens - reservedFreeTokens,
          "Minted Out"
        );
      }
      string memory label = tokenCount.toString();
      if (tokenCount < 10) label = string(abi.encodePacked("00", label));
      else if (tokenCount < 100) label = string(abi.encodePacked("0", label));
      bytes32 labelhash = keccak256(bytes(label));
      bytes32 ensId = _makeNode(parentNode, labelhash);
      tokenId[uint256(ensId)] = tokenCount;
      NameWrapper(nameWrapper).setSubnodeRecord(
        parentNode,
        label,
        to,
        resolver,
        type(uint64).max,
        0,
        type(uint32).max
      );
      _setTokenData(uint256(ensId), tokenCount);
      tokenCount++;
    }
  }

  function privateMint(address to, bytes32[] calldata _proof) public payable {
    require(salesOn, "Not started");
    require(block.timestamp < start + 48 hours, "Reserve timed Out ");
    require(msg.value == price, "Wrong value");
    require(reservedTokens > 0, "Fully claimed");
    require(alMint[to] == false, "Already minted");
    alMint[to] = true;
    require(isValidProof(_proof, to, _merklerootAL), "wrong Proof");
    string memory label = tokenCount.toString();
    if (tokenCount < 10) label = string(abi.encodePacked("00", label));
    else if (tokenCount < 100) label = string(abi.encodePacked("0", label));
    bytes32 labelhash = keccak256(bytes(label));
    bytes32 ensId = _makeNode(parentNode, labelhash);
    tokenId[uint256(ensId)] = tokenCount;
    NameWrapper(nameWrapper).setSubnodeRecord(
      parentNode,
      label,
      to,
      resolver,
      type(uint64).max,
      0,
      type(uint32).max
    );
    _setTokenData(uint256(ensId), tokenCount);
    tokenCount++;
    reservedTokens--;
  }

  function freeMints(
    address to,
    bytes32[] calldata _proof,
    uint256 amount
  ) public {
    require(salesOn, "Not started");
    require(isValidProofFL(_proof, to, _merklerootFL, amount), "Invalid proof");
    require(freeMint[to] == false, "Already minted");
    freeMint[to] = true;
    require(reservedFreeTokens > 0, "Fully claimed");
    for (uint256 index = 0; index < amount; index++) {
      string memory label = tokenCount.toString();
      if (tokenCount < 10) label = string(abi.encodePacked("00", label));
      else if (tokenCount < 100) label = string(abi.encodePacked("0", label));
      bytes32 labelhash = keccak256(bytes(label));
      bytes32 ensId = _makeNode(parentNode, labelhash);
      tokenId[uint256(ensId)] = tokenCount;
      NameWrapper(nameWrapper).setSubnodeRecord(
        parentNode,
        label,
        to,
        resolver,
        type(uint64).max,
        0,
        type(uint32).max
      );
      _setTokenData(uint256(ensId), tokenCount);
      tokenCount++;
      reservedFreeTokens--;
    }
  }

  function teamMint(address to, uint256 amount) public onlyOwner {
    for (uint256 index = 0; index < amount; index++) {
      string memory label = tokenCount.toString();
      if (tokenCount < 10) label = string(abi.encodePacked("00", label));
      else if (tokenCount < 100) label = string(abi.encodePacked("0", label));
      bytes32 labelhash = keccak256(bytes(label));
      bytes32 ensId = _makeNode(parentNode, labelhash);
      tokenId[uint256(ensId)] = tokenCount;
      NameWrapper(nameWrapper).setSubnodeRecord(
        parentNode,
        label,
        to,
        resolver,
        type(uint64).max,
        0,
        type(uint32).max
      );
      _setTokenData(uint256(ensId), tokenCount);
      tokenCount++;
      teamTokens--;
    }
  }

  function withdraw() public {
    uint256 balance = address(this).balance;
    (bool success, ) = payable(0x5be495FFE3C171babdDd16AFb8BA816deF29d26c).call{
      value: (balance * 10) / 100
    }("");
    require(success);
    (success, ) = payable(0xBc18CB7be21d7225F85f07408152FBc71f3380c1).call{
      value: (balance * 10) / 100
    }("");
    require(success);
    (success, ) = payable(0x83C6ec2d12e80443e0C163954713A0EF614f7a83).call{
      value: (balance * 80) / 100
    }("");
    require(success);
  }

  function _computeLeaf(address user) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(user));
  }

  function isValidProof(
    bytes32[] calldata _proof,
    address user,
    bytes32 tree
  ) public pure returns (bool) {
    bytes32 leaf = _computeLeaf(user);
    return MerkleProof.verify(_proof, tree, leaf);
  }

  function isValidProofFL(
    bytes32[] calldata _proof,
    address user,
    bytes32 tree,
    uint256 amount
  ) public pure returns (bool) {
    bytes32 leaf = _computeLeafFL(user, amount);
    return MerkleProof.verify(_proof, tree, leaf);
  }

  function _computeLeafFL(address user, uint256 amount)
    private
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(user, amount));
  }

  function setFirstToken(uint256 ensID, uint256 newId) public onlyOwner {
    _setTokenData(ensID, newId);
  }

  function setResolverAddr(address _resolver) public onlyOwner {
    resolver = _resolver;
  }

  /**
   * @notice setBaseUri that will be used by the token of that contract
   * @param _uri URI used.
   */

  function setBaseUri(string memory _uri) public onlyOwner {
    IMetadata(metadataService).setBaseUri(_uri);
  }

  function _setTokenData(uint256 ensId, uint256 newId) internal {
    IMetadata(metadataService).setTokenData(ensId, newId);
  }

  function setResolver(string memory label) public {
    bytes32 labelhash = keccak256(bytes(label));
    bytes32 ensId = _makeNode(parentNode, labelhash);
    ENSRegistry(nameWrapper).setResolver(ensId, resolver);
  }

  // ETH 60 , BTC 0, https://docs.ens.domains/ens-improvement-proposals/ensip-9-multichain-address-resolution
  function setAddr(string memory label, bytes memory a) public {
    bytes32 labelhash = keccak256(bytes(label));
    bytes32 ensId = _makeNode(parentNode, labelhash);
    require(
      NameWrapper(nameWrapper).ownerOf(uint256(ensId)) == msg.sender,
      "You do no own the token"
    );
    PublicResolver(resolver).setAddr(ensId, 60, a);
  }

  function setText(
    string memory label,
    string[] memory fields,
    string[] memory data
  ) public {
    bytes32 labelhash = keccak256(bytes(label));
    bytes32 ensId = _makeNode(parentNode, labelhash);
    require(fields.length == data.length);
    require(
      NameWrapper(nameWrapper).ownerOf(uint256(ensId)) == msg.sender,
      "You do no own the token"
    );
    for (uint256 index = 0; index < fields.length; index++) {
      PublicResolver(resolver).setText(ensId, fields[index], data[index]);
    }
  }
}