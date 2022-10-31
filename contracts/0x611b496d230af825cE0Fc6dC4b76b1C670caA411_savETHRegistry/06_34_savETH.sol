pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { ERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import { savETHRegistry } from "./savETHRegistry.sol";
import { StakeHouseUniverse } from "./StakeHouseUniverse.sol";
import { ScaledMath } from "./ScaledMath.sol";
import { StakeHouseUUPSCoreModule } from "./StakeHouseUUPSCoreModule.sol";

contract savETH is ERC20PermitUpgradeable, StakeHouseUUPSCoreModule {
    using ScaledMath for uint256;

    /// @notice Minter and configuration for SaveETH
    savETHRegistry public registry;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Used in place of a constructor to support proxies
    /// @dev Can only be called once
    /// @param _registry Address of the registry used to control minting
    function init(savETHRegistry _registry, StakeHouseUniverse _universe) external initializer {
        require(address(_registry) != address(0), "Registry cannot be zero address");
        registry = _registry;

        __ERC20_init("savETH", "savETH");
        __ERC20Permit_init("savETH");
        __StakeHouseUUPSCoreModule_init(_universe);
    }

    /// @notice Mints a given amount of tokens
    /// @dev Only savETH registry module can call
    /// @param _recipient of the tokens
    /// @param _amount of savETH to mint
    function mint(address _recipient, uint256 _amount) external {
        require(msg.sender == address(registry), "mint: Only registry");
        _mint(_recipient, _amount);
    }

    /// @notice Burns a given amount of SaveETH
    /// @dev Only savETH registry can call
    /// @param _account that owns SaveETH
    /// @param _amount of SaveETH to burn
    function burn(address _account, uint256 _amount) external {
        require(msg.sender == address(registry), "burn: Only registry");
        _burn(_account, _amount);
    }

    /// @notice Returns the number of dETH the owner could claim at the current exchange rate
    /// @param _owner address of account that holds SaveETH
    function dETH(address _owner) external view returns (uint256) {
        return registry.savETHToDETH(balanceOf(_owner));
    }
}