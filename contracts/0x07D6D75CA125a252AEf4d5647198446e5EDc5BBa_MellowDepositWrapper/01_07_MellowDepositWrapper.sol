// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "./interfaces/IMellowDepositWrapper.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IERC20RootVault.sol";
import "./libraries/SafeTransferLib.sol";

contract MellowDepositWrapper is IMellowDepositWrapper {
    using SafeTransferLib for IERC20Minimal;
    using SafeTransferLib for IWETH;

    /// @dev Wrapped ETH interface
    IWETH public _weth;

    constructor(address wethAddress) {
        require(address(wethAddress) != address(0), "weth addr zero");
        _weth = IWETH(wethAddress);
    }
    
    // @inheritdoc IMellowDepositWrapper
    function deposit(
        address erc20RootVaultAddress,
        uint256 minLpTokens,
        bytes memory vaultOptions
    ) external payable override returns (uint256[] memory actualTokenAmounts) {
        require(msg.value > 0, "only deposit");
        require(address(erc20RootVaultAddress) != address(0), "erc20rootvault addr zero");

        IERC20RootVault erc20RootVault = IERC20RootVault(erc20RootVaultAddress);

        uint256 marginDelta = msg.value;
        _weth.deposit{value: msg.value}();

        _weth.safeIncreaseAllowanceTo(
            address(erc20RootVault),
            marginDelta
        );

        uint256[] memory tokenAmounts = new uint256[](1);
        tokenAmounts[0] = marginDelta;

        actualTokenAmounts = erc20RootVault.deposit(
          tokenAmounts,
          minLpTokens,
          vaultOptions
        );

        uint256 lpTokens = erc20RootVault.balanceOf(address(this));
        erc20RootVault.transfer(msg.sender, lpTokens);
    }
}