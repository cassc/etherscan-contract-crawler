// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/**
 * @dev Third party imports
 */
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title OnlyTokenAdmin
 * @dev Restricts access for method calls to TokenAdminProxy address
 */
abstract contract OnlyTokenAdmin is ContextUpgradeable {
    /**
     * INITIALIZATION
     */

    /**
     * @dev TokenAdminProxy address
     */
    address private _tokenAdminContract;

    /**
     * @dev Initializes contract with TokenAdminProxy address
     * @param initalTokenAdminContract The TokenAdminProxy address
     */
    function __OnlyTokenAdmin_init(address initalTokenAdminContract) internal {
        _tokenAdminContract = initalTokenAdminContract;
    }

    /**
     * @dev Getter for the current TokenAdminProxy address
     */
    function tokenAdminContract() public view returns (address) {
        return _tokenAdminContract;
    }

    /**
     * @dev Setter for the current TokenAdminProxy address
     */
    function setTokenAdminContract(address _newTokenAdmin) external onlyTokenAdminContract {
        _tokenAdminContract = _newTokenAdmin;
    }

    /**
     * @dev Modifier to restrict access of methods to TokenAdminProxy address
     */
    modifier onlyTokenAdminContract() {
        require(
            _msgSender() == _tokenAdminContract,
            "Method is only callable by TokenAdmin Proxy Contract"
        );
        _;
    }
}