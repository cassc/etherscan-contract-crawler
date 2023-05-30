pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721KODACreatorWithBuyItNow} from "./ERC721KODACreatorWithBuyItNow.sol";
import {UpdatableOperatorFiltererUpgradeable} from "../../operator-filter-registry/UpdatableOperatorFiltererUpgradeable.sol";

/// @author KnownOrigin Labs - https://knownorigin.io/
/// @notice ERC721 KODA Creator with Embedded Primary and Secondary Buy It Now Marketplace
contract ERC721KODACreatorWithBuyItNowAndFilterRegistry is
    ERC721KODACreatorWithBuyItNow,
    UpdatableOperatorFiltererUpgradeable
{
    /// @dev Configure operator registry with init param
    function __Module_init(
        address _operatorRegistry,
        address _subscriptionOrRegistrantToCopy
    ) internal override {
        _UpdatableOperatorFilterer_init(
            _operatorRegistry,
            _subscriptionOrRegistrantToCopy,
            _subscriptionOrRegistrantToCopy != address(0)
        );
    }

    /// @dev Required for solidity compiler due to ownable clashes
    function owner()
        public
        view
        virtual
        override(OwnableUpgradeable, UpdatableOperatorFiltererUpgradeable)
        returns (address)
    {
        return super.owner();
    }

    /// @dev Override the before transfer hook so that the operator filter can be checked against the from address
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override onlyAllowedOperator(_from) {}
}