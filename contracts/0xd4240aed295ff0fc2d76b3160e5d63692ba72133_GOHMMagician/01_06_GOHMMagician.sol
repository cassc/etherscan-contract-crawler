// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IMagician.sol";
import "./interfaces/IOlympusStakingV3Like.sol";
import "./interfaces/IGOHMLikeV2.sol";
import "./interfaces/IBalancerVaultLike.sol";

/// @dev gOHM Magician
/// IT IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
contract GOHMMagician is IMagician {
    /// @dev Value for gOHM -> OHMv2 balances calculation
    uint256 public constant TWO_EXTRA_WEIS = (1 wei) + (1 wei);

    /// @dev Argument for Olympus Staking `stake()`. Mint gOHM tokens instantly on stake.
    bool public constant OLYMPUS_STAKING_CLAIM = true;

    /// @dev Argument for Olympus Staking `stake()` or `unstake()`. Receive gOHM tokens instead of rebasing sOHM.
    bool public constant OLYMPUS_STAKING_REBASING = false;

    /// @dev Argument for Olympus Staking `unstake()`. Do not trigger rebase() of OHM tokens, save gas.
    bool public constant OLYMPUS_STAKING_TRIGGER = false;

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

    /// @dev 10 ** (gOHM decimals), constant and equal to 10**18.
    // solhint-disable-next-line var-name-mixedcase
    uint256 public immutable TEN_POW_GOHM_DECIMALS;

    /// @dev Original token, OHMv2.
    // solhint-disable-next-line var-name-mixedcase
    address public immutable OHM;

    /// @dev Wrapper for rebasing sOHM token.
    // solhint-disable-next-line var-name-mixedcase
    IGOHMLikeV2 public immutable GOHM;

    /// @dev Olympus staking contract for OHMv2 <-> gOHM wrapping and unwrapping.
    // solhint-disable-next-line var-name-mixedcase
    IOlympusStakingV3Like public immutable OLYMPUS_STAKING_V3;

    error InvalidAsset();
    error InvalidBalancerPool();

    constructor(
        address _quote,
        IOlympusStakingV3Like _olympusStakingV3,
        IBalancerVaultLike _balancerVault,
        bytes32 _balancerOhmPool
    ) {
        QUOTE = _quote;

        GOHM = IGOHMLikeV2(_olympusStakingV3.gOHM());
        TEN_POW_GOHM_DECIMALS = 10 ** GOHM.decimals();
        OHM = _olympusStakingV3.OHM();

        OLYMPUS_STAKING_V3 = _olympusStakingV3;
        BALANCER_VAULT = _balancerVault;
        BALANCER_OHM_POOL = _balancerOhmPool;

        if (!verifyPoolAndVault(_balancerVault, _balancerOhmPool)) revert InvalidBalancerPool();
    }

    /// @inheritdoc IMagician
    function towardsNative(address _asset, uint256 _amount) external returns (address, uint256) {
        if (_asset != address(GOHM)) revert InvalidAsset();

        GOHM.approve(address(OLYMPUS_STAKING_V3), _amount);

        uint256 ohmAmount = OLYMPUS_STAKING_V3.unstake(
            address(this),
                _amount,
                OLYMPUS_STAKING_TRIGGER,
                OLYMPUS_STAKING_REBASING
        );

        return (QUOTE, _swapOHMForQuote(ohmAmount));
    }

    /// @inheritdoc IMagician
    function towardsAsset(address _asset, uint256 _amount) external returns (address, uint256) {
        if (_asset != address(GOHM)) revert InvalidAsset();

        uint256 ohmAmount = ohmBalanceFrom(_amount);
        uint256 quoteSpent = _swapQuoteForOHM(ohmAmount);

        IERC20(OHM).approve(address(OLYMPUS_STAKING_V3), ohmAmount);
        OLYMPUS_STAKING_V3.stake(address(this), ohmAmount, OLYMPUS_STAKING_REBASING, OLYMPUS_STAKING_CLAIM);

        return (address(GOHM), quoteSpent);
    }

    /// @dev calculate gOHM -> OHMv2 amounts.
    ///     Our goal is to calculate right amount of OHM that will give us `_gOhmAmount` when we stake it.
    ///     2 extra weis added to make sure that we will not receive less than `_gOhmAmount`.
    ///     First `1 wei` explanation:
    ///     We can lose up to one wei on step of OHM -> gOHM inside OlympusStaking.stake():
    ///     OHM -> gOHM formula: `ohmAmount * (10**18) / (index);`.
    ///     The operation of `/(index)` can cause the lost of [0..index-1] from `ohmAmount * (10**18)`.
    ///     If we add 1 wei to `ohmAmount`, `(ohmAmount + 1 wei) * (10**18) > ohmAmount * (10**18) - (index - 1)`.
    ///     Index has 9 basis points, it will work until it will not increase 10**18.
    ///     Second `1 wei` explanation:
    ///     We can lose up to one wei on step of gOHM -> OHM calculation below.
    ///     gOHM -> OHM formula: `(gOhmAmount * index) / (10**18)`.
    ///     The operation of `/ (10**18)` can cause the lost of [0..10**18 - 1] from `(gOhmAmount * index)`.
    ///     Let's add extra wei to gOHM -> OHM formula.
    ///     Then on gOHM -> OHM calculations, worst case scenario:
    ///     ((gOhmAmount * index) / (10**18) + 1) * (10**18) / (index) >=
    ///     = (gOhmAmount * index - (10**18 - 1) + 10**18) / index =
    ///     = (gOhmAmount * index + 1) / index >= gOhmAmount
    /// @param _gOhmAmount input amount of gOHM
    /// @return ohmAmount equal amount in OHMv2
    function ohmBalanceFrom(uint256 _gOhmAmount) public view returns (uint256 ohmAmount) {
        ohmAmount = _gOhmAmount * GOHM.index();

        // we can safely divide by 10 ** 18 and add 2
        unchecked {
            ohmAmount = ohmAmount / TEN_POW_GOHM_DECIMALS + TWO_EXTRA_WEIS;
        }
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