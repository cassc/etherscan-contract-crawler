// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./CheezburgerStructs.sol";

abstract contract CheezburgerDynamicTokenomics is CheezburgerStructs {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event AppliedTokenomics(DynamicTokenomicsStruct tokenomics);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    uint256 public immutable launchStart = block.timestamp;
    uint256 public immutable EARLY_ACCESS_PREMIUM_DURATION;
    uint16 public immutable EARLY_ACCESS_PREMIUM_START;
    uint16 public immutable EARLY_ACCESS_PREMIUM_END;
    uint16 public immutable SELL_FEE_END;
    uint256 public immutable MAX_WALLET_DURATION;
    uint16 public immutable MAX_WALLET_PERCENT_START;
    uint16 public immutable MAX_WALLET_PERCENT_END;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCT                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    struct DynamicTokenomicsStruct {
        uint16 earlyAccessPremium;
        uint16 sellFee;
        uint16 maxWalletPercentage;
        uint256 maxTokensPerWallet;
    }

    constructor(DynamicSettings memory _fee, DynamicSettings memory _wallet) {
        EARLY_ACCESS_PREMIUM_DURATION = _fee.duration;
        EARLY_ACCESS_PREMIUM_START = _fee.percentStart;
        EARLY_ACCESS_PREMIUM_END = _fee.percentEnd;
        SELL_FEE_END = _fee.percentEnd;
        MAX_WALLET_DURATION = _wallet.duration;
        MAX_WALLET_PERCENT_START = _wallet.percentStart;
        MAX_WALLET_PERCENT_END = _wallet.percentEnd;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Computes current tokenomics values
    /// @return DynamicTokenomics struct with current values
    /// @notice Values will change dynamically based on configured durations and percentages
    function _getTokenomics(
        uint256 _totalSupply
    ) internal view returns (DynamicTokenomicsStruct memory) {
        uint256 _elapsed = block.timestamp - launchStart;
        uint16 _maxWalletPercentage = _currentMaxWalletPercentage(_elapsed);
        return
            DynamicTokenomicsStruct({
                earlyAccessPremium: _currentBuyFeePercent(_elapsed),
                sellFee: SELL_FEE_END,
                maxWalletPercentage: _maxWalletPercentage,
                maxTokensPerWallet: _calculateMaxTokensPerWalletPrecisely(
                    _totalSupply,
                    _maxWalletPercentage
                )
            });
    }

    /// @dev Calculates max tokens per wallet more precisely than standard calculation
    /// @param _totalSupply Current total token supply
    /// @param _maxWalletPercentage Max wallet percentage in basis points (out of 10k)
    /// @return maxTokensPerWallet Precisely calculated max tokens per wallet
    /// @custom:optimizations Uses unchecked math for better gas efficiency
    function _calculateMaxTokensPerWalletPrecisely(
        uint256 _totalSupply,
        uint256 _maxWalletPercentage
    ) private pure returns (uint256) {
        unchecked {
            // Convert the percentage to a fraction and perform the multiplication last to maintain precision
            return (_totalSupply * _maxWalletPercentage + 9999) / 10000;
        }
    }

    /// @dev Gets current buy fee percentage based on elapsed time
    /// @return Current buy fee percentage
    function _currentBuyFeePercent(
        uint256 elapsed
    ) internal view returns (uint16) {
        return
            computeFeePercentage(
                elapsed,
                EARLY_ACCESS_PREMIUM_DURATION,
                EARLY_ACCESS_PREMIUM_START,
                EARLY_ACCESS_PREMIUM_END
            );
    }

    /// @dev Gets current max wallet percentage based on elapsed time
    /// @return Current max wallet percentage
    function _currentMaxWalletPercentage(
        uint256 elapsed
    ) internal view returns (uint16) {
        return
            computeMaxWalletPercentage(
                elapsed,
                MAX_WALLET_DURATION,
                MAX_WALLET_PERCENT_START,
                MAX_WALLET_PERCENT_END
            );
    }

    /// Computes fee percentage based on elapsed time, using an inverted quadratic curve.
    /// The fee percentage starts from a high value and decreases to a low value as time progresses.
    /// This creates a curve that starts fast and then slows down as the elapsed time approaches the total duration.
    ///
    /// @param elapsed The number of seconds that have passed since the launch.
    /// @param duration The total duration in seconds for the decrease.
    /// @param startPercent The starting fee percentage at the launch. Expressed in basis points where 1000 means 10%.
    /// @param endPercent The target fee percentage at the end of the duration. Expressed in basis points where 1000 means 10%.
    /// @return The current fee percentage, expressed in basis points where 1000 means 10%.
    function computeFeePercentage(
        uint256 elapsed,
        uint256 duration,
        uint16 startPercent,
        uint16 endPercent
    ) private pure returns (uint16) {
        if (elapsed >= duration) {
            return endPercent;
        }

        uint16 feePercent;
        /// @solidity memory-safe-assembly
        assembly {
            let scale := 0x0de0b6b3a7640000 // 10^18 in hexadecimal
            // Calculate the position on the curve, x, as a ratio of elapsed time to total duration
            let x := div(mul(elapsed, scale), duration)
            // Subtract squared x from scale to get the inverted position on the curve
            let xx := sub(scale, div(mul(x, x), scale))
            // Calculate delta as a proportion of startPercent scaled by the position on the curve
            let delta := div(mul(startPercent, xx), scale)
            // Ensure feePercent doesn't fall below endPercent
            feePercent := endPercent
            if gt(delta, endPercent) {
                feePercent := delta
            }
        }
        return feePercent;
    }

    /// Computes the maximum wallet percentage based on the elapsed time using a quadratic function.
    /// This function uses the progression of time to determine the maximum wallet percentage allowed,
    /// starting from the `startPercent` and progressively moving towards the `endPercent` in a quadratic manner.
    /// This creates a curve that starts slow and then accelerates as the elapsed time approaches the total duration.
    ///
    /// @param elapsed The number of seconds that have passed since the launch.
    /// @param duration The total duration in seconds for the quadratic progression.
    /// @param startPercent The starting wallet percentage at the launch. Expressed in basis points where 1000 means 10%.
    /// @param endPercent The target wallet percentage at the end of the duration. Expressed in basis points where 1000 means 10%.
    /// @return The current maximum wallet percentage, expressed in basis points where 1000 means 10%.
    function computeMaxWalletPercentage(
        uint256 elapsed,
        uint256 duration,
        uint16 startPercent,
        uint16 endPercent
    ) private pure returns (uint16) {
        // If elapsed time is greater than duration, return endPercent directly
        if (elapsed >= duration) {
            return endPercent;
        }

        uint16 walletPercent;
        /// @solidity memory-safe-assembly
        assembly {
            // Scale factor equivalent to 1 ether in Solidity to handle the fractional values
            let scale := 0x0de0b6b3a7640000 // 10^18 in hexadecimal
            // Calculate the position on the curve, x, as a ratio of elapsed time to total duration
            let x := div(mul(elapsed, scale), duration)
            // Square x to get the position on the curve
            let xx := div(mul(x, x), scale)
            // Calculate the range of percentages and scale by the position on the curve
            let range := sub(endPercent, startPercent)
            let delta := div(mul(range, xx), scale)
            // Add the starting percentage to get the final percentage
            walletPercent := add(startPercent, delta)
        }
        return walletPercent;
    }
}