// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IPool.sol";
import "../interfaces/IPosition.sol";

interface IFactory {
    event PoolCreated(
        address poolAddress,
        uint256 fee,
        uint256 tickSpacing,
        int32 activeTick,
        int256 lookback,
        uint64 protocolFeeRatio,
        IERC20 tokenA,
        IERC20 tokenB
    );
    event SetFactoryProtocolFeeRatio(uint64 protocolFeeRatio);
    event SetFactoryOwner(address owner);

    /// @notice creates new pool
    /// @param _fee is a rate in prbmath 60x18 decimal format
    /// @param _tickSpacing  1.0001^tickSpacing is the bin width
    /// @param _activeTick initial activeTick of the pool
    /// @param _lookback TWAP lookback in whole seconds
    /// @param _tokenA ERC20 token
    /// @param _tokenB ERC20 token
    function create(
        uint256 _fee,
        uint256 _tickSpacing,
        int256 _lookback,
        int32 _activeTick,
        IERC20 _tokenA,
        IERC20 _tokenB
    ) external returns (IPool);

    function lookup(
        uint256 fee,
        uint256 tickSpacing,
        int256 lookback,
        IERC20 tokenA,
        IERC20 tokenB
    ) external view returns (IPool);

    function owner() external view returns (address);

    function position() external view returns (IPosition);

    /// @notice protocolFeeRatio ratio of the swap fee that is kept for the
    //protocol
    function protocolFeeRatio() external view returns (uint64);

    /// @notice lookup table for whether a pool is owned by the factory
    function isFactoryPool(IPool pool) external view returns (bool);
}