// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/MintERC721Lib.sol";
import "./libraries/SecurityLib.sol";
import "./ERC721Base.sol";

/**
 * @title Recomet NFTs implemented using the ERC-721 standard.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract RecometERC721 is ERC721Base {
    /**
     * @notice Set immutable variables for the implementation contract.
     * @dev Using immutable instead of constants allows us to use different values on testnet.
     * @param name The user readable name of the signing domain.
     * @param version The current major version of the signing domain.
     * @param tokenName The symbol of the token.
     * @param tokenSymbol The symbol of the token.
     * @param trustedForwarder The Recomet TrustedForwarder address.
     * @param defaultApprovals The Recomet defaultApproval addresses.
     */
    function __RecometERC721_init(
        string memory name,
        string memory version,
        string memory tokenName,
        string memory tokenSymbol,
        address trustedForwarder,
        address[] memory defaultApprovals
    ) external initializer {
        __ERC721Base_init_unchained(
            name,
            version,
            tokenName,
            tokenSymbol,
            trustedForwarder,
            defaultApprovals
        );
    }

    uint256[50] private __gap;
}