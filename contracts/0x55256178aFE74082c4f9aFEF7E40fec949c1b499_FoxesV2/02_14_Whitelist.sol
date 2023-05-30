// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Whitelist
 * @author Jorge Izquierdo (https://github.com/izqui)
 * @dev Permissioned boolean whitelist implementation
 */
contract Whitelist is Ownable {
    mapping(address => bool) public isWhitelisted;

    /**
     * @notice Set whether an address is whitelisted or not
     * @param _addr Address to set whitelisted status for
     * @param _isWhitelisted Whether to whitelist or not
     */
    function set(address _addr, bool _isWhitelisted) external onlyOwner {
        _setIsWhitelisted(_addr, _isWhitelisted);
    }

    /**
     * @notice Set whether multiple addresses are whitelisted or not
     * @param _addrs Addresses to set whitelisted status for
     * @param _isWhitelisted Whether these addresses are set as whitelist or not
     */
    function setMany(address[] memory _addrs, bool _isWhitelisted)
        external
        onlyOwner
    {
        uint256 addrLen = _addrs.length;
        for (uint256 i = 0; i < addrLen; i++) {
            _setIsWhitelisted(_addrs[i], _isWhitelisted);
        }
    }

    /**
     * @dev Internal function doesn't emit an event to save gas on large whitelists
     */
    function _setIsWhitelisted(address _addr, bool _isWhitelisted) internal {
        isWhitelisted[_addr] = _isWhitelisted;
    }
}