// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC721Collective} from "src/contracts/ERC721Collective/IERC721Collective.sol";
import {IERC20Club} from "src/contracts/ERC20Club/IERC20Club.sol";
import {TokenRecoverable} from "src/contracts/utils/TokenRecoverable/TokenRecoverable.sol";
import {TokenOwnerChecker} from "src/contracts/utils/TokenOwnerChecker.sol";

/**
 * @title RugAllocatedMintModule
 * @author Syndicate Inc.
 * @custom:license Copyright (c) 2021-present Syndicate Inc. All rights
 * reserved.
 *
 * A Module that allows the owner of one ERC20Club to allocate a number of
 * rugTokens to the owners of specific tokenIds of an ERC721Collective, then
 * allows those owners to mint their allocated rugTokens.
 */
contract RugAllocatedMintModule is
    ReentrancyGuard,
    TokenRecoverable,
    TokenOwnerChecker
{
    event Allocated(uint256 indexed hostPassId, uint256 indexed amount);
    event Minted(
        address indexed account,
        uint256 indexed hostPassId,
        uint256 indexed amount
    );

    // the ERC721Collective whose tokenIds are given allocations
    IERC721Collective public hostPass;
    // the ERC20Club token to allocate
    IERC20Club public rugToken;
    // maps Host Pass ID => Rug Token allocation in wei
    mapping(uint256 => uint256) public allocations;

    constructor(address hostPass_, address rugToken_)
        TokenRecoverable(IERC20Club(rugToken_).owner())
    {
        hostPass = IERC721Collective(hostPass_);
        rugToken = IERC20Club(rugToken_);
    }

    /**
     * Allows a caller that owns a Host Pass to claim the amount of Rug Tokens
     * allocated to their Host Pass ID (partial claims are not allowed).
     *
     * Emits a `Minted` event.
     *
     * Requirements:
     * - `hostPassId` must have been allocated at least one token.
     * - The caller must own the Host Pass with tokenId `hostPassId`.
     * @param hostPassId The tokenId of the Host Pass that has been allocated
     */
    function mint(uint256 hostPassId) external nonReentrant {
        // Store to correctly implement checks-effects-interactions
        uint256 allocation = allocations[hostPassId];

        // Checks
        require(allocation > 0, "RugAllocatedMintModule: No tokens allocated");
        require(
            hostPass.ownerOf(hostPassId) == msg.sender,
            "RugAllocatedMintModule: Must own host pass with requested tokenId"
        );

        // Effects
        allocations[hostPassId] = 0;

        // Interactions
        rugToken.mintTo(msg.sender, allocation);

        emit Minted(msg.sender, hostPassId, allocation);
    }

    /**
     * Allows the owner to allocate `amounts` tokens to each Host Pass tokenId
     * in `hostPassIds`.
     *
     * If a Host Pass tokenId in `hostPassIds` already has an allocation set,
     * this function will OVERRIDE that allocation with the new value.
     *
     * If a tokenId appears more than once in `hostPassIds`, the allocation
     * will be set to the LAST corresponding amount.
     *
     * Emits an `Allocated` event for each tokenId-amount pair.
     *
     * Requirements:
     * - The caller must be the Rug Token owner.
     * - `hostPassIds` and `amounts` must be arrays of the same length.
     * @param hostPassIds The Host Pass tokenIds to which Rug Tokens will be
     * allocated
     * @param amounts The amounts of Rug Tokens to be allocated to the Host
     * Pass tokenIds of corresponding index in `hostPassIds`. THIS IS ETH
     * DENOMINATED, NOT WEI DENOMINATED!
     */
    function allocate(
        uint256[] calldata hostPassIds,
        uint256[] calldata amounts
    ) external onlyTokenOwner(address(rugToken)) {
        _checkArrays(hostPassIds, amounts);
        uint256 length = hostPassIds.length;
        for (uint256 i = 0; i < length; ) {
            _allocate(hostPassIds[i], _etherToWei(amounts[i]));
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Allows the owner to increase the allocation to each address in
     * `hostPassIds` by the amount with corresponding index in `amounts`.
     *
     * If an address appears more than once in `hostPassIds`, their allocation
     * will be increased by the sum of all corresponding values in `amounts`.
     *
     * Emits an `Allocated` event for each tokenId-amount pair.
     *
     * Requirements:
     * - The caller must be the Rug Token owner.
     * - `hostPassIds` and `amounts` must be arrays of the same length.
     * @param hostPassIds The Host Pass tokenIds to which Rug Tokens will be
     * allocated
     * @param amounts The amounts of Rug Tokens to be allocated to the Host
     * Pass tokenIds of corresponding index in `hostPassIds`. THIS IS ETHER
     * DENOMINATED, NOT WEI DENOMINATED!
     */
    function increaseAllocations(
        uint256[] calldata hostPassIds,
        uint256[] calldata amounts
    ) external onlyTokenOwner(address(rugToken)) {
        _checkArrays(hostPassIds, amounts);
        uint256 length = hostPassIds.length;
        for (uint256 i = 0; i < length; ) {
            _allocate(
                hostPassIds[i],
                allocations[hostPassIds[i]] + _etherToWei(amounts[i])
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Allows the owner to decrease the allocation to each Host Pass tokenId in
     * `hostPassIds` by the amount with corresponding index in `amounts`.
     *
     * If an address appears more than once in `hostPassIds`, their allocation
     * will be decreased by the SUM of all corresponding values in `amounts`.
     *
     * If some `amounts[i]` EXCEEDS the current allocation of `hostPassIds[i]`,
     * the allocation will be reduced to zero.
     *
     * Emits an `Allocated` event for each tokenId-amount pair.
     *
     * Requirements:
     * - The caller must be the Rug Token owner.
     * - `hostPassIds` and `amounts` must be arrays of the same length.
     * @param hostPassIds The Host Pass tokenIds to which Rug Tokens will be
     * allocated
     * @param amounts The amounts of Rug Tokens to be allocated to the Host
     * Pass tokenIds of corresponding index in `hostPassIds`. THIS IS ETHER
     * DENOMINATED, NOT WEI DENOMINATED!
     */
    function decreaseAllocations(
        uint256[] calldata hostPassIds,
        uint256[] calldata amounts
    ) external onlyTokenOwner(address(rugToken)) {
        _checkArrays(hostPassIds, amounts);
        uint256 length = hostPassIds.length;
        for (uint256 i = 0; i < length; ) {
            uint256 amountInWei = _etherToWei(amounts[i]);
            uint256 hostPassId = hostPassIds[i];
            uint256 allocation = allocations[hostPassId];
            if (allocation >= amountInWei) {
                unchecked {
                    _allocate(hostPassId, allocation - amountInWei);
                }
            } else {
                _allocate(hostPassId, 0);
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Internal helper function to update the allocation of an account.
     *
     * Emits an `Allocated` event.
     * @param hostPassId The Host Pass tokenId to which Rug Tokens will be
     * allocated
     * @param amount The amount of Rug Tokens, in WEI, to be allocated to
     * `account`
     */
    function _allocate(uint256 hostPassId, uint256 amount) internal {
        allocations[hostPassId] = amount;
        emit Allocated(hostPassId, amount);
    }

    /**
     * Internal helper function checking that two input arrays have matching
     * lengths.
     * @param hostPassIds First input array of integers
     * @param amounts Second input array of integers
     */
    function _checkArrays(
        uint256[] calldata hostPassIds,
        uint256[] calldata amounts
    ) internal pure {
        require(
            hostPassIds.length == amounts.length,
            "RugAllocatedMintModule: Differing input array lengths"
        );
    }

    /**
     * Internal helper function converting an ether-denominated input to wei.
     * @return wei-denominated output.
     * @param amount ether-denominated input
     */
    function _etherToWei(uint256 amount) internal pure returns (uint256) {
        return amount * 10**18;
    }

    /**
     * This function is called for all messages sent to this contract (there
     * are no other functions). Sending Ether to this contract will cause an
     * exception, because the fallback function does not have the `payable`
     * modifier.
     * Source: https://docs.soliditylang.org/en/v0.8.9/contracts.html?highlight=fallback#fallback-function
     */
    fallback() external {
        revert("RugAllocatedMintModule: non-existent function");
    }
}