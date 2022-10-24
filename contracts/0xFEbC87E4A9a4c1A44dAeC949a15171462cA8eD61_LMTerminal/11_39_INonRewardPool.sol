// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Interface for NonRewardPool for Solidity integration
 */
interface INonRewardPool is IERC20 {
    function addManager(address _manager) external;

    function adminStake(uint256 amount0, uint256 amount1) external;

    function adminSwap(uint256 amount, bool _0for1) external;

    function calculateAmountsMintedSingleToken(uint8 inputAsset, uint256 amount)
        external
        view
        returns (uint256 amount0Minted, uint256 amount1Minted);

    function calculateMintAmount(uint256 amount0, uint256 amount1)
        external
        view
        returns (uint256 mintAmount);

    function calculatePoolMintedAmounts(uint256 amount0, uint256 amount1)
        external
        view
        returns (uint256 amount0Minted, uint256 amount1Minted);

    function collect()
        external
        returns (uint256 collected0, uint256 collected1);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function deposit(uint8 inputAsset, uint256 amount) external;

    function getAmountsForLiquidity(uint128 liquidity)
        external
        view
        returns (uint256 amount0, uint256 amount1);

    function getBufferToken0Balance() external view returns (uint256 amount0);

    function getBufferToken1Balance() external view returns (uint256 amount1);

    function getBufferTokenBalance()
        external
        view
        returns (uint256 amount0, uint256 amount1);

    function getLiquidityForAmounts(uint256 amount0, uint256 amount1)
        external
        view
        returns (uint128 liquidity);

    function getPositionLiquidity() external view returns (uint128 liquidity);

    function getStakedTokenBalance()
        external
        view
        returns (uint256 amount0, uint256 amount1);

    function getTicks() external view returns (int24 tick0, int24 tick1);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function initialize(
        string memory _symbol,
        int24 _tickLower,
        int24 _tickUpper,
        uint24 _poolFee,
        uint256 _tradeFee,
        address _token0,
        address _token1,
        address _terminal,
        address _uniswapPool,
        UniswapContracts memory contracts
    ) external;

    function manager() external view returns (address);

    function mintInitial(
        uint256 amount0,
        uint256 amount1,
        address sender
    ) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function pauseContract() external returns (bool);

    function paused() external view returns (bool);

    function poolFee() external view returns (uint24);

    function reinvest() external;

    function renounceOwnership() external;

    function symbol() external view returns (string memory);

    function token0() external view returns (address);

    function token0DecimalMultiplier() external view returns (uint256);

    function token0Decimals() external view returns (uint8);

    function token1() external view returns (address);

    function token1DecimalMultiplier() external view returns (uint256);

    function token1Decimals() external view returns (uint8);

    function tokenId() external view returns (uint256);

    function tradeFee() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function uniContracts()
        external
        view
        returns (
            address router,
            address quoter,
            address positionManager
        );

    function uniswapPool() external view returns (address);

    function unpauseContract() external returns (bool);

    function withdraw(uint256 amount) external;

    struct UniswapContracts {
        address router;
        address quoter;
        address positionManager;
    }
}