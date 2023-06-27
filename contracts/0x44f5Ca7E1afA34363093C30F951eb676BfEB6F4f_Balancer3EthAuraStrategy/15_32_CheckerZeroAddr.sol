//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error OnlyNonZeroAddress();

abstract contract CheckerZeroAddr is Initializable {
    modifier onlyNonZeroAddress(address addr) {
        _onlyNonZeroAddress(addr);
        _;
    }

    function __CheckerZeroAddr_init_unchained() internal onlyInitializing {}

    function _onlyNonZeroAddress(address addr) private pure {
        if (addr == address(0)) {
            revert OnlyNonZeroAddress();
        }
    }

    uint256[50] private __gap;
}