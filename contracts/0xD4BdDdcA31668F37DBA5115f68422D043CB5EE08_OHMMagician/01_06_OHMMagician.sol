// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IMagician.sol";
import "./interfaces/IOlympusStakingV3Like.sol";
import "./interfaces/IGOHMLikeV2.sol";
import "./interfaces/IBalancerVaultLike.sol";

/// @dev OHM Magician
/// IT IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
/// we made it because current Uni pool is empty
/// it could be base for `GOHMMagician` but `GOHMMagician` is already deployed
contract OHMMagician is IMagician {
    /// @dev Limit for OHMv2 swap.
    uint256 public constant SWAP_AMOUNT_OUT_LIMIT = type(uint256).max;

    /// @dev Limit for OHMv2 swap.
    uint256 public constant SWAP_AMOUNT_IN_LIMIT = 1;

    /// @dev Required for OHMv2 swap.
    // solhint-disable-next-line var-name-mixedcase
    IBalancerVaultLike public immutable BALANCER_VAULT;

    /// @dev OHMv2 pool that is used for swap.
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public immutable BALANCER_OHM_POOL;

    /// @dev The address of quote token.
    // solhint-disable-next-line var-name-mixedcase
    address public immutable QUOTE;

    /// @dev Original token, OHMv2.
    // solhint-disable-next-line var-name-mixedcase
    address public immutable OHM;

    error InvalidAsset();
    error InvalidBalancerPool();

    constructor(
        address _quote,
        IOlympusStakingV3Like _olympusStakingV3,
        IBalancerVaultLike _balancerVault,
        bytes32 _balancerOhmPool
    ) {
        QUOTE = _quote;

        OHM = _olympusStakingV3.OHM();

        BALANCER_VAULT = _balancerVault;
        BALANCER_OHM_POOL = _balancerOhmPool;

        if (!verifyPoolAndVault(_balancerVault, _balancerOhmPool)) revert InvalidBalancerPool();
    }

    /// @inheritdoc IMagician
    function towardsNative(address _asset, uint256 _amount) external returns (address asset, uint256 amount) {
        if (_asset != address(OHM)) revert InvalidAsset();

        return (QUOTE, _swapOHMForQuote(_amount));
    }

    /// @inheritdoc IMagician
    function towardsAsset(address _asset, uint256 _amount) external returns (address asset, uint256 quoteSpent) {
        if (_asset != address(OHM)) revert InvalidAsset();

        return (address(OHM), _swapQuoteForOHM(_amount));
    }

    /// @dev verify the Balancer pool and the vault. Sanity check for vault address is a call of getPoolTokens(_poolId).
    ///     Pool is valid if it has OHMv2 and quote tokens.
    /// @param _balancerVault address of the Balancer vault
    /// @param _poolId pool id
    /// @return true if the pool is valid for the swap
    function verifyPoolAndVault(IBalancerVaultLike _balancerVault, bytes32 _poolId) public view returns (bool) {
        (address[] memory tokens,,) = IBalancerVaultLike(_balancerVault).getPoolTokens(_poolId);
        bool isQuote;
        bool isOhm;

        for (uint256 i; i < tokens.length && !(isOhm && isQuote);) {
            if (!isOhm && tokens[i] == OHM) {
                isOhm = true;
            } else if (!isQuote && tokens[i] == QUOTE) {
                isQuote = true;
            }

            unchecked {
                i++;
            }
        }

        return isQuote && isOhm;
    }

    /// @dev it swaps OHMv2 for quote token
    /// @param _ohmAmount exact amountIn of OHMv2 token
    /// @return quoteReceived amount of quote token received
    function _swapOHMForQuote(uint256 _ohmAmount) internal returns (uint256 quoteReceived) {
        IERC20(OHM).approve(address(BALANCER_VAULT), _ohmAmount);
        quoteReceived = _swapAmountIn(OHM, QUOTE, _ohmAmount, BALANCER_OHM_POOL);
    }

    /// @dev it swaps quote token for OHMv2
    /// @param _ohmAmount exact amountOut of OHMv2
    /// @return quoteSpent amount of quote token spent
    function _swapQuoteForOHM(uint256 _ohmAmount) internal returns (uint256 quoteSpent) {
        IERC20(QUOTE).approve(address(BALANCER_VAULT), SWAP_AMOUNT_OUT_LIMIT);
        quoteSpent = _swapAmountOut(QUOTE, OHM, _ohmAmount, BALANCER_OHM_POOL);
    }

    /// @dev it swaps _tokenIn for _tokenOut
    /// @param _tokenIn address of the tokenIn
    /// @param _tokenOut address of the tokenOut
    /// @param _amountOut amount of the tokenOut to receive
    /// @param _poolId balancer pool id
    /// @return amount of _tokenIn spent
    function _swapAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut,
        bytes32 _poolId
    ) internal returns (uint256) {
        IBalancerVaultLike.SingleSwap memory singleSwap = IBalancerVaultLike.SingleSwap(
            _poolId, IBalancerVaultLike.SwapKind.GIVEN_OUT, address(_tokenIn), address(_tokenOut), _amountOut, ""
        );

        IBalancerVaultLike.FundManagement memory funds = IBalancerVaultLike.FundManagement(
            address(this), false, payable(address(this)), false
        );

        return BALANCER_VAULT.swap(singleSwap, funds, SWAP_AMOUNT_OUT_LIMIT, block.timestamp);
    }

    /// @dev it swaps _tokenIn for _tokenOut
    /// @param _tokenIn address of the tokenIn
    /// @param _tokenOut address of the tokenOut
    /// @param _amountIn amount of the tokenIn to spend
    /// @param _poolId balancer pool id
    /// @return amount of _tokenOut received
    function _swapAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        bytes32 _poolId
    ) internal returns (uint256) {
        IBalancerVaultLike.SingleSwap memory singleSwap = IBalancerVaultLike.SingleSwap(
            _poolId, IBalancerVaultLike.SwapKind.GIVEN_IN, address(_tokenIn), address(_tokenOut), _amountIn, ""
        );

        IBalancerVaultLike.FundManagement memory funds = IBalancerVaultLike.FundManagement(
            address(this), false, payable(address(this)), false
        );

        return BALANCER_VAULT.swap(singleSwap, funds, SWAP_AMOUNT_IN_LIMIT, block.timestamp);
    }
}