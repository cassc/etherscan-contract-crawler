// SPDX-License-Identifier: Apache-2.0
// https://docs.soliditylang.org/en/v0.8.10/style-guide.html
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @dev Wrapped yvUSDC
 *
 * ERC-4626 wrapper around Yearn Finance USDC token
 * to create a non-rebasing yield token. Value accrued in yvUSDC (asset)
 * is reflected in wyvUSDC (shares).
 */
contract wyvUSDC is ERC4626Upgradeable {
    function initialize(address _yvUSDC) external initializer {
        __ERC20_init("Wrapped yvUSDC", "wyvUSDC");
        __ERC4626_init(IERC20MetadataUpgradeable(_yvUSDC));
    }
}