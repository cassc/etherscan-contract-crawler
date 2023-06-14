// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./IUtilityToken.sol";
import "./ITimeYieldedCredit.sol";

interface INFTYieldedToken is IUtilityToken, ITimeYieldedCredit {
/**
         * @dev Returns the amount claimable by the owner of `tokenId`.
         *
         * Requirements:
         *
         * - `tokenId` must exist.
         */
        function getClaimableAmount(uint256 tokenId)  external view returns (uint256);

        /**
         * @dev Returns an array of amounts claimable by `addr`.
         * If `addr` doesn't own any tokens, returns an empty array.
         */
        function getClaimableForAddress(address addr) external view returns (uint256[] memory, uint256[] memory);

    /**
         * @dev Spends `amount` credit from `tokenId`'s balance -
         * for the consumption of an external service identified by `serviceId`.
         * Optionally sending additional `data`.
         *
         * Requirements:
         *
         * See {NFTYieldedToken._spend}
         */
        function spend(
            uint256 tokenId,
            uint256 amount,
            uint256 serviceId,
            bytes calldata data
        ) external;

        /**
         * @dev Claims `amount` credit as tokens from `tokenId`'s balance.
         *
         * Requirements:
         *
         * See {NFTYieldedToken._spend}
         */
        function claim(uint256 tokenId, uint256 amount) external;


        /**
         * @dev Spends `amount` credit from `tokenId`'s balance on behalf of `account`-
         * for the consumption of an external service identified by `serviceId`.
         * Optionally sending additional `data`.
         *
         * Requirements:
         *
         * See {NFTYieldedToken._spendFrom}
         */
        function spendFrom(
            address account,
            uint256 tokenId,
            uint256 amount,
            uint256 serviceId,
            bytes calldata data
        ) external;


        /**
         * @dev Claims `amount` credit as tokens from `tokenId`'s balance on behalf of `account`-
         * The tokens are minted to the address `to`.
         *
         * Requirements:
         *
         * See {NFTYieldedToken._spendFrom}
         */
        function claimFrom(
            address account,
            uint256 tokenId,
            uint256 amount,
            address to
        ) external;

        /**
         * @dev Spends credit from multiple `tokenIds` as specified by `amounts`-
         * for the consumption of an external service identified by `serviceId`.
         * Optionally sending additional `data`.
         *
         * Requirements:
         *
         * See {NFTYieldedToken._spendMultiple}
         */
        function spendMultiple(
            uint256[] calldata tokenIds,
            uint256[] calldata amounts,
            uint256 serviceId,
            bytes calldata data
        ) external;

         /**
         * @dev Spends credit from multiple `tokenIds` - owned by `account` - as specified by `amounts`-
         * for the consumption of an external service identified by `serviceId`.
         * Optionally sending additional `data`.
         *
         * Requirements:
         *
         * See {NFTYieldedToken._spendMultiple}
         */
        function externalSpendMultiple(
            address account,
            uint256[] calldata tokenIds,
            uint256[] calldata amounts,
            uint256 serviceId,
            bytes calldata data
        ) external;

        /**
         * @dev Claims credit as tokens from multiple `tokenIds` as specified by `amounts`.
         *
         * Requirements:
         *
         * See {NFTYieldedToken._spendMultiple}
         */
        function claimMultiple(
            uint256[] calldata tokenIds,
            uint256[] calldata amounts
        ) external;

        /**
         * @dev Claims all the available credit as the token for `tokenId`.
         *
         * Requirements:
         *
         * - The caller must own `tokenId`.
         *
         * - `tokenId` must exist.
         */
        function claimAll(uint256 tokenId) external;
}