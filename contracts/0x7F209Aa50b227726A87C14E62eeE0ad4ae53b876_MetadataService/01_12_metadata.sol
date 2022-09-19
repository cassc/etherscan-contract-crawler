//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@ensdomains/ens-contracts/contracts/wrapper/IMetadataService.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface SVG {
  function uri(uint256 tokenId) external view returns (string memory);
}

contract MetadataService is
  Initializable,
  OwnableUpgradeable,
  UUPSUpgradeable,
  IMetadataService
{
  using Strings for uint256;
  uint256 public collectionCount;
  struct TokenData {
    uint256 tokenId;
    address collectionAddress;
  }

  struct CollectionData {
    string uri;
    bool authorized;
    uint256 collectionId;
  }
  mapping(address => CollectionData) public collectionDatas;
  mapping(uint256 => TokenData) public tokenDatas;

  /**
   * @notice Checks if msg.sender is approved by the owner of the contract
   */

  modifier onlyAuthorized() {
    require(collectionDatas[msg.sender].authorized, "only authorized");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize() public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  /**
   * @notice allow a contract to use the metadata contract as well as setting up URI and collectionID
   * @param nft (address) of the contract
   * @param _uri (string)
   */
  function addContractData(address nft, string memory _uri) public onlyOwner {
    collectionDatas[nft].uri = _uri;
    collectionDatas[nft].authorized = true;
    collectionDatas[nft].collectionId = collectionCount;
    collectionCount++;
  }

  /**
   * @notice Allow to modify the uri of a collection
   * @param _uri (string)
   */
  function setBaseUri(string memory _uri) public onlyAuthorized {
    collectionDatas[msg.sender].uri = _uri;
  }

  /**
   * @notice Allow to modify or a set a specific token data based on the ensID
   * @param ensId (uint256)
   * @param newId (uint256)
   */
  function setTokenData(uint256 ensId, uint256 newId) public onlyAuthorized {
    tokenDatas[ensId].tokenId = newId;
    tokenDatas[ensId].collectionAddress = msg.sender;
  }

  /**
   * @notice return concatenated URI
   * @dev convert ensId to collection id
   * @param ensId (uint256)
   */
  function uri(uint256 ensId) public view returns (string memory ret) {
    uint256 id = tokenDatas[ensId].tokenId;
    address contractAddress = tokenDatas[ensId].collectionAddress;
    if (bytes(collectionDatas[contractAddress].uri).length > 0) {
      ret = string(
        abi.encodePacked(collectionDatas[contractAddress].uri, id.toString())
      );
    } else {
      ret = SVG(contractAddress).uri(ensId);
    }
  }
}