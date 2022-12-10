// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnerWithdrawable is Ownable {
    using SafeMath for uint256;

    receive() external payable {}

    function withdraw(address token, uint256 amt) public onlyOwner {
      IERC20(token).transfer(msg.sender, amt);
    }

    function withdrawCurrency(uint256 amt) public onlyOwner {
      payable(msg.sender).transfer(amt);
    }

}