// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IWstETHLike.sol";
import "../interfaces/IMagician.sol";
import "../interfaces/ICurvePoolLike.sol";

/// @dev stETH Magician
/// IT IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
abstract contract STETHBaseMagician is IMagician {
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IWstETHLike public constant WSTETH = IWstETHLike(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    ICurvePoolLike public constant CURVE_POOL = ICurvePoolLike(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

    /// @dev Index value for the coin to send (curve stETh/ETH pool)
    // solhint-disable-next-line use-forbidden-name
    int128 public constant STETH_INDEX = 1; // stETH
    /// @dev Index value of the coin to recieve
    // solhint-disable-next-line use-forbidden-name
    int128 public constant ETH_INDEX = 0; // ETH

    /// @notice Calculate the required ETH amount to get the expected number of stETH from the Curve pool.
    /// @dev Present a precision error up to 2e11 (0.002$ if ETH price is 10 000$) in favor of `requiredETH`,
    /// so we will buy a little bit more stETH than needed. Which is fine.
    /// @param _stETHAmountRequired A number of the stETH that we want to get from the Curve pool
    /// @return requiredETH A number of the ETH to buy `_stETHAmountRequired`
    function _calcRequiredETH(uint256 _stETHAmountRequired)
        internal
        view
        returns (uint256 requiredETH, uint256 stETHOutput)
    {
        uint256 one = 1e18; // One coin stETH or ETH, has 18 decimals
        uint256 rate = CURVE_POOL.get_dy(ETH_INDEX, STETH_INDEX, one);
        uint256 multiplied = one * _stETHAmountRequired;
        
        // We have safe math while doing `one * _stETHAmountRequired`. Division should be fine.
        unchecked { requiredETH = multiplied / rate; }

        // `get_dy` is an increasing function.
        // It should take ~ 1 - 6 iterations to `stETHOutput >= _stETHAmountRequired`.
        while (true) {
            stETHOutput = CURVE_POOL.get_dy(ETH_INDEX, STETH_INDEX, requiredETH);

            if (stETHOutput >= _stETHAmountRequired) {
                return (requiredETH, stETHOutput);
            }

            uint256 diff;
            // Because of the condition `stETHOutput >= _stETHAmountRequired`, safe math is not required here.
            unchecked { diff = _stETHAmountRequired - stETHOutput; }
            
            // We may be stuck with a situation where a difference between a `_stETHAmountRequired` and `stETHOutput`
            // will be small and we will need to perform more steps.
            // This expression helps to escape the almost infinite loop.
            if (diff < 1e3) {
                // if `requiredETH` value will be high the `get_dy` function will revert first
                unchecked { requiredETH += 1e3; }
                continue;
            }

            // `one * diff` is safe as `diff` will be lower
            // than `_stETHAmountRequired` for which we have safe math while doing `one * _stETHAmountRequired`.
            unchecked { requiredETH += (one * diff) / rate; }
        }
    }
}