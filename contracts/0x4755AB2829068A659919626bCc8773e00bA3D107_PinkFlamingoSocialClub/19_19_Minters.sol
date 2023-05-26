// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "Ownable.sol";
import "Strings.sol";

/**
 * @author Bruce Wang
 * @notice Pink Flamingo Social Club: Mint Management
 */
abstract contract Minters is Ownable {
    /**
     * @notice struct to maintain limits
     */
    struct Minter {
        uint16 publicMints;
        uint16 whitelistMints;
    }

    /**
     * @notice address => Minter
     */
    mapping(address => Minter) public minters;

    /**
     * @notice limits
     */
    uint16 public whitelistMintLimit = 3;
    uint16 public publicMintLimit = 5;

    /**
     * @notice Change whitelistMintLimit
     */
    function setWhitelistMintLimit(uint16 limit) external onlyOwner {
        require(
            limit != whitelistMintLimit,
            "Must be different to current value"
        );
        whitelistMintLimit = limit;
    }

    /**
     * @notice Change publicMintLimit
     */
    function setPublicMintLimit(uint16 limit) external onlyOwner {
        require(limit != publicMintLimit, "Must be different to current value");
        publicMintLimit = limit;
    }

    /**
     * @notice Verify minter has minted within whitelisted limit
     */
    modifier withinWhitelistLimit(uint16 qty) {
        require(
            minters[msg.sender].whitelistMints + 1 <= whitelistMintLimit,
            "Reached Whitelist Limit"
        );
        require(
            minters[msg.sender].whitelistMints + qty <= whitelistMintLimit,
            string(
                abi.encodePacked(
                    "Can't mint quantity: ",
                    Strings.toString(qty),
                    ", ",
                    Strings.toString(
                        whitelistMintLimit - minters[msg.sender].whitelistMints
                    ),
                    " remaining for Whitelist Mint"
                )
            )
        );
        _;
    }

    /**
     * @notice Verify minter has minted within public limit
     */
    modifier withinPublicLimit(uint16 qty) {
        require(qty <= 5, "Can only mint 5 at a time");
        _;
    }
}