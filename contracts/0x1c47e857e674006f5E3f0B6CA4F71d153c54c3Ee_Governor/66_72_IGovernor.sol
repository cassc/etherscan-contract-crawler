// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../vendors/IENSRegistrar.sol";
import "./IClearingHouseV2.sol";
import "./IDonationsRouter.sol";

interface IGovernor {
  error CannotBeZeroAddress();
  /// Structs
  struct ConstructorParams {
    PublicResolver ensResolver;
    ENSRegistry ensRegistry;
    IENSRegistrar ensRegistrar;
    GnosisSafeProxyFactory gnosisFactory;
    address gnosisSafeSingleton;
    address erc20Singleton;
    address parentDao;
    IClearingHouseV2 clearingHouse;
    IDonationsRouter donationsRouter;
  }

  struct Token {
    bytes tokenName;
    bytes tokenSymbol;
    uint256 maxSupply;
    uint256 maxSwap;
    uint256 release;
    bool autoStaking;
    bool kycRequired;
    uint256 mintingAmount;
    uint256 rewardPercentage;
    bytes KYCId;
    uint256 expiry;
    bytes signature;
    uint256 exchangeRate;
  }

  struct Safe {
    SafeCreationParams safe;
    ZodiacParams zodiac;
  }
  struct ZodiacParams {
    address zodiacFactory; // The factory to deploy from
    address moduleMasterCopy; // The module we want cloned
    address oracle; // The public reality.eth oracle contract
    uint32 timeout;
    uint32 cooldown;
    uint32 expiration;
    uint256 bond;
    uint256 templateId; // To be used to reuse a template
    string template; // If this.length > 0, it will be used to create a new template
    address arbitrator; // Should probably be kleros general court, or earthfund dao safe.
  }

  struct SafeCreationParams {
    address[] owners;
    uint256 threshold;
    address to;
    bytes data;
    address fallbackHandler;
    address paymentToken;
    uint256 payment;
    address payable paymentReceiver;
  }

  struct Subdomain {
    bytes subdomain;
    bytes snapshotKey;
    bytes snapshotValue;
  }

  /// Events
  event ChildDaoCreated(
    address indexed safe,
    address indexed token,
    bytes32 node
  );

  event ZodiacModuleEnabled(
    address indexed safe,
    address indexed module,
    uint256 oracleTemplateId
  );

  event RegisterCauseFailure(bytes failure);

  event ENSTextRecordSet(bytes subdomain, bytes key, bytes value);

  /// Functions

  /// @notice Creates the constituent components of a child dao
  /// @param _tokenData The details of the ERC20 token to create
  /// @param _safeData The details of the Gnosis safe to create
  /// @param _subdomain The details of the ens subdomain to create
  function createChildDAO(
    Token calldata _tokenData,
    Safe calldata _safeData,
    Subdomain calldata _subdomain
  ) external;

  /// @notice Transfers an ENS NFT into the contract for use with subdomains
  /// @param _domainNFTId The ENS NFT to transfer in
  function addENSDomain(uint256 _domainNFTId) external;

  /// @notice Removes the ENS domain from the contract
  /// @param _destination The account to transfer the domain to
  function withdrawENSDomain(address _destination) external;

  function setENSRecord(
    bytes calldata _name,
    bytes calldata _key,
    bytes calldata _value
  ) external;

  /// @notice Gets the predicted addresses required to create the correct snapshot k/v pair
  /// @dev This returns the address in the revert string. abi.decode(address,address,address) returns (token, safe, realityModule)
  /// @dev Call off chain using callstatic, and catching the revert string.
  /// @param _tokenData  The token creation parameters
  /// @param _safeData  The safe creation parameters
  /// @param _subdomain  The desired subdomain to be added to the earthfund ens record
  function getPredictedAddresses(
    Token calldata _tokenData,
    Safe calldata _safeData,
    bytes calldata _subdomain
  )
    external
    returns (
      address token,
      address safe,
      address realityModule
    );

  /// @notice Set ENS Resolver contract
  /// @dev Only callable by contract owner
  /// @param _implementation Contract address
  function setEnsResolver(PublicResolver _implementation) external;

  /// @notice Set ENS Registry contract
  /// @dev Only callable by contract owner
  /// @param _implementation Contract address
  function setEnsRegistry(ENSRegistry _implementation) external;

  /// @notice Set ENS Registrar contract
  /// @dev Only callable by contract owner
  /// @param _implementation Contract address
  function setEnsRegistrar(IENSRegistrar _implementation) external;

  /// @notice Set Gnosis Safe Factory contract
  /// @dev Only callable by contract owner
  /// @param _implementation Contract address
  function setGnosisFactory(GnosisSafeProxyFactory _implementation) external;

  /// @notice Set Gnosis Safe Singleton contract
  /// @dev Only callable by contract owner
  /// @param _implementation Contract address
  function setGnosisSafeSingleton(address _implementation) external;

  /// @notice Set ERC20 Singleton contract
  /// @dev Only callable by contract owner
  /// @param _implementation Contract address
  function setErc20Singleton(address _implementation) external;

  /// @notice Set Clearing House contract
  /// @dev Only callable by contract owner
  /// @param _implementation Contract address
  function setClearingHouse(IClearingHouseV2 _implementation) external;

  /// @notice Set Donations Router  contract
  /// @dev Only callable by contract owner
  /// @param _implementation Contract address
  function setDonationsRouter(IDonationsRouter _implementation) external;

  /// @notice Autogenerated getters
  function ensResolver() external view returns (PublicResolver);

  function ensRegistry() external view returns (ENSRegistry);

  function ensRegistrar() external view returns (IENSRegistrar);

  function gnosisFactory() external view returns (GnosisSafeProxyFactory);

  function gnosisSafeSingleton() external view returns (address);

  function erc20Singleton() external view returns (address);

  function clearingHouse()
    external
    view
    returns (IClearingHouseV2 implementation);

  function donationsRouter() external view returns (IDonationsRouter);

  function ensDomainNFTId() external view returns (uint256);
}