// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../token/IlluviumERC20.sol";
import "../interfaces/ILinkedToILV.sol";

/**
 * @title Illuvium Aware
 *
 * @notice Helper smart contract to be inherited by other smart contracts requiring to
 *      be linked to verified IlluviumERC20 instance and performing some basic tasks on it
 *
 * @author Basil Gorin
 */
abstract contract IlluviumAware is ILinkedToILV {
  /// @dev Link to ILV ERC20 Token IlluviumERC20 instance
  address public immutable override ilv;

  /**
   * @dev Creates IlluviumAware instance, requiring to supply deployed IlluviumERC20 instance address
   *
   * @param _ilv deployed IlluviumERC20 instance address
   */
  constructor(address _ilv) {
    // verify ILV address is set and is correct
    require(_ilv != address(0), "ILV address not set");
    require(IlluviumERC20(_ilv).TOKEN_UID() == 0x83ecb176af7c4f35a45ff0018282e3a05a1018065da866182df12285866f5a2c, "unexpected TOKEN_UID");

    // write ILV address
    ilv = _ilv;
  }

  /**
   * @dev Executes IlluviumERC20.safeTransferFrom(address(this), _to, _value, "")
   *      on the bound IlluviumERC20 instance
   *
   * @dev Reentrancy safe due to the IlluviumERC20 design
   */
  function transferIlv(address _to, uint256 _value) internal {
    // just delegate call to the target
    transferIlvFrom(address(this), _to, _value);
  }

  /**
   * @dev Executes IlluviumERC20.transferFrom(_from, _to, _value)
   *      on the bound IlluviumERC20 instance
   *
   * @dev Reentrancy safe due to the IlluviumERC20 design
   */
  function transferIlvFrom(address _from, address _to, uint256 _value) internal {
    // just delegate call to the target
    IlluviumERC20(ilv).transferFrom(_from, _to, _value);
  }

  /**
   * @dev Executes IlluviumERC20.mint(_to, _values)
   *      on the bound IlluviumERC20 instance
   *
   * @dev Reentrancy safe due to the IlluviumERC20 design
   */
  function mintIlv(address _to, uint256 _value) internal {
    // just delegate call to the target
    IlluviumERC20(ilv).mint(_to, _value);
  }

}