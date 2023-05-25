// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./PauserPausable.sol";

/**
 * @title BaseUpgradeablePausable contract
 * @notice This is our Base contract that most other contracts inherit from. It includes many standard
 *  useful abilities like ugpradeability, pausability, access control, and re-entrancy guards.
 * @author Goldfinch
 */

contract BaseUpgradeablePausable is
  Initializable,
  AccessControlUpgradeSafe,
  PauserPausable,
  ReentrancyGuardUpgradeSafe
{
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  using SafeMath for uint256;
  // Pre-reserving a few slots in the base contract in case we need to add things in the future.
  // This does not actually take up gas cost or storage cost, but it does reserve the storage slots.
  // See OpenZeppelin's use of this pattern here:
  // https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/GSN/Context.sol#L37
  uint256[50] private __gap1;
  uint256[50] private __gap2;
  uint256[50] private __gap3;
  uint256[50] private __gap4;

  // solhint-disable-next-line func-name-mixedcase
  function __BaseUpgradeablePausable__init(address owner) public initializer {
    require(owner != address(0), "Owner cannot be the zero address");
    __AccessControl_init_unchained();
    __Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();

    _setupRole(OWNER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);

    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  function isAdmin() public view returns (bool) {
    return hasRole(OWNER_ROLE, _msgSender());
  }

  modifier onlyAdmin() {
    require(isAdmin(), "Must have admin role to perform this action");
    _;
  }
}