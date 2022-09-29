// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./extras/ERC20TokenRecoverable.sol";
import "./access/AccessControllable.sol";
import "./BaseContract.sol";

// solhint-disable func-name-mixedcase
abstract contract BaseRecoverableContract is BaseContract, ERC20TokenRecoverable {
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    // slither-disable-next-line unused-state
    uint256[50] private __gap;

    function __BaseRecoverableContract_init(address acl) internal onlyInitializing {
        __BaseContract_init(acl);
    }

    function __BaseRecoverableContract_init_unchained(address acl) internal onlyInitializing {
        __BaseContract_init_unchained(acl);
    }

    function _authorizeRecover(
        IERC20Upgradeable,
        address,
        uint256
    ) internal override onlyAdmin {}
}