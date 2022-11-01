pragma solidity 0.8.15;

import "IERC20.sol";
import "Ownable.sol";
import "SafeERC20.sol";

interface ICurveFactory {
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address receiver
    ) external returns (uint256);
}

contract CurveFactoryConverter is Ownable {
    using SafeERC20 for IERC20;

    ICurveFactory public pool;

    address public assetConverter;

    mapping(address => int128) public indices; // int128 is 0 by default. It is need check in swap, what token is correct?

    constructor(
        address _assetConverter,
        address curvePool,
        address[] memory coins
    ) {
        require(curvePool != address(0), "Null address provided");
        require(_assetConverter != address(0), "Null address provided");
        assetConverter = _assetConverter;
        pool = ICurveFactory(curvePool);
        for (uint128 i = 0; i < coins.length; i++) {
            address token = coins[i];
            indices[token] = int128(i);
            IERC20(token).safeIncreaseAllowance(curvePool, type(uint256).max);
        }
    }

    function swap(
        address source,
        address destination,
        uint256 value,
        address beneficiary
    ) external returns (uint256) {
        require(msg.sender == assetConverter, "Invalid caller");
        int128 i = indices[source];
        int128 j = indices[destination];
        uint256 result = pool.exchange_underlying(i, j, value, 0, beneficiary);

        return result;
    }
}