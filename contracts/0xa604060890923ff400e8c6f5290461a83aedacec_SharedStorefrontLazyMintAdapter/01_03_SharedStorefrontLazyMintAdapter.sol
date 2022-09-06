// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @author emo.eth
 * @title SharedStorefrontLazyMintAdapter
 * @notice SharedStorefrontLazymintAdapter is a stub of an ERC1155 token,
 *         which acts as a safe proxy for lazily minting tokens from the
 *         the underlying Shared Storefront.
 *         The lazy minting functionality of the original Shared Storefront
 *         was built with the assumption that every user would have their own
 *         individual Wyvern-style proxy, which makes an exchange with
 *         a global proxy like Seaport unsafe to add as a shared proxy.
 *         This adapter contract performs the necessary check that lazily
 *         minted tokens are being spent from their creators' address, relying
 *         on the invariant that Seaport will never transfer tokens from an
 *         account that has not signed a valid order.
 */
contract SharedStorefrontLazyMintAdapter {
    IERC1155 immutable ssfToken;
    address private constant SEAPORT =
        0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address private constant CONDUIT =
        0x1E0049783F008A0085193E00003D00cd54003c71;

    error InsufficientBalance();
    error UnauthorizedCaller();

    modifier onlySeaportOrConduit() {
        if (msg.sender != CONDUIT && msg.sender != SEAPORT) {
            revert UnauthorizedCaller();
        }
        _;
    }

    modifier onlyCreatorLazyMint(
        address from,
        uint256 tokenId,
        uint256 amount
    ) {
        // get balance of spender - this will return current balance
        // plus remaining supply if spender is the creator
        // (or this contract itself - which should never be possible,
        // as Seaport will only spend from accts that have signed a valid order)
        uint256 fromBalance = ssfToken.balanceOf(from, tokenId);

        // if insufficient balance, revert
        if (fromBalance < amount) {
            revert InsufficientBalance();
        }
        _;
    }

    /// @dev parameterless constructor allows us to CREATE2 this contract at the same address on each network
    constructor() {
        // can't set immutables within an if statement; use temp var
        address tokenAddress;

        uint256 chainId = block.chainid;
        // use chainId to get network SSF address
        if (chainId == 4) {
            // rinkeby SSF
            tokenAddress = 0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656;
        } else if (chainId == 137 || chainId == 80001) {
            // polygon + mumbai SSF
            tokenAddress = 0x2953399124F0cBB46d2CbACD8A89cF0599974963;
        } else {
            // mainnet SSF
            tokenAddress = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
        }

        ssfToken = IERC1155(tokenAddress);
    }

    /**
     * @notice stub method that performs two checks before calling real SSF safeTransferFrom
     *   1. check that the caller is a valid proxy (Seaport or OpenSea conduit)
     *   2. check that the token spender owns enough tokens, or is the creator of
     *      the token and not all tokens have been minted yet
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory
    ) public onlySeaportOrConduit onlyCreatorLazyMint(from, tokenId, amount) {
        // Seaport 1.1 always calls safeTransferFrom with empty data
        ssfToken.safeTransferFrom(from, to, tokenId, amount, "");
    }

    /**
     * @notice pass-through balanceOf method to the SSF for backwards-compatibility with seaport-js
     * @param owner address to check balance of
     * @param tokenId id to check balance of
     * @return uint256 balance of tokenId for owner
     */
    function balanceOf(address owner, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return ssfToken.balanceOf(owner, tokenId);
    }

    /**
     * @notice stub isApprovedForAll method for backwards-compatibility with seaport-js
     * @param operator address to check approval of
     * @return bool if operator is Conduit or Seaport
     */
    function isApprovedForAll(address, address operator)
        public
        pure
        returns (bool)
    {
        return operator == CONDUIT || operator == SEAPORT;
    }
}