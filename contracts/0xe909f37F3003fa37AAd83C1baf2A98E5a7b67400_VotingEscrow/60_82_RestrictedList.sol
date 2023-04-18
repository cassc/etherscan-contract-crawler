// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RestrictedList is Ownable2Step {
    /**
     * @dev Emitted when add the address to restricted list
     */
    event AddedRestrictedList(address _user);
    /**
     * @dev Emitted when remove the address to restricted list
     */
    event RemovedRestrictedList(address _user);

    mapping(address => bool) public isRestrictedList;

    /**
     * @dev Add the address to the restricted list
     */
    function addRestrictedList(address _evilUser) public onlyOwner {
        isRestrictedList[_evilUser] = true;
        emit AddedRestrictedList(_evilUser);
    }

    /**
     * @dev Remove the address to the restricted list
     */
    function removeRestrictedList(address _clearedUser) public onlyOwner {
        isRestrictedList[_clearedUser] = false;
        emit RemovedRestrictedList(_clearedUser);
    }
}