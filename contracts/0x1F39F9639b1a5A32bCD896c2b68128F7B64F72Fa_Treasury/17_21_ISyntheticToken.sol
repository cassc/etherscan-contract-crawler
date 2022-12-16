// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./IDebtToken.sol";
import "./IPoolRegistry.sol";

interface ISyntheticToken is IERC20Metadata {
    function isActive() external view returns (bool);

    function mint(address to_, uint256 amount_) external;

    function burn(address from_, uint256 amount) external;

    function poolRegistry() external returns (IPoolRegistry);

    function toggleIsActive() external;

    function seize(
        address from_,
        address to_,
        uint256 amount_
    ) external;

    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external;

    function maxTotalSupply() external view returns (uint256);
}