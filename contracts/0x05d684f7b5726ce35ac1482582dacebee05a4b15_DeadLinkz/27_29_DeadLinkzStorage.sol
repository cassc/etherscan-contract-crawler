// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IDeadCrew.sol";

library DeadLinkzStorage {
    struct Layout {
        /// @notice Base URI of the NFT
        string baseURI;
        /// @notice External signer for minting
        address signer;
        /// @notice Whitelist sale
        bool whitelistSale;
        /// @notice Public sale
        bool publicSale;
        /// @notice Maximum per wallet
        uint256 maxMintQuantity;
        /// @notice Number of mints for a wallet
        mapping(address => uint256) addressNumMints;
        /// @notice Revealed
        mapping(uint256 => bool) tokenRevealed;
        /// @notice Reveal price
        uint256 revealPrice;
        /// @notice Reveal base URI
        string revealBaseURI;
        /// @notice Dead crew nft
        IDeadCrew deadCrew;
        /// @notice Received
        mapping(uint256 => bool) crewNonce;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("deadlinkz.contracts.storage.deadlinkz");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}