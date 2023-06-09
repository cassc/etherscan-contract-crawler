// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCallUpgradable is Initializable {
    /// @dev The original address of this contract
    address private original;

    function __NoDelegateCall_init() internal onlyInitializing {
        __NoDelegateCall_init_unchained();
    }

    function __NoDelegateCall_init_unchained() internal onlyInitializing {
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original, "delegate call check violation");
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}