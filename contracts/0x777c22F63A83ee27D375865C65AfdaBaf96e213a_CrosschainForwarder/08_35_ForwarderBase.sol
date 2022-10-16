// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract ForwarderBase is Initializable, AccessControlUpgradeable {

    /* ========== ERRORS ========== */

    error EthTransferFailed();
    error AdminBadRole();

    /* ========== MODIFIERS ========== */

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert AdminBadRole();
        _;
    }

    /* ========== INITIALIZERS ========== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initializeBase() internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _externalCall(
        address _destination,
        bytes memory _data,
        uint256 _value
    ) internal returns (bool result) {
        assembly {
            result := call(
                gas(),
                _destination,
                _value,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
        }
    }

    /*
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (!success) revert EthTransferFailed();
    }

    receive() external payable {}
}