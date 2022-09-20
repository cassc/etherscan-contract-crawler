// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IERC4626.sol";

interface IWrappedUsdPlusToken is IERC20Upgradeable, IERC4626 {

    /**
     * @dev Returns UsdPlusToken liquidity index in e27 (ray)
     * @return rate Rate between WrappedUsdPlusToken and UsdPlusToken in e27 (ray)
     **/
    function rate() external view returns (uint256);

}