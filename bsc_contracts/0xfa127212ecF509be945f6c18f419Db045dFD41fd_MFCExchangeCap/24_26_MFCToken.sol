// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../lib/token/BEP20/MFCBEP20.sol";
import "../Registrar.sol";
import "../RegistrarClient.sol";
import "../access/AdminAgent.sol";
import "../access/BackendAgent.sol";

contract MFCToken is MFCBEP20, RegistrarClient, AdminAgent, BackendAgent {

  // EIP712 Precomputed hashes:
  // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
  bytes32 private constant EIP712DOMAINTYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

  // keccak256("MFCToken")
  bytes32 private constant NAME_HASH = 0xdb4db5fa560f82db369fcd92e192fd316a82e907eaf9c98c16090611a9914217;

  // keccak256("1")
  bytes32 private constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

  // keccak256("MFCPermit(address owner,address spender,uint256 amount,uint256 nonce)");
  bytes32 private constant TXTYPE_HASH = 0xc6eadd329a3e2aac488e2cfafe9dc8060a0b814e9352e8484f04a656f2d69158;

  // solhint-disable-next-line var-name-mixedcase
  bytes32 public DOMAIN_SEPARATOR;
  mapping(address => uint) public nonces;

  bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 private constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");
  bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint8 public constant DECIMALS = 18;
  uint256 public constant MAX_SUPPLY = 7000000000000000000000000000; // 7 billion hard cap
  uint256 public constant MULTIPLIER = 10 ** DECIMALS;

  mapping(address => bool) private _users;
  mapping(address => bool) private _agents;
  address private _mfcExchangeCap;
  uint256 private _mfcCirculation = 0;
  uint256 private _userTransferFee = 0; // user transfer fee in %
  bool private _userTransferEnabled;

  event UserWhitelisted(address recipient);
  event AgentWhitelisted(address recipient);
  event UserWhitelistRevoked(address recipient);
  event AgentWhitelistRevoked(address recipient);

  /**
   * @dev Constructor that setup all the role admins.
   */
  constructor(
    string memory name,
    string memory symbol,
    address registrarAddress_,
    address[] memory adminAgents_,
    address[] memory backendAdminAgents,
    address[] memory backendAgents
  ) MFCBEP20(name, symbol, DECIMALS) RegistrarClient(registrarAddress_) AdminAgent(adminAgents_) {
    // make OWNER_ROLE the admin role for each role (only people with the role of an admin role can manage that role)
    _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
    _setRoleAdmin(WHITELISTER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    // setup deployer to be part of OWNER_ROLE which allow deployer to manage all roles
    _setupRole(OWNER_ROLE, _msgSender());

    // Setup backend
    _setBackendAdminAgents(backendAdminAgents);
    _setBackendAgents(backendAgents);

    // Setup EIP712
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        EIP712DOMAINTYPE_HASH,
        NAME_HASH,
        VERSION_HASH,
        block.chainid,
        address(this)
      )
    );
  }

  modifier onlyTransferable(address sender, address recipient) {
    // sender and recipient must both be whitelisted
    require((_users[sender] || _agents[sender]) && (_users[recipient] || _agents[recipient]), "Address not whitelisted");
    _;
  }

  modifier onlyUnfinalized() {
    require(_registrar.isFinalized() == false, "Registrar already finalized");
    _;
  }

  function getMfcCirculation() external view returns (uint256) {
    return _mfcCirculation;
  }

  function transfer(address recipient, uint256 amount) public override onlyTransferable(_msgSender(), recipient) returns (bool) {
    // Check if fee is not zero then it's user to user transfer - send fee to mfcExchangeCap
    uint256 fee = _calculateUserTransferFee(_msgSender(), recipient, amount);
    if (fee != 0) {
      _updateMfcCirculation(_msgSender(), _mfcExchangeCap, fee);
      super.transfer(recipient, amount - fee); // transfers amount - fee to recipient
      return super.transfer(_mfcExchangeCap, fee); // transfer fee to mfcExchangeCap
    }

    _updateMfcCirculation(_msgSender(), recipient, amount);
    return super.transfer(recipient, amount);
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override onlyTransferable(sender, recipient) returns (bool) {
    // Check if fee is not zero then it's user to user transfer - send fee to mfcExchangeCap
    uint256 fee = _calculateUserTransferFee(sender, recipient, amount);
    if (fee != 0) {
      _updateMfcCirculation(sender, _mfcExchangeCap, fee);
      super.transferFrom(sender, recipient, amount - fee); // transfers amount - fee to recipient
      return super.transferFrom(sender, _mfcExchangeCap, fee); // transfer fee to mfcExchangeCap
    }

    _updateMfcCirculation(sender, recipient, amount);
    return super.transferFrom(sender, recipient, amount);
  }

  function getUserTransferFee() external view returns (uint256) {
    return _userTransferFee;
  }

  function isUserTransferEnabled() external view returns (bool) {
    return _userTransferEnabled;
  }

  function setUserTransferFee(uint256 fee) external onlyAdminAgents {
    _userTransferFee = fee;
  }

  function setUserTransfer(bool enabled) external onlyAdminAgents {
    _userTransferEnabled = enabled;
  }

  /**
   * @dev If MFCExchangeCap is to be swapped out, this must be called before
   *      Registrar is updated with new replacement MFCExchangeCap address.
   */
  function registrarMigrateExchangeCap(address recipient, uint256 amount) public returns (bool) {
    require(_msgSender() == _mfcExchangeCap, "Can only transfer to exchange cap");
    return super.transfer(recipient, amount);
  }

  function mint(uint256 amount) public override onlyRole(MINTER_ROLE) returns (bool) {
    require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
    super._mint(_mfcExchangeCap, amount);
    return true;
  }

  function airdropTokens(address[] calldata _addresses, uint[] calldata _amounts, bool updateCirculation) external onlyBackendAgents onlyUnfinalized {
    require(_addresses.length == _amounts.length, "Argument array length mismatch");

    uint256 mfcCirculation = 0;

    for (uint i = 0; i < _addresses.length; i++) {
      super._mint(_addresses[i], _amounts[i]);
      mfcCirculation += _amounts[i];
    }

    if (updateCirculation) {
      _increaseMfcCirculation(mfcCirculation);
    }
  }

  function setMfcCirculation(uint256 mfcCirculation) external onlyAdminAgents onlyUnfinalized {
    _mfcCirculation = mfcCirculation;
  }

  function grantOwnerRole(address _address) external onlyRole(OWNER_ROLE) {
    grantRole(OWNER_ROLE, _address);
  }

  function grantMinterRole(address _address) external onlyRole(OWNER_ROLE) {
    grantRole(MINTER_ROLE, _address);
  }

  function grantWhitelisterRole(address _address) external onlyRole(OWNER_ROLE) {
    grantRole(WHITELISTER_ROLE, _address);
  }

  function revokeOwnerRole(address _address) external onlyRole(OWNER_ROLE) {
    revokeRole(OWNER_ROLE, _address);
  }

  function revokeMinterRole(address _address) external onlyRole(OWNER_ROLE) {
    revokeRole(MINTER_ROLE, _address);
  }

  function revokeWhitelisterRole(address _address) external onlyRole(OWNER_ROLE) {
    revokeRole(WHITELISTER_ROLE, _address);
  }

  function isWhitelistedUser(address _address) external view returns (bool) {
    return _users[_address];
  }

  function isWhitelistedAgent(address _address) external view returns (bool) {
    return _agents[_address];
  }

  function whitelistUser(address _address) external onlyRole(WHITELISTER_ROLE) {
    require(_users[_address] == false, "Already whitelisted");
    _users[_address] = true;
    emit UserWhitelisted(_address);
  }

  function whitelistUserBatch(address[] calldata _addresses) external onlyRole(WHITELISTER_ROLE) onlyUnfinalized {
    for (uint i = 0; i < _addresses.length; i++) {
      // Only whitelist if necessary
      if (_users[_addresses[i]] == false) {
        _users[_addresses[i]] = true;
        emit UserWhitelisted(_addresses[i]);
      }
    }
  }

  function whitelistAgent(address _address) external onlyRole(WHITELISTER_ROLE) {
    require(_agents[_address] == false, "Already whitelisted");
    _agents[_address] = true;
    emit AgentWhitelisted(_address);
  }

  function revokeWhitelistedUser(address _address) external onlyRole(WHITELISTER_ROLE) {
    require(_users[_address] == true, "Not whitelisted");
    delete _users[_address];
    emit UserWhitelistRevoked(_address);
  }

  function revokeWhitelistedAgent(address _address) external onlyRole(WHITELISTER_ROLE) {
    require(_agents[_address] == true, "Not whitelisted");
    delete _agents[_address];
    emit AgentWhitelistRevoked(_address);
  }

  function permit(address owner, address spender, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
    // EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
    bytes32 txInputHash = keccak256(abi.encode(TXTYPE_HASH, owner, spender, amount, nonces[owner]));
    bytes32 totalHash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash));

    address recoveredAddress = ecrecover(totalHash, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, "MFCToken: INVALID_SIGNATURE");

    nonces[owner] = nonces[owner] + 1;
    _approve(owner, spender, amount);
  }

  function updateAddresses() public override onlyRegistrar {
    _mfcExchangeCap = _registrar.getMFCExchangeCap();
  }

  function _updateMfcCirculation(address from, address to, uint256 amount) internal {
    if (to == _mfcExchangeCap) {
      _decreaseMfcCirculation(amount);
    } else if (from == _mfcExchangeCap) {
      _increaseMfcCirculation(amount);
    }
  }

  function _increaseMfcCirculation(uint256 quantity) internal {
    _mfcCirculation += quantity;
  }

  function _decreaseMfcCirculation(uint256 quantity) internal {
    if (quantity > _mfcCirculation) {
      _mfcCirculation = 0;
    } else {
      _mfcCirculation -= quantity;
    }
  }

  // Calculate for user to user transfer fee
  // If it's user to user transfer and user transfer is disabled, it will throw require error message
  function _calculateUserTransferFee(address from, address to, uint256 amount) internal view returns (uint256) {
    // Check for user to user transfer
    if (_users[from] && _users[to]) {
      require(_userTransferEnabled, "User transfer disabled");

      uint256 transferFee = amount * _userTransferFee / MULTIPLIER;
      return transferFee;
    }

    return 0;
  }
}