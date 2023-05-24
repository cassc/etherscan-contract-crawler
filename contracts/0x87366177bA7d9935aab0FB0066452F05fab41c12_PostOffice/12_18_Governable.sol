// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../interfaces/IGovernable.sol";

error CallerIsNotGovernor();
error ProposedGovernorIsNull();
error CallerIsNotTheProposedGovernor();

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (governor) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governor account will be the one that deploys the contract. This
 * can later be changed with {transferGovernorship}.
 *
 */
abstract contract Governable is IGovernable, ContextUpgradeable {
    address public governor;
    address private proposedGovernor;

    event UpdatedGovernor(address indexed previousGovernor, address indexed proposedGovernor);

    /**
     * @dev Initializes the contract setting the deployer as the initial governor.
     */
    constructor() {
        address msgSender = _msgSender();
        governor = msgSender;
        emit UpdatedGovernor(address(0), msgSender);
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial governor.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Governable_init() internal onlyInitializing {
        address msgSender = _msgSender();
        governor = msgSender;
        emit UpdatedGovernor(address(0), msgSender);
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor() {
        if (governor != msg.sender) revert CallerIsNotGovernor();
        _;
    }

    /**
     * @dev Transfers governorship of the contract to a new account (`proposedGovernor`).
     * Can only be called by the current governor.
     */
    function transferGovernorship(address proposedGovernor_) external onlyGovernor {
        if (proposedGovernor_ == address(0)) revert ProposedGovernorIsNull();
        proposedGovernor = proposedGovernor_;
    }

    /**
     * @dev Allows new governor to accept governorship of the contract.
     */
    function acceptGovernorship() external {
        address _proposedGovernor = proposedGovernor;
        if (msg.sender != _proposedGovernor) revert CallerIsNotTheProposedGovernor();
        emit UpdatedGovernor(governor, _proposedGovernor);
        governor = _proposedGovernor;
        proposedGovernor = address(0);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}