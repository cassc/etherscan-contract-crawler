// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./interfaces/ITitleEscrow.sol";
import "./interfaces/ITradeTrustToken.sol";
import "./interfaces/TitleEscrowErrors.sol";

contract TitleEscrow is Initializable, IERC165, TitleEscrowErrors, ITitleEscrow {
  address public override registry;
  uint256 public override tokenId;

  address public override beneficiary;
  address public override holder;

  address public override nominee;

  bool public override active;

  constructor() initializer {}

  modifier onlyBeneficiary() {
    if (msg.sender != beneficiary) {
      revert CallerNotBeneficiary();
    }
    _;
  }

  modifier onlyHolder() {
    if (msg.sender != holder) {
      revert CallerNotHolder();
    }
    _;
  }

  modifier whenHoldingToken() {
    if (!_isHoldingToken()) {
      revert TitleEscrowNotHoldingToken();
    }
    _;
  }

  modifier whenNotPaused() {
    bool paused = Pausable(registry).paused();
    if (paused) {
      revert RegistryContractPaused();
    }
    _;
  }

  modifier whenActive() {
    if (!active) {
      revert InactiveTitleEscrow();
    }
    _;
  }

  function initialize(address _registry, uint256 _tokenId) public virtual initializer {
    __TitleEscrow_init(_registry, _tokenId);
  }

  function __TitleEscrow_init(address _registry, uint256 _tokenId) internal virtual onlyInitializing {
    registry = _registry;
    tokenId = _tokenId;
    active = true;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(ITitleEscrow).interfaceId;
  }

  function onERC721Received(
    address, /* operator */
    address, /* from */
    uint256 _tokenId,
    bytes calldata data
  ) external virtual override whenNotPaused whenActive returns (bytes4) {
    if (_tokenId != tokenId) {
      revert InvalidTokenId(_tokenId);
    }
    if (msg.sender != address(registry)) {
      revert InvalidRegistry(msg.sender);
    }
    bool isMinting = false;
    if (beneficiary == address(0) || holder == address(0)) {
      if (data.length == 0) {
        revert EmptyReceivingData();
      }
      (address _beneficiary, address _holder) = abi.decode(data, (address, address));
      if (_beneficiary == address(0) || _holder == address(0)) {
        revert InvalidTokenTransferToZeroAddressOwners(_beneficiary, _holder);
      }
      _setBeneficiary(_beneficiary);
      _setHolder(_holder);
      isMinting = true;
    }

    emit TokenReceived(beneficiary, holder, isMinting, registry, tokenId);
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function nominate(address _nominee)
    public
    virtual
    override
    whenNotPaused
    whenActive
    onlyBeneficiary
    whenHoldingToken
  {
    if (beneficiary == _nominee) {
      revert TargetNomineeAlreadyBeneficiary();
    }
    if (nominee == _nominee) {
      revert NomineeAlreadyNominated();
    }

    _setNominee(_nominee);
  }

  function transferBeneficiary(address _nominee)
    public
    virtual
    override
    whenNotPaused
    whenActive
    onlyHolder
    whenHoldingToken
  {
    if (_nominee == address(0)) {
      revert InvalidTransferToZeroAddress();
    }
    if (!(beneficiary == holder || nominee == _nominee)) {
      revert InvalidNominee();
    }

    _setBeneficiary(_nominee);
  }

  function transferHolder(address newHolder)
    public
    virtual
    override
    whenNotPaused
    whenActive
    onlyHolder
    whenHoldingToken
  {
    if (newHolder == address(0)) {
      revert InvalidTransferToZeroAddress();
    }
    if (holder == newHolder) {
      revert RecipientAlreadyHolder();
    }

    _setHolder(newHolder);
  }

  function transferOwners(address _nominee, address newHolder) external virtual override {
    transferBeneficiary(_nominee);
    transferHolder(newHolder);
  }

  function surrender() external virtual override whenNotPaused whenActive onlyBeneficiary onlyHolder whenHoldingToken {
    _setNominee(address(0));
    ITradeTrustToken(registry).transferFrom(address(this), registry, tokenId);

    emit Surrender(msg.sender, registry, tokenId);
  }

  function shred() external virtual override whenNotPaused whenActive {
    if (_isHoldingToken()) {
      revert TokenNotSurrendered();
    }
    if (msg.sender != registry) {
      revert InvalidRegistry(msg.sender);
    }

    _setBeneficiary(address(0));
    _setHolder(address(0));
    active = false;

    emit Shred(registry, tokenId);
  }

  function isHoldingToken() external view override returns (bool) {
    return _isHoldingToken();
  }

  function _isHoldingToken() internal view returns (bool) {
    return ITradeTrustToken(registry).ownerOf(tokenId) == address(this);
  }

  function _setNominee(address newNominee) internal virtual {
    emit Nomination(nominee, newNominee, registry, tokenId);
    nominee = newNominee;
  }

  function _setBeneficiary(address newBeneficiary) internal virtual {
    emit BeneficiaryTransfer(beneficiary, newBeneficiary, registry, tokenId);
    _setNominee(address(0));
    beneficiary = newBeneficiary;
  }

  function _setHolder(address newHolder) internal virtual {
    emit HolderTransfer(holder, newHolder, registry, tokenId);
    holder = newHolder;
  }
}