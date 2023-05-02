// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenWithdraw is OwnableUpgradeable {
  event Received(address _sender, uint256 _amount);

  receive() external payable {
    emit Received(_msgSender(), msg.value);
  }

  function getEthBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function emergencyWithdrawEthBalance(address _pTo, uint256 _pAmount) external onlyOwner {
    require(_pTo != address(0), "Invalid to");
    payable(_pTo).transfer(_pAmount);
  }

  function getTokenBalance(address _pTokenAddress) external view returns (uint256) {
    IERC20 erc20 = IERC20(_pTokenAddress);
    return erc20.balanceOf(address(this));
  }

  function emergencyWithdrawTokenBalance(
    address _pTokenAddress,
    address _pTo,
    uint256 _pAmount
  ) external onlyOwner {
    IERC20 erc20 = IERC20(_pTokenAddress);
    erc20.transfer(_pTo, _pAmount);
  }
}