// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISyntheticToken is IERC20 {
    function isActive() external view returns (bool);

    function mint(address to_, uint256 amount_) external;

    function burn(address from_, uint256 amount) external;

    function toggleIsActive() external;

    function seize(address from_, address to_, uint256 amount_) external;

    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external;
}