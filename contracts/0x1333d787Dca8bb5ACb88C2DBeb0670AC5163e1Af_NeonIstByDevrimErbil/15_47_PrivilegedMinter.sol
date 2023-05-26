// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/utils/Context.sol';

/**
 * @title PrivilegedMinter
 * @author @NiftyMike | @NFTCulture
 * @dev Control functions for supporting a privileged minter that mints to other, typically custodial wallets.
 */
abstract contract PrivilegedMinter is Context {
    address internal _privilegedMinter;

    modifier onlyPrivilegedMinter() {
        require(_privilegedMinter == _msgSender(), 'DM: caller is not delegate');
        _;
    }

    constructor(address __defaultPrivilegedMinter) {
        _privilegedMinter = __defaultPrivilegedMinter;
    }

    function _setPrivilegedMinter(address __newPrivilegedMinter) internal virtual {
        _privilegedMinter = __newPrivilegedMinter;
    }

    function getPrivilegedMinter() external view returns (address) {
        return _privilegedMinter;
    }
}