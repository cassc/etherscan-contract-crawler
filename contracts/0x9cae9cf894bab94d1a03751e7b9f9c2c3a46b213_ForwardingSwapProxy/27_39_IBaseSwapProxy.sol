import "./IVault.sol";
import "./IERC20Extension.sol";

import "./IPermit2.sol";

interface IBaseSwapProxy {
    /// @dev Event used when an admin updates the feePercentage
    event SetFee(address indexed from, uint256 fee);
    /// @dev Event emitted when permit2 is set
    event Permit2Set(IPermit2 permit2, address indexed setter);
    /// @dev Event used when an admin updates the vault contract
    event VaultSet(IVault vault, address indexed setter);
    /// @dev Event used whenever a user executes a proxy swap through the contract
    event ProxySwapWithFee(
        address indexed _fromToken,
        address indexed _toToken,
        uint256 amountIn,
        uint256 amountOut,
        uint256 feeTotal
    );

    error NativePermitNotAllowed();

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

    function proxySwapWithPermit(
        IERC20Extension _fromToken,
        IERC20Extension _toToken,
        SwapParams calldata _swapParams,
        uint256 _minimumReturnAmount,
        uint256 _gasRefund,
        IPermit2.PermitSingle calldata _permit,
        bytes calldata _signature
    ) external;

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

    /// @notice This function calculates the exchange rate between the _fromToken and _toToken
    /// @dev This function tries to lookup the rate through chainlink first and if the request fails it then looks for a rate through Uniswap V2. If no rate can be found the function reverts.
    /// @param _fromToken The token the user is swapping with
    /// @param _toToken The token the user wwants
    /// @return The exchange rate
    function getExchangeRate(IERC20Extension _fromToken, IERC20Extension _toToken) external view returns (uint256);

    /// @notice This function tries to calculate the exchange rate between the two tokens using chainlink
    /// @dev This function returns 0 if no rate can be found
    /// @param _fromToken The token the user is swapping with
    /// @param _toToken The token the user wwants
    /// @return exchangeRate The exchange rate or 0 if no rate is found
    function getChainlinkRate(
        IERC20Extension _fromToken,
        IERC20Extension _toToken
    ) external view returns (uint256 exchangeRate);

    /// @notice This function tries to find a rate using Uniswap V2. It gets the spot ratio between _fromToken and _toToken. This is typically a pretty unsafe operation and susceptible to MEV and sandwich attacks. This is somewhat mitigated because all swap transactions will be submitted through flashbots, which is private RPC.
    /// @param _fromToken The token the user is swapping with
    /// @param _toToken The token the user wwants
    /// @return exchangeRate The exchange rate or 0 if no rate is found
    function getUniswapV2Rate(IERC20Extension _fromToken, IERC20Extension _toToken) external view returns (uint256);

    /// @notice This function calculates the percentage fee amount in ETH for the _fromToken the user is swapping from. It is deducts the _gasRefund value to ensure the user is charged correctly
    /// @param _fromToken The token the user is swapping from
    /// @param _amount The amount they are swapping with
    /// @param _gasRefund The gas refund required to cover the proxied swap
    /// @return feeTotalInETH The fee total priced in ETH
    /// @return feeTotalInFromToken The fee total priced in _fromToken
    function calculatePercentageFeeInETH(
        IERC20Extension _fromToken,
        uint256 _amount,
        uint256 _gasRefund
    ) external view returns (uint256 feeTotalInETH, uint256 feeTotalInFromToken);
}