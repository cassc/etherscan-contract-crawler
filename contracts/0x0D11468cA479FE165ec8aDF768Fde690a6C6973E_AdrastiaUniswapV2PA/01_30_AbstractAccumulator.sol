//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

pragma experimental ABIEncoderV2;

import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin-v4/contracts/utils/math/SafeCast.sol";

import "../interfaces/IAccumulator.sol";

abstract contract AbstractAccumulator is IERC165, IAccumulator {
    uint256 public immutable override changePrecision = 10**8;

    uint256 public immutable override updateThreshold;

    constructor(uint256 updateThreshold_) {
        updateThreshold = updateThreshold_;
    }

    /// @inheritdoc IAccumulator
    function updateThresholdSurpassed(address token) public view virtual override returns (bool) {
        return changeThresholdSurpassed(token, updateThreshold);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccumulator).interfaceId;
    }

    function calculateChange(uint256 a, uint256 b) internal view virtual returns (uint256 change, bool isInfinite) {
        // Ensure a is never smaller than b
        if (a < b) {
            uint256 temp = a;
            a = b;
            b = temp;
        }

        // a >= b

        if (a == 0) {
            // a == b == 0 (since a >= b), therefore no change
            return (0, false);
        } else if (b == 0) {
            // (a > 0 && b == 0) => change threshold passed
            // Zero to non-zero always returns true
            return (0, true);
        }

        unchecked {
            uint256 delta = a - b; // a >= b, therefore no underflow
            uint256 preciseDelta = delta * changePrecision;

            // If the delta is so large that multiplying by CHANGE_PRECISION overflows, we assume that
            // the change threshold has been surpassed.
            // If our assumption is incorrect, the accumulator will be extra-up-to-date, which won't
            // really break anything, but will cost more gas in keeping this accumulator updated.
            if (preciseDelta < delta) return (0, true);

            change = preciseDelta / b;
            isInfinite = false;
        }
    }

    function changeThresholdSurpassed(
        uint256 a,
        uint256 b,
        uint256 changeThreshold
    ) internal view virtual returns (bool) {
        (uint256 change, bool isInfinite) = calculateChange(a, b);

        return isInfinite || change >= changeThreshold;
    }
}