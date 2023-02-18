// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error ReentrancyGuard__Locked();

abstract contract ReentrancyGuard is Initializable {
    uint256 private locked;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        locked = 1;
    }

    modifier nonReentrant() virtual {
        if (locked != 1) revert ReentrancyGuard__Locked();

        locked = 2;

        _;

        locked = 1;
    }

    uint256[49] private __gap;
}