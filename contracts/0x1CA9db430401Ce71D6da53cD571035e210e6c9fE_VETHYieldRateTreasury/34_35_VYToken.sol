// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { AccessControl } from "../lib/access/AccessControl.sol";
import { ERC20 } from "../lib/token/ERC20/ERC20.sol";
import { AdminAgent } from "../access/AdminAgent.sol";
import { BackendAgent } from "../access/BackendAgent.sol";
import { VYRevenueCycleCirculationTracker } from "../exchange/VYRevenueCycleCirculationTracker.sol";
import { Registrar } from "../Registrar.sol";
import { VETHGovernance } from "../governance/VETHGovernance.sol";

contract VYToken is ERC20, AdminAgent, BackendAgent, AccessControl {

  uint256 private constant MULTIPLIER = 10**18;

  // EIP712 Precomputed hashes:
  // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
  bytes32 private constant EIP712DOMAINTYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

  // keccak256("VYToken")
  bytes32 private constant NAME_HASH = 0xc8992ef634b020d3849cb749bb94cf703a7071d02872a417a811fadacc5fdcbb;

  // keccak256("1")
  bytes32 private constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

  // keccak256("VYPermit(address owner,address spender,uint256 amount,uint256 nonce)");
  bytes32 private constant TXTYPE_HASH = 0x085abc97e2d328b3816b8248b9e8aa0e35bb8f414343c830d2d375b0d9b3c98f;

  // solhint-disable-next-line var-name-mixedcase
  bytes32 public DOMAIN_SEPARATOR;
  mapping(address => uint) public nonces;

  bytes32 public constant MAIN_ECOSYSTEM_ID = keccak256(bytes("VY_ETH"));
  bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 private constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");

  uint256 public constant MAX_SUPPLY = 7000000000000000000000000000; // 7 billion hard cap

  mapping(address => bool) private _agents;
  mapping(address => bool) private _minters;
  mapping(bytes32 => address) private _registrars; // Ecosystems
  uint256 private _vyCirculation = 0;
  uint256 private _transferFee = 0; // user transfer fee in %

  event AgentWhitelisted(address recipient);
  event AgentWhitelistRevoked(address recipient);
  event SetRegistrar(address registrar, bytes32 ecosystemId);

  /**
   * @dev Constructor that setup all the role admins.
   */
  constructor(
    string memory name,
    string memory symbol,
    address registrarAddress,
    address[] memory adminAgents,
    address[] memory backendAdminAgents,
    address[] memory backendAgents,
    uint256 transferFee_,
    uint256 initialCirculation
  ) ERC20(name, symbol) AdminAgent(adminAgents) {
    // make OWNER_ROLE the admin role for each role (only people with the role of an admin role can manage that role)
    _setRoleAdmin(WHITELISTER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    // setup deployer to be part of OWNER_ROLE which allow deployer to manage all roles
    _setupRole(OWNER_ROLE, _msgSender());

    // Setup backend
    _setBackendAdminAgents(backendAdminAgents);
    _setBackendAgents(backendAgents);

    // Setup registrar
    _setRegistrar(registrarAddress);

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

    _transferFee = transferFee_;
    _vyCirculation = initialCirculation;
  }

  function getVYCirculation() external view returns (uint256) {
    return _vyCirculation;
  }

  function getRegistrarById(bytes32 id) external view returns(address) {
    return _registrars[id];
  }

  function isMinter(address _address) external view returns (bool) {
    return _minters[_address];
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    // Check if fee is not zero then it's user to user transfer - send fee to vethRevenueCycleTreasury
    uint256 fee = _calculateTransferFee(_msgSender(), recipient, amount);

    if (fee != 0) {
      address mainRevenueCycleTreasury = _getMainEcosystemRegistrar().getVETHRevenueCycleTreasury();
      _updateCirculationAndSupply(_msgSender(), mainRevenueCycleTreasury, fee);

      super.transfer(recipient, amount - fee); // transfers amount - fee to recipient
      return super.transfer(mainRevenueCycleTreasury, fee); // transfers fee to vethRevenueCycleTreasury
    }

    _updateCirculationAndSupply(_msgSender(), recipient, amount);
    return super.transfer(recipient, amount);
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    // Check if fee is not zero then it's user to user transfer - send fee to vethRevenueCycleTreasury
    uint256 fee = _calculateTransferFee(sender, recipient, amount);

    if (fee != 0) {
      address mainRevenueCycleTreasury = _getMainEcosystemRegistrar().getVETHRevenueCycleTreasury();
      _updateCirculationAndSupply(sender, mainRevenueCycleTreasury, fee);

      super.transferFrom(sender, recipient, amount - fee); // transfers amount - fee to recipient
      return super.transferFrom(sender, mainRevenueCycleTreasury, fee); // transfers fee to vethRevenueCycleTreasury
    }

    _updateCirculationAndSupply(sender, recipient, amount);
    return super.transferFrom(sender, recipient, amount);
  }

  function getTransferFee() external view returns (uint256) {
    return _transferFee;
  }

  function setTransferFee(uint256 fee) external onlyAdminAgents {
    _transferFee = fee;
  }

  /*
   * Register a new ecosystem Registrar with us
   *
   * @dev can only be called by VETHGovernance
   */
  function setRegistrar(bytes32 originEcosystemId, uint proposalNonce) external {
    address registrarAddress = _registrars[originEcosystemId];
    require(registrarAddress != address(0), "Invalid originEcosystemId");

    // Only VETHGovernance of applicable Registrar may call this function
    Registrar registrar = Registrar(registrarAddress);
    VETHGovernance governance = VETHGovernance(registrar.getVETHGovernance());
    require(_msgSender() == address(governance), "Caller must be VETHGovernance");

    VETHGovernance.Proposal memory proposal = governance.getProposalById(proposalNonce);

    // Must be valid proposal
    require(proposal.approved == true && proposal.proposalType == VETHGovernance.ProposalType.Registrar, "Invalid proposal");

    _setRegistrar(proposal.registrar.registrar);
    _setMinter(Registrar(proposal.registrar.registrar));
  }

  /**
   * @dev 1) Must be called by the outgoing contract (contract to be swapped out) as
   * the _msgSender must initiate the transfer.
   * 2) Since the registrar now saves the previous contract, registrarMigrateTokens
   * can be called post-swap
   * 3) Registrar must be not finalized
   */
  function registrarMigrateTokens(bytes32 registrarId, uint256 contractIndex) external {
    // The reason we need this function is to transfer tokens due to a registrar contract
    // swap without modifying the circulation and supply.

    // Require valid registrar id
    address registrarAddress = _registrars[registrarId];
    require(registrarAddress != address(0), "Invalid registar id");

    // Require that this registrar is not finalized
    Registrar registrar = Registrar(registrarAddress);
    _requireRegistrarIsUnfinalized(registrar);

    address prevContract = registrar.getPrevContractByIndex(contractIndex);
    address newContract = registrar.getContractByIndex(contractIndex);

    // Require that _msgSender is prevContract
    require(_msgSender() == prevContract, "Caller must be prevContract");

    // Require newContract should not be the zero address
    require(newContract != address(0), "newContract is the zero address");

    super.transfer(newContract, balanceOf(prevContract));
  }

  function _setRegistrar(address registrar) private {
    require(registrar != address(0), "Invalid address");
    bytes32 ecosystemId = Registrar(registrar).getEcosystemId();
    _registrars[ecosystemId] = registrar;

    emit SetRegistrar(registrar, ecosystemId);
  }

  /**
   * @dev Only whitelisted minters may call this function
   */
  function mint(uint256 amount) public returns (bool) {
    require(_minters[_msgSender()], "Caller is not an allowed minter");
    require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");

    super._mint(_msgSender(), amount);

    return true;
  }

  /**
   * @dev Can only be called by Registrar, in the case of registrar contract swap update.
   * Registrar must not be finalized.
   */
  function setMinter() external {
    Registrar registrar = Registrar(_msgSender());
    require(_registrars[registrar.getEcosystemId()] == _msgSender(), "Invalid registar");
    _requireRegistrarIsUnfinalized(registrar);

    _setMinter(registrar);
  }

  function _setMinter(Registrar registrar) private {
    // Unset previous revenueCycleTreasury
    address prevRevenueCycleTreasury = registrar.getPrevContractByIndex(uint(Registrar.Contract.VETHRevenueCycleTreasury));
    _minters[prevRevenueCycleTreasury] = false;

    // Set current revenueCycleTreasury
    address revenueCycleTreasury = registrar.getVETHRevenueCycleTreasury();
    _minters[revenueCycleTreasury] = true;
  }

  /**
   * @dev Airdrop tokens to holders in case VYToken is migrated.
   * Can only be done if main ecosystem's registrar is not finalized.
   */
  function airdropTokens(address[] calldata _addresses, uint[] calldata _amounts) external onlyBackendAgents {
    require(_addresses.length == _amounts.length, "Argument array length mismatch");
    _requireRegistrarIsUnfinalized(_getMainEcosystemRegistrar()); // Check main ecosystem

    for (uint i = 0; i < _addresses.length; i++) {
      super._mint(_addresses[i], _amounts[i]);
    }
  }

  function grantOwnerRole(address _address) external onlyRole(OWNER_ROLE) {
    grantRole(OWNER_ROLE, _address);
  }

  function grantWhitelisterRole(address _address) external onlyRole(OWNER_ROLE) {
    grantRole(WHITELISTER_ROLE, _address);
  }

  function revokeOwnerRole(address _address) external onlyRole(OWNER_ROLE) {
    revokeRole(OWNER_ROLE, _address);
  }

  function revokeWhitelisterRole(address _address) external onlyRole(OWNER_ROLE) {
    revokeRole(WHITELISTER_ROLE, _address);
  }

  function isWhitelistedAgent(address _address) external view returns (bool) {
    return _agents[_address];
  }

  function whitelistAgent(address _address) external onlyRole(WHITELISTER_ROLE) {
    require(_agents[_address] == false, "Already whitelisted");
    _agents[_address] = true;
    emit AgentWhitelisted(_address);
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
    require(recoveredAddress != address(0) && recoveredAddress == owner, "VYToken: INVALID_SIGNATURE");

    nonces[owner] = nonces[owner] + 1;
    _approve(owner, spender, amount);
  }

  function _getMainEcosystemRegistrar() private view returns (Registrar) {
    address registrarAddress = _registrars[MAIN_ECOSYSTEM_ID];

    return Registrar(registrarAddress);
  }

  function _updateCirculationAndSupply(address from, address to, uint256 amount) private {
    if (_minters[to]) {
      _decreaseCirculationAndSupply(amount, to);
    } else if (_minters[from]) {
      _increaseCirculationAndSupply(amount, from);
    }
  }

  function _increaseCirculationAndSupply(uint256 amount, address minter) internal {
    _vyCirculation += amount;

    VYRevenueCycleCirculationTracker(minter).increaseRevenueCycleCirculation(amount);
  }

  function _decreaseCirculationAndSupply(uint256 amount, address minter) internal {
    if (amount > _vyCirculation) {
      _vyCirculation = 0;
    } else {
      _vyCirculation -= amount;
    }

    VYRevenueCycleCirculationTracker(minter).decreaseRevenueCycleCirculation(amount);
  }

  function _calculateTransferFee(address from, address to, uint256 amount) private view returns (uint256) {
    // Check for user to user transfer
    if (!_agents[from] && !_agents[to]) {
      uint256 transferFee = amount * _transferFee / MULTIPLIER;
      return transferFee;
    }

    return 0;
  }

  function _requireRegistrarIsUnfinalized(Registrar registrar) private view {
    require(!registrar.isFinalized(), "Registrar already finalized");
  }
}