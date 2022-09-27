// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { IERC20Bridgeable } from "./base/interfaces/IERC20Bridgeable.sol";
import { BRLCTokenBase } from "./BRLCTokenBase.sol";

/**
 * @title BRLCTokenBridgeable contract
 * @dev The BRLC token implementation that supports the bridge operations.
 */
contract BRLCTokenBridgeable is BRLCTokenBase, IERC20Bridgeable {
    /// @dev The address of the bridge.
    address private _bridge;

    // -------------------- Errors -----------------------------------

    /// @dev The transaction sender is not a bridge.
    error UnauthorizedBridge(address account);

    /// @dev The zero amount of tokens is passed during the mint operation.
    error ZeroMintForBridgingAmount();

    /// @dev The zero amount of tokens is passed during the burn operation.
    error ZeroBurnForBridgingAmount();

    // -------------------- Modifiers -----------------------------------

    /// @dev Throws if called by any account other than the bridge.
    modifier onlyBridge() {
        if (_msgSender() != _bridge) {
            revert UnauthorizedBridge(_msgSender());
        }
        _;
    }

    // -------------------- Functions -----------------------------------

    /**
     * @dev The initialize function of the upgradable contract.
     *
     * See details https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable .
     *
     * Requirements:
     *
     * - The passed bridge address must not be zero.
     *
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     * @param bridge_ The address of a bridge contract to support by this contract.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address bridge_
    ) external virtual initializer {
        __BRLCTokenBridgeable_init(name_, symbol_, bridge_);
    }

    function __BRLCTokenBridgeable_init(
        string memory name_,
        string memory symbol_,
        address bridge_
    ) internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __PausableExt_init_unchained();
        __Blacklistable_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
        __BRLCTokenBase_init_unchained();
        __BRLCTokenBridgeable_init_unchained(bridge_);
    }

    function __BRLCTokenBridgeable_init_unchained(address bridge_) internal onlyInitializing {
        require(bridge_ != address(0));
        _bridge = bridge_;
    }

    /**
     * @dev See {IERC20Bridgeable-mintForBridging}.
     *
     * Requirements:
     *
     * - Can only be called by the bridge.
     * - The `amount` value must be greater than zero.
     */
    function mintForBridging(address account, uint256 amount) external onlyBridge returns (bool) {
        if (amount == 0) {
            revert ZeroMintForBridgingAmount();
        }

        _mint(account, amount);
        emit MintForBridging(account, amount);

        return true;
    }

    /**
     * @dev See {IERC20Bridgeable-burnForBridging}.
     *
     * Requirements:
     *
     * - Can only be called by the bridge.
     * - The `amount` value must be greater than zero.
     */
    function burnForBridging(address account, uint256 amount) external onlyBridge returns (bool) {
        if (amount == 0) {
            revert ZeroBurnForBridgingAmount();
        }

        _burn(account, amount);
        emit BurnForBridging(account, amount);

        return true;
    }

    /**
     * @dev See {IERC20Bridgeable-isBridgeSupported}.
     */
    function isBridgeSupported(address bridge_) external view returns (bool) {
        return _bridge == bridge_;
    }

    /// @dev Returns the bridge address.
    function bridge() external view virtual returns (address) {
        return _bridge;
    }

    /**
     * @dev See {IERC20Bridgeable-isIERC20Bridgeable}.
     */
    function isIERC20Bridgeable() external pure returns (bool) {
        return true;
    }
}