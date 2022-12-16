// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/proxy/utils/Initializable.sol";
import "../utils/TokenHolder.sol";
import "../interfaces/IGovernable.sol";

error SenderIsNotGovernor();
error ProposedGovernorIsNull();
error SenderIsNotTheProposedGovernor();

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (governor) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governor account will be the one that deploys the contract. This
 * can later be changed with {transferGovernorship}.
 *
 */
abstract contract Governable is IGovernable, TokenHolder, Initializable {
    /**
     * @notice The governor
     * @dev By default the contract deployer is the initial governor
     */
    address public governor;

    /**
     * @notice The proposed governor
     * @dev It will be empty (address(0)) if there isn't a proposed governor
     */
    address public proposedGovernor;

    event UpdatedGovernor(address indexed previousGovernor, address indexed proposedGovernor);

    constructor() {
        governor = msg.sender;
        emit UpdatedGovernor(address(0), msg.sender);
    }

    /**
     * @dev If inheriting child is using proxy then child contract can use
     * __Governable_init() function to initialization this contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Governable_init() internal initializer {
        governor = msg.sender;
        emit UpdatedGovernor(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor() {
        if (governor != msg.sender) revert SenderIsNotGovernor();
        _;
    }

    /// @inheritdoc TokenHolder
    function _requireCanSweep() internal view override onlyGovernor {}

    /**
     * @notice Transfers governorship of the contract to a new account (`proposedGovernor`).
     * @dev Can only be called by the current owner.
     * @param proposedGovernor_ The new proposed governor
     */
    function transferGovernorship(address proposedGovernor_) external onlyGovernor {
        if (proposedGovernor_ == address(0)) revert ProposedGovernorIsNull();
        proposedGovernor = proposedGovernor_;
    }

    /**
     * @notice Allows new governor to accept governorship of the contract.
     */
    function acceptGovernorship() external {
        address _proposedGovernor = proposedGovernor;
        if (msg.sender != _proposedGovernor) revert SenderIsNotTheProposedGovernor();
        emit UpdatedGovernor(governor, _proposedGovernor);
        governor = _proposedGovernor;
        proposedGovernor = address(0);
    }
}