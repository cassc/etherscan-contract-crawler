pragma solidity ^0.6.12;

import "./IUniswapV2Pair.sol";


interface IReserve {
    function uniswapV2Pair() external returns (IUniswapV2Pair);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function swapAndCollect(uint256 tokenAmount) external;

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function swapAndLiquify(uint256 tokenAmount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function buyAndBurn(uint256 usdcAmount) external;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event BuyAndBurn(uint256 tokenAmount, uint256 usdcAmount);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event SwapAndCollect(uint256 tokenAmount, uint256 usdcAmount);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event SwapAndLiquify(
        uint256 tokenSwapped,
        uint256 usdcReceived,
        uint256 tokensIntoLiqudity
    );
}