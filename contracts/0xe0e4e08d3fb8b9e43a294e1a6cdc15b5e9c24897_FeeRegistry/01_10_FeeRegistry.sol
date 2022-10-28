// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// ==========================================
// |            ____  _ __       __         |
// |           / __ \(_) /______/ /_        |
// |          / /_/ / / __/ ___/ __ \       |
// |         / ____/ / /_/ /__/ / / /       |
// |        /_/   /_/\__/\___/_/ /_/        |
// |                                        |
// ==========================================
// ================= Pitch ==================
// ==========================================

// Authored by Pitch Research: [email protected]

import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

contract FeeRegistry is OwnableUpgradeable, UUPSUpgradeable {
    /// @notice Fee deposit address.
    address public feeAddress;

    /// @notice The fee amount (in bips).
    uint256 public unmanagedLPFee;

    // Constants
    uint256 public constant FEE_DENOMINATOR = 10000;

    uint256 public veRevenueFee;

    /* ========== INITIALIZER FUNCTION ========== */
    function initialize(address _feeAddress) public initializer {
        __UUPSUpgradeable_init_unchained();
        __Context_init_unchained();
        __Ownable_init_unchained();

        feeAddress = _feeAddress;
    }

    /// @notice Owner set's the fee address.
    /// @param _feeAddress Where fees are paid to.
    function setFeeAddress(address _feeAddress) external onlyOwner {
        emit FeeAddressUpdated(feeAddress, _feeAddress);
        feeAddress = _feeAddress;
    }

    /// @notice Set's the amount of the fee.
    /// @param _fee Amount of the fee (divided by 10000, so in bips)
    function setUnmanagedLPFee(uint256 _fee) external onlyOwner {
        emit FeeUpdated(unmanagedLPFee, _fee);
        unmanagedLPFee = _fee;
    }

    function setVeRevenueFee(uint256 _fee) external onlyOwner {
        emit FeeUpdated(veRevenueFee, _fee);
        veRevenueFee = _fee;
    }

    /* ========== OWNER FUNCTIONS ========== */

    /// @notice Overrides the function in UUPSUpgradeable to include access control.
    /// @param newImplementation The address of the upgraded contract.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /* ========== END OWNER FUNCTIONS ========== */

    /* ========== CONVERTER FUNCTIONS ========== */
    event FeeUpdated(uint256 oldFeeBps, uint256 newFeeBps);
    event FeeAddressUpdated(address oldAddress, address newAddress);
}