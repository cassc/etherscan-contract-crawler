//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/IValidator.sol";

interface IHoney is IERC20, IValidator {
    function mint(address for_, uint256 amount) external;
    function burn(address for_, uint256 amount) external;
}