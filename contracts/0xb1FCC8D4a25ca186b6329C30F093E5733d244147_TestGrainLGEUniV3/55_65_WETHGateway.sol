// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IWETHGateway.sol";
import "./interfaces/IGrainLGE.sol";

contract WETHGateway is IWETHGateway, Ownable {
  using SafeERC20 for IERC20;

  IWETH public immutable WETH;
  address public immutable grainLge;

  /**
   * @dev Sets the WETH address and the lge address and
   * grants max approval to lge contract
   * @param weth Address of the Wrapped Ether contract
   * @param _grainLge Address of the grain lge contract
   **/
  constructor(address weth, address _grainLge) {
    WETH = IWETH(weth);
    grainLge = _grainLge;
    WETH.approve(grainLge, type(uint256).max);
  }

  /**
   * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (aTokens)
   * is minted.
   * @param numberOfReleases how many trimesters of vesting for this user (0 -> 32)
   **/
  function depositETH(
    uint256 minUsdcAmountOut,
    uint256 numberOfReleases
  ) external payable override {
    WETH.deposit{value: msg.value}();
    IGrainLGE(grainLge).buy(address(WETH), msg.value, minUsdcAmountOut, numberOfReleases, msg.sender, address(0), 0);
  }

  /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'ETH_TRANSFER_FAILED');
  }

  /**
   * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
   * direct transfers to the contract address.
   * @param token token to transfer
   * @param to recipient of the transfer
   * @param amount amount to send
   */
  function emergencyTokenTransfer(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    IERC20(token).safeTransfer(to, amount);
  }

  /**
   * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
   * due selfdestructs or transfer ether to pre-computated contract address before deployment.
   * @param to recipient of the transfer
   * @param amount amount to send
   */
  function emergencyEtherTransfer(address to, uint256 amount) external onlyOwner {
    _safeTransferETH(to, amount);
  }

  /**
   * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
   */
  receive() external payable {
    require(msg.sender == address(WETH), 'Receive not allowed');
  }

  /**
   * @dev Revert fallback calls
   */
  fallback() external payable {
    revert('Fallback not allowed');
  }
}