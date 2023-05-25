// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.10;

import "./mixins/InflationaryToken.sol";
import "./vendored/mixins/StorageAccessible.sol";

/// @dev The governance token for the CoW Protocol.
/// @title CoW Protocol Governance Token
/// @author CoW Protocol Developers
contract CowProtocolToken is InflationaryToken, StorageAccessible {
    string private constant ERC20_SYMBOL = "COW";
    string private constant ERC20_NAME = "CoW Protocol Token";

    constructor(
        address initialTokenHolder,
        address cowDao,
        uint256 totalSupply
    )
        InflationaryToken(
            initialTokenHolder,
            cowDao,
            totalSupply,
            ERC20_NAME,
            ERC20_SYMBOL
        )
    // solhint-disable-next-line no-empty-blocks
    {

    }
}