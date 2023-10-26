// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./StakeDAOVaultBase.sol";

// solhint-disable const-name-snakecase

contract SdCRVBribeBurner is Ownable {
  using SafeERC20 for IERC20;

  /**********
   * Events *
   **********/

  /// @notice Emitted when the zap logic contract is updated.
  /// @param _oldLogic The old logic address.
  /// @param _newLogic The new logic address.
  event UpdateLogic(address _oldLogic, address _newLogic);

  /*************
   * Constants *
   *************/

  /// @dev The address of CRV Token.
  address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

  /// @dev The address of CRV Token.
  address private constant sdCRV = 0xD1b5651E55D4CeeD36251c61c50C889B36F6abB5;

  /// @dev The address of Stake DAO: SDT Token.
  address private constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;

  /// @dev The address of StakeDAOCRVVault contract.
  address private constant vault = 0x2b3e72f568F96d7209E20C8B8f4F2A363ee1E3F6;

  /// @dev The address of VeSDTDelegation contract.
  address private constant delegator = 0x6037Bb1BBa598bf88D816cAD90A28cC00fE3ff64;

  /*************
   * Variables *
   *************/

  /// @notice Check whether an account is whitelisted.
  mapping(address => bool) public isWhitelist;

  /// @notice The address of TokenZapLogic contract.
  address public logic;

  /***************
   * Constructor *
   ***************/
  constructor(address _logic) {
    logic = _logic;

    IERC20(CRV).safeApprove(vault, uint256(-1));
    IERC20(sdCRV).safeApprove(vault, uint256(-1));
  }

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Burn token and send to StakeDAOCRVVault and VeSDTDelegation contract.
  /// @param token The amount of token to burn.
  /// @param routeSDT The route to convert token as SDT.
  /// @param routeCRV The route to convert token as CRV.
  function burn(
    address token,
    uint256[] memory routeSDT,
    uint256 minSDT,
    uint256[] memory routeCRV,
    uint256 minCRV
  ) external {
    require(isWhitelist[msg.sender], "only whitelist");

    uint256 _balance = IERC20(token).balanceOf(address(this));
    (address _platform, uint256 _platformFee, , uint256 _boostFee, ) = StakeDAOVaultBase(vault).feeInfo();

    uint256 _rewards = _balance;
    if (_platformFee > 0) {
      _platformFee = (_platformFee * _balance) / 1e7;
      _rewards -= _platformFee;

      IERC20(token).safeTransfer(_platform, _platformFee);
    }

    if (_boostFee > 0) {
      _boostFee = (_boostFee * _balance) / 1e7;
      _rewards -= _boostFee;

      _boostFee = _convert(_boostFee, routeSDT);
      require(_boostFee >= minSDT, "insufficient SDT");

      IERC20(SDT).safeTransfer(delegator, _boostFee);
    }

    if (_rewards > 0) {
      address[] memory _tokens = new address[](1);

      // don't convert sdCRV for gas saving.
      if (token != sdCRV) {
        _rewards = _convert(_rewards, routeCRV);
        require(_rewards >= minCRV, "insufficient CRV");

        _tokens[0] = CRV;
      } else {
        _tokens[0] = sdCRV;
      }

      uint256[] memory _amounts = new uint256[](1);
      _amounts[0] = _rewards;

      StakeDAOVaultBase(vault).donate(_tokens, _amounts);
    }
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  /*******************************
   * Public Restricted Functions *
   *******************************/

  /// @notice Update the whitelist status of account.
  /// @param _account The address to update.
  /// @param _status The status to update.
  function updateWhitelist(address _account, bool _status) external onlyOwner {
    isWhitelist[_account] = _status;
  }

  /// @notice Update zap logic contract.
  /// @param _newLogic The address to update.
  function updateLogic(address _newLogic) external onlyOwner {
    address _oldLogic = logic;
    logic = _newLogic;

    emit UpdateLogic(_oldLogic, _newLogic);
  }

  /// @notice Emergency function
  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external payable onlyOwner returns (bool, bytes memory) {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory result) = _to.call{ value: _value }(_data);
    return (success, result);
  }

  /**********************
   * Internal Functions *
   **********************/

  /// @dev Internal function to convert token with routes.
  /// @param _amount The amount of input token.
  /// @param _routes The routes to do zap. See comments in `TokenZapLogic` for more details.
  function _convert(uint256 _amount, uint256[] memory _routes) internal returns (uint256) {
    if (_routes.length == 0) return _amount;

    address _logic = logic;
    for (uint256 i = 0; i < _routes.length; i++) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool _success, bytes memory _result) = _logic.delegatecall(
        abi.encodeWithSignature("swap(uint256,uint256)", _routes[i], _amount)
      );
      // below lines will propagate inner error up
      if (!_success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
          let ptr := mload(0x40)
          let size := returndatasize()
          returndatacopy(ptr, 0, size)
          revert(ptr, size)
        }
      }
      _amount = abi.decode(_result, (uint256));
    }
    return _amount;
  }
}