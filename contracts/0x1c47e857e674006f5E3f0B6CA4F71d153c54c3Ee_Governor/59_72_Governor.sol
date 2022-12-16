// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./ERC20Singleton.sol";
import "../interfaces/IGovernor.sol";
import "../interfaces/IModuleProxyFactory.sol";
import "../vendors/IGnosisSafe.sol";
import "@reality.eth/contracts/development/contracts/IRealityETH.sol";

contract Governor is IGovernor, Ownable, ERC721Holder {
  PublicResolver public override ensResolver;
  ENSRegistry public override ensRegistry;
  IENSRegistrar public override ensRegistrar;
  GnosisSafeProxyFactory public override gnosisFactory;
  address public override gnosisSafeSingleton;
  address public override erc20Singleton;
  uint256 public override ensDomainNFTId;
  IClearingHouseV2 public clearingHouse;
  IDonationsRouter public donationsRouter;

  constructor(ConstructorParams memory _params) {
    require(
      address(_params.ensResolver) != address(0),
      "invalid resolver address"
    );
    require(
      address(_params.ensRegistry) != address(0),
      "invalid registry address"
    );
    require(
      address(_params.ensRegistrar) != address(0),
      "invalid registrar address"
    );
    require(
      address(_params.gnosisFactory) != address(0),
      "invalid factory address"
    );
    require(
      _params.gnosisSafeSingleton != address(0),
      "invalid safe singleton address"
    );
    require(
      _params.erc20Singleton != address(0),
      "invalid token singleton address"
    );
    require(_params.parentDao != address(0), "invalid owner");
    require(
      address(_params.clearingHouse) != address(0),
      "invalid clearing house address"
    );
    require(
      address(_params.donationsRouter) != address(0),
      "invalid donations router address"
    );

    ensResolver = _params.ensResolver;
    ensRegistry = _params.ensRegistry;
    ensRegistrar = _params.ensRegistrar;
    gnosisFactory = _params.gnosisFactory;
    gnosisSafeSingleton = _params.gnosisSafeSingleton;
    erc20Singleton = _params.erc20Singleton;
    clearingHouse = _params.clearingHouse;
    donationsRouter = _params.donationsRouter;

    transferOwnership(_params.parentDao);
  }

  receive() external payable {}

  function addENSDomain(uint256 _domainNFTId) external override onlyOwner {
    require(ensDomainNFTId == 0, "ens domain already set");
    ensDomainNFTId = _domainNFTId;
    ensRegistrar.safeTransferFrom(
      address(msg.sender),
      address(this),
      _domainNFTId
    );

    ensRegistrar.reclaim(_domainNFTId, address(this));
  }

  function withdrawENSDomain(address _destination) external override onlyOwner {
    require(ensDomainNFTId > 0, "ens domain not set");
    uint256 _domainNFTId = ensDomainNFTId;
    delete ensDomainNFTId;
    ensRegistrar.safeTransferFrom(address(this), _destination, _domainNFTId);
  }

  function createChildDAO(
    Token calldata _tokenData,
    Safe calldata _safeData,
    Subdomain calldata _subdomain
  ) external override {
    require(ensDomainNFTId > 0, "ENS domain unavailable");

    // Need to disable auto staking initially
    require(_tokenData.autoStaking == false, "disable auto staking");

    /// Gnosis multi sig
    (address safe, ) = _createGnosisSafe(
      _safeData.safe,
      _safeData.zodiac,
      uint256(keccak256(abi.encodePacked(_subdomain.subdomain, address(this))))
    );

    /// Token
    address token = _createERC20Clone(
      _tokenData.tokenName,
      _tokenData.tokenSymbol,
      _tokenData.maxSupply,
      safe,
      _tokenData.mintingAmount
    );

    /// Register the token in the clearing house contract
    clearingHouse.registerChildDao(
      ERC20Singleton(token),
      _tokenData.autoStaking,
      _tokenData.kycRequired,
      _tokenData.maxSupply,
      _tokenData.maxSwap,
      _tokenData.release,
      _tokenData.exchangeRate
    );
    /// ENS Subdomain + Snapshot text record
    bytes32 node = _createENSSubdomain(
      safe,
      _subdomain.subdomain,
      _subdomain.snapshotKey,
      _subdomain.snapshotValue
    );

    emit ChildDaoCreated(safe, token, node);

    try
      donationsRouter.registerCause(
        IDonationsRouter.CauseRegistrationRequest({
          owner: address(safe),
          rewardPercentage: _tokenData.rewardPercentage,
          daoToken: address(token)
        })
      )
    {} catch (bytes memory reason) {
      emit RegisterCauseFailure(reason);
    }
  }

  function _checkZeroAddress(address _address) internal pure {
    if (_address == address(0)) {
      revert CannotBeZeroAddress();
    }
  }

  function _createGnosisSafe(
    SafeCreationParams memory safeData,
    ZodiacParams memory zodiacData,
    uint256 safeDeploymentSalt
  ) internal returns (address safe, address module) {
    address[] memory initialOwners = new address[](safeData.owners.length + 1);
    uint256 i;
    for (i = 0; i < safeData.owners.length; ++i) {
      initialOwners[i] = safeData.owners[i];
    }
    initialOwners[initialOwners.length - 1] = address(this);
    safe = address(
      gnosisFactory.createProxyWithNonce(
        gnosisSafeSingleton,
        _getSafeInitializer(
          SafeCreationParams({
            owners: initialOwners,
            threshold: 1,
            to: safeData.to,
            data: "",
            fallbackHandler: safeData.fallbackHandler,
            paymentToken: safeData.paymentToken,
            payment: safeData.payment,
            paymentReceiver: safeData.paymentReceiver
          })
        ),
        safeDeploymentSalt
      )
    );
    /// @dev The reality module requires a template. This will create, or reuse an existing one.
    uint256 templateId;
    if (bytes(zodiacData.template).length > 0) {
      templateId = IRealityETH(zodiacData.oracle).createTemplate(
        zodiacData.template
      );
    } else {
      // @dev reality template IDs start at 0;
      templateId = zodiacData.templateId;
    }

    module = IModuleProxyFactory(zodiacData.zodiacFactory).deployModule(
      zodiacData.moduleMasterCopy,
      _getZodiacInitializer(safe, templateId, zodiacData),
      uint256(keccak256(abi.encode(safeDeploymentSalt)))
    );
    /// @dev Enable the newly deployed module on our safe
    IGnosisSafe(safe).execTransaction(
      safe,
      0,
      abi.encodeWithSignature("enableModule(address)", module),
      IGnosisSafe.Operation.Call,
      0,
      0,
      0,
      address(0),
      payable(msg.sender),
      _getApprovedHashSignature()
    );
    /// @dev Remove this contract as an owner in the safe
    IGnosisSafe(safe).execTransaction(
      safe,
      0,
      abi.encodeWithSignature(
        "removeOwner(address,address,uint256)",
        initialOwners[initialOwners.length - 2],
        initialOwners[initialOwners.length - 1],
        safeData.threshold
      ),
      IGnosisSafe.Operation.Call,
      0,
      0,
      0,
      address(0),
      payable(msg.sender),
      _getApprovedHashSignature()
    );
    emit ZodiacModuleEnabled(safe, module, templateId);
  }

  function _getApprovedHashSignature()
    internal
    view
    returns (bytes memory signature)
  {
    signature = abi.encodePacked(
      bytes32(uint256(uint160(address(this)))),
      bytes32(0),
      uint8(1)
    );
  }

  function _getZodiacInitializer(
    address safe,
    uint256 templateId,
    ZodiacParams memory zodiacData
  ) internal pure returns (bytes memory initializer) {
    initializer = abi.encodeWithSignature(
      "setUp(bytes)",
      abi.encode(
        safe,
        safe,
        safe,
        zodiacData.oracle,
        zodiacData.timeout,
        zodiacData.cooldown,
        zodiacData.expiration,
        zodiacData.bond,
        templateId,
        zodiacData.arbitrator == address(0) ? safe : zodiacData.arbitrator
      )
    );
  }

  function _getSafeInitializer(SafeCreationParams memory safeData)
    internal
    pure
    returns (bytes memory initData)
  {
    initData = abi.encodeWithSignature(
      "setup(address[],uint256,address,bytes,address,address,uint256,address)",
      safeData.owners,
      safeData.threshold,
      safeData.to,
      safeData.data,
      safeData.fallbackHandler,
      safeData.paymentToken,
      safeData.payment,
      safeData.paymentReceiver
    );
  }

  function _createERC20Clone(
    bytes memory _name,
    bytes memory _symbol,
    uint256 _maxSupply,
    address _preMintDestination,
    uint256 _preMint
  ) internal returns (address token) {
    token = Clones.cloneDeterministic(
      erc20Singleton,
      keccak256(abi.encodePacked(_name, _symbol, _maxSupply))
    );
    ERC20Singleton(token).initialize(
      _name,
      _symbol,
      _maxSupply,
      address(clearingHouse),
      _preMintDestination,
      _preMint
    );
  }

  function _calculateENSNode(bytes32 baseNode, bytes32 childNode)
    internal
    pure
    returns (bytes32 ensNode)
  {
    ensNode = keccak256(abi.encodePacked(baseNode, childNode));
  }

  function _createENSSubdomain(
    address _owner,
    bytes memory _name,
    bytes memory _key,
    bytes memory _value
  ) internal returns (bytes32 childNode) {
    bytes32 labelHash = keccak256(_name);

    bytes32 ensBaseNode = ensRegistrar.baseNode();
    bytes32 parentNode = _calculateENSNode(
      ensBaseNode,
      bytes32(ensDomainNFTId)
    );
    childNode = _calculateENSNode(parentNode, labelHash);

    ensRegistry.setSubnodeRecord(
      parentNode,
      labelHash,
      address(this),
      address(ensResolver),
      3600
    );

    ensResolver.setAddr(childNode, _owner);

    ensResolver.setText(childNode, string(_key), string(_value));
  }

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
    )
  {
    token = Clones.predictDeterministicAddress(
      erc20Singleton,
      keccak256(
        abi.encodePacked(
          _tokenData.tokenName,
          _tokenData.tokenSymbol,
          _tokenData.maxSupply
        )
      )
    );
    (safe, realityModule) = _createGnosisSafe(
      _safeData.safe,
      _safeData.zodiac,
      uint256(keccak256(abi.encodePacked(_subdomain, address(this))))
    );
  }

  function setENSRecord(
    bytes calldata _name,
    bytes calldata _key,
    bytes calldata _value
  ) external {
    bytes32 labelHash = keccak256(_name);

    bytes32 ensBaseNode = ensRegistrar.baseNode();
    bytes32 parentNode = _calculateENSNode(
      ensBaseNode,
      bytes32(ensDomainNFTId)
    );
    bytes32 childNode = _calculateENSNode(parentNode, labelHash);
    ensResolver.setText(childNode, string(_key), string(_value));

    emit ENSTextRecordSet(_name, _key, _value);

    require(msg.sender == ensResolver.addr(childNode), "Invalid owner");
  }

  function setEnsResolver(PublicResolver _implementation)
    external
    override
    onlyOwner
  {
    _checkZeroAddress(address(_implementation));
    ensResolver = _implementation;
  }

  function setEnsRegistry(ENSRegistry _implementation) external onlyOwner {
    _checkZeroAddress(address(_implementation));
    ensRegistry = _implementation;
  } //#

  function setEnsRegistrar(IENSRegistrar _implementation) external onlyOwner {
    _checkZeroAddress(address(_implementation));
    ensRegistrar = _implementation;
  }

  function setGnosisFactory(GnosisSafeProxyFactory _implementation)
    external
    onlyOwner
  {
    _checkZeroAddress(address(_implementation));
    gnosisFactory = _implementation;
  }

  function setGnosisSafeSingleton(address _implementation) external onlyOwner {
    _checkZeroAddress(address(_implementation));
    gnosisSafeSingleton = _implementation;
  }

  function setErc20Singleton(address _implementation) external onlyOwner {
    _checkZeroAddress(address(_implementation));
    erc20Singleton = _implementation;
  }

  function setClearingHouse(IClearingHouseV2 _implementation)
    external
    onlyOwner
  {
    _checkZeroAddress(address(_implementation));
    clearingHouse = _implementation;
  }

  function setDonationsRouter(IDonationsRouter _implementation)
    external
    onlyOwner
  {
    _checkZeroAddress(address(_implementation));
    donationsRouter = _implementation;
  }
}