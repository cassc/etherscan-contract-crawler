//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PaymentERC20Registry is Ownable {
  // Maps an ERC20 address to whether or not it is approved.
  mapping(address => bool) private _approved;

  /**
   * @dev Returns true if the ERC20 is approved for payments.
   */
  function isApprovedERC20(address _token) external view returns (bool) {
    return _approved[_token];
  }

  /**
   * @dev Approves the ERC20 to be approved for payments.
   */
  function addApprovedERC20(address _token) external onlyOwner {
    _approved[_token] = true;
  }

  /**
   * @dev Removes the ERC20 from the registry.
   */
  function removeApprovedERC20(address _token) external onlyOwner {
    _approved[_token] = false;   
  }
}