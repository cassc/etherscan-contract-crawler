//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface IBridgeSwapper {
    event Swapped(address _inputToken, uint256 _amountIn, address _outputToken, uint256 _amountOut);

    /**
    * @notice Perform an exchange between two tokens
    * @dev Index values can usually be found via the constructor arguments (if not hardcoded)
    * @param _indexIn Index value for the token to send
    * @param _indexOut Index valie of the token to receive
    * @param _amountIn Amount of `_indexIn` being exchanged
    * @return Actual amount of `_indexOut` received
    */
    function exchange(uint256 _indexIn, uint256 _indexOut, uint256 _amountIn, uint256 _minAmountOut) external returns (uint256);
}