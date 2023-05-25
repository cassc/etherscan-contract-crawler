// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ILocker {
    /**
     * @dev Fails if transaction is not allowed.
     * Return values can be ignored for AntiBot launches
     */
     function lockOrGetPenalty(address source, address dest)
     external
     returns (bool, uint256);
}

contract OpulousToken is ERC20, ERC20Burnable, Ownable {

    ILocker public locker;

    constructor(uint256 initialSupply) ERC20("OpulousToken", "OPUL") {
        _mint(msg.sender, initialSupply * 1e18 );	// convert whole tokens to 18 decimal places
    }

    function setLocker(address _locker) external onlyOwner() {
        locker = ILocker(_locker);
    }

    function _beforeTokenTransfer(address from, address to, uint256)
    internal override {
        if( address(locker) != address(0) ) {
            locker.lockOrGetPenalty( from, to );
        }
    }
}