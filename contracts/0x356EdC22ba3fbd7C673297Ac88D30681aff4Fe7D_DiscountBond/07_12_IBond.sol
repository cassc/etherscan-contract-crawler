// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IBond is IERC20MetadataUpgradeable {
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory series,
        address factory_,
        IERC20MetadataUpgradeable underlyingToken_,
        uint256 maturity_,
        string memory isin_
    ) external;

    function kind() external returns (string memory);

    function series() external returns (string memory);

    function isin() external returns (string memory);

    function underlyingOut(uint256 amount_, address to_) external;

    function grant(uint256 amount_) external;

    function faceValue(uint256 bondAmount_) external view returns (uint256);

    function amountToUnderlying(uint256 bondAmount_) external view returns (uint256);

    function emergencyWithdraw(
        IERC20MetadataUpgradeable token_,
        address to_,
        uint256 amount_
    ) external;
}