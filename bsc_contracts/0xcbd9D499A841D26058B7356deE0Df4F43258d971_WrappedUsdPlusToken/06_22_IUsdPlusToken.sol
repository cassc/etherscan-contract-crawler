// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUsdPlusToken is IERC20 {

    function liquidityIndex() external view returns (uint256);

    function setLiquidityIndex(uint256 _liquidityIndex) external;

    function mint(address _sender, uint256 _amount) external;

    function burn(address _sender, uint256 _amount) external;

}