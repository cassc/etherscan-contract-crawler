// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../algebra/core/contracts/interfaces/IAlgebraPool.sol";

interface IHypervisor {
    /// @notice Deposit tokens
    /// @param deposit0 Amount of token0 transfered from sender to Hypervisor
    /// @param deposit1 Amount of token1 transfered from sender to Hypervisor
    /// @param to Address to which liquidity tokens are minted
    /// @param from Address from which asset tokens are transferred
    /// @param inMin min spend for directDeposit is true
    /// @return shares Quantity of liquidity tokens minted as a result of deposit
    function deposit(
        uint256 deposit0,
        uint256 deposit1,
        address to,
        address from,
        uint256[4] memory inMin
    ) external returns (uint256 shares);

    /// @param shares Number of liquidity tokens to redeem as pool assets
    /// @param to Address to which redeemed pool assets are sent
    /// @param from Address from which liquidity tokens are sent
    /// @param minAmounts min amount0,1 returned for shares of liq
    /// @return amount0 Amount of token0 redeemed by the submitted liquidity tokens
    /// @return amount1 Amount of token1 redeemed by the submitted liquidity tokens
    function withdraw(
        uint256 shares,
        address to,
        address from,
        uint256[4] memory minAmounts
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Compound pending fees
    /// @param inMin min spend
    /// @return baseToken0Owed Pending fees of base token0
    /// @return baseToken1Owed Pending fees of base token1
    /// @return limitToken0Owed Pending fees of limit token0
    /// @return limitToken1Owed Pending fees of limit token1
    function compound(uint256[4] memory inMin)
        external
        returns (
            uint128 baseToken0Owed,
            uint128 baseToken1Owed,
            uint128 limitToken0Owed,
            uint128 limitToken1Owed
        );

    /// @param _baseLower The lower tick of the base position
    /// @param _baseUpper The upper tick of the base position
    /// @param _limitLower The lower tick of the limit position
    /// @param _limitUpper The upper tick of the limit position
    /// @param  inMin min spend
    /// @param  outMin min amount0,1 returned for shares of liq
    /// @param _feeRecipient Address of recipient of 10% of earned fees since last rebalance
    function rebalance(
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address _feeRecipient,
        uint256[4] memory inMin,
        uint256[4] memory outMin
    ) external;

    function addBaseLiquidity(
        uint256 amount0,
        uint256 amount1,
        uint256[2] memory minIn
    ) external;

    function addLimitLiquidity(
        uint256 amount0,
        uint256 amount1,
        uint256[2] memory minIn
    ) external;

    function pullLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 shares,
        uint256[2] memory amountMin
    ) external returns (uint256 base0, uint256 base1);

    function pool() external view returns (IAlgebraPool);

    function currentTick() external view returns (int24 tick);

    function tickSpacing() external view returns (int24 spacing);

    function baseLower() external view returns (int24 tick);

    function baseUpper() external view returns (int24 tick);

    function limitLower() external view returns (int24 tick);

    function limitUpper() external view returns (int24 tick);

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function deposit0Max() external view returns (uint256);

    function deposit1Max() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function getTotalAmounts() external view returns (uint256 total0, uint256 total1);

    function getBasePosition()
        external
        view
        returns (
            uint256 liquidity,
            uint256 total0,
            uint256 total1
        );

    function totalSupply() external view returns (uint256);

    function setWhitelist(address _address) external;

    function setFee(uint8 newFee) external;

    function removeWhitelisted() external;

    function transferOwnership(address newOwner) external;

    function toggleDirectDeposit() external;

    function directDeposit() external view returns (bool);

    function whitelistedAddress() external returns (address);
}