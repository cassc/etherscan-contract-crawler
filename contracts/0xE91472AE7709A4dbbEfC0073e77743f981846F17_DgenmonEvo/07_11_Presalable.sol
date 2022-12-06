// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Context.sol";

abstract contract Presalable is Context {
  /**
    * @dev Emitted when the presale is triggered by `account`.
    */
  event Presaled(address account);

  /**
    * @dev Emitted when the presale is lifted by `account`.
    */
  event Unpresaled(address account);

  bool private _presaled;
  
  modifier whenPresaled() {
      require(_presaled, "Sale closed");
      _;
  }

  modifier whenNotPresaled() {
      require(!_presaled, "Presale closed");
      _;
  }

  function presaled() public view virtual returns (bool) {
      return _presaled;
  }

  function _presale() internal virtual whenNotPresaled {
      _presaled = true;
      emit Presaled(_msgSender());
  }

  function _unpresale() internal virtual whenPresaled {
      _presaled = false;
      emit Unpresaled(_msgSender());
  }
}