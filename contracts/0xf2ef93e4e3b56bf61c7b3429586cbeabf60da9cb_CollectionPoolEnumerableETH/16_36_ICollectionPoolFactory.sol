// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";
import {
    PoolVariant,
    NFTFilterParams,
    CreateETHPoolParams,
    CreateERC20PoolParams,
    RoyaltyDue
} from "./CollectionStructsAndEnums.sol";

interface ICollectionPoolFactory is IERC721 {
    function protocolFeeMultiplier() external view returns (uint24);

    function protocolFeeRecipient() external view returns (address payable);

    function carryFeeMultiplier() external view returns (uint24);

    function callAllowed(address target) external view returns (bool);

    function routerStatus(CollectionRouter router) external view returns (bool allowed, bool wasEverAllowed);

    function isPool(address potentialPool) external view returns (bool);

    function isPoolVariant(address potentialPool, PoolVariant variant) external view returns (bool);

    function requireAuthorizedForToken(address spender, uint256 tokenId) external view;

    function swapPaused() external view returns (bool);

    function creationPaused() external view returns (bool);

    function depositPaused() external view returns (bool);

    function othersPaused() external view returns (bool);

    function createPoolETH(CreateETHPoolParams calldata params)
        external
        payable
        returns (ICollectionPool pool, uint256 tokenId);

    function createPoolERC20(CreateERC20PoolParams calldata params)
        external
        returns (ICollectionPool pool, uint256 tokenId);

    function createPoolETHFiltered(CreateETHPoolParams calldata params, NFTFilterParams calldata filterParams)
        external
        payable
        returns (ICollectionPool pool, uint256 tokenId);

    function createPoolERC20Filtered(CreateERC20PoolParams calldata params, NFTFilterParams calldata filterParams)
        external
        returns (ICollectionPool pool, uint256 tokenId);

    function depositRoyaltiesNotification(ERC20 token, RoyaltyDue[] calldata royaltiesDue, PoolVariant poolVariant)
        external
        payable;

    function burn(uint256 tokenId) external;

    /**
     * @dev Returns the pool of the `tokenId` token.
     */
    function poolOf(uint256 tokenId) external view returns (ICollectionPool);

    function withdrawRoyalties(address payable recipient, ERC20 token) external;

    /**
     * @notice Withdraw all `token` royalties awardable to `recipient`. If the
     * zero address is passed as `token`, then ETH royalties are paid. Does not
     * use msg.sender so this function can be called on behalf of contract
     * royalty recipients
     *
     * @dev Does not call `withdrawRoyalties` to avoid making multiple unneeded
     * checks of whether `address(token) == address(0)` for each iteration
     */
    function withdrawRoyaltiesMultipleRecipients(address payable[] calldata recipients, ERC20 token) external;

    function withdrawRoyaltiesMultipleCurrencies(address payable recipient, ERC20[] calldata tokens) external;

    /**
     * @notice Withdraw royalties for ALL combinations of recipients and tokens
     * in the given arguments
     *
     * @dev Iterate over tokens as outer loop to reduce stores/loads to `royaltiesStored`
     * and also reduce the number of `address(token) == address(0)` condition checks
     * from O(m * n) to O(n)
     */
    function withdrawRoyaltiesMultipleRecipientsAndCurrencies(
        address payable[] calldata recipients,
        ERC20[] calldata tokens
    ) external;
}