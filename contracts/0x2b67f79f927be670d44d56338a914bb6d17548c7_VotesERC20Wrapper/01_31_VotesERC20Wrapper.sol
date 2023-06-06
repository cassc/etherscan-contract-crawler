//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { ERC20VotesUpgradeable, ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import { ERC20WrapperUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20WrapperUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { VotesERC20 } from "./VotesERC20.sol";

/**
 * An extension of `VotesERC20` which supports wrapping / unwrapping an existing ERC20 token,
 * to allow for importing an existing token into the Azorius governance framework.
 */
contract VotesERC20Wrapper is VotesERC20, ERC20WrapperUpgradeable {
    
    constructor() {
      _disableInitializers();
    }

    /**
     * Initialize function, will be triggered when a new instance is deployed.
     *
     * @param initializeParams encoded initialization parameters: `address _underlyingTokenAddress`
     */
    function setUp(bytes memory initializeParams) public override initializer {
        (address _underlyingTokenAddress) = abi.decode(initializeParams, (address));

        // not necessarily upgradeable, but required to pass into __ERC20Wrapper_init
        ERC20Upgradeable token = ERC20Upgradeable(_underlyingTokenAddress);

        __ERC20Wrapper_init(token);

        string memory name = string.concat("Wrapped ", token.name());
        __ERC20_init(name, string.concat("W", token.symbol()));
        __ERC20Permit_init(name);
        _registerInterface(type(IERC20Upgradeable).interfaceId);
    }

    // -- The functions below are overrides required by extended contracts. --

    /** Overridden without modification. */
    function _mint(
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, VotesERC20) {
        super._mint(to, amount);
    }

    /** Overridden without modification. */
    function _burn(
        address account,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, VotesERC20) {
        super._burn(account, amount);
    }

    /** Overridden without modification. */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, VotesERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /** Overridden without modification. */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, VotesERC20) {
        super._afterTokenTransfer(from, to, amount);
    }

    /** Overridden without modification. */
    function decimals() public view virtual override(ERC20Upgradeable, ERC20WrapperUpgradeable) returns (uint8) {
        return super.decimals();
    }
}