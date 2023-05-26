import "./IERC20Extension.sol";

/// @title IForwardingSwapProxy
/// @notice This swap proxy contract is for forwarding swaps, meaning the user will provide a data field and a destination contract and this contract will then execute it on the users behalf. Other parameters are provided to this contract to allow for safe validation of the users request.
interface IForwardingSwapProxy {
    /// @dev Event used whenever a user executes a proxy swap through the contract
    event ProxySwapWithFee(
        address indexed _fromToken,
        address indexed _toToken,
        uint256 amountIn,
        uint256 amountOut,
        uint256 feeTotal
    );

    /// @notice Struct containing the required fields to forward a swap transaction
    /// @param to The address of where to execute the proxy swap
    /// @param amount The amount to swap, this is 0 if the user is swapping ETH otherwise its the amount of tokens
    /// @param value The value in ETH if the user is swapping from ETH. Amount will be 0 in this case
    /// @param data The data field of the swap transaction
    struct SwapParams {
        address to;
        uint256 amount;
        uint256 value;
        bytes data;
    }

    /// @notice This method will forward a swap for a user, the user provides the swap parameters and this method will execute them on the users behalf. This method also will take a fee from the user
    /// @param _fromToken The token the user is swapping from
    /// @param _toToken The toke the user wants to swap to
    /// @param _swapParams The required fields to execute the proxy swap
    /// @param _gasRefund The amount in ETH to refund Aurox for proxying the swap
    /// @param _minimumReturnAmount The minimum amount of _toToken's to receive for the swap. This is the final return amount for the user, after the fee has been deducted
    function proxySwapWithFee(
        IERC20Extension _fromToken,
        IERC20Extension _toToken,
        SwapParams calldata _swapParams,
        uint256 _gasRefund,
        uint256 _minimumReturnAmount
    ) external payable;
}