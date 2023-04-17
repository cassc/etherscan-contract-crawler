// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./UniwhaleToken.sol";
import "../interfaces/AbstractVestable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/// @custom:security-contact [email protected]
contract esUniwhaleToken is UniwhaleToken, AbstractVestable, Multicall {
  using FixedPoint for uint256;
  using SafeCast for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address owner,
    string memory name,
    string memory symbol,
    bool _transferrable,
    uint256 _cap,
    IMintable _vestingToken
  ) public initializer {
    super.initialize(owner, name, symbol, _transferrable, _cap);
    __AbstractVestable_init(_vestingToken);
  }

  // governance / priviliged functions

  function setVestingSpeed(uint256 _vestingSpeed) external onlyOwner {
    _setVestingSpeed(_vestingSpeed);
  }

  function setVestingRate(uint256 _vestingRate) external onlyOwner {
    _setVestingRate(_vestingRate);
  }

  function pauseVesting() external onlyOwner {
    _pauseVesting();
  }

  function unpauseVesting() external onlyOwner {
    _unpauseVesting();
  }

  function setVesingToken(IMintable _vestingToken) external onlyOwner {
    _setVestingToken(_vestingToken);
  }

  function burnFromByOwner(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }

  // external functions

  function getVested(address _user) external view returns (uint256) {
    return _accruedVestedByLocker[_user].add(_getVested(_user));
  }

  function lock(
    uint256 amount
  ) external override whenNotPaused nonReentrant whenVestingNotPaused {
    _lock(msg.sender, amount);
  }

  function unlock(
    uint256 amount
  ) external override whenNotPaused nonReentrant whenVestingNotPaused {
    _unlock(msg.sender, amount);
  }

  function vest()
    external
    override
    whenNotPaused
    nonReentrant
    whenVestingNotPaused
  {
    _vest(msg.sender);
  }

  function vest(
    address _user
  ) external override whenNotPaused nonReentrant whenVestingNotPaused {
    _vest(_user);
  }

  function convert(
    uint256 amount
  ) external override whenNotPaused nonReentrant whenVestingNotPaused {
    _convert(msg.sender, amount);
  }

  function convert(
    address _user,
    uint256 amount
  ) external override whenNotPaused nonReentrant whenVestingNotPaused {
    _require(tx.origin == _user, Errors.APPROVED_ONLY);
    _convert(_user, amount);
  }

  function convertAndStake(
    address _user,
    uint256 amount
  ) external whenNotPaused nonReentrant whenVestingNotPaused {
    _require(tx.origin == _user, Errors.APPROVED_ONLY);
    _convert(_user, amount);
    _stake(_user, amount);
  }

  // internal functions

  function _mint(
    address to,
    uint256 amount
  ) internal override(ERC20Upgradeable, UniwhaleToken) whenNotPaused {
    super._mint(to, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  )
    internal
    override(ERC20Upgradeable, UniwhaleToken)
    whenNotPaused
    canTransfer
  {
    super._transfer(from, to, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Upgradeable, UniwhaleToken) whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}