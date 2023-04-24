// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "../core/interfaces/ITicket.sol";

import "./PermitAndMulticall.sol";
import "./LowLevelDelegator.sol";

/**
 * @title Delegate chances to win to multiple accounts.
 * @notice This contract allows accounts to easily delegate a portion of their
 *         tickets to multiple delegatees. The delegatees chance of winning
 *         prizes is increased by the delegated amount.
 */
contract TWABDelegator is
    LowLevelDelegator,
    PermitAndMulticall,
    OwnableUpgradeable
{
    using AddressUpgradeable for address;
    using ClonesUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ============ Events ============ */

    /**
     * @notice Emitted when ticket associated with this contract has been set.
     * @param ticket Address of the ticket
     */
    event TicketSet(ITicket indexed ticket);

    /**
     * @notice Emitted when min lock duration has been set.
     * @param minLockDuration Min lock duration in seconds
     */
    event MinLockDurationSet(uint96 minLockDuration);

    /**
     * @notice Emitted when max lock duration has been set.
     * @param maxLockDuration Max lock duration in seconds
     */
    event MaxLockDurationSet(uint96 maxLockDuration);

    /**
     * @notice Emitted when a new delegation is created.
     * @param delegator Delegator of the delegation
     * @param slot Slot of the delegation
     * @param lockUntil Timestamp until which the delegation is locked
     * @param delegatee Address of the delegatee
     * @param delegation Address of the delegation that was created
     * @param user Address of the user who created the delegation
     */
    event DelegationCreated(
        address indexed delegator,
        uint256 indexed slot,
        uint96 lockUntil,
        address indexed delegatee,
        Delegation delegation,
        address user
    );

    /**
     * @notice Emitted when a delegatee is updated.
     * @param delegator Address of the delegator
     * @param slot Slot of the delegation
     * @param delegatee Address of the delegatee
     * @param lockUntil Timestamp until which the delegation is locked
     * @param user Address of the user who updated the delegatee
     */
    event DelegateeUpdated(
        address indexed delegator,
        uint256 indexed slot,
        address indexed delegatee,
        uint96 lockUntil,
        address user
    );

    /**
     * @notice Emitted when a delegation is funded.
     * @param delegator Address of the delegator
     * @param slot Slot of the delegation
     * @param amount Amount of tickets that were sent to the delegation
     * @param user Address of the user who funded the delegation
     */
    event DelegationFunded(
        address indexed delegator,
        uint256 indexed slot,
        uint256 amount,
        address indexed user
    );

    /**
     * @notice Emitted when an amount of tickets has been withdrawn from a
     *         delegation.
     * @param delegator Address of the delegator
     * @param slot Slot of the delegation
     * @param amount Amount of tickets withdrawn
     * @param user Address of the user who withdrew the tickets
     */
    event WithdrewDelegation(
        address indexed delegator,
        uint256 indexed slot,
        uint256 amount,
        address indexed user
    );

    /**
     * @notice Emitted when a delegator withdraws an amount of tickets from a
     *         delegation to a specified wallet.
     * @param delegator Address of the delegator
     * @param slot  Slot of the delegation
     * @param amount Amount of tickets withdrawn
     * @param to Recipient address of withdrawn tickets
     */
    event TransferredDelegation(
        address indexed delegator,
        uint256 indexed slot,
        uint256 amount,
        address indexed to
    );

    /* ============ Variables ============ */

    /// @notice Prize pool ticket to which this contract is tied to.
    ITicket public ticket;

    /// @notice Min lock time during which a delegation cannot be updated.
    uint96 public minLockDuration;

    /// @notice Max lock time during which a delegation cannot be updated.
    uint96 public maxLockDuration;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* ============ Initialize ============ */

    /**
     * @notice Creates a new TWAB Delegator that is bound to the given ticket
     *         contract.
     * @param _ticket Address of the ticket contract
     * @param _minLockDuration minimum lock duration
     * @param _maxLockDuration maximum lock duration
     */
    function initialize(
        ITicket _ticket,
        uint96 _minLockDuration,
        uint96 _maxLockDuration
    ) external virtual initializer {
        __TWABDelegator_init_unchained(
            _ticket,
            _minLockDuration,
            _maxLockDuration
        );
    }

    function __TWABDelegator_init_unchained(
        ITicket _ticket,
        uint96 _minLockDuration,
        uint96 _maxLockDuration
    ) internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __LowLevelDelegator_init_unchained();

        _setTicket(_ticket);

        _setMaxLockDuration(_maxLockDuration);
        _setMinLockDuration(_minLockDuration);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Creates a new delegation. This will create a new Delegation
     *         contract for the given slot and have it delegate its tickets to
     *         the given delegatee. If a non-zero lock duration is passed, then
     *         the delegatee cannot be changed, nor funding withdrawn, until the
     *         lock has expired.
     * @dev    The `_delegator` and `_slot` params are used to compute the salt
     *         of the delegation
     * @param _delegator Address of the delegator that will be able to handle
     *                   the delegation
     * @param _slot Slot of the delegation
     * @param _delegatee Address of the delegatee
     * @param _lockDuration Duration of time for which the delegation is locked.
     *                      Must be less than the max duration.
     * @return Returns the address of the Delegation contract that will hold the
     *         tickets
     */
    function createDelegation(
        address _delegator,
        uint256 _slot,
        address _delegatee,
        uint96 _lockDuration
    ) external returns (Delegation) {
        _requireDelegateeNotZeroAddress(_delegatee);
        _requireDelegator(_delegator);
        _requireLockDuration(_lockDuration);

        uint96 _lockUntil = _computeLockUntil(_lockDuration);

        Delegation _delegation = _createDelegation(
            _computeSalt(_delegator, bytes32(_slot)),
            _lockUntil
        );

        _setDelegateeCall(_delegation, _delegatee);

        emit DelegationCreated(
            _delegator,
            _slot,
            _lockUntil,
            _delegatee,
            _delegation,
            msg.sender
        );

        return _delegation;
    }

    /**
     * @notice Updates the delegatee and lock duration for a delegation slot.
     * @dev Only callable by the `_delegator`.
     * @dev Will revert if delegation is still locked.
     * @param _delegator Address of the delegator
     * @param _slot Slot of the delegation
     * @param _delegatee Address of the delegatee
     * @param _lockDuration Duration of time during which the delegatee cannot
     *                      be changed nor withdrawn
     * @return The address of the Delegation
     */
    function updateDelegatee(
        address _delegator,
        uint256 _slot,
        address _delegatee,
        uint96 _lockDuration
    ) external returns (Delegation) {
        _requireDelegateeNotZeroAddress(_delegatee);
        _requireDelegator(_delegator);
        _requireLockDuration(_lockDuration);

        Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));

        _requireDelegationUnlocked(_delegation);

        uint96 _lockUntil = _computeLockUntil(_lockDuration);

        if (_lockDuration > 0) {
            _delegation.setLockUntil(_lockUntil);
        }

        _setDelegateeCall(_delegation, _delegatee);

        emit DelegateeUpdated(
            _delegator,
            _slot,
            _delegatee,
            _lockUntil,
            msg.sender
        );

        return _delegation;
    }

    /**
     * @notice Fund a delegation by transferring tickets from the caller to the
     *         delegation.
     * @dev Callable by anyone.
     * @dev Will revert if delegation does not exist.
     * @param _delegator Address of the delegator
     * @param _slot Slot of the delegation
     * @param _amount Amount of tickets to transfer
     * @return The address of the Delegation
     */
    function fundDelegation(
        address _delegator,
        uint256 _slot,
        uint256 _amount
    ) external returns (Delegation) {
        require(_delegator != address(0), "TWABDelegator/dlgtr-not-zero-adr");

        _requireAmountGtZero(_amount);

        Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));

        IERC20Upgradeable(ticket).safeTransferFrom(
            msg.sender,
            address(_delegation),
            _amount
        );

        emit DelegationFunded(_delegator, _slot, _amount, msg.sender);

        return _delegation;
    }

    /**
     * @notice Withdraw tickets from a delegation.
     * @dev Only callable by the `_delegator`.
     * @dev Will send the tickets to this contract and increase the `_delegator`
     *      staked amount.
     * @dev Will revert if delegation is still locked.
     * @param _delegator Address of the delegator
     * @param _slot Slot of the delegation
     * @param _amount Amount of tickets to withdraw
     * @return The address of the Delegation
     */
    function withdrawDelegation(
        address _delegator,
        uint256 _slot,
        uint256 _amount
    ) external returns (Delegation) {
        _requireDelegator(_delegator);

        Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));

        _transfer(_delegation, _delegator, _amount);

        emit WithdrewDelegation(_delegator, _slot, _amount, msg.sender);

        return _delegation;
    }

    /**
     * @notice Withdraw an `_amount` of tickets from a delegation. The delegator
     *         is assumed to be the caller.
     * @dev Tickets are sent directly to the passed `_to` address.
     * @dev Will revert if delegation is still locked.
     * @param _slot Slot of the delegation
     * @param _amount Amount to withdraw
     * @param _to Account to transfer the withdrawn tickets to
     * @return The address of the Delegation
     */
    function transferDelegationTo(
        uint256 _slot,
        uint256 _amount,
        address _to
    ) external returns (Delegation) {
        _requireRecipientNotZeroAddress(_to);

        Delegation _delegation = Delegation(_computeAddress(msg.sender, _slot));

        _transfer(_delegation, _to, _amount);

        emit TransferredDelegation(msg.sender, _slot, _amount, _to);

        return _delegation;
    }

    /**
     * @notice Allows a user to call multiple functions on the same contract.
     *         Useful for EOA who wants to batch transactions.
     * @param _data An array of encoded function calls.  The calls must be
     *              abi-encoded calls to this contract.
     * @return The results from each function call
     */
    function multicall(
        bytes[] calldata _data
    ) external returns (bytes[] memory) {
        return _multicall(_data);
    }

    /**
     * @notice Allow a user to approve ticket and run various calls in one
     *         transaction.
     * @param _amount Amount of tickets to approve
     * @param _permitSignature Permit signature
     * @param _data Datas to call with `functionDelegateCall`
     */
    function permitAndMulticall(
        uint256 _amount,
        Signature calldata _permitSignature,
        bytes[] calldata _data
    ) external {
        _permitAndMulticall(
            IERC20PermitUpgradeable(address(ticket)),
            _amount,
            _permitSignature,
            _data
        );
    }

    /**
     * @notice Allows the caller to easily get the details for a delegation.
     * @param _delegator The delegator address
     * @param _slot The delegation slot they are using
     * @return delegation The address that holds tickets for the delegation
     * @return delegatee The address that tickets are being delegated to
     * @return balance The balance of tickets in the delegation
     * @return lockUntil The timestamp at which the delegation unlocks
     * @return wasCreated Whether or not the delegation has been created
     */
    function getDelegation(
        address _delegator,
        uint256 _slot
    )
        external
        view
        returns (
            Delegation delegation,
            address delegatee,
            uint256 balance,
            uint256 lockUntil,
            bool wasCreated
        )
    {
        delegation = Delegation(_computeAddress(_delegator, _slot));
        wasCreated = address(delegation).isContract();
        delegatee = ticket.delegateOf(address(delegation));
        balance = ticket.balanceOf(address(delegation));

        if (wasCreated) {
            lockUntil = delegation.lockUntil();
        }
    }

    /**
     * @notice Computes the address of the delegation for the delegator + slot
     *         combination.
     * @param _delegator The user who is delegating tickets
     * @param _slot The delegation slot
     * @return The address of the delegation.  This is the address that holds
     *         the balance of tickets.
     */
    function computeDelegationAddress(
        address _delegator,
        uint256 _slot
    ) external view returns (address) {
        return _computeAddress(_delegator, _slot);
    }

    /**
     * @notice Sets a new min lock duration. Only callable by the owner.
     * @param _minLockDuration New min lock duration in seconds
     */
    function setMinLockDuration(uint96 _minLockDuration) external onlyOwner {
        _setMinLockDuration(_minLockDuration);
    }

    /**
     * @notice Sets a new max lock duration. Only callable by the owner.
     * @param _maxLockDuration New max lock duration in seconds
     */
    function setMaxLockDuration(uint96 _maxLockDuration) external onlyOwner {
        _setMaxLockDuration(_maxLockDuration);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Computes the address of a delegation contract using the delegator
     *         and slot as a salt. The contract is a clone, also known as
     *         minimal proxy contract.
     * @param _delegator Address of the delegator
     * @param _slot Slot of the delegation
     * @return Address at which the delegation contract will be deployed
     */
    function _computeAddress(
        address _delegator,
        uint256 _slot
    ) internal view returns (address) {
        return _computeAddress(_computeSalt(_delegator, bytes32(_slot)));
    }

    /**
     * @notice Computes the timestamp at which the delegation unlocks, after
     *         which the delegatee can be changed and tickets withdrawn.
     * @param _lockDuration The duration of the lock
     * @return The lock expiration timestamp
     */
    function _computeLockUntil(
        uint96 _lockDuration
    ) internal view returns (uint96) {
        unchecked {
            return uint96(block.timestamp) + _lockDuration;
        }
    }

    /**
     * @notice Delegates tickets from the `_delegation` contract to the
     *         `_delegatee` address.
     * @param _delegation Address of the delegation contract
     * @param _delegatee Address of the delegatee
     */
    function _setDelegateeCall(
        Delegation _delegation,
        address _delegatee
    ) internal {
        bytes4 _selector = ticket.delegate.selector;
        bytes memory _data = abi.encodeWithSelector(_selector, _delegatee);

        _executeCall(_delegation, _data);
    }

    /**
     * @notice Tranfers tickets from the Delegation contract to the `_to`
     *         address.
     * @param _delegation Address of the delegation contract
     * @param _to Address of the recipient
     * @param _amount Amount of tickets to transfer
     */
    function _transferCall(
        Delegation _delegation,
        address _to,
        uint256 _amount
    ) internal {
        bytes4 _selector = ticket.transfer.selector;
        bytes memory _data = abi.encodeWithSelector(_selector, _to, _amount);

        _executeCall(_delegation, _data);
    }

    /**
     * @notice Execute a function call on the delegation contract.
     * @param _delegation Address of the delegation contract
     * @param _data The call data that will be executed
     * @return The return datas from the calls
     */
    function _executeCall(
        Delegation _delegation,
        bytes memory _data
    ) internal returns (bytes[] memory) {
        Delegation.Call[] memory _calls = new Delegation.Call[](1);

        _calls[0] = Delegation.Call({ to: address(ticket), data: _data });

        return _delegation.executeCalls(_calls);
    }

    /**
     * @notice Transfers tickets from a delegation contract to `_to`.
     * @param _delegation Address of the delegation contract
     * @param _to Address of the recipient
     * @param _amount Amount of tickets to transfer
     */
    function _transfer(
        Delegation _delegation,
        address _to,
        uint256 _amount
    ) internal {
        _requireAmountGtZero(_amount);
        _requireDelegationUnlocked(_delegation);

        _transferCall(_delegation, _to, _amount);
    }

    /**
     * @notice Sets a new min lock duration.
     * @dev New min lock duration should be LTE max lock duration.
     * @param _minLockDuration New min lock duration in seconds
     */
    function _setMinLockDuration(uint96 _minLockDuration) internal {
        require(
            _minLockDuration <= maxLockDuration,
            "TWABDelegator/min-lock-duration-is-too-big"
        );

        minLockDuration = _minLockDuration;

        emit MinLockDurationSet(_minLockDuration);
    }

    /**
     * @notice Sets a new max lock duration.
     * @dev New max lock duration should be GTE min lock duration.
     * @param _maxLockDuration New max lock duration in seconds
     */
    function _setMaxLockDuration(uint96 _maxLockDuration) internal {
        require(
            _maxLockDuration >= minLockDuration,
            "TWABDelegator/max-lock-duration-is-too-small"
        );

        maxLockDuration = _maxLockDuration;

        emit MaxLockDurationSet(_maxLockDuration);
    }

    /**
     * @notice Sets a prize pool ticket to which this contract is tied to.
     * @param _ticket A ticket contract address
     */
    function _setTicket(ITicket _ticket) internal {
        require(
            address(_ticket) != address(0),
            "TWABDelegator/tick-not-zero-addr"
        );

        ticket = _ticket;

        emit TicketSet(_ticket);
    }

    /* ============ Modifier/Require Functions ============ */

    /**
     * @notice Require to only allow the delegator to call a function.
     * @param _delegator Address of the delegator
     */
    function _requireDelegator(address _delegator) internal view {
        require(_delegator == msg.sender, "TWABDelegator/not-dlgtr");
    }

    /**
     * @notice Require to verify that `_delegatee` is not address zero.
     * @param _delegatee Address of the delegatee
     */
    function _requireDelegateeNotZeroAddress(address _delegatee) internal pure {
        require(_delegatee != address(0), "TWABDelegator/dlgt-not-zero-addr");
    }

    /**
     * @notice Require to verify that `_amount` is greater than 0.
     * @param _amount Amount to check
     */
    function _requireAmountGtZero(uint256 _amount) internal pure {
        require(_amount > 0, "TWABDelegator/amount-gt-zero");
    }

    /**
     * @notice Require to verify that `_to` is not address zero.
     * @param _to Address to check
     */
    function _requireRecipientNotZeroAddress(address _to) internal pure {
        require(_to != address(0), "TWABDelegator/to-not-zero-addr");
    }

    /**
     * @notice Require to verify if a `_delegation` is locked.
     * @param _delegation Delegation to check
     */
    function _requireDelegationUnlocked(Delegation _delegation) internal view {
        require(
            block.timestamp >= _delegation.lockUntil(),
            "TWABDelegator/delegation-locked"
        );
    }

    /**
     * @notice Require to verify that a `_lockDuration` is zero or is between
     *         min and max lock duration.
     * @param _lockDuration Lock duration to check
     */
    function _requireLockDuration(uint96 _lockDuration) internal view {
        if (_lockDuration != 0) {
            require(
                _lockDuration >= minLockDuration,
                "TWABDelegator/lock-too-short"
            );
            require(
                _lockDuration <= maxLockDuration,
                "TWABDelegator/lock-too-long"
            );
        }
    }
}