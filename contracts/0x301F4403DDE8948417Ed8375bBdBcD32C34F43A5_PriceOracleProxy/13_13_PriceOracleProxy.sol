pragma solidity 0.5.16;

import "./PriceOracle.sol";
import "../BErc20.sol";

interface IBaseOracle {
    /// @dev Return the USD based price of the given input, multiplied by 10**18.
    /// @param token The ERC-20 token to check the value.
    function getPrice(address token) external view returns (uint256);
}

contract PriceOracleProxy is PriceOracle {
    IBaseOracle public baseOracle;

    /**
     * @param baseOracle_ The address of BlueBerry Core Oracle
     */
    constructor(IBaseOracle baseOracle_) public {
        baseOracle = baseOracle_;
    }

    /**
     * @notice Get the underlying price of a listed bToken asset
     * @param bToken The bToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18)
     */
    function getUnderlyingPrice(BToken bToken) public view returns (uint256) {
        address underlying = BErc20(address(bToken)).underlying();
        return baseOracle.getPrice(underlying);
    }
}