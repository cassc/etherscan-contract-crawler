// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an governance) that can be granted exclusive access to
 * specific functions.
 *
 * The governance account will be passed on initialization of the contract. This
 * can later be changed with {setPendingGovernance and then transferGovernorship  after 2 days}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyGovernance`, which can be applied to your functions to restrict their use to
 * the governance.
 */
contract Governable {
    address private _governance;
    address public governancePending;
    uint256 public setGovernancePendingAt;
    uint256 public constant TIME_LOCK_DELAY = 2 days;


    /// @notice An event thats emitted when a new governance address is set
    event GovernorshipTransferred(address indexed _previousGovernance, address indexed _newGovernance);
    /// @notice An event thats emitted when a new governance address is pending
    event GovernancePending(address indexed _previousGovernance, address indexed _newGovernance, uint256 _at);

    /**
     * @dev Throws if called by any account other than the governance.
     */
    modifier onlyGovernance() {
        require(msg.sender == _governance, "only governance");
        _;
    }

    /**
     * @dev setPendingGovernance set a pending governance address.
     * NOTE: transferGovernorship can be called after a time delay of 2 days.
     */
    function setPendingGovernance(address _newGovernance) external  onlyGovernance {
        require(_newGovernance != address(0), "Governable:new governance is the zero address");
        governancePending = _newGovernance;
        // solhint-disable-next-line not-rely-on-time
        setGovernancePendingAt = block.timestamp;
        emit GovernancePending(_governance, _newGovernance, setGovernancePendingAt);
    }

    /**
     * @dev transferGovernorship transfer governorship to the pending governance address.
     * NOTE: transferGovernorship can be called after a time delay of 2 days from the latest setPendingGovernance.
     */
    function transferGovernorship() external onlyGovernance {
        require(setGovernancePendingAt > 0, "Governable: no pending governance");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp - setGovernancePendingAt > TIME_LOCK_DELAY,
        "Governable: cannot confirm governance at this time");
        emit GovernorshipTransferred(_governance, governancePending);
        _governance = governancePending;
        setGovernancePendingAt = 0;
    }

    /**
     * @dev Returns the address of the current governance.
     */
    function governance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Initializes the contract setting the initial governance.
     */
    function initialize(address _initialGovernance) internal {
        _governance = _initialGovernance;
        emit GovernorshipTransferred(address(0), _initialGovernance);
    }
}