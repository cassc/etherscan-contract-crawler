// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

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
  bool private _allowedPublic;
  
  modifier whenPresaled() {
    require(_presaled, "Sale closed");
    _;
  }

  modifier whenNotPresaled() {
    require(!_presaled, "Presale closed");
    _;
  }

  modifier whenAllowedPublic() {
    require(_allowedPublic, "Sale closed");
    _;
  }

  function presaled() public view virtual returns (bool) {
    return _presaled;
  }

  function allowedPublic() public view virtual returns (bool) {
    return _allowedPublic;
  }

  function _presale() internal virtual whenNotPresaled {
    _presaled = true;
    emit Presaled(_msgSender());
  }

  function _unpresale() internal virtual whenPresaled {
    _presaled = false;
    emit Unpresaled(_msgSender());
  }

  function _allowPublic() internal virtual {
    _allowedPublic = true;
  }

  function _disallowPublic() internal virtual {
    _allowedPublic = false;
  }
}