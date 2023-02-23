// SPDX-License-Identifier: GPL-3.0                                                                                                                                                                                                                                                          
// --- Bruno721Drop Contract. --- 
// --- Don't Copy. Be careful your asset ---
pragma solidity ^0.8.7;
import "./proxy.sol";
import "./ERC1967Upgrade.sol";

contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}