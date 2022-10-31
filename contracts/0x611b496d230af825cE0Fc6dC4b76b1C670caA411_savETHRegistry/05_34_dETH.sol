pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { ERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import { StakeHouseUniverse } from "./StakeHouseUniverse.sol";
import { StakeHouseUUPSCoreModule } from "./StakeHouseUUPSCoreModule.sol";

contract dETH is ERC20PermitUpgradeable, StakeHouseUUPSCoreModule {
    /// @notice Minter address
    address public registry;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @param _registry Address of the savETH registry contract used to control minting
    function init(address _registry, StakeHouseUniverse _universe) external initializer {
        require(address(_registry) != address(0), "Registry cannot be zero address");
        registry = _registry;

        __ERC20_init("dToken", "dETH");
        __ERC20Permit_init("dETH");
        __StakeHouseUUPSCoreModule_init(_universe);
    }

    /// @notice Mints a given amount of tokens
    /// @dev Only savETH registry
    function mint(address _recipient, uint256 _amount) external {
        require(msg.sender == registry, "mint: Only registry");
        _mint(_recipient, _amount);
    }

    /// @notice Allows a dETH owner to burn their tokens
    function burn(address _recipient, uint256 _amount) external {
        require(msg.sender == registry, "burn: Only registry");
        _burn(_recipient, _amount);
    }
}