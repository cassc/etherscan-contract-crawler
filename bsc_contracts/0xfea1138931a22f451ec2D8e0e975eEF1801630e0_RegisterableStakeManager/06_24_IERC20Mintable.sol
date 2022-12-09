// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Full is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IERC20Mintable is IERC20Full {
    function mint(address to, uint256 value) external;

    function burn(address from, uint256 value) external;
}