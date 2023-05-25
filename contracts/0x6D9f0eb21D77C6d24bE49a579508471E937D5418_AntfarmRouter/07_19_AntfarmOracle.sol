// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "../libraries/fixedpoint/FixedPoint.sol";

error InvalidToken();

/// @title Antfarm Oracle for AntfarmPair
/// @notice Fixed window oracle that recomputes the average price for the entire period once every period
contract AntfarmOracle {
    using FixedPoint for *;

    uint256 public constant PERIOD = 1 hours;

    address public token1;
    address public pair;

    uint256 public price1CumulativeLast;
    uint32 public blockTimestampLast;
    FixedPoint.uq112x112 public price1Average;

    bool public firstUpdateCall;

    constructor(
        address _token1,
        uint256 _price1CumulativeLast,
        uint32 _blockTimestampLast
    ) {
        token1 = _token1;
        pair = msg.sender;
        price1CumulativeLast = _price1CumulativeLast; // fetch the current accumulated price value (1 / 0)
        blockTimestampLast = _blockTimestampLast;
        firstUpdateCall = true;
    }

    /// @notice Average price update
    /// @param price1Cumulative Price cumulative for the associated AntfarmPair's token1
    /// @param blockTimestamp Last block timestamp for the associated AntfarmPair
    /// @dev Only usable by the associated AntfarmPair
    function update(uint256 price1Cumulative, uint32 blockTimestamp) external {
        require(msg.sender == pair);
        unchecked {
            uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
            // ensure that at least one full period has passed since the last update
            if (timeElapsed >= PERIOD || firstUpdateCall) {
                // overflow is desired, casting never truncates
                // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
                price1Average = FixedPoint.uq112x112(
                    uint224(
                        (price1Cumulative - price1CumulativeLast) / timeElapsed
                    )
                );
                price1CumulativeLast = price1Cumulative;
                blockTimestampLast = blockTimestamp;
                if (firstUpdateCall) {
                    firstUpdateCall = false;
                }
            }
        }
    }

    /// @notice Consult the average price for a given token
    /// @param token Price cumulative for the associated AntfarmPair's token
    /// @param amountIn The amount to get the value of
    /// @return amountOut Return the calculated amount (always return 0 before update has been called successfully for the first time)
    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut)
    {
        if (token == token1) {
            amountOut = price1Average.mul(amountIn).decode144();
        } else {
            revert InvalidToken();
        }
    }
}