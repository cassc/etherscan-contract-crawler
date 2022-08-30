// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDEXAccessControl {
    /**
     * Return the locked state of the DEX.
     * In locked state, all transactional functions are disabled.
     * @return `True` if the DEX is in locked state, `false` if the DEX is in unlocked state.
     */
    function locked() external view returns (bool);

    /**
     * Return the deprecated state of the DEX.
     * In deprecated state, no new swaps can be opened. All other functions remain intact.
     * @return `True` if the DEX is in deprecated state.
     */
    function deprecated() external view returns (bool);

    /**
     * Lock the DEX in case of an emergency.
     * @param lock_ `True` to lock the DEX, `false` to unlock the DEX.
     */
    function lock(bool lock_) external;

    /**
     * Deprecate the DEX if a new contract is rolled out.
     * @param deprecate_ `True` to deprecate the DEX, `false` to lift DEX deprecation.
     */
    function deprecate(bool deprecate_) external;

    /**
     * Emitted when the DEX locked state changed, see :sol:func:`locked`.
     * @param locked_ `True` if the DEX was locked, `false` if the DEX was unlocked.
     */
    event Locked(bool locked_);

    /**
     * Emitted when the DEX deprecated state changed, see :sol:func:`deprecated`.
     * @param deprecated_ `True` if the DEX was deprecated, `false` if DEX deprecation was lifted.
     */
    event Deprecated(bool deprecated_);
}