// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "../ownable/Ownable.sol";
import "../../interfaces/IAuthorizable.sol";

abstract contract Authorizable is IAuthorizable, Ownable {

    mapping(address => bool) private _authorized;

    /* -------------------------------------------------------- MODIFIERS -------------------------------------------------------- */

    /**
        * @dev Throws if called by any account other than _authorized.
    */
    modifier onlyAuthorized() {
        require(_authorized[_msgSender()], "Authorizable::onlyAuthorized:Only authorized address can call");
        _;
    }

    /* -------------------------------------------------------- SETTERS -------------------------------------------------------- */
    
    /**
        * @dev Add _authorized account {add} if it's not _authorized.
        * Can only be called by the current owner.
        *
        * Emits a {_Authorized} event.
        * Requirements:
        * - `add` cannot be the zero address.
        * - `add` cannot be _authorized already.
    */
    function addAuthorized(address add) onlyOwner external override returns(bool){
        require(add != address(0), "Authorizable::addAuthorized:toAdd address must be different than 0");
        require(!_authorized[add], "Authorizable::addAuthorized:toAdd is already authorized");
        _authorized[add] = true;
        emit Authorized(add, true);
        return true;
    }

    /**
        * @dev Remove _authorized account {remove} if it's _authorized.
        * Can only be called by the current owner.
        *
        * Emits a {Authorized} event.
        * Requirements:
        * - `remove` cannot be the zero address.
        * - `remove` must be _authorized already.
    */
    function removeAuthorized(address remove) onlyOwner external override returns(bool) {
        require(remove != address(0), "Authorizable::removeAuthorized:remove address must be different than 0");
        require(_authorized[remove], "Authorizable::removeAuthorized:remove is not authorized");
        _authorized[remove] = false;
        emit Authorized(remove, false);
        return true;
    }

    /* -------------------------------------------------------- VIEWS -------------------------------------------------------- */

    /**
        * @dev Returns the bool if the {auth} address is _authorized.
    */
    function isAuthorized(address auth) external override view returns(bool){
        return _authorized[auth];
    }
}