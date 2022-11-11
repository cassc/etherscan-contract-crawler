// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC2771Context_Upgradeable.sol";
import "./IERC20_Game_Currency.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WRLD_Token_Exchanger is Ownable, ERC2771Context_Upgradeable {
  IERC20 immutable V1_WRLD;
  IERC20_Game_Currency immutable V2_WRLD;
  uint256 exchangeBonusBP = 500; // basis points, 5%

  constructor(address _forwarder, address _V1WRLD, address _V2WRLD)
  ERC2771Context_Upgradeable(_forwarder) {
    V1_WRLD = IERC20(_V1WRLD);
    V2_WRLD = IERC20_Game_Currency(_V2WRLD);
  }

  function exchange(uint256 inputAmount) external {
    uint256 outputAmount = inputAmount + (inputAmount * exchangeBonusBP / 10000);

    // forever locked into exchanger contract since transferFrom cannot transfer to burn addr
    V1_WRLD.transferFrom(_msgSender(), address(this), inputAmount);

    if (V2_WRLD.balanceOf(address(this)) >= outputAmount) {
        V2_WRLD.transfer(_msgSender(), outputAmount);
    } else {
        V2_WRLD.mint(_msgSender(), outputAmount);
    }
  }

  /**
   * @dev Support for gasless transactions
   */

  function upgradeTrustedForwarder(address _newTrustedForwarder) external onlyOwner {
    _upgradeTrustedForwarder(_newTrustedForwarder);
  }

  function _msgSender() internal view override(Context, ERC2771Context_Upgradeable) returns (address) {
    return super._msgSender();
  }

  function _msgData() internal view override(Context, ERC2771Context_Upgradeable) returns (bytes calldata) {
    return super._msgData();
  }
}