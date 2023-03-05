// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Clones.sol";

interface ITokenVesting {
    function initialize(address token, address owner) external;
}

contract TokenVestingFactory {
    address public implementation;
    event LockBoxCreated(address indexed owner, address lockBox);

    constructor(address implementation_) {
        require(implementation_ != address(0),"must have implementation address");
        implementation = implementation_;
    }
    /*
     * @dev createLockBox create a new lockbox(proxied) contract
     * @param token token address to vest/lock
     * @param owner of the new lockBox
     */
    function createLockBox(address token, address owner) public returns (address lockBoxAddress) {
        address cloned = Clones.clone(implementation);
        owner = owner == address(0) ? msg.sender : owner;
        ITokenVesting(cloned).initialize(token, owner);
        emit LockBoxCreated(owner, cloned);
        return cloned;
    }
}