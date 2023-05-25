// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Governable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a governance) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governance account will be the one that deploys the contract. This
 * can later be changed with {transferGovernance}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyGovernance`, which can be applied to your functions to restrict their use to
 * the governance.
 */
abstract contract Governable is Context {
    address private _governance;

    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);

    /**
     * @dev Initializes the contract setting the deployer as the initial governance.
     */
    constructor() {
        _transferGovernance(_msgSender());
    }

    /**
     * @dev Returns the address of the current governance.
     */
    function governance() public view virtual returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the governance.
     */
    modifier onlyGovernance() {
        require(governance() == _msgSender(), "Governable: caller is not the governance");
        _;
    }

    /**
     * @dev Leaves the contract without governance. It will not be possible to call
     * `onlyGovernance` functions anymore. Can only be called by the current governance.
     *
     * NOTE: Renouncing governanceship will leave the contract without an governance,
     * thereby removing any functionality that is only available to the governance.
     */
    function renounceGovernance() public virtual onlyGovernance {
        _transferGovernance(address(0));
    }

    /**
     * @dev Transfers governanceship of the contract to a new account (`newGovernance`).
     * Can only be called by the current governance.
     */
    function transferGovernance(address newGovernance) public virtual onlyGovernance {
        require(newGovernance != address(0), "Governable: new governance is the zero address");
        _transferGovernance(newGovernance);
    }

    /**
     * @dev Transfers governanceship of the contract to a new account (`newGovernance`).
     * Internal function without access restriction.
     */
    function _transferGovernance(address newGovernance) internal virtual {
        address oldGovernance = _governance;
        _governance = newGovernance;
        emit GovernanceTransferred(oldGovernance, newGovernance);
    }
}