// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { StoragePlaceholder200 } from "@cloudwalkinc/brlc-contracts/contracts/storage/StoragePlaceholder200.sol";

import { IBridgeGuard } from "./interfaces/IBridgeGuard.sol";
import { BridgeGuardStorage } from "./BridgeGuardStorage.sol";

/**
 * @title BridgeGuard contract
 * @author CloudWalk Inc.
 */
contract BridgeGuard is Initializable, OwnableUpgradeable, StoragePlaceholder200, BridgeGuardStorage, IBridgeGuard {
    /// @dev The caller is not the configured bridge address.
    error NotBridge();

    /// @dev The passed chain id is zero.
    error ZeroChainId();

    /// @dev The passed token address is zero address.
    error ZeroTokenAddress();

    /// @dev The passed bridge address is zero address.
    error ZeroBridgeAddress();

    /// @dev The passed time frame is zero.
    error ZeroTimeFrame();

    /// @dev The passed volume limit is zero.
    error ZeroVolumeLimit();

    /**
     * @dev Throws if called by any account other than the bridge.
     */
    modifier onlyBridge() {
        if (_msgSender() != _bridge) {
            revert NotBridge();
        }
        _;
    }

    /**
     * @dev Constructor that prohibits the initialization of the implementation of the upgradable contract.
     *
     * See details
     * https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
     *
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev The initializer of the upgradable contract.
     *
     * See details https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
     */
    function initialize(address bridge_) external initializer {
        if (bridge_ == address(0)) {
            revert ZeroBridgeAddress();
        }
        __BridgeGuard_init(bridge_);
    }

    /**
     * @dev The internal initializer of the upgradable contract.
     *
     * See {BridgeGuard-initialize}.
     */
    function __BridgeGuard_init(address bridge_) internal {
        __Ownable_init_unchained();
        __BridgeGuard_init_unchained(bridge_);
    }

    /**
     * @dev The unchained internal initializer of the upgradable contract.
     *
     * See {BridgeGuard-initialize}.
     */
    function __BridgeGuard_init_unchained(address bridge_) internal {
        _bridge = bridge_;
    }

    /**
     * @dev See {IBridgeGuard - validateAccommodation}.
     */
    function validateAccommodation(
        uint256 chainId,
        address token,
        address account,
        uint256 amount
    ) external onlyBridge returns (uint256) {
        Guard storage guard = _accommodationGuards[chainId][token];

        uint256 timeFrame = guard.timeFrame;
        if (timeFrame == 0) {
            return uint256(ValidationError.TIME_FRAME_NOT_SET);
        }

        if (block.timestamp - guard.lastResetTime > timeFrame) {
            guard.lastResetTime = block.timestamp;
        } else {
            amount += guard.currentVolume;
        }

        if (amount > guard.volumeLimit) {
            return uint256(ValidationError.VOLUME_LIMIT_REACHED);
        }
        guard.currentVolume = amount;
        account; // Silences a compiler warning about the unused parameter.

        return uint256(ValidationError.NO_ERROR);
    }

    /**
     * @dev Configures selected address as the new bridge address.
     *
     * Requirements:
     *
     * - The new bridge address should not be zero address.
     * @param newBridge The new address of the bridge.
     */
    function setBridge(address newBridge) external onlyOwner {
        if (newBridge == address(0)) {
            revert ZeroBridgeAddress();
        }
        _bridge = newBridge;
    }

    /**
     * @dev See {IBridgeGuard - configureAccommodationGuard}
     *
     * Requirements:
     *
     * - The id of the chain should not be zero.
     * - The address of the token should not be zero address.
     * - The time frame should not be zero.
     * - The volume limit should not be zero.
     */
    function configureAccommodationGuard(
        uint256 chainId,
        address token,
        uint256 newTimeFrame,
        uint256 newVolumeLimit
    ) external onlyOwner {
        if (chainId == 0) {
            revert ZeroChainId();
        }
        if (token == address(0)) {
            revert ZeroTokenAddress();
        }
        if (newTimeFrame == 0) {
            revert ZeroTimeFrame();
        }
        if (newVolumeLimit == 0) {
            revert ZeroVolumeLimit();
        }

        Guard storage guard = _accommodationGuards[chainId][token];
        guard.timeFrame = newTimeFrame;
        guard.volumeLimit = newVolumeLimit;
        guard.lastResetTime = block.timestamp;

        emit ConfigureAccommodationGuard(chainId, token, newTimeFrame, newVolumeLimit);
    }

    /**
     * @dev Resets configuration of the accommodation guard for a selected chain and token.
     *
     * Requirements:
     *
     * - The id of the chain should not be zero.
     * - The address of the token should not be zero address.
     * @param chainId The id of the selected chain.
     * @param token The address of the selected token.
     */
    function resetAccommodationGuard(uint256 chainId, address token) external onlyOwner {
        if (chainId == 0) {
            revert ZeroChainId();
        }
        if (token == address(0)) {
            revert ZeroTokenAddress();
        }
        _accommodationGuards[chainId][token] = Guard(0, 0, 0, 0);
        emit ResetAccommodationGuard(chainId, token);
    }

    /**
     * @dev Returns accommodation guard configuration for a selected chain and token.
     * @param chainId The id of the selected chain.
     * @param token The address of the selected token.
     */
    function getAccommodationGuard(uint256 chainId, address token) external view returns (Guard memory) {
        return _accommodationGuards[chainId][token];
    }

    /**
     * @dev Returns address of the current bridge account.
     */
    function bridge() external view returns (address) {
        return _bridge;
    }
}