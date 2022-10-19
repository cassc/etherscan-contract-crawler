// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./treasury/BUSDT.sol";
import "./governance/Governable.sol";
import "./access/AdminGovernanceAgent.sol";
import "./token/MFCToken.sol";
import "./treasury/Treasury.sol";
import "./RegistrarClient.sol";
import "./RegistrarMigrator.sol";

contract MFCTradingLicense is Treasury, AdminGovernanceAgent, Governable, RegistrarClient, RegistrarMigrator {

  // EIP712 Precomputed hashes:
  // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
  bytes32 private constant EIP712DOMAINTYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

  // keccak256("MFCTradingLicense")
  bytes32 private constant NAME_HASH = 0x98ad06dc31ab9a6c2b4f3c48f8689eed452dadecf53d148853e4a12626792f85;

  // keccak256("1")
  bytes32 private constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

  // keccak256("MFCCreateMember(address account,address inviter,uint256 nonce)");
  bytes32 private constant TXTYPE_HASH = 0x9c74536da0e05306758e62a83b44279c6119a95973c33acc6c65723de959281b;

  // solhint-disable-next-line var-name-mixedcase
  bytes32 public DOMAIN_SEPARATOR;
  mapping(address => uint) public nonces;

  uint256 public constant MULTIPLIER = 10**18;

  BUSDT private _busdt;
  MFCToken private _mfcToken;
  address private _migration;
  address private _originMember;
  uint256 private _licenseFee;
  uint256 private _inviterFeeSplit;
  uint256 private _licenseTermInHours;
  address private _deployer;

  struct MembershipData {
    address inviter;
    bool isExist;
    uint256 credits;
    uint256 expiresAt;
  }
  mapping(address => MembershipData) private _memberships;

  event CreateOriginMember(address account, uint256 timestamp);
  event CreateMember(address invitee, address inviter, uint256 timestamp);
  event RestoreMember(address invitee, address inviter, uint256 timestamp);
  event PaySubscription(
    address account,
    uint256 amount,
    uint256 timestamp,
    uint256 inviterAmount,
    uint256 remainingAmount,
    uint256 memberLicenseExpiresAt);
  event AddMemberCredits(address account, uint256 amount);
  event ClaimMemberCredits(address account, uint256 amount);
  event WithdrawBuybackCredits(uint256 amount);
  event SetLicenseParameters(uint256 licenseFee, uint256 inviterFeeSplit);

  constructor(
    address registrarAddress_,
    address busdContractAddress_,
    address[] memory adminAgents,
    address[] memory adminGovAgents,
    address originMember_,
    uint256 licenseTermInHours_,
    uint256 licenseFee_,
    uint256 inviterFeeSplit_
  ) Treasury(busdContractAddress_)
    AdminGovernanceAgent(adminGovAgents)
    RegistrarClient(registrarAddress_)
    RegistrarMigrator(registrarAddress_, adminAgents) {
    _originMember = originMember_;
    _licenseTermInHours = licenseTermInHours_;
    _deployer = _msgSender();

    _setLicenseParameters(licenseFee_, inviterFeeSplit_);

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

  modifier onlyDeployer() {
    require(_deployer == _msgSender(), "Caller is not the deployer");
    _;
  }

  function getDeployer() external view returns (address) {
    return _deployer;
  }

  function isMemberActive(address _address) external view returns (bool) {
    if (!isMember(_address)) {
        return false;
    }

    if (_licenseFee == 0) {
        return true;
    }

    return _memberships[_address].expiresAt > block.timestamp;
  }

  function creditBalance(address account) external view returns (uint256) {
    return _memberships[account].credits;
  }

  function getMigration() external view returns (address) {
    return _migration;
  }

  function getLicenseTermInHours() external view returns (uint256) {
    return _licenseTermInHours;
  }

  function getMemberLicenseExpiration(address account) external view returns (uint256) {
    return _memberships[account].expiresAt;
  }

  function getLicenseFee() external view returns (uint256) {
    return _licenseFee;
  }

  function getInviterFeeSplit() external view returns (uint256) {
    return _inviterFeeSplit;
  }

  function isMember(address _address) public view returns (bool) {
    return _memberships[_address].isExist;
  }

  function createOriginMember() external {
    require(!isMember(_originMember), "Member already exist");

    _createMember(_originMember, _originMember);

    emit CreateOriginMember(_originMember, block.timestamp);
  }

  function createMember(address account, address inviter, uint8 v, bytes32 r, bytes32 s) external {
    require(isMember(inviter), "Inviter is not member");
    require(!isMember(account), "Member already exist");

    // EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
    bytes32 txInputHash = keccak256(abi.encode(TXTYPE_HASH, account, inviter, nonces[account]));
    bytes32 totalHash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash));
    address recoveredAddress = ecrecover(totalHash, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == account, "MFCTradingLicense: INVALID_SIGNATURE");
    nonces[account] = nonces[account] + 1;

    _createMember(account, inviter);
    emit CreateMember(account, inviter, block.timestamp);
  }

  function renounceDeployer() external onlyDeployer {
    _deployer = address(0);
  }

  function migrateMembers(address[] calldata members, address[] calldata inviters) external onlyDeployer {
    require(members.length == inviters.length, "Input length mismatch");
    require(members.length > 0, "Zero input length");

    for (uint i = 0; i < members.length; i++) {
      require(isMember(inviters[i]), "Inviter is not member");
      require(!isMember(members[i]), "Member already exist");

      _createMember(members[i], inviters[i]);
      emit CreateMember(members[i], inviters[i], block.timestamp);
    }
  }

  function migrateMemberCredits(address[] calldata members, uint256[] calldata credits) external onlyDeployer {
    require(members.length == credits.length, "Input length mismatch");
    require(members.length > 0, "Zero input length");

    for (uint i = 0; i < members.length; i++) {
      require(isMember(members[i]), "Member doesn't exist");

      // If credit > 0, add member's credit and emit event else do not do anything
      // Add credit == 0 check to make sure deployer doesn't call migrateMemberCredits twice
      if (credits[i] > 0 && _memberships[members[i]].credits == 0) {
        _memberships[members[i]].credits = credits[i];
        emit AddMemberCredits(members[i], credits[i]);
      }
    }
  }

  function payMembership(uint256 membershipFee) external {
    require(isMember(_msgSender()), "Member doesn't exist");
    require(membershipFee > 0, "Invalid membership fee");

    _payMembership(membershipFee, _memberships[_msgSender()].inviter);
  }

  function setLicenseParameters(uint256 licenseFee, uint256 inviterFeeSplit) external onlyAdminAgents {
    _setLicenseParameters(licenseFee, inviterFeeSplit);
  }

  function setMigration(address destination) external onlyGovernance {
    _migration = destination;
  }

  function claimMemberCredits(uint256 amount) external {
    require(_memberships[_msgSender()].credits >= amount, "Insufficient credits");
    _memberships[_msgSender()].credits -= amount;
    getTreasuryToken().transfer(_msgSender(), amount);
    emit ClaimMemberCredits(_msgSender(), amount);
  }

  function transferMigration(uint256 amount) external onlyAdminGovAgents {
    require(_migration != address(0), "Migration not set");
    require(getTreasuryToken().balanceOf(address(this)) >= amount, "Insufficient balance");
    getTreasuryToken().transfer(_migration, amount);
  }

  function updateAddresses() public override onlyRegistrar {
    _mfcToken = MFCToken(_registrar.getMFCToken());
    _busdt = BUSDT(_registrar.getBUSDT());
    _updateGovernable(_registrar);
  }

  function _createMember(address account, address inviterAddress) private {
    _memberships[account].inviter = inviterAddress;
    _memberships[account].isExist = true;
    _memberships[account].credits = 0;

    if (!_mfcToken.isWhitelistedUser(account)) {
      _mfcToken.whitelistUser(account);
    }
  }

  function _payMembership(uint256 membershipFee, address inviter) private {
    require(membershipFee == _licenseFee, "Invalid membership fee");

    if (_licenseFee > 0) {
      require(getTreasuryToken().allowance(_msgSender(), address(this)) >= _licenseFee, "Insufficient allowance");
      require(getTreasuryToken().balanceOf(_msgSender()) >= _licenseFee, "Insufficient balance");

      (uint256 inviterAmount, uint256 remainingAmount) = _splitInviterFee(_licenseFee, inviter);
      _extendExpiresAt(_msgSender());

      emit PaySubscription(_msgSender(), _licenseFee, block.timestamp, inviterAmount, remainingAmount, _memberships[_msgSender()].expiresAt);
    }
  }

  function _setLicenseParameters(uint256 licenseFee, uint256 inviterFeeSplit) private {
    _licenseFee = licenseFee;
    _inviterFeeSplit = inviterFeeSplit;

    emit SetLicenseParameters(licenseFee, inviterFeeSplit);
  }

  function _makePaymentFromBUSD(uint256 amount, address destination) private {
    getTreasuryToken().transferFrom(_msgSender(), destination, amount);
  }

  function _splitInviterFee(uint256 amount, address inviter) private returns (uint256 inviterAmount, uint256 remainingAmount) {
    inviterAmount = _inviterFeeSplit * amount / MULTIPLIER;
    remainingAmount = amount - inviterAmount;

    // inviterAmount goes to inviter's credits
    _memberships[inviter].credits += inviterAmount;

    // transfer inviterAmount to this contract
    _makePaymentFromBUSD(inviterAmount, address(this));

    // remainingAmount goes to BUSDT
    _makePaymentFromBUSD(remainingAmount, address(_busdt));
  }

  function _extendExpiresAt(address account) private {
    // If block timestamp > expiresAt (has already been expired) then extend from block timestamp
    if (block.timestamp > _memberships[account].expiresAt) {
      _memberships[account].expiresAt = block.timestamp + _licenseTermInHours * 3600;
    } else { // Increment expiresAt
      _memberships[account].expiresAt +=  _licenseTermInHours * 3600;
    }
  }

  function _registrarMigrate(uint256 amount) internal override {
    getTreasuryToken().transfer(getRegistrarMigrateDestination(), amount);
  }
}