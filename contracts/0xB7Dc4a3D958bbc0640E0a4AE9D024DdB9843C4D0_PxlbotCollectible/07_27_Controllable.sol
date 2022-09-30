//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract Controllable is Ownable {
  mapping(address => bool) private _controllers;
  /**
   * @dev Initializes the contract setting the deployer as a controller.
   */
  constructor() {
    _addController(_msgSender());
  }

  modifier mutualControllersOnly(address _caller) {
    Controllable caller = Controllable(_caller);
    require(_controllers[_caller] && caller.isController(address(this)), 'Controllable: not mutual controllers');
    _;
  }

  /**
   * @dev Returns true if the address is a controller.
   */
  function isController(address controller) public view virtual returns (bool) {
    return _controllers[controller];
  }

  /**
   * @dev Throws if called by any account that isn't a controller
   */
  modifier onlyController() {
    require(_controllers[_msgSender()], "Controllable: not controller");
    _;
  }

  modifier nonZero(address a) {
    require(a != address(0), "Controllable: input is zero address");
    _;
  }

  /**
   * @dev Adds a new controller.
   * Can only be called by the current owner.
   */
  function addController(address c) public virtual onlyOwner nonZero(c) {
     _addController(c);
  }

  /**
   * @dev Adds a new controller.
   * Internal function without access restriction.
   */
  function _addController(address newController) internal virtual {
    _controllers[newController] = true;
  }

    /**
   * @dev Removes a controller.
   * Can only be called by the current owner.
   */
  function removeController(address c) public virtual onlyOwner nonZero(c) {
     _removeController(c);
  }
  
  /**
   * @dev Removes a controller.
   * Internal function without access restriction.
   */
  function _removeController(address controller) internal virtual {
    delete _controllers[controller];
  }
}