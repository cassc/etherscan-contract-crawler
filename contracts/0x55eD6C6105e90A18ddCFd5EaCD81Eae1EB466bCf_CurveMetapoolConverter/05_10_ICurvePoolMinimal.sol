pragma solidity ^0.8.10;

/// @dev This interface is incomplete and may be invalid for some of Curve pools.
/// It has only functions required for converters functionality.
/// Please ensure that it is correct for chosen pool or test it before deployment
/// Also, it does not contain exchange function with `receiver` parameter
/// We do not include it for better compatibility because some pools (for example 3CRV or FRAXUSDC) do not support it
interface ICurvePoolMinimal {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function coins(uint256 i) external view returns (address);
}