// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

import "./proxy/InitializableAdminUpgradeabilityProxy.sol";
import "./utils/Address.sol";
import "./utils/Create2.sol";
import "./utils/Ownable.sol";
import "./interfaces/IProtocolFactory.sol";

/**
 * @title ProtocolFactory contract
 * @author [email protected]
 */
contract ProtocolFactory is IProtocolFactory, Ownable {

  bytes4 private constant PROTOCOL_INIT_SIGNITURE = bytes4(keccak256("initialize(bytes32,bool,address,uint48[],bytes32[])"));

  uint16 public override redeemFeeNumerator = 10; // 0 to 65,535
  uint16 public override redeemFeeDenominator = 10000; // 0 to 65,535

  address public override protocolImplementation;
  address public override coverImplementation;
  address public override coverERC20Implementation;

  address public override treasury;
  address public override governance;
  address public override claimManager;

  // not all protocols are active
  bytes32[] private protocolNames;

  mapping(bytes32 => address) public override protocols;

  modifier onlyGovernance() {
    require(msg.sender == governance, "COVER: caller not governance");
    _;
  }

  constructor (
    address _protocolImplementation,
    address _coverImplementation,
    address _coverERC20Implementation,
    address _governance,
    address _treasury
  ) {
    protocolImplementation = _protocolImplementation;
    coverImplementation = _coverImplementation;
    coverERC20Implementation = _coverERC20Implementation;
    governance = _governance;
    treasury = _treasury;

    initializeOwner();
  }

  function getAllProtocolAddresses() external view override returns (address[] memory) {
    bytes32[] memory protocolNamesCopy = protocolNames;
    address[] memory protocolAddresses = new address[](protocolNamesCopy.length);
    for (uint i = 0; i < protocolNamesCopy.length; i++) {
      protocolAddresses[i] = protocols[protocolNamesCopy[i]];
    }
    return protocolAddresses;
  }

  function getRedeemFees() external view override returns (uint16 _numerator, uint16 _denominator) {
    return (redeemFeeNumerator, redeemFeeDenominator);
  }

  function getProtocolsLength() external view override returns (uint256) {
    return protocolNames.length;
  }

  function getProtocolNameAndAddress(uint256 _index)
   external view override returns (bytes32, address)
  {
    bytes32 name = protocolNames[_index];
    return (name, protocols[name]);
  }

  /// @notice return protocol contract address, the contract may not be deployed yet
  function getProtocolAddress(bytes32 _name) public view override returns (address) {
    return _computeAddress(keccak256(abi.encodePacked(_name)), address(this));
  }

  /// @notice return cover contract address, the contract may not be deployed yet
  function getCoverAddress(
    bytes32 _protocolName,
    uint48 _timestamp,
    address _collateral,
    uint256 _claimNonce
  )
   public view override returns (address)
  {
    return _computeAddress(
      keccak256(abi.encodePacked(_protocolName, _timestamp, _collateral, _claimNonce)),
      getProtocolAddress(_protocolName)
    );
  }

  /// @notice return covToken contract address, the contract may not be deployed yet
  function getCovTokenAddress(
    bytes32 _protocolName,
    uint48 _timestamp,
    address _collateral,
    uint256 _claimNonce,
    bool _isClaimCovToken
  )
   external view override returns (address) 
  {
    return _computeAddress(
      keccak256(abi.encodePacked(
        _protocolName,
        _timestamp,
        _collateral,
        _claimNonce,
        _isClaimCovToken ? "CLAIM" : "NOCLAIM")
      ),
      getCoverAddress(_protocolName, _timestamp, _collateral, _claimNonce)
    );
  }

  /// @dev Emits ProtocolInitiation, add a supported protocol in COVER
  function addProtocol(
    bytes32 _name,
    bool _active,
    address _collateral,
    uint48[] calldata _timestamps,
    bytes32[] calldata _timestampNames
  )
    external override onlyOwner returns (address)
  {
    require(protocols[_name] == address(0), "COVER: protocol exists");
    require(_timestamps.length == _timestampNames.length, "COVER: timestamp lengths don't match");
    protocolNames.push(_name);

    bytes memory bytecode = type(InitializableAdminUpgradeabilityProxy).creationCode;
    // unique salt required for each protocol, salt + deployer decides contract address
    bytes32 salt = keccak256(abi.encodePacked(_name));
    address payable proxyAddr = Create2.deploy(0, salt, bytecode);
    emit ProtocolInitiation(proxyAddr);

    bytes memory initData = abi.encodeWithSelector(PROTOCOL_INIT_SIGNITURE, _name, _active, _collateral, _timestamps, _timestampNames);
    // governance will be the admin for the protocol contracts
    InitializableAdminUpgradeabilityProxy(proxyAddr).initialize(protocolImplementation, governance, initData);

    protocols[_name] = proxyAddr;

    return proxyAddr;
  }

  /// @dev update this will only affect protocols deployed after
  function updateProtocolImplementation(address _newImplementation)
   external override onlyOwner returns (bool)
  {
    require(Address.isContract(_newImplementation), "COVER: new implementation is not a contract");
    protocolImplementation = _newImplementation;
    return true;
  }

  /// @dev update this will only affect covers of protocols deployed after
  function updateCoverImplementation(address _newImplementation)
   external override onlyOwner returns (bool)
  {
    require(Address.isContract(_newImplementation), "COVER: new implementation is not a contract");
    coverImplementation = _newImplementation;
    return true;
  }

  /// @dev update this will only affect covTokens of covers of protocols deployed after
  function updateCoverERC20Implementation(address _newImplementation)
   external override onlyOwner returns (bool)
  {
    require(Address.isContract(_newImplementation), "COVER: new implementation is not a contract");
    coverERC20Implementation = _newImplementation;
    return true;
  }

  function updateFees(
    uint16 _redeemFeeNumerator,
    uint16 _redeemFeeDenominator
  )
    external override onlyGovernance returns (bool)
  {
    require(_redeemFeeDenominator > 0, "COVER: denominator cannot be 0");
    redeemFeeNumerator = _redeemFeeNumerator;
    redeemFeeDenominator = _redeemFeeDenominator;
    return true;
  }

  /// @dev called once and only by dev to set the claimManager for the first time
  function assignClaimManager(address _address)
   external override onlyOwner returns (bool)
  {
    require(_address != address(0), "COVER: address cannot be 0");
    require(claimManager == address(0), "COVER: claimManager is assigned");
    claimManager = _address;
    return true;
  }

  function updateClaimManager(address _address)
   external override onlyGovernance returns (bool)
  {
    require(_address != address(0), "COVER: address cannot be 0");
    claimManager = _address;
    return true;
  }

  function updateGovernance(address _address)
   external override onlyGovernance returns (bool)
  {
    require(_address != address(0), "COVER: address cannot be 0");
    require(_address != owner(), "COVER: governance cannot be owner");
    governance = _address;
    return true;
  }

  function updateTreasury(address _address)
   external override onlyGovernance returns (bool)
  {
    require(_address != address(0), "COVER: address cannot be 0");
    treasury = _address;
    return true;
  }

  function _computeAddress(bytes32 salt, address deployer) private pure returns (address) {
    bytes memory bytecode = type(InitializableAdminUpgradeabilityProxy).creationCode;
    return Create2.computeAddress(salt, keccak256(bytecode), deployer);
  }
}