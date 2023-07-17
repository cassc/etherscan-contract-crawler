// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./ERC20/ERC20Permit.sol";
import "./utils/Initializable.sol";
import "./utils/Ownable.sol";
import "./utils/Address.sol";

/**
 * @title Ruler Protocol Governance Token
 * @author crypto-pumpkin
 */
contract RULER is ERC20Permit, Ownable {
  uint256 public constant CAP = 1000000 ether;

  function initialize() external initializer {
    initializeOwner();
    initializeERC20("Ruler Protocol", "RULER", 18);
    initializeERC20Permit("Ruler Protocol");
    _mint(msg.sender, CAP);
  }

  // collect any tokens sent by mistake
  function collect(address _token) external {
    if (_token == address(0)) { // token address(0) = ETH
      Address.sendValue(payable(owner()), address(this).balance);
    } else {
      uint256 balance = IERC20(_token).balanceOf(address(this));
      IERC20(_token).transfer(owner(), balance);
    }
  }
}