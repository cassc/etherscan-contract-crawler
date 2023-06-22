// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool `LP` Actions
 */
interface IPoolLPActions {

    /**
     *  @notice Called by `LP` owners to approve transfer of an amount of `LP` to a new owner.
     *  @dev    Intended for use by the `PositionManager` contract.
     *  @param  spender_ The new owner of the `LP`.
     *  @param  indexes_ Bucket indexes from where `LP` are transferred.
     *  @param  amounts_ The amounts of `LP` approved to transfer (`WAD` precision).
     */
    function increaseLPAllowance(
        address spender_,
        uint256[] calldata indexes_,
        uint256[] calldata amounts_
    ) external;

    /**
     *  @notice Called by `LP` owners to decrease the amount of `LP` that can be spend by a new owner.
     *  @dev    Intended for use by the `PositionManager` contract.
     *  @param  spender_ The new owner of the `LP`.
     *  @param  indexes_ Bucket indexes from where `LP` are transferred.
     *  @param  amounts_ The amounts of `LP` disapproved to transfer (`WAD` precision).
     */
    function decreaseLPAllowance(
        address spender_,
        uint256[] calldata indexes_,
        uint256[] calldata amounts_
    ) external;

    /**
     *  @notice Called by `LP` owners to decrease the amount of `LP` that can be spend by a new owner.
     *  @param  spender_ Address that is having it's allowance revoked.
     *  @param  indexes_ List of bucket index to remove the allowance from.
     */
    function revokeLPAllowance(
        address spender_,
        uint256[] calldata indexes_
    ) external;

    /**
     *  @notice Called by `LP` owners to allow addresses that can transfer LP.
     *  @dev    Intended for use by the `PositionManager` contract.
     *  @param  transferors_ Addresses that are allowed to transfer `LP` to new owner.
     */
    function approveLPTransferors(
        address[] calldata transferors_
    ) external;

    /**
     *  @notice Called by `LP` owners to revoke addresses that can transfer `LP`.
     *  @dev    Intended for use by the `PositionManager` contract.
     *  @param  transferors_ Addresses that are revoked to transfer `LP` to new owner.
     */
    function revokeLPTransferors(
        address[] calldata transferors_
    ) external;

    /**
     *  @notice Called by `LP` owners to transfers their `LP` to a different address. `approveLpOwnership` needs to be run first.
     *  @dev    Used by `PositionManager.memorializePositions()`.
     *  @param  owner_    The original owner address of the position.
     *  @param  newOwner_ The new owner address of the position.
     *  @param  indexes_  Array of price buckets index at which `LP` were moved.
     */
    function transferLP(
        address owner_,
        address newOwner_,
        uint256[] calldata indexes_
    ) external;
}