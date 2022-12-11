// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

// interface
import {IERC20} from '../interfaces/IERC20.sol';

// libs
import {TransferHelpers} from '../libraries/TransferHelpers.sol';

// contracts
import {Ownable} from '../access/Ownable.sol';

/**
 * @title AdapterBase Contract
 * @author Plug Exchange
 * @notice Implemented on each bridge apdater contracts
 */
abstract contract AdapterBase is Ownable {
  /**
   @notice Receive ethereum
   */
  receive() external payable {}

  /// @notice The plug router contract address
  address public immutable plugRouter;

  /// @notice The native token address
  address public constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @notice Initlization of base contract
   * @param _plugRouter The plug router contract address
   */
  constructor(address _plugRouter) {
    require(_plugRouter != address(0), 'INVALID_PLUG_ROUTER');
    plugRouter = _plugRouter;
  }

  /**
   * @notice Validate msg sender
   * @dev Throws error if sender is not plugRouter
   */
  modifier onlyPlugRouter() {
    _onlyPlugRouter();
    _;
  }

  /**
   * @notice Rescue stuck tokens of plug router
   * @dev Call by current owner
   * @param withdrawableAddress The Address to withdraw this tokens
   * @param tokens The list of tokens
   * @param amounts The list of amounts
   */
  function rescueTokens(
    address withdrawableAddress,
    address[] memory tokens,
    uint256[] memory amounts
  ) external onlyOwner {
    require(withdrawableAddress != address(0), 'ZERO_ADDRESS_NOT_ALLOWED');
    require(tokens.length == amounts.length, 'RESCUE_TOKEN_FAILED');

    uint8 len = uint8(tokens.length);
    uint8 i = 0;
    while (i < len) {
      TransferHelpers.safeTransfer(tokens[i], withdrawableAddress, amounts[i]);
      i++;
    }
  }

  /**
   * @notice Rescue stuck ETH of plug router
   * @dev Call by current owner
   * @param withdrawableAddress The withdrawable address
   * @param amount The value to withdraw
   */
  function resuceEth(address withdrawableAddress, uint256 amount) external onlyOwner {
    require(withdrawableAddress != address(0), 'ZERO_ADDRESS_NOT_ALLOWED');
    TransferHelpers.safeTransferETH(withdrawableAddress, amount);
  }

  /**
   * @notice Validate msg sender
   */
  function _onlyPlugRouter() internal view {
    require(msg.sender == plugRouter, 'ONLY_PLUG_ROUTER');
  }

  /**
   * @notice ERC20 Token approvals
   * @param token The token address to spend
   */
  function _approve(address spender, address token) internal {
    uint256 allowance = IERC20(token).allowance(address(this), spender);
    if (allowance == 0) {
      TransferHelpers.safeApprove(token, spender, type(uint256).max);
    }
  }

  /**
   * @notice Returns revert message thorough return data of a call
   * @dev Throws Error if there is no reason
   * @param _returnData The return data of delegate call
   * @return revertMessage The revert reason
   */
  function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
    // If the _res length is less than 68, then the transaction failed silently (without a revert message)
    if (_returnData.length < 68) return 'Unknown Error';

    // solhint-disable-next-line
    assembly {
      // Slice the sighash.
      _returnData := add(_returnData, 0x04)
    }
    return abi.decode(_returnData, (string)); // All that remains is the revert string
  }
}