// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/interfaces/IRegistry.sol";
import "contracts/libraries/OndoLibrary.sol";

abstract contract OndoRegistryClientInitializable is
  Initializable,
  ReentrancyGuard,
  Pausable
{
  using SafeERC20 for IERC20;

  IRegistry public registry;
  uint256 public denominator;

  // solhint-disable-next-line func-name-mixedcase
  function __OndoRegistryClient__initialize(address _registry)
    internal
    initializer
  {
    require(_registry != address(0), "Invalid registry address");
    registry = IRegistry(_registry);
    denominator = registry.denominator();
  }

  /**
   * @notice General ACL checker
   * @param _role Role as defined in OndoLibrary
   */
  modifier isAuthorized(bytes32 _role) {
    require(registry.authorized(_role, msg.sender), "Unauthorized");
    _;
  }

  /*
   * @notice Helper to expose a Pausable interface to tools
   */
  function paused() public view virtual override returns (bool) {
    return registry.paused() || super.paused();
  }

  function pause() external virtual isAuthorized(OLib.PANIC_ROLE) {
    super._pause();
  }

  function unpause() external virtual isAuthorized(OLib.GUARDIAN_ROLE) {
    super._unpause();
  }

  /**
   * @notice Grab tokens and send to caller
   * @dev If the _amount[i] is 0, then transfer all the tokens
   * @param _tokens List of tokens
   * @param _amounts Amount of each token to send
   */
  function _rescueTokens(address[] calldata _tokens, uint256[] memory _amounts)
    internal
    virtual
  {
    for (uint256 i = 0; i < _tokens.length; i++) {
      uint256 amount = _amounts[i];
      if (amount == 0) {
        amount = IERC20(_tokens[i]).balanceOf(address(this));
      }
      IERC20(_tokens[i]).safeTransfer(msg.sender, amount);
    }
  }

  function rescueTokens(address[] calldata _tokens, uint256[] memory _amounts)
    public
    whenPaused
    isAuthorized(OLib.GUARDIAN_ROLE)
  {
    require(_tokens.length == _amounts.length, "Invalid array sizes");
    _rescueTokens(_tokens, _amounts);
  }
}