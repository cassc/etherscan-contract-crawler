// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../libs/token/ERC20/ERC20.sol";
import "../libs/token/ERC20/ERC20Detailed.sol";
import "../libs/math/SafeMath.sol";

/**
* @title WrappeddXCADToken - Ethereum-bridged dXCAD Token for Ethereum.
*
* @dev Standard ERC20 that mints from the PoS lock
* contract. Does not burn after transferring to the lock contract
* as the lock contract checks for balance after deposits.
* https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
*/
contract WrappeddXCADToken is ERC20, ERC20Detailed {
  using SafeMath for uint256;

  address public lockProxyAddress;

  constructor(address _lockProxyAddress) ERC20Detailed("Ethereum-bridged dXCAD Token", "dXCAD", 18) public {
    lockProxyAddress = _lockProxyAddress;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal override {
      if (sender == lockProxyAddress) {
          require(recipient != lockProxyAddress, "WrappeddXCADToken: lockProxy should not call transfer to self");
          // lockProxy is the primary minter - so mint whenever required.
          uint256 balance = balanceOf(lockProxyAddress);
          if (balance < amount) {
            _mint(lockProxyAddress, amount.sub(balance));
          }
      }

      super._transfer(sender, recipient, amount);
  }

  function circulatingSupply() external view returns (uint256 amount) {
      return totalSupply().sub(balanceOf(lockProxyAddress));
  }
}