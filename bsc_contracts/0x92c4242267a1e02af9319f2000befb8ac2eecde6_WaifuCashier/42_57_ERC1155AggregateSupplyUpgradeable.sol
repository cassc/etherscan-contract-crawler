// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a aggregateSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155AggregateSupplyUpgradeable is
    Initializable,
    ERC1155Upgradeable
{
    function __ERC1155AggregateSupply_init() internal onlyInitializing {
        __ERC1155AggregateSupply_init_unchained();
    }

    function __ERC1155AggregateSupply_init_unchained()
        internal
        onlyInitializing
    {}

    uint256 private _aggregateSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function aggregateSupply() public view virtual returns (uint256) {
        return _aggregateSupply;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _aggregateSupply += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                require(
                    _aggregateSupply >= amounts[i],
                    "ERC1155AggregateSupply: insufficient supply"
                );

                unchecked {
                    _aggregateSupply -= amounts[i];
                }
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}