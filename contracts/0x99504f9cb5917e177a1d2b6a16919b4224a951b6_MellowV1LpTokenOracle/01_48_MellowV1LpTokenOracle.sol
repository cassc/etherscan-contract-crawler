// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ERC20RootVault} from "@mellow-vaults/contracts/vaults/ERC20RootVault.sol";
import {IVault, IVaultGovernance} from "@mellow-vaults/contracts/interfaces/vaults/IVault.sol";

import "../../interfaces/oracles/IBaseOracle.sol";
import "../../libraries/external/FullMath.sol";
import "../../utils/DefaultAccessControl.sol";

import "./utils/IMEVProtectionImpl.sol";

contract MellowV1LpTokenOracle is IBaseOracle, DefaultAccessControl {
    constructor(address admin) DefaultAccessControl(admin) {}

    mapping(address => address) public protectionImplementationByGovernance;

    function setMEVProtectionImpl(address[] memory governances, address[] memory mevProtectionImpl) external {
        _requireAdmin();
        for (uint256 i = 0; i < governances.length; i++) {
            protectionImplementationByGovernance[governances[i]] = mevProtectionImpl[i];
        }
    }

    function ensureNoMEV(address vault) public view {
        address governance = address(IVault(vault).vaultGovernance());
        address mevProtectionImpl = protectionImplementationByGovernance[governance];
        if (address(0) == mevProtectionImpl) return;
        IMEVProtectionImpl(mevProtectionImpl).ensureNoMEV(vault);
    }

    /// @inheritdoc IBaseOracle
    function quote(
        address token,
        uint256 amount,
        bytes memory
    ) public view override returns (address[] memory tokens, uint256[] memory tokenAmounts) {
        ERC20RootVault rootVault = ERC20RootVault(token);
        {
            uint256[] memory subvaultNfts = rootVault.subvaultNfts();
            for (uint256 i = 0; i < subvaultNfts.length; i++) {
                ensureNoMEV(address(rootVault.subvaultAt(i)));
            }
        }

        (tokenAmounts, ) = rootVault.tvl();
        tokens = rootVault.vaultTokens();
        uint256 totalSupply = rootVault.totalSupply();
        if (totalSupply > 0) {
            for (uint256 i = 0; i < tokenAmounts.length; i++) {
                tokenAmounts[i] = FullMath.mulDiv(tokenAmounts[i], amount, totalSupply);
            }
        }
    }
}