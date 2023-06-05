//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { FactoryFriendly } from "@gnosis.pm/zodiac/contracts/factory/FactoryFriendly.sol";
import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ERC20VotesUpgradeable, ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import { ERC20SnapshotUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";

/**
 * An implementation of the Open Zeppelin `IVotes` voting token standard.
 */
contract VotesERC20 is
    IERC20Upgradeable,
    ERC20SnapshotUpgradeable,
    ERC20VotesUpgradeable,
    ERC165Storage,
    FactoryFriendly
{

    constructor() {
      _disableInitializers();
    }

    /**
     * Initialize function, will be triggered when a new instance is deployed.
     *
     * @param initializeParams encoded initialization parameters: `string memory _name`,
     * `string memory _symbol`, `address[] memory _allocationAddresses`, 
     * `uint256[] memory _allocationAmounts`
     */
    function setUp(bytes memory initializeParams) public virtual override initializer {
        (
            string memory _name,                    // token name
            string memory _symbol,                  // token symbol
            address[] memory _allocationAddresses,  // addresses of initial allocations
            uint256[] memory _allocationAmounts     // amounts of initial allocations
        ) = abi.decode(
                initializeParams,
                (string, string, address[], uint256[])
            );

        __ERC20_init(_name, _symbol);
        __ERC20Permit_init(_name);
        _registerInterface(type(IERC20Upgradeable).interfaceId);

        uint256 holderCount = _allocationAddresses.length;
        for (uint256 i; i < holderCount; ) {
            _mint(_allocationAddresses[i], _allocationAmounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * See `ERC20SnapshotUpgradeable._snapshot()`.
     */
    function captureSnapShot() external returns (uint256 snapId) {
        snapId = _snapshot();
    }

    // -- The functions below are overrides required by extended contracts. --

    /** Overridden without modification. */
    function _mint(
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._mint(to, amount);
    }

    /** Overridden without modification. */
    function _burn(
        address account,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._burn(account, amount);
    }

    /** Overridden without modification. */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20SnapshotUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /** Overridden without modification. */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }
}