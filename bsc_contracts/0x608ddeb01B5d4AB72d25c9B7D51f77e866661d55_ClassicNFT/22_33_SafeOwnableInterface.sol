// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

/**
 * This is a contract copied from 'OwnableUpgradeable.sol'
 * It has the same fundation of Ownable, besides it accept pendingOwner for mor Safe Use
 */
abstract contract SafeOwnableInterface {

    function owner() public virtual view returns (address);

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

}